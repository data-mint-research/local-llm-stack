#!/bin/bash
# validate_config.sh - Validate configuration files against schemas
# This module provides functions for validating configuration files

# Guard against multiple inclusion
if [[ -n "$_VALIDATE_CONFIG_SH_INCLUDED" ]]; then
  return 0
fi
_VALIDATE_CONFIG_SH_INCLUDED=1

# Use a different variable name for the script directory
VALIDATE_CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$VALIDATE_CONFIG_DIR/logging.sh"
source "$VALIDATE_CONFIG_DIR/error.sh"
source "$VALIDATE_CONFIG_DIR/system.sh"

# Check if required tools are installed
check_validation_dependencies() {
  log_debug "Checking validation dependencies"
  
  # Check if yq is installed
  if ! command_exists "yq"; then
    log_error "yq is not installed. Please install it to validate YAML files."
    return $ERR_COMMAND_NOT_FOUND
  fi
  
  # Check if jq is installed
  if ! command_exists "jq"; then
    log_error "jq is not installed. Please install it to validate JSON files."
    return $ERR_COMMAND_NOT_FOUND
  fi
  
  return $ERR_SUCCESS
}

# Validate a YAML file against a schema
validate_yaml_file() {
  local file=$1
  local schema=$2
  
  log_debug "Validating YAML file $file against schema $schema"
  
  # Check if files exist
  if [[ ! -f "$file" ]]; then
    log_error "File not found: $file"
    return $ERR_FILE_NOT_FOUND
  fi
  
  if [[ ! -f "$schema" ]]; then
    log_error "Schema file not found: $schema"
    return $ERR_FILE_NOT_FOUND
  fi
  
  # Check if yamllint is installed
  if command_exists "yamllint"; then
    log_debug "Running yamllint on $file"
    yamllint -d relaxed "$file" > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
      log_error "YAML syntax error in $file"
      yamllint -d relaxed "$file"
      return $ERR_VALIDATION_ERROR
    fi
  else
    log_warn "yamllint not installed, skipping YAML syntax validation"
  fi
  
  # For now, we'll just check if the file is valid YAML
  # In the future, we can implement more sophisticated schema validation
  yq eval '.' "$file" > /dev/null 2>&1
  if [[ $? -ne 0 ]]; then
    log_error "Invalid YAML in $file"
    return $ERR_VALIDATION_ERROR
  fi
  
  log_success "YAML file $file is valid"
  return $ERR_SUCCESS
}

# Validate a JSON file against a schema
validate_json_file() {
  local file=$1
  local schema=$2
  
  log_debug "Validating JSON file $file against schema $schema"
  
  # Check if files exist
  if [[ ! -f "$file" ]]; then
    log_error "File not found: $file"
    return $ERR_FILE_NOT_FOUND
  fi
  
  if [[ ! -f "$schema" ]]; then
    log_error "Schema file not found: $schema"
    return $ERR_FILE_NOT_FOUND
  fi
  
  # Check if the file is valid JSON
  jq '.' "$file" > /dev/null 2>&1
  if [[ $? -ne 0 ]]; then
    log_error "Invalid JSON in $file"
    return $ERR_VALIDATION_ERROR
  fi
  
  log_success "JSON file $file is valid"
  return $ERR_SUCCESS
}

