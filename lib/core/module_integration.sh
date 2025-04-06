#!/bin/bash
# lib/core/module_integration.sh
# Standardized module integration library for LOCAL-LLM-Stack

# Guard against multiple inclusion
if [[ -n "$_CORE_MODULE_INTEGRATION_SH_INCLUDED" ]]; then
  return 0
fi
_CORE_MODULE_INTEGRATION_SH_INCLUDED=1

# Get the absolute path of the script directory
MODULE_INTEGRATION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$MODULE_INTEGRATION_DIR/../.." && pwd)"

# Source dependencies
source "$MODULE_INTEGRATION_DIR/logging.sh"
source "$MODULE_INTEGRATION_DIR/error.sh"
source "$MODULE_INTEGRATION_DIR/validation.sh"
source "$MODULE_INTEGRATION_DIR/config.sh"
source "$MODULE_INTEGRATION_DIR/docker.sh"

# Module status constants
readonly MODULE_STATUS_UNKNOWN=0
readonly MODULE_STATUS_STOPPED=1
readonly MODULE_STATUS_STARTING=2
readonly MODULE_STATUS_RUNNING=3
readonly MODULE_STATUS_STOPPING=4
readonly MODULE_STATUS_ERROR=5

# Module directories
readonly MODULES_DIR="$ROOT_DIR/modules"
readonly CONFIG_DIR="$ROOT_DIR/config"
readonly DATA_DIR="$ROOT_DIR/data"

# Get a list of all available modules
# 
# Returns:
#   Space-separated list of module names
function get_available_modules() {
  find "$MODULES_DIR" -mindepth 1 -maxdepth 1 -type d -not -path "*/\.*" -not -path "*/template" | sort | xargs -n1 basename
}

# Check if a module exists
# 
# Parameters:
#   $1 - Module name
#
# Returns:
#   0 - Module exists
#   1 - Module does not exist
function module_exists() {
  local module_name=$1
  
  if [[ -d "$MODULES_DIR/$module_name" ]]; then
    return 0
  else
    return 1
  fi
}

# Get the status of a module
# 
# Parameters:
#   $1 - Module name
#
# Returns:
#   Module status code (0-5)
function get_module_status() {
  local module_name=$1
  
  # Check if module exists
  if ! module_exists "$module_name"; then
    log_error "Module does not exist: $module_name"
    return $MODULE_STATUS_UNKNOWN
  fi
  
  # Check if Docker is running
  if ! command -v docker &> /dev/null || ! docker info &> /dev/null; then
    return $MODULE_STATUS_UNKNOWN
  fi
  
  # Check if module has a docker-compose.yml file
  local docker_compose_file="$MODULES_DIR/$module_name/docker-compose.yml"
  if [[ ! -f "$docker_compose_file" ]]; then
    # If no docker-compose.yml, check if module has a setup script
    local setup_script="$MODULES_DIR/$module_name/scripts/setup.sh"
    if [[ -f "$setup_script" && -x "$setup_script" ]]; then
      # Module has a setup script but no docker-compose.yml
      # Consider it running if setup has been executed
      if [[ -d "$DATA_DIR/$module_name" ]]; then
        return $MODULE_STATUS_RUNNING
      else
        return $MODULE_STATUS_STOPPED
      fi
    else
      # Module has neither docker-compose.yml nor setup script
      return $MODULE_STATUS_UNKNOWN
    fi
  fi
  
  # Get the number of running containers for this module
  local running_containers=$(docker-compose -f "$docker_compose_file" ps --services --filter "status=running" 2>/dev/null | wc -l)
  local total_containers=$(docker-compose -f "$docker_compose_file" ps --services 2>/dev/null | wc -l)
  
  # Determine status based on container count
  if [[ $total_containers -eq 0 ]]; then
    return $MODULE_STATUS_UNKNOWN
  elif [[ $running_containers -eq 0 ]]; then
    return $MODULE_STATUS_STOPPED
  elif [[ $running_containers -lt $total_containers ]]; then
    # Some containers are running, but not all
    return $MODULE_STATUS_ERROR
  else
    # All containers are running
    return $MODULE_STATUS_RUNNING
  fi
}

