#!/bin/bash
# validation.sh - Input validation functions for LOCAL-LLM-Stack
# This module provides functions for validating user input and configuration values

# Guard against multiple inclusion
if [[ -n "$_VALIDATION_SH_INCLUDED" ]]; then
  return 0
fi
_VALIDATION_SH_INCLUDED=1

# Use a different variable name for the script directory
VALIDATION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$VALIDATION_DIR/logging.sh"
source "$VALIDATION_DIR/error.sh"

# Validate if a string is not empty
validate_not_empty() {
  local value=$1
  local name=${2:-"Value"}
  
  log_debug "Validating that $name is not empty"
  
  if [[ -z "$value" ]]; then
    log_error "$name cannot be empty"
    return $ERR_VALIDATION_ERROR
  fi
  
  return $ERR_SUCCESS
}

# Validate if a value is a number
validate_is_number() {
  local value=$1
  local name=${2:-"Value"}
  
  log_debug "Validating that $name is a number"
  
  if ! [[ "$value" =~ ^[0-9]+$ ]]; then
    log_error "$name must be a number: $value"
    return $ERR_VALIDATION_ERROR
  fi
  
  return $ERR_SUCCESS
}

# Validate if a value is a decimal number
validate_is_decimal() {
  local value=$1
  local name=${2:-"Value"}
  
  log_debug "Validating that $name is a decimal number"
  
  if ! [[ "$value" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    log_error "$name must be a decimal number: $value"
    return $ERR_VALIDATION_ERROR
  fi
  
  return $ERR_SUCCESS
}

# Validate if a value is within a range
validate_in_range() {
  local value=$1
  local min=$2
  local max=$3
  local name=${4:-"Value"}
  
  log_debug "Validating that $name is in range [$min, $max]"
  
  # First check if it's a number
  validate_is_decimal "$value" "$name"
  if [[ $? -ne 0 ]]; then
    return $ERR_VALIDATION_ERROR
  fi
  
  # Then check if it's in range
  if (( $(echo "$value < $min" | bc -l) )) || (( $(echo "$value > $max" | bc -l) )); then
    log_error "$name must be between $min and $max: $value"
    return $ERR_VALIDATION_ERROR
  fi
  
  return $ERR_SUCCESS
}

# Validate if a value is one of a set of allowed values
validate_in_set() {
  local value=$1
  local allowed=("${@:2:$#-2}")  # All arguments except first and last
  local name=${@: -1}            # Last argument
  
  log_debug "Validating that $name is one of: ${allowed[*]}"
  
  for allowed_value in "${allowed[@]}"; do
    if [[ "$value" == "$allowed_value" ]]; then
      return $ERR_SUCCESS
    fi
  done
  
  log_error "$name must be one of: ${allowed[*]}, got: $value"
  return $ERR_VALIDATION_ERROR
}

# Validate if a file exists
validate_file_exists() {
  local file=$1
  local name=${2:-"File"}
  
  log_debug "Validating that $name exists: $file"
  
  if [[ ! -f "$file" ]]; then
    log_error "$name does not exist: $file"
    return $ERR_VALIDATION_ERROR
  fi
  
  return $ERR_SUCCESS
}

# Validate if a directory exists
validate_directory_exists() {
  local dir=$1
  local name=${2:-"Directory"}
  
  log_debug "Validating that $name exists: $dir"
  
  if [[ ! -d "$dir" ]]; then
    log_error "$name does not exist: $dir"
    return $ERR_VALIDATION_ERROR
  fi
  
  return $ERR_SUCCESS
}

# Validate if a string matches a pattern
validate_pattern() {
  local value=$1
  local pattern=$2
  local name=${3:-"Value"}
  
  log_debug "Validating that $name matches pattern: $pattern"
  
  if ! [[ "$value" =~ $pattern ]]; then
    log_error "$name does not match required pattern: $value"
    return $ERR_VALIDATION_ERROR
  fi
  
  return $ERR_SUCCESS
}

# Validate if a port number is valid
validate_port() {
  local port=$1
  local name=${2:-"Port"}
  
  log_debug "Validating that $name is a valid port number: $port"
  
  # Check if it's a number
  validate_is_number "$port" "$name"
  if [[ $? -ne 0 ]]; then
    return $ERR_VALIDATION_ERROR
  fi
  
  # Check if it's in the valid port range
  if (( port < 1 )) || (( port > 65535 )); then
    log_error "$name must be between 1 and 65535: $port"
    return $ERR_VALIDATION_ERROR
  fi
  
  return $ERR_SUCCESS
}

# Validate if a port is available
validate_port_available() {
  local port=$1
  local name=${2:-"Port"}
  
  log_debug "Validating that $name is available: $port"
  
  # First validate it's a valid port
  validate_port "$port" "$name"
  if [[ $? -ne 0 ]]; then
    return $ERR_VALIDATION_ERROR
  fi
  
  # Check if the port is in use
  if command -v nc &>/dev/null; then
    if nc -z localhost "$port" &>/dev/null; then
      log_error "$name is already in use: $port"
      return $ERR_VALIDATION_ERROR
    fi
  elif command -v lsof &>/dev/null; then
    if lsof -i :"$port" &>/dev/null; then
      log_error "$name is already in use: $port"
      return $ERR_VALIDATION_ERROR
    fi
  else
    log_warn "Cannot check if $name is available: neither nc nor lsof is installed"
  fi
  
  return $ERR_SUCCESS
}

# Validate if a string is a valid URL
validate_url() {
  local url=$1
  local name=${2:-"URL"}
  
  log_debug "Validating that $name is a valid URL: $url"
  
  # Simple URL pattern
  local pattern='^(https?|ftp)://[A-Za-z0-9.-]+\.[A-Za-z]{2,}(/[A-Za-z0-9./-]*)?$'
  
  if ! [[ "$url" =~ $pattern ]]; then
    log_error "$name is not a valid URL: $url"
    return $ERR_VALIDATION_ERROR
  fi
  
  return $ERR_SUCCESS
}

# Validate if a string is a valid email address
validate_email() {
  local email=$1
  local name=${2:-"Email"}
  
  log_debug "Validating that $name is a valid email address: $email"
  
  # Simple email pattern
  local pattern='^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
  
  if ! [[ "$email" =~ $pattern ]]; then
    log_error "$name is not a valid email address: $email"
    return $ERR_VALIDATION_ERROR
  fi
  
  return $ERR_SUCCESS
}

# Validate if a string is a valid IP address
validate_ip() {
  local ip=$1
  local name=${2:-"IP address"}
  
  log_debug "Validating that $name is a valid IP address: $ip"
  
  # IPv4 pattern
  local pattern='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
  
  if ! [[ "$ip" =~ $pattern ]]; then
    log_error "$name is not a valid IP address: $ip"
    return $ERR_VALIDATION_ERROR
  fi
  
  # Check each octet
  IFS='.' read -r -a octets <<< "$ip"
  for octet in "${octets[@]}"; do
    if (( octet < 0 )) || (( octet > 255 )); then
      log_error "$name is not a valid IP address (octet out of range): $ip"
      return $ERR_VALIDATION_ERROR
    fi
  done
  
  return $ERR_SUCCESS
}

# Validate if a string has minimum length
validate_min_length() {
  local value=$1
  local min_length=$2
  local name=${3:-"Value"}
  
  log_debug "Validating that $name has minimum length of $min_length"
  
  if (( ${#value} < min_length )); then
    log_error "$name must be at least $min_length characters long"
    return $ERR_VALIDATION_ERROR
  fi
  
  return $ERR_SUCCESS
}

# Validate if a string has maximum length
validate_max_length() {
  local value=$1
  local max_length=$2
  local name=${3:-"Value"}
  
  log_debug "Validating that $name has maximum length of $max_length"
  
  if (( ${#value} > max_length )); then
    log_error "$name must be at most $max_length characters long"
    return $ERR_VALIDATION_ERROR
  fi
  
  return $ERR_SUCCESS
}

# Validate if a password is strong enough
validate_password_strength() {
  local password=$1
  local name=${2:-"Password"}
  
  log_debug "Validating that $name is strong enough"
  
  # Check minimum length
  if (( ${#password} < 8 )); then
    log_error "$name must be at least 8 characters long"
    return $ERR_VALIDATION_ERROR
  fi
  
  # Check for uppercase letters
  if ! [[ "$password" =~ [A-Z] ]]; then
    log_error "$name must contain at least one uppercase letter"
    return $ERR_VALIDATION_ERROR
  fi
  
  # Check for lowercase letters
  if ! [[ "$password" =~ [a-z] ]]; then
    log_error "$name must contain at least one lowercase letter"
    return $ERR_VALIDATION_ERROR
  fi
  
  # Check for numbers
  if ! [[ "$password" =~ [0-9] ]]; then
    log_error "$name must contain at least one number"
    return $ERR_VALIDATION_ERROR
  fi
  
  # Check for special characters
  if ! [[ "$password" =~ [^A-Za-z0-9] ]]; then
    log_error "$name must contain at least one special character"
    return $ERR_VALIDATION_ERROR
  fi
  
  return $ERR_SUCCESS
}

log_debug "Validation module initialized"