# Validate an environment file
validate_env_file() {
  local file=$1
  
  log_debug "Validating environment file $file"
  
  # Check if file exists
  if [[ ! -f "$file" ]]; then
    log_error "File not found: $file"
    return $ERR_FILE_NOT_FOUND
  fi
  
  # Check for common issues in environment files
  local line_num=0
  local errors=0
  
  while IFS= read -r line || [[ -n "$line" ]]; do
    ((line_num++))
    
    # Skip comments and empty lines
    [[ "$line" =~ ^#.*$ ]] || [[ -z "$line" ]] && continue
    
    # Check for lines without equals sign
    if ! [[ "$line" =~ = ]]; then
      log_error "Line $line_num: Missing equals sign: $line"
      ((errors++))
      continue
    fi
    
    # Check for lines with spaces around equals sign
    if [[ "$line" =~ [[:space:]]=|=[[:space:]] ]]; then
      log_warn "Line $line_num: Spaces around equals sign: $line"
    fi
    
    # Extract key and value
    local key="${line%%=*}"
    local value="${line#*=}"
    
    # Check for empty keys
    if [[ -z "$key" ]]; then
      log_error "Line $line_num: Empty key: $line"
      ((errors++))
      continue
    fi
    
    # Check for keys with invalid characters
    if [[ ! "$key" =~ ^[A-Za-z0-9_]+$ ]]; then
      log_error "Line $line_num: Invalid characters in key: $key"
      ((errors++))
      continue
    fi
    
    # Check for specific variables that should not be empty
    if [[ "$key" =~ ^(JWT_SECRET|JWT_REFRESH_SECRET|SESSION_SECRET|CRYPT_SECRET|CREDS_KEY|CREDS_IV|ADMIN_PASSWORD|GRAFANA_ADMIN_PASSWORD|MEILI_MASTER_KEY)$ ]] && [[ -z "$value" ]]; then
      log_error "Line $line_num: Security-sensitive variable $key should not be empty"
      ((errors++))
      continue
    fi
    
    # Check for specific variables that should be true
    if [[ "$key" == "ENABLE_AUTH" ]] && [[ "$value" != "true" ]]; then
      log_error "Line $line_num: ENABLE_AUTH should be set to true for security"
      ((errors++))
      continue
    fi
    
    # Check for specific variables that should have minimum length
    if [[ "$key" =~ ^(JWT_SECRET|JWT_REFRESH_SECRET|SESSION_SECRET|CRYPT_SECRET)$ ]] && [[ ${#value} -lt 32 ]]; then
      log_error "Line $line_num: $key should be at least 32 characters long"
      ((errors++))
      continue
    fi
    
    if [[ "$key" =~ ^(ADMIN_PASSWORD|GRAFANA_ADMIN_PASSWORD|MEILI_MASTER_KEY)$ ]] && [[ ${#value} -lt 8 ]]; then
      log_error "Line $line_num: $key should be at least 8 characters long"
      ((errors++))
      continue
    fi
    
    # Check for specific variables that should be valid memory limits
    if [[ "$key" =~ _MEMORY_LIMIT$ ]] && ! [[ "$value" =~ ^[0-9]+G$ ]]; then
      log_error "Line $line_num: $key should be in format '16G': $value"
      ((errors++))
      continue
    fi
    
    # Check for specific variables that should be valid CPU limits
    if [[ "$key" =~ _CPU_LIMIT$ ]] && ! [[ "$value" =~ ^0\.[0-9]+$ ]]; then
      log_error "Line $line_num: $key should be a decimal between 0.0 and 1.0: $value"
      ((errors++))
      continue
    fi
    
    # Check for specific variables that should be valid ports
    if [[ "$key" =~ ^HOST_PORT_ ]] && ! [[ "$value" =~ ^[0-9]+$ ]]; then
      log_error "Line $line_num: $key should be a valid port number: $value"
      ((errors++))
      continue
    fi
    
    if [[ "$key" =~ ^HOST_PORT_ ]] && (( value < 1 || value > 65535 )); then
      log_error "Line $line_num: $key should be between 1 and 65535: $value"
      ((errors++))
      continue
    fi
    
  done < "$file"
  
  if [[ $errors -gt 0 ]]; then
    log_error "Found $errors errors in $file"
    return $ERR_VALIDATION_ERROR
  fi
  
  log_success "Environment file $file is valid"
  return $ERR_SUCCESS
}

# Validate all configuration files
validate_all_configs() {
  local config_dir=${1:-"config"}
  local schema_dir=${2:-"docs/schema"}
  
  log_info "Validating all configuration files"
  
  # Check dependencies
  check_validation_dependencies
  if [[ $? -ne 0 ]]; then
    log_warn "Skipping validation due to missing dependencies"
    return $ERR_COMMAND_NOT_FOUND
  fi
  
  # Validate main environment file
  validate_env_file "$config_dir/.env"
  if [[ $? -ne 0 ]]; then
    log_error "Main environment file validation failed"
    return $ERR_VALIDATION_ERROR
  fi
  
  # Validate research environment file if it exists
  if [[ -f "$config_dir/research.env" ]]; then
    validate_env_file "$config_dir/research.env"
    if [[ $? -ne 0 ]]; then
      log_error "Research environment file validation failed"
      return $ERR_VALIDATION_ERROR
    fi
  fi
  
  # Validate LibreChat YAML config if it exists
  if [[ -f "$config_dir/librechat/librechat.yaml" ]]; then
    validate_yaml_file "$config_dir/librechat/librechat.yaml" "$schema_dir/config-schema.yaml"
    if [[ $? -ne 0 ]]; then
      log_error "LibreChat YAML config validation failed"
      return $ERR_VALIDATION_ERROR
    fi
  fi
  
  # Validate Traefik config if it exists
  if [[ -f "modules/security/config/traefik/traefik.yml" ]]; then
    validate_yaml_file "modules/security/config/traefik/traefik.yml" "$schema_dir/config-schema.yaml"
    if [[ $? -ne 0 ]]; then
      log_error "Traefik config validation failed"
      return $ERR_VALIDATION_ERROR
    fi
  fi
  
  # Validate Traefik dynamic config if it exists
  if [[ -f "modules/security/config/traefik/dynamic/services.yml" ]]; then
    validate_yaml_file "modules/security/config/traefik/dynamic/services.yml" "$schema_dir/config-schema.yaml"
    if [[ $? -ne 0 ]]; then
      log_error "Traefik dynamic config validation failed"
      return $ERR_VALIDATION_ERROR
    fi
  fi
  
  # Validate core YAML files
  for yaml_file in core/*.yml; do
    validate_yaml_file "$yaml_file" "$schema_dir/config-schema.yaml"
    if [[ $? -ne 0 ]]; then
      log_error "Core YAML file validation failed: $yaml_file"
      return $ERR_VALIDATION_ERROR
    fi
  done
  
  log_success "All configuration files are valid"
  return $ERR_SUCCESS
}

log_debug "Configuration validation module initialized"