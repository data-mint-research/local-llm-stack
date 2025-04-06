#!/bin/bash
# test_validation.sh - Unit tests for the validation module
# This script tests the functions in the validation.sh module

# Source the test framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../test/test_framework.sh"

# Source the module to test
source "$SCRIPT_DIR/../validation.sh"

# Setup function that runs before each test
function setup() {
  # Create any test fixtures or setup needed for tests
  TEST_DIR="/tmp/validation_test_$$"
  mkdir -p "$TEST_DIR"
  
  # Create test files
  echo "test content" > "$TEST_DIR/test_file.txt"
  mkdir -p "$TEST_DIR/test_dir"
}

# Teardown function that runs after each test
function teardown() {
  # Clean up test fixtures
  rm -rf "$TEST_DIR"
}

# Test case for validate_not_empty function
function test_validate_not_empty() {
  # Test with non-empty value
  validate_not_empty "test value" "Test Value"
  assert_equals 0 $? "validate_not_empty should return success for non-empty value"
  
  # Test with empty value
  validate_not_empty "" "Empty Value"
  assert_equals $ERR_VALIDATION_ERROR $? "validate_not_empty should return error for empty value"
}

# Test case for validate_is_number function
function test_validate_is_number() {
  # Test with valid number
  validate_is_number "123" "Valid Number"
  assert_equals 0 $? "validate_is_number should return success for valid number"
  
  # Test with invalid number (contains letters)
  validate_is_number "123abc" "Invalid Number"
  assert_equals $ERR_VALIDATION_ERROR $? "validate_is_number should return error for invalid number"
  
  # Test with invalid number (contains special characters)
  validate_is_number "123.45" "Invalid Number"
  assert_equals $ERR_VALIDATION_ERROR $? "validate_is_number should return error for decimal number"
  
  # Test with empty value
  validate_is_number "" "Empty Number"
  assert_equals $ERR_VALIDATION_ERROR $? "validate_is_number should return error for empty value"
}

# Test case for validate_is_decimal function
function test_validate_is_decimal() {
  # Test with valid integer
  validate_is_decimal "123" "Valid Integer"
  assert_equals 0 $? "validate_is_decimal should return success for valid integer"
  
  # Test with valid decimal
  validate_is_decimal "123.45" "Valid Decimal"
  assert_equals 0 $? "validate_is_decimal should return success for valid decimal"
  
  # Test with invalid decimal (contains letters)
  validate_is_decimal "123.45abc" "Invalid Decimal"
  assert_equals $ERR_VALIDATION_ERROR $? "validate_is_decimal should return error for invalid decimal"
  
  # Test with invalid decimal (multiple decimal points)
  validate_is_decimal "123.45.67" "Invalid Decimal"
  assert_equals $ERR_VALIDATION_ERROR $? "validate_is_decimal should return error for multiple decimal points"
  
  # Test with empty value
  validate_is_decimal "" "Empty Decimal"
  assert_equals $ERR_VALIDATION_ERROR $? "validate_is_decimal should return error for empty value"
}

# Test case for validate_in_range function
function test_validate_in_range() {
  # Test with value in range
  validate_in_range "5" "1" "10" "In Range"
  assert_equals 0 $? "validate_in_range should return success for value in range"
  
  # Test with value at lower bound
  validate_in_range "1" "1" "10" "Lower Bound"
  assert_equals 0 $? "validate_in_range should return success for value at lower bound"
  
  # Test with value at upper bound
  validate_in_range "10" "1" "10" "Upper Bound"
  assert_equals 0 $? "validate_in_range should return success for value at upper bound"
  
  # Test with value below range
  validate_in_range "0" "1" "10" "Below Range"
  assert_equals $ERR_VALIDATION_ERROR $? "validate_in_range should return error for value below range"
  
  # Test with value above range
  validate_in_range "11" "1" "10" "Above Range"
  assert_equals $ERR_VALIDATION_ERROR $? "validate_in_range should return error for value above range"
  
  # Test with decimal value in range
  validate_in_range "5.5" "1" "10" "Decimal In Range"
  assert_equals 0 $? "validate_in_range should return success for decimal value in range"
  
  # Test with invalid value
  validate_in_range "abc" "1" "10" "Invalid Value"
  assert_equals $ERR_VALIDATION_ERROR $? "validate_in_range should return error for invalid value"
}

# Test case for validate_in_set function
function test_validate_in_set() {
  # Test with value in set
  validate_in_set "apple" "apple" "banana" "orange" "Fruit"
  assert_equals 0 $? "validate_in_set should return success for value in set"
  
  # Test with value not in set
  validate_in_set "grape" "apple" "banana" "orange" "Fruit"
  assert_equals $ERR_VALIDATION_ERROR $? "validate_in_set should return error for value not in set"
  
  # Test with empty value
  validate_in_set "" "apple" "banana" "orange" "Fruit"
  assert_equals $ERR_VALIDATION_ERROR $? "validate_in_set should return error for empty value"
  
  # Test with case sensitivity
  validate_in_set "Apple" "apple" "banana" "orange" "Fruit"
  assert_equals $ERR_VALIDATION_ERROR $? "validate_in_set should be case sensitive"
}

# Test case for validate_file_exists function
function test_validate_file_exists() {
  # Test with existing file
  validate_file_exists "$TEST_DIR/test_file.txt" "Existing File"
  assert_equals 0 $? "validate_file_exists should return success for existing file"
  
  # Test with non-existent file
  validate_file_exists "$TEST_DIR/nonexistent.txt" "Non-existent File"
  assert_equals $ERR_VALIDATION_ERROR $? "validate_file_exists should return error for non-existent file"
  
  # Test with directory
  validate_file_exists "$TEST_DIR/test_dir" "Directory"
  assert_equals $ERR_VALIDATION_ERROR $? "validate_file_exists should return error for directory"
}

