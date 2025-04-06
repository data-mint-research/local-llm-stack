# LOCAL-LLM-Stack Architecture

This document provides a detailed overview of the LOCAL-LLM-Stack architecture, including components, interactions, configuration, and data flow.

## Table of Contents

1. [System Overview](#system-overview)
2. [Component Details](#component-details)
3. [Configuration System](#configuration-system)
4. [Data Flow](#data-flow)
5. [Startup Process](#startup-process)
6. [Health Check System](#health-check-system)

## System Overview

The LOCAL-LLM-Stack is a Docker Compose-based system that integrates multiple components to provide a complete local LLM (Large Language Model) solution. The system is designed to run entirely on the user's machine without requiring external API access.

### High-Level Architecture

```
┌─────────────────┐     ┌─────────────────┐
│                 │     │                 │
│    LibreChat    │◄────┤     Ollama      │
│  (Web Interface)│     │  (LLM Inference)│
│                 │     │                 │
└────────┬────────┘     └─────────────────┘
         │
         │
         ▼
┌─────────────────┐     ┌─────────────────┐
│                 │     │                 │
│    MongoDB      │     │   Meilisearch   │
│   (Database)    │     │    (Search)     │
│                 │     │                 │
└─────────────────┘     └─────────────────┘
```

All components are connected via a Docker network called `llm-stack-network`, allowing them to communicate with each other using their container names as hostnames.

## Component Details

### Ollama

**Purpose**: Provides local LLM inference capabilities.

**Details**:
- **Image**: ollama/ollama:${OLLAMA_VERSION:-0.1.27}
- **Port**: ${HOST_PORT_OLLAMA:-11434}:11434
- **Data Volumes**:
  - ../data/ollama:/root/.ollama
  - ../data/models:/models
- **Environment Variables**:
  - OLLAMA_HOST=0.0.0.0
  - OLLAMA_MODELS_PATH=/root/.ollama/models
- **Resource Limits**:
  - CPU: ${OLLAMA_CPU_LIMIT:-0.75}
  - Memory: ${OLLAMA_MEMORY_LIMIT:-16G}
- **Health Check**:
  - Command: `bash -c "(echo > /dev/tcp/localhost/11434) 2>/dev/null || exit 1"`
  - Interval: 30s
  - Timeout: 10s
  - Retries: 3
  - Start Period: 40s

### LibreChat

**Purpose**: Provides a web interface for interacting with LLMs.

**Details**:
- **Image**: librechat/librechat:${LIBRECHAT_VERSION:-latest}
- **Port**: ${HOST_PORT_LIBRECHAT:-3080}:3080
- **Debug Port**: 9229:9229 (only in debug mode)
- **Data Volumes**:
  - ../data/librechat:/app/data
- **Environment Variables**:
  - MONGO_URI=mongodb://mongodb:27017/librechat
  - OLLAMA_HOST=http://ollama:11434
  - JWT_SECRET, JWT_REFRESH_SECRET, etc.
- **Resource Limits**:
  - CPU: ${LIBRECHAT_CPU_LIMIT:-0.50}
  - Memory: ${LIBRECHAT_MEMORY_LIMIT:-4G}
- **Health Check**:
  - Command: `wget -q --spider http://localhost:3080/health || exit 1`
  - Interval: 30s
  - Timeout: 10s
  - Retries: 3
  - Start Period: 40s

### MongoDB

**Purpose**: Provides database storage for LibreChat.

**Details**:
- **Image**: mongo:${MONGODB_VERSION:-6.0.6}
- **Data Volumes**:
  - ../data/mongodb:/data/db
- **Resource Limits**:
  - Memory: ${MONGODB_MEMORY_LIMIT:-2G}
- **Health Check**:
  - Command: `mongosh --eval "db.adminCommand('ping')"`
  - Interval: 30s
  - Timeout: 10s
  - Retries: 3
  - Start Period: 40s

### Meilisearch

**Purpose**: Provides search capabilities for LibreChat.

**Details**:
- **Image**: getmeili/meilisearch:${MEILISEARCH_VERSION:-latest}
- **Data Volumes**:
  - ../data/meilisearch:/meili_data
- **Environment Variables**:
  - MEILI_NO_ANALYTICS=true
  - MEILI_ENV=production
  - MEILI_MASTER_KEY=masterKey123456789
- **Resource Limits**:
  - Memory: ${MEILISEARCH_MEMORY_LIMIT:-1G}
- **Health Check**:
  - Command: `wget -q --spider http://127.0.0.1:7700/health || exit 1`
  - Interval: 30s
  - Timeout: 10s
  - Retries: 3
  - Start Period: 40s

## Configuration System

The LOCAL-LLM-Stack uses a multi-layered configuration system:

### Main Configuration

The main configuration file (`config/.env`) contains global settings for all components:

- Component versions
- Port configurations
- Resource limits
- Security settings
- Authentication settings

### Component-Specific Configuration

Each component may have its own configuration file:

- **LibreChat**: `config/librechat/.env`

### Configuration Synchronization

The system includes mechanisms to keep configurations synchronized:

1. The `check_secrets` function in `lib/common.sh` checks for empty secrets before starting services
2. The `generate_secrets.sh` script generates secure random values for all secret fields
3. The `update_librechat_secrets.sh` script ensures that LibreChat's configuration is synchronized with the main configuration

## Data Flow

### User Interaction Flow

1. User accesses LibreChat web interface at http://localhost:3080
2. User authenticates with email/password
3. User sends a message to the LLM
4. LibreChat forwards the message to Ollama
5. Ollama processes the message using the selected model
6. Ollama returns the response to LibreChat
7. LibreChat displays the response to the user
8. LibreChat stores the conversation in MongoDB
9. LibreChat indexes the conversation in Meilisearch for future search

### Model Loading Flow

1. User requests to use a specific model
2. LibreChat forwards the request to Ollama
3. Ollama checks if the model is already loaded
4. If not, Ollama downloads the model from the Ollama model repository
5. Ollama loads the model into memory
6. Ollama returns the model information to LibreChat
7. LibreChat displays the model information to the user

## Startup Process

The LOCAL-LLM-Stack uses a carefully orchestrated startup process to ensure all components are properly initialized:

1. **Configuration Check**:
   - The `check_secrets` function checks for missing secrets
   - If secrets are missing, they are generated

2. **Network Creation**:
   - Docker Compose creates the `llm-stack-network` if it doesn't exist

3. **Container Startup**:
   - MongoDB and Meilisearch are started first
   - Ollama is started next
   - LibreChat is started last, with dependencies on the other services

4. **Health Checks**:
   - Each container performs health checks to ensure it's running correctly
   - If a health check fails, the container is restarted
   - LibreChat waits for other services to be healthy before starting

5. **Initialization**:
   - LibreChat initializes its database connection
   - LibreChat loads its configuration
   - LibreChat starts its web server

## Health Check System

The LOCAL-LLM-Stack includes a comprehensive health check system to ensure all components are running correctly:

### Ollama Health Check

```yaml
healthcheck:
  test: ["CMD", "bash", "-c", "(echo > /dev/tcp/localhost/11434) 2>/dev/null || exit 1"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

This health check uses bash's `/dev/tcp` feature to check if port 11434 is accessible. If the port is not accessible, the health check fails.

### LibreChat Health Check

```yaml
healthcheck:
  test: ["CMD-SHELL", "wget -q --spider http://localhost:3080/health || exit 1"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

This health check uses `wget` to check if the `/health` endpoint is accessible. If the endpoint is not accessible, the health check fails.

### MongoDB Health Check

```yaml
healthcheck:
  test: ["CMD", "mongosh", "--eval", "db.adminCommand('ping')"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

This health check uses `mongosh` to ping the database. If the ping fails, the health check fails.

### Meilisearch Health Check

```yaml
healthcheck:
  test: ["CMD-SHELL", "wget -q --spider http://127.0.0.1:7700/health || exit 1"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

This health check uses `wget` to check if the `/health` endpoint is accessible. If the endpoint is not accessible, the health check fails.

## Debugging and Monitoring

The LOCAL-LLM-Stack includes several features for debugging and monitoring:

### Debug Mode

The system can be started in debug mode using:

```bash
./llm debug
```

This mode:
- Exposes the Node.js debugger port (9229) for LibreChat
- Enables more verbose logging
- Allows attaching a debugger to the LibreChat process

### Container Logs

Container logs can be viewed using:

```bash
docker logs librechat
docker logs ollama
docker logs mongodb
docker logs meilisearch
```

### Health Status

The health status of all containers can be viewed using:

```bash
docker ps
```

This shows the status of each container, including its health status.

### Detailed Health Information

Detailed health information for a container can be viewed using:

```bash
docker inspect --format='{{json .State.Health}}' ollama | jq
```

This shows the results of the last few health checks, including any error messages.