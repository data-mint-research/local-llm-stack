#!/bin/bash
# tools/template/main.sh
# Main script template for tools

# Get the absolute path of the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source core libraries
source "$ROOT_DIR/lib/core/logging.sh"
source "$ROOT_DIR/lib/core/error.sh"
source "$ROOT_DIR/lib/core/validation.sh"
source "$ROOT_DIR/lib/core/config.sh"

# Source tool-specific libraries
source "$SCRIPT_DIR/lib/common.sh"

# Tool name (derived from directory name)
TOOL_NAME=$(basename "$SCRIPT_DIR")

# Tool version
TOOL_VERSION="1.0.0"

# Default configuration file
CONFIG_FILE="$SCRIPT_DIR/config/config.yaml"

# Display tool usage information
function display_usage() {
  cat << EOF
Usage: $0 [OPTIONS] COMMAND

A template tool for the LOCAL-LLM-Stack.

Options:
  -h, --help              Display this help message and exit
  -v, --version           Display version information and exit
  -c, --config FILE       Use a specific configuration file
  -d, --debug             Enable debug output
  -q, --quiet             Suppress all output except errors

Commands:
  run                     Run the tool with default settings
  validate                Validate the tool configuration
  status                  Display the tool status

Examples:
  $0 run                  Run the tool with default settings
  $0 --config custom.yaml run  Run the tool with a custom configuration
  $0 --debug validate     Validate the configuration with debug output

EOF
}

# Display version information
function display_version() {
  echo "$TOOL_NAME v$TOOL_VERSION"
}

# Parse command line arguments
function parse_arguments() {
  # Default values
  local command=""
  local debug=false
  local quiet=false
  
  # Parse options
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        display_usage
        exit 0
        ;;
      -v|--version)
        display_version
        exit 0
        ;;
      -c|--config)
        if [[ -z "$2" || "$2" == -* ]]; then
          log_error "Option --config requires an argument."
          display_usage
          exit $ERR_INVALID_ARGUMENT
        fi
        CONFIG_FILE="$2"
        shift 2
        ;;
      -d|--debug)
        debug=true
        shift
        ;;
      -q|--quiet)
        quiet=true
        shift
        ;;
      -*)
        log_error "Unknown option: $1"
        display_usage
        exit $ERR_INVALID_ARGUMENT
        ;;
      *)
        if [[ -z "$command" ]]; then
          command="$1"
        else
          log_error "Too many arguments: $1"
          display_usage
          exit $ERR_INVALID_ARGUMENT
        fi
        shift
        ;;
    esac
  done
  
  # Set logging level based on options
  if [[ "$debug" == "true" ]]; then
    set_log_level $LOG_LEVEL_DEBUG
  elif [[ "$quiet" == "true" ]]; then
    set_log_level $LOG_LEVEL_ERROR
  fi
  
  # Validate command
  if [[ -z "$command" ]]; then
    log_error "No command specified."
    display_usage
    exit $ERR_INVALID_ARGUMENT
  fi
  
  # Return the command
  echo "$command"
}

# Validate the tool configuration
function validate_configuration() {
  log_info "Validating configuration file: $CONFIG_FILE"
  
  # Check if configuration file exists
  if [[ ! -f "$CONFIG_FILE" ]]; then
    log_error "Configuration file not found: $CONFIG_FILE"
    return $ERR_FILE_NOT_FOUND
  fi
  
  # Check if configuration file is readable
  if [[ ! -r "$CONFIG_FILE" ]]; then
    log_error "Configuration file is not readable: $CONFIG_FILE"
    return $ERR_PERMISSION_DENIED
  }
  
  # Validate configuration file format (assuming YAML)
  if command -v yq &> /dev/null; then
    yq eval '.' "$CONFIG_FILE" > /dev/null
    if [[ $? -ne 0 ]]; then
      log_error "Invalid YAML format in configuration file: $CONFIG_FILE"
      return $ERR_INVALID_FORMAT
    fi
  else
    log_warning "yq not found, skipping YAML validation."
  fi
  
  # Validate required configuration values
  # Example: Check if a required value exists
  # if ! grep -q "required_value:" "$CONFIG_FILE"; then
  #   log_error "Required configuration value 'required_value' not found in $CONFIG_FILE"
  #   return $ERR_INVALID_CONFIG
  # fi
  
  log_success "Configuration validation successful."
  return $ERR_SUCCESS
}

# Run the tool
function run_tool() {
  log_info "Running $TOOL_NAME v$TOOL_VERSION..."
  
  # Validate configuration
  validate_configuration
  if [[ $? -ne 0 ]]; then
    log_error "Configuration validation failed."
    return $ERR_INVALID_CONFIG
  fi
  
  # Example: Load configuration values
  # local config_value=$(grep "config_value:" "$CONFIG_FILE" | cut -d':' -f2- | tr -d ' ')
  
  # Example: Perform tool operation
  log_info "Performing tool operation..."
  
  # Example: Process files
  # find "$ROOT_DIR" -type f -name "*.sh" | while read -r file; do
  #   log_debug "Processing file: $file"
  #   # Process the file
  # done
  
  log_success "$TOOL_NAME completed successfully."
  return $ERR_SUCCESS
}

# Display tool status
function display_status() {
  log_info "Checking $TOOL_NAME status..."
  
  # Example: Check if configuration file exists
  if [[ ! -f "$CONFIG_FILE" ]]; then
    log_warning "Configuration file not found: $CONFIG_FILE"
  else
    log_info "Configuration file: $CONFIG_FILE"
  fi
  
  # Example: Check if dependencies are installed
  if command -v yq &> /dev/null; then
    log_info "yq: Installed"
  else
    log_warning "yq: Not installed"
  fi
  
  # Example: Check if tool is properly configured
  validate_configuration > /dev/null
  if [[ $? -eq 0 ]]; then
    log_info "Configuration: Valid"
  else
    log_warning "Configuration: Invalid"
  fi
  
  return $ERR_SUCCESS
}

# Main function
function main() {
  # Parse command line arguments
  local command=$(parse_arguments "$@")
  
  # Execute the requested command
  case "$command" in
    run)
      run_tool
      ;;
    validate)
      validate_configuration
      ;;
    status)
      display_status
      ;;
    *)
      log_error "Unknown command: $command"
      display_usage
      exit $ERR_INVALID_ARGUMENT
      ;;
  esac
  
  # Return the result of the command
  return $?
}

# Execute main function with all arguments
main "$@"
exit $?