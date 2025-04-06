#!/bin/bash
# update.sh - Update the knowledge graph
# This script updates the knowledge graph when changes are detected in the codebase

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
    
    if ! command -v git &> /dev/null; then
        echo -e "${RED}Error: git is not installed. Please install it to detect changes.${NC}"
        exit 1
    fi
}

# Detect changes in the codebase
detect_changes() {
    echo "Detecting changes in the codebase..."
    
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
    
    # Return the list of relevant changes
    echo "$relevant_changes"
}

# Update entities for changed files
update_entities() {
    local changed_files=$1
    
    echo "Updating entities for changed files..."
    
    # Check if there are any shell scripts to process
    local shell_scripts=$(echo "$changed_files" | grep -E '\.sh$')
    
    if [[ -n "$shell_scripts" ]]; then
        echo "Processing shell scripts..."
        
        # For each changed shell script, extract entities
        for script in $shell_scripts; do
            echo "Extracting entities from $script"
            "$ROOT_DIR/tools/entity-extraction/extract-entities.sh" "$script"
        done
    fi
    
    # Check if there are any YAML documentation files to process
    local yaml_docs=$(echo "$changed_files" | grep -E '\.yaml$' | grep -E 'docs/system/')
    
    if [[ -n "$yaml_docs" ]]; then
        echo "Processing YAML documentation..."
        
        # Extract components and services from YAML documentation
        "$ROOT_DIR/tools/entity-extraction/extract-entities.sh" --yaml
    fi
    
    echo -e "${GREEN}Entity update completed!${NC}"
}

# Update relationships for changed files
update_relationships() {
    local changed_files=$1
    
    echo "Updating relationships for changed files..."
    
    # Check if there are any shell scripts to process
    local shell_scripts=$(echo "$changed_files" | grep -E '\.sh$')
    
    if [[ -n "$shell_scripts" ]]; then
        echo "Processing shell scripts..."
        
        # For each changed shell script, map relationships
        for script in $shell_scripts; do
            echo "Mapping relationships from $script"
            "$ROOT_DIR/tools/relationship-mapping/map-relationships.sh" "$script"
        done
    fi
    
    # Check if there are any YAML documentation files to process
    local yaml_docs=$(echo "$changed_files" | grep -E '\.yaml$' | grep -E 'docs/system/')
    
    if [[ -n "$yaml_docs" ]]; then
        echo "Processing YAML documentation..."
        
        # Map relationships from YAML documentation
        "$ROOT_DIR/tools/relationship-mapping/map-relationships.sh" --yaml
    fi
    
    echo -e "${GREEN}Relationship update completed!${NC}"
}

# Regenerate the knowledge graph
regenerate_graph() {
    echo "Regenerating the knowledge graph..."
    
    # Generate the knowledge graph
    "$ROOT_DIR/tools/knowledge-graph/generate-graph.sh"
    
    echo -e "${GREEN}Knowledge graph regenerated!${NC}"
}

# Update the last update timestamp
update_timestamp() {
    echo "Updating last update timestamp..."
    
    # Get the current commit hash
    local current_commit=$(git rev-parse HEAD)
    
    # Save the current commit hash as the last update
    echo "$current_commit" > "$ROOT_DIR/.last_kg_update"
    
    echo "Last update timestamp set to: $current_commit"
}

# Main function
main() {
    echo "Starting knowledge graph update..."
    
    # Check dependencies
    check_dependencies
    
    # Detect changes in the codebase
    local changed_files=$(detect_changes)
    
    # If no changes, exit
    if [[ -z "$changed_files" ]]; then
        echo "No relevant changes detected. Knowledge graph is up to date."
        exit 0
    fi
    
    echo "Detected changes in the following files:"
    echo "$changed_files"
    
    # Update entities for changed files
    update_entities "$changed_files"
    
    # Update relationships for changed files
    update_relationships "$changed_files"
    
    # Regenerate the knowledge graph
    regenerate_graph
    
    # Update the last update timestamp
    update_timestamp
    
    echo -e "${GREEN}Knowledge graph update completed successfully!${NC}"
    return 0
}

# Run the main function
main "$@"