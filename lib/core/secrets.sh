#!/bin/bash
# secrets.sh - Secure secrets management for LOCAL-LLM-Stack
# This module provides functions for generating, storing, and managing secrets

# Guard against multiple inclusion
if [[ -n "$_SECRETS_SH_INCLUDED" ]]; then
  return 0
fi
_SECRETS_SH_INCLUDED=1

# Use a different variable name for the script directory
SECRETS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SECRETS_DIR/logging.sh"
source "$SECRETS_DIR/error.sh"
source "$SECRETS_DIR/system.sh"
source "$SECRETS_DIR/config.sh"

# Default secrets file location
SECRETS_FILE="$CONFIG_DIR/.secrets"

# Initialize secrets management
init_secrets() {
  log_debug "Initializing secrets management"
  
  # Ensure the config directory exists
  ensure_directory "$CONFIG_DIR"
  if [[ $? -ne 0 ]]; then
    handle_error $ERR_PERMISSION_DENIED "Failed to create config directory"
  fi
  
  # Create the secrets file if it doesn't exist
  if [[ ! -f "$SECRETS_FILE" ]]; then
    log_debug "Creating secrets file: $SECRETS_FILE"
    touch "$SECRETS_FILE" 2>/dev/null
    if [[ $? -ne 0 ]]; then
      handle_error $ERR_PERMISSION_DENIED "Failed to create secrets file"
    fi
    
    # Set secure permissions on the secrets file
    chmod 600 "$SECRETS_FILE" 2>/dev/null
    if [[ $? -ne 0 ]]; then
      log_warn "Failed to set secure permissions on secrets file"
    fi
  fi
  
  return $ERR_SUCCESS
}

# Get a secret from the secrets file
get_secret() {
  local key=$1
  local default_value=${2:-""}
  
  log_debug "Getting secret: $key"
  
  # Check if the secrets file exists
  if [[ ! -f "$SECRETS_FILE" ]]; then
    log_warn "Secrets file not found: $SECRETS_FILE"
    echo "$default_value"
    return $ERR_FILE_NOT_FOUND
  fi
  
  # Get the value from the secrets file
  local value=$(grep -E "^$key=" "$SECRETS_FILE" | cut -d= -f2-)
  
  # Return the value or default
  if [[ -z "$value" ]]; then
    echo "$default_value"
  else
    echo "$value"
  fi
  
  return $ERR_SUCCESS
}

# Set a secret in the secrets file
set_secret() {
  local key=$1
  local value=$2
  
  log_debug "Setting secret: $key"
  
  # Check if the secrets file exists
  if [[ ! -f "$SECRETS_FILE" ]]; then
    init_secrets
  fi
  
  # Update the secret in the file
  if grep -q -E "^$key=" "$SECRETS_FILE"; then
    # Replace existing secret
    sed -i "s|^$key=.*|$key=$value|" "$SECRETS_FILE" 2>/dev/null
  else
    # Add new secret
    echo "$key=$value" >> "$SECRETS_FILE" 2>/dev/null
  fi
  
  if [[ $? -ne 0 ]]; then
    log_error "Failed to set secret: $key"
    return $ERR_GENERAL
  fi
  
  return $ERR_SUCCESS
}

# Generate a new secret
generate_secret() {
  local key=$1
  local length=${2:-32}
  local type=${3:-"random"}
  
  log_debug "Generating secret: $key (length: $length, type: $type)"
  
  # Generate the secret value
  local value=""
  case "$type" in
    "random")
      value=$(generate_random_string $length)
      ;;
    "hex")
      value=$(generate_hex_string $length)
      ;;
    "password")
      value=$(generate_password $length)
      ;;
    *)
      log_error "Unknown secret type: $type"
      return $ERR_VALIDATION_ERROR
      ;;
  esac
  
  # Set the secret
  set_secret "$key" "$value"
  if [[ $? -ne 0 ]]; then
    log_error "Failed to set secret: $key"
    return $ERR_GENERAL
  fi
  
  return $ERR_SUCCESS
}

