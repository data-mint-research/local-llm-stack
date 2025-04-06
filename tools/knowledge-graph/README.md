# Knowledge Graph Tools

This directory contains tools for generating, validating, and updating the knowledge graph for the LOCAL-LLM-Stack project.

## Overview

The knowledge graph is a structured representation of the LOCAL-LLM-Stack codebase, including:

- **Entities**: Components, functions, variables, configuration parameters, and services
- **Relationships**: Dependencies, function calls, imports, and data flows
- **Interfaces**: APIs, CLI commands, and their parameters

The knowledge graph is stored in JSON-LD format, which is a method of encoding Linked Data using JSON. This format is particularly well-suited for AI agents to process and understand the system.

## Tools

### generate-graph.sh

This script generates a JSON-LD knowledge graph from the extracted entities and mapped relationships.

The script performs the following operations:
- Reads the entity files from the `docs/knowledge-graph/entities/` directory
- Reads the relationship files from the `docs/knowledge-graph/relationships/` directory
- Generates a JSON-LD knowledge graph with the following elements:
  - Components (containers, scripts, libraries, modules)
  - Functions and their parameters
  - Variables and configuration parameters
  - Relationships between entities
  - Interfaces (APIs, CLI commands)
  - Data flows
- Saves the knowledge graph to `docs/knowledge-graph/graph.json`
- Generates visualizations of the knowledge graph

Usage:
```bash
./tools/knowledge-graph/generate-graph.sh
```

### update.sh

This script updates the knowledge graph when changes are detected in the codebase.

The script performs the following operations:
- Detects changes in the codebase since the last update
- Extracts entities from changed files
- Maps relationships for changed entities
- Regenerates the knowledge graph
- Updates the last update timestamp

Usage:
```bash
./tools/knowledge-graph/update.sh
```

### validation/validate-graph.sh

This script validates the knowledge graph for accuracy and consistency.

The script performs the following operations:
- Validates JSON syntax
- Validates required fields
- Validates entity references
- Validates function existence
- Validates component existence
- Validates relationship consistency

Usage:
```bash
./tools/knowledge-graph/validation/validate-graph.sh
```

### git-hooks/pre-commit

This Git hook automatically updates the knowledge graph when changes are committed.

The hook performs the following operations:
- Detects changes in staged files
- Filters for relevant file types (shell scripts and YAML documentation)
- Updates the knowledge graph if relevant changes are detected
- Adds the updated knowledge graph files to the commit

### git-hooks/install-hooks.sh

This script installs the Git hooks for automatically updating the knowledge graph.

Usage:
```bash
./tools/knowledge-graph/git-hooks/install-hooks.sh
```

### ci-cd/ci-validate.sh

This script validates the knowledge graph and updates it if necessary in CI/CD pipelines.

The script performs the following operations:
- Validates the knowledge graph
- Checks if the knowledge graph is up-to-date with the codebase
- Updates the knowledge graph if it's out of date
- Fails the build if validation fails

Usage:
```bash
./tools/knowledge-graph/ci-cd/ci-validate.sh
```

## Knowledge Graph Structure

The knowledge graph is structured as follows:

- `@context`: Defines the context for the JSON-LD document, including the ontology used
- `@graph`: Contains the actual graph data, including:
  - Components (containers, scripts, libraries, modules)
  - Functions and their parameters
  - Variables and configuration parameters
  - Relationships between entities
  - Interfaces (APIs, CLI commands)
  - Data flows

Each entity in the graph has:
- `@id`: A unique identifier for the entity
- `@type`: The type of the entity (Component, Function, Variable, etc.)
- Properties specific to the entity type

Relationships between entities are represented as properties of the source entity, with the value being the target entity.

## Visualizations

The knowledge graph tools generate the following visualizations:

- **Component Dependencies**: Shows the dependencies between components
- **Function Calls**: Shows the function call graph
- **Data Flows**: Shows the flow of data through the system

These visualizations are stored in the `docs/knowledge-graph/visualizations/` directory as SVG files.

## Dependencies

These tools have the following dependencies:

- `jq`: For processing JSON files
- `yq`: For processing YAML files
- `dot` (Graphviz): For generating visualizations
- `git`: For detecting changes in the codebase
- `grep` and `sed`: For text processing

To install these dependencies:

```bash
# Install jq
sudo apt-get install jq

# Install yq
sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod +x /usr/local/bin/yq

# Install Graphviz
sudo apt-get install graphviz
```

## Integration with Development Workflow

The knowledge graph should be updated whenever the documentation or codebase changes:

1. Make changes to the code
2. Update the documentation (manually or using the doc-sync tools)
3. The knowledge graph will be automatically updated when you commit your changes (if you've installed the Git hooks)
4. Alternatively, run `./tools/knowledge-graph/update.sh` to update the knowledge graph manually

## Using the Knowledge Graph

The knowledge graph can be used by AI agents to understand the system architecture, components, relationships, interfaces, and data flows. It provides a machine-readable representation of the system that can be queried and traversed.

For example, an AI agent can:
- Find all components of a specific type
- Find all relationships between components
- Find all interfaces exposed by a component
- Find all data flows in the system
- Trace the flow of data through the system

This enables AI agents to provide more accurate and helpful assistance when working with the LOCAL-LLM-Stack project.

For more information on using the knowledge graph, see the [Knowledge Graph Usage Guide](../../docs/knowledge-graph/usage.md).

For more information on the automation system, see the [Knowledge Graph Automation Guide](../../docs/knowledge-graph/automation.md).