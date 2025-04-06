#!/bin/bash
# modules/template/tests/unit/test_module.sh
# Unit test template for modules

# Get the absolute path of the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
ROOT_DIR="$(cd "$MODULE_DIR/../.." && pwd)"

# Source test framework
source "$ROOT_DIR/lib/test/test_framework.sh"

# Source module scripts to test
# source "$MODULE_DIR/scripts/example_script.sh"

# Module name (derived from directory name)
MODULE_NAME=$(basename "$MODULE_DIR")

# Begin test suite
begin_test_suite "$MODULE_NAME Module Unit Tests"

# Test case: Module configuration validation
test_case "module_config_validation" "Validates module configuration"
function test_module_config_validation() {
  # Setup
  local config_file="$MODULE_DIR/config/env.conf"
  
  # Test
  assert_file_exists "$config_file" "Module configuration file should exist"
  
  # Check for required configuration entries
  assert_file_contains "$config_file" "EXAMPLE_SERVICE_VERSION" "Configuration should define service version"
  assert_file_contains "$config_file" "HOST_PORT_EXAMPLE" "Configuration should define host port"
  
  # Success
  return 0
}

# Test case: Module directory structure
test_case "module_directory_structure" "Validates module directory structure"
function test_module_directory_structure() {
  # Test
  assert_directory_exists "$MODULE_DIR/config" "Module should have a config directory"
  assert_directory_exists "$MODULE_DIR/scripts" "Module should have a scripts directory"
  assert_directory_exists "$MODULE_DIR/tests" "Module should have a tests directory"
  assert_file_exists "$MODULE_DIR/README.md" "Module should have a README.md file"
  assert_file_exists "$MODULE_DIR/docker-compose.yml" "Module should have a docker-compose.yml file"
  
  # Success
  return 0
}

# Test case: Module setup script
test_case "module_setup_script" "Validates module setup script"
function test_module_setup_script() {
  # Setup
  local setup_script="$MODULE_DIR/scripts/setup.sh"
  
  # Test
  assert_file_exists "$setup_script" "Module should have a setup script"
  assert_file_executable "$setup_script" "Setup script should be executable"
  
  # Check for required functions
  assert_file_contains "$setup_script" "validate_prerequisites" "Setup script should validate prerequisites"
  assert_file_contains "$setup_script" "create_directories" "Setup script should create directories"
  assert_file_contains "$setup_script" "configure_module" "Setup script should configure the module"
  
  # Success
  return 0
}

# Add more test cases as needed

# End test suite
end_test_suite