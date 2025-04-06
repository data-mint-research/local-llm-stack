#!/bin/bash
# validate-graph.sh - Validate the knowledge graph for accuracy and consistency
# This script validates the knowledge graph against the codebase

# Get the absolute path of the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Input and output directories
ENTITIES_DIR="$ROOT_DIR/docs/knowledge-graph/entities"
RELATIONSHIPS_DIR="$ROOT_DIR/docs/knowledge-graph/relationships"
GRAPH_FILE="$ROOT_DIR/docs/knowledge-graph/graph.json"

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

# Validate JSON syntax
validate_json_syntax() {
    echo "Validating JSON syntax..."
    
    # Check if the knowledge graph file exists
    if [[ ! -f "$GRAPH_FILE" ]]; then
        echo -e "${RED}Error: Knowledge graph file not found: $GRAPH_FILE${NC}"
        return 1
    fi
    
    # Validate JSON syntax
    jq empty "$GRAPH_FILE" 2>/dev/null
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Error: Knowledge graph file contains invalid JSON.${NC}"
        return 1
    fi
    
    echo -e "${GREEN}JSON syntax validation passed!${NC}"
    return 0
}

# Validate required fields
validate_required_fields() {
    echo "Validating required fields..."
    
    # Check if the knowledge graph file exists
    if [[ ! -f "$GRAPH_FILE" ]]; then
        echo -e "${RED}Error: Knowledge graph file not found: $GRAPH_FILE${NC}"
        return 1
    fi
    
    # Validate required fields
    local context=$(jq -r '."@context"' "$GRAPH_FILE")
    if [[ -z "$context" || "$context" == "null" ]]; then
        echo -e "${RED}Error: Knowledge graph file is missing @context field.${NC}"
        return 1
    fi
    
    local graph=$(jq -r '."@graph"' "$GRAPH_FILE")
    if [[ -z "$graph" || "$graph" == "null" ]]; then
        echo -e "${RED}Error: Knowledge graph file is missing @graph field.${NC}"
        return 1
    fi
    
    # Validate that the graph is not empty
    local graph_size=$(jq '."@graph" | length' "$GRAPH_FILE")
    if [[ $graph_size -eq 0 ]]; then
        echo -e "${YELLOW}Warning: Knowledge graph is empty.${NC}"
    fi
    
    echo -e "${GREEN}Required fields validation passed!${NC}"
    return 0
}

