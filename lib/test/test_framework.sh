#!/bin/bash
# test_framework.sh - Unit testing framework for shell scripts
# This module provides functions for writing and running unit tests

# Guard against multiple inclusion
if [[ -n "$_TEST_FRAMEWORK_SH_INCLUDED" ]]; then
  return 0
fi
_TEST_FRAMEWORK_SH_INCLUDED=1

# Use a different variable name for the script directory
TEST_FRAMEWORK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$TEST_FRAMEWORK_DIR/../core/logging.sh"

# ANSI color codes for test output
readonly TEST_COLOR_RED='\033[0;31m'
readonly TEST_COLOR_GREEN='\033[0;32m'
readonly TEST_COLOR_YELLOW='\033[0;33m'
readonly TEST_COLOR_BLUE='\033[0;34m'
readonly TEST_COLOR_RESET='\033[0m'

# Test statistics
TEST_COUNT=0
TEST_PASSED=0
TEST_FAILED=0
TEST_SKIPPED=0
CURRENT_TEST_SUITE=""
CURRENT_TEST_CASE=""

# Test output verbosity (0=quiet, 1=normal, 2=verbose)
TEST_VERBOSITY=${TEST_VERBOSITY:-1}

# Test output format (text, tap, junit)
TEST_OUTPUT_FORMAT=${TEST_OUTPUT_FORMAT:-"text"}

# Test output file
TEST_OUTPUT_FILE=${TEST_OUTPUT_FILE:-""}

# Begin a test suite
# 
# Parameters:
#   $1 - Test suite name
function begin_test_suite() {
  CURRENT_TEST_SUITE="$1"
  
  if [[ $TEST_VERBOSITY -ge 1 ]]; then
    echo -e "${TEST_COLOR_BLUE}Test Suite: ${CURRENT_TEST_SUITE}${TEST_COLOR_RESET}"
  fi
  
  if [[ "$TEST_OUTPUT_FORMAT" == "tap" ]]; then
    echo "# Test Suite: ${CURRENT_TEST_SUITE}"
  elif [[ "$TEST_OUTPUT_FORMAT" == "junit" ]]; then
    echo "<testsuite name=\"${CURRENT_TEST_SUITE}\">"
  fi
}

# End a test suite
function end_test_suite() {
  if [[ $TEST_VERBOSITY -ge 1 ]]; then
    echo -e "${TEST_COLOR_BLUE}End Test Suite: ${CURRENT_TEST_SUITE}${TEST_COLOR_RESET}"
    echo ""
  fi
  
  if [[ "$TEST_OUTPUT_FORMAT" == "junit" ]]; then
    echo "</testsuite>"
  fi
  
  CURRENT_TEST_SUITE=""
}

# Begin a test case
# 
# Parameters:
#   $1 - Test case name
function begin_test_case() {
  CURRENT_TEST_CASE="$1"
  TEST_COUNT=$((TEST_COUNT + 1))
  
  if [[ $TEST_VERBOSITY -ge 2 ]]; then
    echo -e "  ${TEST_COLOR_BLUE}Test Case: ${CURRENT_TEST_CASE}${TEST_COLOR_RESET}"
  fi
}

# End a test case
function end_test_case() {
  CURRENT_TEST_CASE=""
}

# Skip the current test case
# 
# Parameters:
#   $1 - Reason for skipping (optional)
function skip_test() {
  local reason=${1:-"No reason provided"}
  TEST_SKIPPED=$((TEST_SKIPPED + 1))
  
  if [[ $TEST_VERBOSITY -ge 1 ]]; then
    echo -e "  ${TEST_COLOR_YELLOW}SKIP: ${CURRENT_TEST_CASE} - ${reason}${TEST_COLOR_RESET}"
  fi
  
  if [[ "$TEST_OUTPUT_FORMAT" == "tap" ]]; then
    echo "ok $TEST_COUNT # SKIP ${CURRENT_TEST_CASE} - ${reason}"
  elif [[ "$TEST_OUTPUT_FORMAT" == "junit" ]]; then
    echo "  <testcase name=\"${CURRENT_TEST_CASE}\">"
    echo "    <skipped message=\"${reason}\"/>"
    echo "  </testcase>"
  fi
  
  end_test_case
}

# Assert that a condition is true
# 
# Parameters:
#   $1 - Condition to evaluate
#   $2 - Message to display on failure (optional)
#
# Returns:
#   0 - If the condition is true
#   1 - If the condition is false
function assert() {
  local condition=$1
  local message=${2:-"Assertion failed"}
  
  if eval "$condition"; then
    if [[ $TEST_VERBOSITY -ge 2 ]]; then
      echo -e "    ${TEST_COLOR_GREEN}PASS: ${condition}${TEST_COLOR_RESET}"
    fi
    return 0
  else
    if [[ $TEST_VERBOSITY -ge 1 ]]; then
      echo -e "    ${TEST_COLOR_RED}FAIL: ${condition} - ${message}${TEST_COLOR_RESET}"
    fi
    return 1
  fi
}

