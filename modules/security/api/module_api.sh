#!/bin/bash
# modules/security/api/module_api.sh
# Standardized API interface for modules

# Guard against multiple inclusion
if [[ -n "$_MODULE_API_SH_INCLUDED" ]]; then
  return 0
fi
_MODULE_API_SH_INCLUDED=1

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

# Module API version
MODULE_API_VERSION="1.0.0"

# Module status constants
readonly MODULE_STATUS_UNKNOWN=0
readonly MODULE_STATUS_STOPPED=1
readonly MODULE_STATUS_STARTING=2
readonly MODULE_STATUS_RUNNING=3
readonly MODULE_STATUS_STOPPING=4
readonly MODULE_STATUS_ERROR=5

# Module API documentation
function module_api_help() {
  cat << EOF
Module API for $MODULE_NAME (v$MODULE_API_VERSION)

This API provides a standardized interface for interacting with the $MODULE_NAME module.

Available functions:

module_start()
  Starts the module services.
  
  Parameters:
    None
    
  Returns:
    0 - Success
    Non-zero - Error code

module_stop()
  Stops the module services.
  
  Parameters:
    None
    
  Returns:
    0 - Success
    Non-zero - Error code

module_restart()
  Restarts the module services.
  
  Parameters:
    None
    
  Returns:
    0 - Success
    Non-zero - Error code

module_status()
  Gets the current status of the module.
  
  Parameters:
    None
    
  Returns:
    Status code (0-5)
    0 - Unknown
    1 - Stopped
    2 - Starting
    3 - Running
    4 - Stopping
    5 - Error

module_get_status_text()
  Gets the current status of the module as text.
  
  Parameters:
    None
    
  Returns:
    Status text (string)

module_get_config()
  Gets the current configuration of the module.
  
  Parameters:
    $1 - Configuration key (optional)
    
  Returns:
    Configuration value(s)

module_set_config()
  Sets a configuration value for the module.
  
  Parameters:
    $1 - Configuration key
    $2 - Configuration value
    
  Returns:
    0 - Success
    Non-zero - Error code

module_get_logs()
  Gets the logs for the module services.
  
  Parameters:
    $1 - Service name (optional)
    $2 - Number of lines (optional, default: 100)
    
  Returns:
    Log output

module_get_health()
  Gets the health status of the module services.
  
  Parameters:
    $1 - Service name (optional)
    
  Returns:
    Health status (JSON)

module_get_version()
  Gets the version of the module.
  
  Parameters:
    None
    
  Returns:
    Module version (string)

module_get_api_version()
  Gets the version of the module API.
  
  Parameters:
    None
    
  Returns:
    API version (string)
EOF
}

# Start the module services
function module_start() {
  log_info "Starting $MODULE_NAME module..."
  
  # Check if module is already running
  if [[ $(module_status) -eq $MODULE_STATUS_RUNNING ]]; then
    log_warning "$MODULE_NAME module is already running."
    return $ERR_SUCCESS
  fi
  
  # Start the module services using Docker Compose
  docker-compose -f "$MODULE_DIR/docker-compose.yml" up -d
  local result=$?
  
  if [[ $result -ne 0 ]]; then
    log_error "Failed to start $MODULE_NAME module."
    return $ERR_GENERAL
  fi
  
  log_success "$MODULE_NAME module started successfully."
  return $ERR_SUCCESS
}

# Stop the module services
function module_stop() {
  log_info "Stopping $MODULE_NAME module..."
  
  # Check if module is already stopped
  if [[ $(module_status) -eq $MODULE_STATUS_STOPPED ]]; then
    log_warning "$MODULE_NAME module is already stopped."
    return $ERR_SUCCESS
  fi
  
  # Stop the module services using Docker Compose
  docker-compose -f "$MODULE_DIR/docker-compose.yml" down
  local result=$?
  
  if [[ $result -ne 0 ]]; then
    log_error "Failed to stop $MODULE_NAME module."
    return $ERR_GENERAL
  fi
  
  log_success "$MODULE_NAME module stopped successfully."
  return $ERR_SUCCESS
}

# Restart the module services
function module_restart() {
  log_info "Restarting $MODULE_NAME module..."
  
  # Stop the module
  module_stop
  if [[ $? -ne 0 ]]; then
    log_error "Failed to stop $MODULE_NAME module during restart."
    return $ERR_GENERAL
  fi
  
  # Start the module
  module_start
  if [[ $? -ne 0 ]]; then
    log_error "Failed to start $MODULE_NAME module during restart."
    return $ERR_GENERAL
  fi
  
  log_success "$MODULE_NAME module restarted successfully."
  return $ERR_SUCCESS
}

