#!/bin/bash
# run_tests.sh - Run all tests for LOCAL-LLM-Stack
# This script discovers and runs all test scripts in the project

# Source the test framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_framework.sh"

# Default options
VERBOSITY=1
OUTPUT_FORMAT="text"
OUTPUT_FILE=""
TEST_PATTERN="test_*.sh"
TEST_DIRS=("$SCRIPT_DIR")
INCLUDE_CORE=true
INCLUDE_MODULES=true

# Display usage information
function show_usage() {
  echo "Usage: $(basename "$0") [options]"
  echo ""
  echo "Run all tests for LOCAL-LLM-Stack"
  echo ""
  echo "Options:"
  echo "  -h, --help           Show this help message and exit"
  echo "  -v, --verbose        Enable verbose output"
  echo "  -q, --quiet          Suppress all output except errors"
  echo "  -t, --tap            Output in TAP format"
  echo "  -j, --junit          Output in JUnit XML format"
  echo "  -o, --output FILE    Write output to FILE"
  echo "  -p, --pattern PATTERN Only run tests matching PATTERN (default: test_*.sh)"
  echo "  -d, --dir DIRECTORY  Add DIRECTORY to test search path"
  echo "  --no-core            Don't run core library tests"
  echo "  --no-modules         Don't run module tests"
  echo ""
  echo "Examples:"
  echo "  $(basename "$0") --verbose"
  echo "  $(basename "$0") --tap --output test-results.tap"
  echo "  $(basename "$0") --pattern \"*system*\""
  echo "  $(basename "$0") --dir lib/custom/tests"
}

# Parse command line arguments
function parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        show_usage
        exit 0
        ;;
      -v|--verbose)
        VERBOSITY=2
        shift
        ;;
      -q|--quiet)
        VERBOSITY=0
        shift
        ;;
      -t|--tap)
        OUTPUT_FORMAT="tap"
        shift
        ;;
      -j|--junit)
        OUTPUT_FORMAT="junit"
        shift
        ;;
      -o|--output)
        OUTPUT_FILE="$2"
        shift 2
        ;;
      -p|--pattern)
        TEST_PATTERN="$2"
        shift 2
        ;;
      -d|--dir)
        TEST_DIRS+=("$2")
        shift 2
        ;;
      --no-core)
        INCLUDE_CORE=false
        shift
        ;;
      --no-modules)
        INCLUDE_MODULES=false
        shift
        ;;
      *)
        echo "Unknown option: $1"
        show_usage
        exit 1
        ;;
    esac
  done
}

# Find all test scripts matching the pattern
function find_test_scripts() {
  local test_scripts=()
  
  # Add core library tests if enabled
  if [[ "$INCLUDE_CORE" == "true" ]]; then
    TEST_DIRS+=("$SCRIPT_DIR/../core/test")
  fi
  
  # Add module tests if enabled
  if [[ "$INCLUDE_MODULES" == "true" ]]; then
    # Find all module test directories
    local module_dirs
    module_dirs=$(find "$SCRIPT_DIR/../../modules" -type d -name "test" 2>/dev/null)
    
    # Add each module test directory to the search path
    for dir in $module_dirs; do
      TEST_DIRS+=("$dir")
    done
  fi
  
  # Find all test scripts in the search path
  for dir in "${TEST_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
      local scripts
      scripts=$(find "$dir" -type f -name "$TEST_PATTERN" 2>/dev/null)
      
      for script in $scripts; do
        test_scripts+=("$script")
      done
    fi
  done
  
  # Return the list of test scripts
  echo "${test_scripts[@]}"
}

# Run a test script
function run_test_script() {
  local script=$1
  local script_name=$(basename "$script")
  
  echo -e "${TEST_COLOR_BLUE}Running test script: ${script_name}${TEST_COLOR_RESET}"
  
  # Make the script executable if it's not already
  if [[ ! -x "$script" ]]; then
    chmod +x "$script"
  fi
  
  # Run the test script with the appropriate options
  local options=""
  
  if [[ $VERBOSITY -eq 0 ]]; then
    options="$options --quiet"
  elif [[ $VERBOSITY -eq 2 ]]; then
    options="$options --verbose"
  fi
  
  if [[ "$OUTPUT_FORMAT" != "text" ]]; then
    options="$options --$OUTPUT_FORMAT"
  fi
  
  # Run the test script
  "$script" $options
  local result=$?
  
  echo ""
  
  return $result
}

# Main function
function main() {
  # Parse command line arguments
  parse_arguments "$@"
  
  # Set test framework options
  set_test_verbosity "$VERBOSITY"
  set_test_output_format "$OUTPUT_FORMAT"
  
  if [[ -n "$OUTPUT_FILE" ]]; then
    set_test_output_file "$OUTPUT_FILE"
  fi
  
  # Find all test scripts
  local test_scripts
  test_scripts=($(find_test_scripts))
  
  # Check if we found any test scripts
  if [[ ${#test_scripts[@]} -eq 0 ]]; then
    echo "No test scripts found matching pattern: $TEST_PATTERN"
    exit 0
  fi
  
  echo "Found ${#test_scripts[@]} test scripts"
  
  # Initialize counters
  local total_scripts=${#test_scripts[@]}
  local passed_scripts=0
  local failed_scripts=0
  
  # Run each test script
  for script in "${test_scripts[@]}"; do
    run_test_script "$script"
    if [[ $? -eq 0 ]]; then
      passed_scripts=$((passed_scripts + 1))
    else
      failed_scripts=$((failed_scripts + 1))
    fi
  done
  
  # Print summary
  echo -e "${TEST_COLOR_BLUE}Test Summary:${TEST_COLOR_RESET}"
  echo -e "  Total test scripts: $total_scripts"
  echo -e "  ${TEST_COLOR_GREEN}Passed: $passed_scripts${TEST_COLOR_RESET}"
  echo -e "  ${TEST_COLOR_RED}Failed: $failed_scripts${TEST_COLOR_RESET}"
  echo ""
  
  # Return non-zero exit code if any scripts failed
  if [[ $failed_scripts -gt 0 ]]; then
    return 1
  else
    return 0
  fi
}

# Run the main function
main "$@"
exit $?