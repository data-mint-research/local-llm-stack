#!/bin/bash
# map-relationships.sh - Map relationships between entities
# This script identifies function call dependencies, component interactions, and configuration dependencies

# Get the absolute path of the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Input and output directories
ENTITIES_DIR="$ROOT_DIR/docs/knowledge-graph/entities"
RELATIONSHIPS_DIR="$ROOT_DIR/docs/knowledge-graph/relationships"

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

# Create the relationships directory if it doesn't exist
create_relationships_directory() {
    if [[ ! -d "$RELATIONSHIPS_DIR" ]]; then
        mkdir -p "$RELATIONSHIPS_DIR"
        echo "Created relationships directory: $RELATIONSHIPS_DIR"
    fi
}

# Map function call dependencies
map_function_calls() {
    local output_file="$RELATIONSHIPS_DIR/function_calls.json"
    
    echo "Mapping function call dependencies..."
    
    # Initialize the function calls file
    echo "[]" > "$output_file"
    
    # Load functions from entities
    local functions_file="$ENTITIES_DIR/functions.json"
    
    if [[ ! -f "$functions_file" ]]; then
        echo -e "${YELLOW}Warning: Functions file not found: $functions_file${NC}"
        return 1
    fi
    
    # Get all function names
    local function_names=$(jq -r '.[].name' "$functions_file")
    
    # For each function, find calls to other functions
    for function_name in $function_names; do
        # Get function details
        local function_details=$(jq --arg name "$function_name" '.[] | select(.name == $name)' "$functions_file")
        local function_id=$(echo "$function_details" | jq -r '."@id"')
        local file_path=$(echo "$function_details" | jq -r '.filePath')
        local line_number=$(echo "$function_details" | jq -r '.lineNumber')
        
        echo "Analyzing function calls for: $function_name"
        
        # Extract function body
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
        
        # For each other function, check if it's called in this function
        for called_function in $function_names; do
            # Skip self-calls
            [[ "$called_function" == "$function_name" ]] && continue
            
            # Check if the function is called
            if [[ "$function_body" =~ $called_function[[:space:]]*\( ]]; then
                echo "Found call from $function_name to $called_function"
                
                # Get called function details
                local called_function_details=$(jq --arg name "$called_function" '.[] | select(.name == $name)' "$functions_file")
                local called_function_id=$(echo "$called_function_details" | jq -r '."@id"')
                
                # Create function call relationship
                local call_relationship=$(cat <<EOF
{
  "@id": "llm:call_${function_name}_${called_function}",
  "@type": "llm:Calls",
  "name": "${function_name}_calls_${called_function}",
  "description": "Function ${function_name} calls function ${called_function}",
  "source": "${function_id}",
  "target": "${called_function_id}"
}
EOF
)
                
                # Add function call to the output file
                local temp_file=$(mktemp)
                jq --argjson relationship "$call_relationship" '. + [$relationship]' "$output_file" > "$temp_file" && mv "$temp_file" "$output_file"
                
                echo "Added function call: ${function_name} -> ${called_function}"
            fi
        done
    done
    
    echo -e "${GREEN}Mapped function call dependencies${NC}"
}

# Map component dependencies from YAML documentation
map_component_dependencies() {
    local relationships_file="$ROOT_DIR/docs/system/relationships.yaml"
    local output_file="$RELATIONSHIPS_DIR/component_dependencies.json"
    
    echo "Mapping component dependencies..."
    
    # Check if the relationships file exists
    if [[ ! -f "$relationships_file" ]]; then
        echo -e "${YELLOW}Warning: Relationships file not found: $relationships_file${NC}"
        return 1
    fi
    
    # Initialize the component dependencies file
    echo "[]" > "$output_file"
    
    # Use grep and sed to extract dependency information
    local dependency_blocks=$(grep -n -A 10 "^  - source:" "$relationships_file" | grep -E "type: \"?depends_on\"?" -A 10 -B 10)
    
    # Process each dependency block
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*- ]]; then
            # Extract source (dependent)
            local source=$(echo "$line" | grep -E "source:" | sed -E 's/^[[:space:]]*source:[[:space:]]*"?([^"]+)"?.*/\1/')
            
            # Skip if source is empty
            [[ -z "$source" ]] && continue
            
            # Extract target (dependency)
            local target=$(echo "$line" | grep -E "target:" | sed -E 's/^[[:space:]]*target:[[:space:]]*"?([^"]+)"?.*/\1/')
            
            # Skip if target is empty
            [[ -z "$target" ]] && continue
            
            # Extract description
            local description=$(echo "$line" | grep -E "description:" | sed -E 's/^[[:space:]]*description:[[:space:]]*"?([^"]+)"?.*/\1/')
            
            # Skip if description is empty
            [[ -z "$description" ]] && continue
            
            echo "Found dependency: $source depends on $target"
            
            # Create dependency relationship
            local dependency_relationship=$(cat <<EOF
{
  "@id": "llm:dependency_${source}_${target}",
  "@type": "llm:DependsOn",
  "name": "${source}_depends_on_${target}",
  "description": "${description}",
  "source": "llm:${source}",
  "target": "llm:${target}"
}
EOF
)
            
            # Add dependency to the output file
            local temp_file=$(mktemp)
            jq --argjson relationship "$dependency_relationship" '. + [$relationship]' "$output_file" > "$temp_file" && mv "$temp_file" "$output_file"
            
            echo "Added dependency: ${source} -> ${target}"
        fi
    done <<< "$dependency_blocks"
    
    echo -e "${GREEN}Mapped component dependencies${NC}"
}

