# Maintaining AI-Optimized Documentation

This guide explains how to keep the AI-optimized documentation in sync with code changes in the LOCAL-LLM-Stack project.

## Overview

The LOCAL-LLM-Stack project uses a machine-readable documentation system that is optimized for AI agent comprehension. This documentation is stored in YAML files in the `docs/system/` directory and follows a specific schema defined in `docs/schema/system-schema.yaml`.

The documentation is used to generate a knowledge graph that can be used by AI agents to understand the system architecture, components, relationships, interfaces, and data flows.

## Documentation Structure

The documentation is organized into the following files:

- `docs/system/components.yaml`: Documents all system components (containers, scripts, libraries, modules)
- `docs/system/relationships.yaml`: Documents relationships between components (dependencies, service provision, etc.)
- `docs/system/interfaces.yaml`: Documents interfaces (APIs, CLI commands, shell functions) and data flows

## Automated Documentation Updates

The system includes tools to automatically extract and update documentation from the codebase:

1. `tools/doc-sync/extract-docs.sh`: Extracts documentation from shell scripts and Docker Compose files
2. `tools/doc-sync/validate-docs.sh`: Validates the documentation against the schema
3. Git hooks in `tools/doc-sync/git-hooks/` that run automatically when code changes

### Setting Up Git Hooks

To enable automatic documentation updates when code changes, you need to set up the Git hooks:

```bash
# Navigate to the project root directory
cd /path/to/local-llm-stack

# Create a symbolic link to the pre-commit hook
ln -sf ../../tools/doc-sync/git-hooks/pre-commit .git/hooks/pre-commit

# Make the hook executable
chmod +x .git/hooks/pre-commit
```

Once the hook is set up, it will automatically update the documentation when you commit changes to shell scripts or Docker Compose files.

## Manual Documentation Updates

For changes that cannot be automatically detected or extracted, you'll need to update the documentation manually:

### Updating Component Documentation

To add or update a component in `docs/system/components.yaml`:

```yaml
components:
  - type: "container"  # container, script, library, module
    name: "component_name"
    purpose: "Brief description of the component's purpose"
    # Add other component properties as needed
```

### Updating Relationship Documentation

To add or update a relationship in `docs/system/relationships.yaml`:

```yaml
relationships:
  - source: "source_component"
    target: "target_component"
    type: "depends_on"  # depends_on, provides_service_to, startup_dependency, runtime_dependency, configuration_dependency
    description: "Description of the relationship"
    # Add other relationship properties as needed
```

### Updating Interface Documentation

To add or update an interface in `docs/system/interfaces.yaml`:

```yaml
# API Interfaces
api_interfaces:
  - component: "component_name"
    interface_type: "http_api"  # http_api, grpc, websocket, cli
    base_url: "http://base.url"
    endpoints:
      - path: "/api/endpoint"
        method: "POST"  # GET, POST, PUT, DELETE, PATCH
        description: "Description of the endpoint"
        # Add request and response formats as needed

# CLI Interfaces
cli_interfaces:
  - component: "component_name"
    commands:
      - name: "command_name"
        description: "Description of the command"
        function: "function_name"
        # Add parameters and subcommands as needed

# Shell Functions
shell_functions:
  - file: "path/to/file.sh"
    functions:
      - name: "function_name"
        description: "Description of the function"
        # Add parameters and return value as needed

# Data Flows
data_flows:
  - name: "data_flow_name"
    description: "Description of the data flow"
    steps:
      - step: 1
        source: "source_component"
        target: "target_component"
        data: "data_description"
        # Add format, transport, and endpoint as needed
```

## Validating Documentation

After making manual changes to the documentation, you should validate it to ensure it follows the schema:

```bash
# Navigate to the project root directory
cd /path/to/local-llm-stack

# Run the validation script
./tools/doc-sync/validate-docs.sh
```

The validation script will check that:
- All YAML files conform to the schema
- All required fields are present
- All references between files are valid

## Generating the Knowledge Graph

To generate or update the knowledge graph from the documentation:

```bash
# Navigate to the project root directory
cd /path/to/local-llm-stack

# Run the knowledge graph generation script
./tools/knowledge-graph/generate-graph.sh
```

This will create a JSON-LD knowledge graph in `docs/knowledge-graph/graph.json` that can be used by AI agents to understand the system.

## Best Practices

1. **Keep Documentation Up-to-Date**: Update the documentation whenever you make changes to the code. The Git hooks will help with this, but you should also manually update the documentation for changes that cannot be automatically detected.

2. **Follow the Schema**: Make sure your documentation follows the schema defined in `docs/schema/system-schema.yaml`. The validation script will help with this.

3. **Be Descriptive**: Provide clear, concise descriptions for components, relationships, interfaces, and data flows. This will help AI agents understand the system better.

4. **Use Consistent Terminology**: Use consistent terminology throughout the documentation. This will help AI agents make connections between different parts of the system.

5. **Document Relationships**: Make sure to document all relationships between components. This is crucial for AI agents to understand how the system works.

6. **Document Interfaces**: Document all interfaces (APIs, CLI commands, shell functions) that components expose. This will help AI agents understand how to interact with the system.

7. **Document Data Flows**: Document how data flows through the system. This will help AI agents understand the system's behavior.

## Troubleshooting

### Documentation Validation Fails

If the documentation validation fails, check the error messages for details on what's wrong. Common issues include:

- Missing required fields
- Invalid field values
- Invalid references between files

### Git Hook Fails

If the Git hook fails to update the documentation, check the error messages for details. Common issues include:

- Missing dependencies (yq, jq)
- Permission issues
- Syntax errors in the documentation

### Knowledge Graph Generation Fails

If the knowledge graph generation fails, check the error messages for details. Common issues include:

- Missing dependencies (yq, jq)
- Invalid documentation
- Permission issues

## Conclusion

By following this guide, you'll help keep the AI-optimized documentation in sync with code changes, making it easier for AI agents to understand and work with the LOCAL-LLM-Stack project.