# LOCAL-LLM-Stack

A complete system for running Large Language Models (LLMs) locally with a user-friendly web interface.

Developed by [MINT-RESEARCH](https://mint-research.com)

## Overview

LOCAL-LLM-Stack integrates multiple components to provide a complete solution for local LLMs:

- **Ollama**: Local LLM inference server
- **LibreChat**: Web interface for interacting with LLMs
- **MongoDB**: Database for storing conversations and user data
- **Meilisearch**: Search engine for conversation history

## Prerequisites

- **Docker**: Version 20.10.0 or higher
- **Docker Compose**: Version 2.0.0 or higher
- **Bash**: For running management scripts
- **Curl**: For testing API endpoints
- **Git**: For cloning the repository

### Hardware Requirements

- **CPU**: 4+ cores recommended
- **RAM**: 16GB+ recommended (depends on the models you plan to use)
- **Disk Space**: 10GB+ for the system, plus additional space for models
- **GPU**: Optional but recommended for better performance

## Installation

1. Clone the repository:

```bash
git clone https://gitlab.com/your-username/LOCAL-LLM-Stack.git
cd LOCAL-LLM-Stack
```

2. Make the management script executable:

```bash
chmod +x llm
```

3. Start the stack:

```bash
./llm start
```

The system automatically checks for missing secrets and generates them if needed. On first start, it will download the required Docker images and start the containers.

4. Open the LibreChat web interface:

```
http://localhost:3080
```

5. Log in with the admin credentials:
   - **Email**: admin@local.host
   - **Password**: The password generated during startup (shown in the console output)

## Usage

### Stack Management

- **Start the stack**:
  ```bash
  ./llm start
  ```

- **Stop the stack**:
  ```bash
  ./llm stop
  ```

- **Check stack status**:
  ```bash
  ./llm status
  ```

- **Start debug mode**:
  ```bash
  ./llm debug
  ```

### Model Management

- **List available models**:
  ```bash
  ./llm models list
  ```

- **Add a new model**:
  ```bash
  ./llm models add llama3
  ```

- **Remove a model**:
  ```bash
  ./llm models remove mistral
  ```

### Configuration

- **Show configuration**:
  ```bash
  ./llm config show
  ```

- **Edit configuration**:
  ```bash
  ./llm config edit
  ```

- **Generate secure secrets**:
  ```bash
  ./llm generate-secrets
  ```

## Documentation

Detailed documentation can be found in the `docs/` directory:

- [Getting Started](docs/getting-started.md) - Step-by-step guide to setting up and using the LOCAL-LLM-Stack.
- [Troubleshooting](docs/troubleshooting.md) - Solutions to common issues when using the LOCAL-LLM-Stack.
- [Architecture](docs/architecture.md) - Detailed overview of the system architecture, components, and data flow.
- [Security](docs/security.md) - Information about security aspects, authentication, and best practices.
- [Documentation Style Guide](docs/documentation-style-guide.md) - Standards and guidelines for documentation.
- [Maintaining Documentation](docs/maintaining-documentation.md) - Guidelines for keeping documentation up-to-date.

### System Documentation

The LOCAL-LLM-Stack includes comprehensive machine-readable documentation:

- **Documentation Schema**: Structured documentation schema in `docs/schema/system-schema.yaml`
- **System Components**: Detailed component documentation in `docs/system/components.yaml`
- **System Relationships**: Relationship mapping between components in `docs/system/relationships.yaml`
- **System Interfaces**: Interface definitions for component interactions in `docs/system/interfaces.yaml`
- **Documentation Templates**: Templates for creating new documentation in `docs/templates/`

### Visual Documentation

The system architecture is visualized through various diagrams:

- **Component Architecture**: High-level view of system components in `docs/diagrams/component-architecture.mmd`
- **Deployment Architecture**: Deployment structure in `docs/diagrams/deployment-architecture.mmd`
- **System Relationships**: Component relationships in `docs/diagrams/system-relationships.mmd`
- **Data Flow**: Data flow between components in `docs/diagrams/system-data-flow.mmd`

### Documentation Tools

The LOCAL-LLM-Stack includes tools for maintaining documentation:

- **Documentation Extraction**: Tools for extracting documentation from code in `tools/doc-sync/extract-docs.sh`
- **Documentation Validation**: Tools for validating documentation in `tools/doc-sync/validate-docs.sh`
- **Git Hooks**: Automated documentation checks in `tools/doc-sync/git-hooks/`

## Data Directories

All data is stored in the `data/` directory:

- **Ollama Models**: `data/ollama` and `data/models`
- **MongoDB Data**: `data/mongodb`
- **Meilisearch Data**: `data/meilisearch`
- **LibreChat Data**: `data/librechat`

These directories are listed in the `.gitignore` file and are not stored in the repository. They will be created on the first start of the stack.

## Shell Script Library

The LOCAL-LLM-Stack includes a structured shell script library for better maintainability:

- **Core Modules**: Standardized modules in `lib/core/` for common operations
- **Configuration**: Centralized configuration handling in `lib/core/config.sh`
- **Docker Operations**: Docker-related functions in `lib/core/docker.sh`
- **Validation**: Input validation functions in `lib/core/validation.sh`
- **System Operations**: System-related functions in `lib/core/system.sh`
- **Error Handling**: Standardized error handling in `lib/core/error.sh`
- **Logging**: Consistent logging functions in `lib/core/logging.sh`

## Contributing

Contributions are welcome! Please create a fork of the repository and submit a pull request.

Before contributing, please:

1. Read the [Documentation Style Guide](docs/documentation-style-guide.md)
2. Install the Git hooks for documentation validation:
   ```bash
   ./tools/doc-sync/git-hooks/install-hooks.sh
   ```
3. Ensure all documentation is up-to-date with your code changes

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Copyright (c) 2025 MINT-RESEARCH