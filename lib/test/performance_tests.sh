#!/bin/bash
# performance_tests.sh - Performance tests for LOCAL-LLM-Stack
# This script tests the performance of the system under various loads

# Get the absolute path of the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
LIB_DIR="$ROOT_DIR/lib"

# Source core libraries
source "$LIB_DIR/core/logging.sh"
source "$LIB_DIR/core/error.sh"
source "$LIB_DIR/core/validation.sh"
source "$LIB_DIR/core/config.sh"
source "$LIB_DIR/core/system.sh"

# Default options
VERBOSE=false
CONCURRENT_USERS=10
TEST_DURATION=60
TEST_TYPE="all"
OUTPUT_DIR="$ROOT_DIR/test_results"

# Function to display usage information
function display_usage() {
  echo "Usage: $0 [OPTIONS] [TEST_TYPE]"
  echo "Run performance tests for LOCAL-LLM-Stack"
  echo ""
  echo "Options:"
  echo "  --verbose               Display detailed information during execution"
  echo "  --concurrent-users N    Number of concurrent users to simulate (default: 10)"
  echo "  --duration N            Test duration in seconds (default: 60)"
  echo "  --output-dir DIR        Directory to store test results (default: ./test_results)"
  echo "  --help                  Display this help message and exit"
  echo ""
  echo "Test Types:"
  echo "  all                     Run all performance tests (default)"
  echo "  api                     Test API performance only"
  echo "  web                     Test web interface performance only"
  echo "  ollama                  Test Ollama performance only"
  echo "  librechat               Test LibreChat performance only"
  echo ""
  echo "Example:"
  echo "  $0 --concurrent-users 20 --duration 120 api  # Run API tests with 20 users for 2 minutes"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --verbose)
      VERBOSE=true
      shift
      ;;
    --concurrent-users)
      CONCURRENT_USERS="$2"
      shift 2
      ;;
    --duration)
      TEST_DURATION="$2"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --help)
      display_usage
      exit 0
      ;;
    all|api|web|ollama|librechat)
      TEST_TYPE="$1"
      shift
      ;;
    *)
      log_error "Unknown option or test type: $1"
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

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Log the start of the performance tests
log_info "Starting performance tests for LOCAL-LLM-Stack"
log_info "Test type: $TEST_TYPE"
log_info "Concurrent users: $CONCURRENT_USERS"
log_info "Test duration: $TEST_DURATION seconds"
log_info "Output directory: $OUTPUT_DIR"

# Function to check if required tools are installed
function check_prerequisites() {
  log_info "Checking prerequisites..."
  
  # Check if ab (Apache Benchmark) is installed
  if ! command -v ab &>/dev/null; then
    log_error "ab (Apache Benchmark) is not installed"
    log_info "Install with: apt-get install apache2-utils"
    return $ERR_DEPENDENCY_ERROR
  fi
  
  # Check if curl is installed
  if ! command -v curl &>/dev/null; then
    log_error "curl is not installed"
    log_info "Install with: apt-get install curl"
    return $ERR_DEPENDENCY_ERROR
  fi
  
  # Check if jq is installed
  if ! command -v jq &>/dev/null; then
    log_warn "jq is not installed, some tests may not work properly"
    log_info "Install with: apt-get install jq"
  fi
  
  # Check if Docker is running
  if ! docker ps &>/dev/null; then
    log_error "Docker is not running"
    return $ERR_DEPENDENCY_ERROR
  fi
  
  # Check if required containers are running
  local required_containers=("ollama" "librechat" "mongodb" "meilisearch")
  for container in "${required_containers[@]}"; do
    if ! docker ps --format '{{.Names}}' | grep -q "$container"; then
      log_error "$container container is not running"
      return $ERR_DEPENDENCY_ERROR
    fi
  done
  
  log_success "All prerequisites checked successfully"
  return $ERR_SUCCESS
}

# Function to get component ports
function get_component_ports() {
  log_info "Getting component ports..."
  
  # Get LibreChat port
  LIBRECHAT_PORT=$(get_config "HOST_PORT_LIBRECHAT" "3080")
  log_info "LibreChat port: $LIBRECHAT_PORT"
  
  # Get Ollama port
  OLLAMA_PORT=$(get_config "HOST_PORT_OLLAMA" "11434")
  log_info "Ollama port: $OLLAMA_PORT"
  
  return $ERR_SUCCESS
}