# Assert that two values are equal
# 
# Parameters:
#   $1 - Expected value
#   $2 - Actual value
#   $3 - Message to display on failure (optional)
#
# Returns:
#   0 - If the values are equal
#   1 - If the values are not equal
function assert_equals() {
  local expected=$1
  local actual=$2
  local message=${3:-"Expected '$expected' but got '$actual'"}
  
  if [[ "$expected" == "$actual" ]]; then
    if [[ $TEST_VERBOSITY -ge 2 ]]; then
      echo -e "    ${TEST_COLOR_GREEN}PASS: Expected '$expected' and got '$actual'${TEST_COLOR_RESET}"
    fi
    return 0
  else
    if [[ $TEST_VERBOSITY -ge 1 ]]; then
      echo -e "    ${TEST_COLOR_RED}FAIL: ${message}${TEST_COLOR_RESET}"
    fi
    return 1
  fi
}

# Assert that a command succeeds
# 
# Parameters:
#   $1 - Command to execute
#   $2 - Message to display on failure (optional)
#
# Returns:
#   0 - If the command succeeds
#   1 - If the command fails
function assert_success() {
  local command=$1
  local message=${2:-"Command failed: $command"}
  
  if eval "$command" &>/dev/null; then
    if [[ $TEST_VERBOSITY -ge 2 ]]; then
      echo -e "    ${TEST_COLOR_GREEN}PASS: Command succeeded: ${command}${TEST_COLOR_RESET}"
    fi
    return 0
  else
    if [[ $TEST_VERBOSITY -ge 1 ]]; then
      echo -e "    ${TEST_COLOR_RED}FAIL: ${message}${TEST_COLOR_RESET}"
    fi
    return 1
  fi
}

# Assert that a command fails
# 
# Parameters:
#   $1 - Command to execute
#   $2 - Message to display on failure (optional)
#
# Returns:
#   0 - If the command fails
#   1 - If the command succeeds
function assert_failure() {
  local command=$1
  local message=${2:-"Command succeeded but should have failed: $command"}
  
  if ! eval "$command" &>/dev/null; then
    if [[ $TEST_VERBOSITY -ge 2 ]]; then
      echo -e "    ${TEST_COLOR_GREEN}PASS: Command failed as expected: ${command}${TEST_COLOR_RESET}"
    fi
    return 0
  else
    if [[ $TEST_VERBOSITY -ge 1 ]]; then
      echo -e "    ${TEST_COLOR_RED}FAIL: ${message}${TEST_COLOR_RESET}"
    fi
    return 1
  fi
}

# Assert that a file exists
# 
# Parameters:
#   $1 - File path
#   $2 - Message to display on failure (optional)
#
# Returns:
#   0 - If the file exists
#   1 - If the file does not exist
function assert_file_exists() {
  local file=$1
  local message=${2:-"File does not exist: $file"}
  
  if [[ -f "$file" ]]; then
    if [[ $TEST_VERBOSITY -ge 2 ]]; then
      echo -e "    ${TEST_COLOR_GREEN}PASS: File exists: ${file}${TEST_COLOR_RESET}"
    fi
    return 0
  else
    if [[ $TEST_VERBOSITY -ge 1 ]]; then
      echo -e "    ${TEST_COLOR_RED}FAIL: ${message}${TEST_COLOR_RESET}"
    fi
    return 1
  fi
}

# Assert that a directory exists
# 
# Parameters:
#   $1 - Directory path
#   $2 - Message to display on failure (optional)
#
# Returns:
#   0 - If the directory exists
#   1 - If the directory does not exist
function assert_directory_exists() {
  local dir=$1
  local message=${2:-"Directory does not exist: $dir"}
  
  if [[ -d "$dir" ]]; then
    if [[ $TEST_VERBOSITY -ge 2 ]]; then
      echo -e "    ${TEST_COLOR_GREEN}PASS: Directory exists: ${dir}${TEST_COLOR_RESET}"
    fi
    return 0
  else
    if [[ $TEST_VERBOSITY -ge 1 ]]; then
      echo -e "    ${TEST_COLOR_RED}FAIL: ${message}${TEST_COLOR_RESET}"
    fi
    return 1
  fi
}

