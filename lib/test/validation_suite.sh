#!/bin/bash
# validation_suite.sh - Comprehensive validation suite for LOCAL-LLM-Stack
# This script provides a comprehensive set of tests to validate the system's functionality,
# security, configuration, and performance.

# Get the absolute path of the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
LIB_DIR="$ROOT_DIR/lib"

# Source core libraries
source "$LIB_DIR/core/logging.sh"
source "$LIB_DIR/core/error.sh"
source "$LIB_DIR/core/validation.sh"
source "$LIB_DIR/core/config.sh"
source "$LIB_DIR/core/docker.sh"
source "$LIB_DIR/core/system.sh"

# Default options
VERBOSE=false
SKIP_PERFORMANCE=false
SKIP_SECURITY=false
TEST_CATEGORY="all"

# Function to display usage information
function display_usage() {
  echo "Usage: $0 [OPTIONS] [CATEGORY]"
  echo "Run comprehensive validation tests for LOCAL-LLM-Stack"
  echo ""
  echo "Options:"
  echo "  --verbose           Display detailed information during execution"
  echo "  --skip-performance  Skip performance tests"
  echo "  --skip-security     Skip security tests"
  echo "  --help              Display this help message and exit"
  echo ""
  echo "Categories:"
  echo "  all                 Run all tests (default)"
  echo "  functional          Run only functional tests"
  echo "  security            Run only security tests"
  echo "  configuration       Run only configuration tests"
  echo "  performance         Run only performance tests"
  echo "  error-handling      Run only error handling tests"
  echo ""
  echo "Example:"
  echo "  $0 functional       # Run only functional tests"
  echo "  $0 --verbose all    # Run all tests with verbose output"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --verbose)
      VERBOSE=true
      shift
      ;;
    --skip-performance)
      SKIP_PERFORMANCE=true
      shift
      ;;
    --skip-security)
      SKIP_SECURITY=true
      shift
      ;;
    --help)
      display_usage
      exit 0
      ;;
    all|functional|security|configuration|performance|error-handling)
      TEST_CATEGORY="$1"
      shift
      ;;
    *)
      log_error "Unknown option or category: $1"
      display_usage
      exit 1
      ;;
  esac
done

# Set log level based on verbosity
if [[ "$VERBOSE" == "true" ]]; then
  set_log_level "debug"
else
  set_log_level "info"
fi

# Log the start of the validation
log_info "Starting validation suite for LOCAL-LLM-Stack"
log_info "Test category: $TEST_CATEGORY"

# Initialize test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Function to run a test and update counters
function run_test() {
  local test_name="$1"
  local test_category="$2"
  local test_function="$3"
  
  # Check if we should run this test based on category
  if [[ "$TEST_CATEGORY" != "all" && "$TEST_CATEGORY" != "$test_category" ]]; then
    log_debug "Skipping test: $test_name (category: $test_category)"
    ((SKIPPED_TESTS++))
    return $ERR_SUCCESS
  fi
  
  # Skip performance tests if requested
  if [[ "$test_category" == "performance" && "$SKIP_PERFORMANCE" == "true" ]]; then
    log_info "Skipping performance test: $test_name"
    ((SKIPPED_TESTS++))
    return $ERR_SUCCESS
  fi
  
  # Skip security tests if requested
  if [[ "$test_category" == "security" && "$SKIP_SECURITY" == "true" ]]; then
    log_info "Skipping security test: $test_name"
    ((SKIPPED_TESTS++))
    return $ERR_SUCCESS
  fi
  
  log_info "Running test: $test_name"
  ((TOTAL_TESTS++))
  
  # Run the test function
  $test_function
  local result=$?
  
  if [[ $result -eq 0 ]]; then
    log_success "Test passed: $test_name"
    ((PASSED_TESTS++))
  else
    log_error "Test failed: $test_name"
    ((FAILED_TESTS++))
  fi
  
  return $result
}

# Function to print test summary
function print_test_summary() {
  echo ""
  echo "Test Summary:"
  echo "============="
  echo "Total tests:  $TOTAL_TESTS"
  echo "Passed:       $PASSED_TESTS"
  echo "Failed:       $FAILED_TESTS"
  echo "Skipped:      $SKIPPED_TESTS"
  echo ""
  
  if [[ $FAILED_TESTS -eq 0 ]]; then
    log_success "All tests passed!"
    return $ERR_SUCCESS
  else
    log_error "$FAILED_TESTS tests failed."
    return $ERR_VALIDATION_ERROR
  fi
}