# Get the status of a module as text
# 
# Parameters:
#   $1 - Module name
#
# Returns:
#   Module status text
function get_module_status_text() {
  local module_name=$1
  local status
  
  get_module_status "$module_name"
  status=$?
  
  case $status in
    $MODULE_STATUS_UNKNOWN)
      echo "Unknown"
      ;;
    $MODULE_STATUS_STOPPED)
      echo "Stopped"
      ;;
    $MODULE_STATUS_STARTING)
      echo "Starting"
      ;;
    $MODULE_STATUS_RUNNING)
      echo "Running"
      ;;
    $MODULE_STATUS_STOPPING)
      echo "Stopping"
      ;;
    $MODULE_STATUS_ERROR)
      echo "Error"
      ;;
    *)
      echo "Invalid status"
      ;;
  esac
}

# Start a module
# 
# Parameters:
#   $1 - Module name
#
# Returns:
#   0 - Success
#   Non-zero - Error code
function start_module() {
  local module_name=$1
  
  # Check if module exists
  if ! module_exists "$module_name"; then
    log_error "Module does not exist: $module_name"
    return $ERR_NOT_FOUND
  fi
  
  log_info "Starting module: $module_name"
  
  # Check if module is already running
  get_module_status "$module_name"
  local status=$?
  
  if [[ $status -eq $MODULE_STATUS_RUNNING ]]; then
    log_warning "Module is already running: $module_name"
    return $ERR_SUCCESS
  fi
  
  # Check if module has a docker-compose.yml file
  local docker_compose_file="$MODULES_DIR/$module_name/docker-compose.yml"
  if [[ -f "$docker_compose_file" ]]; then
    # Start the module using Docker Compose
    log_debug "Starting module using Docker Compose: $module_name"
    docker_compose_up "$docker_compose_file" "-d"
    local result=$?
    
    if [[ $result -ne 0 ]]; then
      log_error "Failed to start module: $module_name"
      return $ERR_GENERAL
    fi
  else
    # Check if module has a setup script
    local setup_script="$MODULES_DIR/$module_name/scripts/setup.sh"
    if [[ -f "$setup_script" && -x "$setup_script" ]]; then
      # Run the setup script
      log_debug "Running module setup script: $module_name"
      "$setup_script"
      local result=$?
      
      if [[ $result -ne 0 ]]; then
        log_error "Failed to run setup script for module: $module_name"
        return $ERR_GENERAL
      fi
    else
      log_error "Module has no docker-compose.yml or setup script: $module_name"
      return $ERR_NOT_IMPLEMENTED
    fi
  fi
  
  log_success "Module started successfully: $module_name"
  return $ERR_SUCCESS
}

# Stop a module
# 
# Parameters:
#   $1 - Module name
#
# Returns:
#   0 - Success
#   Non-zero - Error code
function stop_module() {
  local module_name=$1
  
  # Check if module exists
  if ! module_exists "$module_name"; then
    log_error "Module does not exist: $module_name"
    return $ERR_NOT_FOUND
  fi
  
  log_info "Stopping module: $module_name"
  
  # Check if module is already stopped
  get_module_status "$module_name"
  local status=$?
  
  if [[ $status -eq $MODULE_STATUS_STOPPED ]]; then
    log_warning "Module is already stopped: $module_name"
    return $ERR_SUCCESS
  fi
  
  # Check if module has a docker-compose.yml file
  local docker_compose_file="$MODULES_DIR/$module_name/docker-compose.yml"
  if [[ -f "$docker_compose_file" ]]; then
    # Stop the module using Docker Compose
    log_debug "Stopping module using Docker Compose: $module_name"
    docker_compose_down "$docker_compose_file"
    local result=$?
    
    if [[ $result -ne 0 ]]; then
      log_error "Failed to stop module: $module_name"
      return $ERR_GENERAL
    fi
  else
    # Check if module has a teardown script
    local teardown_script="$MODULES_DIR/$module_name/scripts/teardown.sh"
    if [[ -f "$teardown_script" && -x "$teardown_script" ]]; then
      # Run the teardown script
      log_debug "Running module teardown script: $module_name"
      "$teardown_script"
      local result=$?
      
      if [[ $result -ne 0 ]]; then
        log_error "Failed to run teardown script for module: $module_name"
        return $ERR_GENERAL
      fi
    else
      log_warning "Module has no docker-compose.yml or teardown script: $module_name"
      return $ERR_SUCCESS
    fi
  fi
  
  log_success "Module stopped successfully: $module_name"
  return $ERR_SUCCESS
}

