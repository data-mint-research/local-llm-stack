#!/bin/bash
# extract-entities.sh - Extract entities from shell scripts
# This script extracts functions, variables, components, and other entities from shell scripts

# Get the absolute path of the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Output directories
ENTITIES_DIR="$ROOT_DIR/docs/knowledge-graph/entities"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Check if required tools are installed
check_dependencies() {
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Error: jq is not installed. Please install it to process JSON files.${NC}"
        echo "You can install it with: sudo apt-get install jq"
        exit 1
    fi
    
    if ! command -v grep &> /dev/null || ! command -v sed &> /dev/null; then
        echo -e "${RED}Error: grep or sed is not installed. These are required for text processing.${NC}"
        exit 1
    fi
}

# Create the entities directory if it doesn't exist
create_entities_directory() {
    if [[ ! -d "$ENTITIES_DIR" ]]; then
        mkdir -p "$ENTITIES_DIR"
        echo "Created entities directory: $ENTITIES_DIR"
    fi
}

# Extract functions from a shell script
extract_functions() {
    local file_path=$1
    local output_file="$ENTITIES_DIR/functions.json"
    local file_name=$(basename "$file_path")
    local module_name="${file_name%.sh}"
    
    echo "Extracting functions from $file_path"
    
    # Initialize or load the existing functions file
    if [[ ! -f "$output_file" ]]; then
        echo "[]" > "$output_file"
    fi
    
    # Use grep to find function definitions
    # Pattern: function_name() { or function function_name {
    local functions=$(grep -n -E '(^[a-zA-Z0-9_]+\(\))|^function [a-zA-Z0-9_]+ \{' "$file_path" | sed -E 's/([0-9]+):.*(function )?([a-zA-Z0-9_]+)(\(\))? \{.*/\1:\3/')
    
    # Process each function
    while IFS=: read -r line_number function_name; do
        # Skip if empty
        [[ -z "$function_name" ]] && continue
        
        echo "Found function: $function_name at line $line_number"
        
        # Extract function description from comments above the function
        local description=""
        local start_line=$((line_number - 1))
        while [[ $start_line -gt 0 ]]; do
            local line=$(sed "${start_line}q;d" "$file_path")
            if [[ "$line" =~ ^[[:space:]]*# ]]; then
                # Remove leading # and spaces
                line=$(echo "$line" | sed -E 's/^[[:space:]]*#[[:space:]]*//')
                description="$line. $description"
                start_line=$((start_line - 1))
            else
                break
            fi
        done
        
        # Remove trailing period and space
        description=$(echo "$description" | sed -E 's/\. $//')
        
        # If no description found, use a default
        if [[ -z "$description" ]]; then
            description="Function $function_name in $file_name"
        fi
        
        # Extract function parameters
        local parameters=()
        local function_body=""
        local in_function=false
        local brace_count=0
        local end_line=$line_number
        
        # Read the file line by line to extract the function body
        while IFS= read -r line; do
            if [[ $in_function == true ]]; then
                function_body+="$line"$'\n'
                
                # Count opening and closing braces
                local open_braces=$(echo "$line" | grep -o "{" | wc -l)
                local close_braces=$(echo "$line" | grep -o "}" | wc -l)
                brace_count=$((brace_count + open_braces - close_braces))
                
                # If brace count is 0, we've reached the end of the function
                if [[ $brace_count -eq 0 ]]; then
                    break
                fi
                
                end_line=$((end_line + 1))
            elif [[ $end_line -eq $line_number ]]; then
                function_body+="$line"$'\n'
                in_function=true
                
                # Count opening braces in the first line
                local open_braces=$(echo "$line" | grep -o "{" | wc -l)
                brace_count=$open_braces
                
                end_line=$((end_line + 1))
            fi
        done < <(tail -n +$line_number "$file_path")
        
        # Extract parameters from function body
        # Look for variable references like $1, $2, etc.
        local param_refs=$(echo "$function_body" | grep -o -E '\$[0-9]+' | sort -u)
        
        # Also look for parameter validation like [[ -z "$1" ]]
        local param_validations=$(echo "$function_body" | grep -o -E '\[\[ -[a-z] "\$[0-9]+" \]\]' | grep -o -E '\$[0-9]+' | sort -u)
        
        # Combine both sets of parameters
        local all_params=$(echo -e "$param_refs\n$param_validations" | sort -u)
        
        # Convert parameters to JSON array
        local param_json="[]"
        while IFS= read -r param; do
            # Skip if empty
            [[ -z "$param" ]] && continue
            
            # Extract parameter number
            local param_num=$(echo "$param" | sed -E 's/\$([0-9]+)/\1/')
            
            # Look for parameter description in comments
            local param_desc=""
            local param_pattern="\$${param_num}"
            local param_comment=$(echo "$function_body" | grep -E "# .*${param_pattern}")
            
            if [[ -n "$param_comment" ]]; then
                param_desc=$(echo "$param_comment" | sed -E "s/.*# *(.*${param_pattern}[^:]*):? *(.*)/\2/")
            fi
            
            # If no description found, use a default
            if [[ -z "$param_desc" ]]; then
                param_desc="Parameter $param_num"
            fi
            
            # Add parameter to JSON array
            param_json=$(echo "$param_json" | jq --arg name "param$param_num" --arg desc "$param_desc" --arg type "string" --argjson required true '. + [{"name": $name, "description": $desc, "type": $type, "required": $required}]')
        done <<< "$all_params"
        
        # Extract return value
        local return_type="void"
        local return_desc="No return value"
        
        # Look for return statements
        local return_stmt=$(echo "$function_body" | grep -E 'return [^$]*\$?[a-zA-Z0-9_]+')
        
        if [[ -n "$return_stmt" ]]; then
            # Extract return value
            local return_val=$(echo "$return_stmt" | sed -E 's/.*return ([^$]*\$?[a-zA-Z0-9_]+).*/\1/')
            
            # If return value is a number, it's likely an error code
            if [[ "$return_val" =~ ^[0-9]+$ ]]; then
                return_type="integer"
                return_desc="Error code ($return_val)"
            elif [[ "$return_val" =~ ^\$ERR_ ]]; then
                return_type="integer"
                return_desc="Error code (${return_val#$})"
            else
                return_type="string"
                return_desc="Return value"
            fi
        fi
        
        # Create function entity
        local function_entity=$(cat <<EOF
{
  "@id": "llm:${module_name}_${function_name}",
  "@type": "llm:Function",
  "name": "${function_name}",
  "description": "${description}",
  "filePath": "${file_path}",
  "lineNumber": ${line_number},
  "parameters": ${param_json},
  "returnType": "${return_type}",
  "returnDescription": "${return_desc}",
  "module": "llm:${module_name}"
}
EOF
)
        
        # Add function to the output file
        local temp_file=$(mktemp)
        jq --argjson entity "$function_entity" '. + [$entity]' "$output_file" > "$temp_file" && mv "$temp_file" "$output_file"
        
        echo "Added function: $function_name"
    done <<< "$functions"
    
    echo -e "${GREEN}Extracted functions from $file_path${NC}"
}

# Extract variables from a shell script
extract_variables() {
    local file_path=$1
    local output_file="$ENTITIES_DIR/variables.json"
    local file_name=$(basename "$file_path")
    local module_name="${file_name%.sh}"
    
    echo "Extracting variables from $file_path"
    
    # Initialize or load the existing variables file
    if [[ ! -f "$output_file" ]]; then
        echo "[]" > "$output_file"
    fi
    
    # Use grep to find variable definitions
    # Pattern: VAR=value or readonly VAR=value or export VAR=value
    local variables=$(grep -n -E '^[[:space:]]*(readonly|export)?[[:space:]]*[A-Z0-9_]+=.*' "$file_path" | sed -E 's/([0-9]+):.*(readonly|export)?[[:space:]]*([A-Z0-9_]+)=.*/\1:\3/')
    
    # Process each variable
    while IFS=: read -r line_number variable_name; do
        # Skip if empty
        [[ -z "$variable_name" ]] && continue
        
        # Skip if variable name contains spaces
        [[ "$variable_name" =~ [[:space:]] ]] && continue
        
        echo "Found variable: $variable_name at line $line_number"
        
        # Extract variable description from comments above the variable
        local description=""
        local start_line=$((line_number - 1))
        while [[ $start_line -gt 0 ]]; do
            local line=$(sed "${start_line}q;d" "$file_path")
            if [[ "$line" =~ ^[[:space:]]*# ]]; then
                # Remove leading # and spaces
                line=$(echo "$line" | sed -E 's/^[[:space:]]*#[[:space:]]*//')
                description="$line. $description"
                start_line=$((start_line - 1))
            else
                break
            fi
        done
        
        # Remove trailing period and space
        description=$(echo "$description" | sed -E 's/\. $//')
        
        # If no description found, use a default
        if [[ -z "$description" ]]; then
            description="Variable $variable_name in $file_name"
        fi
        
        # Extract variable value
        local variable_line=$(sed "${line_number}q;d" "$file_path")
        local variable_value=$(echo "$variable_line" | sed -E "s/.*${variable_name}=\"?([^\"]+)\"?.*/\1/")
        
        # Determine if the variable is readonly or exported
        local is_readonly=false
        local is_exported=false
        
        if [[ "$variable_line" =~ ^[[:space:]]*readonly ]]; then
            is_readonly=true
        fi
        
        if [[ "$variable_line" =~ ^[[:space:]]*export ]]; then
            is_exported=true
        fi
        
        # Create variable entity
        local variable_entity=$(cat <<EOF
{
  "@id": "llm:${module_name}_${variable_name}",
  "@type": "llm:Variable",
  "name": "${variable_name}",
  "description": "${description}",
  "filePath": "${file_path}",
  "lineNumber": ${line_number},
  "value": "${variable_value}",
  "readonly": ${is_readonly},
  "exported": ${is_exported},
  "module": "llm:${module_name}"
}
EOF
)
        
        # Add variable to the output file
        local temp_file=$(mktemp)
        jq --argjson entity "$variable_entity" '. + [$entity]' "$output_file" > "$temp_file" && mv "$temp_file" "$output_file"
        
        echo "Added variable: $variable_name"
    done <<< "$variables"
    
    echo -e "${GREEN}Extracted variables from $file_path${NC}"
}

# Extract configuration parameters from a shell script
extract_config_params() {
    local file_path=$1
    local output_file="$ENTITIES_DIR/config_params.json"
    local file_name=$(basename "$file_path")
    local module_name="${file_name%.sh}"
    
    echo "Extracting configuration parameters from $file_path"
    
    # Initialize or load the existing config params file
    if [[ ! -f "$output_file" ]]; then
        echo "[]" > "$output_file"
    fi
    
    # Use grep to find configuration parameter references
    # Pattern: get_config "PARAM_NAME" or get_config "PARAM_NAME" "default_value"
    local config_params=$(grep -n -E 'get_config[[:space:]]*"[A-Z0-9_]+"' "$file_path" | sed -E 's/([0-9]+):.*get_config[[:space:]]*"([A-Z0-9_]+)".*/\1:\2/')
    
    # Process each configuration parameter
    while IFS=: read -r line_number param_name; do
        # Skip if empty
        [[ -z "$param_name" ]] && continue
        
        echo "Found configuration parameter: $param_name at line $line_number"
        
        # Extract parameter description from comments above the reference
        local description=""
        local start_line=$((line_number - 1))
        while [[ $start_line -gt 0 ]]; do
            local line=$(sed "${start_line}q;d" "$file_path")
            if [[ "$line" =~ ^[[:space:]]*# ]]; then
                # Remove leading # and spaces
                line=$(echo "$line" | sed -E 's/^[[:space:]]*#[[:space:]]*//')
                description="$line. $description"
                start_line=$((start_line - 1))
            else
                break
            fi
        done
        
        # Remove trailing period and space
        description=$(echo "$description" | sed -E 's/\. $//')
        
        # If no description found, use a default
        if [[ -z "$description" ]]; then
            description="Configuration parameter $param_name"
        fi
        
        # Extract default value if present
        local param_line=$(sed "${line_number}q;d" "$file_path")
        local default_value=""
        
        if [[ "$param_line" =~ get_config[[:space:]]*\"${param_name}\"[[:space:]]*\"([^\"]+)\" ]]; then
            default_value="${BASH_REMATCH[1]}"
        fi
        
        # Create config parameter entity
        local param_entity=$(cat <<EOF
{
  "@id": "llm:config_${param_name}",
  "@type": "llm:ConfigParam",
  "name": "${param_name}",
  "description": "${description}",
  "filePath": "${file_path}",
  "lineNumber": ${line_number},
  "defaultValue": "${default_value}"
}
EOF
)
        
        # Add config parameter to the output file
        local temp_file=$(mktemp)
        jq --argjson entity "$param_entity" '. + [$entity]' "$output_file" > "$temp_file" && mv "$temp_file" "$output_file"
        
        echo "Added configuration parameter: $param_name"
    done <<< "$config_params"
    
    echo -e "${GREEN}Extracted configuration parameters from $file_path${NC}"
}

# Extract components from YAML documentation
extract_components() {
    local components_file="$ROOT_DIR/docs/system/components.yaml"
    local output_file="$ENTITIES_DIR/components.json"
    
    echo "Extracting components from $components_file"
    
    # Check if the components file exists
    if [[ ! -f "$components_file" ]]; then
        echo -e "${YELLOW}Warning: Components file not found: $components_file${NC}"
        return 1
    fi
    
    # Initialize the components file
    echo "[]" > "$output_file"
    
    # Use grep and sed to extract component information
    local component_blocks=$(grep -n -A 1000 "^  - type:" "$components_file" | sed -n '/^  - type:/,/^  -/p')
    
    # Split the blocks
    local IFS=$'\n'
    local blocks=()
    local current_block=""
    
    for line in $component_blocks; do
        if [[ "$line" =~ ^[[:space:]]*- ]]; then
            if [[ -n "$current_block" ]]; then
                blocks+=("$current_block")
                current_block=""
            fi
        fi
        current_block+="$line"$'\n'
    done
    
    # Add the last block
    if [[ -n "$current_block" ]]; then
        blocks+=("$current_block")
    fi
    
    # Process each component block
    for block in "${blocks[@]}"; do
        # Extract component type
        local type=$(echo "$block" | grep -E "^  - type:" | sed -E 's/^  - type:[[:space:]]*"?([^"]+)"?.*/\1/')
        
        # Skip if type is empty
        [[ -z "$type" ]] && continue
        
        # Extract component name
        local name=$(echo "$block" | grep -E "^    name:" | sed -E 's/^    name:[[:space:]]*"?([^"]+)"?.*/\1/')
        
        # Skip if name is empty
        [[ -z "$name" ]] && continue
        
        # Extract component purpose
        local purpose=$(echo "$block" | grep -E "^    purpose:" | sed -E 's/^    purpose:[[:space:]]*"?([^"]+)"?.*/\1/')
        
        # Skip if purpose is empty
        [[ -z "$purpose" ]] && continue
        
        echo "Found component: $name (type: $type)"
        
        # Create component entity
        local component_entity=$(cat <<EOF
{
  "@id": "llm:${name}",
  "@type": "llm:${type^}",
  "name": "${name}",
  "description": "${purpose}"
}
EOF
)
        
        # Add component to the output file
        local temp_file=$(mktemp)
        jq --argjson entity "$component_entity" '. + [$entity]' "$output_file" > "$temp_file" && mv "$temp_file" "$output_file"
        
        echo "Added component: $name"
    done
    
    echo -e "${GREEN}Extracted components from $components_file${NC}"
}

# Extract services from YAML documentation
extract_services() {
    local relationships_file="$ROOT_DIR/docs/system/relationships.yaml"
    local output_file="$ENTITIES_DIR/services.json"
    
    echo "Extracting services from $relationships_file"
    
    # Check if the relationships file exists
    if [[ ! -f "$relationships_file" ]]; then
        echo -e "${YELLOW}Warning: Relationships file not found: $relationships_file${NC}"
        return 1
    fi
    
    # Initialize the services file
    echo "[]" > "$output_file"
    
    # Use grep and sed to extract service information
    local service_blocks=$(grep -n -A 10 "^  - source:" "$relationships_file" | grep -E "type: \"?provides_service_to\"?" -A 10 -B 10)
    
    # Process each service block
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*- ]]; then
            # Extract source (service provider)
            local source=$(echo "$line" | grep -E "source:" | sed -E 's/^[[:space:]]*source:[[:space:]]*"?([^"]+)"?.*/\1/')
            
            # Skip if source is empty
            [[ -z "$source" ]] && continue
            
            # Extract target (service consumer)
            local target=$(echo "$line" | grep -E "target:" | sed -E 's/^[[:space:]]*target:[[:space:]]*"?([^"]+)"?.*/\1/')
            
            # Skip if target is empty
            [[ -z "$target" ]] && continue
            
            # Extract description
            local description=$(echo "$line" | grep -E "description:" | sed -E 's/^[[:space:]]*description:[[:space:]]*"?([^"]+)"?.*/\1/')
            
            # Skip if description is empty
            [[ -z "$description" ]] && continue
            
            # Extract interface
            local interface=$(echo "$line" | grep -E "interface:" | sed -E 's/^[[:space:]]*interface:[[:space:]]*"?([^"]+)"?.*/\1/')
            
            # Skip if interface is empty
            [[ -z "$interface" ]] && continue
            
            echo "Found service: $source provides service to $target"
            
            # Create service entity
            local service_entity=$(cat <<EOF
{
  "@id": "llm:service_${source}_${target}",
  "@type": "llm:Service",
  "name": "${source}_${target}_service",
  "description": "${description}",
  "provider": "llm:${source}",
  "consumer": "llm:${target}",
  "interface": "${interface}"
}
EOF
)
            
            # Add service to the output file
            local temp_file=$(mktemp)
            jq --argjson entity "$service_entity" '. + [$entity]' "$output_file" > "$temp_file" && mv "$temp_file" "$output_file"
            
            echo "Added service: ${source}_${target}_service"
        fi
    done <<< "$service_blocks"
    
    echo -e "${GREEN}Extracted services from $relationships_file${NC}"
}

# Main function to extract all entities
extract_all_entities() {
    echo "Starting entity extraction..."
    
    # Check dependencies
    check_dependencies
    
    # Create the entities directory
    create_entities_directory
    
    # Extract components from YAML documentation
    extract_components
    
    # Extract services from YAML documentation
    extract_services
    
    # Extract entities from shell scripts
    local shell_scripts=$(find "$ROOT_DIR" -name "*.sh" -type f)
    
    for script in $shell_scripts; do
        # Extract functions
        extract_functions "$script"
        
        # Extract variables
        extract_variables "$script"
        
        # Extract configuration parameters
        extract_config_params "$script"
    done
    
    echo -e "${GREEN}Entity extraction completed successfully!${NC}"
    return 0
}

# Run the main function
extract_all_entities