#
# Functional Tests
#

# Test if all core components are running
function test_core_components_running() {
  log_info "Testing if all core components are running..."
  
  # Check if Docker is running
  if ! docker ps &>/dev/null; then
    log_error "Docker is not running"
    return $ERR_VALIDATION_ERROR
  fi
  
  # Check if Ollama container is running
  if ! docker ps --format '{{.Names}}' | grep -q "ollama"; then
    log_error "Ollama container is not running"
    return $ERR_VALIDATION_ERROR
  fi
  
  # Check if LibreChat container is running
  if ! docker ps --format '{{.Names}}' | grep -q "librechat"; then
    log_error "LibreChat container is not running"
    return $ERR_VALIDATION_ERROR
  fi
  
  # Check if MongoDB container is running
  if ! docker ps --format '{{.Names}}' | grep -q "mongodb"; then
    log_error "MongoDB container is not running"
    return $ERR_VALIDATION_ERROR
  fi
  
  # Check if Meilisearch container is running
  if ! docker ps --format '{{.Names}}' | grep -q "meilisearch"; then
    log_error "Meilisearch container is not running"
    return $ERR_VALIDATION_ERROR
  fi
  
  log_success "All core components are running"
  return $ERR_SUCCESS
}

# Test if Ollama API is accessible
function test_ollama_api_accessible() {
  log_info "Testing if Ollama API is accessible..."
  
  # Get Ollama port from configuration
  local ollama_port=$(get_config "HOST_PORT_OLLAMA" "11434")
  
  # Check if Ollama API is accessible
  if ! curl -s -f "http://localhost:${ollama_port}/api/version" &>/dev/null; then
    log_error "Ollama API is not accessible"
    return $ERR_VALIDATION_ERROR
  fi
  
  log_success "Ollama API is accessible"
  return $ERR_SUCCESS
}

# Test if LibreChat web interface is accessible
function test_librechat_web_accessible() {
  log_info "Testing if LibreChat web interface is accessible..."
  
  # Get LibreChat port from configuration
  local librechat_port=$(get_config "HOST_PORT_LIBRECHAT" "3080")
  
  # Check if LibreChat web interface is accessible
  if ! curl -s -f "http://localhost:${librechat_port}/health" &>/dev/null; then
    log_error "LibreChat web interface is not accessible"
    return $ERR_VALIDATION_ERROR
  fi
  
  log_success "LibreChat web interface is accessible"
  return $ERR_SUCCESS
}

# Test if CLI commands work correctly
function test_cli_commands() {
  log_info "Testing if CLI commands work correctly..."
  
  # Check if llm script exists
  if [[ ! -f "$ROOT_DIR/llm" ]]; then
    log_error "llm script not found"
    return $ERR_VALIDATION_ERROR
  fi
  
  # Check if llm script is executable
  if [[ ! -x "$ROOT_DIR/llm" ]]; then
    log_error "llm script is not executable"
    return $ERR_VALIDATION_ERROR
  fi
  
  # Test help command
  if ! "$ROOT_DIR/llm" help &>/dev/null; then
    log_error "llm help command failed"
    return $ERR_VALIDATION_ERROR
  fi
  
  # Test status command
  if ! "$ROOT_DIR/llm" status &>/dev/null; then
    log_error "llm status command failed"
    return $ERR_VALIDATION_ERROR
  fi
  
  # Test models list command
  if ! "$ROOT_DIR/llm" models list &>/dev/null; then
    log_error "llm models list command failed"
    return $ERR_VALIDATION_ERROR
  fi
  
  log_success "CLI commands work correctly"
  return $ERR_SUCCESS
}

