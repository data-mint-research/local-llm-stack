# LOCAL-LLM-Stack Documentation Tools

This directory contains tools for maintaining the AI-optimized documentation of the LOCAL-LLM-Stack project.

## Directory Structure

- `/tools/doc-sync/`: Tools for synchronizing documentation with code
- `/tools/knowledge-graph/`: Tools for generating and validating the knowledge graph

## Documentation Synchronization Tools

The `doc-sync` directory contains tools for keeping the documentation in sync with code changes:

### extract-docs.sh

This script extracts documentation from shell scripts, Docker Compose files, and other source files to update the machine-readable documentation.

Usage:
```bash
./tools/doc-sync/extract-docs.sh
```

This will:
1. Extract component information from Docker Compose files
2. Extract relationship information from Docker Compose files
3. Extract CLI command information from the main script
4. Extract shell function information from core library files
5. Update the YAML documentation files with the extracted information

### validate-docs.sh

This script validates the YAML documentation files against their schemas.

Usage:
```bash
./tools/doc-sync/validate-docs.sh
```

This will:
1. Check that all YAML files are valid
2. Check that all required fields are present
3. Check that all references between files are valid

### Git Hooks

The `git-hooks` directory contains Git hooks for automatically updating documentation when code changes:

#### pre-commit

This hook automatically updates documentation when code changes are committed.

To install the hook:
```bash
# Navigate to the project root directory
cd /path/to/local-llm-stack

# Create a symbolic link to the pre-commit hook
ln -sf ../../tools/doc-sync/git-hooks/pre-commit .git/hooks/pre-commit

# Make the hook executable
chmod +x .git/hooks/pre-commit
```

## Knowledge Graph Tools

The `knowledge-graph` directory contains tools for generating and validating the knowledge graph:

### generate-graph.sh

This script generates a JSON-LD knowledge graph from the YAML documentation.

Usage:
```bash
./tools/knowledge-graph/generate-graph.sh
```

This will:
1. Read the YAML documentation files
2. Generate a JSON-LD knowledge graph
3. Save the knowledge graph to `docs/knowledge-graph/graph.json`

## Dependencies

These tools have the following dependencies:

- `yq`: For processing YAML files
- `jq`: For processing JSON files

To install these dependencies:

```bash
# Install yq
sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod +x /usr/local/bin/yq

# Install jq
sudo apt-get install jq
```

## Usage in Development Workflow

1. Make changes to the code
2. Run `./tools/doc-sync/extract-docs.sh` to update the documentation
3. Run `./tools/doc-sync/validate-docs.sh` to validate the documentation
4. Run `./tools/knowledge-graph/generate-graph.sh` to update the knowledge graph
5. Commit the changes

Alternatively, install the Git hooks to automate steps 2-4.