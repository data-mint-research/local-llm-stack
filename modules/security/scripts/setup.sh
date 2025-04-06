#!/bin/bash
# modules/security/scripts/setup.sh
# Setup script security for modules

# Get the absolute path of the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT_DIR="$(cd "$MODULE_DIR/../.." && pwd)"

# Source core libraries
source "$ROOT_DIR/lib/core/logging.sh"
source "$ROOT_DIR/lib/core/error.sh"
source "$ROOT_DIR/lib/core/validation.sh"
source "$ROOT_DIR/lib/core/config.sh"

# Module name (derived from directory name)
MODULE_NAME=$(basename "$MODULE_DIR")

# Log the start of setup
log_info "Setting up $MODULE_NAME module..."

# Function to validate module prerequisites
function validate_prerequisites() {
  log_debug "Validating prerequisites for $MODULE_NAME module..."
  
  # Example: Check if Docker is installed
  if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed. Please install Docker before setting up this module."
    return $ERR_DEPENDENCY_MISSING
  fi
  
  # Example: Check if Docker Compose is installed
  if ! command -v docker-compose &> /dev/null; then
    log_error "Docker Compose is not installed. Please install Docker Compose before setting up this module."
    return $ERR_DEPENDENCY_MISSING
  fi
  
  # Add more prerequisite checks as needed
  
  log_debug "All prerequisites for $MODULE_NAME module are satisfied."
  return $ERR_SUCCESS
}

# Function to create required directories
function create_directories() {
  log_debug "Creating required directories for $MODULE_NAME module..."
  
  # Example: Create data directory
  mkdir -p "$ROOT_DIR/data/$MODULE_NAME"
  if [[ $? -ne 0 ]]; then
    log_error "Failed to create data directory for $MODULE_NAME module."
    return $ERR_GENERAL
  fi
  
  # Add more directory creation as needed
  
  log_debug "All required directories for $MODULE_NAME module have been created."
  return $ERR_SUCCESS
}

# Function to configure the module
function configure_module() {
  log_debug "Configuring $MODULE_NAME module..."
  
  # Example: Copy default configuration if not exists
  if [[ ! -f "$ROOT_DIR/config/$MODULE_NAME/env.conf" ]]; then
    mkdir -p "$ROOT_DIR/config/$MODULE_NAME"
    cp "$MODULE_DIR/config/env.conf" "$ROOT_DIR/config/$MODULE_NAME/env.conf"
    if [[ $? -ne 0 ]]; then
      log_error "Failed to copy default configuration for $MODULE_NAME module."
      return $ERR_GENERAL
    fi
    log_info "Created default configuration for $MODULE_NAME module."
  else
    log_debug "Configuration for $MODULE_NAME module already exists."
  fi
  
  # Add more configuration steps as needed
  
  log_debug "$MODULE_NAME module has been configured."
  return $ERR_SUCCESS
}

# Function to perform post-setup tasks
function post_setup() {
  log_debug "Performing post-setup tasks for $MODULE_NAME module..."
  
  # Example: Display success message with usage instructions
  log_success "$MODULE_NAME module has been set up successfully."
  log_info "To start the module, run: ./llm start --with $MODULE_NAME"
  
  # Add more post-setup tasks as needed
  
  return $ERR_SUCCESS
}

# Main setup function
function setup_module() {
  log_debug "Starting setup process for $MODULE_NAME module..."
  
  # Validate prerequisites
  validate_prerequisites
  if [[ $? -ne 0 ]]; then
    log_error "Failed to validate prerequisites for $MODULE_NAME module."
    return $ERR_GENERAL
  fi
  
  # Create required directories
  create_directories
  if [[ $? -ne 0 ]]; then
    log_error "Failed to create required directories for $MODULE_NAME module."
    return $ERR_GENERAL
  fi
  
  # Configure the module
  configure_module
  if [[ $? -ne 0 ]]; then
    log_error "Failed to configure $MODULE_NAME module."
    return $ERR_GENERAL
  fi
  
  # Perform post-setup tasks
  post_setup
  if [[ $? -ne 0 ]]; then
    log_error "Failed to perform post-setup tasks for $MODULE_NAME module."
    return $ERR_GENERAL
  fi
  
  log_success "$MODULE_NAME module setup completed successfully."
  return $ERR_SUCCESS
}

# Run the setup function
setup_module
exit $?