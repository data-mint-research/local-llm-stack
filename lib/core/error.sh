#!/bin/bash
# error.sh - Standardized error handling for LOCAL-LLM-Stack
# This module provides consistent error handling functions and error codes

# Guard against multiple inclusion
if [[ -n "$_ERROR_SH_INCLUDED" ]]; then
  return 0
fi
_ERROR_SH_INCLUDED=1

# Use a different variable name for the script directory
ERROR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ERROR_DIR/logging.sh"

# Error codes
readonly ERR_SUCCESS=0
readonly ERR_GENERAL=1
readonly ERR_INVALID_ARGUMENT=2
readonly ERR_FILE_NOT_FOUND=3
readonly ERR_PERMISSION_DENIED=4
readonly ERR_COMMAND_NOT_FOUND=5
readonly ERR_DOCKER_ERROR=10
readonly ERR_NETWORK_ERROR=11
readonly ERR_CONFIG_ERROR=20
readonly ERR_SECRET_ERROR=21
readonly ERR_MODULE_ERROR=30
readonly ERR_COMPONENT_ERROR=31
readonly ERR_VALIDATION_ERROR=40
readonly ERR_DEPENDENCY_ERROR=50

# Error messages
declare -A ERROR_MESSAGES=(
  [$ERR_SUCCESS]="Operation completed successfully"
  [$ERR_GENERAL]="An error occurred"
  [$ERR_INVALID_ARGUMENT]="Invalid argument provided"
  [$ERR_FILE_NOT_FOUND]="File not found"
  [$ERR_PERMISSION_DENIED]="Permission denied"
  [$ERR_COMMAND_NOT_FOUND]="Command not found"
  [$ERR_DOCKER_ERROR]="Docker operation failed"
  [$ERR_NETWORK_ERROR]="Network operation failed"
  [$ERR_CONFIG_ERROR]="Configuration error"
  [$ERR_SECRET_ERROR]="Secret management error"
  [$ERR_MODULE_ERROR]="Module operation failed"
  [$ERR_COMPONENT_ERROR]="Component operation failed"
  [$ERR_VALIDATION_ERROR]="Validation failed"
  [$ERR_DEPENDENCY_ERROR]="Dependency check failed"
)

# Track whether an error has occurred
ERROR_OCCURRED=false

# Main error handling function
handle_error() {
  local exit_code=${1:-$ERR_GENERAL}
  local error_message=${2:-${ERROR_MESSAGES[$exit_code]}}
  local exit_on_error=${3:-true}
  
  ERROR_OCCURRED=true
  
  # Log the error
  log_error "$error_message"
  
  # Provide helpful suggestions based on error context
  case "$exit_code" in
    $ERR_DOCKER_ERROR)
      log_info "Tip: Make sure Docker is running with 'docker ps'"
      ;;
    $ERR_PERMISSION_DENIED)
      log_info "Tip: You may need to run with sudo or fix permissions"
      ;;
    $ERR_FILE_NOT_FOUND)
      log_info "Tip: Check if the path is correct"
      ;;
    $ERR_COMMAND_NOT_FOUND)
      log_info "Tip: Make sure all required dependencies are installed"
      ;;
    $ERR_CONFIG_ERROR)
      log_info "Tip: Check your configuration file for errors"
      ;;
    $ERR_NETWORK_ERROR)
      log_info "Tip: Check your network connection and firewall settings"
      ;;
  esac
  
  # Exit if requested
  if [[ "$exit_on_error" == "true" ]]; then
    exit $exit_code
  fi
  
  return $exit_code
}

# Function to check if an error has occurred
has_error() {
  [[ "$ERROR_OCCURRED" == "true" ]]
}

# Function to reset error state
reset_error() {
  ERROR_OCCURRED=false
}

# Function to assert a condition and handle error if it fails
assert() {
  local condition=$1
  local error_code=${2:-$ERR_GENERAL}
  local error_message=${3:-${ERROR_MESSAGES[$error_code]}}
  local exit_on_error=${4:-true}
  
  if ! eval "$condition"; then
    handle_error "$error_code" "$error_message" "$exit_on_error"
    return $error_code
  fi
  
  return $ERR_SUCCESS
}

# Function to handle errors with cleanup
handle_error_with_cleanup() {
  local exit_code=$1
  local error_message=$2
  local cleanup_function=$3
  
  # Call the cleanup function if provided
  if [[ -n "$cleanup_function" ]]; then
    log_debug "Running cleanup function: $cleanup_function"
    $cleanup_function
  fi
  
  # Handle the error
  handle_error "$exit_code" "$error_message"
}

# Function to set a trap for script cleanup
set_cleanup_trap() {
  local cleanup_function=$1
  
  # Set trap for common signals
  trap "$cleanup_function; exit $ERR_GENERAL" SIGHUP SIGINT SIGTERM
  
  # Set trap for EXIT to ensure cleanup happens
  trap "$cleanup_function" EXIT
  
  log_debug "Cleanup trap set for function: $cleanup_function"
}

# Export error codes for use in other scripts
export ERR_SUCCESS
export ERR_GENERAL
export ERR_INVALID_ARGUMENT
export ERR_FILE_NOT_FOUND
export ERR_PERMISSION_DENIED
export ERR_COMMAND_NOT_FOUND
export ERR_DOCKER_ERROR
export ERR_NETWORK_ERROR
export ERR_CONFIG_ERROR
export ERR_SECRET_ERROR
export ERR_MODULE_ERROR
export ERR_COMPONENT_ERROR
export ERR_VALIDATION_ERROR
export ERR_DEPENDENCY_ERROR

log_debug "Error handling module initialized"