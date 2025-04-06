#!/bin/bash
# lib/core/tool_integration.sh
# Standardized tool integration library for LOCAL-LLM-Stack

# Guard against multiple inclusion
if [[ -n "$_CORE_TOOL_INTEGRATION_SH_INCLUDED" ]]; then
  return 0
fi
_CORE_TOOL_INTEGRATION_SH_INCLUDED=1

# Get the absolute path of the script directory
TOOL_INTEGRATION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$TOOL_INTEGRATION_DIR/../.." && pwd)"

# Source dependencies
source "$TOOL_INTEGRATION_DIR/logging.sh"
source "$TOOL_INTEGRATION_DIR/error.sh"
source "$TOOL_INTEGRATION_DIR/validation.sh"
source "$TOOL_INTEGRATION_DIR/config.sh"

# Tool directories
readonly TOOLS_DIR="$ROOT_DIR/tools"
readonly CONFIG_DIR="$ROOT_DIR/config"

# Get a list of all available tools
# 
# Returns:
#   Space-separated list of tool names
function get_available_tools() {
  find "$TOOLS_DIR" -mindepth 1 -maxdepth 1 -type d -not -path "*/\.*" -not -path "*/template" | sort | xargs -n1 basename
}

# Check if a tool exists
# 
# Parameters:
#   $1 - Tool name
#
# Returns:
#   0 - Tool exists
#   1 - Tool does not exist
function tool_exists() {
  local tool_name=$1
  
  if [[ -d "$TOOLS_DIR/$tool_name" ]]; then
    return 0
  else
    return 1
  fi
}

# Run a tool with arguments
# 
# Parameters:
#   $1 - Tool name
#   $@ - Additional arguments to pass to the tool
#
# Returns:
#   Tool exit code
function run_tool() {
  local tool_name=$1
  shift
  
  # Check if tool exists
  if ! tool_exists "$tool_name"; then
    log_error "Tool does not exist: $tool_name"
    return $ERR_NOT_FOUND
  fi
  
  # Check if tool has a main script
  local main_script="$TOOLS_DIR/$tool_name/main.sh"
  if [[ ! -f "$main_script" ]]; then
    log_error "Tool has no main script: $tool_name"
    return $ERR_NOT_IMPLEMENTED
  fi
  
  # Check if main script is executable
  if [[ ! -x "$main_script" ]]; then
    log_error "Tool main script is not executable: $tool_name"
    return $ERR_PERMISSION_DENIED
  fi
  
  log_info "Running tool: $tool_name $@"
  
  # Run the tool
  "$main_script" "$@"
  local result=$?
  
  if [[ $result -ne 0 ]]; then
    log_error "Tool execution failed: $tool_name (exit code: $result)"
  else
    log_success "Tool execution completed successfully: $tool_name"
  fi
  
  return $result
}

# Get tool help
# 
# Parameters:
#   $1 - Tool name
#
# Returns:
#   Tool help text
function get_tool_help() {
  local tool_name=$1
  
  # Check if tool exists
  if ! tool_exists "$tool_name"; then
    log_error "Tool does not exist: $tool_name"
    return $ERR_NOT_FOUND
  fi
  
  # Check if tool has a main script
  local main_script="$TOOLS_DIR/$tool_name/main.sh"
  if [[ ! -f "$main_script" ]]; then
    log_error "Tool has no main script: $tool_name"
    return $ERR_NOT_IMPLEMENTED
  fi
  
  # Run the tool with --help
  "$main_script" --help
  return $?
}

# Get tool version
# 
# Parameters:
#   $1 - Tool name
#
# Returns:
#   Tool version
function get_tool_version() {
  local tool_name=$1
  
  # Check if tool exists
  if ! tool_exists "$tool_name"; then
    log_error "Tool does not exist: $tool_name"
    return $ERR_NOT_FOUND
  fi
  
  # Check if tool has a main script
  local main_script="$TOOLS_DIR/$tool_name/main.sh"
  if [[ ! -f "$main_script" ]]; then
    log_error "Tool has no main script: $tool_name"
    return $ERR_NOT_IMPLEMENTED
  fi
  
  # Run the tool with --version
  "$main_script" --version
  return $?
}

# Get tool configuration
# 
# Parameters:
#   $1 - Tool name
#   $2 - Configuration key (optional)
#
# Returns:
#   Tool configuration
function get_tool_config() {
  local tool_name=$1
  local config_key=$2
  
  # Check if tool exists
  if ! tool_exists "$tool_name"; then
    log_error "Tool does not exist: $tool_name"
    return $ERR_NOT_FOUND
  fi
  
  # Check if tool has a configuration file
  local config_file="$TOOLS_DIR/$tool_name/config/config.yaml"
  if [[ ! -f "$config_file" ]]; then
    log_error "Tool has no configuration file: $tool_name"
    return $ERR_NOT_FOUND
  fi
  
  # Check if yq is available
  if ! command -v yq &> /dev/null; then
    log_error "yq is required to read YAML configuration"
    return $ERR_DEPENDENCY_MISSING
  fi
  
  # Get configuration
  if [[ -n "$config_key" ]]; then
    yq eval ".$config_key" "$config_file"
  else
    cat "$config_file"
  fi
  
  return $ERR_SUCCESS
}

