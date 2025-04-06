#!/bin/bash
# secure_configs.sh - Secure configuration files
# This script updates the permissions on configuration files to ensure they are secure

# Source core library modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/core/logging.sh"
source "$SCRIPT_DIR/core/error.sh"
source "$SCRIPT_DIR/core/system.sh"
source "$SCRIPT_DIR/core/config.sh"

log_info "Securing configuration files..."

# Secure the secrets file
SECRETS_FILE="$CONFIG_DIR/.secrets"
if [[ -f "$SECRETS_FILE" ]]; then
  log_info "Securing secrets file: $SECRETS_FILE"
  chmod 600 "$SECRETS_FILE" 2>/dev/null
  if [[ $? -ne 0 ]]; then
    log_error "Failed to secure secrets file: $SECRETS_FILE"
  else
    log_success "Secrets file secured: $SECRETS_FILE"
  fi
fi

# Secure the main environment file
ENV_FILE="$CONFIG_DIR/.env"
if [[ -f "$ENV_FILE" ]]; then
  log_info "Securing environment file: $ENV_FILE"
  chmod 644 "$ENV_FILE" 2>/dev/null
  if [[ $? -ne 0 ]]; then
    log_error "Failed to secure environment file: $ENV_FILE"
  else
    log_success "Environment file secured: $ENV_FILE"
  fi
fi

# Secure the LibreChat environment file
LIBRECHAT_ENV="$CONFIG_DIR/librechat/.env"
if [[ -f "$LIBRECHAT_ENV" ]]; then
  log_info "Securing LibreChat environment file: $LIBRECHAT_ENV"
  chmod 644 "$LIBRECHAT_ENV" 2>/dev/null
  if [[ $? -ne 0 ]]; then
    log_error "Failed to secure LibreChat environment file: $LIBRECHAT_ENV"
  else
    log_success "LibreChat environment file secured: $LIBRECHAT_ENV"
  fi
fi

# Secure the research environment file
RESEARCH_ENV="$CONFIG_DIR/research.env"
if [[ -f "$RESEARCH_ENV" ]]; then
  log_info "Securing research environment file: $RESEARCH_ENV"
  chmod 644 "$RESEARCH_ENV" 2>/dev/null
  if [[ $? -ne 0 ]]; then
    log_error "Failed to secure research environment file: $RESEARCH_ENV"
  else
    log_success "Research environment file secured: $RESEARCH_ENV"
  fi
fi

# Secure the LibreChat YAML file
LIBRECHAT_YAML="$CONFIG_DIR/librechat/librechat.yaml"
if [[ -f "$LIBRECHAT_YAML" ]]; then
  log_info "Securing LibreChat YAML file: $LIBRECHAT_YAML"
  chmod 644 "$LIBRECHAT_YAML" 2>/dev/null
  if [[ $? -ne 0 ]]; then
    log_error "Failed to secure LibreChat YAML file: $LIBRECHAT_YAML"
  else
    log_success "LibreChat YAML file secured: $LIBRECHAT_YAML"
  fi
fi

# Secure the Traefik YAML file
TRAEFIK_YAML="modules/security/config/traefik/traefik.yml"
if [[ -f "$TRAEFIK_YAML" ]]; then
  log_info "Securing Traefik YAML file: $TRAEFIK_YAML"
  chmod 644 "$TRAEFIK_YAML" 2>/dev/null
  if [[ $? -ne 0 ]]; then
    log_error "Failed to secure Traefik YAML file: $TRAEFIK_YAML"
  else
    log_success "Traefik YAML file secured: $TRAEFIK_YAML"
  fi
fi

# Secure the Traefik services YAML file
TRAEFIK_SERVICES_YAML="modules/security/config/traefik/dynamic/services.yml"
if [[ -f "$TRAEFIK_SERVICES_YAML" ]]; then
  log_info "Securing Traefik services YAML file: $TRAEFIK_SERVICES_YAML"
  chmod 644 "$TRAEFIK_SERVICES_YAML" 2>/dev/null
  if [[ $? -ne 0 ]]; then
    log_error "Failed to secure Traefik services YAML file: $TRAEFIK_SERVICES_YAML"
  else
    log_success "Traefik services YAML file secured: $TRAEFIK_SERVICES_YAML"
  fi
fi

# Secure the Meilisearch YAML file
MEILISEARCH_YAML="core/meilisearch.yml"
if [[ -f "$MEILISEARCH_YAML" ]]; then
  log_info "Securing Meilisearch YAML file: $MEILISEARCH_YAML"
  chmod 644 "$MEILISEARCH_YAML" 2>/dev/null
  if [[ $? -ne 0 ]]; then
    log_error "Failed to secure Meilisearch YAML file: $MEILISEARCH_YAML"
  else
    log_success "Meilisearch YAML file secured: $MEILISEARCH_YAML"
  fi
fi

# Secure the config directory
log_info "Securing config directory: $CONFIG_DIR"
chmod 755 "$CONFIG_DIR" 2>/dev/null
if [[ $? -ne 0 ]]; then
  log_error "Failed to secure config directory: $CONFIG_DIR"
else
  log_success "Config directory secured: $CONFIG_DIR"
fi

# Secure the LibreChat config directory
LIBRECHAT_CONFIG_DIR="$CONFIG_DIR/librechat"
if [[ -d "$LIBRECHAT_CONFIG_DIR" ]]; then
  log_info "Securing LibreChat config directory: $LIBRECHAT_CONFIG_DIR"
  chmod 755 "$LIBRECHAT_CONFIG_DIR" 2>/dev/null
  if [[ $? -ne 0 ]]; then
    log_error "Failed to secure LibreChat config directory: $LIBRECHAT_CONFIG_DIR"
  else
    log_success "LibreChat config directory secured: $LIBRECHAT_CONFIG_DIR"
  fi
fi

# Secure the Traefik config directory
TRAEFIK_CONFIG_DIR="modules/security/config/traefik"
if [[ -d "$TRAEFIK_CONFIG_DIR" ]]; then
  log_info "Securing Traefik config directory: $TRAEFIK_CONFIG_DIR"
  chmod 755 "$TRAEFIK_CONFIG_DIR" 2>/dev/null
  if [[ $? -ne 0 ]]; then
    log_error "Failed to secure Traefik config directory: $TRAEFIK_CONFIG_DIR"
  else
    log_success "Traefik config directory secured: $TRAEFIK_CONFIG_DIR"
  fi
fi

# Secure the Traefik dynamic config directory
TRAEFIK_DYNAMIC_CONFIG_DIR="modules/security/config/traefik/dynamic"
if [[ -d "$TRAEFIK_DYNAMIC_CONFIG_DIR" ]]; then
  log_info "Securing Traefik dynamic config directory: $TRAEFIK_DYNAMIC_CONFIG_DIR"
  chmod 755 "$TRAEFIK_DYNAMIC_CONFIG_DIR" 2>/dev/null
  if [[ $? -ne 0 ]]; then
    log_error "Failed to secure Traefik dynamic config directory: $TRAEFIK_DYNAMIC_CONFIG_DIR"
  else
    log_success "Traefik dynamic config directory secured: $TRAEFIK_DYNAMIC_CONFIG_DIR"
  fi
fi

log_success "Configuration files secured"