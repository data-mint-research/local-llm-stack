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
DIAGRAMS_FILE="$ROOT_DIR/docs/system/diagrams.yaml"
SCHEMA_FILE="$ROOT_DIR/docs/schema/system-schema.yaml"

# Validation levels
STRICT=0
WARNING_ONLY=1
VALIDATION_LEVEL=$STRICT

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check if yq is installed
check_dependencies() {
    if ! command -v yq &> /dev/null; then
        echo -e "${RED}Error: yq is not installed. Please install it to validate YAML files.${NC}"
        echo "You can install it with: sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && sudo chmod +x /usr/local/bin/yq"
        exit 1
    fi
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --warning-only)
                VALIDATION_LEVEL=$WARNING_ONLY
                shift
                ;;
            --help)
                echo "Usage: $0 [options]"
                echo "Options:"
                echo "  --warning-only    Only show warnings, don't fail on warnings"
                echo "  --help            Show this help message"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
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

# Validate metadata
validate_metadata() {
    local file="$1"
    local prefix="$2"
    
    echo -e "${BLUE}Validating metadata in $file${NC}"
    
    # Check if metadata section exists
    if ! yq eval "$prefix.metadata" "$file" > /dev/null 2>&1 || [[ "$(yq eval "$prefix.metadata" "$file")" == "null" ]]; then
        if [[ $VALIDATION_LEVEL -eq $STRICT ]]; then
            echo -e "${RED}Error: Missing 'metadata' section in $file${NC}"
            return 1
        else
            echo -e "${YELLOW}Warning: Missing 'metadata' section in $file${NC}"
            return 0
        fi
    fi
    
    # Check required metadata fields
    local version=$(yq eval "$prefix.metadata.version" "$file")
    local last_updated=$(yq eval "$prefix.metadata.last_updated" "$file")
    local author=$(yq eval "$prefix.metadata.author" "$file")
    
    if [[ -z "$version" || "$version" == "null" ]]; then
        if [[ $VALIDATION_LEVEL -eq $STRICT ]]; then
            echo -e "${RED}Error: Missing 'version' field in metadata${NC}"
            return 1
        else
            echo -e "${YELLOW}Warning: Missing 'version' field in metadata${NC}"
        fi
    fi
    
    if [[ -z "$last_updated" || "$last_updated" == "null" ]]; then
        if [[ $VALIDATION_LEVEL -eq $STRICT ]]; then
            echo -e "${RED}Error: Missing 'last_updated' field in metadata${NC}"
            return 1
        else
            echo -e "${YELLOW}Warning: Missing 'last_updated' field in metadata${NC}"
        fi
    fi
    
    if [[ -z "$author" || "$author" == "null" ]]; then
        if [[ $VALIDATION_LEVEL -eq $STRICT ]]; then
            echo -e "${RED}Error: Missing 'author' field in metadata${NC}"
            return 1
        else
            echo -e "${YELLOW}Warning: Missing 'author' field in metadata${NC}"
        fi
    fi
    
    echo -e "${GREEN}✓ Metadata validation passed${NC}"
    return 0
}

# Validate components file against schema
validate_components() {
    local file="$COMPONENTS_FILE"
    
    echo -e "${CYAN}Validating components file: $file${NC}"
    
    # Check if file exists and is valid YAML
    if ! validate_yaml "$file"; then
        return 1
    fi
    
    # Validate metadata
    validate_metadata "$file" "."
    local metadata_valid=$?
    if [[ $metadata_valid -ne 0 && $VALIDATION_LEVEL -eq $STRICT ]]; then
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
        
        echo -e "${GREEN}✓ Component '$name' ($type) is valid${NC}"
    done
    
    echo -e "${GREEN}✓ Components validation passed${NC}"
    return 0
}

# Validate relationships file against schema
validate_relationships() {
    local file="$RELATIONSHIPS_FILE"
    
    echo -e "${CYAN}Validating relationships file: $file${NC}"
    
    # Check if file exists and is valid YAML
    if ! validate_yaml "$file"; then
        return 1
    fi
    
    # Validate metadata
    validate_metadata "$file" "."
    local metadata_valid=$?
    if [[ $metadata_valid -ne 0 && $VALIDATION_LEVEL -eq $STRICT ]]; then
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
        
        echo -e "${GREEN}✓ Relationship from '$source' to '$target' ($type) is valid${NC}"
    done
    
    echo -e "${GREEN}✓ Relationships validation passed${NC}"
    return 0
}

# Validate interfaces file against schema
validate_interfaces() {
    local file="$INTERFACES_FILE"
    
    echo -e "${CYAN}Validating interfaces file: $file${NC}"
    
    # Check if file exists and is valid YAML
    if ! validate_yaml "$file"; then
        return 1
    fi
    
    # Validate metadata
    validate_metadata "$file" "."
    local metadata_valid=$?
    if [[ $metadata_valid -ne 0 && $VALIDATION_LEVEL -eq $STRICT ]]; then
        return 1
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

# Validate diagrams
validate_diagrams() {
    if [[ -f "$DIAGRAMS_FILE" ]]; then
        echo -e "${CYAN}Validating diagrams file: $DIAGRAMS_FILE${NC}"
        
        # Check if file exists and is valid YAML
        if ! validate_yaml "$DIAGRAMS_FILE"; then
            return 1
        fi
        
        # Validate metadata
        validate_metadata "$DIAGRAMS_FILE" "."
        local metadata_valid=$?
        if [[ $metadata_valid -ne 0 && $VALIDATION_LEVEL -eq $STRICT ]]; then
            return 1
        fi
        
        echo -e "${GREEN}✓ Diagrams validation passed${NC}"
    else
        echo -e "${YELLOW}Warning: Diagrams file not found: $DIAGRAMS_FILE${NC}"
    fi
    
    return 0
}

# Main function
main() {
    echo "Starting documentation validation..."
    
    # Parse command line arguments
    parse_args "$@"
    
    # Check dependencies
    check_dependencies
    
    # Validate each file
    validate_components
    local components_valid=$?
    
    validate_relationships
    local relationships_valid=$?
    
    validate_interfaces
    local interfaces_valid=$?
    
    validate_diagrams
    local diagrams_valid=$?
    
    # Validate cross-references if all files are valid
    if [[ $components_valid -eq 0 && $relationships_valid -eq 0 && $interfaces_valid -eq 0 ]]; then
        validate_cross_references
        local cross_references_valid=$?
    else
        local cross_references_valid=1
    fi
    
    # Check overall validation result
    if [[ $components_valid -eq 0 && $relationships_valid -eq 0 && $interfaces_valid -eq 0 && $diagrams_valid -eq 0 && $cross_references_valid -eq 0 ]]; then
        echo -e "${GREEN}All documentation files are valid!${NC}"
        return 0
    else
        echo -e "${RED}Documentation validation failed!${NC}"
        return 1
    fi
}

# Run the main function
main "$@"
