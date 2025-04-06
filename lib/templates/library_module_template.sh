#!/bin/bash
# library_module_template.sh - Template for library modules
# This template follows the LOCAL-LLM-Stack shell script style guide

# Guard against multiple inclusion
if [[ -n "$_LIBRARY_MODULE_TEMPLATE_SH_INCLUDED" ]]; then
  return 0
fi
_LIBRARY_MODULE_TEMPLATE_SH_INCLUDED=1

# Use a different variable name for the script directory to avoid conflicts
LIBRARY_MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source dependencies
source "$LIBRARY_MODULE_DIR/../core/logging.sh"
source "$LIBRARY_MODULE_DIR/../core/error.sh"

# Module constants
readonly MODULE_NAME="library_module_template"
readonly MODULE_VERSION="1.0.0"

# Module global variables (use sparingly)
MODULE_CONFIG_PATH="${MODULE_CONFIG_PATH:-"./config"}"

# Initialize the module
function init_module() {
  log_debug "Initializing $MODULE_NAME module v$MODULE_VERSION"
  
  # Perform any initialization tasks here
  # For example: check dependencies, load configuration, etc.
  
  return $ERR_SUCCESS
}

# Example public function
# 
# Parameters:
#   $1 - Input parameter
#   $2 - Option parameter (optional)
#
# Returns:
#   0 - Success
#   1 - Failure
function module_function() {
  local input=$1
  local option=${2:-"default"}
  
  log_debug "Executing module_function with input: $input, option: $option"
  
  # Validate input
  if [[ -z "$input" ]]; then
    log_error "Input parameter is required"
    return $ERR_INVALID_ARGUMENT
  fi
  
  # Function implementation
  log_info "Processing $input with option $option"
  
  # Example success case
  log_debug "module_function completed successfully"
  return $ERR_SUCCESS
}

# Example private function (prefixed with underscore)
# This function is meant to be used only within this module
# 
# Parameters:
#   $1 - Internal parameter
#
# Returns:
#   0 - Success
#   1 - Failure
function _internal_helper() {
  local param=$1
  
  log_debug "Executing internal helper with param: $param"
  
  # Function implementation
  
  return $ERR_SUCCESS
}

# Example function that uses the internal helper
function process_data() {
  local data=$1
  
  log_debug "Processing data: $data"
  
  # Use the internal helper
  _internal_helper "$data"
  if [[ $? -ne 0 ]]; then
    log_error "Internal helper failed"
    return $ERR_GENERAL
  }
  
  # Continue processing
  
  return $ERR_SUCCESS
}

# Example function with error handling
function safe_operation() {
  local input=$1
  
  log_debug "Performing safe operation on: $input"
  
  # Check if input file exists
  if [[ ! -f "$input" ]]; then
    log_error "Input file not found: $input"
    return $ERR_FILE_NOT_FOUND
  fi
  
  # Perform operation with error handling
  local result
  result=$(cat "$input" 2>/dev/null)
  if [[ $? -ne 0 ]]; then
    log_error "Failed to read input file: $input"
    return $ERR_GENERAL
  fi
  
  # Process the result
  echo "$result"
  
  return $ERR_SUCCESS
}

# Example function with cleanup
function operation_with_cleanup() {
  local input=$1
  local temp_file="/tmp/module_temp_$$.txt"
  
  log_debug "Performing operation with cleanup on: $input"
  
  # Define cleanup function
  function _cleanup() {
    log_debug "Cleaning up temporary file: $temp_file"
    rm -f "$temp_file"
  }
  
  # Set trap for cleanup
  trap _cleanup EXIT
  
  # Perform operation
  echo "$input" > "$temp_file"
  if [[ $? -ne 0 ]]; then
    log_error "Failed to write to temporary file"
    return $ERR_GENERAL
  fi
  
  # Process the file
  local result
  result=$(cat "$temp_file" 2>/dev/null)
  
  # Return the result
  echo "$result"
  
  return $ERR_SUCCESS
}

# Initialize the module
init_module

# Log module initialization
log_debug "$MODULE_NAME module initialized"