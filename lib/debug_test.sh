#!/bin/bash
# debug_test.sh - A simple script to test VSCode debugging
# This file has been refactored to use the new core library

# Source core library modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/core/logging.sh"
source "$SCRIPT_DIR/core/error.sh"

# Function to demonstrate debugging
debug_demo() {
  local name=$1
  local count=$2
  
  log_info "Starting debug demo..."
  
  # Variables to inspect
  local array=("one" "two" "three" "four" "five")
  local number=42
  local string="Hello, $name!"
  
  # Loop to set breakpoints
  for ((i=1; i<=count; i++)); do
    log_success "Step $i of $count"
    
    # Conditional logic for debugging
    if [ $i -gt 3 ]; then
      log_warn "More than halfway through!"
    fi
    
    # Modify array for watching changes
    array[$i]="modified-$i"
    
    # Sleep to make debugging easier
    sleep 1
  done
  
  # Final output
  log_success "Debug demo completed!"
  log_info "Final array: ${array[*]}"
  log_info "Message: $string"
  
  return 0
}

# Main function
main() {
  local name=${1:-"World"}
  local count=${2:-5}
  
  log_info "Debug Test Script"
  log_info "=================="
  
  # Call the debug demo function
  debug_demo "$name" "$count"
  
  # Check the return value
  if [ $? -eq 0 ]; then
    log_success "Script executed successfully!"
  else
    log_error "Script execution failed!"
  fi
}

# Execute main function with all arguments
main "$@"