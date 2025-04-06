# LOCAL-LLM-Stack Configuration Guide

This document provides a comprehensive guide to the configuration system in LOCAL-LLM-Stack.

## Configuration Overview

LOCAL-LLM-Stack uses a centralized configuration approach with the following key features:

1. **Centralized Configuration**: All configuration settings are managed through a central system
2. **Secure Secrets Management**: Sensitive information is handled securely
3. **Configuration Validation**: All configuration files are validated against schemas
4. **Template-Based Configuration**: Templates are provided for all configuration files
5. **Hierarchical Configuration**: Configuration follows a clear hierarchy

## Configuration Files

The configuration system uses the following file types:

1. **Environment Files (.env)**: Used for global settings and environment variables
2. **YAML Files (.yml, .yaml)**: Used for structured configuration
3. **JSON Files (.json)**: Used for specific component configuration
4. **Secrets File (.secrets)**: Used for storing sensitive information securely

## Configuration Hierarchy

The configuration follows this hierarchy:

1. **Default Values**: Defined in the code
2. **Template Values**: Defined in template files
3. **User Values**: Defined in user configuration files
4. **Environment Variables**: Can override any setting at runtime

## Secrets Management

Sensitive information is managed securely through the following mechanisms:

1. **Secrets File**: Sensitive information is stored in a dedicated secrets file with restricted permissions
2. **Secrets Generation**: Secure secrets are generated using cryptographically strong methods
3. **Secrets Distribution**: Secrets are distributed to the appropriate configuration files as needed
4. **No Hardcoding**: Secrets are never hardcoded in configuration files or source code

## Configuration Templates

Templates are provided for all configuration files to serve as a reference and starting point:

1. **Main Configuration**: `config/templates/config-template.env`
2. **LibreChat Configuration**: `config/templates/librechat-template.yaml`
3. **Traefik Configuration**: `config/templates/traefik-template.yml`
4. **Traefik Services Configuration**: `config/templates/traefik-services-template.yml`

## Configuration Validation

All configuration files are validated to ensure they meet the required format and constraints:

1. **Schema Validation**: Configuration files are validated against JSON Schema definitions
2. **Syntax Validation**: Configuration files are checked for syntax errors
3. **Security Validation**: Security-sensitive settings are validated for compliance with security best practices
4. **Dependency Validation**: Configuration dependencies are validated for consistency

## Configuration Tools

The following tools are provided for managing configuration:

1. **generate_secrets.sh**: Generates secure secrets and updates all configuration files
2. **validate_configs.sh**: Validates all configuration files against schemas
3. **update_librechat_secrets.sh**: Updates LibreChat configuration with secrets from the main configuration

## How to Configure LOCAL-LLM-Stack

Follow these steps to configure LOCAL-LLM-Stack:

1. **Copy Templates**: Copy the template files to their respective locations
   ```bash
   mkdir -p config/librechat
   cp config/templates/config-template.env config/.env
   cp config/templates/librechat-template.yaml config/librechat/librechat.yaml
   mkdir -p modules/security/config/traefik/dynamic
   cp config/templates/traefik-template.yml modules/security/config/traefik/traefik.yml
   cp config/templates/traefik-services-template.yml modules/security/config/traefik/dynamic/services.yml
   ```

2. **Generate Secrets**: Run the secrets generation script
   ```bash
   ./lib/generate_secrets_new.sh
   ```

3. **Validate Configuration**: Run the configuration validation script
   ```bash
   ./lib/validate_configs.sh
   ```

4. **Customize Configuration**: Edit the configuration files as needed
   - Edit `config/.env` for global settings
   - Edit `config/librechat/librechat.yaml` for LibreChat settings
   - Edit `modules/security/config/traefik/traefik.yml` for Traefik settings
   - Edit `modules/security/config/traefik/dynamic/services.yml` for Traefik services settings

5. **Validate Again**: Run the configuration validation script again to ensure your changes are valid
   ```bash
   ./lib/validate_configs.sh
   ```

## Security Best Practices

Follow these security best practices when configuring LOCAL-LLM-Stack:

1. **Always Enable Authentication**: Set `ENABLE_AUTH=true` in all environment files
2. **Use Strong Passwords**: Use strong, unique passwords for all accounts
3. **Secure API Keys**: Never share or expose API keys
4. **Enable TLS**: Always enable TLS for production environments
5. **Restrict Access**: Use IP whitelisting and other access controls when possible
6. **Regular Updates**: Regularly update secrets and credentials
7. **Audit Configuration**: Regularly audit configuration files for security issues

## Troubleshooting

If you encounter issues with configuration:

1. **Check Validation**: Run the validation script to identify issues
2. **Check Logs**: Look for error messages in the logs
3. **Check Permissions**: Ensure file permissions are correct
4. **Regenerate Secrets**: Try regenerating secrets if you suspect they are corrupted
5. **Reset to Templates**: If all else fails, reset to the template files and reconfigure

## Advanced Configuration

For advanced configuration needs:

1. **Custom Environment Variables**: Add custom environment variables to the `.env` file
2. **Custom Traefik Middlewares**: Add custom middlewares to the Traefik services configuration
3. **Custom LibreChat Endpoints**: Add custom endpoints to the LibreChat configuration
4. **Custom Docker Compose Overrides**: Create custom Docker Compose override files for specific environments