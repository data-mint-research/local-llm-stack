#!/bin/bash
# service_script_template.sh - Template for service management scripts
# This template follows the LOCAL-LLM-Stack shell script style guide

# Source core library modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../core/logging.sh"
source "$SCRIPT_DIR/../core/error.sh"
source "$SCRIPT_DIR/../core/system.sh"
source "$SCRIPT_DIR/../core/docker.sh"
source "$SCRIPT_DIR/../core/config.sh"

# Script constants
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_VERSION="1.0.0"
readonly SERVICE_NAME="example-service"
readonly SERVICE_COMPOSE_FILE="core/$SERVICE_NAME.yml"
readonly SERVICE_PROJECT="local-llm-stack-$SERVICE_NAME"

# Display usage information
function show_usage() {
  echo "Usage: $SCRIPT_NAME [command] [options]"
  echo ""
  echo "Template service management script for LOCAL-LLM-Stack"
  echo ""
  echo "Commands:"
  echo "  start       Start the service"
  echo "  stop        Stop the service"
  echo "  restart     Restart the service"
  echo "  status      Show service status"
  echo "  logs        Show service logs"
  echo "  help        Show this help message"
  echo ""
  echo "Options:"
  echo "  -h, --help     Show this help message and exit"
  echo "  -v, --verbose  Enable verbose output"
  echo "  -q, --quiet    Suppress all output except errors"
  echo ""
  echo "Examples:"
  echo "  $SCRIPT_NAME start"
  echo "  $SCRIPT_NAME stop"
  echo "  $SCRIPT_NAME status"
  echo "  $SCRIPT_NAME logs"
}

# Parse command line arguments
function parse_arguments() {
  local command=""
  local args=()
  
  # First argument is the command
  if [[ $# -gt 0 ]]; then
    command="$1"
    shift
  fi
  
  # Parse remaining options
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        show_usage
        exit 0
        ;;
      -v|--verbose)
        set_log_level "debug"
        shift
        ;;
      -q|--quiet)
        set_log_level "error"
        shift
        ;;
      -*)
        log_error "Unknown option: $1"
        show_usage
        exit $ERR_INVALID_ARGUMENT
        ;;
      *)
        args+=("$1")
        shift
        ;;
    esac
  done
  
  # Return the command and arguments
  echo "$command ${args[@]}"
}

# Start the service
function start_service() {
  log_info "Starting $SERVICE_NAME service..."
  
  # Check if Docker is running
  check_docker
  if [[ $? -ne 0 ]]; then
    handle_error $ERR_DOCKER_ERROR "Docker is not running"
  fi
  
  # Check if the service is already running
  if container_is_running "$SERVICE_NAME"; then
    log_info "$SERVICE_NAME is already running"
    return $ERR_SUCCESS
  fi
  
  # Start the service using Docker Compose
  docker_compose_op "up" "$SERVICE_PROJECT" "-f $SERVICE_COMPOSE_FILE" ""
  if [[ $? -ne 0 ]]; then
    handle_error $ERR_DOCKER_ERROR "Failed to start $SERVICE_NAME service"
  fi
  
  log_success "$SERVICE_NAME service started successfully"
  return $ERR_SUCCESS
}

# Stop the service
function stop_service() {
  log_info "Stopping $SERVICE_NAME service..."
  
  # Check if Docker is running
  check_docker
  if [[ $? -ne 0 ]]; then
    handle_error $ERR_DOCKER_ERROR "Docker is not running"
  fi
  
  # Check if the service is running
  if ! container_is_running "$SERVICE_NAME"; then
    log_info "$SERVICE_NAME is not running"
    return $ERR_SUCCESS
  fi
  
  # Stop the service using Docker Compose
  docker_compose_op "down" "$SERVICE_PROJECT" "-f $SERVICE_COMPOSE_FILE" ""
  if [[ $? -ne 0 ]]; then
    handle_error $ERR_DOCKER_ERROR "Failed to stop $SERVICE_NAME service"
  fi
  
  log_success "$SERVICE_NAME service stopped successfully"
  return $ERR_SUCCESS
}

# Restart the service
function restart_service() {
  log_info "Restarting $SERVICE_NAME service..."
  
  # Stop the service
  stop_service
  if [[ $? -ne 0 ]]; then
    return $ERR_DOCKER_ERROR
  fi
  
  # Start the service
  start_service
  if [[ $? -ne 0 ]]; then
    return $ERR_DOCKER_ERROR
  fi
  
  log_success "$SERVICE_NAME service restarted successfully"
  return $ERR_SUCCESS
}

# Show service status
function show_service_status() {
  log_info "Checking $SERVICE_NAME service status..."
  
  # Check if Docker is running
  check_docker
  if [[ $? -ne 0 ]]; then
    handle_error $ERR_DOCKER_ERROR "Docker is not running"
  fi
  
  # Get container status
  get_container_status "$SERVICE_NAME"
  
  return $ERR_SUCCESS
}

# Show service logs
function show_service_logs() {
  local tail=${1:-"100"}
  
  log_info "Showing $SERVICE_NAME service logs (last $tail lines)..."
  
  # Check if Docker is running
  check_docker
  if [[ $? -ne 0 ]]; then
    handle_error $ERR_DOCKER_ERROR "Docker is not running"
  fi
  
  # Check if the service is running
  if ! container_is_running "$SERVICE_NAME"; then
    log_warn "$SERVICE_NAME is not running"
    return $ERR_SUCCESS
  fi
  
  # Show logs
  docker_logs "$SERVICE_NAME" "$tail"
  
  return $ERR_SUCCESS
}

# Cleanup function to run on exit
function cleanup() {
  log_debug "Performing cleanup operations"
  # Add your cleanup operations here
}

# Main function
function main() {
  log_info "Starting $SCRIPT_NAME v$SCRIPT_VERSION"
  
  # Set up cleanup trap
  set_cleanup_trap cleanup
  
  # Parse command line arguments
  local parsed_args
  parsed_args=($(parse_arguments "$@"))
  local command="${parsed_args[0]}"
  
  # Execute the appropriate command
  case "$command" in
    start)
      start_service
      ;;
    stop)
      stop_service
      ;;
    restart)
      restart_service
      ;;
    status)
      show_service_status
      ;;
    logs)
      show_service_logs "${parsed_args[1]}"
      ;;
    help|"")
      show_usage
      ;;
    *)
      log_error "Unknown command: $command"
      show_usage
      exit $ERR_INVALID_ARGUMENT
      ;;
  esac
  
  return $ERR_SUCCESS
}

# Execute main function if script is run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
  exit $?
fi