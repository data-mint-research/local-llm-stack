# Documentation Synchronization Tools

This directory contains tools for keeping the AI-optimized documentation in sync with code changes in the LOCAL-LLM-Stack project.

## Tools

### extract-docs.sh

This script extracts documentation from shell scripts, Docker Compose files, and other source files to update the machine-readable documentation.

The script performs the following operations:
- Extracts component information from Docker Compose files
- Extracts relationship information from Docker Compose files
- Extracts CLI command information from the main script
- Extracts shell function information from core library files
- Updates the YAML documentation files with the extracted information

Usage:
```bash
./tools/doc-sync/extract-docs.sh
```

### validate-docs.sh

This script validates the YAML documentation files against their schemas.

The script performs the following validations:
- Checks that all YAML files are valid
- Checks that all required fields are present
- Checks that all references between files are valid
- Checks for consistent terminology across all documentation

Usage:
```bash
./tools/doc-sync/validate-docs.sh
```

### Git Hooks

The `git-hooks` directory contains Git hooks for automatically updating documentation when code changes:

#### pre-commit

This hook automatically updates documentation when code changes are committed.

The hook performs the following operations:
- Checks if any relevant files have changed (shell scripts, Docker Compose files)
- If relevant files have changed, runs the extract-docs.sh script
- Adds the updated documentation files to the commit

To install the hook:
```bash
# Navigate to the project root directory
cd /path/to/local-llm-stack

# Create a symbolic link to the pre-commit hook
ln -sf ../../tools/doc-sync/git-hooks/pre-commit .git/hooks/pre-commit

# Make the hook executable
chmod +x .git/hooks/pre-commit
```

## Dependencies

These tools have the following dependencies:

- `yq`: For processing YAML files

To install these dependencies:

```bash
# Install yq
sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod +x /usr/local/bin/yq
```

## Integration with Development Workflow

These tools are designed to be integrated into the development workflow to ensure that documentation stays in sync with code changes:

1. Make changes to the code
2. Run `./tools/doc-sync/extract-docs.sh` to update the documentation
3. Run `./tools/doc-sync/validate-docs.sh` to validate the documentation
4. Commit the changes

Alternatively, install the Git hooks to automate steps 2-3.