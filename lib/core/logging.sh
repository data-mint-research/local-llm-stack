#!/bin/bash
# logging.sh - Standardized logging framework for LOCAL-LLM-Stack
# This module provides consistent logging functions with different severity levels

# Guard against multiple inclusion
if [[ -n "$_LOGGING_SH_INCLUDED" ]]; then
  return 0
fi
_LOGGING_SH_INCLUDED=1

# Use a different variable name for the script directory
LOGGING_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ANSI color codes for better readability
readonly LOG_COLOR_RED='\033[0;31m'
readonly LOG_COLOR_GREEN='\033[0;32m'
readonly LOG_COLOR_YELLOW='\033[0;33m'
readonly LOG_COLOR_BLUE='\033[0;34m'
readonly LOG_COLOR_MAGENTA='\033[0;35m'
readonly LOG_COLOR_CYAN='\033[0;36m'
readonly LOG_COLOR_RESET='\033[0m'

# Log levels
readonly LOG_LEVEL_DEBUG=0
readonly LOG_LEVEL_INFO=1
readonly LOG_LEVEL_WARN=2
readonly LOG_LEVEL_ERROR=3
readonly LOG_LEVEL_FATAL=4

# Default log level (can be overridden in config)
LOG_LEVEL=${LOG_LEVEL:-$LOG_LEVEL_INFO}

# Enable/disable timestamps in logs
LOG_TIMESTAMPS=${LOG_TIMESTAMPS:-true}

# Enable/disable log file output
LOG_TO_FILE=${LOG_TO_FILE:-false}
LOG_FILE=${LOG_FILE:-"./local-llm-stack.log"}

# Format timestamp for logs
_format_timestamp() {
  date "+%Y-%m-%d %H:%M:%S"
}

# Internal logging function
_log() {
  local level=$1
  local color=$2
  local prefix=$3
  local message=$4
  
  # Check if we should log this message based on level
  if [[ $level -ge $LOG_LEVEL ]]; then
    local timestamp=""
    if [[ "$LOG_TIMESTAMPS" == "true" ]]; then
      timestamp="[$(_format_timestamp)] "
    fi
    
    # Print to console with color
    echo -e "${color}${timestamp}${prefix}: ${message}${LOG_COLOR_RESET}" >&2
    
    # Log to file if enabled (without colors)
    if [[ "$LOG_TO_FILE" == "true" ]]; then
      echo "${timestamp}${prefix}: ${message}" >> "$LOG_FILE"
    fi
  fi
}

# Public logging functions
log_debug() {
  _log $LOG_LEVEL_DEBUG "$LOG_COLOR_CYAN" "DEBUG" "$1"
}

log_info() {
  _log $LOG_LEVEL_INFO "$LOG_COLOR_BLUE" "INFO" "$1"
}

log_success() {
  _log $LOG_LEVEL_INFO "$LOG_COLOR_GREEN" "SUCCESS" "$1"
}

log_warn() {
  _log $LOG_LEVEL_WARN "$LOG_COLOR_YELLOW" "WARNING" "$1"
}

log_error() {
  _log $LOG_LEVEL_ERROR "$LOG_COLOR_RED" "ERROR" "$1"
}

log_fatal() {
  _log $LOG_LEVEL_FATAL "$LOG_COLOR_RED" "FATAL" "$1"
}

# Function to set the log level
set_log_level() {
  case "${1,,}" in
    debug) LOG_LEVEL=$LOG_LEVEL_DEBUG ;;
    info)  LOG_LEVEL=$LOG_LEVEL_INFO ;;
    warn)  LOG_LEVEL=$LOG_LEVEL_WARN ;;
    error) LOG_LEVEL=$LOG_LEVEL_ERROR ;;
    fatal) LOG_LEVEL=$LOG_LEVEL_FATAL ;;
    *)     log_warn "Invalid log level: $1. Using default." ;;
  esac
}

# Function to enable/disable logging to file
enable_file_logging() {
  LOG_TO_FILE=true
  LOG_FILE="${1:-$LOG_FILE}"
  
  # Create log directory if it doesn't exist
  local log_dir=$(dirname "$LOG_FILE")
  if [[ ! -d "$log_dir" ]]; then
    mkdir -p "$log_dir"
  fi
  
  log_debug "File logging enabled: $LOG_FILE"
}

disable_file_logging() {
  LOG_TO_FILE=false
  log_debug "File logging disabled"
}

# Export color variables for backward compatibility
# These will be deprecated in future versions
export RED="$LOG_COLOR_RED"
export GREEN="$LOG_COLOR_GREEN"
export YELLOW="$LOG_COLOR_YELLOW"
export BLUE="$LOG_COLOR_BLUE"
export MAGENTA="$LOG_COLOR_MAGENTA"
export CYAN="$LOG_COLOR_CYAN"
export NC="$LOG_COLOR_RESET"  # No Color

log_debug "Logging module initialized"