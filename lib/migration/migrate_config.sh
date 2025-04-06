#!/bin/bash
# migrate_config.sh - Migrate existing configurations to the new standardized format
# This script helps users migrate their existing configurations to the new standardized format
# while preserving their custom settings and data.

# Get the absolute path of the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
LIB_DIR="$ROOT_DIR/lib"

# Source core libraries
source "$LIB_DIR/core/logging.sh"
source "$LIB_DIR/core/error.sh"
source "$LIB_DIR/core/validation.sh"
source "$LIB_DIR/core/config.sh"
source "$LIB_DIR/core/system.sh"

# Default options
VERBOSE=false
FORCE=false
BACKUP=true
DRY_RUN=false
CONFIG_DIR="$ROOT_DIR/config"
CUSTOM_CONFIG_DIR=""

# Function to display usage information
function display_usage() {
  echo "Usage: $0 [OPTIONS]"
  echo "Migrate existing configurations to the new standardized format"
  echo ""
  echo "Options:"
  echo "  --verbose           Display detailed information during execution"
  echo "  --force             Force migration even if validation fails"
  echo "  --no-backup         Skip creating backups of existing configurations"
  echo "  --dry-run           Show what would be done without making changes"
  echo "  --config-dir DIR    Specify custom configuration directory to migrate from"
  echo "  --help              Display this help message and exit"
  echo ""
  echo "Example:"
  echo "  $0 --dry-run                    # Show what would be done without making changes"
  echo "  $0 --config-dir /path/to/config # Migrate from a custom configuration directory"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --verbose)
      VERBOSE=true
      shift
      ;;
    --force)
      FORCE=true
      shift
      ;;
    --no-backup)
      BACKUP=false
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --config-dir)
      CUSTOM_CONFIG_DIR="$2"
      shift 2
      ;;
    --help)
      display_usage
      exit 0
      ;;
    *)
      log_error "Unknown option: $1"
      display_usage
      exit 1
      ;;
  esac
done

# Set log level based on verbosity
if [[ "$VERBOSE" == "true" ]]; then
  set_log_level "debug"
else
  set_log_level "info"
fi

# Set source configuration directory
if [[ -n "$CUSTOM_CONFIG_DIR" ]]; then
  SOURCE_CONFIG_DIR="$CUSTOM_CONFIG_DIR"
  log_info "Using custom configuration directory: $SOURCE_CONFIG_DIR"
else
  SOURCE_CONFIG_DIR="$CONFIG_DIR"
  log_info "Using default configuration directory: $SOURCE_CONFIG_DIR"
fi

# Log the start of the migration
log_info "Starting configuration migration"
if [[ "$DRY_RUN" == "true" ]]; then
  log_warn "Running in dry-run mode. No changes will be made."
fi

# Function to create backup
function create_backup() {
  if [[ "$BACKUP" == "false" ]]; then
    log_warn "Skipping backup as requested"
    return $ERR_SUCCESS
  fi
  
  log_info "Creating backup of existing configurations..."
  
  # Create backup directory with timestamp
  local timestamp=$(date +"%Y%m%d_%H%M%S")
  local backup_dir="$ROOT_DIR/backups/config_$timestamp"
  
  # Ensure backup directory exists
  mkdir -p "$backup_dir"
  
  # Backup configuration files
  log_info "Backing up configuration files..."
  cp -r "$SOURCE_CONFIG_DIR/"* "$backup_dir/"
  
  log_success "Backup created successfully at $backup_dir"
  return $ERR_SUCCESS
}

# Function to validate source configuration
function validate_source_config() {
  log_info "Validating source configuration..."
  
  # Check if source configuration directory exists
  if [[ ! -d "$SOURCE_CONFIG_DIR" ]]; then
    log_error "Source configuration directory not found: $SOURCE_CONFIG_DIR"
    return $ERR_FILE_NOT_FOUND
  fi
  
  # Check if main environment file exists
  if [[ ! -f "$SOURCE_CONFIG_DIR/.env" && ! -f "$SOURCE_CONFIG_DIR/config.env" ]]; then
    log_error "Main environment file not found in source configuration directory"
    if [[ "$FORCE" == "true" ]]; then
      log_warn "Continuing anyway due to --force option"
    else
      return $ERR_FILE_NOT_FOUND
    fi
  fi
  
  log_success "Source configuration validated successfully"
  return $ERR_SUCCESS
}

