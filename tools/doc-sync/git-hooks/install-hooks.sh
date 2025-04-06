#!/bin/bash
# install-hooks.sh - Install Git hooks for documentation management
# This script installs Git hooks for documentation validation and extraction

# Get the absolute path of the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
GIT_HOOKS_DIR="$ROOT_DIR/.git/hooks"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Check if .git directory exists
if [[ ! -d "$ROOT_DIR/.git" ]]; then
    echo -e "${RED}Error: .git directory not found. Are you in a Git repository?${NC}"
    exit 1
fi

# Create hooks directory if it doesn't exist
if [[ ! -d "$GIT_HOOKS_DIR" ]]; then
    echo -e "${YELLOW}Creating Git hooks directory: $GIT_HOOKS_DIR${NC}"
    mkdir -p "$GIT_HOOKS_DIR"
fi

# Install pre-commit hook
echo -e "${YELLOW}Installing pre-commit hook...${NC}"
cp "$SCRIPT_DIR/pre-commit" "$GIT_HOOKS_DIR/pre-commit"
chmod +x "$GIT_HOOKS_DIR/pre-commit"

# Install post-commit hook
echo -e "${YELLOW}Installing post-commit hook...${NC}"
cp "$SCRIPT_DIR/post-commit" "$GIT_HOOKS_DIR/post-commit"
chmod +x "$GIT_HOOKS_DIR/post-commit"

# Install pre-push hook if it exists
if [[ -f "$SCRIPT_DIR/pre-push" ]]; then
    echo -e "${YELLOW}Installing pre-push hook...${NC}"
    cp "$SCRIPT_DIR/pre-push" "$GIT_HOOKS_DIR/pre-push"
    chmod +x "$GIT_HOOKS_DIR/pre-push"
fi

echo -e "${GREEN}Git hooks installed successfully!${NC}"
echo -e "${YELLOW}The following hooks are now active:${NC}"
echo -e "${YELLOW}- pre-commit: Validates documentation before committing${NC}"
echo -e "${YELLOW}- post-commit: Extracts documentation after committing${NC}"
if [[ -f "$SCRIPT_DIR/pre-push" ]]; then
    echo -e "${YELLOW}- pre-push: Ensures documentation is up-to-date before pushing${NC}"
fi

echo -e "${YELLOW}You can bypass these hooks with the --no-verify flag, but this is not recommended.${NC}"
echo -e "${YELLOW}Example: git commit --no-verify -m \"Commit message\"${NC}"

exit 0