#!/bin/bash
# config.sh - Configuration management for LOCAL-LLM-Stack
# This module provides functions for loading, validating, and managing configuration

# Guard against multiple inclusion
if [[ -n "$_CONFIG_SH_INCLUDED" ]]; then
  return 0
fi
_CONFIG_SH_INCLUDED=1

# Use a different variable name for the script directory
CONFIG_MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CONFIG_MODULE_DIR/logging.sh"
source "$CONFIG_MODULE_DIR/error.sh"
source "$CONFIG_MODULE_DIR/system.sh"
source "$CONFIG_MODULE_DIR/validation.sh"

# Default configuration values
readonly DEFAULT_CONFIG_DIR="config"
readonly DEFAULT_ENV_FILE="$DEFAULT_CONFIG_DIR/.env"
readonly DEFAULT_CORE_PROJECT="local-llm-stack"
readonly DEFAULT_DEBUG_PROJECT="$DEFAULT_CORE_PROJECT-debug"
readonly DEFAULT_CORE_COMPOSE="-f core/docker-compose.yml"
readonly DEFAULT_DEBUG_COMPOSE="$DEFAULT_CORE_COMPOSE -f core/docker-compose.debug.yml"

# Global configuration variables
CONFIG_DIR="$DEFAULT_CONFIG_DIR"
ENV_FILE="$DEFAULT_ENV_FILE"
CORE_PROJECT="$DEFAULT_CORE_PROJECT"
DEBUG_PROJECT="$DEFAULT_DEBUG_PROJECT"
CORE_COMPOSE="$DEFAULT_CORE_COMPOSE"
DEBUG_COMPOSE="$DEFAULT_DEBUG_COMPOSE"

# Initialize configuration with default values
init_config() {
  log_debug "Initializing configuration with default values"
  
  # Set default values
  CONFIG_DIR="$DEFAULT_CONFIG_DIR"
  ENV_FILE="$DEFAULT_ENV_FILE"
  CORE_PROJECT="$DEFAULT_CORE_PROJECT"
  DEBUG_PROJECT="$DEFAULT_DEBUG_PROJECT"
  CORE_COMPOSE="$DEFAULT_CORE_COMPOSE"
  DEBUG_COMPOSE="$DEFAULT_DEBUG_COMPOSE"
  
  return $ERR_SUCCESS
}

