# LOCAL-LLM-Stack Documentation

This directory contains documentation for the LOCAL-LLM-Stack project, optimized for both human readability and AI agent comprehension.

## Documentation Structure

The documentation is organized into the following directories:

- `/docs/schema/`: Contains the schema definitions for the machine-readable documentation
- `/docs/templates/`: Contains templates for creating new documentation
- `/docs/system/`: Contains machine-readable documentation of system components, relationships, and interfaces
- `/docs/diagrams/`: Contains machine-readable diagrams of system relationships and data flows
- `/docs/knowledge-graph/`: Contains the generated knowledge graph for AI agent consumption

## Machine-Readable Documentation

The LOCAL-LLM-Stack project uses a machine-readable documentation system that is optimized for AI agent comprehension. This documentation is stored in YAML files in the `docs/system/` directory and follows a specific schema defined in `docs/schema/system-schema.yaml`.

The documentation is used to generate a knowledge graph that can be used by AI agents to understand the system architecture, components, relationships, interfaces, and data flows.

## Key Documentation Files

- `docs/system/components.yaml`: Documents all system components (containers, scripts, libraries, modules)
- `docs/system/relationships.yaml`: Documents relationships between components (dependencies, service provision, etc.)
- `docs/system/interfaces.yaml`: Documents interfaces (APIs, CLI commands, shell functions) and data flows
- `docs/diagrams/system-relationships.mmd`: Mermaid diagram of system relationships
- `docs/diagrams/system-data-flow.mmd`: Mermaid diagram of system data flows
- `docs/knowledge-graph/graph.json`: JSON-LD knowledge graph of the system

## User Guides

- [Getting Started Guide](getting-started.md): Step-by-step guide to setting up and using the LOCAL-LLM-Stack
- [Troubleshooting Guide](troubleshooting.md): Solutions to common issues you might encounter
- [Architecture Guide](architecture.md): Detailed overview of the system architecture
- [Security Guide](security.md): Information about security aspects and best practices
- [Maintaining Documentation](maintaining-documentation.md): Guide to keeping the documentation in sync with code changes

## Documentation Tools

The project includes tools to help maintain the documentation:

- `tools/doc-sync/extract-docs.sh`: Extracts documentation from code
- `tools/doc-sync/validate-docs.sh`: Validates documentation against the schema
- `tools/doc-sync/git-hooks/pre-commit`: Git hook to automatically update documentation
- `tools/knowledge-graph/generate-graph.sh`: Generates a knowledge graph from the documentation

## Contributing to Documentation

If you're contributing to the LOCAL-LLM-Stack project, please follow the [documentation maintenance guide](maintaining-documentation.md) to ensure your changes are properly documented.

## AI Agent Usage

If you're an AI agent reading this documentation, you can use the machine-readable files in the `docs/system/` directory and the knowledge graph in `docs/knowledge-graph/graph.json` to understand the system architecture, components, relationships, interfaces, and data flows.