# Run a test function and record the result
# 
# Parameters:
#   $1 - Test function name
#   $2 - Test description (optional)
function run_test() {
  local test_function=$1
  local description=${2:-$test_function}
  
  begin_test_case "$description"
  
  # Run the test function in a subshell to isolate it
  (
    set -e
    $test_function
  )
  local result=$?
  
  if [[ $result -eq 0 ]]; then
    TEST_PASSED=$((TEST_PASSED + 1))
    if [[ $TEST_VERBOSITY -ge 1 ]]; then
      echo -e "  ${TEST_COLOR_GREEN}PASS: ${description}${TEST_COLOR_RESET}"
    fi
    
    if [[ "$TEST_OUTPUT_FORMAT" == "tap" ]]; then
      echo "ok $TEST_COUNT - ${description}"
    elif [[ "$TEST_OUTPUT_FORMAT" == "junit" ]]; then
      echo "  <testcase name=\"${description}\"/>"
    fi
  else
    TEST_FAILED=$((TEST_FAILED + 1))
    if [[ $TEST_VERBOSITY -ge 1 ]]; then
      echo -e "  ${TEST_COLOR_RED}FAIL: ${description}${TEST_COLOR_RESET}"
    fi
    
    if [[ "$TEST_OUTPUT_FORMAT" == "tap" ]]; then
      echo "not ok $TEST_COUNT - ${description}"
    elif [[ "$TEST_OUTPUT_FORMAT" == "junit" ]]; then
      echo "  <testcase name=\"${description}\">"
      echo "    <failure message=\"Test failed\"/>"
      echo "  </testcase>"
    fi
  fi
  
  end_test_case
}

# Run all test functions in the current script
# 
# Parameters:
#   $@ - List of test function names (optional, if not provided all functions starting with "test_" will be run)
function run_tests() {
  local test_functions=("$@")
  
  # If no test functions are provided, find all functions starting with "test_"
  if [[ ${#test_functions[@]} -eq 0 ]]; then
    # Get all functions in the current script
    local all_functions
    all_functions=$(declare -F | awk '{print $3}')
    
    # Filter functions starting with "test_"
    for func in $all_functions; do
      if [[ "$func" == test_* ]]; then
        test_functions+=("$func")
      fi
    done
  fi
  
  # Initialize test statistics
  TEST_COUNT=0
  TEST_PASSED=0
  TEST_FAILED=0
  TEST_SKIPPED=0
  
  # Start TAP output
  if [[ "$TEST_OUTPUT_FORMAT" == "tap" ]]; then
    echo "TAP version 13"
    echo "1..${#test_functions[@]}"
  elif [[ "$TEST_OUTPUT_FORMAT" == "junit" ]]; then
    echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
    echo "<testsuites>"
  fi
  
  # Run each test function
  for test_function in "${test_functions[@]}"; do
    run_test "$test_function"
  done
  
  # End TAP output
  if [[ "$TEST_OUTPUT_FORMAT" == "junit" ]]; then
    echo "</testsuites>"
  fi
  
  # Print test summary
  if [[ $TEST_VERBOSITY -ge 1 ]]; then
    echo ""
    echo -e "${TEST_COLOR_BLUE}Test Summary:${TEST_COLOR_RESET}"
    echo -e "  Total: $TEST_COUNT"
    echo -e "  ${TEST_COLOR_GREEN}Passed: $TEST_PASSED${TEST_COLOR_RESET}"
    echo -e "  ${TEST_COLOR_RED}Failed: $TEST_FAILED${TEST_COLOR_RESET}"
    echo -e "  ${TEST_COLOR_YELLOW}Skipped: $TEST_SKIPPED${TEST_COLOR_RESET}"
    echo ""
  fi
  
  # Return non-zero exit code if any tests failed
  if [[ $TEST_FAILED -gt 0 ]]; then
    return 1
  else
    return 0
  fi
}

# Set the test output format
# 
# Parameters:
#   $1 - Output format (text, tap, junit)
function set_test_output_format() {
  TEST_OUTPUT_FORMAT="$1"
}

# Set the test verbosity level
# 
# Parameters:
#   $1 - Verbosity level (0=quiet, 1=normal, 2=verbose)
function set_test_verbosity() {
  TEST_VERBOSITY="$1"
}

# Set the test output file
# 
# Parameters:
#   $1 - Output file path
function set_test_output_file() {
  TEST_OUTPUT_FILE="$1"
  
  # Redirect output to the file
  if [[ -n "$TEST_OUTPUT_FILE" ]]; then
    exec > >(tee "$TEST_OUTPUT_FILE") 2>&1
  fi
}

# Initialize the test framework
function init_test_framework() {
  log_debug "Initializing test framework"
  
  # Set default values
  TEST_VERBOSITY=${TEST_VERBOSITY:-1}
  TEST_OUTPUT_FORMAT=${TEST_OUTPUT_FORMAT:-"text"}
  TEST_OUTPUT_FILE=${TEST_OUTPUT_FILE:-""}
  
  # Redirect output to file if specified
  if [[ -n "$TEST_OUTPUT_FILE" ]]; then
    set_test_output_file "$TEST_OUTPUT_FILE"
  fi
}

# Initialize the test framework
init_test_framework

log_debug "Test framework initialized"