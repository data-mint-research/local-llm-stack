#!/bin/bash
# utility_script_template.sh - Template for utility scripts
# This template follows the LOCAL-LLM-Stack shell script style guide

# Source core library modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../core/logging.sh"
source "$SCRIPT_DIR/../core/error.sh"
source "$SCRIPT_DIR/../core/system.sh"
source "$SCRIPT_DIR/../core/validation.sh"

# Script constants
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_VERSION="1.0.0"

# Display usage information
function show_usage() {
  echo "Usage: $SCRIPT_NAME [options] <arguments>"
  echo ""
  echo "Template utility script for LOCAL-LLM-Stack"
  echo ""
  echo "Options:"
  echo "  -h, --help     Show this help message and exit"
  echo "  -v, --verbose  Enable verbose output"
  echo "  -q, --quiet    Suppress all output except errors"
  echo ""
  echo "Examples:"
  echo "  $SCRIPT_NAME --help"
  echo "  $SCRIPT_NAME --verbose argument1 argument2"
}

# Parse command line arguments
function parse_arguments() {
  local args=()
  
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
  
  # Return the remaining arguments
  echo "${args[@]}"
}

# Example utility function
# 
# Parameters:
#   $1 - Input string to process
#   $2 - Option flag (optional)
#
# Returns:
#   0 - Success
#   1 - Failure
function process_input() {
  local input=$1
  local option=${2:-"default"}
  
  log_debug "Processing input: $input with option: $option"
  
  # Validate input
  validate_not_empty "$input" "Input"
  if [[ $? -ne 0 ]]; then
    return $ERR_VALIDATION_ERROR
  fi
  
  # Process the input
  # Replace this with your actual processing logic
  log_info "Processing $input..."
  
  # Example success case
  log_success "Successfully processed $input"
  return $ERR_SUCCESS
}

# Cleanup function to run on exit
function cleanup() {
  log_debug "Performing cleanup operations"
  # Add your cleanup operations here
  # For example: remove temporary files, close connections, etc.
}

# Main function
function main() {
  log_info "Starting $SCRIPT_NAME v$SCRIPT_VERSION"
  
  # Set up cleanup trap
  set_cleanup_trap cleanup
  
  # Parse command line arguments
  local args
  args=($(parse_arguments "$@"))
  
  # Check if we have the required arguments
  if [[ ${#args[@]} -lt 1 ]]; then
    log_error "Missing required arguments"
    show_usage
    exit $ERR_INVALID_ARGUMENT
  fi
  
  # Process each input argument
  for arg in "${args[@]}"; do
    process_input "$arg"
    if [[ $? -ne 0 ]]; then
      log_error "Failed to process input: $arg"
      exit $ERR_GENERAL
    fi
  done
  
  log_success "$SCRIPT_NAME completed successfully"
  return $ERR_SUCCESS
}

# Execute main function if script is run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
  exit $?
fi