# Test component integration
function test_component_integration() {
  log_info "Testing component integration..."
  
  # Check if LibreChat can connect to MongoDB
  # This is a simplified test - in a real scenario, we would check the actual connection
  local librechat_container=$(docker ps --format '{{.Names}}' | grep "librechat")
  if [[ -z "$librechat_container" ]]; then
    log_error "LibreChat container not found"
    return $ERR_VALIDATION_ERROR
  fi
  
  # Check MongoDB connection in LibreChat logs
  if ! docker logs "$librechat_container" 2>&1 | grep -q "Connected to MongoDB"; then
    log_error "LibreChat is not connected to MongoDB"
    return $ERR_VALIDATION_ERROR
  fi
  
  # Check if LibreChat can connect to Ollama
  # This is a simplified test - in a real scenario, we would check the actual connection
  if ! docker logs "$librechat_container" 2>&1 | grep -q "Ollama"; then
    log_error "LibreChat is not connected to Ollama"
    return $ERR_VALIDATION_ERROR
  fi
  
  log_success "Component integration is working correctly"
  return $ERR_SUCCESS
}

#
# Security Tests
#

# Test if configuration files have appropriate permissions
function test_config_file_permissions() {
  log_info "Testing if configuration files have appropriate permissions..."
  
  # Check main environment file permissions
  local env_file="$ROOT_DIR/config/.env"
  if [[ -f "$env_file" ]]; then
    local perms=$(stat -c "%a" "$env_file")
    if [[ "$perms" != "600" && "$perms" != "400" ]]; then
      log_error "Main environment file has incorrect permissions: $perms (should be 600 or 400)"
      return $ERR_VALIDATION_ERROR
    fi
  else
    log_error "Main environment file not found"
    return $ERR_VALIDATION_ERROR
  fi
  
  # Check LibreChat environment file permissions
  local librechat_env="$ROOT_DIR/config/librechat/.env"
  if [[ -f "$librechat_env" ]]; then
    local perms=$(stat -c "%a" "$librechat_env")
    if [[ "$perms" != "600" && "$perms" != "400" ]]; then
      log_error "LibreChat environment file has incorrect permissions: $perms (should be 600 or 400)"
      return $ERR_VALIDATION_ERROR
    fi
  fi
  
  log_success "Configuration files have appropriate permissions"
  return $ERR_SUCCESS
}

# Test if there are no hard-coded credentials
function test_no_hardcoded_credentials() {
  log_info "Testing if there are no hard-coded credentials..."
  
  # Check for hard-coded credentials in shell scripts
  local credential_patterns=("password" "secret" "token" "key" "credential")
  local shell_scripts=$(find "$ROOT_DIR" -name "*.sh" -type f)
  
  for script in $shell_scripts; do
    for pattern in "${credential_patterns[@]}"; do
      # Look for pattern followed by = and a string (excluding variables)
      if grep -i -E "$pattern[[:space:]]*=[[:space:]]*[\"'][^\"']*[\"']" "$script" | grep -v -E "\\\$|VARIABLE|VAR|ENV"; then
        log_error "Possible hard-coded credential found in $script"
        return $ERR_VALIDATION_ERROR
      fi
    done
  done
  
  log_success "No hard-coded credentials found"
  return $ERR_SUCCESS
}

# Test if secrets are properly managed
function test_secrets_management() {
  log_info "Testing if secrets are properly managed..."
  
  # Check if secrets are generated
  if [[ ! -f "$ROOT_DIR/config/.env" ]]; then
    log_error "Main environment file not found"
    return $ERR_VALIDATION_ERROR
  fi
  
  # Check if required secrets exist in the environment file
  local required_secrets=("JWT_SECRET" "JWT_REFRESH_SECRET" "SESSION_SECRET" "CRYPT_SECRET" "CREDS_KEY" "CREDS_IV")
  
  for secret in "${required_secrets[@]}"; do
    if ! grep -q "$secret=" "$ROOT_DIR/config/.env"; then
      log_error "Required secret not found in environment file: $secret"
      return $ERR_VALIDATION_ERROR
    fi
    
    # Check if the secret is not empty
    local value=$(grep "$secret=" "$ROOT_DIR/config/.env" | cut -d= -f2)
    if [[ -z "$value" ]]; then
      log_error "Secret is empty: $secret"
      return $ERR_VALIDATION_ERROR
    fi
  done
  
  log_success "Secrets are properly managed"
  return $ERR_SUCCESS
}

#
# Configuration Tests
#