# Restart a module
# 
# Parameters:
#   $1 - Module name
#
# Returns:
#   0 - Success
#   Non-zero - Error code
function restart_module() {
  local module_name=$1
  
  # Check if module exists
  if ! module_exists "$module_name"; then
    log_error "Module does not exist: $module_name"
    return $ERR_NOT_FOUND
  fi
  
  log_info "Restarting module: $module_name"
  
  # Stop the module
  stop_module "$module_name"
  local stop_result=$?
  
  if [[ $stop_result -ne 0 && $stop_result -ne $ERR_SUCCESS ]]; then
    log_error "Failed to stop module during restart: $module_name"
    return $stop_result
  fi
  
  # Start the module
  start_module "$module_name"
  local start_result=$?
  
  if [[ $start_result -ne 0 ]]; then
    log_error "Failed to start module during restart: $module_name"
    return $start_result
  fi
  
  log_success "Module restarted successfully: $module_name"
  return $ERR_SUCCESS
}

# Get module logs
# 
# Parameters:
#   $1 - Module name
#   $2 - Service name (optional)
#   $3 - Number of lines (optional, default: 100)
#
# Returns:
#   Module logs
function get_module_logs() {
  local module_name=$1
  local service_name=$2
  local lines=${3:-100}
  
  # Check if module exists
  if ! module_exists "$module_name"; then
    log_error "Module does not exist: $module_name"
    return $ERR_NOT_FOUND
  fi
  
  # Check if module has a docker-compose.yml file
  local docker_compose_file="$MODULES_DIR/$module_name/docker-compose.yml"
  if [[ ! -f "$docker_compose_file" ]]; then
    log_error "Module has no docker-compose.yml file: $module_name"
    return $ERR_NOT_IMPLEMENTED
  fi
  
  # Get logs
  if [[ -n "$service_name" ]]; then
    docker-compose -f "$docker_compose_file" logs --tail="$lines" "$service_name"
  else
    docker-compose -f "$docker_compose_file" logs --tail="$lines"
  fi
  
  return $ERR_SUCCESS
}

# Get module health
# 
# Parameters:
#   $1 - Module name
#   $2 - Service name (optional)
#
# Returns:
#   Module health status (JSON)
function get_module_health() {
  local module_name=$1
  local service_name=$2
  
  # Check if module exists
  if ! module_exists "$module_name"; then
    log_error "Module does not exist: $module_name"
    return $ERR_NOT_FOUND
  fi
  
  # Check if module has a docker-compose.yml file
  local docker_compose_file="$MODULES_DIR/$module_name/docker-compose.yml"
  if [[ ! -f "$docker_compose_file" ]]; then
    log_error "Module has no docker-compose.yml file: $module_name"
    return $ERR_NOT_IMPLEMENTED
  fi
  
  # Get the list of services
  local services
  if [[ -n "$service_name" ]]; then
    services=("$service_name")
  else
    services=($(docker-compose -f "$docker_compose_file" ps --services))
  fi
  
  # Check health status for each service
  echo "{"
  echo "  \"module\": \"$module_name\","
  echo "  \"status\": \"$(get_module_status_text "$module_name")\","
  echo "  \"services\": ["
  
  local first=true
  for service in "${services[@]}"; do
    # Skip if service doesn't exist
    if ! docker-compose -f "$docker_compose_file" ps --services | grep -q "^$service$"; then
      continue
    fi
    
    # Get container ID
    local container_id=$(docker-compose -f "$docker_compose_file" ps -q "$service")
    
    # Skip if container doesn't exist
    if [[ -z "$container_id" ]]; then
      continue
    fi
    
    # Get health status
    local health=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$container_id" 2>/dev/null)
    
    # Add comma for all but the first service
    if [[ "$first" == "true" ]]; then
      first=false
    else
      echo ","
    fi
    
    # Output service health
    echo "    {"
    echo "      \"name\": \"$service\","
    echo "      \"health\": \"$health\","
    echo "      \"container_id\": \"$container_id\""
    echo -n "    }"
  done
  
  echo ""
  echo "  ]"
  echo "}"
  
  return $ERR_SUCCESS
}

