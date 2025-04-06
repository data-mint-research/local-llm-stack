# Maintaining Documentation

This guide outlines the process for maintaining documentation in the LOCAL-LLM-Stack project. Following these guidelines ensures that documentation remains accurate, up-to-date, and consistent with the codebase.

## Table of Contents

1. [Documentation Structure](#documentation-structure)
2. [Documentation Update Process](#documentation-update-process)
3. [Using Documentation Tools](#using-documentation-tools)
4. [Documentation Standards](#documentation-standards)
5. [Git Hooks for Documentation](#git-hooks-for-documentation)
6. [Validation and Testing](#validation-and-testing)
7. [Troubleshooting](#troubleshooting)

## Documentation Structure

The LOCAL-LLM-Stack documentation is organized as follows:

```
docs/
├── README.md                     # Overview of documentation
├── *.md                          # General documentation files
├── documentation-style-guide.md  # Documentation style guide
├── diagrams/                     # Diagram files
│   ├── *.mmd                     # Mermaid diagram source files
│   └── *.png                     # Rendered diagram images
├── schema/                       # Schema definitions
│   └── *.yaml                    # YAML schema files
├── system/                       # Machine-readable system documentation
│   ├── components.yaml           # Component documentation
│   ├── relationships.yaml        # Relationship documentation
│   └── interfaces.yaml           # Interface documentation
└── templates/                    # Documentation templates
    ├── *.md                      # Markdown templates
    └── *.yaml                    # YAML templates
```

## Documentation Update Process

### When to Update Documentation

Documentation should be updated in the following scenarios:

1. **Code Changes**: When making changes to code, update the corresponding documentation.
2. **New Features**: When adding new features, create or update documentation to reflect the changes.
3. **Bug Fixes**: When fixing bugs that affect behavior described in documentation, update the documentation.
4. **Configuration Changes**: When changing configuration options, update the documentation.
5. **Architectural Changes**: When changing the system architecture, update diagrams and related documentation.

### Documentation Update Workflow

Follow this workflow when updating documentation:

1. **Identify Documentation to Update**: Determine which documentation files need to be updated based on your code changes.
2. **Extract Documentation**: Use the documentation extraction tools to automatically update machine-readable documentation.
3. **Validate Documentation**: Use the validation tools to ensure the documentation is valid and consistent.
4. **Update Human-Readable Documentation**: Update any human-readable documentation (Markdown files) as needed.
5. **Update Diagrams**: Update diagrams to reflect any architectural changes.
6. **Review Documentation**: Review the documentation changes to ensure accuracy and completeness.
7. **Commit Documentation**: Commit the documentation changes along with the code changes.

## Using Documentation Tools

### Documentation Extraction

The documentation extraction tool automatically extracts information from code and updates the machine-readable documentation.

```bash
# Extract documentation from all sources
./tools/doc-sync/extract-docs.sh

# Extract documentation from a specific file
./tools/doc-sync/extract-docs.sh --file path/to/file.sh
```

### Documentation Validation

The documentation validation tool ensures that documentation follows the defined schema and standards.

```bash
# Validate all documentation
./tools/doc-sync/validate-docs.sh

# Validate with warnings only (don't fail on warnings)
./tools/doc-sync/validate-docs.sh --warning-only
```

## Documentation Standards

All documentation should follow the standards defined in the [Documentation Style Guide](documentation-style-guide.md). Key points include:

- Use consistent formatting and structure
- Follow naming conventions
- Use clear, concise language
- Include examples where appropriate
- Keep documentation up-to-date with code

### Machine-Readable Documentation

Machine-readable documentation (YAML files) should:

- Follow the schema defined in `docs/schema/system-schema.yaml`
- Include all required fields
- Use consistent terminology
- Include metadata (version, last updated, author)
- Include cross-references to related documentation

### Human-Readable Documentation

Human-readable documentation (Markdown files) should:

- Follow the structure defined in the templates
- Use consistent formatting (headers, lists, code blocks)
- Include examples and diagrams where appropriate
- Use consistent terminology
- Include links to related documentation

## Git Hooks for Documentation

Git hooks automate documentation validation and updates. To install the git hooks:

```bash
# Install git hooks
./tools/doc-sync/git-hooks/install-hooks.sh
```

The following git hooks are available:

- **pre-commit**: Validates documentation before committing
- **post-commit**: Extracts documentation after committing
- **pre-push**: Ensures documentation is up-to-date before pushing

## Validation and Testing

### Documentation Validation

Documentation validation checks for:

- Valid YAML syntax
- Compliance with the schema
- Required fields
- Consistent terminology
- Valid cross-references

### Documentation Testing

Documentation testing checks for:

- Broken links
- Missing files
- Inconsistent terminology
- Outdated information

## Troubleshooting

### Common Issues

#### Validation Errors

If you encounter validation errors:

1. Check the error message for details
2. Verify that the documentation follows the schema
3. Ensure all required fields are present
4. Check for syntax errors

#### Extraction Errors

If you encounter extraction errors:

1. Check the error message for details
2. Verify that the code follows the expected format
3. Check for syntax errors in the code
4. Manually update the documentation if needed

#### Git Hook Errors

If you encounter git hook errors:

1. Check the error message for details
2. Run the validation or extraction tools manually to debug
3. Fix any issues in the documentation or code
4. Try the git operation again

### Getting Help

If you need help with documentation:

1. Check the [Documentation Style Guide](documentation-style-guide.md)
2. Review the templates in `docs/templates/`
3. Ask for help from the team