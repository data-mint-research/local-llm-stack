#!/bin/bash
# tools/doc-sync/tests/unit/test_tool.sh
# Unit test doc-sync for tools

# Get the absolute path of the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
ROOT_DIR="$(cd "$TOOL_DIR/../.." && pwd)"

# Source test framework
source "$ROOT_DIR/lib/test/test_framework.sh"

# Source tool libraries to test
source "$TOOL_DIR/lib/common.sh"

# Tool name (derived from directory name)
TOOL_NAME=$(basename "$TOOL_DIR")

# Begin test suite
begin_test_suite "$TOOL_NAME Tool Unit Tests"

# Test case: Tool configuration validation
test_case "tool_config_validation" "Validates tool configuration"
function test_tool_config_validation() {
  # Setup
  local config_file="$TOOL_DIR/config/config.yaml"
  
  # Test
  assert_file_exists "$config_file" "Tool configuration file should exist"
  
  # Check for required configuration entries
  if command -v yq &> /dev/null; then
    local tool_name=$(yq eval '.tool.name' "$config_file")
    assert_not_empty "$tool_name" "Tool name should be defined in configuration"
    
    local tool_version=$(yq eval '.tool.version' "$config_file")
    assert_not_empty "$tool_version" "Tool version should be defined in configuration"
  else
    # Skip tests that require yq
    skip "yq not available, skipping configuration validation tests"
  fi
  
  # Success
  return 0
}

# Test case: Tool directory structure
test_case "tool_directory_structure" "Validates tool directory structure"
function test_tool_directory_structure() {
  # Test
  assert_directory_exists "$TOOL_DIR/config" "Tool should have a config directory"
  assert_directory_exists "$TOOL_DIR/lib" "Tool should have a lib directory"
  assert_directory_exists "$TOOL_DIR/tests" "Tool should have a tests directory"
  assert_file_exists "$TOOL_DIR/README.md" "Tool should have a README.md file"
  assert_file_exists "$TOOL_DIR/main.sh" "Tool should have a main.sh file"
  
  # Success
  return 0
}

# Test case: Tool main script
test_case "tool_main_script" "Validates tool main script"
function test_tool_main_script() {
  # Setup
  local main_script="$TOOL_DIR/main.sh"
  
  # Test
  assert_file_exists "$main_script" "Tool should have a main script"
  assert_file_executable "$main_script" "Main script should be executable"
  
  # Check for required functions
  assert_file_contains "$main_script" "display_usage" "Main script should have a display_usage function"
  assert_file_contains "$main_script" "parse_arguments" "Main script should have a parse_arguments function"
  assert_file_contains "$main_script" "main" "Main script should have a main function"
  
  # Success
  return 0
}

# Test case: Tool common library
test_case "tool_common_library" "Validates tool common library"
function test_tool_common_library() {
  # Setup
  local common_lib="$TOOL_DIR/lib/common.sh"
  
  # Test
  assert_file_exists "$common_lib" "Tool should have a common library"
  
  # Check for required functions
  assert_function_exists "read_config_value" "Common library should have a read_config_value function"
  assert_function_exists "find_matching_files" "Common library should have a find_matching_files function"
  assert_function_exists "backup_file" "Common library should have a backup_file function"
  
  # Success
  return 0
}

# Test case: Read config value function
test_case "read_config_value" "Tests the read_config_value function"
function test_read_config_value() {
  # Skip if yq is not available
  if ! command -v yq &> /dev/null; then
    skip "yq not available, skipping read_config_value test"
    return 0
  fi
  
  # Setup
  local config_file="$TOOL_DIR/config/config.yaml"
  local test_key="tool.name"
  
  # Test
  local value=$(read_config_value "$config_file" "$test_key")
  assert_not_empty "$value" "read_config_value should return a value for $test_key"
  
  # Test with non-existent key
  local non_existent_key="non.existent.key"
  local result=$(read_config_value "$config_file" "$non_existent_key" 2>/dev/null)
  local exit_code=$?
  assert_not_equals 0 "$exit_code" "read_config_value should return non-zero for non-existent key"
  
  # Success
  return 0
}

# Test case: Find matching files function
test_case "find_matching_files" "Tests the find_matching_files function"
function test_find_matching_files() {
  # Setup
  local test_dir="$TOOL_DIR"
  local pattern="*.sh"
  
  # Test
  local files=$(find_matching_files "$test_dir" "$pattern")
  assert_not_empty "$files" "find_matching_files should find .sh files in the tool directory"
  
  # Test with exclude pattern
  local exclude_pattern="*/tests/*"
  local filtered_files=$(find_matching_files "$test_dir" "$pattern" "$exclude_pattern")
  assert_not_empty "$filtered_files" "find_matching_files should find .sh files excluding tests"
  
  # Test with non-existent directory
  local non_existent_dir="/non/existent/directory"
  local result=$(find_matching_files "$non_existent_dir" "$pattern" 2>/dev/null)
  local exit_code=$?
  assert_not_equals 0 "$exit_code" "find_matching_files should return non-zero for non-existent directory"
  
  # Success
  return 0
}

# Test case: Backup and restore file functions
test_case "backup_restore_file" "Tests the backup_file and restore_file functions"
function test_backup_restore_file() {
  # Setup
  local test_file="/tmp/test-$TOOL_NAME-file.txt"
  local test_content="Test content for backup and restore"
  echo "$test_content" > "$test_file"
  
  # Test backup_file
  backup_file "$test_file"
  assert_file_exists "${test_file}.bak" "backup_file should create a .bak file"
  
  # Modify the original file
  local modified_content="Modified content"
  echo "$modified_content" > "$test_file"
  
  # Test restore_file
  restore_file "$test_file"
  local restored_content=$(cat "$test_file")
  assert_equals "$test_content" "$restored_content" "restore_file should restore the original content"
  
  # Cleanup
  rm -f "$test_file" "${test_file}.bak"
  
  # Success
  return 0
}

# Add more test cases as needed

# End test suite
end_test_suite