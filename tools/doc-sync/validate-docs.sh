#!/bin/bash
# validate-docs.sh - Validate documentation files against schema
# This script validates the YAML documentation files against their schemas

# Get the absolute path of the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Documentation files
COMPONENTS_FILE="$ROOT_DIR/docs/system/components.yaml"
RELATIONSHIPS_FILE="$ROOT_DIR/docs/system/relationships.yaml"
INTERFACES_FILE="$ROOT_DIR/docs/system/interfaces.yaml"
SCHEMA_FILE="$ROOT_DIR/docs/schema/system-schema.yaml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Check if yq is installed
check_dependencies() {
    if ! command -v yq &> /dev/null; then
        echo -e "${RED}Error: yq is not installed. Please install it to validate YAML files.${NC}"
        echo "You can install it with: sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && sudo chmod +x /usr/local/bin/yq"
        exit 1
    fi
}

# Validate a YAML file
validate_yaml() {
    local file="$1"
    
    # Check if file exists
    if [[ ! -f "$file" ]]; then
        echo -e "${RED}Error: File not found: $file${NC}"
        return 1
    fi
    
    # Check if file is valid YAML
    if ! yq eval '.' "$file" > /dev/null 2>&1; then
        echo -e "${RED}Error: Invalid YAML in $file${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✓ $file is valid YAML${NC}"
    return 0
}

# Validate components file against schema
validate_components() {
    local file="$COMPONENTS_FILE"
    
    echo "Validating components file: $file"
    
    # Check if file exists and is valid YAML
    if ! validate_yaml "$file"; then
        return 1
    fi
    
    # Check if components section exists
    if ! yq eval '.components' "$file" > /dev/null 2>&1; then
        echo -e "${RED}Error: Missing 'components' section in $file${NC}"
        return 1
    fi
    
    # Check each component
    local component_count=$(yq eval '.components | length' "$file")
    echo "Found $component_count components"
    
    for ((i=0; i<component_count; i++)); do
        local name=$(yq eval ".components[$i].name" "$file")
        local type=$(yq eval ".components[$i].type" "$file")
        local purpose=$(yq eval ".components[$i].purpose" "$file")
        
        # Check required fields
        if [[ -z "$name" || "$name" == "null" ]]; then
            echo -e "${RED}Error: Component #$i is missing 'name' field${NC}"
            return 1
        fi
        
        if [[ -z "$type" || "$type" == "null" ]]; then
            echo -e "${RED}Error: Component '$name' is missing 'type' field${NC}"
            return 1
        fi
        
        if [[ -z "$purpose" || "$purpose" == "null" ]]; then
            echo -e "${RED}Error: Component '$name' is missing 'purpose' field${NC}"
            return 1
        fi
        
        # Check type is valid
        if [[ ! "$type" =~ ^(container|script|library|module)$ ]]; then
            echo -e "${YELLOW}Warning: Component '$name' has invalid type: $type. Should be one of: container, script, library, module${NC}"
        fi
        
        echo -e "${GREEN}✓ Component '$name' ($type) is valid${NC}"
    done
    
    echo -e "${GREEN}✓ Components validation passed${NC}"
    return 0
}

# Validate relationships file against schema
validate_relationships() {
    local file="$RELATIONSHIPS_FILE"
    
    echo "Validating relationships file: $file"
    
    # Check if file exists and is valid YAML
    if ! validate_yaml "$file"; then
        return 1
    fi
    
    # Check if relationships section exists
    if ! yq eval '.relationships' "$file" > /dev/null 2>&1; then
        echo -e "${RED}Error: Missing 'relationships' section in $file${NC}"
        return 1
    fi
    
    # Check each relationship
    local relationship_count=$(yq eval '.relationships | length' "$file")
    echo "Found $relationship_count relationships"
    
    for ((i=0; i<relationship_count; i++)); do
        local source=$(yq eval ".relationships[$i].source" "$file")
        local target=$(yq eval ".relationships[$i].target" "$file")
        local type=$(yq eval ".relationships[$i].type" "$file")
        local description=$(yq eval ".relationships[$i].description" "$file")
        
        # Check required fields
        if [[ -z "$source" || "$source" == "null" ]]; then
            echo -e "${RED}Error: Relationship #$i is missing 'source' field${NC}"
            return 1
        fi
        
        if [[ -z "$target" || "$target" == "null" ]]; then
            echo -e "${RED}Error: Relationship from '$source' is missing 'target' field${NC}"
            return 1
        fi
        
        if [[ -z "$type" || "$type" == "null" ]]; then
            echo -e "${RED}Error: Relationship from '$source' to '$target' is missing 'type' field${NC}"
            return 1
        fi
        
        if [[ -z "$description" || "$description" == "null" ]]; then
            echo -e "${RED}Error: Relationship from '$source' to '$target' is missing 'description' field${NC}"
            return 1
        fi
        
        # Check type is valid
        if [[ ! "$type" =~ ^(depends_on|provides_service_to|startup_dependency|runtime_dependency|configuration_dependency)$ ]]; then
            echo -e "${YELLOW}Warning: Relationship from '$source' to '$target' has invalid type: $type${NC}"
        fi
        
        echo -e "${GREEN}✓ Relationship from '$source' to '$target' ($type) is valid${NC}"
    done
    
    echo -e "${GREEN}✓ Relationships validation passed${NC}"
    return 0
}