# Function to test Ollama API performance
function test_ollama_api_performance() {
  log_info "Testing Ollama API performance..."
  
  # Create test data file
  local test_data_file="$OUTPUT_DIR/ollama_test_data.json"
  cat > "$test_data_file" << EOF
{
  "model": "tinyllama",
  "prompt": "What is the capital of France?",
  "stream": false
}
EOF
  
  # Run Apache Benchmark test
  log_info "Running Apache Benchmark test for Ollama API..."
  ab -n $((CONCURRENT_USERS * 10)) -c $CONCURRENT_USERS -T "application/json" -p "$test_data_file" -t $TEST_DURATION "http://localhost:$OLLAMA_PORT/api/generate" > "$OUTPUT_DIR/ollama_api_performance.txt" 2>&1
  
  # Check if the test was successful
  if [[ $? -ne 0 ]]; then
    log_error "Ollama API performance test failed"
    return $ERR_GENERAL
  fi
  
  # Extract and log key metrics
  local requests_per_second=$(grep "Requests per second" "$OUTPUT_DIR/ollama_api_performance.txt" | awk '{print $4}')
  local mean_response_time=$(grep "Time per request" "$OUTPUT_DIR/ollama_api_performance.txt" | head -n 1 | awk '{print $4}')
  local failed_requests=$(grep "Failed requests" "$OUTPUT_DIR/ollama_api_performance.txt" | awk '{print $3}')
  
  log_info "Ollama API performance metrics:"
  log_info "  Requests per second: $requests_per_second"
  log_info "  Mean response time: $mean_response_time ms"
  log_info "  Failed requests: $failed_requests"
  
  # Check if performance meets requirements
  if (( $(echo "$mean_response_time > 2000" | bc -l) )); then
    log_warn "Ollama API response time exceeds 2 seconds: $mean_response_time ms"
  else
    log_success "Ollama API response time is within limits: $mean_response_time ms"
  fi
  
  if [[ "$failed_requests" != "0" ]]; then
    log_warn "Ollama API had failed requests: $failed_requests"
  else
    log_success "Ollama API had no failed requests"
  fi
  
  log_success "Ollama API performance test completed"
  return $ERR_SUCCESS
}