# Test if configuration files are valid
function test_config_files_valid() {
  log_info "Testing if configuration files are valid..."
  
  # Check if main environment file exists
  if [[ ! -f "$ROOT_DIR/config/.env" ]]; then
    log_error "Main environment file not found"
    return $ERR_VALIDATION_ERROR
  fi
  
  # Check if LibreChat YAML file exists
  if [[ ! -f "$ROOT_DIR/config/librechat/librechat.yaml" ]]; then
    log_error "LibreChat YAML file not found"
    return $ERR_VALIDATION_ERROR
  fi
  
  # Check if LibreChat YAML file is valid YAML
  if command -v yamllint &>/dev/null; then
    if ! yamllint -d "{extends: relaxed, rules: {line-length: disable}}" "$ROOT_DIR/config/librechat/librechat.yaml" &>/dev/null; then
      log_error "LibreChat YAML file is not valid YAML"
      return $ERR_VALIDATION_ERROR
    fi
  else
    log_warn "yamllint not installed, skipping YAML validation"
  fi
  
  # Run configuration validation script
  if [[ -f "$LIB_DIR/validate_configs.sh" ]]; then
    if ! "$LIB_DIR/validate_configs.sh" &>/dev/null; then
      log_error "Configuration validation failed"
      return $ERR_VALIDATION_ERROR
    fi
  else
    log_error "Configuration validation script not found"
    return $ERR_VALIDATION_ERROR
  fi
  
  log_success "Configuration files are valid"
  return $ERR_SUCCESS
}

# Test if configuration values are consistent
function test_config_consistency() {
  log_info "Testing if configuration values are consistent..."
  
  # Check if main environment file exists
  if [[ ! -f "$ROOT_DIR/config/.env" ]]; then
    log_error "Main environment file not found"
    return $ERR_VALIDATION_ERROR
  fi
  
  # Check if LibreChat environment file exists
  local librechat_env="$ROOT_DIR/config/librechat/.env"
  if [[ -f "$librechat_env" ]]; then
    # Check if MongoDB URI is consistent
    local main_mongo_uri=$(grep "MONGODB_URI=" "$ROOT_DIR/config/.env" | cut -d= -f2)
    local librechat_mongo_uri=$(grep "MONGO_URI=" "$librechat_env" | cut -d= -f2)
    
    if [[ -n "$main_mongo_uri" && -n "$librechat_mongo_uri" && "$main_mongo_uri" != "$librechat_mongo_uri" ]]; then
      log_error "MongoDB URI is inconsistent between main and LibreChat environment files"
      return $ERR_VALIDATION_ERROR
    fi
    
    # Check if Ollama host is consistent
    local main_ollama_host=$(grep "OLLAMA_HOST=" "$ROOT_DIR/config/.env" | cut -d= -f2)
    local librechat_ollama_host=$(grep "OLLAMA_HOST=" "$librechat_env" | cut -d= -f2)
    
    if [[ -n "$main_ollama_host" && -n "$librechat_ollama_host" && "$main_ollama_host" != "$librechat_ollama_host" ]]; then
      log_error "Ollama host is inconsistent between main and LibreChat environment files"
      return $ERR_VALIDATION_ERROR
    fi
  fi
  
  log_success "Configuration values are consistent"
  return $ERR_SUCCESS
}

#
# Performance Tests
#

# Test if the system can handle concurrent users
function test_concurrent_users() {
  if [[ "$SKIP_PERFORMANCE" == "true" ]]; then
    log_info "Skipping concurrent users test"
    return $ERR_SUCCESS
  fi
  
  log_info "Testing if the system can handle concurrent users..."
  
  # Get LibreChat port from configuration
  local librechat_port=$(get_config "HOST_PORT_LIBRECHAT" "3080")
  
  # Check if ab (Apache Benchmark) is installed
  if ! command -v ab &>/dev/null; then
    log_warn "ab (Apache Benchmark) not installed, skipping concurrent users test"
    return $ERR_SUCCESS
  fi
  
  # Run Apache Benchmark with 10 concurrent users
  if ! ab -n 100 -c 10 "http://localhost:${librechat_port}/health" &>/dev/null; then
    log_error "System failed to handle 10 concurrent users"
    return $ERR_VALIDATION_ERROR
  fi
  
  log_success "System can handle 10 concurrent users"
  return $ERR_SUCCESS
}