# Get module configuration
# 
# Parameters:
#   $1 - Module name
#   $2 - Configuration key (optional)
#
# Returns:
#   Module configuration
function get_module_config() {
  local module_name=$1
  local config_key=$2
  
  # Check if module exists
  if ! module_exists "$module_name"; then
    log_error "Module does not exist: $module_name"
    return $ERR_NOT_FOUND
  fi
  
  # Check if module has a configuration file
  local config_file="$CONFIG_DIR/$module_name/env.conf"
  if [[ ! -f "$config_file" ]]; then
    log_error "Module has no configuration file: $module_name"
    return $ERR_NOT_FOUND
  fi
  
  # Get configuration
  if [[ -n "$config_key" ]]; then
    grep -E "^$config_key=" "$config_file" | cut -d'=' -f2-
  else
    cat "$config_file" | grep -v "^#" | grep "="
  fi
  
  return $ERR_SUCCESS
}

# Set module configuration
# 
# Parameters:
#   $1 - Module name
#   $2 - Configuration key
#   $3 - Configuration value
#
# Returns:
#   0 - Success
#   Non-zero - Error code
function set_module_config() {
  local module_name=$1
  local config_key=$2
  local config_value=$3
  
  # Check if module exists
  if ! module_exists "$module_name"; then
    log_error "Module does not exist: $module_name"
    return $ERR_NOT_FOUND
  fi
  
  # Check if configuration key is provided
  if [[ -z "$config_key" ]]; then
    log_error "Configuration key is required"
    return $ERR_INVALID_ARGUMENT
  fi
  
  # Ensure module configuration directory exists
  local config_dir="$CONFIG_DIR/$module_name"
  if [[ ! -d "$config_dir" ]]; then
    mkdir -p "$config_dir"
  fi
  
  # Check if module has a configuration file
  local config_file="$config_dir/env.conf"
  if [[ ! -f "$config_file" ]]; then
    # Create configuration file if it doesn't exist
    touch "$config_file"
  fi
  
  # Update configuration
  if grep -q "^$config_key=" "$config_file"; then
    # Update existing key
    sed -i "s|^$config_key=.*|$config_key=$config_value|" "$config_file"
  else
    # Add new key
    echo "$config_key=$config_value" >> "$config_file"
  fi
  
  log_info "Updated module configuration: $module_name.$config_key=$config_value"
  return $ERR_SUCCESS
}

# Initialize a new module
# 
# Parameters:
#   $1 - Module name
#
# Returns:
#   0 - Success
#   Non-zero - Error code
function initialize_module() {
  local module_name=$1
  
  # Check if module name is provided
  if [[ -z "$module_name" ]]; then
    log_error "Module name is required"
    return $ERR_INVALID_ARGUMENT
  fi
  
  # Check if module already exists
  if module_exists "$module_name"; then
    log_error "Module already exists: $module_name"
    return $ERR_ALREADY_EXISTS
  fi
  
  log_info "Initializing new module: $module_name"
  
  # Create module directory
  local module_dir="$MODULES_DIR/$module_name"
  mkdir -p "$module_dir"
  
  # Copy template files
  cp -r "$MODULES_DIR/template/"* "$module_dir/"
  
  # Update module name in files
  find "$module_dir" -type f -exec sed -i "s/template/$module_name/g" {} \;
  
  # Create module data directory
  mkdir -p "$DATA_DIR/$module_name"
  
  # Create module configuration directory
  mkdir -p "$CONFIG_DIR/$module_name"
  
  # Copy default configuration
  cp "$module_dir/config/env.conf" "$CONFIG_DIR/$module_name/env.conf"
  
  # Make scripts executable
  find "$module_dir/scripts" -type f -name "*.sh" -exec chmod +x {} \;
  
  log_success "Module initialized successfully: $module_name"
  return $ERR_SUCCESS
}

# Log initialization of the module integration library
log_debug "Module integration library initialized"