# Map configuration dependencies
map_config_dependencies() {
    local output_file="$RELATIONSHIPS_DIR/config_dependencies.json"
    
    echo "Mapping configuration dependencies..."
    
    # Initialize the config dependencies file
    echo "[]" > "$output_file"
    
    # Load functions from entities
    local functions_file="$ENTITIES_DIR/functions.json"
    local config_params_file="$ENTITIES_DIR/config_params.json"
    
    if [[ ! -f "$functions_file" ]]; then
        echo -e "${YELLOW}Warning: Functions file not found: $functions_file${NC}"
        return 1
    fi
    
    if [[ ! -f "$config_params_file" ]]; then
        echo -e "${YELLOW}Warning: Config parameters file not found: $config_params_file${NC}"
        return 1
    fi
    
    # Get all function names and IDs
    local function_data=$(jq -r '.[] | .name + ":" + ."@id" + ":" + .filePath' "$functions_file")
    
    # Get all config parameter names and IDs
    local config_param_data=$(jq -r '.[] | .name + ":" + ."@id"' "$config_params_file")
    
    # For each function, find references to config parameters
    while IFS=: read -r function_name function_id file_path; do
        # Skip if empty
        [[ -z "$function_name" ]] && continue
        
        echo "Analyzing config dependencies for function: $function_name"
        
        # For each config parameter, check if it's referenced in the function
        while IFS=: read -r param_name param_id; do
            # Skip if empty
            [[ -z "$param_name" ]] && continue
            
            # Check if the parameter is referenced in the function
            local grep_result=$(grep -n "$param_name" "$file_path" | grep -E "get_config.*\"$param_name\"")
            
            if [[ -n "$grep_result" ]]; then
                echo "Found config dependency: $function_name uses $param_name"
                
                # Create config dependency relationship
                local config_dependency=$(cat <<EOF
{
  "@id": "llm:config_dependency_${function_name}_${param_name}",
  "@type": "llm:Configures",
  "name": "${function_name}_uses_${param_name}",
  "description": "Function ${function_name} uses configuration parameter ${param_name}",
  "source": "${function_id}",
  "target": "${param_id}"
}
EOF
)
                
                # Add config dependency to the output file
                local temp_file=$(mktemp)
                jq --argjson relationship "$config_dependency" '. + [$relationship]' "$output_file" > "$temp_file" && mv "$temp_file" "$output_file"
                
                echo "Added config dependency: ${function_name} -> ${param_name}"
            fi
        done <<< "$config_param_data"
    done <<< "$function_data"
    
    echo -e "${GREEN}Mapped configuration dependencies${NC}"
}

# Map import relationships
map_imports() {
    local output_file="$RELATIONSHIPS_DIR/imports.json"
    
    echo "Mapping import relationships..."
    
    # Initialize the imports file
    echo "[]" > "$output_file"
    
    # Find all shell scripts
    local shell_scripts=$(find "$ROOT_DIR" -name "*.sh" -type f)
    
    # Process each script
    for script in $shell_scripts; do
        local script_name=$(basename "$script")
        local module_name="${script_name%.sh}"
        
        echo "Analyzing imports for script: $script_name"
        
        # Find source statements
        local imports=$(grep -n -E "^[[:space:]]*source[[:space:]]+\"?[^\"]+\"?" "$script" | sed -E 's/([0-9]+):.*source[[:space:]]+\"?([^\"]+)\"?.*/\1:\2/')
        
        # Process each import
        while IFS=: read -r line_number import_path; do
            # Skip if empty
            [[ -z "$import_path" ]] && continue
            
            # Normalize the import path
            import_path=$(echo "$import_path" | sed -E 's/\$[A-Z_]+\///')
            
            # Extract the imported module name
            local imported_module=$(basename "$import_path")
            imported_module="${imported_module%.sh}"
            
            echo "Found import: $module_name imports $imported_module"
            
            # Create import relationship
            local import_relationship=$(cat <<EOF
{
  "@id": "llm:import_${module_name}_${imported_module}",
  "@type": "llm:Imports",
  "name": "${module_name}_imports_${imported_module}",
  "description": "Module ${module_name} imports module ${imported_module}",
  "source": "llm:${module_name}",
  "target": "llm:${imported_module}",
  "filePath": "${script}",
  "lineNumber": ${line_number}
}
EOF
)
            
            # Add import to the output file
            local temp_file=$(mktemp)
            jq --argjson relationship "$import_relationship" '. + [$relationship]' "$output_file" > "$temp_file" && mv "$temp_file" "$output_file"
            
            echo "Added import: ${module_name} -> ${imported_module}"
        done <<< "$imports"
    done
    
    echo -e "${GREEN}Mapped import relationships${NC}"
}