# Function to test LibreChat API performance
function test_librechat_api_performance() {
  log_info "Testing LibreChat API performance..."
  
  # Get admin credentials
  local admin_email=$(get_config "ADMIN_EMAIL" "admin@local.host")
  local admin_password=$(get_config "ADMIN_PASSWORD" "password")
  
  # Login to get token
  log_info "Logging in to LibreChat..."
  local login_response=$(curl -s -X POST "http://localhost:$LIBRECHAT_PORT/api/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$admin_email\",\"password\":\"$admin_password\"}")
  
  local token=$(echo "$login_response" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
  
  if [[ -z "$token" ]]; then
    log_error "Failed to login to LibreChat"
    return $ERR_GENERAL
  fi
  
  # Create test data file
  local test_data_file="$OUTPUT_DIR/librechat_test_data.json"
  cat > "$test_data_file" << EOF
{
  "endpoint": "ollama",
  "message": "What is the capital of France?",
  "model": "tinyllama"
}
EOF
  
  # Run Apache Benchmark test
  log_info "Running Apache Benchmark test for LibreChat API..."
  ab -n $((CONCURRENT_USERS * 10)) -c $CONCURRENT_USERS -T "application/json" -H "Authorization: Bearer $token" -p "$test_data_file" -t $TEST_DURATION "http://localhost:$LIBRECHAT_PORT/api/ask" > "$OUTPUT_DIR/librechat_api_performance.txt" 2>&1
  
  # Check if the test was successful
  if [[ $? -ne 0 ]]; then
    log_error "LibreChat API performance test failed"
    return $ERR_GENERAL
  fi
  
  # Extract and log key metrics
  local requests_per_second=$(grep "Requests per second" "$OUTPUT_DIR/librechat_api_performance.txt" | awk '{print $4}')
  local mean_response_time=$(grep "Time per request" "$OUTPUT_DIR/librechat_api_performance.txt" | head -n 1 | awk '{print $4}')
  local failed_requests=$(grep "Failed requests" "$OUTPUT_DIR/librechat_api_performance.txt" | awk '{print $3}')
  
  log_info "LibreChat API performance metrics:"
  log_info "  Requests per second: $requests_per_second"
  log_info "  Mean response time: $mean_response_time ms"
  log_info "  Failed requests: $failed_requests"
  
  # Check if performance meets requirements
  if (( $(echo "$mean_response_time > 2000" | bc -l) )); then
    log_warn "LibreChat API response time exceeds 2 seconds: $mean_response_time ms"
  else
    log_success "LibreChat API response time is within limits: $mean_response_time ms"
  fi
  
  if [[ "$failed_requests" != "0" ]]; then
    log_warn "LibreChat API had failed requests: $failed_requests"
  else
    log_success "LibreChat API had no failed requests"
  fi
  
  log_success "LibreChat API performance test completed"
  return $ERR_SUCCESS
}

# Function to test LibreChat web interface performance
function test_librechat_web_performance() {
  log_info "Testing LibreChat web interface performance..."
  
  # Run Apache Benchmark test
  log_info "Running Apache Benchmark test for LibreChat web interface..."
  ab -n $((CONCURRENT_USERS * 10)) -c $CONCURRENT_USERS -t $TEST_DURATION "http://localhost:$LIBRECHAT_PORT/" > "$OUTPUT_DIR/librechat_web_performance.txt" 2>&1
  
  # Check if the test was successful
  if [[ $? -ne 0 ]]; then
    log_error "LibreChat web performance test failed"
    return $ERR_GENERAL
  fi
  
  # Extract and log key metrics
  local requests_per_second=$(grep "Requests per second" "$OUTPUT_DIR/librechat_web_performance.txt" | awk '{print $4}')
  local mean_response_time=$(grep "Time per request" "$OUTPUT_DIR/librechat_web_performance.txt" | head -n 1 | awk '{print $4}')
  local failed_requests=$(grep "Failed requests" "$OUTPUT_DIR/librechat_web_performance.txt" | awk '{print $3}')
  
  log_info "LibreChat web performance metrics:"
  log_info "  Requests per second: $requests_per_second"
  log_info "  Mean response time: $mean_response_time ms"
  log_info "  Failed requests: $failed_requests"
  
  # Check if performance meets requirements
  if (( $(echo "$mean_response_time > 2000" | bc -l) )); then
    log_warn "LibreChat web response time exceeds 2 seconds: $mean_response_time ms"
  else
    log_success "LibreChat web response time is within limits: $mean_response_time ms"
  fi
  
  if [[ "$failed_requests" != "0" ]]; then
    log_warn "LibreChat web had failed requests: $failed_requests"
  else
    log_success "LibreChat web had no failed requests"
  fi
  
  log_success "LibreChat web performance test completed"
  return $ERR_SUCCESS
}

# Function to generate performance report
function generate_performance_report() {
  log_info "Generating performance report..."
  
  local report_file="$OUTPUT_DIR/performance_report.md"
  
  # Create report file
  cat > "$report_file" << EOF
# LOCAL-LLM-Stack Performance Test Report

## Test Configuration

- **Test Type:** $TEST_TYPE
- **Concurrent Users:** $CONCURRENT_USERS
- **Test Duration:** $TEST_DURATION seconds
- **Date:** $(date)

## Summary

EOF
  
  # Add Ollama API metrics if available
  if [[ -f "$OUTPUT_DIR/ollama_api_performance.txt" ]]; then
    local requests_per_second=$(grep "Requests per second" "$OUTPUT_DIR/ollama_api_performance.txt" | awk '{print $4}')
    local mean_response_time=$(grep "Time per request" "$OUTPUT_DIR/ollama_api_performance.txt" | head -n 1 | awk '{print $4}')
    local failed_requests=$(grep "Failed requests" "$OUTPUT_DIR/ollama_api_performance.txt" | awk '{print $3}')
    
    cat >> "$report_file" << EOF
### Ollama API Performance

- **Requests per second:** $requests_per_second
- **Mean response time:** $mean_response_time ms
- **Failed requests:** $failed_requests

EOF
  fi
  
  # Add LibreChat API metrics if available
  if [[ -f "$OUTPUT_DIR/librechat_api_performance.txt" ]]; then
    local requests_per_second=$(grep "Requests per second" "$OUTPUT_DIR/librechat_api_performance.txt" | awk '{print $4}')
    local mean_response_time=$(grep "Time per request" "$OUTPUT_DIR/librechat_api_performance.txt" | head -n 1 | awk '{print $4}')
    local failed_requests=$(grep "Failed requests" "$OUTPUT_DIR/librechat_api_performance.txt" | awk '{print $3}')
    
    cat >> "$report_file" << EOF
### LibreChat API Performance

- **Requests per second:** $requests_per_second
- **Mean response time:** $mean_response_time ms
- **Failed requests:** $failed_requests

EOF
  fi
  
  # Add LibreChat web metrics if available
  if [[ -f "$OUTPUT_DIR/librechat_web_performance.txt" ]]; then
    local requests_per_second=$(grep "Requests per second" "$OUTPUT_DIR/librechat_web_performance.txt" | awk '{print $4}')
    local mean_response_time=$(grep "Time per request" "$OUTPUT_DIR/librechat_web_performance.txt" | head -n 1 | awk '{print $4}')
    local failed_requests=$(grep "Failed requests" "$OUTPUT_DIR/librechat_web_performance.txt" | awk '{print $3}')
    
    cat >> "$report_file" << EOF
### LibreChat Web Performance

- **Requests per second:** $requests_per_second
- **Mean response time:** $mean_response_time ms
- **Failed requests:** $failed_requests

EOF
  fi
  
  # Add conclusion
  cat >> "$report_file" << EOF
## Conclusion

EOF
  
  # Check if all tests meet the 2-second response time requirement
  local all_tests_pass=true
  
  if [[ -f "$OUTPUT_DIR/ollama_api_performance.txt" ]]; then
    local mean_response_time=$(grep "Time per request" "$OUTPUT_DIR/ollama_api_performance.txt" | head -n 1 | awk '{print $4}')
    if (( $(echo "$mean_response_time > 2000" | bc -l) )); then
      all_tests_pass=false
    fi
  fi
  
  if [[ -f "$OUTPUT_DIR/librechat_api_performance.txt" ]]; then
    local mean_response_time=$(grep "Time per request" "$OUTPUT_DIR/librechat_api_performance.txt" | head -n 1 | awk '{print $4}')
    if (( $(echo "$mean_response_time > 2000" | bc -l) )); then
      all_tests_pass=false
    fi
  fi
  
  if [[ -f "$OUTPUT_DIR/librechat_web_performance.txt" ]]; then
    local mean_response_time=$(grep "Time per request" "$OUTPUT_DIR/librechat_web_performance.txt" | head -n 1 | awk '{print $4}')
    if (( $(echo "$mean_response_time > 2000" | bc -l) )); then
      all_tests_pass=false
    fi
  fi
  
  if [[ "$all_tests_pass" == "true" ]]; then
    cat >> "$report_file" << EOF
The system meets the performance requirement of handling $CONCURRENT_USERS concurrent users with response times under 2 seconds.
EOF
  else
    cat >> "$report_file" << EOF
The system does not meet the performance requirement of handling $CONCURRENT_USERS concurrent users with response times under 2 seconds. Further optimization is recommended.
EOF
  fi
  
  log_success "Performance report generated: $report_file"
  return $ERR_SUCCESS
}

# Main function
function main() {
  log_info "Starting performance tests"
  
  # Check prerequisites
  check_prerequisites
  if [[ $? -ne 0 ]]; then
    log_error "Prerequisites check failed"
    exit $ERR_DEPENDENCY_ERROR
  fi
  
  # Get component ports
  get_component_ports
  if [[ $? -ne 0 ]]; then
    log_error "Failed to get component ports"
    exit $ERR_GENERAL
  fi
  
  # Run tests based on test type
  case "$TEST_TYPE" in
    all)
      test_ollama_api_performance
      test_librechat_api_performance
      test_librechat_web_performance
      ;;
    api)
      test_ollama_api_performance
      test_librechat_api_performance
      ;;
    web)
      test_librechat_web_performance
      ;;
    ollama)
      test_ollama_api_performance
      ;;
    librechat)
      test_librechat_api_performance
      test_librechat_web_performance
      ;;
  esac
  
  # Generate performance report
  generate_performance_report
  if [[ $? -ne 0 ]]; then
    log_error "Failed to generate performance report"
    exit $ERR_GENERAL
  fi
  
  log_success "Performance tests completed successfully"
  log_info "Performance report: $OUTPUT_DIR/performance_report.md"
}

# Run the main function
main