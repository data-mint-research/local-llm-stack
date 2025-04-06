#!/bin/bash
# ci-validate.sh - CI/CD script for validating and updating the knowledge graph
# This script validates the knowledge graph and updates it if necessary

# Get the absolute path of the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

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
    
    if ! command -v git &> /dev/null; then
        echo -e "${RED}Error: git is not installed. Please install it to detect changes.${NC}"
        exit 1
    fi
}

# Validate the knowledge graph
validate_knowledge_graph() {
    echo "Validating knowledge graph..."
    
    # Check if the knowledge graph file exists
    if [[ ! -f "$ROOT_DIR/docs/knowledge-graph/graph.json" ]]; then
        echo -e "${RED}Error: Knowledge graph file not found. Please generate the knowledge graph first.${NC}"
        return 1
    fi
    
    # Validate JSON syntax
    jq empty "$ROOT_DIR/docs/knowledge-graph/graph.json" 2>/dev/null
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Error: Knowledge graph file contains invalid JSON.${NC}"
        return 1
    fi
    
    # Validate required fields
    local context=$(jq -r '."@context"' "$ROOT_DIR/docs/knowledge-graph/graph.json")
    if [[ -z "$context" || "$context" == "null" ]]; then
        echo -e "${RED}Error: Knowledge graph file is missing @context field.${NC}"
        return 1
    fi
    
    local graph=$(jq -r '."@graph"' "$ROOT_DIR/docs/knowledge-graph/graph.json")
    if [[ -z "$graph" || "$graph" == "null" ]]; then
        echo -e "${RED}Error: Knowledge graph file is missing @graph field.${NC}"
        return 1
    fi
    
    # Validate that the graph is not empty
    local graph_size=$(jq '."@graph" | length' "$ROOT_DIR/docs/knowledge-graph/graph.json")
    if [[ $graph_size -eq 0 ]]; then
        echo -e "${YELLOW}Warning: Knowledge graph is empty.${NC}"
    fi
    
    # Validate entity references
    local invalid_references=$(jq -r '."@graph"[] | select(.source != null or .target != null) | 
        if (.source != null and (.source | type) == "string" and (.source | startswith("llm:")) | not) or 
           (.target != null and (.target | type) == "string" and (.target | startswith("llm:")) | not) then
            "Invalid reference: " + (.name // "unknown")
        else
            empty
        end' "$ROOT_DIR/docs/knowledge-graph/graph.json")
    
    if [[ -n "$invalid_references" ]]; then
        echo -e "${RED}Error: Knowledge graph contains invalid entity references:${NC}"
        echo "$invalid_references"
        return 1
    fi
    
    echo -e "${GREEN}Knowledge graph validation passed!${NC}"
    return 0
}

# Check if the knowledge graph is up to date
check_knowledge_graph_status() {
    echo "Checking knowledge graph status..."
    
    # Get the list of changed files since the last update
    local last_update_file="$ROOT_DIR/.last_kg_update"
    local changed_files=""
    
    if [[ -f "$last_update_file" ]]; then
        local last_update=$(cat "$last_update_file")
        changed_files=$(git diff --name-only "$last_update" HEAD)
    else
        # If no last update, consider all files
        changed_files=$(git ls-files)
    fi
    
    # Filter for shell scripts and YAML documentation
    local shell_scripts=$(echo "$changed_files" | grep -E '\.sh$')
    local yaml_docs=$(echo "$changed_files" | grep -E '\.yaml$' | grep -E 'docs/system/')
    
    # Combine the results
    local relevant_changes=$(echo -e "$shell_scripts\n$yaml_docs" | sort -u)
    
    # If no changes, the knowledge graph is up to date
    if [[ -z "$relevant_changes" ]]; then
        echo -e "${GREEN}Knowledge graph is up to date.${NC}"
        return 0
    else
        echo -e "${YELLOW}Knowledge graph is out of date. The following files have changed:${NC}"
        echo "$relevant_changes"
        return 1
    fi
}

# Update the knowledge graph
update_knowledge_graph() {
    echo "Updating knowledge graph..."
    
    # Run the update script
    "$ROOT_DIR/tools/knowledge-graph/update.sh"
    
    # Check if the update was successful
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Error: Knowledge graph update failed.${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Knowledge graph updated successfully!${NC}"
    return 0
}

# Main function
main() {
    echo "Starting knowledge graph validation..."
    
    # Check dependencies
    check_dependencies
    
    # Validate the knowledge graph
    validate_knowledge_graph
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Knowledge graph validation failed. Attempting to update...${NC}"
        update_knowledge_graph
        if [[ $? -ne 0 ]]; then
            echo -e "${RED}Knowledge graph update failed. Please fix the errors manually.${NC}"
            exit 1
        fi
        
        # Validate again after update
        validate_knowledge_graph
        if [[ $? -ne 0 ]]; then
            echo -e "${RED}Knowledge graph validation failed even after update. Please fix the errors manually.${NC}"
            exit 1
        fi
    fi
    
    # Check if the knowledge graph is up to date
    check_knowledge_graph_status
    if [[ $? -ne 0 ]]; then
        echo -e "${YELLOW}Knowledge graph is out of date. Updating...${NC}"
        update_knowledge_graph
        if [[ $? -ne 0 ]]; then
            echo -e "${RED}Knowledge graph update failed. Please fix the errors manually.${NC}"
            exit 1
        fi
    fi
    
    echo -e "${GREEN}Knowledge graph validation and update completed successfully!${NC}"
    exit 0
}

# Run the main function
main