# Map data flow relationships from YAML documentation
map_data_flows() {
    local interfaces_file="$ROOT_DIR/docs/system/interfaces.yaml"
    local output_file="$RELATIONSHIPS_DIR/data_flows.json"
    
    echo "Mapping data flow relationships..."
    
    # Check if the interfaces file exists
    if [[ ! -f "$interfaces_file" ]]; then
        echo -e "${YELLOW}Warning: Interfaces file not found: $interfaces_file${NC}"
        return 1
    fi
    
    # Initialize the data flows file
    echo "[]" > "$output_file"
    
    # Use grep and sed to extract data flow information
    local data_flow_blocks=$(grep -n -A 1000 "^data_flows:" "$interfaces_file" | sed -n '/^data_flows:/,/^[a-z_]*:/p')
    
    # Extract data flow names
    local data_flow_names=$(echo "$data_flow_blocks" | grep -E "^  - name:" | sed -E 's/^  - name:[[:space:]]*"?([^"]+)"?.*/\1/')
    
    # Process each data flow
    for flow_name in $data_flow_names; do
        echo "Processing data flow: $flow_name"
        
        # Extract data flow description
        local flow_description=$(echo "$data_flow_blocks" | grep -A 1 "^  - name: $flow_name" | grep -E "^    description:" | sed -E 's/^    description:[[:space:]]*"?([^"]+)"?.*/\1/')
        
        # Extract steps for this data flow
        local flow_steps=$(echo "$data_flow_blocks" | grep -A 1000 "^  - name: $flow_name" | sed -n '/^    steps:/,/^  -/p')
        
        # Extract step information
        local step_numbers=$(echo "$flow_steps" | grep -E "^      - step:" | sed -E 's/^      - step:[[:space:]]*([0-9]+).*/\1/')
        
        # Process each step
        for step_num in $step_numbers; do
            # Extract step details
            local step_block=$(echo "$flow_steps" | grep -A 10 "^      - step: $step_num")
            
            # Extract source and target
            local source=$(echo "$step_block" | grep -E "^        source:" | sed -E 's/^        source:[[:space:]]*"?([^"]+)"?.*/\1/')
            local target=$(echo "$step_block" | grep -E "^        target:" | sed -E 's/^        target:[[:space:]]*"?([^"]+)"?.*/\1/')
            
            # Skip if source or target is empty
            [[ -z "$source" || -z "$target" ]] && continue
            
            # Extract data, format, and transport
            local data=$(echo "$step_block" | grep -E "^        data:" | sed -E 's/^        data:[[:space:]]*"?([^"]+)"?.*/\1/')
            local format=$(echo "$step_block" | grep -E "^        format:" | sed -E 's/^        format:[[:space:]]*"?([^"]+)"?.*/\1/')
            local transport=$(echo "$step_block" | grep -E "^        transport:" | sed -E 's/^        transport:[[:space:]]*"?([^"]+)"?.*/\1/')
            
            echo "Found data flow step: $source -> $target (data: $data)"
            
            # Create data flow relationship
            local data_flow_relationship=$(cat <<EOF
{
  "@id": "llm:dataflow_${flow_name}_step_${step_num}",
  "@type": "llm:DataFlow",
  "name": "${flow_name}_step_${step_num}",
  "description": "${source} sends ${data} to ${target}",
  "source": "llm:${source}",
  "target": "llm:${target}",
  "data": "${data}",
  "format": "${format}",
  "transport": "${transport}",
  "stepNumber": ${step_num},
  "dataFlow": "llm:dataflow_${flow_name}"
}
EOF
)
            
            # Add data flow to the output file
            local temp_file=$(mktemp)
            jq --argjson relationship "$data_flow_relationship" '. + [$relationship]' "$output_file" > "$temp_file" && mv "$temp_file" "$output_file"
            
            echo "Added data flow: ${source} -> ${target} (step ${step_num})"
        done
    done
    
    echo -e "${GREEN}Mapped data flow relationships${NC}"
}

# Map all relationships
map_all_relationships() {
    echo "Starting relationship mapping..."
    
    # Check dependencies
    check_dependencies
    
    # Create the relationships directory
    create_relationships_directory
    
    # Map function call dependencies
    map_function_calls
    
    # Map component dependencies
    map_component_dependencies
    
    # Map configuration dependencies
    map_config_dependencies
    
    # Map import relationships
    map_imports
    
    # Map data flow relationships
    map_data_flows
    
    echo -e "${GREEN}Relationship mapping completed successfully!${NC}"
    return 0
}

# Run the main function
map_all_relationships