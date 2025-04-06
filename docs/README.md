# LOCAL-LLM-Stack Documentation

This directory contains documentation for the LOCAL-LLM-Stack project.

## Available Documentation

- [Getting Started Guide](getting-started.md) - Step-by-step guide to setting up and using the LOCAL-LLM-Stack.
- [Troubleshooting Guide](troubleshooting.md) - Solutions to common issues you might encounter when running the LOCAL-LLM-Stack.
- [Architecture Guide](architecture.md) - Detailed overview of the system architecture, components, and data flow.
- [Security Guide](security.md) - Information about security aspects, authentication, and best practices.
- [GitLab Setup Guide](gitlab-setup.md) - Instructions for creating a private GitLab repository and pushing the project.
- [GitLab Automation Guide](gitlab-automation.md) - Instructions for automating the GitLab repository setup process.

## Getting Started

If you're new to the LOCAL-LLM-Stack, here's how to get started:

1. Start the stack:
   ```bash
   ./llm start
   ```

2. For development or debugging:
   ```bash
   ./llm debug
   ```

3. Check the status of all components:
   ```bash
   ./llm status
   ```

4. Stop the stack:
   ```bash
   ./llm stop
   ```

5. Manage models:
   ```bash
   ./llm models list
   ./llm models add llama3
   ```

## Configuration

The stack is configured through environment variables in the `config/.env` file. You can generate secure secrets for the configuration using:

```bash
./llm generate-secrets
```

> **Note:** The system now automatically checks for missing secrets when starting the stack and generates them if needed. You typically won't need to run this command manually.

### Configuration Files

The LOCAL-LLM-Stack uses multiple configuration files:

1. **Main Configuration** (`config/.env`): Contains global settings, component versions, resource limits, and security settings.
2. **LibreChat Configuration** (`config/librechat/.env`): Contains LibreChat-specific settings, including database connection, API endpoints, and authentication settings.

The system includes mechanisms to keep these configurations synchronized:

- The `check_secrets` function in `lib/common.sh` checks for empty secrets before starting services
- The `generate_secrets.sh` script generates secure random values for all required secrets
- The `update_librechat_secrets.sh` script ensures that LibreChat's configuration is synchronized with the main configuration

## System Architecture

The LOCAL-LLM-Stack is built using Docker Compose to orchestrate multiple containers that work together:

### Components

- **Ollama**: Local LLM inference server
  - Runs on port 11434
  - Provides API for model inference
  - Supports multiple models (llama, mistral, etc.)

- **LibreChat**: Web interface for interacting with LLMs
  - Runs on port 3080
  - Connects to Ollama for model inference
  - Uses MongoDB for data storage
  - Uses Meilisearch for conversation search

- **MongoDB**: Database for storing conversations and user data
  - Used by LibreChat to store conversations, user data, and settings
  - Data persisted in `../data/mongodb`

- **Meilisearch**: Search engine for conversation history
  - Provides fast search capabilities for LibreChat
  - Data persisted in `../data/meilisearch`

### Networking

All components are connected via a Docker network called `llm-stack-network`. This allows containers to communicate with each other using their container names as hostnames.

### Health Checks

Each container includes health checks to ensure it's running correctly:

- **Ollama**: Checks if port 11434 is accessible using bash's `/dev/tcp` feature
- **MongoDB**: Uses `mongosh` to ping the database
- **Meilisearch**: Checks if the HTTP health endpoint is accessible
- **LibreChat**: Checks if the HTTP health endpoint is accessible

### Data Persistence

All data is persisted in the `../data` directory:

- **Ollama Models**: `../data/ollama` and `../data/models`
- **MongoDB Data**: `../data/mongodb`
- **Meilisearch Data**: `../data/meilisearch`

## Security Considerations

The LOCAL-LLM-Stack includes several security features:

1. **JWT Authentication**: LibreChat uses JWT tokens for authentication, which requires secure random secrets
2. **Automatic Secret Generation**: The system automatically generates secure random secrets if they're not set
3. **Configuration Backup**: Before making changes to configuration files, the system creates backups
4. **Container Isolation**: Each component runs in its own container with limited permissions

## Advanced Usage

### Custom Models

You can add custom models to Ollama:

```bash
./llm models add llama3
```

### Debugging

For debugging issues with the stack, you can:

1. Check container logs:
   ```bash
   docker logs librechat
   docker logs ollama
   ```

2. Check container health:
   ```bash
   docker inspect --format='{{json .State.Health}}' ollama | jq
   ```

3. Test inter-container communication:
   ```bash
   docker exec -it librechat curl -s http://ollama:11434/api/version
   ```

## Additional Resources

- For more detailed information about each component, refer to their respective documentation:
  - [Ollama Documentation](https://github.com/ollama/ollama)
  - [LibreChat Documentation](https://docs.librechat.ai/)
  - [MongoDB Documentation](https://www.mongodb.com/docs/)
  - [Meilisearch Documentation](https://www.meilisearch.com/docs)