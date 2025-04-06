# Documentation Git Hooks

This directory contains Git hooks for automating documentation validation and extraction in the LOCAL-LLM-Stack project.

## Overview

These Git hooks help ensure that documentation stays in sync with code changes by:

1. **Validating documentation** before committing changes
2. **Extracting documentation** from code after committing changes
3. **Prompting developers** to update documentation when code changes

## Available Hooks

### pre-commit

The pre-commit hook runs before a commit is completed and performs the following checks:

- Validates documentation files against the schema
- Checks for consistency in documentation
- Prompts the developer to update documentation when code changes

### post-commit

The post-commit hook runs after a commit is completed and performs the following actions:

- Extracts documentation from changed code files
- Updates machine-readable documentation files
- Notifies the developer of documentation changes that need to be committed

## Installation

To install the Git hooks, run the installation script:

```bash
# Make the script executable
chmod +x tools/doc-sync/git-hooks/install-hooks.sh

# Run the installation script
./tools/doc-sync/git-hooks/install-hooks.sh
```

This will install the hooks in your local `.git/hooks` directory.

## Usage

Once installed, the hooks will run automatically during the Git workflow:

- **pre-commit** runs when you execute `git commit`
- **post-commit** runs after a commit is completed

### Bypassing Hooks

In some cases, you may need to bypass the hooks. You can do this using the `--no-verify` flag:

```bash
git commit --no-verify -m "Commit message"
```

**Note**: Bypassing hooks should be done only in exceptional cases, as it may lead to documentation becoming out of sync with code.

## Troubleshooting

### Hook Not Running

If a hook is not running, check the following:

1. Ensure the hook is installed in `.git/hooks/`
2. Ensure the hook file is executable (`chmod +x .git/hooks/hook-name`)
3. Check for any error messages in the hook output

### Documentation Validation Errors

If you encounter documentation validation errors:

1. Check the error message for details
2. Verify that the documentation follows the schema
3. Ensure all required fields are present
4. Check for syntax errors

### Documentation Extraction Errors

If you encounter documentation extraction errors:

1. Check the error message for details
2. Verify that the code follows the expected format
3. Check for syntax errors in the code
4. Manually update the documentation if needed

## Customization

You can customize the hooks by editing the files in this directory. After making changes, you'll need to reinstall the hooks using the installation script.

## Related Documentation

- [Documentation Style Guide](../../../docs/documentation-style-guide.md)
- [Maintaining Documentation](../../../docs/maintaining-documentation.md)