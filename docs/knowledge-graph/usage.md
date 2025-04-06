# Knowledge Graph Usage Guide

This document provides information on how to use and interact with the LOCAL-LLM-Stack Knowledge Graph.

## Overview

The Knowledge Graph is a structured representation of the LOCAL-LLM-Stack codebase, including:

- **Entities**: Components, functions, variables, configuration parameters, and services
- **Relationships**: Dependencies, function calls, imports, and data flows
- **Interfaces**: APIs, CLI commands, and their parameters

The Knowledge Graph is stored in JSON-LD format, which is a method of encoding Linked Data using JSON. This format is particularly well-suited for AI agents to process and understand the system.

## Knowledge Graph Structure

The Knowledge Graph is structured as follows:

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

## Entity Types

The Knowledge Graph includes the following entity types:

### Components

- **Container**: A Docker container component (e.g., ollama, mongodb)
- **Script**: A shell script component (e.g., llm)
- **Library**: A library component (e.g., config)
- **Module**: A module component (e.g., logging)

### Code Elements

- **Function**: A shell function with parameters and return value
- **Variable**: A shell variable with value and scope
- **Parameter**: A function parameter with type and description
- **ConfigParam**: A configuration parameter with default value

### Interfaces

- **API**: An API interface exposed by a component
- **CLI**: A CLI interface exposed by a component
- **APIEndpoint**: An endpoint of an API interface
- **CLICommand**: A command of a CLI interface

### Relationships

- **DependsOn**: A dependency relationship between components
- **Calls**: A function call relationship
- **Imports**: An import relationship between modules
- **Configures**: A configuration relationship
- **Defines**: A definition relationship
- **Uses**: A usage relationship
- **ProvidesServiceTo**: A service provision relationship
- **DataFlow**: A data flow relationship

## Querying the Knowledge Graph

The Knowledge Graph can be queried using standard JSON processing tools like `jq`. Here are some example queries:

### Find all components of a specific type

```bash
jq '."@graph"[] | select(."@type" == "llm:Container") | .name' docs/knowledge-graph/graph.json
```

### Find all functions in a specific module

```bash
jq '."@graph"[] | select(."@type" == "llm:Function" and .module == "llm:config") | .name' docs/knowledge-graph/graph.json
```

### Find all dependencies of a component

```bash
jq '."@graph"[] | select(."@type" == "llm:DependsOn" and .source == "llm:librechat") | .target' docs/knowledge-graph/graph.json
```

### Find all function calls from a specific function

```bash
jq '."@graph"[] | select(."@type" == "llm:Calls" and .source == "llm:config_load_config") | .target' docs/knowledge-graph/graph.json
```

### Find all data flows in the system

```bash
jq '."@graph"[] | select(."@type" == "llm:DataFlow") | {name: .name, source: .source, target: .target, data: .data}' docs/knowledge-graph/graph.json
```

## Visualizations

The Knowledge Graph includes visualizations to help understand the system structure:

- **Component Dependencies**: Shows the dependencies between components
- **Function Calls**: Shows the function call graph
- **Data Flows**: Shows the flow of data through the system

These visualizations are stored in the `docs/knowledge-graph/visualizations/` directory as SVG files.

## Updating the Knowledge Graph

The Knowledge Graph is automatically updated when changes are made to the codebase. However, you can also update it manually:

```bash
./tools/knowledge-graph/update.sh
```

This will:
1. Extract entities from the codebase
2. Map relationships between entities
3. Generate the Knowledge Graph
4. Create visualizations

## Validating the Knowledge Graph

You can validate the Knowledge Graph to ensure it is accurate and consistent:

```bash
./tools/knowledge-graph/validation/validate-graph.sh
```

This will check:
1. JSON syntax
2. Required fields
3. Entity references
4. Function existence
5. Component existence
6. Relationship consistency

## Integration with Development Workflow

The Knowledge Graph is integrated with the development workflow through Git hooks:

1. Install the Git hooks:
   ```bash
   ./tools/knowledge-graph/git-hooks/install-hooks.sh
   ```

2. The Knowledge Graph will be automatically updated when you commit changes to the codebase.

## CI/CD Integration

The Knowledge Graph is integrated with CI/CD pipelines through the following script:

```bash
./tools/knowledge-graph/ci-cd/ci-validate.sh
```

This script:
1. Validates the Knowledge Graph
2. Updates it if necessary
3. Fails the build if validation fails

## Using the Knowledge Graph with AI Agents

The Knowledge Graph is designed to be used by AI agents to understand the system architecture, components, relationships, interfaces, and data flows. It provides a machine-readable representation of the system that can be queried and traversed.

For example, an AI agent can:
- Find all components of a specific type
- Find all relationships between components
- Find all interfaces exposed by a component
- Find all data flows in the system
- Trace the flow of data through the system

This enables AI agents to provide more accurate and helpful assistance when working with the LOCAL-LLM-Stack project.