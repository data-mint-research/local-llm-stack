# Knowledge Graph Automation

This document describes the automation system for the LOCAL-LLM-Stack Knowledge Graph.

## Overview

The Knowledge Graph automation system ensures that the Knowledge Graph is always up-to-date with the codebase. It includes:

1. **Change Detection**: Detecting changes in the codebase that affect the Knowledge Graph
2. **Incremental Updates**: Updating only the affected parts of the Knowledge Graph
3. **Git Hooks**: Automatically updating the Knowledge Graph on commit
4. **CI/CD Integration**: Validating and updating the Knowledge Graph in CI/CD pipelines
5. **Validation**: Ensuring the Knowledge Graph is accurate and consistent

## Change Detection

The system detects changes in the codebase by comparing the current state with the state at the last Knowledge Graph update. It focuses on:

- Shell scripts (`.sh` files)
- YAML documentation files in the `docs/system/` directory

The change detection is implemented in the `tools/knowledge-graph/update.sh` script, which:

1. Stores the commit hash of the last update in `.last_kg_update`
2. Uses `git diff` to find files that have changed since the last update
3. Filters for relevant file types (shell scripts and YAML documentation)

## Incremental Updates

The system performs incremental updates to the Knowledge Graph by:

1. Extracting entities only from changed files
2. Mapping relationships only for changed entities
3. Regenerating the Knowledge Graph with the updated entities and relationships

This approach is more efficient than regenerating the entire Knowledge Graph from scratch, especially for large codebases.

The incremental update process is implemented in the `tools/knowledge-graph/update.sh` script, which:

1. Calls `tools/entity-extraction/extract-entities.sh` for changed files
2. Calls `tools/relationship-mapping/map-relationships.sh` for changed files
3. Calls `tools/knowledge-graph/generate-graph.sh` to regenerate the Knowledge Graph

## Git Hooks

The system includes Git hooks to automatically update the Knowledge Graph when changes are committed:

- **Pre-Commit Hook**: Updates the Knowledge Graph before a commit is completed
- **Install Script**: Installs the Git hooks in the repository

### Pre-Commit Hook

The pre-commit hook (`tools/knowledge-graph/git-hooks/pre-commit`):

1. Detects changes in staged files
2. Filters for relevant file types (shell scripts and YAML documentation)
3. Updates the Knowledge Graph if relevant changes are detected
4. Adds the updated Knowledge Graph files to the commit

### Installing Git Hooks

To install the Git hooks, run:

```bash
./tools/knowledge-graph/git-hooks/install-hooks.sh
```

This script:

1. Checks if the `.git` directory exists
2. Creates the hooks directory if it doesn't exist
3. Copies the pre-commit hook to `.git/hooks/pre-commit`
4. Makes the hook executable

## CI/CD Integration

The system includes CI/CD integration to validate and update the Knowledge Graph in CI/CD pipelines:

- **CI Validation Script**: Validates the Knowledge Graph and updates it if necessary

### CI Validation Script

The CI validation script (`tools/knowledge-graph/ci-cd/ci-validate.sh`):

1. Validates the Knowledge Graph for accuracy and consistency
2. Checks if the Knowledge Graph is up-to-date with the codebase
3. Updates the Knowledge Graph if it's out of date
4. Fails the build if validation fails

### Integrating with CI/CD Pipelines

To integrate with CI/CD pipelines, add the following step to your pipeline configuration:

```yaml
# Example for GitHub Actions
jobs:
  validate-knowledge-graph:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
        with:
          fetch-depth: 0  # Fetch all history for change detection
      - name: Validate Knowledge Graph
        run: ./tools/knowledge-graph/ci-cd/ci-validate.sh
```

## Validation

The system includes validation to ensure the Knowledge Graph is accurate and consistent:

- **Validation Script**: Validates the Knowledge Graph against the codebase

### Validation Script

The validation script (`tools/knowledge-graph/validation/validate-graph.sh`):

1. Validates JSON syntax
2. Validates required fields
3. Validates entity references
4. Validates function existence
5. Validates component existence
6. Validates relationship consistency

### Running Validation

To validate the Knowledge Graph, run:

```bash
./tools/knowledge-graph/validation/validate-graph.sh
```

## Troubleshooting

### Knowledge Graph Update Fails

If the Knowledge Graph update fails, check:

1. **JSON Syntax Errors**: Ensure the Knowledge Graph files contain valid JSON
2. **Missing Dependencies**: Ensure all required tools (jq, git, grep, sed) are installed
3. **File Permissions**: Ensure the scripts have execute permissions
4. **Git Repository**: Ensure you're in a Git repository

### Git Hook Not Working

If the Git hook is not working, check:

1. **Hook Installation**: Ensure the hook is installed in `.git/hooks/pre-commit`
2. **Execute Permissions**: Ensure the hook has execute permissions
3. **Hook Path**: Ensure the hook references the correct paths to the update script

### CI/CD Integration Fails

If the CI/CD integration fails, check:

1. **Pipeline Configuration**: Ensure the pipeline is configured to run the validation script
2. **Git History**: Ensure the pipeline fetches the full Git history for change detection
3. **Dependencies**: Ensure the CI/CD environment has all required dependencies installed

## Best Practices

1. **Commit Frequently**: Smaller, more frequent commits make incremental updates more efficient
2. **Update Documentation**: Keep the YAML documentation files up-to-date with the codebase
3. **Validate Before Committing**: Run the validation script before committing to catch issues early
4. **Review Knowledge Graph Changes**: Review the changes to the Knowledge Graph files in your commits
5. **Keep Dependencies Updated**: Ensure all required tools are installed and up-to-date