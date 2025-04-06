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
- [GitLab Automation](docs/gitlab-automation.md) - Instructions for automating the GitLab repository setup.
- [Maintaining Documentation](docs/maintaining-documentation.md) - Guidelines for maintaining the AI-optimized documentation.

### System Documentation

The LOCAL-LLM-Stack includes comprehensive AI-optimized documentation:

- **Machine-Readable Schema**: Structured documentation schema in `docs/schema/`
- **System Components**: Detailed component documentation in `docs/system/`
- **System Relationships**: Relationship mapping between components
- **System Interfaces**: Interface definitions for component interactions
- **Documentation Templates**: Templates for creating new documentation in `docs/templates/`

### Knowledge Graph

The codebase includes a knowledge graph system for better understanding of the architecture:

- **Entity Extraction**: Tools for extracting entities from the codebase in `tools/entity-extraction/`
- **Relationship Mapping**: Tools for mapping relationships between entities in `tools/relationship-mapping/`
- **Graph Visualization**: Visualizations of the system architecture in `docs/diagrams/`
- **Automated Updates**: Git hooks and CI/CD integration for keeping the knowledge graph up-to-date

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

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Copyright (c) 2025 MINT-RESEARCH