# Set tool configuration
# 
# Parameters:
#   $1 - Tool name
#   $2 - Configuration key
#   $3 - Configuration value
#
# Returns:
#   0 - Success
#   Non-zero - Error code
function set_tool_config() {
  local tool_name=$1
  local config_key=$2
  local config_value=$3
  
  # Check if tool exists
  if ! tool_exists "$tool_name"; then
    log_error "Tool does not exist: $tool_name"
    return $ERR_NOT_FOUND
  fi
  
  # Check if configuration key is provided
  if [[ -z "$config_key" ]]; then
    log_error "Configuration key is required"
    return $ERR_INVALID_ARGUMENT
  fi
  
  # Check if tool has a configuration file
  local config_file="$TOOLS_DIR/$tool_name/config/config.yaml"
  if [[ ! -f "$config_file" ]]; then
    log_error "Tool has no configuration file: $tool_name"
    return $ERR_NOT_FOUND
  fi
  
  # Check if yq is available
  if ! command -v yq &> /dev/null; then
    log_error "yq is required to modify YAML configuration"
    return $ERR_DEPENDENCY_MISSING
  fi
  
  # Update configuration
  yq eval -i ".$config_key = \"$config_value\"" "$config_file"
  local result=$?
  
  if [[ $result -ne 0 ]]; then
    log_error "Failed to update tool configuration: $tool_name.$config_key"
    return $ERR_GENERAL
  }
  
  log_info "Updated tool configuration: $tool_name.$config_key=$config_value"
  return $ERR_SUCCESS
}

# Initialize a new tool
# 
# Parameters:
#   $1 - Tool name
#
# Returns:
#   0 - Success
#   Non-zero - Error code
function initialize_tool() {
  local tool_name=$1
  
  # Check if tool name is provided
  if [[ -z "$tool_name" ]]; then
    log_error "Tool name is required"
    return $ERR_INVALID_ARGUMENT
  fi
  
  # Check if tool already exists
  if tool_exists "$tool_name"; then
    log_error "Tool already exists: $tool_name"
    return $ERR_ALREADY_EXISTS
  fi
  
  log_info "Initializing new tool: $tool_name"
  
  # Create tool directory
  local tool_dir="$TOOLS_DIR/$tool_name"
  mkdir -p "$tool_dir"
  
  # Copy template files
  cp -r "$TOOLS_DIR/template/"* "$tool_dir/"
  
  # Update tool name in files
  find "$tool_dir" -type f -exec sed -i "s/template/$tool_name/g" {} \;
  
  # Make scripts executable
  chmod +x "$tool_dir/main.sh"
  
  log_success "Tool initialized successfully: $tool_name"
  return $ERR_SUCCESS
}

# Run tool tests
# 
# Parameters:
#   $1 - Tool name
#   $2 - Test type (unit, integration, all) (default: all)
#
# Returns:
#   0 - Success
#   Non-zero - Error code
function run_tool_tests() {
  local tool_name=$1
  local test_type=${2:-all}
  
  # Check if tool exists
  if ! tool_exists "$tool_name"; then
    log_error "Tool does not exist: $tool_name"
    return $ERR_NOT_FOUND
  fi
  
  log_info "Running $test_type tests for tool: $tool_name"
  
  local test_dir="$TOOLS_DIR/$tool_name/tests"
  local exit_code=0
  
  # Run unit tests
  if [[ "$test_type" == "unit" || "$test_type" == "all" ]]; then
    if [[ -d "$test_dir/unit" ]]; then
      log_info "Running unit tests..."
      find "$test_dir/unit" -name "test_*.sh" -type f -executable | while read -r test_script; do
        log_debug "Running test script: $test_script"
        "$test_script"
        local result=$?
        if [[ $result -ne 0 ]]; then
          log_error "Unit test failed: $test_script (exit code: $result)"
          exit_code=$result
        fi
      done
    else
      log_warning "No unit tests found for tool: $tool_name"
    fi
  fi
  
  # Run integration tests
  if [[ "$test_type" == "integration" || "$test_type" == "all" ]]; then
    if [[ -d "$test_dir/integration" ]]; then
      log_info "Running integration tests..."
      find "$test_dir/integration" -name "test_*.sh" -type f -executable | while read -r test_script; do
        log_debug "Running test script: $test_script"
        "$test_script"
        local result=$?
        if [[ $result -ne 0 ]]; then
          log_error "Integration test failed: $test_script (exit code: $result)"
          exit_code=$result
        fi
      done
    else
      log_warning "No integration tests found for tool: $tool_name"
    fi
  fi
  
  if [[ $exit_code -eq 0 ]]; then
    log_success "All tests passed for tool: $tool_name"
  else
    log_error "Tests failed for tool: $tool_name"
  fi
  
  return $exit_code
}

# Get tool metadata
# 
# Parameters:
#   $1 - Tool name
#
# Returns:
#   Tool metadata in JSON format
function get_tool_metadata() {
  local tool_name=$1
  
  # Check if tool exists
  if ! tool_exists "$tool_name"; then
    log_error "Tool does not exist: $tool_name"
    return $ERR_NOT_FOUND
  fi
  
  # Check if tool has a configuration file
  local config_file="$TOOLS_DIR/$tool_name/config/config.yaml"
  if [[ ! -f "$config_file" ]]; then
    log_error "Tool has no configuration file: $tool_name"
    return $ERR_NOT_FOUND
  fi
  
  # Check if yq is available
  if ! command -v yq &> /dev/null; then
    log_error "yq is required to read YAML configuration"
    return $ERR_DEPENDENCY_MISSING
  fi
  
  # Get tool metadata
  local tool_version=$(yq eval '.tool.version' "$config_file")
  local tool_description=$(yq eval '.tool.description' "$config_file")
  local tool_author=$(yq eval '.tool.author' "$config_file")
  
  # Output metadata as JSON
  echo "{"
  echo "  \"name\": \"$tool_name\","
  echo "  \"version\": \"$tool_version\","
  echo "  \"description\": \"$tool_description\","
  echo "  \"author\": \"$tool_author\","
  echo "  \"path\": \"$TOOLS_DIR/$tool_name\""
  echo "}"
  
  return $ERR_SUCCESS
}

# Log initialization of the tool integration library
log_debug "Tool integration library initialized"