# Relationship Mapping Tools

This directory contains tools for mapping relationships between entities in the LOCAL-LLM-Stack codebase.

## Overview

Relationship mapping is the process of identifying and extracting structured information about relationships between entities in the codebase, such as:

- **Function Calls**: Function A calls Function B
- **Component Dependencies**: Component A depends on Component B
- **Configuration Dependencies**: Function A uses Configuration Parameter B
- **Import Relationships**: Module A imports Module B
- **Data Flows**: Data flows from Component A to Component B

These relationships are mapped from:
- Shell scripts (`.sh` files)
- YAML documentation files in the `docs/system/` directory

## Tools

### map-relationships.sh

This script maps relationships between entities in the codebase.

The script performs the following operations:
- Maps function call dependencies
- Maps component dependencies
- Maps configuration dependencies
- Maps import relationships
- Maps data flow relationships
- Saves the mapped relationships to JSON files in the `docs/knowledge-graph/relationships/` directory

#### Usage

To map relationships from all shell scripts and YAML documentation:

```bash
./tools/relationship-mapping/map-relationships.sh
```

To map relationships from a specific shell script:

```bash
./tools/relationship-mapping/map-relationships.sh /path/to/script.sh
```

To map relationships from YAML documentation only:

```bash
./tools/relationship-mapping/map-relationships.sh --yaml
```

## Output Files

The relationship mapping tools generate the following output files:

- `docs/knowledge-graph/relationships/function_calls.json`: Function call dependencies
- `docs/knowledge-graph/relationships/component_dependencies.json`: Component dependencies
- `docs/knowledge-graph/relationships/config_dependencies.json`: Configuration dependencies
- `docs/knowledge-graph/relationships/imports.json`: Import relationships
- `docs/knowledge-graph/relationships/data_flows.json`: Data flow relationships

## Relationship Structure

### Function Calls

Function call relationships are mapped with the following information:
- **Source**: The function making the call
- **Target**: The function being called
- **Description**: A description of the call

Example:
```json
{
  "@id": "llm:call_validate_config_validate_port",
  "@type": "llm:Calls",
  "name": "validate_config_calls_validate_port",
  "description": "Function validate_config calls function validate_port",
  "source": "llm:config_validate_config",
  "target": "llm:validation_validate_port"
}
```

### Component Dependencies

Component dependency relationships are mapped with the following information:
- **Source**: The component that depends on another
- **Target**: The component being depended on
- **Description**: A description of the dependency

Example:
```json
{
  "@id": "llm:dependency_librechat_ollama",
  "@type": "llm:DependsOn",
  "name": "librechat_depends_on_ollama",
  "description": "LibreChat requires Ollama for LLM inference",
  "source": "llm:librechat",
  "target": "llm:ollama"
}
```

### Configuration Dependencies

Configuration dependency relationships are mapped with the following information:
- **Source**: The function using the configuration parameter
- **Target**: The configuration parameter being used
- **Description**: A description of the dependency

Example:
```json
{
  "@id": "llm:config_dependency_validate_config_HOST_PORT_OLLAMA",
  "@type": "llm:Configures",
  "name": "validate_config_uses_HOST_PORT_OLLAMA",
  "description": "Function validate_config uses configuration parameter HOST_PORT_OLLAMA",
  "source": "llm:config_validate_config",
  "target": "llm:config_HOST_PORT_OLLAMA"
}
```

### Import Relationships

Import relationships are mapped with the following information:
- **Source**: The module importing another
- **Target**: The module being imported
- **Description**: A description of the import
- **File Path**: The path to the file containing the import
- **Line Number**: The line number where the import is defined

Example:
```json
{
  "@id": "llm:import_config_logging",
  "@type": "llm:Imports",
  "name": "config_imports_logging",
  "description": "Module config imports module logging",
  "source": "llm:config",
  "target": "llm:logging",
  "filePath": "lib/core/config.sh",
  "lineNumber": 13
}
```

### Data Flow Relationships

Data flow relationships are mapped with the following information:
- **Source**: The component sending data
- **Target**: The component receiving data
- **Data**: The type of data being sent
- **Format**: The format of the data
- **Transport**: The transport mechanism
- **Step Number**: The step number in the data flow
- **Data Flow**: The data flow this step belongs to

Example:
```json
{
  "@id": "llm:dataflow_user_interaction_step_3",
  "@type": "llm:DataFlow",
  "name": "user_interaction_step_3",
  "description": "librechat_backend sends inference_request to ollama",
  "source": "llm:librechat_backend",
  "target": "llm:ollama",
  "data": "inference_request",
  "format": "json",
  "transport": "http",
  "stepNumber": 3,
  "dataFlow": "llm:dataflow_user_interaction"
}
```

## Dependencies

These tools have the following dependencies:
- `jq`: For processing JSON files
- `grep`: For pattern matching
- `sed`: For text processing

## Integration with Knowledge Graph

The relationships mapped by these tools are used to generate the Knowledge Graph. The Knowledge Graph generation process:
1. Extracts entities from the codebase
2. Maps relationships between entities using these tools
3. Generates the Knowledge Graph in JSON-LD format
4. Creates visualizations of the Knowledge Graph

For more information on the Knowledge Graph, see the [Knowledge Graph Usage Guide](../../docs/knowledge-graph/usage.md).

## Extending Relationship Mapping

To add support for mapping new types of relationships:

1. Create a new function in `map-relationships.sh` to map the new relationship type
2. Add the new function to the `map_all_relationships` function
3. Create a new output file for the new relationship type
4. Update the Knowledge Graph generation script to include the new relationship type

Example of a new relationship mapping function:

```bash
# Map new relationship type
map_new_relationship_type() {
    local output_file="$RELATIONSHIPS_DIR/new_relationship_type.json"
    
    echo "Mapping new relationship type..."
    
    # Initialize the output file
    echo "[]" > "$output_file"
    
    # Map relationships
    # ...
    
    echo -e "${GREEN}Mapped new relationship type${NC}"
}