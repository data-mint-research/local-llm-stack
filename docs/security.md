# LOCAL-LLM-Stack Security Guide

This document provides information about the security aspects of the LOCAL-LLM-Stack, including authentication, secrets management, and best practices.

## Table of Contents

1. [Authentication](#authentication)
2. [Secrets Management](#secrets-management)
3. [Configuration Security](#configuration-security)
4. [Network Security](#network-security)
5. [Best Practices](#best-practices)

## Authentication

The LOCAL-LLM-Stack uses several authentication mechanisms to secure access to its components:

### LibreChat Authentication

LibreChat uses JWT (JSON Web Tokens) for authentication, which requires several secret keys:

- **JWT_SECRET**: Used to sign and verify access tokens
- **JWT_REFRESH_SECRET**: Used to sign and verify refresh tokens
- **SESSION_SECRET**: Used to encrypt session data

These secrets are critical for the security of the application. If they are compromised, an attacker could forge authentication tokens and gain unauthorized access.

### Admin Authentication

The stack includes an admin user for LibreChat with the following credentials:

- **Email**: admin@local.host
- **Password**: Generated during setup (displayed when running `./llm generate-secrets`)

This admin user has full access to the LibreChat application, including user management and system settings.

## Secrets Management

The LOCAL-LLM-Stack includes several mechanisms for managing secrets:

### Automatic Secret Generation

The system automatically checks for missing secrets when starting and generates them if needed:

1. The `check_secrets` function in `lib/common.sh` checks for empty secrets before starting services
2. If secrets are missing, it calls the `generate_secrets.sh` script to generate them
3. The generated secrets are saved to the configuration files

### Manual Secret Generation

You can manually generate new secrets using the provided script:

```bash
./llm generate-secrets
```

This will:
1. Create a backup of the current configuration
2. Generate secure random values for all secret fields
3. Update the configuration files with these values
4. Display the admin password (save this somewhere secure)

### Secret Synchronization

The system includes mechanisms to keep secrets synchronized between different configuration files:

1. The `generate_secrets.sh` script updates both the main configuration and the LibreChat configuration
2. The `update_librechat_secrets.sh` script can be used to manually synchronize secrets between configurations

## Configuration Security

The LOCAL-LLM-Stack uses several configuration files that contain sensitive information:

### Main Configuration

The main configuration file (`config/.env`) contains:

- Component versions
- Port configurations
- Resource limits
- Security settings (secrets)
- Authentication settings

### LibreChat Configuration

The LibreChat configuration file (`config/librechat/.env`) contains:

- Database connection settings
- API endpoints
- Authentication settings (secrets)
- Crypto settings

### Configuration Backups

Before making changes to configuration files, the system creates backups:

```
config/.env.backup-YYYYMMDDHHMMSS
config/librechat/.env.backup-YYYYMMDDHHMMSS
```

These backups can be used to restore the configuration if something goes wrong.

## Network Security

The LOCAL-LLM-Stack uses Docker networking to isolate components:

### Docker Network

All components are connected via a Docker network called `llm-stack-network`. This allows containers to communicate with each other using their container names as hostnames, without exposing all services directly to the host network.

### Port Exposure

Only necessary ports are exposed to the host:

- **Ollama**: Port 11434 for API access
- **LibreChat**: Port 3080 for web interface
- **LibreChat Debug**: Port 9229 for Node.js debugger (only in debug mode)

Other services (MongoDB, Meilisearch) are not directly exposed to the host network, reducing the attack surface.

## Best Practices

Here are some best practices for securing your LOCAL-LLM-Stack deployment:

### 1. Keep Secrets Secure

- Do not commit configuration files with secrets to version control
- Use the provided scripts for generating and managing secrets
- Regularly rotate secrets, especially in production environments

### 2. Limit Access

- Use strong passwords for admin accounts
- Consider using a reverse proxy with HTTPS for production deployments
- Implement IP-based access restrictions if needed

### 3. Regular Updates

- Keep all components updated to the latest versions
- Check for security advisories for all components
- Apply security patches promptly

### 4. Backup Data

- Regularly backup the data directories:
  - `../data/ollama`
  - `../data/mongodb`
  - `../data/meilisearch`
- Test restoring from backups to ensure they work

### 5. Monitor Logs

- Regularly check container logs for suspicious activity:
  ```bash
  docker logs librechat
  docker logs ollama
  ```
- Consider implementing a centralized logging solution for production deployments

## Advanced Security Considerations

For production deployments, consider implementing additional security measures:

### HTTPS

Use a reverse proxy (like Nginx or Traefik) to provide HTTPS encryption for all services.

### Authentication Proxy

Consider using an authentication proxy (like Authelia or Keycloak) for additional authentication and authorization layers.

### Network Isolation

Use Docker network isolation features to further restrict communication between containers.

### Resource Limits

Set appropriate CPU and memory limits for all containers to prevent resource exhaustion attacks.