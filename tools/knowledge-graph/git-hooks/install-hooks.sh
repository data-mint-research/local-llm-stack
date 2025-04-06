#!/bin/bash
# install-hooks.sh - Install Git hooks for knowledge graph updates
# This script installs the Git hooks for automatically updating the knowledge graph

# Get the absolute path of the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Check if the .git directory exists
if [[ ! -d "$REPO_ROOT/.git" ]]; then
    echo -e "${RED}Error: .git directory not found. Make sure you're in a Git repository.${NC}"
    exit 1
fi

# Check if the pre-commit hook exists
if [[ ! -f "$SCRIPT_DIR/pre-commit" ]]; then
    echo -e "${RED}Error: pre-commit hook not found. Make sure the hook file exists.${NC}"
    exit 1
fi

# Create the hooks directory if it doesn't exist
if [[ ! -d "$REPO_ROOT/.git/hooks" ]]; then
    mkdir -p "$REPO_ROOT/.git/hooks"
    echo "Created hooks directory: $REPO_ROOT/.git/hooks"
fi

# Install the pre-commit hook
echo "Installing pre-commit hook..."
cp "$SCRIPT_DIR/pre-commit" "$REPO_ROOT/.git/hooks/pre-commit"
chmod +x "$REPO_ROOT/.git/hooks/pre-commit"

echo -e "${GREEN}Git hooks installed successfully!${NC}"
echo "The knowledge graph will now be automatically updated when you commit changes."
exit 0