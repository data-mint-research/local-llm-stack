# Git Hooks for Documentation Synchronization

This directory contains Git hooks for automatically updating the AI-optimized documentation when code changes are committed.

## Hooks

### pre-commit

This hook automatically updates documentation when code changes are committed.

The hook performs the following operations:
- Checks if any relevant files have changed (shell scripts, Docker Compose files)
- If relevant files have changed, runs the extract-docs.sh script
- Adds the updated documentation files to the commit

## Installation

To install the hooks, you need to create symbolic links from the `.git/hooks` directory to the hooks in this directory.

```bash
# Navigate to the project root directory
cd /path/to/local-llm-stack

# Create a symbolic link to the pre-commit hook
ln -sf ../../tools/doc-sync/git-hooks/pre-commit .git/hooks/pre-commit

# Make the hook executable
chmod +x .git/hooks/pre-commit
```

## How It Works

The pre-commit hook is triggered automatically when you run `git commit`. It runs before the commit is created, allowing it to modify the files that will be included in the commit.

The hook:
1. Gets the list of files that are staged for commit
2. Checks if any of those files are shell scripts or Docker Compose files
3. If relevant files have changed, runs the extract-docs.sh script to update the documentation
4. Adds the updated documentation files to the commit

This ensures that the documentation is always in sync with the code.

## Troubleshooting

If the hook fails, the commit will be aborted. You'll need to fix the issues and try again.

Common issues include:
- Missing dependencies (yq)
- Permission issues
- Syntax errors in the documentation

If you need to bypass the hook for a specific commit, you can use the `--no-verify` option:

```bash
git commit --no-verify
```

However, this should be used sparingly, as it defeats the purpose of the hook.

## Manual Updates

If you prefer not to use the Git hooks, you can manually update the documentation:

```bash
# Update the documentation
./tools/doc-sync/extract-docs.sh

# Validate the documentation
./tools/doc-sync/validate-docs.sh

# Add the updated documentation files to the commit
git add docs/system/components.yaml docs/system/relationships.yaml docs/system/interfaces.yaml