# Validate interfaces file against schema
validate_interfaces() {
    local file="$INTERFACES_FILE"
    
    echo "Validating interfaces file: $file"
    
    # Check if file exists and is valid YAML
    if ! validate_yaml "$file"; then
        return 1
    fi
    
    # Check API interfaces
    if yq eval '.api_interfaces' "$file" > /dev/null 2>&1; then
        local api_count=$(yq eval '.api_interfaces | length' "$file")
        echo "Found $api_count API interfaces"
        
        for ((i=0; i<api_count; i++)); do
            local component=$(yq eval ".api_interfaces[$i].component" "$file")
            local interface_type=$(yq eval ".api_interfaces[$i].interface_type" "$file")
            local base_url=$(yq eval ".api_interfaces[$i].base_url" "$file")
            
            # Check required fields
            if [[ -z "$component" || "$component" == "null" ]]; then
                echo -e "${RED}Error: API interface #$i is missing 'component' field${NC}"
                return 1
            fi
            
            if [[ -z "$interface_type" || "$interface_type" == "null" ]]; then
                echo -e "${RED}Error: API interface for '$component' is missing 'interface_type' field${NC}"
                return 1
            fi
            
            if [[ -z "$base_url" || "$base_url" == "null" ]]; then
                echo -e "${RED}Error: API interface for '$component' is missing 'base_url' field${NC}"
                return 1
            fi
            
            # Check endpoints
            if yq eval ".api_interfaces[$i].endpoints" "$file" > /dev/null 2>&1; then
                local endpoint_count=$(yq eval ".api_interfaces[$i].endpoints | length" "$file")
                echo "Found $endpoint_count endpoints for '$component'"
                
                for ((j=0; j<endpoint_count; j++)); do
                    local path=$(yq eval ".api_interfaces[$i].endpoints[$j].path" "$file")
                    local method=$(yq eval ".api_interfaces[$i].endpoints[$j].method" "$file")
                    local description=$(yq eval ".api_interfaces[$i].endpoints[$j].description" "$file")
                    
                    # Check required fields
                    if [[ -z "$path" || "$path" == "null" ]]; then
                        echo -e "${RED}Error: Endpoint #$j for '$component' is missing 'path' field${NC}"
                        return 1
                    fi
                    
                    if [[ -z "$method" || "$method" == "null" ]]; then
                        echo -e "${RED}Error: Endpoint '$path' for '$component' is missing 'method' field${NC}"
                        return 1
                    fi
                    
                    if [[ -z "$description" || "$description" == "null" ]]; then
                        echo -e "${RED}Error: Endpoint '$path' for '$component' is missing 'description' field${NC}"
                        return 1
                    fi
                    
                    echo -e "${GREEN}✓ Endpoint '$path' for '$component' is valid${NC}"
                done
            else
                echo -e "${YELLOW}Warning: API interface for '$component' has no endpoints${NC}"
            fi
            
            echo -e "${GREEN}✓ API interface for '$component' is valid${NC}"
        done
    fi
    
    # Check CLI interfaces
    if yq eval '.cli_interfaces' "$file" > /dev/null 2>&1; then
        local cli_count=$(yq eval '.cli_interfaces | length' "$file")
        echo "Found $cli_count CLI interfaces"
        
        for ((i=0; i<cli_count; i++)); do
            local component=$(yq eval ".cli_interfaces[$i].component" "$file")
            
            # Check required fields
            if [[ -z "$component" || "$component" == "null" ]]; then
                echo -e "${RED}Error: CLI interface #$i is missing 'component' field${NC}"
                return 1
            fi
            
            # Check commands
            if yq eval ".cli_interfaces[$i].commands" "$file" > /dev/null 2>&1; then
                local command_count=$(yq eval ".cli_interfaces[$i].commands | length" "$file")
                echo "Found $command_count commands for '$component'"
                
                for ((j=0; j<command_count; j++)); do
                    local name=$(yq eval ".cli_interfaces[$i].commands[$j].name" "$file")
                    local description=$(yq eval ".cli_interfaces[$i].commands[$j].description" "$file")
                    
                    # Check required fields
                    if [[ -z "$name" || "$name" == "null" ]]; then
                        echo -e "${RED}Error: Command #$j for '$component' is missing 'name' field${NC}"
                        return 1
                    fi
                    
                    if [[ -z "$description" || "$description" == "null" ]]; then
                        echo -e "${RED}Error: Command '$name' for '$component' is missing 'description' field${NC}"
                        return 1
                    fi
                    
                    echo -e "${GREEN}✓ Command '$name' for '$component' is valid${NC}"
                done
            else
                echo -e "${YELLOW}Warning: CLI interface for '$component' has no commands${NC}"
            fi
            
            echo -e "${GREEN}✓ CLI interface for '$component' is valid${NC}"
        done
    fi
    
    # Check shell functions
    if yq eval '.shell_functions' "$file" > /dev/null 2>&1; then
        local shell_count=$(yq eval '.shell_functions | length' "$file")
        echo "Found $shell_count shell function files"
        
        for ((i=0; i<shell_count; i++)); do
            local file_path=$(yq eval ".shell_functions[$i].file" "$file")
            
            # Check required fields
            if [[ -z "$file_path" || "$file_path" == "null" ]]; then
                echo -e "${RED}Error: Shell function file #$i is missing 'file' field${NC}"
                return 1
            fi
            
            # Check functions
            if yq eval ".shell_functions[$i].functions" "$file" > /dev/null 2>&1; then
                local function_count=$(yq eval ".shell_functions[$i].functions | length" "$file")
                echo "Found $function_count functions in '$file_path'"
                
                for ((j=0; j<function_count; j++)); do
                    local name=$(yq eval ".shell_functions[$i].functions[$j].name" "$file")
                    local description=$(yq eval ".shell_functions[$i].functions[$j].description" "$file")
                    
                    # Check required fields
                    if [[ -z "$name" || "$name" == "null" ]]; then
                        echo -e "${RED}Error: Function #$j in '$file_path' is missing 'name' field${NC}"
                        return 1
                    fi
                    
                    if [[ -z "$description" || "$description" == "null" ]]; then
                        echo -e "${RED}Error: Function '$name' in '$file_path' is missing 'description' field${NC}"
                        return 1
                    fi
                    
                    echo -e "${GREEN}✓ Function '$name' in '$file_path' is valid${NC}"
                done
            else
                echo -e "${YELLOW}Warning: Shell function file '$file_path' has no functions${NC}"
            fi
            
            echo -e "${GREEN}✓ Shell function file '$file_path' is valid${NC}"
        done
    fi
    
    # Check data flows
    if yq eval '.data_flows' "$file" > /dev/null 2>&1; then
        local flow_count=$(yq eval '.data_flows | length' "$file")
        echo "Found $flow_count data flows"
        
        for ((i=0; i<flow_count; i++)); do
            local name=$(yq eval ".data_flows[$i].name" "$file")
            local description=$(yq eval ".data_flows[$i].description" "$file")
            
            # Check required fields
            if [[ -z "$name" || "$name" == "null" ]]; then
                echo -e "${RED}Error: Data flow #$i is missing 'name' field${NC}"
                return 1
            fi
            
            if [[ -z "$description" || "$description" == "null" ]]; then
                echo -e "${RED}Error: Data flow '$name' is missing 'description' field${NC}"
                return 1
            fi
            
            # Check steps
            if yq eval ".data_flows[$i].steps" "$file" > /dev/null 2>&1; then
                local step_count=$(yq eval ".data_flows[$i].steps | length" "$file")
                echo "Found $step_count steps in data flow '$name'"
                
                for ((j=0; j<step_count; j++)); do
                    local step=$(yq eval ".data_flows[$i].steps[$j].step" "$file")
                    local source=$(yq eval ".data_flows[$i].steps[$j].source" "$file")
                    local target=$(yq eval ".data_flows[$i].steps[$j].target" "$file")
                    local data=$(yq eval ".data_flows[$i].steps[$j].data" "$file")
                    
                    # Check required fields
                    if [[ -z "$step" || "$step" == "null" ]]; then
                        echo -e "${RED}Error: Step #$j in data flow '$name' is missing 'step' field${NC}"
                        return 1
                    fi
                    
                    if [[ -z "$source" || "$source" == "null" ]]; then
                        echo -e "${RED}Error: Step $step in data flow '$name' is missing 'source' field${NC}"
                        return 1
                    fi
                    
                    if [[ -z "$target" || "$target" == "null" ]]; then
                        echo -e "${RED}Error: Step $step in data flow '$name' is missing 'target' field${NC}"
                        return 1
                    fi
                    
                    if [[ -z "$data" || "$data" == "null" ]]; then
                        echo -e "${RED}Error: Step $step in data flow '$name' is missing 'data' field${NC}"
                        return 1
                    fi
                    
                    echo -e "${GREEN}✓ Step $step in data flow '$name' is valid${NC}"
                done
            else
                echo -e "${YELLOW}Warning: Data flow '$name' has no steps${NC}"
            fi
            
            echo -e "${GREEN}✓ Data flow '$name' is valid${NC}"
        done
    fi
    
    echo -e "${GREEN}✓ Interfaces validation passed${NC}"
    return 0
}

