#!/bin/bash
# test_template.sh - Template for unit tests
# This template demonstrates how to write unit tests using the test framework

# Source the test framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_framework.sh"

# Source the module to test
source "$SCRIPT_DIR/../core/system.sh"

# Setup function that runs before each test
function setup() {
  # Create any test fixtures or setup needed for tests
  TEST_DIR="/tmp/test_$$"
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

# Test case for file_exists function
function test_file_exists() {
  # Test that file_exists returns success for existing file
  assert "file_exists '$TEST_DIR/test_file.txt'" "file_exists should return success for existing file"
  
  # Test that file_exists returns failure for non-existent file
  assert "! file_exists '$TEST_DIR/nonexistent.txt'" "file_exists should return failure for non-existent file"
  
  # Test that file_exists returns failure for directory
  assert "! file_exists '$TEST_DIR/test_dir'" "file_exists should return failure for directory"
}

# Test case for directory_is_writable function
function test_directory_is_writable() {
  # Test that directory_is_writable returns success for writable directory
  assert "directory_is_writable '$TEST_DIR'" "directory_is_writable should return success for writable directory"
  
  # Create a read-only directory
  mkdir -p "$TEST_DIR/readonly_dir"
  chmod 555 "$TEST_DIR/readonly_dir"
  
  # Test that directory_is_writable returns failure for read-only directory
  assert "! directory_is_writable '$TEST_DIR/readonly_dir'" "directory_is_writable should return failure for read-only directory"
  
  # Reset permissions for cleanup
  chmod 755 "$TEST_DIR/readonly_dir"
}

# Test case for backup_file function
function test_backup_file() {
  # Test that backup_file creates a backup with the correct content
  local backup_path
  backup_path=$(backup_file "$TEST_DIR/test_file.txt")
  
  # Check that backup file exists
  assert_file_exists "$backup_path" "Backup file should exist"
  
  # Check that backup file has the same content as the original
  local original_content
  local backup_content
  original_content=$(cat "$TEST_DIR/test_file.txt")
  backup_content=$(cat "$backup_path")
  
  assert_equals "$original_content" "$backup_content" "Backup file should have the same content as the original"
  
  # Test that backup_file returns error for non-existent file
  assert_failure "backup_file '$TEST_DIR/nonexistent.txt'" "backup_file should fail for non-existent file"
}

# Test case for command_exists function
function test_command_exists() {
  # Test that command_exists returns success for existing command
  assert "command_exists 'ls'" "command_exists should return success for 'ls'"
  
  # Test that command_exists returns failure for non-existent command
  assert "! command_exists 'nonexistentcommand123'" "command_exists should return failure for non-existent command"
}

# Test case for get_os_type function
function test_get_os_type() {
  # Test that get_os_type returns a non-empty string
  local os_type
  os_type=$(get_os_type)
  
  assert "[[ -n '$os_type' ]]" "get_os_type should return a non-empty string"
  
  # Test that get_os_type returns a known OS type
  assert "[[ '$os_type' == 'linux' || '$os_type' == 'darwin' || '$os_type' == 'windows' ]]" \
    "get_os_type should return a known OS type (linux, darwin, windows)"
}

# Test case for generate_random_string function
function test_generate_random_string() {
  # Test that generate_random_string returns a string of the correct length
  local random_string
  random_string=$(generate_random_string 10)
  
  assert "[[ ${#random_string} -eq 10 ]]" "generate_random_string should return a string of length 10"
  
  # Test that generate_random_string returns different strings on subsequent calls
  local random_string2
  random_string2=$(generate_random_string 10)
  
  assert "[[ '$random_string' != '$random_string2' ]]" "generate_random_string should return different strings on subsequent calls"
}

# Main test runner
function run_all_tests() {
  begin_test_suite "System Module Tests"
  
  # Run setup before each test
  setup
  
  # Run the test_file_exists function
  run_test test_file_exists "Test file_exists function"
  
  # Run teardown after the test
  teardown
  
  # Run setup before the next test
  setup
  
  # Run the test_directory_is_writable function
  run_test test_directory_is_writable "Test directory_is_writable function"
  
  # Run teardown after the test
  teardown
  
  # Run setup before the next test
  setup
  
  # Run the test_backup_file function
  run_test test_backup_file "Test backup_file function"
  
  # Run teardown after the test
  teardown
  
  # Run the test_command_exists function (no setup/teardown needed)
  run_test test_command_exists "Test command_exists function"
  
  # Run the test_get_os_type function (no setup/teardown needed)
  run_test test_get_os_type "Test get_os_type function"
  
  # Run the test_generate_random_string function (no setup/teardown needed)
  run_test test_generate_random_string "Test generate_random_string function"
  
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