# Function to migrate main environment file
function migrate_main_env_file() {
  log_info "Migrating main environment file..."
  
  # Determine source environment file
  local source_env_file=""
  if [[ -f "$SOURCE_CONFIG_DIR/.env" ]]; then
    source_env_file="$SOURCE_CONFIG_DIR/.env"
  elif [[ -f "$SOURCE_CONFIG_DIR/config.env" ]]; then
    source_env_file="$SOURCE_CONFIG_DIR/config.env"
  else
    log_error "No environment file found in source configuration directory"
    return $ERR_FILE_NOT_FOUND
  fi
  
  # Determine target environment file
  local target_env_file="$CONFIG_DIR/.env"
  
  log_info "Migrating from $source_env_file to $target_env_file"
  
  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "Dry run: Would migrate environment file from $source_env_file to $target_env_file"
    return $ERR_SUCCESS
  fi
  
  # Ensure target directory exists
  mkdir -p "$CONFIG_DIR"
  
  # Create a temporary file for the new environment file
  local temp_file=$(mktemp)
  
  # Start with the template if it exists
  if [[ -f "$CONFIG_DIR/templates/config-template.env" ]]; then
    cp "$CONFIG_DIR/templates/config-template.env" "$temp_file"
  else
    touch "$temp_file"
  fi
  
  # Read source environment file and update values in the target
  while IFS='=' read -r key value; do
    # Skip comments and empty lines
    if [[ "$key" =~ ^# || -z "$key" ]]; then
      continue
    fi
    
    # Remove any leading/trailing whitespace
    key=$(echo "$key" | xargs)
    value=$(echo "$value" | xargs)
    
    # Update the value in the target file
    if grep -q "^$key=" "$temp_file"; then
      sed -i "s|^$key=.*|$key=$value|" "$temp_file"
    else
      echo "$key=$value" >> "$temp_file"
    fi
  done < "$source_env_file"
  
  # Move the temporary file to the target
  mv "$temp_file" "$target_env_file"
  
  # Set appropriate permissions
  chmod 600 "$target_env_file"
  
  log_success "Main environment file migrated successfully"
  return $ERR_SUCCESS
}

# Function to migrate LibreChat configuration
function migrate_librechat_config() {
  log_info "Migrating LibreChat configuration..."
  
  # Check if source LibreChat configuration exists
  if [[ ! -d "$SOURCE_CONFIG_DIR/librechat" ]]; then
    log_warn "Source LibreChat configuration directory not found, skipping"
    return $ERR_SUCCESS
  fi
  
  # Ensure target directory exists
  mkdir -p "$CONFIG_DIR/librechat"
  
  # Migrate LibreChat YAML file
  if [[ -f "$SOURCE_CONFIG_DIR/librechat/librechat.yaml" ]]; then
    log_info "Migrating LibreChat YAML file..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
      log_info "Dry run: Would migrate LibreChat YAML file"
    else
      cp "$SOURCE_CONFIG_DIR/librechat/librechat.yaml" "$CONFIG_DIR/librechat/librechat.yaml"
    fi
  fi
  
  # Migrate LibreChat environment file
  if [[ -f "$SOURCE_CONFIG_DIR/librechat/.env" ]]; then
    log_info "Migrating LibreChat environment file..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
      log_info "Dry run: Would migrate LibreChat environment file"
    else
      cp "$SOURCE_CONFIG_DIR/librechat/.env" "$CONFIG_DIR/librechat/.env"
      chmod 600 "$CONFIG_DIR/librechat/.env"
    fi
  fi
  
  # Migrate LibreChat auth.json file
  if [[ -f "$SOURCE_CONFIG_DIR/librechat/auth.json" ]]; then
    log_info "Migrating LibreChat auth.json file..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
      log_info "Dry run: Would migrate LibreChat auth.json file"
    else
      cp "$SOURCE_CONFIG_DIR/librechat/auth.json" "$CONFIG_DIR/librechat/auth.json"
    fi
  fi
  
  log_success "LibreChat configuration migrated successfully"
  return $ERR_SUCCESS
}

# Function to migrate MongoDB configuration
function migrate_mongodb_config() {
  log_info "Migrating MongoDB configuration..."
  
  # Check if source MongoDB configuration exists
  if [[ ! -d "$SOURCE_CONFIG_DIR/mongodb" ]]; then
    log_warn "Source MongoDB configuration directory not found, skipping"
    return $ERR_SUCCESS
  fi
  
  # Ensure target directory exists
  mkdir -p "$CONFIG_DIR/mongodb"
  
  # Migrate MongoDB configuration file
  if [[ -f "$SOURCE_CONFIG_DIR/mongodb/mongod.conf" ]]; then
    log_info "Migrating MongoDB configuration file..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
      log_info "Dry run: Would migrate MongoDB configuration file"
    else
      cp "$SOURCE_CONFIG_DIR/mongodb/mongod.conf" "$CONFIG_DIR/mongodb/mongod.conf"
    fi
  fi
  
  log_success "MongoDB configuration migrated successfully"
  return $ERR_SUCCESS
}

# Function to migrate Meilisearch configuration
function migrate_meilisearch_config() {
  log_info "Migrating Meilisearch configuration..."
  
  # Check if source Meilisearch configuration exists
  if [[ ! -d "$SOURCE_CONFIG_DIR/meilisearch" ]]; then
    log_warn "Source Meilisearch configuration directory not found, skipping"
    return $ERR_SUCCESS
  fi
  
  # Ensure target directory exists
  mkdir -p "$CONFIG_DIR/meilisearch"
  
  # Migrate Meilisearch environment file
  if [[ -f "$SOURCE_CONFIG_DIR/meilisearch/env.conf" ]]; then
    log_info "Migrating Meilisearch environment file..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
      log_info "Dry run: Would migrate Meilisearch environment file"
    else
      cp "$SOURCE_CONFIG_DIR/meilisearch/env.conf" "$CONFIG_DIR/meilisearch/env.conf"
    fi
  fi
  
  log_success "Meilisearch configuration migrated successfully"
  return $ERR_SUCCESS
}

# Function to migrate Ollama configuration
function migrate_ollama_config() {
  log_info "Migrating Ollama configuration..."
  
  # Check if source Ollama configuration exists
  if [[ ! -d "$SOURCE_CONFIG_DIR/ollama" ]]; then
    log_warn "Source Ollama configuration directory not found, skipping"
    return $ERR_SUCCESS
  fi
  
  # Ensure target directory exists
  mkdir -p "$CONFIG_DIR/ollama"
  
  # Migrate Ollama environment file
  if [[ -f "$SOURCE_CONFIG_DIR/ollama/env.conf" ]]; then
    log_info "Migrating Ollama environment file..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
      log_info "Dry run: Would migrate Ollama environment file"
    else
      cp "$SOURCE_CONFIG_DIR/ollama/env.conf" "$CONFIG_DIR/ollama/env.conf"
    fi
  fi
  
  # Migrate Ollama modelfile directory
  if [[ -d "$SOURCE_CONFIG_DIR/ollama/modelfile" ]]; then
    log_info "Migrating Ollama modelfile directory..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
      log_info "Dry run: Would migrate Ollama modelfile directory"
    else
      mkdir -p "$CONFIG_DIR/ollama/modelfile"
      cp -r "$SOURCE_CONFIG_DIR/ollama/modelfile/"* "$CONFIG_DIR/ollama/modelfile/"
    fi
  fi
  
  log_success "Ollama configuration migrated successfully"
  return $ERR_SUCCESS
}

# Function to migrate Nginx configuration
function migrate_nginx_config() {
  log_info "Migrating Nginx configuration..."
  
  # Check if source Nginx configuration exists
  if [[ ! -d "$SOURCE_CONFIG_DIR/nginx" ]]; then
    log_warn "Source Nginx configuration directory not found, skipping"
    return $ERR_SUCCESS
  fi
  
  # Ensure target directory exists
  mkdir -p "$CONFIG_DIR/nginx"
  
  # Migrate Nginx configuration file
  if [[ -f "$SOURCE_CONFIG_DIR/nginx/default.conf" ]]; then
    log_info "Migrating Nginx configuration file..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
      log_info "Dry run: Would migrate Nginx configuration file"
    else
      cp "$SOURCE_CONFIG_DIR/nginx/default.conf" "$CONFIG_DIR/nginx/default.conf"
    fi
  fi
  
  log_success "Nginx configuration migrated successfully"
  return $ERR_SUCCESS
}

# Function to update secrets
function update_secrets() {
  log_info "Updating secrets..."
  
  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "Dry run: Would update secrets"
    return $ERR_SUCCESS
  fi
  
  # Check if update_librechat_secrets.sh exists
  if [[ -f "$LIB_DIR/update_librechat_secrets.sh" ]]; then
    log_info "Running update_librechat_secrets.sh..."
    
    # Make the script executable
    chmod +x "$LIB_DIR/update_librechat_secrets.sh"
    
    # Run the script
    "$LIB_DIR/update_librechat_secrets.sh"
    local result=$?
    
    if [[ $result -ne 0 ]]; then
      log_error "Failed to update LibreChat secrets"
      return $result
    fi
  else
    log_warn "update_librechat_secrets.sh not found, skipping"
  fi
  
  log_success "Secrets updated successfully"
  return $ERR_SUCCESS
}

# Function to validate migrated configuration
function validate_migrated_config() {
  log_info "Validating migrated configuration..."
  
  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "Dry run: Would validate migrated configuration"
    return $ERR_SUCCESS
  fi
  
  # Check if validate_configs.sh exists
  if [[ -f "$LIB_DIR/validate_configs.sh" ]]; then
    log_info "Running validate_configs.sh..."
    
    # Make the script executable
    chmod +x "$LIB_DIR/validate_configs.sh"
    
    # Run the script
    "$LIB_DIR/validate_configs.sh"
    local result=$?
    
    if [[ $result -ne 0 ]]; then
      log_error "Configuration validation failed"
      if [[ "$FORCE" == "true" ]]; then
        log_warn "Continuing anyway due to --force option"
      else
        return $result
      fi
    fi
  else
    log_warn "validate_configs.sh not found, skipping validation"
  fi
  
  log_success "Migrated configuration validated successfully"
  return $ERR_SUCCESS
}

# Main function
function main() {
  log_info "Starting configuration migration"
  
  # Validate source configuration
  validate_source_config
  if [[ $? -ne 0 && "$FORCE" != "true" ]]; then
    log_error "Source configuration validation failed"
    exit $ERR_VALIDATION_ERROR
  fi
  
  # Create backup
  create_backup
  if [[ $? -ne 0 ]]; then
    log_error "Backup creation failed"
    exit $ERR_GENERAL
  fi
  
  # Migrate main environment file
  migrate_main_env_file
  if [[ $? -ne 0 ]]; then
    log_error "Main environment file migration failed"
    exit $ERR_GENERAL
  fi
  
  # Migrate component configurations
  migrate_librechat_config
  migrate_mongodb_config
  migrate_meilisearch_config
  migrate_ollama_config
  migrate_nginx_config
  
  # Update secrets
  update_secrets
  if [[ $? -ne 0 ]]; then
    log_error "Secrets update failed"
    exit $ERR_GENERAL
  fi
  
  # Validate migrated configuration
  validate_migrated_config
  if [[ $? -ne 0 && "$FORCE" != "true" ]]; then
    log_error "Migrated configuration validation failed"
    exit $ERR_VALIDATION_ERROR
  fi
  
  log_success "Configuration migration completed successfully"
  log_info "The following tasks have been completed:"
  log_info "1. Backed up existing configuration"
  log_info "2. Migrated main environment file"
  log_info "3. Migrated component configurations"
  log_info "4. Updated secrets"
  log_info "5. Validated migrated configuration"
  
  log_warn "IMPORTANT: Please review the migrated configuration and test the system to ensure everything works correctly"
  log_info "For more information, see the migration guide: docs/migration_guide.md"
}

# Run the main function
main