# Test case for validate_directory_exists function
function test_validate_directory_exists() {
  # Test with existing directory
  validate_directory_exists "$TEST_DIR/test_dir" "Existing Directory"
  assert_equals 0 $? "validate_directory_exists should return success for existing directory"
  
  # Test with non-existent directory
  validate_directory_exists "$TEST_DIR/nonexistent_dir" "Non-existent Directory"
  assert_equals $ERR_VALIDATION_ERROR $? "validate_directory_exists should return error for non-existent directory"
  
  # Test with file
  validate_directory_exists "$TEST_DIR/test_file.txt" "File"
  assert_equals $ERR_VALIDATION_ERROR $? "validate_directory_exists should return error for file"
}

# Test case for validate_pattern function
function test_validate_pattern() {
  # Test with matching pattern
  validate_pattern "abc123" "^[a-z]+[0-9]+$" "Valid Pattern"
  assert_equals 0 $? "validate_pattern should return success for matching pattern"
  
  # Test with non-matching pattern
  validate_pattern "123abc" "^[a-z]+[0-9]+$" "Invalid Pattern"
  assert_equals $ERR_VALIDATION_ERROR $? "validate_pattern should return error for non-matching pattern"
  
  # Test with empty value
  validate_pattern "" "^[a-z]+[0-9]+$" "Empty Value"
  assert_equals $ERR_VALIDATION_ERROR $? "validate_pattern should return error for empty value"
}

# Test case for validate_port function
function test_validate_port() {
  # Test with valid port
  validate_port "8080" "Valid Port"
  assert_equals 0 $? "validate_port should return success for valid port"
  
  # Test with port at lower bound
  validate_port "1" "Lower Bound Port"
  assert_equals 0 $? "validate_port should return success for port at lower bound"
  
  # Test with port at upper bound
  validate_port "65535" "Upper Bound Port"
  assert_equals 0 $? "validate_port should return success for port at upper bound"
  
  # Test with port below range
  validate_port "0" "Below Range Port"
  assert_equals $ERR_VALIDATION_ERROR $? "validate_port should return error for port below range"
  
  # Test with port above range
  validate_port "65536" "Above Range Port"
  assert_equals $ERR_VALIDATION_ERROR $? "validate_port should return error for port above range"
  
  # Test with invalid port (contains letters)
  validate_port "8080a" "Invalid Port"
  assert_equals $ERR_VALIDATION_ERROR $? "validate_port should return error for invalid port"
  
  # Test with empty value
  validate_port "" "Empty Port"
  assert_equals $ERR_VALIDATION_ERROR $? "validate_port should return error for empty value"
}

# Test case for validate_email function
function test_validate_email() {
  # Test with valid email
  validate_email "user@example.com" "Valid Email"
  assert_equals 0 $? "validate_email should return success for valid email"
  
  # Test with invalid email (no @)
  validate_email "userexample.com" "Invalid Email"
  assert_equals $ERR_VALIDATION_ERROR $? "validate_email should return error for email without @"
  
  # Test with invalid email (no domain)
  validate_email "user@" "Invalid Email"
  assert_equals $ERR_VALIDATION_ERROR $? "validate_email should return error for email without domain"
  
  # Test with invalid email (no username)
  validate_email "@example.com" "Invalid Email"
  assert_equals $ERR_VALIDATION_ERROR $? "validate_email should return error for email without username"
  
  # Test with empty value
  validate_email "" "Empty Email"
  assert_equals $ERR_VALIDATION_ERROR $? "validate_email should return error for empty value"
}

# Main test runner
function run_all_tests() {
  begin_test_suite "Validation Module Tests"
  
  # Run tests with setup and teardown
  setup
  run_test test_validate_not_empty "Test validate_not_empty function"
  teardown
  
  setup
  run_test test_validate_is_number "Test validate_is_number function"
  teardown
  
  setup
  run_test test_validate_is_decimal "Test validate_is_decimal function"
  teardown
  
  setup
  run_test test_validate_in_range "Test validate_in_range function"
  teardown
  
  setup
  run_test test_validate_in_set "Test validate_in_set function"
  teardown
  
  setup
  run_test test_validate_file_exists "Test validate_file_exists function"
  teardown
  
  setup
  run_test test_validate_directory_exists "Test validate_directory_exists function"
  teardown
  
  setup
  run_test test_validate_pattern "Test validate_pattern function"
  teardown
  
  setup
  run_test test_validate_port "Test validate_port function"
  teardown
  
  setup
  run_test test_validate_email "Test validate_email function"
  teardown
  
  end_test_suite
}

# Run all tests if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  # Parse command line arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --verbose)
        set_test_verbosity 2
        shift
        ;;
      --quiet)
        set_test_verbosity 0
        shift
        ;;
      --tap)
        set_test_output_format "tap"
        shift
        ;;
      --junit)
        set_test_output_format "junit"
        shift
        ;;
      --output)
        set_test_output_file "$2"
        shift 2
        ;;
      *)
        echo "Unknown option: $1"
        echo "Usage: $0 [--verbose|--quiet] [--tap|--junit] [--output file]"
        exit 1
        ;;
    esac
  done
  
  # Run all tests
  run_all_tests
  exit $?
fi