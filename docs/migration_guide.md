# Migration Guide for LOCAL-LLM-Stack

This guide will help you migrate your existing LOCAL-LLM-Stack installation to the new standardized format implemented in Phase 5. It covers directory structure changes, script naming conventions, configuration changes, and how to adapt custom modules to the new standardized format.

## Table of Contents

1. [Overview](#overview)
2. [Migration Process](#migration-process)
3. [Directory Structure Changes](#directory-structure-changes)
4. [Script Naming Conventions](#script-naming-conventions)
5. [Configuration Changes](#configuration-changes)
6. [Custom Module Migration](#custom-module-migration)
7. [Troubleshooting](#troubleshooting)

## Overview

Phase 5 of the LOCAL-LLM-Stack cleanup plan has implemented several changes to standardize and improve the system. These changes include:

- Standardized directory structure
- Consistent script naming conventions
- Improved configuration management
- Enhanced module and tool integration
- Comprehensive validation and testing

This guide will help you migrate your existing setup to the new standardized format while preserving your custom configurations and data.

## Migration Process

The migration process consists of the following steps:

1. **Backup your existing setup**
2. **Run the migration scripts**
3. **Validate the migrated setup**
4. **Test the migrated setup**
5. **Adapt custom modules (if any)**

### Automated Migration

We provide automated migration scripts to help you migrate your existing setup:

```bash
# Migrate configuration
./lib/migration/migrate_config.sh

# Migrate custom modules
./lib/migration/migrate_custom_modules.sh
```

These scripts will:
- Create backups of your existing configuration and modules
- Migrate your configuration to the new standardized format
- Adapt your custom modules to the new standardized format
- Validate the migrated setup

### Migration Options

Both migration scripts support the following options:

- `--verbose`: Display detailed information during execution
- `--force`: Force migration even if validation fails
- `--no-backup`: Skip creating backups (not recommended)
- `--dry-run`: Show what would be done without making changes

For example, to see what changes would be made without actually making them:

```bash
./lib/migration/migrate_config.sh --dry-run
./lib/migration/migrate_custom_modules.sh --dry-run
```

## Directory Structure Changes

The directory structure has been standardized to improve organization and maintainability. Here's an overview of the new directory structure:

```
/
├── config/                  # Configuration files
│   ├── templates/           # Configuration templates
│   ├── librechat/           # LibreChat configuration
│   ├── mongodb/             # MongoDB configuration
│   ├── meilisearch/         # Meilisearch configuration
│   ├── ollama/              # Ollama configuration
│   └── nginx/               # Nginx configuration
├── core/                    # Core Docker Compose files
│   ├── docker-compose.yml   # Main Docker Compose file
│   ├── librechat.yml        # LibreChat service definition
│   ├── mongodb.yml          # MongoDB service definition
│   ├── meilisearch.yml      # Meilisearch service definition
│   └── ollama.yml           # Ollama service definition
├── docs/                    # Documentation
│   ├── diagrams/            # System diagrams
│   ├── schema/              # Documentation schemas
│   ├── system/              # System documentation
│   └── templates/           # Documentation templates
├── lib/                     # Library scripts
│   ├── core/                # Core library modules
│   ├── templates/           # Script templates
│   ├── test/                # Test scripts
│   └── migration/           # Migration scripts
├── modules/                 # Optional modules
│   ├── template/            # Module template
│   ├── monitoring/          # Monitoring module
│   ├── scaling/             # Scaling module
│   └── security/            # Security module
├── tools/                   # Utility tools
│   ├── template/            # Tool template
│   ├── doc-sync/            # Documentation synchronization
│   ├── knowledge-graph/     # Knowledge graph generation
│   └── relationship-mapping/ # Relationship mapping
└── llm                      # Main CLI script
```

### Key Changes

- **Configuration files** are now centralized in the `config` directory
- **Core Docker Compose files** are now in the `core` directory
- **Library scripts** are now organized in the `lib` directory
- **Module structure** has been standardized with a consistent template
- **Tool structure** has been standardized with a consistent template

## Script Naming Conventions

Script naming conventions have been standardized to improve consistency and maintainability:

### Core Library Scripts

Core library scripts are named according to their functionality:

- `logging.sh`: Logging functions
- `error.sh`: Error handling functions
- `validation.sh`: Validation functions
- `config.sh`: Configuration management functions
- `system.sh`: System operation functions
- `docker.sh`: Docker management functions

### Utility Scripts

Utility scripts are named according to their purpose:

- `generate_secrets.sh`: Generate secure secrets
- `validate_configs.sh`: Validate configuration files
- `update_librechat_secrets.sh`: Update LibreChat secrets

### Module Scripts

Module scripts follow a standardized structure:

- `api/module_api.sh`: Module API functions
- `scripts/setup.sh`: Module setup script
- `tests/unit/test_module.sh`: Module unit tests
- `tests/integration/test_integration.sh`: Module integration tests

## Configuration Changes

Configuration management has been improved to enhance security, consistency, and maintainability:

### Environment Variables

Environment variables are now managed in a centralized `.env` file in the `config` directory. This file contains all the configuration variables for the system.

### Component-Specific Configuration

Component-specific configuration files are now organized in subdirectories of the `config` directory:

- `config/librechat/`: LibreChat configuration
- `config/mongodb/`: MongoDB configuration
- `config/meilisearch/`: Meilisearch configuration
- `config/ollama/`: Ollama configuration
- `config/nginx/`: Nginx configuration

### Configuration Templates

Configuration templates are now provided in the `config/templates` directory. These templates can be used as a starting point for creating new configurations.

### Configuration Validation

Configuration validation has been improved to ensure that all configuration files are valid and consistent. The `validate_configs.sh` script can be used to validate your configuration.

## Custom Module Migration

If you have created custom modules for LOCAL-LLM-Stack, you'll need to adapt them to the new standardized format. The `migrate_custom_modules.sh` script can help you with this process.

### Module Structure

Custom modules should follow this standardized structure:

```
modules/your-module/
├── api/                     # Module API
│   └── module_api.sh        # Module API functions
├── config/                  # Module configuration
│   └── env.conf             # Module environment variables
├── scripts/                 # Module scripts
│   └── setup.sh             # Module setup script
├── tests/                   # Module tests
│   ├── unit/                # Unit tests
│   │   └── test_module.sh   # Module unit tests
│   └── integration/         # Integration tests
│       └── test_integration.sh # Module integration tests
├── docker-compose.yml       # Module Docker Compose file
└── README.md                # Module documentation
```

### Module API

Each module should provide an API script (`api/module_api.sh`) that exposes the module's functionality to the rest of the system. This script should:

- Source the core libraries
- Define functions for interacting with the module
- Provide documentation for each function

Example:

```bash
#!/bin/bash
# module_api.sh - API for your-module

# Get the absolute path of the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source core libraries
source "$ROOT_DIR/lib/core/logging.sh"
source "$ROOT_DIR/lib/core/error.sh"

# Function to start the module
function start_your_module() {
  log_info "Starting your-module..."
  # Implementation
}

# Function to stop the module
function stop_your_module() {
  log_info "Stopping your-module..."
  # Implementation
}

# Function to get module status
function get_your_module_status() {
  log_info "Getting your-module status..."
  # Implementation
}
```

### Docker Compose File

The module's Docker Compose file should:

- Use version '3.8' or later
- Define services with appropriate names
- Use the external `llm-stack-network` network

Example:

```yaml
version: '3.8'

services:
  your-service:
    image: your-image
    container_name: your-module-service
    restart: unless-stopped
    networks:
      - default
    volumes:
      - ../data/your-module:/data
    environment:
      - VARIABLE=value

networks:
  default:
    name: llm-stack-network
    external: true
```

### Module Scripts

Module scripts should:

- Source the core libraries
- Use consistent error handling
- Follow the shell script style guide
- Be executable

Example:

```bash
#!/bin/bash
# setup.sh - Setup script for your-module

# Get the absolute path of the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source core libraries
source "$ROOT_DIR/lib/core/logging.sh"
source "$ROOT_DIR/lib/core/error.sh"

# Setup function
function setup_your_module() {
  log_info "Setting up your-module..."
  # Implementation
}

# Run setup
setup_your_module
```

### Module Tests

Module tests should:

- Source the core libraries and test framework
- Define test functions for each feature
- Be executable

Example:

```bash
#!/bin/bash
# test_module.sh - Unit tests for your-module

# Get the absolute path of the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Source core libraries
source "$ROOT_DIR/lib/core/logging.sh"
source "$ROOT_DIR/lib/core/error.sh"
source "$ROOT_DIR/lib/test/test_framework.sh"

# Test function
function test_your_feature() {
  # Test implementation
  assert_true "true"
}

# Run tests
run_test "Your Feature" test_your_feature
```

## Troubleshooting

### Migration Failures

If the migration process fails, you can:

1. Check the error messages for details
2. Run the migration script with the `--verbose` option for more information
3. Run the migration script with the `--force` option to ignore validation errors
4. Restore from the backup if necessary

### Configuration Issues

If you encounter configuration issues after migration:

1. Check the error messages for details
2. Validate your configuration with `./lib/validate_configs.sh`
3. Compare your configuration with the templates in `config/templates`
4. Restore from the backup if necessary

### Custom Module Issues

If you encounter issues with custom modules after migration:

1. Check the error messages for details
2. Validate your module structure against the template in `modules/template`
3. Check your module's Docker Compose file for compatibility
4. Restore from the backup if necessary

### Getting Help

If you need further assistance:

1. Check the documentation in the `docs` directory
2. Run the appropriate script with the `--help` option for usage information
3. Check the known issues document at `docs/known_issues.md`