#!/bin/bash
# modules/security/tests/integration/test_integration.sh
# Integration test security for modules

# Get the absolute path of the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
ROOT_DIR="$(cd "$MODULE_DIR/../.." && pwd)"

# Source test framework
source "$ROOT_DIR/lib/test/test_framework.sh"

# Source core libraries
source "$ROOT_DIR/lib/core/logging.sh"
source "$ROOT_DIR/lib/core/error.sh"
source "$ROOT_DIR/lib/core/docker.sh"

# Module name (derived from directory name)
MODULE_NAME=$(basename "$MODULE_DIR")

# Begin test suite
begin_test_suite "$MODULE_NAME Module Integration Tests"

# Test case: Module startup
test_case "module_startup" "Tests module startup and service availability"
function test_module_startup() {
  # Setup - start the module services
  log_info "Starting $MODULE_NAME module services for testing..."
  
  # Use the docker-compose.yml from the module directory
  docker_compose_up "$MODULE_DIR/docker-compose.yml" "-d"
  assert_success $? "Module services should start successfully"
  
  # Wait for services to be ready (adjust timeout as needed)
  sleep 10
  
  # Test - check if services are running
  local service_running=$(docker ps --format '{{.Names}}' | grep -c "example-service")
  assert_equals 1 "$service_running" "Example service should be running"
  
  # Test - check service health
  local health_status=$(docker inspect --format='{{.State.Health.Status}}' example-service)
  assert_equals "healthy" "$health_status" "Example service should be healthy"
  
  # Test - check service API (adjust as needed for your service)
  local response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health)
  assert_equals "200" "$response" "Example service health endpoint should return 200 OK"
  
  # Cleanup - stop the module services
  log_info "Stopping $MODULE_NAME module services..."
  docker_compose_down "$MODULE_DIR/docker-compose.yml"
  assert_success $? "Module services should stop successfully"
  
  # Success
  return 0
}

# Test case: Module integration with core system
test_case "module_core_integration" "Tests module integration with core system"
function test_module_core_integration() {
  # Setup - ensure core system is running
  log_info "Checking core system status..."
  local core_running=$(docker ps --format '{{.Names}}' | grep -c "ollama")
  
  if [[ "$core_running" -eq 0 ]]; then
    log_warning "Core system is not running. Starting core services..."
    docker_compose_up "$ROOT_DIR/core/docker-compose.yml" "-d"
    assert_success $? "Core services should start successfully"
    sleep 10
  fi
  
  # Setup - start the module services
  log_info "Starting $MODULE_NAME module services for testing..."
  docker_compose_up "$MODULE_DIR/docker-compose.yml" "-d"
  assert_success $? "Module services should start successfully"
  sleep 10
  
  # Test - check network connectivity between module and core
  log_info "Testing network connectivity between module and core..."
  docker exec example-service ping -c 3 ollama
  assert_success $? "Module should be able to communicate with core services"
  
  # Test - check API integration (adjust as needed for your module)
  # Example: Test if module can access Ollama API
  log_info "Testing API integration..."
  local response=$(docker exec example-service curl -s -o /dev/null -w "%{http_code}" http://ollama:11434/api/health)
  assert_equals "200" "$response" "Module should be able to access core service APIs"
  
  # Cleanup - stop the module services
  log_info "Stopping $MODULE_NAME module services..."
  docker_compose_down "$MODULE_DIR/docker-compose.yml"
  assert_success $? "Module services should stop successfully"
  
  # Success
  return 0
}

# Test case: Module configuration
test_case "module_configuration" "Tests module configuration handling"
function test_module_configuration() {
  # Setup - create a test configuration
  local test_config_dir="/tmp/test-$MODULE_NAME-config"
  mkdir -p "$test_config_dir"
  
  # Create a test configuration file with custom settings
  cat > "$test_config_dir/env.conf" << EOF
# Test configuration
EXAMPLE_SERVICE_VERSION=latest
HOST_PORT_EXAMPLE=8081
EXAMPLE_VAR_1=test_value
EOF
  
  # Test - start the module with custom configuration
  log_info "Starting $MODULE_NAME module with custom configuration..."
  EXAMPLE_CONFIG_DIR="$test_config_dir" docker_compose_up "$MODULE_DIR/docker-compose.yml" "-d"
  assert_success $? "Module should start with custom configuration"
  sleep 10
  
  # Test - verify custom configuration was applied
  local port_mapping=$(docker port example-service 8080/tcp)
  assert_contains "$port_mapping" "8081" "Custom port configuration should be applied"
  
  # Test - verify environment variables
  local env_value=$(docker exec example-service env | grep EXAMPLE_VAR_1)
  assert_contains "$env_value" "test_value" "Custom environment variables should be applied"
  
  # Cleanup - stop the module services
  log_info "Stopping $MODULE_NAME module services..."
  EXAMPLE_CONFIG_DIR="$test_config_dir" docker_compose_down "$MODULE_DIR/docker-compose.yml"
  assert_success $? "Module services should stop successfully"
  
  # Cleanup - remove test configuration
  rm -rf "$test_config_dir"
  
  # Success
  return 0
}

# Add more test cases as needed

# End test suite
end_test_suite