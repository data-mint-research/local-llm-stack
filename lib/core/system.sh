#!/bin/bash
# system.sh - System operations for LOCAL-LLM-Stack
# This module provides functions for file handling, system checks, and other OS operations

# Guard against multiple inclusion
if [[ -n "$_SYSTEM_SH_INCLUDED" ]]; then
  return 0
fi
_SYSTEM_SH_INCLUDED=1

# Use a different variable name for the script directory
SYSTEM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SYSTEM_DIR/logging.sh"
source "$SYSTEM_DIR/error.sh"

# File operations

# Create a backup of a file with timestamp
backup_file() {
  local file=$1
  local backup="${file}.backup-$(date +%Y%m%d%H%M%S)"
  
  log_debug "Creating backup of $file to $backup"
  
  if [[ ! -f "$file" ]]; then
    log_warn "File does not exist: $file"
    return $ERR_FILE_NOT_FOUND
  fi
  
  cp "$file" "$backup" 2>/dev/null
  if [[ $? -eq 0 ]]; then
    log_success "Backup created at $backup"
    echo "$backup"
    return $ERR_SUCCESS
  else
    log_error "Failed to create backup of $file"
    return $ERR_GENERAL
  fi
}

# Ensure a directory exists, creating it if necessary
ensure_directory() {
  local dir=$1
  local permissions=${2:-755}
  
  log_debug "Ensuring directory exists: $dir"
  
  if [[ -d "$dir" ]]; then
    log_debug "Directory already exists: $dir"
    return $ERR_SUCCESS
  fi
  
  mkdir -p "$dir" 2>/dev/null
  if [[ $? -eq 0 ]]; then
    chmod "$permissions" "$dir" 2>/dev/null
    log_success "Created directory: $dir"
    return $ERR_SUCCESS
  else
    log_error "Failed to create directory: $dir"
    return $ERR_PERMISSION_DENIED
  fi
}

# Check if a file exists and is readable
file_exists() {
  local file=$1
  
  if [[ -f "$file" && -r "$file" ]]; then
    return $ERR_SUCCESS
  else
    return $ERR_FILE_NOT_FOUND
  fi
}

# Check if a directory exists and is writable
directory_is_writable() {
  local dir=$1
  
  if [[ -d "$dir" && -w "$dir" ]]; then
    return $ERR_SUCCESS
  else
    return $ERR_PERMISSION_DENIED
  fi
}

# Check if we need sudo for file operations
need_sudo() {
  local dir=$1
  
  if [[ ! -w "$dir" ]] || find "$dir" -not -writable -print -quit 2>/dev/null | grep -q .; then
    log_debug "Sudo is required for operations in: $dir"
    return $ERR_SUCCESS  # Return success (true) if sudo is needed
  else
    log_debug "Sudo is not required for operations in: $dir"
    return $ERR_GENERAL  # Return non-zero (false) if sudo is not needed
  fi
}

# System operations

# Check if a command exists
command_exists() {
  local cmd=$1
  
  if command -v "$cmd" > /dev/null 2>&1; then
    log_debug "Command exists: $cmd"
    return $ERR_SUCCESS
  else
    log_debug "Command not found: $cmd"
    return $ERR_COMMAND_NOT_FOUND
  fi
}

# Get available disk space in GB
get_disk_space() {
  local dir=${1:-.}
  
  log_debug "Checking disk space for directory: $dir"
  
  if [[ ! -d "$dir" ]]; then
    log_warn "Directory does not exist: $dir"
    return $ERR_FILE_NOT_FOUND
  fi
  
  local space=$(df -BG "$dir" | awk 'NR==2 {print $4}' | sed 's/G//')
  echo "$space"
  return $ERR_SUCCESS
}

# Check if there's enough disk space
check_disk_space() {
  local dir=${1:-.}
  local required_gb=$2
  
  log_debug "Checking if there's at least ${required_gb}GB available in $dir"
  
  local available=$(get_disk_space "$dir")
  if [[ $? -ne 0 ]]; then
    return $ERR_GENERAL
  fi
  
  if (( available < required_gb )); then
    log_warn "Not enough disk space. Required: ${required_gb}GB, Available: ${available}GB"
    return $ERR_GENERAL
  else
    log_debug "Sufficient disk space. Required: ${required_gb}GB, Available: ${available}GB"
    return $ERR_SUCCESS
  fi
}

# Get system memory in GB
get_system_memory() {
  log_debug "Getting system memory"
  
  if command_exists "free"; then
    local mem=$(free -g | awk '/^Mem:/ {print $2}')
    echo "$mem"
    return $ERR_SUCCESS
  else
    log_warn "Cannot determine system memory: 'free' command not found"
    return $ERR_COMMAND_NOT_FOUND
  fi
}

# Check if there's enough system memory
check_system_memory() {
  local required_gb=$1
  
  log_debug "Checking if there's at least ${required_gb}GB of system memory"
  
  local available=$(get_system_memory)
  if [[ $? -ne 0 ]]; then
    return $ERR_GENERAL
  fi
  
  if (( available < required_gb )); then
    log_warn "Not enough system memory. Required: ${required_gb}GB, Available: ${available}GB"
    return $ERR_GENERAL
  else
    log_debug "Sufficient system memory. Required: ${required_gb}GB, Available: ${available}GB"
    return $ERR_SUCCESS
  fi
}

# Get CPU count
get_cpu_count() {
  log_debug "Getting CPU count"
  
  local count=$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo 2>/dev/null || echo 1)
  echo "$count"
  return $ERR_SUCCESS
}

# Check if running as root
is_root() {
  if [[ $EUID -eq 0 ]]; then
    return $ERR_SUCCESS
  else
    return $ERR_GENERAL
  fi
}

# Get the absolute path of a file or directory
get_absolute_path() {
  local path=$1
  
  if [[ -d "$path" ]]; then
    (cd "$path" && pwd)
  elif [[ -f "$path" ]]; then
    local dir=$(dirname "$path")
    local file=$(basename "$path")
    echo "$(cd "$dir" && pwd)/$file"
  else
    log_warn "Path does not exist: $path"
    return $ERR_FILE_NOT_FOUND
  fi
}

# Get the OS type (linux, darwin, etc.)
get_os_type() {
  local os=$(uname -s | tr '[:upper:]' '[:lower:]')
  echo "$os"
  return $ERR_SUCCESS
}

# Get the OS distribution (ubuntu, fedora, etc.)
get_os_distribution() {
  if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    echo "$ID"
  elif [[ -f /etc/lsb-release ]]; then
    source /etc/lsb-release
    echo "$DISTRIB_ID" | tr '[:upper:]' '[:lower:]'
  else
    echo "unknown"
  fi
  return $ERR_SUCCESS
}

# Generate random string using OpenSSL
generate_random_string() {
  local length=$1
  openssl rand -base64 $((length * 2)) | tr -dc 'a-zA-Z0-9' | head -c $length
}

# Generate hex string using OpenSSL
generate_hex_string() {
  local length=$1
  openssl rand -hex $((length / 2))
}

log_debug "System operations module initialized"