#!/bin/bash
# debug_test.sh - A simple script to test VSCode debugging

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Function to demonstrate debugging
debug_demo() {
  local name=$1
  local count=$2
  
  echo -e "${BLUE}Starting debug demo...${NC}"
  
  # Variables to inspect
  local array=("one" "two" "three" "four" "five")
  local number=42
  local string="Hello, $name!"
  
  # Loop to set breakpoints
  for ((i=1; i<=count; i++)); do
    echo -e "${GREEN}Step $i of $count${NC}"
    
    # Conditional logic for debugging
    if [ $i -gt 3 ]; then
      echo -e "${YELLOW}More than halfway through!${NC}"
    fi
    
    # Modify array for watching changes
    array[$i]="modified-$i"
    
    # Sleep to make debugging easier
    sleep 1
  done
  
  # Final output
  echo -e "${GREEN}Debug demo completed!${NC}"
  echo -e "${BLUE}Final array: ${array[*]}${NC}"
  echo -e "${BLUE}Message: $string${NC}"
  
  return 0
}

# Main function
main() {
  local name=${1:-"World"}
  local count=${2:-5}
  
  echo -e "${BLUE}Debug Test Script${NC}"
  echo -e "${BLUE}==================${NC}"
  
  # Call the debug demo function
  debug_demo "$name" "$count"
  
  # Check the return value
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}Script executed successfully!${NC}"
  else
    echo -e "${RED}Script execution failed!${NC}"
  fi
}

# Execute main function with all arguments
main "$@"