# Get the current status of the module
function module_status() {
  # Check if Docker is running
  if ! command -v docker &> /dev/null || ! docker info &> /dev/null; then
    return $MODULE_STATUS_UNKNOWN
  fi
  
  # Get the number of running containers for this module
  local running_containers=$(docker-compose -f "$MODULE_DIR/docker-compose.yml" ps --services --filter "status=running" | wc -l)
  local total_containers=$(docker-compose -f "$MODULE_DIR/docker-compose.yml" ps --services | wc -l)
  
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

# Get the current status of the module as text
function module_get_status_text() {
  local status=$(module_status)
  
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

# Get the current configuration of the module
function module_get_config() {
  local config_key=$1
  local config_file="$ROOT_DIR/config/$MODULE_NAME/env.conf"
  
  # Check if config file exists
  if [[ ! -f "$config_file" ]]; then
    log_error "Configuration file not found: $config_file"
    return $ERR_FILE_NOT_FOUND
  fi
  
  # If a specific key is requested, return its value
  if [[ -n "$config_key" ]]; then
    grep -E "^$config_key=" "$config_file" | cut -d'=' -f2-
  else
    # Otherwise, return all configuration values
    cat "$config_file" | grep -v "^#" | grep "="
  fi
  
  return $ERR_SUCCESS
}

# Set a configuration value for the module
function module_set_config() {
  local config_key=$1
  local config_value=$2
  local config_file="$ROOT_DIR/config/$MODULE_NAME/env.conf"
  
  # Validate input
  if [[ -z "$config_key" ]]; then
    log_error "Configuration key is required."
    return $ERR_INVALID_ARGUMENT
  fi
  
  # Check if config file exists
  if [[ ! -f "$config_file" ]]; then
    log_error "Configuration file not found: $config_file"
    return $ERR_FILE_NOT_FOUND
  fi
  
  # Check if the key exists in the config file
  if grep -q "^$config_key=" "$config_file"; then
    # Update existing key
    sed -i "s|^$config_key=.*|$config_key=$config_value|" "$config_file"
  else
    # Add new key
    echo "$config_key=$config_value" >> "$config_file"
  fi
  
  log_info "Updated configuration: $config_key=$config_value"
  return $ERR_SUCCESS
}

# Get the logs for the module services
function module_get_logs() {
  local service_name=$1
  local lines=${2:-100}
  
  # Validate input
  if [[ -n "$service_name" ]]; then
    # Get logs for a specific service
    docker-compose -f "$MODULE_DIR/docker-compose.yml" logs --tail="$lines" "$service_name"
  else
    # Get logs for all services
    docker-compose -f "$MODULE_DIR/docker-compose.yml" logs --tail="$lines"
  fi
  
  return $ERR_SUCCESS
}

# Get the health status of the module services
function module_get_health() {
  local service_name=$1
  local health_status=()
  
  # Get the list of services
  local services
  if [[ -n "$service_name" ]]; then
    services=("$service_name")
  else
    services=($(docker-compose -f "$MODULE_DIR/docker-compose.yml" ps --services))
  fi
  
  # Check health status for each service
  echo "{"
  echo "  \"module\": \"$MODULE_NAME\","
  echo "  \"status\": \"$(module_get_status_text)\","
  echo "  \"services\": ["
  
  local first=true
  for service in "${services[@]}"; do
    # Skip if service doesn't exist
    if ! docker-compose -f "$MODULE_DIR/docker-compose.yml" ps --services | grep -q "^$service$"; then
      continue
    fi
    
    # Get container ID
    local container_id=$(docker-compose -f "$MODULE_DIR/docker-compose.yml" ps -q "$service")
    
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

# Get the version of the module
function module_get_version() {
  # Try to get version from a version file
  local version_file="$MODULE_DIR/VERSION"
  if [[ -f "$version_file" ]]; then
    cat "$version_file"
    return $ERR_SUCCESS
  fi
  
  # If no version file, try to get from docker-compose.yml
  local version=$(grep -E "version:" "$MODULE_DIR/docker-compose.yml" | head -n 1 | cut -d'"' -f2)
  if [[ -n "$version" ]]; then
    echo "$version"
    return $ERR_SUCCESS
  fi
  
  # Default version if not found
  echo "1.0.0"
  return $ERR_SUCCESS
}

# Get the version of the module API
function module_get_api_version() {
  echo "$MODULE_API_VERSION"
  return $ERR_SUCCESS
}

# Log module API initialization
log_debug "$MODULE_NAME module API initialized (v$MODULE_API_VERSION)"