# Generate a secure password
generate_password() {
  local length=$1
  local chars="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()-_=+[]{}|;:,.<>?"
  
  # Ensure we have at least one of each character type
  local password=$(generate_random_string $length)
  
  # Ensure we have at least one uppercase letter
  if ! [[ "$password" =~ [A-Z] ]]; then
    local pos=$((RANDOM % length))
    local upper_char=${chars:$((RANDOM % 26)):1}
    password="${password:0:$pos}$upper_char${password:$((pos+1))}"
  fi
  
  # Ensure we have at least one lowercase letter
  if ! [[ "$password" =~ [a-z] ]]; then
    local pos=$((RANDOM % length))
    local lower_char=${chars:$((26 + RANDOM % 26)):1}
    password="${password:0:$pos}$lower_char${password:$((pos+1))}"
  fi
  
  # Ensure we have at least one number
  if ! [[ "$password" =~ [0-9] ]]; then
    local pos=$((RANDOM % length))
    local num_char=${chars:$((52 + RANDOM % 10)):1}
    password="${password:0:$pos}$num_char${password:$((pos+1))}"
  fi
  
  # Ensure we have at least one special character
  if ! [[ "$password" =~ [^A-Za-z0-9] ]]; then
    local pos=$((RANDOM % length))
    local special_char=${chars:$((62 + RANDOM % (${#chars} - 62))):1}
    password="${password:0:$pos}$special_char${password:$((pos+1))}"
  fi
  
  echo "$password"
}

# Generate all required secrets
generate_all_secrets() {
  log_info "Generating all required secrets"
  
  # Initialize secrets management
  init_secrets
  
  # Generate admin passwords
  generate_secret "ADMIN_PASSWORD" 16 "password"
  generate_secret "GRAFANA_ADMIN_PASSWORD" 16 "password"
  
  # Generate JWT secrets
  generate_secret "JWT_SECRET" 64 "random"
  generate_secret "JWT_REFRESH_SECRET" 64 "random"
  
  # Generate session and encryption secrets
  generate_secret "SESSION_SECRET" 64 "random"
  generate_secret "CRYPT_SECRET" 64 "random"
  generate_secret "CREDS_KEY" 64 "hex"
  generate_secret "CREDS_IV" 32 "hex"
  
  # Generate Meilisearch master key
  generate_secret "MEILI_MASTER_KEY" 32 "random"
  
  # Generate Traefik basic auth
  local admin_password=$(get_secret "ADMIN_PASSWORD")
  local hashed_password=$(htpasswd -nb admin "$admin_password" 2>/dev/null || echo "admin:$admin_password")
  set_secret "TRAEFIK_BASIC_AUTH" "$hashed_password"
  
  log_success "All secrets generated successfully"
  return $ERR_SUCCESS
}

# Update environment file with secrets
update_env_with_secrets() {
  local env_file=${1:-"$ENV_FILE"}
  
  log_info "Updating environment file with secrets: $env_file"
  
  # Check if the environment file exists
  if [[ ! -f "$env_file" ]]; then
    log_error "Environment file not found: $env_file"
    return $ERR_FILE_NOT_FOUND
  fi
  
  # Create backup of the environment file
  local backup_file=$(backup_file "$env_file")
  if [[ $? -ne 0 ]]; then
    log_warn "Could not create backup of environment file"
  else
    log_info "Backup created: $backup_file"
  fi
  
  # Get all secrets
  local admin_password=$(get_secret "ADMIN_PASSWORD")
  local grafana_admin_password=$(get_secret "GRAFANA_ADMIN_PASSWORD")
  local jwt_secret=$(get_secret "JWT_SECRET")
  local jwt_refresh_secret=$(get_secret "JWT_REFRESH_SECRET")
  local session_secret=$(get_secret "SESSION_SECRET")
  local crypt_secret=$(get_secret "CRYPT_SECRET")
  local creds_key=$(get_secret "CREDS_KEY")
  local creds_iv=$(get_secret "CREDS_IV")
  
  # Update the environment file
  local variables=(
    "ADMIN_PASSWORD=$admin_password"
    "GRAFANA_ADMIN_USER=admin"
    "GRAFANA_ADMIN_PASSWORD=$grafana_admin_password"
    "JWT_SECRET=$jwt_secret"
    "JWT_REFRESH_SECRET=$jwt_refresh_secret"
    "SESSION_SECRET=$session_secret"
    "CRYPT_SECRET=$crypt_secret"
    "CREDS_KEY=$creds_key"
    "CREDS_IV=$creds_iv"
    "ENABLE_AUTH=true"
  )
  
  # Update the environment file
  update_env_vars "$env_file" "${variables[@]}"
  if [[ $? -ne 0 ]]; then
    log_error "Failed to update environment file: $env_file"
    return $ERR_GENERAL
  fi
  
  log_success "Environment file updated with secrets: $env_file"
  return $ERR_SUCCESS
}

# Update LibreChat configuration with secrets
update_librechat_config() {
  local librechat_env="$CONFIG_DIR/librechat/.env"
  local librechat_yaml="$CONFIG_DIR/librechat/librechat.yaml"
  
  log_info "Updating LibreChat configuration with secrets"
  
  # Update LibreChat .env file if it exists
  if [[ -f "$librechat_env" ]]; then
    log_info "Updating LibreChat environment file: $librechat_env"
    
    # Create backup of LibreChat .env file
    local backup_file=$(backup_file "$librechat_env")
    if [[ $? -ne 0 ]]; then
      log_warn "Could not create backup of LibreChat environment file"
    else
      log_info "Backup created: $backup_file"
    fi
    
    # Get JWT secrets
    local jwt_secret=$(get_secret "JWT_SECRET")
    local jwt_refresh_secret=$(get_secret "JWT_REFRESH_SECRET")
    
    # Update the JWT secrets in the LibreChat .env file
    sed -i "s|^JWT_SECRET=.*|JWT_SECRET=$jwt_secret|" "$librechat_env" 2>/dev/null
    sed -i "s|^JWT_REFRESH_SECRET=.*|JWT_REFRESH_SECRET=$jwt_refresh_secret|" "$librechat_env" 2>/dev/null
    
    if [[ $? -ne 0 ]]; then
      log_error "Failed to update LibreChat environment file: $librechat_env"
      return $ERR_GENERAL
    fi
    
    log_success "LibreChat environment file updated with secrets"
  fi
  
  # Update LibreChat YAML file if it exists
  if [[ -f "$librechat_yaml" ]]; then
    log_info "Updating LibreChat YAML file: $librechat_yaml"
    
    # Create backup of LibreChat YAML file
    local backup_file=$(backup_file "$librechat_yaml")
    if [[ $? -ne 0 ]]; then
      log_warn "Could not create backup of LibreChat YAML file"
    else
      log_info "Backup created: $backup_file"
    fi
    
    # Generate a new API key for Ollama
    local ollama_api_key=$(generate_random_string 32)
    
    # Update the API key in the LibreChat YAML file using yq if available
    if command_exists "yq"; then
      yq eval '.endpoints.custom[0].apiKey = env(OLLAMA_API_KEY)' -i "$librechat_yaml" 2>/dev/null
      if [[ $? -ne 0 ]]; then
        log_error "Failed to update LibreChat YAML file with yq: $librechat_yaml"
        return $ERR_GENERAL
      fi
    else
      # Fallback to sed if yq is not available
      sed -i "s|apiKey: \".*\"|apiKey: \"$ollama_api_key\"|" "$librechat_yaml" 2>/dev/null
      if [[ $? -ne 0 ]]; then
        log_error "Failed to update LibreChat YAML file with sed: $librechat_yaml"
        return $ERR_GENERAL
      fi
    fi
    
    log_success "LibreChat YAML file updated with secrets"
  fi
  
  return $ERR_SUCCESS
}

# Update Meilisearch configuration with secrets
update_meilisearch_config() {
  local meilisearch_yml="core/meilisearch.yml"
  
  log_info "Updating Meilisearch configuration with secrets"
  
  # Check if the Meilisearch YAML file exists
  if [[ ! -f "$meilisearch_yml" ]]; then
    log_error "Meilisearch YAML file not found: $meilisearch_yml"
    return $ERR_FILE_NOT_FOUND
  fi
  
  # Create backup of Meilisearch YAML file
  local backup_file=$(backup_file "$meilisearch_yml")
  if [[ $? -ne 0 ]]; then
    log_warn "Could not create backup of Meilisearch YAML file"
  else
    log_info "Backup created: $backup_file"
  fi
  
  # Get Meilisearch master key
  local meili_master_key=$(get_secret "MEILI_MASTER_KEY")
  
  # Update the Meilisearch YAML file using yq if available
  if command_exists "yq"; then
    yq eval '.services.meilisearch.environment[2] = "MEILI_MASTER_KEY=" + env(MEILI_MASTER_KEY)' -i "$meilisearch_yml" 2>/dev/null
    if [[ $? -ne 0 ]]; then
      log_error "Failed to update Meilisearch YAML file with yq: $meilisearch_yml"
      return $ERR_GENERAL
    fi
  else
    # Fallback to sed if yq is not available
    sed -i "s|MEILI_MASTER_KEY=.*|MEILI_MASTER_KEY=$meili_master_key|" "$meilisearch_yml" 2>/dev/null
    if [[ $? -ne 0 ]]; then
      log_error "Failed to update Meilisearch YAML file with sed: $meilisearch_yml"
      return $ERR_GENERAL
    fi
  fi
  
  log_success "Meilisearch YAML file updated with secrets"
  return $ERR_SUCCESS
}

# Update Traefik configuration with secrets
update_traefik_config() {
  local traefik_yml="modules/security/config/traefik/traefik.yml"
  local services_yml="modules/security/config/traefik/dynamic/services.yml"
  
  log_info "Updating Traefik configuration with secrets"
  
  # Update Traefik main configuration if it exists
  if [[ -f "$traefik_yml" ]]; then
    log_info "Updating Traefik main configuration: $traefik_yml"
    
    # Create backup of Traefik YAML file
    local backup_file=$(backup_file "$traefik_yml")
    if [[ $? -ne 0 ]]; then
      log_warn "Could not create backup of Traefik YAML file"
    else
      log_info "Backup created: $backup_file"
    fi
    
    # Update the insecure setting to false
    if command_exists "yq"; then
      yq eval '.api.insecure = false' -i "$traefik_yml" 2>/dev/null
      if [[ $? -ne 0 ]]; then
        log_error "Failed to update Traefik YAML file with yq: $traefik_yml"
        return $ERR_GENERAL
      fi
    else
      # Fallback to sed if yq is not available
      sed -i "s|insecure: true|insecure: false|" "$traefik_yml" 2>/dev/null
      if [[ $? -ne 0 ]]; then
        log_error "Failed to update Traefik YAML file with sed: $traefik_yml"
        return $ERR_GENERAL
      fi
    fi
    
    # Update the email address
    local admin_email=$(get_config "ADMIN_EMAIL" "admin@local.host")
    if command_exists "yq"; then
      yq eval '.certificatesResolvers.default.acme.email = env(ADMIN_EMAIL)' -i "$traefik_yml" 2>/dev/null
      if [[ $? -ne 0 ]]; then
        log_error "Failed to update Traefik YAML file with yq: $traefik_yml"
        return $ERR_GENERAL
      fi
    else
      # Fallback to sed if yq is not available
      sed -i "s|email: \".*\"|email: \"$admin_email\"|" "$traefik_yml" 2>/dev/null
      if [[ $? -ne 0 ]]; then
        log_error "Failed to update Traefik YAML file with sed: $traefik_yml"
        return $ERR_GENERAL
      fi
    fi
    
    # Enable TLS for websecure entry point
    if command_exists "yq"; then
      yq eval '.entryPoints.websecure.http.tls = {}' -i "$traefik_yml" 2>/dev/null
      if [[ $? -ne 0 ]]; then
        log_error "Failed to update Traefik YAML file with yq: $traefik_yml"
        return $ERR_GENERAL
      fi
    else
      # Fallback to sed if yq is not available
      # This is a bit more complex, so we'll just log a warning
      log_warn "Could not enable TLS for websecure entry point: yq not available"
    fi
    
    log_success "Traefik main configuration updated"
  fi
  
  # Update Traefik dynamic configuration if it exists
  if [[ -f "$services_yml" ]]; then
    log_info "Updating Traefik dynamic configuration: $services_yml"
    
    # Create backup of Traefik services YAML file
    local backup_file=$(backup_file "$services_yml")
    if [[ $? -ne 0 ]]; then
      log_warn "Could not create backup of Traefik services YAML file"
    else
      log_info "Backup created: $backup_file"
    fi
    
    # Get Traefik basic auth
    local traefik_basic_auth=$(get_secret "TRAEFIK_BASIC_AUTH")
    
    # Update the basic auth credentials
    if command_exists "yq"; then
      yq eval '.http.middlewares.ollama-auth.basicAuth.users[0] = env(TRAEFIK_BASIC_AUTH)' -i "$services_yml" 2>/dev/null
      yq eval '.http.middlewares.traefik-auth.basicAuth.users[0] = env(TRAEFIK_BASIC_AUTH)' -i "$services_yml" 2>/dev/null
      if [[ $? -ne 0 ]]; then
        log_error "Failed to update Traefik services YAML file with yq: $services_yml"
        return $ERR_GENERAL
      fi
    else
      # Fallback to sed if yq is not available
      sed -i "s|users:.*|users:|" "$services_yml" 2>/dev/null
      sed -i "s|  - \".*\"|  - \"$traefik_basic_auth\"|" "$services_yml" 2>/dev/null
      if [[ $? -ne 0 ]]; then
        log_error "Failed to update Traefik services YAML file with sed: $services_yml"
        return $ERR_GENERAL
      fi
    fi
    
    # Enable TLS for all routers
    if command_exists "yq"; then
      yq eval '.http.routers.librechat.tls = {}' -i "$services_yml" 2>/dev/null
      yq eval '.http.routers.ollama.tls = {}' -i "$services_yml" 2>/dev/null
      yq eval '.http.routers.traefik-dashboard.tls = {}' -i "$services_yml" 2>/dev/null
      if [[ $? -ne 0 ]]; then
        log_error "Failed to update Traefik services YAML file with yq: $services_yml"
        return $ERR_GENERAL
      fi
    else
      # Fallback to sed if yq is not available
      # This is a bit more complex, so we'll just log a warning
      log_warn "Could not enable TLS for routers: yq not available"
    fi
    
    log_success "Traefik dynamic configuration updated"
  fi
  
  return $ERR_SUCCESS
}

# Update research environment file with secure defaults
update_research_env() {
  local research_env="$CONFIG_DIR/research.env"
  
  log_info "Updating research environment file with secure defaults"
  
  # Check if the research environment file exists
  if [[ ! -f "$research_env" ]]; then
    log_warn "Research environment file not found: $research_env"
    return $ERR_FILE_NOT_FOUND
  fi
  
  # Create backup of research environment file
  local backup_file=$(backup_file "$research_env")
  if [[ $? -ne 0 ]]; then
    log_warn "Could not create backup of research environment file"
  else
    log_info "Backup created: $backup_file"
  fi
  
  # Update the ENABLE_AUTH setting to true
  sed -i "s|ENABLE_AUTH=false|ENABLE_AUTH=true|" "$research_env" 2>/dev/null
  if [[ $? -ne 0 ]]; then
    log_error "Failed to update research environment file: $research_env"
    return $ERR_GENERAL
  fi
  
  log_success "Research environment file updated with secure defaults"
  return $ERR_SUCCESS
}

# Update all configuration files with secrets
update_all_configs() {
  log_info "Updating all configuration files with secrets"
  
  # Generate all required secrets if they don't exist
  generate_all_secrets
  if [[ $? -ne 0 ]]; then
    log_error "Failed to generate secrets"
    return $ERR_GENERAL
  fi
  
  # Update main environment file
  update_env_with_secrets
  if [[ $? -ne 0 ]]; then
    log_error "Failed to update main environment file"
    return $ERR_GENERAL
  fi
  
  # Update LibreChat configuration
  update_librechat_config
  if [[ $? -ne 0 ]]; then
    log_error "Failed to update LibreChat configuration"
    return $ERR_GENERAL
  fi
  
  # Update Meilisearch configuration
  update_meilisearch_config
  if [[ $? -ne 0 ]]; then
    log_error "Failed to update Meilisearch configuration"
    return $ERR_GENERAL
  fi
  
  # Update Traefik configuration
  update_traefik_config
  if [[ $? -ne 0 ]]; then
    log_error "Failed to update Traefik configuration"
    return $ERR_GENERAL
  fi
  
  # Update research environment file
  update_research_env
  if [[ $? -ne 0 ]]; then
    log_warn "Failed to update research environment file"
  fi
  
  log_success "All configuration files updated with secrets"
  return $ERR_SUCCESS
}

# Initialize secrets management
init_secrets

log_debug "Secrets management module initialized"