# Check for cross-references
validate_cross_references() {
    echo "Validating cross-references between files"
    
    # Get all component names
    local components=()
    local component_count=$(yq eval '.components | length' "$COMPONENTS_FILE")
    
    for ((i=0; i<component_count; i++)); do
        local name=$(yq eval ".components[$i].name" "$COMPONENTS_FILE")
        components+=("$name")
    done
    
    # Check relationships reference valid components
    local relationship_count=$(yq eval '.relationships | length' "$RELATIONSHIPS_FILE")
    
    for ((i=0; i<relationship_count; i++)); do
        local source=$(yq eval ".relationships[$i].source" "$RELATIONSHIPS_FILE")
        local target=$(yq eval ".relationships[$i].target" "$RELATIONSHIPS_FILE")
        local type=$(yq eval ".relationships[$i].type" "$RELATIONSHIPS_FILE")
        
        # Skip network and configuration dependencies
        if [[ "$target" == *"network"* || "$target" == *"config"* || "$target" == *".env"* || "$target" == *".yaml"* || "$target" == *".yml"* ]]; then
            continue
        fi
        
        # Skip external dependencies
        if [[ "$target" == "docker" || "$target" == "docker-compose" ]]; then
            continue
        fi
        
        # Check source component exists
        local source_exists=false
        for component in "${components[@]}"; do
            if [[ "$source" == "$component" ]]; then
                source_exists=true
                break
            fi
        done
        
        if [[ "$source_exists" == false ]]; then
            echo -e "${YELLOW}Warning: Relationship #$i references source component '$source' which is not documented${NC}"
        fi
        
        # Check target component exists
        local target_exists=false
        for component in "${components[@]}"; do
            if [[ "$target" == "$component" ]]; then
                target_exists=true
                break
            fi
        done
        
        if [[ "$target_exists" == false ]]; then
            echo -e "${YELLOW}Warning: Relationship #$i references target component '$target' which is not documented${NC}"
        fi
    done
    
    echo -e "${GREEN}✓ Cross-reference validation passed${NC}"
    return 0
}

# Main function
main() {
    echo "Starting documentation validation..."
    
    # Check dependencies
    check_dependencies
    
    # Validate each file
    validate_components
    local components_valid=$?
    
    validate_relationships
    local relationships_valid=$?
    
    validate_interfaces
    local interfaces_valid=$?
    
    # Validate cross-references if all files are valid
    if [[ $components_valid -eq 0 && $relationships_valid -eq 0 && $interfaces_valid -eq 0 ]]; then
        validate_cross_references
        local cross_references_valid=$?
    else
        local cross_references_valid=1
    fi
    
    # Check overall validation result
    if [[ $components_valid -eq 0 && $relationships_valid -eq 0 && $interfaces_valid -eq 0 && $cross_references_valid -eq 0 ]]; then
        echo -e "${GREEN}All documentation files are valid!${NC}"
        return 0
    else
        echo -e "${RED}Documentation validation failed!${NC}"
        return 1
    fi
}

# Run the main function
main