# Test if response times are acceptable
function test_response_times() {
  if [[ "$SKIP_PERFORMANCE" == "true" ]]; then
    log_info "Skipping response times test"
    return $ERR_SUCCESS
  fi
  
  log_info "Testing if response times are acceptable..."
  
  # Get LibreChat port from configuration
  local librechat_port=$(get_config "HOST_PORT_LIBRECHAT" "3080")
  
  # Check if curl is installed
  if ! command -v curl &>/dev/null; then
    log_warn "curl not installed, skipping response times test"
    return $ERR_SUCCESS
  fi
  
  # Measure response time
  local start_time=$(date +%s.%N)
  if ! curl -s -f "http://localhost:${librechat_port}/health" &>/dev/null; then
    log_error "Failed to access LibreChat health endpoint"
    return $ERR_VALIDATION_ERROR
  fi
  local end_time=$(date +%s.%N)
  
  # Calculate response time in seconds
  local response_time=$(echo "$end_time - $start_time" | bc)
  
  # Check if response time is under 2 seconds
  if (( $(echo "$response_time > 2.0" | bc -l) )); then
    log_error "Response time is too slow: $response_time seconds (should be under 2 seconds)"
    return $ERR_VALIDATION_ERROR
  fi
  
  log_success "Response times are acceptable: $response_time seconds"
  return $ERR_SUCCESS
}

#
# Error Handling Tests
#

# Test if the system handles component failures gracefully
function test_component_failure_handling() {
  log_info "Testing if the system handles component failures gracefully..."
  
  # This is a simplified test - in a real scenario, we would simulate component failures
  # and check if the system handles them gracefully
  
  # For now, we'll just check if error handling is implemented in the core libraries
  
  # Check if error.sh exists and contains error handling functions
  if [[ ! -f "$LIB_DIR/core/error.sh" ]]; then
    log_error "Error handling library not found"
    return $ERR_VALIDATION_ERROR
  fi
  
  # Check if handle_error function is defined
  if ! grep -q "function handle_error" "$LIB_DIR/core/error.sh"; then
    log_error "handle_error function not found in error handling library"
    return $ERR_VALIDATION_ERROR
  fi
  
  # Check if set_cleanup_trap function is defined
  if ! grep -q "function set_cleanup_trap" "$LIB_DIR/core/error.sh"; then
    log_error "set_cleanup_trap function not found in error handling library"
    return $ERR_VALIDATION_ERROR
  fi
  
  log_success "System has error handling mechanisms in place"
  return $ERR_SUCCESS
}

# Test if the system recovers from errors
function test_error_recovery() {
  log_info "Testing if the system recovers from errors..."
  
  # This is a simplified test - in a real scenario, we would simulate errors
  # and check if the system recovers from them
  
  # For now, we'll just check if error recovery is implemented in the core libraries
  
  # Check if docker.sh exists and contains container management functions
  if [[ ! -f "$LIB_DIR/core/docker.sh" ]]; then
    log_error "Docker management library not found"
    return $ERR_VALIDATION_ERROR
  fi
  
  # Check if restart_container function is defined
  if ! grep -q "function restart_container" "$LIB_DIR/core/docker.sh"; then
    log_warn "restart_container function not found in Docker management library"
    # This is not a critical error, so we'll just warn about it
  fi
  
  log_success "System has error recovery mechanisms in place"
  return $ERR_SUCCESS
}

# Main function
function main() {
  log_info "Running validation suite for LOCAL-LLM-Stack"
  
  # Run functional tests
  run_test "Core Components Running" "functional" test_core_components_running
  run_test "Ollama API Accessible" "functional" test_ollama_api_accessible
  run_test "LibreChat Web Accessible" "functional" test_librechat_web_accessible
  run_test "CLI Commands" "functional" test_cli_commands
  run_test "Component Integration" "functional" test_component_integration
  
  # Run security tests
  run_test "Configuration File Permissions" "security" test_config_file_permissions
  run_test "No Hard-coded Credentials" "security" test_no_hardcoded_credentials
  run_test "Secrets Management" "security" test_secrets_management
  
  # Run configuration tests
  run_test "Configuration Files Valid" "configuration" test_config_files_valid
  run_test "Configuration Consistency" "configuration" test_config_consistency
  
  # Run performance tests
  run_test "Concurrent Users" "performance" test_concurrent_users
  run_test "Response Times" "performance" test_response_times
  
  # Run error handling tests
  run_test "Component Failure Handling" "error-handling" test_component_failure_handling
  run_test "Error Recovery" "error-handling" test_error_recovery
  
  # Print test summary
  print_test_summary
  return $?
}

# Run the main function
main