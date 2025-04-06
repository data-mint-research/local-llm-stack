# LOCAL-LLM-Stack Troubleshooting Guide

This document provides solutions to common issues you might encounter when running the LOCAL-LLM-Stack.

## Table of Contents

1. [Container Health Check Issues](#container-health-check-issues)
2. [Authentication and Secret Issues](#authentication-and-secret-issues)
3. [Network and Connectivity Issues](#network-and-connectivity-issues)
4. [Configuration Synchronization Issues](#configuration-synchronization-issues)
5. [Verifying the Stack is Working](#verifying-the-stack-is-working)

## Container Health Check Issues

### Ollama Container Health Check Failing

**Symptoms:**
- The ollama container is marked as "unhealthy"
- The librechat container fails to start with a dependency error
- Error message: `dependency failed to start: container ollama is unhealthy`
- Repeated container restarts

**Possible Causes:**
1. The health check command is using `/dev/tcp` feature which is bash-specific
2. The container is using `sh` instead of `bash` for the health check
3. The ollama service is not actually running

**Solution:**
1. Modify the health check in `core/docker-compose.yml` to explicitly use bash:

```yaml
healthcheck:
  test: ["CMD", "bash", "-c", "(echo > /dev/tcp/localhost/11434) 2>/dev/null || exit 1"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

2. Restart the services:

```bash
./llm stop
./llm debug  # or ./llm start
```

**Technical Details:**
The `/dev/tcp` feature is specific to bash and not available in other shells like sh or dash. When the health check tries to use this feature with sh, it fails because sh doesn't support it. By explicitly specifying bash as the shell to use for the health check, we ensure that the `/dev/tcp` feature is available.

## Authentication and Secret Issues

### LibreChat Container Failing to Start

**Symptoms:**
- The librechat container starts but then crashes
- Error message: `There was an uncaught error: JwtStrategy requires a secret or key`
- The container logs show authentication-related errors

**Possible Causes:**
1. Missing JWT secrets in the configuration
2. Empty values for required security settings
3. Mismatch between secrets in main config and LibreChat config

**Solution:**
1. Generate secure secrets using the provided script:

```bash
./llm generate-secrets
```

This will create random secure values for:
- JWT_SECRET
- JWT_REFRESH_SECRET
- SESSION_SECRET
- CRYPT_SECRET
- CREDS_KEY
- CREDS_IV
- ADMIN_PASSWORD
- GRAFANA_ADMIN_PASSWORD

2. Restart the services:

```bash
./llm stop
./llm debug  # or ./llm start
```

3. Note the admin password displayed after running the generate-secrets command, as you'll need it to log in to LibreChat.

> **Note:** As of the latest update, the system now automatically checks for missing secrets when starting the stack and generates them if needed. This should prevent this issue from occurring in the first place.

**Technical Details:**
LibreChat uses JWT (JSON Web Tokens) for authentication, which requires a secret key to sign and verify tokens. If this secret is missing or empty, the authentication system fails to initialize, causing the application to crash. The system now has multiple layers of protection:

1. The `check_secrets` function in `lib/common.sh` checks for empty secrets before starting services
2. The `generate_secrets.sh` script generates secure random values for all required secrets
3. The `update_librechat_secrets.sh` script ensures that LibreChat's configuration is synchronized with the main configuration

## Network and Connectivity Issues

### Services Cannot Communicate with Each Other

**Symptoms:**
- Services start but cannot connect to each other
- Error messages about connection refused or host not found
- Services appear healthy but functionality is limited

**Possible Causes:**
1. Docker network issues
2. Incorrect hostnames in configuration
3. Ports not properly exposed

**Solution:**
1. Ensure all services are on the same Docker network:

```yaml
networks:
  - llm-stack-network
```

2. Use container names for inter-service communication:

```
MONGO_URI=mongodb://mongodb:27017/librechat
MEILI_HOST=http://meilisearch:7700
OLLAMA_HOST=http://ollama:11434
```

3. Check if ports are properly exposed in the docker-compose.yml file:

```yaml
ports:
  - "${HOST_PORT_OLLAMA:-11434}:11434"
  - "${HOST_PORT_LIBRECHAT:-3080}:3080"
```

4. Verify network connectivity between containers:

```bash
docker exec -it librechat ping ollama
docker exec -it librechat curl -s http://ollama:11434/api/version
```

## Configuration Synchronization Issues

### LibreChat Configuration Not Synchronized with Main Configuration

**Symptoms:**
- LibreChat works initially but fails after configuration changes
- Authentication issues despite having secrets in the main configuration
- Inconsistent behavior between services

**Possible Causes:**
1. Configuration changes not propagated to all services
2. Multiple configuration files with conflicting values
3. Manual edits to one configuration file but not others

**Solution:**
1. Use the update_librechat_secrets.sh script to synchronize configurations:

```bash
./lib/update_librechat_secrets.sh
```

2. Always use the provided scripts for configuration changes:

```bash
./llm generate-secrets  # For generating new secrets
./llm config edit       # For editing configuration
```

3. After making manual changes, restart the services:

```bash
./llm stop
./llm start
```

**Technical Details:**
The LOCAL-LLM-Stack uses multiple configuration files for different services. The main configuration is in `config/.env`, but LibreChat has its own configuration in `config/librechat/.env`. When changes are made to the main configuration, they need to be propagated to the service-specific configurations. The system now includes mechanisms to automatically synchronize these configurations.

## Verifying the Stack is Working

To verify that all components are working correctly:

1. Check container status:
```bash
docker ps
```
All containers should show as "healthy" or "(health: starting)" for recently started containers.

2. Check ollama API:
```bash
curl http://localhost:11434/api/version
```
Expected output: `{"version":"0.1.27"}`

3. Check librechat health:
```bash
curl http://localhost:3080/health
```
Expected output: `OK`

4. Check container logs for any errors:
```bash
docker logs librechat
docker logs ollama
```

5. Access the LibreChat web interface:
   - Open http://localhost:3080 in your browser
   - Log in with the admin credentials (email: admin@local.host, password: generated during setup)
   - Try sending a message to test the connection to Ollama

## Advanced Troubleshooting

### Debugging Container Health Checks

To see the exact output of a container's health check:

```bash
docker inspect --format='{{json .State.Health}}' ollama | jq
```

### Checking Environment Variables in Containers

To verify that environment variables are correctly set in a container:

```bash
docker exec -it librechat env | grep JWT
```

### Manually Testing Inter-Container Communication

To test if containers can communicate with each other:

```bash
docker exec -it librechat curl -s http://ollama:11434/api/version
```