# Load configuration from .env file
load_config() {
  local env_file=${1:-"$ENV_FILE"}
  
  log_debug "Loading configuration from $env_file"
  
  # Check if file exists
  if [[ ! -f "$env_file" ]]; then
    log_warn "Configuration file not found: $env_file"
    return $ERR_FILE_NOT_FOUND
  fi
  
  # Check if file is readable
  if [[ ! -r "$env_file" ]]; then
    log_error "Configuration file is not readable: $env_file"
    return $ERR_PERMISSION_DENIED
  fi
  
  # Load variables without exporting them
  log_debug "Parsing configuration file"
  while IFS='=' read -r key value || [[ -n "$key" ]]; do
    # Skip comments and empty lines
    [[ $key =~ ^#.*$ ]] || [[ -z "$key" ]] && continue
    
    # Remove quotes from value if present
    value="${value%\"}"
    value="${value#\"}"
    
    # Export the variable
    export "$key=$value"
    log_debug "Loaded config: $key=$value"
  done < "$env_file"
  
  log_success "Configuration loaded from $env_file"
  return $ERR_SUCCESS
}

# Save configuration to .env file
save_config() {
  local env_file=${1:-"$ENV_FILE"}
  local variables=("${@:2}")
  
  log_debug "Saving configuration to $env_file"
  
  # Ensure the config directory exists
  local config_dir=$(dirname "$env_file")
  ensure_directory "$config_dir"
  if [[ $? -ne 0 ]]; then
    log_error "Failed to create config directory: $config_dir"
    return $ERR_PERMISSION_DENIED
  fi
  
  # Create backup if the file exists
  if [[ -f "$env_file" ]]; then
    local backup_file=$(backup_file "$env_file")
    if [[ $? -ne 0 ]]; then
      log_warn "Could not create backup of configuration file"
    else
      log_info "Backup created: $backup_file"
    fi
  fi
  
  # If no variables are provided, don't modify the file
  if [[ ${#variables[@]} -eq 0 ]]; then
    log_debug "No variables provided, configuration file not modified"
    return $ERR_SUCCESS
  fi
  
  # Update the configuration file
  update_env_vars "$env_file" "${variables[@]}"
  if [[ $? -ne 0 ]]; then
    log_error "Failed to update configuration file: $env_file"
    return $ERR_CONFIG_ERROR
  fi
  
  log_success "Configuration saved to $env_file"
  return $ERR_SUCCESS
}

# Get a configuration value
get_config() {
  local key=$1
  local default_value=${2:-""}
  
  log_debug "Getting configuration value for $key"
  
  # Get the value from environment
  local value=${!key:-$default_value}
  
  echo "$value"
  return $ERR_SUCCESS
}

# Set a configuration value
set_config() {
  local key=$1
  local value=$2
  
  log_debug "Setting configuration value: $key=$value"
  
  # Export the variable
  export "$key=$value"
  
  return $ERR_SUCCESS
}

# Update environment variables in a file
update_env_vars() {
  local env_file=$1
  shift
  local vars=("$@")
  
  log_debug "Updating environment variables in $env_file"
  
  # Check if file exists and is writable
  if [[ ! -f "$env_file" ]]; then
    log_debug "Creating new file: $env_file"
    # Create the file with the variables
    for var in "${vars[@]}"; do
      echo "$var" >> "$env_file" 2> /dev/null || {
        log_error "Could not write to $env_file"
        return $ERR_PERMISSION_DENIED
      }
    done
    return $ERR_SUCCESS
  fi
  
  # Check if file is writable
  if [[ ! -w "$env_file" ]]; then
    log_error "File $env_file is not writable"
    return $ERR_PERMISSION_DENIED
  fi
  
  # Create a temporary file
  local tmp_file="$env_file.tmp"
  
  # Build the awk script dynamically
  local awk_script="{"
  for var in "${vars[@]}"; do
    IFS='=' read -r name value <<< "$var"
    # Add a flag to track if the variable was found
    awk_script+="found_$name=0; "
    # Replace existing variable
    awk_script+="if (/^$name=/) { print \"$name=$value\"; found_$name=1; next; } "
  done
  # Print all other lines
  awk_script+="print; "
  # End of file processing
  awk_script+="} END {"
  # Add any variables that weren't found
  for var in "${vars[@]}"; do
    IFS='=' read -r name value <<< "$var"
    awk_script+="if (found_$name==0) { print \"$name=$value\"; } "
  done
  awk_script+="}"
  
  # Execute the awk command
  awk "$awk_script" "$env_file" > "$tmp_file" 2> /dev/null && mv "$tmp_file" "$env_file" 2> /dev/null || {
    log_error "Could not update $env_file"
    return $ERR_CONFIG_ERROR
  }
  
  return $ERR_SUCCESS
}

# Validate configuration
validate_config() {
  log_debug "Validating configuration"
  
  # Check if required configuration files exist
  if [[ ! -f "$ENV_FILE" ]]; then
    log_error "Main configuration file not found: $ENV_FILE"
    return $ERR_CONFIG_ERROR
  fi
  
  # Validate port configurations
  local host_port_ollama=$(get_config "HOST_PORT_OLLAMA" "11434")
  validate_port "$host_port_ollama" "HOST_PORT_OLLAMA"
  if [[ $? -ne 0 ]]; then
    return $ERR_VALIDATION_ERROR
  fi
  
  local host_port_librechat=$(get_config "HOST_PORT_LIBRECHAT" "3080")
  validate_port "$host_port_librechat" "HOST_PORT_LIBRECHAT"
  if [[ $? -ne 0 ]]; then
    return $ERR_VALIDATION_ERROR
  fi
  
  # Validate resource limits
  local ollama_cpu_limit=$(get_config "OLLAMA_CPU_LIMIT" "0.75")
  validate_is_decimal "$ollama_cpu_limit" "OLLAMA_CPU_LIMIT"
  if [[ $? -ne 0 ]]; then
    return $ERR_VALIDATION_ERROR
  fi
  
  # Validate memory limits (ensure they have G suffix)
  local ollama_memory_limit=$(get_config "OLLAMA_MEMORY_LIMIT" "16G")
  if ! [[ "$ollama_memory_limit" =~ ^[0-9]+G$ ]]; then
    log_error "OLLAMA_MEMORY_LIMIT must be in format '16G': $ollama_memory_limit"
    return $ERR_VALIDATION_ERROR
  fi
  
  # Validate security settings
  local jwt_secret=$(get_config "JWT_SECRET" "")
  if [[ -z "$jwt_secret" ]]; then
    log_error "JWT_SECRET is not set"
    return $ERR_VALIDATION_ERROR
  fi
  
  local jwt_refresh_secret=$(get_config "JWT_REFRESH_SECRET" "")
  if [[ -z "$jwt_refresh_secret" ]]; then
    log_error "JWT_REFRESH_SECRET is not set"
    return $ERR_VALIDATION_ERROR
  fi
  
  log_success "Configuration validation passed"
  return $ERR_SUCCESS
}

# Check if secrets are generated and generate them if needed
check_secrets() {
  log_info "Checking if secrets are generated"
  
  # Check if config/.env exists
  if [[ ! -f "$ENV_FILE" ]]; then
    log_warn "Configuration file not found. Generating secrets..."
    generate_secrets
    return $ERR_SUCCESS
  fi
  
  # Check if any of the required secrets are empty in the main config file
  local jwt_secret=$(get_config "JWT_SECRET" "")
  local jwt_refresh_secret=$(get_config "JWT_REFRESH_SECRET" "")
  local session_secret=$(get_config "SESSION_SECRET" "")
  
  # Also check the LibreChat .env file if it exists
  local librechat_jwt_secret=""
  local librechat_jwt_refresh_secret=""
  local librechat_needs_update=false
  local librechat_env="$CONFIG_DIR/librechat/.env"
  
  if [[ -f "$librechat_env" ]]; then
    log_debug "Found LibreChat .env file"
    
    # Get LibreChat JWT secrets
    librechat_jwt_secret=$(grep -E "^JWT_SECRET=" "$librechat_env" | cut -d= -f2)
    librechat_jwt_refresh_secret=$(grep -E "^JWT_REFRESH_SECRET=" "$librechat_env" | cut -d= -f2)
    
    # Check if LibreChat secrets are empty
    if [[ -z "$librechat_jwt_secret" ]]; then
      log_warn "LibreChat JWT_SECRET is empty"
      librechat_needs_update=true
    fi
    
    if [[ -z "$librechat_jwt_refresh_secret" ]]; then
      log_warn "LibreChat JWT_REFRESH_SECRET is empty"
      librechat_needs_update=true
    fi
  fi
  
  # Check if main secrets need to be generated
  if [[ -z "$jwt_secret" || -z "$jwt_refresh_secret" || -z "$session_secret" ]]; then
    log_warn "Some required secrets are not set in main config. Generating secrets..."
    generate_secrets
  elif [[ "$librechat_needs_update" == "true" ]]; then
    log_warn "LibreChat JWT secrets need to be updated. Updating from main config..."
    
    # Update LibreChat secrets from main config
    update_librechat_secrets
  else
    log_success "All required secrets are set"
  fi
  
  return $ERR_SUCCESS
}

# Generate secure secrets
generate_secrets() {
  log_info "Generating secure secrets"
  
  # This function will be implemented in a separate script
  # For now, we'll just call the existing script
  "$CONFIG_MODULE_DIR/../../lib/generate_secrets.sh"
  
  return $ERR_SUCCESS
}

# Update LibreChat secrets from main config
update_librechat_secrets() {
  log_info "Updating LibreChat secrets from main config"
  
  # This function will be implemented in a separate script
  # For now, we'll just call the existing script
  "$CONFIG_MODULE_DIR/../../lib/update_librechat_secrets.sh"
  
  return $ERR_SUCCESS
}

# Initialize configuration
init_config

log_debug "Configuration module initialized"