# Validate entity references
validate_entity_references() {
    echo "Validating entity references..."
    
    # Check if the knowledge graph file exists
    if [[ ! -f "$GRAPH_FILE" ]]; then
        echo -e "${RED}Error: Knowledge graph file not found: $GRAPH_FILE${NC}"
        return 1
    fi
    
    # Get all entity IDs
    local entity_ids=$(jq -r '."@graph"[] | ."@id"' "$GRAPH_FILE" | sort -u)
    
    # Check for duplicate entity IDs
    local duplicate_ids=$(echo "$entity_ids" | sort | uniq -d)
    if [[ -n "$duplicate_ids" ]]; then
        echo -e "${RED}Error: Knowledge graph contains duplicate entity IDs:${NC}"
        echo "$duplicate_ids"
        return 1
    fi
    
    # Validate entity references in relationships
    local invalid_references=$(jq -r '."@graph"[] | select(.source != null or .target != null) | 
        if (.source != null and (.source | type) == "string" and (.source | startswith("llm:")) | not) or 
           (.target != null and (.target | type) == "string" and (.target | startswith("llm:")) | not) then
            "Invalid reference: " + (.name // "unknown")
        else
            empty
        end' "$GRAPH_FILE")
    
    if [[ -n "$invalid_references" ]]; then
        echo -e "${RED}Error: Knowledge graph contains invalid entity references:${NC}"
        echo "$invalid_references"
        return 1
    fi
    
    # Validate that all referenced entities exist
    local referenced_entities=$(jq -r '."@graph"[] | 
        if .source != null and (.source | type) == "string" then .source 
        elif .source != null and (.source | type) == "object" and .source."@id" != null then .source."@id"
        else empty end' "$GRAPH_FILE")
    
    referenced_entities+=$'\n'$(jq -r '."@graph"[] | 
        if .target != null and (.target | type) == "string" then .target 
        elif .target != null and (.target | type) == "object" and .target."@id" != null then .target."@id"
        else empty end' "$GRAPH_FILE")
    
    # Filter out empty lines and get unique references
    referenced_entities=$(echo "$referenced_entities" | grep -v '^$' | sort -u)
    
    # Check if all referenced entities exist
    for entity_ref in $referenced_entities; do
        if ! echo "$entity_ids" | grep -q "^$entity_ref$"; then
            echo -e "${RED}Error: Referenced entity does not exist: $entity_ref${NC}"
            return 1
        fi
    done
    
    echo -e "${GREEN}Entity references validation passed!${NC}"
    return 0
}

# Validate function existence
validate_function_existence() {
    echo "Validating function existence..."
    
    # Check if the knowledge graph file exists
    if [[ ! -f "$GRAPH_FILE" ]]; then
        echo -e "${RED}Error: Knowledge graph file not found: $GRAPH_FILE${NC}"
        return 1
    fi
    
    # Get all function entities
    local functions=$(jq -r '."@graph"[] | select(."@type" == "llm:Function") | {name: .name, file: .filePath}' "$GRAPH_FILE")
    
    # Check if functions exist in the codebase
    local function_count=$(echo "$functions" | jq -r '. | length')
    local missing_functions=0
    
    for function in $(echo "$functions" | jq -c '.'); do
        local function_name=$(echo "$function" | jq -r '.name')
        local file_path=$(echo "$function" | jq -r '.file')
        
        # Skip if file path is empty
        [[ -z "$file_path" ]] && continue
        
        # Check if the file exists
        if [[ ! -f "$file_path" ]]; then
            echo -e "${YELLOW}Warning: File not found for function $function_name: $file_path${NC}"
            continue
        fi
        
        # Check if the function exists in the file
        if ! grep -q -E "(^|[[:space:]])$function_name[[:space:]]*\(\)" "$file_path" && ! grep -q -E "function[[:space:]]+$function_name[[:space:]]*\{" "$file_path"; then
            echo -e "${RED}Error: Function $function_name not found in file: $file_path${NC}"
            missing_functions=$((missing_functions + 1))
        fi
    done
    
    if [[ $missing_functions -gt 0 ]]; then
        echo -e "${RED}Error: $missing_functions functions are missing from the codebase.${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Function existence validation passed!${NC}"
    return 0
}

# Validate component existence
validate_component_existence() {
    echo "Validating component existence..."
    
    # Check if the knowledge graph file exists
    if [[ ! -f "$GRAPH_FILE" ]]; then
        echo -e "${RED}Error: Knowledge graph file not found: $GRAPH_FILE${NC}"
        return 1
    fi
    
    # Get all component entities
    local components=$(jq -r '."@graph"[] | select(."@type" == "llm:Container" or ."@type" == "llm:Script" or ."@type" == "llm:Library" or ."@type" == "llm:Module") | .name' "$GRAPH_FILE")
    
    # Check if components exist in the YAML documentation
    local components_file="$ROOT_DIR/docs/system/components.yaml"
    
    if [[ ! -f "$components_file" ]]; then
        echo -e "${YELLOW}Warning: Components file not found: $components_file${NC}"
        return 0
    fi
    
    local missing_components=0
    
    for component in $components; do
        # Check if the component exists in the YAML file
        if ! grep -q -E "^    name:[[:space:]]*\"?$component\"?" "$components_file"; then
            echo -e "${RED}Error: Component $component not found in components.yaml${NC}"
            missing_components=$((missing_components + 1))
        fi
    done
    
    if [[ $missing_components -gt 0 ]]; then
        echo -e "${RED}Error: $missing_components components are missing from the documentation.${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Component existence validation passed!${NC}"
    return 0
}

# Validate relationship consistency
validate_relationship_consistency() {
    echo "Validating relationship consistency..."
    
    # Check if the knowledge graph file exists
    if [[ ! -f "$GRAPH_FILE" ]]; then
        echo -e "${RED}Error: Knowledge graph file not found: $GRAPH_FILE${NC}"
        return 1
    fi
    
    # Get all relationships
    local relationships=$(jq -r '."@graph"[] | select(."@type" | startswith("llm:") and (. | contains("Relationship") or . | contains("DependsOn") or . | contains("Calls") or . | contains("Imports") or . | contains("Configures") or . | contains("Defines") or . | contains("Uses") or . | contains("ProvidesServiceTo") or . | contains("StartupDependency") or . | contains("RuntimeDependency") or . | contains("ConfigurationDependency")))' "$GRAPH_FILE")
    
    # Check if relationships have both source and target
    local invalid_relationships=$(echo "$relationships" | jq -r 'select(.source == null or .target == null) | ."@id"')
    
    if [[ -n "$invalid_relationships" ]]; then
        echo -e "${RED}Error: The following relationships are missing source or target:${NC}"
        echo "$invalid_relationships"
        return 1
    fi
    
    echo -e "${GREEN}Relationship consistency validation passed!${NC}"
    return 0
}

# Main function
main() {
    echo "Starting knowledge graph validation..."
    
    # Check dependencies
    check_dependencies
    
    # Validate JSON syntax
    validate_json_syntax
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Knowledge graph validation failed: Invalid JSON syntax.${NC}"
        exit 1
    fi
    
    # Validate required fields
    validate_required_fields
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Knowledge graph validation failed: Missing required fields.${NC}"
        exit 1
    fi
    
    # Validate entity references
    validate_entity_references
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Knowledge graph validation failed: Invalid entity references.${NC}"
        exit 1
    fi
    
    # Validate function existence
    validate_function_existence
    if [[ $? -ne 0 ]]; then
        echo -e "${YELLOW}Warning: Some functions in the knowledge graph may not exist in the codebase.${NC}"
    fi
    
    # Validate component existence
    validate_component_existence
    if [[ $? -ne 0 ]]; then
        echo -e "${YELLOW}Warning: Some components in the knowledge graph may not exist in the documentation.${NC}"
    fi
    
    # Validate relationship consistency
    validate_relationship_consistency
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Knowledge graph validation failed: Inconsistent relationships.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Knowledge graph validation completed successfully!${NC}"
    exit 0
}

# Run the main function
main