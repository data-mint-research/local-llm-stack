#!/bin/bash
# tools/relationship-mapping/lib/common.sh
# Common functions for the tool relationship-mapping

# Guard against multiple inclusion
if [[ -n "$_TOOL_TEMPLATE_COMMON_SH_INCLUDED" ]]; then
  return 0
fi
_TOOL_TEMPLATE_COMMON_SH_INCLUDED=1

# Get the absolute path of the script directory
COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_DIR="$(cd "$COMMON_DIR/.." && pwd)"
ROOT_DIR="$(cd "$TOOL_DIR/../.." && pwd)"

# Source core libraries if not already sourced
if [[ -z "$_CORE_LOGGING_SH_INCLUDED" ]]; then
  source "$ROOT_DIR/lib/core/logging.sh"
fi

if [[ -z "$_CORE_ERROR_SH_INCLUDED" ]]; then
  source "$ROOT_DIR/lib/core/error.sh"
fi

# Tool constants
readonly TOOL_NAME=$(basename "$TOOL_DIR")
readonly TOOL_CONFIG_DIR="$TOOL_DIR/config"
readonly TOOL_DEFAULT_CONFIG="$TOOL_CONFIG_DIR/config.yaml"

# Read a value from the YAML configuration file
# 
# Parameters:
#   $1 - Configuration file path
#   $2 - Key to read (in dot notation, e.g., "section.key")
#
# Returns:
#   The value of the key, or empty string if not found
function read_config_value() {
  local config_file=$1
  local key=$2
  
  # Check if configuration file exists
  if [[ ! -f "$config_file" ]]; then
    log_error "Configuration file not found: $config_file"
    return $ERR_FILE_NOT_FOUND
  fi
  
  # Check if yq is available
  if command -v yq &> /dev/null; then
    # Use yq to read the value
    yq eval ".$key" "$config_file"
    return $?
  else
    # Fallback to grep/sed if yq is not available
    log_warning "yq not found, using fallback method to read configuration."
    
    # Convert dot notation to nested grep pattern
    local pattern=$(echo "$key" | sed 's/\./\.\*\n[[:space:]]*/')
    
    # Use grep and sed to extract the value
    grep -A 1 "$pattern:" "$config_file" | tail -n 1 | sed 's/^[[:space:]]*//;s/:[[:space:]]*//'
    
    # Check if the key was found
    if [[ $? -ne 0 ]]; then
      log_error "Key not found in configuration: $key"
      return $ERR_NOT_FOUND
    fi
  fi
  
  return $ERR_SUCCESS
}

# Write a value to the YAML configuration file
# 
# Parameters:
#   $1 - Configuration file path
#   $2 - Key to write (in dot notation, e.g., "section.key")
#   $3 - Value to write
#
# Returns:
#   0 - Success
#   Non-zero - Error code
function write_config_value() {
  local config_file=$1
  local key=$2
  local value=$3
  
  # Check if configuration file exists
  if [[ ! -f "$config_file" ]]; then
    log_error "Configuration file not found: $config_file"
    return $ERR_FILE_NOT_FOUND
  fi
  
  # Check if yq is available
  if command -v yq &> /dev/null; then
    # Use yq to write the value
    yq eval -i ".$key = \"$value\"" "$config_file"
    return $?
  else
    log_error "yq not found, cannot write to YAML configuration."
    return $ERR_DEPENDENCY_MISSING
  fi
  
  return $ERR_SUCCESS
}

# Process a file with the tool
# 
# Parameters:
#   $1 - File path
#   $2 - Output file path (optional)
#
# Returns:
#   0 - Success
#   Non-zero - Error code
function process_file() {
  local input_file=$1
  local output_file=$2
  
  # Check if input file exists
  if [[ ! -f "$input_file" ]]; then
    log_error "Input file not found: $input_file"
    return $ERR_FILE_NOT_FOUND
  fi
  
  # Process the file
  log_debug "Processing file: $input_file"
  
  # Example: Read the file
  local content=$(cat "$input_file")
  
  # Example: Process the content
  # local processed_content=$(echo "$content" | some_processing)
  
  # Example: Write the processed content to output file if specified
  if [[ -n "$output_file" ]]; then
    # echo "$processed_content" > "$output_file"
    log_debug "Output written to: $output_file"
  else
    # Echo the processed content to stdout
    # echo "$processed_content"
    log_debug "Output sent to stdout"
  fi
  
  return $ERR_SUCCESS
}

# Find files matching a pattern
# 
# Parameters:
#   $1 - Base directory
#   $2 - File pattern (e.g., "*.sh")
#   $3 - Exclude pattern (optional, e.g., "*/test/*")
#
# Returns:
#   List of matching files
function find_matching_files() {
  local base_dir=$1
  local file_pattern=$2
  local exclude_pattern=$3
  
  # Check if base directory exists
  if [[ ! -d "$base_dir" ]]; then
    log_error "Base directory not found: $base_dir"
    return $ERR_DIRECTORY_NOT_FOUND
  fi
  
  # Find files matching the pattern
  if [[ -n "$exclude_pattern" ]]; then
    find "$base_dir" -type f -name "$file_pattern" -not -path "$exclude_pattern"
  else
    find "$base_dir" -type f -name "$file_pattern"
  fi
  
  return $ERR_SUCCESS
}

# Create a backup of a file
# 
# Parameters:
#   $1 - File path
#
# Returns:
#   0 - Success
#   Non-zero - Error code
function backup_file() {
  local file=$1
  local backup_file="${file}.bak"
  
  # Check if file exists
  if [[ ! -f "$file" ]]; then
    log_error "File not found: $file"
    return $ERR_FILE_NOT_FOUND
  fi
  
  # Create backup
  cp "$file" "$backup_file"
  if [[ $? -ne 0 ]]; then
    log_error "Failed to create backup of file: $file"
    return $ERR_GENERAL
  fi
  
  log_debug "Created backup: $backup_file"
  return $ERR_SUCCESS
}

# Restore a file from backup
# 
# Parameters:
#   $1 - File path
#
# Returns:
#   0 - Success
#   Non-zero - Error code
function restore_file() {
  local file=$1
  local backup_file="${file}.bak"
  
  # Check if backup file exists
  if [[ ! -f "$backup_file" ]]; then
    log_error "Backup file not found: $backup_file"
    return $ERR_FILE_NOT_FOUND
  fi
  
  # Restore from backup
  cp "$backup_file" "$file"
  if [[ $? -ne 0 ]]; then
    log_error "Failed to restore file from backup: $file"
    return $ERR_GENERAL
  fi
  
  log_debug "Restored file from backup: $file"
  return $ERR_SUCCESS
}

# Log initialization of the common library
log_debug "Tool common library initialized for $TOOL_NAME"