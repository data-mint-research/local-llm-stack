# Getting Started with LOCAL-LLM-Stack

This guide will walk you through the process of setting up and using the LOCAL-LLM-Stack, a complete solution for running Large Language Models locally.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Starting the Stack](#starting-the-stack)
4. [Using LibreChat](#using-librechat)
5. [Managing Models](#managing-models)
6. [Troubleshooting](#troubleshooting)
7. [Next Steps](#next-steps)

## Prerequisites

Before you begin, ensure you have the following installed on your system:

- **Docker**: Version 20.10.0 or higher
- **Docker Compose**: Version 2.0.0 or higher
- **Bash**: For running the management scripts
- **Curl**: For testing API endpoints
- **Git**: For cloning the repository (optional)

### Hardware Requirements

- **CPU**: 4+ cores recommended
- **RAM**: 16GB+ recommended (depends on the models you plan to use)
- **Disk Space**: 10GB+ for the stack, plus additional space for models (varies by model)
- **GPU**: Optional but recommended for better performance

## Installation

1. Clone the repository or download the source code:

```bash
git clone https://github.com/example/LOCAL-LLM-Stack.git
cd LOCAL-LLM-Stack
```

2. Make the management script executable:

```bash
chmod +x llm
```

3. Generate secure secrets for the configuration:

```bash
./llm generate-secrets
```

This will create random secure values for all secret fields and display the admin password. **Make sure to save this password** as you'll need it to log in to LibreChat.

> **Note:** The system now automatically checks for missing secrets when starting the stack and generates them if needed. You typically won't need to run this command manually.

## Starting the Stack

1. Start all components:

```bash
./llm start
```

This will start all components (Ollama, LibreChat, MongoDB, and Meilisearch) in the background.

2. Check the status of all components:

```bash
./llm status
```

This will display the status of all containers, including their health status and exposed ports.

3. Wait for all components to become healthy. This may take a few minutes, especially on the first run when models need to be downloaded.

## Using LibreChat

1. Open your web browser and navigate to:

```
http://localhost:3080
```

2. Log in with the admin credentials:
   - **Email**: admin@local.host
   - **Password**: The password displayed when you ran `./llm generate-secrets`

3. Create a new chat:
   - Click on the "New Chat" button
   - Select "Ollama" as the model provider
   - Select a model from the dropdown (e.g., "tinyllama")

4. Start chatting with the model:
   - Type your message in the input field
   - Press Enter or click the Send button
   - Wait for the model to generate a response

## Managing Models

The LOCAL-LLM-Stack includes commands for managing Ollama models:

1. List available models:

```bash
./llm models list
```

2. Add a new model:

```bash
./llm models add llama3
```

This will download and install the specified model. The download may take some time depending on the model size and your internet connection.

3. Remove a model:

```bash
./llm models remove mistral
```

This will remove the specified model from Ollama.

## Troubleshooting

If you encounter any issues, check the [Troubleshooting Guide](troubleshooting.md) for solutions to common problems.

### Common Issues

1. **Container Health Check Failing**:
   - Check the container logs: `docker logs ollama`
   - Ensure the required ports are not in use by other applications
   - Check if your system meets the hardware requirements

2. **Authentication Issues**:
   - Ensure the JWT secrets are properly set in the configuration
   - Try regenerating the secrets: `./llm generate-secrets`
   - Check the LibreChat logs for authentication errors: `docker logs librechat`

3. **Model Loading Issues**:
   - Check if you have enough disk space for the model
   - Check if you have enough RAM for the model
   - Check the Ollama logs for model loading errors: `docker logs ollama`

## Next Steps

Now that you have the LOCAL-LLM-Stack up and running, here are some next steps to explore:

### Customizing the Configuration

You can customize the configuration by editing the `config/.env` file:

```bash
./llm config edit
```

This will open the configuration file in your default editor. After making changes, restart the stack:

```bash
./llm stop
./llm start
```

### Adding More Models

Explore different models available for Ollama:

```bash
./llm models list
```

Add models that suit your needs:

```bash
./llm models add llama3
./llm models add mistral
./llm models add codellama
```

### Exploring Advanced Features

- **Debug Mode**: Start the stack in debug mode for development and troubleshooting:
  ```bash
  ./llm debug
  ```

- **Custom Prompts**: Experiment with different prompts and system messages in LibreChat to get better results from the models.

- **RAG (Retrieval-Augmented Generation)**: Upload documents to LibreChat and use them as context for your conversations.

### Learning More

- Read the [Architecture Guide](architecture.md) to understand how the system works
- Read the [Security Guide](security.md) for information about security aspects
- Explore the documentation for each component:
  - [Ollama Documentation](https://github.com/ollama/ollama)
  - [LibreChat Documentation](https://docs.librechat.ai/)

## Stopping the Stack

When you're done using the LOCAL-LLM-Stack, you can stop all components:

```bash
./llm stop
```

This will stop all containers, but your data will be preserved in the `../data` directory.

## Updating the Stack

To update the LOCAL-LLM-Stack to the latest version:

1. Pull the latest changes:

```bash
git pull
```

2. Restart the stack:

```bash
./llm stop
./llm start
```

This will pull the latest images for all components and restart the stack.