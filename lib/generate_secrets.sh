#!/bin/bash
# generate_secrets.sh - Generate secure secrets for LOCAL-LLM-Stack
# This file has been refactored to use the new core library

# Source core library modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/core/logging.sh"
source "$SCRIPT_DIR/core/error.sh"
source "$SCRIPT_DIR/core/system.sh"
source "$SCRIPT_DIR/core/config.sh"
source "$SCRIPT_DIR/core/secrets.sh"

log_info "Generating secure secrets..."

# Generate all required secrets
generate_all_secrets
if [[ $? -ne 0 ]]; then
  handle_error $ERR_GENERAL "Failed to generate secrets"
fi

# Get the generated secrets for use in the .env file
ADMIN_PASSWORD=$(get_secret "ADMIN_PASSWORD")
GRAFANA_ADMIN_PASSWORD=$(get_secret "GRAFANA_ADMIN_PASSWORD")
JWT_SECRET=$(get_secret "JWT_SECRET")
JWT_REFRESH_SECRET=$(get_secret "JWT_REFRESH_SECRET")
SESSION_SECRET=$(get_secret "SESSION_SECRET")
CRYPT_SECRET=$(get_secret "CRYPT_SECRET")
CREDS_KEY=$(get_secret "CREDS_KEY")
CREDS_IV=$(get_secret "CREDS_IV")

# Create backup if the file exists
if [[ -f "$ENV_FILE" ]]; then
  BACKUP_FILE=$(backup_file "$ENV_FILE")
  if [[ $? -eq 0 ]]; then
    log_success "Backup created at $BACKUP_FILE"
  else
    log_warn "Could not create backup"
    BACKUP_FILE="No backup created"
  fi
else
  log_warn "No existing configuration file to backup"
  BACKUP_FILE="No backup needed"
fi

# Create the .env file with the secrets directly
cat > "$ENV_FILE" << EOF
# LOCAL-LLM-Stack Configuration

# Component Versions
OLLAMA_VERSION=0.1.27
MONGODB_VERSION=6.0.6
MEILISEARCH_VERSION=latest
LIBRECHAT_VERSION=latest
TRAEFIK_VERSION=v2.10.4
NGINX_VERSION=1.25.3
PROMETHEUS_VERSION=v2.45.0
GRAFANA_VERSION=10.0.3

# Port Configuration
HOST_PORT_OLLAMA=11434
HOST_PORT_LIBRECHAT=3080
HOST_PORT_LOAD_BALANCER=8080
HOST_PORT_PROMETHEUS=9090
HOST_PORT_GRAFANA=3000

# Resource Limits
OLLAMA_CPU_LIMIT=0.75
OLLAMA_MEMORY_LIMIT=16G
MONGODB_MEMORY_LIMIT=2G
MEILISEARCH_MEMORY_LIMIT=1G
LIBRECHAT_CPU_LIMIT=0.50
LIBRECHAT_MEMORY_LIMIT=4G

# Default Models
DEFAULT_MODELS=tinyllama

# Security Settings
ADMIN_PASSWORD=$ADMIN_PASSWORD
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=$GRAFANA_ADMIN_PASSWORD
JWT_SECRET=$JWT_SECRET
JWT_REFRESH_SECRET=$JWT_REFRESH_SECRET
SESSION_SECRET=$SESSION_SECRET
CRYPT_SECRET=$CRYPT_SECRET
CREDS_KEY=$CREDS_KEY
CREDS_IV=$CREDS_IV

# Authentication Settings
ENABLE_AUTH=true
ALLOW_SOCIAL_LOGIN=false
ALLOW_REGISTRATION=true
ADMIN_EMAIL=admin@local.host
EOF

if [[ $? -eq 0 ]]; then
  log_success "Secure secrets generated and saved to $ENV_FILE"

  # Update all configuration files with the new secrets
  update_all_configs
  if [[ $? -ne 0 ]]; then
    handle_error $ERR_GENERAL "Failed to update configuration files with secrets"
  fi

  log_success "All configuration files updated with the new secrets."

  log_warn "IMPORTANT: Keep your secrets safe! They are stored in $SECRETS_FILE"
  log_warn "LibreChat Admin password: $ADMIN_PASSWORD"
  log_warn "Grafana Admin password: $GRAFANA_ADMIN_PASSWORD"
  if [[ "$BACKUP_FILE" != "No backup needed" && "$BACKUP_FILE" != "No backup created" ]]; then
    log_warn "If you need to restore the original configuration, use:"
    log_warn "cp $BACKUP_FILE $ENV_FILE"
  fi
  log_info "To view your admin password, run: grep ADMIN_PASSWORD $SECRETS_FILE"
else
  handle_error $ERR_CONFIG_ERROR "Failed to write configuration file"
fi
