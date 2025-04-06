# Entity Extraction Tools

This directory contains tools for extracting entities from the LOCAL-LLM-Stack codebase.

## Overview

Entity extraction is the process of identifying and extracting structured information about entities in the codebase, such as:

- **Functions**: Shell functions with their parameters and return values
- **Variables**: Shell variables with their values and scope
- **Components**: System components like containers, scripts, and libraries
- **Configuration Parameters**: Configuration parameters with their default values
- **Services**: Services provided by components to other components

These entities are extracted from:
- Shell scripts (`.sh` files)
- YAML documentation files in the `docs/system/` directory

## Tools

### extract-entities.sh

This script extracts entities from shell scripts and YAML documentation files.

The script performs the following operations:
- Extracts functions from shell scripts
- Extracts variables from shell scripts
- Extracts configuration parameters from shell scripts
- Extracts components from YAML documentation
- Extracts services from YAML documentation
- Saves the extracted entities to JSON files in the `docs/knowledge-graph/entities/` directory

#### Usage

To extract entities from all shell scripts and YAML documentation:

```bash
./tools/entity-extraction/extract-entities.sh
```

To extract entities from a specific shell script:

```bash
./tools/entity-extraction/extract-entities.sh /path/to/script.sh
```

To extract entities from YAML documentation only:

```bash
./tools/entity-extraction/extract-entities.sh --yaml
```

## Output Files

The entity extraction tools generate the following output files:

- `docs/knowledge-graph/entities/functions.json`: Functions extracted from shell scripts
- `docs/knowledge-graph/entities/variables.json`: Variables extracted from shell scripts
- `docs/knowledge-graph/entities/config_params.json`: Configuration parameters extracted from shell scripts
- `docs/knowledge-graph/entities/components.json`: Components extracted from YAML documentation
- `docs/knowledge-graph/entities/services.json`: Services extracted from YAML documentation

## Entity Structure

### Functions

Functions are extracted with the following information:
- **Name**: The name of the function
- **Description**: The description of the function (from comments above the function)
- **File Path**: The path to the file containing the function
- **Line Number**: The line number where the function is defined
- **Parameters**: The parameters of the function (extracted from parameter references in the function body)
- **Return Type**: The return type of the function (inferred from return statements)
- **Return Description**: The description of the return value

Example:
```json
{
  "@id": "llm:config_load_config",
  "@type": "llm:Function",
  "name": "load_config",
  "description": "Load configuration from .env file",
  "filePath": "lib/core/config.sh",
  "lineNumber": 50,
  "parameters": [
    {
      "name": "param1",
      "description": "Path to .env file (defaults to $ENV_FILE)",
      "type": "string",
      "required": false
    }
  ],
  "returnType": "integer",
  "returnDescription": "Error code (0 for success, non-zero for failure)",
  "module": "llm:config"
}
```

### Variables

Variables are extracted with the following information:
- **Name**: The name of the variable
- **Description**: The description of the variable (from comments above the variable)
- **File Path**: The path to the file containing the variable
- **Line Number**: The line number where the variable is defined
- **Value**: The value of the variable
- **Readonly**: Whether the variable is readonly
- **Exported**: Whether the variable is exported

Example:
```json
{
  "@id": "llm:config_DEFAULT_CONFIG_DIR",
  "@type": "llm:Variable",
  "name": "DEFAULT_CONFIG_DIR",
  "description": "Default configuration directory",
  "filePath": "lib/core/config.sh",
  "lineNumber": 19,
  "value": "config",
  "readonly": true,
  "exported": false,
  "module": "llm:config"
}
```

### Configuration Parameters

Configuration parameters are extracted with the following information:
- **Name**: The name of the parameter
- **Description**: The description of the parameter (from comments above the reference)
- **File Path**: The path to the file containing the reference
- **Line Number**: The line number where the parameter is referenced
- **Default Value**: The default value of the parameter (if provided)

Example:
```json
{
  "@id": "llm:config_HOST_PORT_OLLAMA",
  "@type": "llm:ConfigParam",
  "name": "HOST_PORT_OLLAMA",
  "description": "Host port for Ollama API",
  "filePath": "lib/core/config.sh",
  "lineNumber": 225,
  "defaultValue": "11434"
}
```

### Components

Components are extracted with the following information:
- **Name**: The name of the component
- **Type**: The type of the component (container, script, library, module)
- **Description**: The purpose of the component

Example:
```json
{
  "@id": "llm:ollama",
  "@type": "llm:Container",
  "name": "ollama",
  "description": "Provides local LLM inference capabilities"
}
```

### Services

Services are extracted with the following information:
- **Name**: The name of the service
- **Description**: The description of the service
- **Provider**: The component providing the service
- **Consumer**: The component consuming the service
- **Interface**: The interface used for the service

Example:
```json
{
  "@id": "llm:service_ollama_librechat",
  "@type": "llm:Service",
  "name": "ollama_librechat_service",
  "description": "Ollama provides LLM inference to LibreChat",
  "provider": "llm:ollama",
  "consumer": "llm:librechat",
  "interface": "http_api"
}
```

## Dependencies

These tools have the following dependencies:
- `jq`: For processing JSON files
- `grep`: For pattern matching
- `sed`: For text processing

## Integration with Knowledge Graph

The entities extracted by these tools are used to generate the Knowledge Graph. The Knowledge Graph generation process:
1. Extracts entities using these tools
2. Maps relationships between entities
3. Generates the Knowledge Graph in JSON-LD format
4. Creates visualizations of the Knowledge Graph

For more information on the Knowledge Graph, see the [Knowledge Graph Usage Guide](../../docs/knowledge-graph/usage.md).