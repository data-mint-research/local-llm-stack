#!/bin/bash
# security_tests.sh - Security tests for LOCAL-LLM-Stack
# This script performs security audits and tests to ensure the system is secure

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
SCAN_DEPTH="normal"
OUTPUT_DIR="$ROOT_DIR/security_results"
SKIP_NETWORK=false

# Function to display usage information
function display_usage() {
  echo "Usage: $0 [OPTIONS]"
  echo "Run security tests for LOCAL-LLM-Stack"
  echo ""
  echo "Options:"
  echo "  --verbose           Display detailed information during execution"
  echo "  --scan-depth DEPTH  Scan depth: quick, normal, thorough (default: normal)"
  echo "  --output-dir DIR    Directory to store security results (default: ./security_results)"
  echo "  --skip-network      Skip network security tests"
  echo "  --help              Display this help message and exit"
  echo ""
  echo "Example:"
  echo "  $0 --scan-depth thorough  # Run thorough security scan"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --verbose)
      VERBOSE=true
      shift
      ;;
    --scan-depth)
      SCAN_DEPTH="$2"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --skip-network)
      SKIP_NETWORK=true
      shift
      ;;
    --help)
      display_usage
      exit 0
      ;;
    *)
      log_error "Unknown option: $1"
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

# Log the start of the security tests
log_info "Starting security tests for LOCAL-LLM-Stack"
log_info "Scan depth: $SCAN_DEPTH"
log_info "Output directory: $OUTPUT_DIR"

# Initialize counters
TOTAL_ISSUES=0
HIGH_SEVERITY_ISSUES=0
MEDIUM_SEVERITY_ISSUES=0
LOW_SEVERITY_ISSUES=0

# Function to increment issue counter
function increment_issue_counter() {
  local severity="$1"
  
  ((TOTAL_ISSUES++))
  
  case "$severity" in
    high)
      ((HIGH_SEVERITY_ISSUES++))
      ;;
    medium)
      ((MEDIUM_SEVERITY_ISSUES++))
      ;;
    low)
      ((LOW_SEVERITY_ISSUES++))
      ;;
  esac
}

# Function to check file permissions
function check_file_permissions() {
  log_info "Checking file permissions..."
  
  local issues_found=0
  local report_file="$OUTPUT_DIR/file_permissions.txt"
  
  # Create report file header
  cat > "$report_file" << EOF
# File Permissions Security Report
Generated: $(date)

## Sensitive Files with Incorrect Permissions

| File | Current Permissions | Expected Permissions | Severity |
|------|--------------------|--------------------|----------|
EOF
  
  # Check configuration files
  log_info "Checking configuration file permissions..."
  
  # Check main environment file
  if [[ -f "$ROOT_DIR/config/.env" ]]; then
    local perms=$(stat -c "%a" "$ROOT_DIR/config/.env")
    if [[ "$perms" != "600" && "$perms" != "400" ]]; then
      log_warn "Main environment file has incorrect permissions: $perms (should be 600 or 400)"
      echo "| config/.env | $perms | 600 or 400 | high |" >> "$report_file"
      increment_issue_counter "high"
      ((issues_found++))
    fi
  fi
  
  # Check LibreChat environment file
  if [[ -f "$ROOT_DIR/config/librechat/.env" ]]; then
    local perms=$(stat -c "%a" "$ROOT_DIR/config/librechat/.env")
    if [[ "$perms" != "600" && "$perms" != "400" ]]; then
      log_warn "LibreChat environment file has incorrect permissions: $perms (should be 600 or 400)"
      echo "| config/librechat/.env | $perms | 600 or 400 | high |" >> "$report_file"
      increment_issue_counter "high"
      ((issues_found++))
    fi
  fi
  
  # Check LibreChat auth.json file
  if [[ -f "$ROOT_DIR/config/librechat/auth.json" ]]; then
    local perms=$(stat -c "%a" "$ROOT_DIR/config/librechat/auth.json")
    if [[ "$perms" != "600" && "$perms" != "400" && "$perms" != "644" ]]; then
      log_warn "LibreChat auth.json file has incorrect permissions: $perms (should be 600, 400, or 644)"
      echo "| config/librechat/auth.json | $perms | 600, 400, or 644 | medium |" >> "$report_file"
      increment_issue_counter "medium"
      ((issues_found++))
    fi
  fi
  
  # Check other configuration files if scan depth is thorough
  if [[ "$SCAN_DEPTH" == "thorough" ]]; then
    log_info "Performing thorough scan of all configuration files..."
    
    # Find all configuration files
    local config_files=$(find "$ROOT_DIR/config" -type f -name "*.env" -o -name "*.conf" -o -name "*.yaml" -o -name "*.yml" -o -name "*.json")
    
    for file in $config_files; do
      local rel_path=${file#"$ROOT_DIR/"}
      local perms=$(stat -c "%a" "$file")
      
      # Check if file has appropriate permissions
      if [[ "$perms" != "600" && "$perms" != "400" && "$perms" != "644" ]]; then
        log_warn "Configuration file has incorrect permissions: $rel_path ($perms)"
        echo "| $rel_path | $perms | 600, 400, or 644 | medium |" >> "$report_file"
        increment_issue_counter "medium"
        ((issues_found++))
      fi
    done
  fi
  
  # Check script permissions
  log_info "Checking script permissions..."
  
  # Find all shell scripts
  local shell_scripts=$(find "$ROOT_DIR" -name "*.sh")
  
  for script in $shell_scripts; do
    local rel_path=${script#"$ROOT_DIR/"}
    
    # Check if script is executable
    if [[ ! -x "$script" ]]; then
      log_warn "Shell script is not executable: $rel_path"
      echo "| $rel_path | $(stat -c "%a" "$script") | 755 or 700 | low |" >> "$report_file"
      increment_issue_counter "low"
      ((issues_found++))
    fi
  done
  
  # Check data directory permissions if they exist
  if [[ -d "$ROOT_DIR/data" ]]; then
    log_info "Checking data directory permissions..."
    
    # Find all data directories
    local data_dirs=$(find "$ROOT_DIR/data" -type d)
    
    for dir in $data_dirs; do
      local rel_path=${dir#"$ROOT_DIR/"}
      local perms=$(stat -c "%a" "$dir")
      
      # Check if directory has appropriate permissions
      if [[ "$perms" != "755" && "$perms" != "750" && "$perms" != "700" ]]; then
        log_warn "Data directory has incorrect permissions: $rel_path ($perms)"
        echo "| $rel_path | $perms | 755, 750, or 700 | medium |" >> "$report_file"
        increment_issue_counter "medium"
        ((issues_found++))
      fi
    done
  fi
  
  # Add summary to report
  cat >> "$report_file" << EOF

## Summary

- Total files with permission issues: $issues_found
EOF
  
  if [[ $issues_found -eq 0 ]]; then
    log_success "No file permission issues found"
  else
    log_warn "Found $issues_found file permission issues"
  fi
  
  return $ERR_SUCCESS
}

# Function to check for hard-coded credentials
function check_hardcoded_credentials() {
  log_info "Checking for hard-coded credentials..."
  
  local issues_found=0
  local report_file="$OUTPUT_DIR/hardcoded_credentials.txt"
  
  # Create report file header
  cat > "$report_file" << EOF
# Hard-coded Credentials Security Report
Generated: $(date)

## Files with Potential Hard-coded Credentials

| File | Line | Match | Severity |
|------|------|------|----------|
EOF
  
  # Define patterns to search for
  local patterns=(
    "password[[:space:]]*=[[:space:]]*[\"'][^\"']*[\"']"
    "secret[[:space:]]*=[[:space:]]*[\"'][^\"']*[\"']"
    "key[[:space:]]*=[[:space:]]*[\"'][^\"']*[\"']"
    "token[[:space:]]*=[[:space:]]*[\"'][^\"']*[\"']"
    "credential[[:space:]]*=[[:space:]]*[\"'][^\"']*[\"']"
    "apiKey[[:space:]]*=[[:space:]]*[\"'][^\"']*[\"']"
    "api_key[[:space:]]*=[[:space:]]*[\"'][^\"']*[\"']"
    "passwd[[:space:]]*=[[:space:]]*[\"'][^\"']*[\"']"
    "pwd[[:space:]]*=[[:space:]]*[\"'][^\"']*[\"']"
  )
  
  # Define files to exclude
  local exclude_patterns=(
    ".git/"
    "node_modules/"
    "data/"
    "backups/"
    "test_results/"
    "security_results/"
    ".env.example"
    "template"
    "example"
    "sample"
    "test"
  )
  
  # Build exclude arguments for grep
  local exclude_args=""
  for pattern in "${exclude_patterns[@]}"; do
    exclude_args="$exclude_args --exclude-dir=$pattern"
  done
  
  # Determine files to scan based on scan depth
  local files_to_scan=""
  case "$SCAN_DEPTH" in
    quick)
      # Only scan shell scripts and configuration files
      files_to_scan=$(find "$ROOT_DIR" -type f -name "*.sh" -o -name "*.env" -o -name "*.conf" -o -name "*.yaml" -o -name "*.yml" -o -name "*.json")
      ;;
    normal)
      # Scan all text files except excluded patterns
      files_to_scan=$(find "$ROOT_DIR" -type f -not -path "*/\.*" | xargs file --mime-type | grep "text/" | cut -d: -f1)
      ;;
    thorough)
      # Scan all files except binary files and excluded patterns
      files_to_scan=$(find "$ROOT_DIR" -type f -not -path "*/\.*")
      ;;
  esac
  
  # Search for patterns in files
  for pattern in "${patterns[@]}"; do
    log_debug "Searching for pattern: $pattern"
    
    # Use grep to find matches
    while IFS=: read -r file line_content; do
      # Skip if file matches any exclude pattern
      local skip=false
      for exclude in "${exclude_patterns[@]}"; do
        if [[ "$file" == *"$exclude"* ]]; then
          skip=true
          break
        fi
      done
      
      if [[ "$skip" == "true" ]]; then
        continue
      fi
      
      # Extract line number and content
      local line=$(echo "$line_content" | cut -d: -f1)
      local content=$(echo "$line_content" | cut -d: -f2-)
      
      # Skip if content contains variable reference
      if [[ "$content" =~ \$\{.*\} || "$content" =~ \$[A-Za-z0-9_]+ ]]; then
        continue
      fi
      
      # Skip if content is a template or example
      if [[ "$content" =~ template || "$content" =~ example || "$content" =~ sample || "$content" =~ placeholder ]]; then
        continue
      fi
      
      # Determine severity based on context
      local severity="medium"
      if [[ "$file" == *"config"* || "$file" == *".env"* ]]; then
        severity="high"
      fi
      
      # Add to report
      local rel_path=${file#"$ROOT_DIR/"}
      echo "| $rel_path | $line | \`${content//|/\\|}\` | $severity |" >> "$report_file"
      increment_issue_counter "$severity"
      ((issues_found++))
      
    done < <(grep -n -E "$pattern" $exclude_args $files_to_scan 2>/dev/null || true)
  done
  
  # Add summary to report
  cat >> "$report_file" << EOF

## Summary

- Total potential credential issues: $issues_found
EOF
  
  if [[ $issues_found -eq 0 ]]; then
    log_success "No hard-coded credentials found"
  else
    log_warn "Found $issues_found potential hard-coded credentials"
  fi
  
  return $ERR_SUCCESS
}

# Function to check for secure configuration
function check_secure_configuration() {
  log_info "Checking for secure configuration..."
  
  local issues_found=0
  local report_file="$OUTPUT_DIR/secure_configuration.txt"
  
  # Create report file header
  cat > "$report_file" << EOF
# Secure Configuration Report
Generated: $(date)

## Configuration Security Issues

| Issue | Description | Severity |
|-------|-------------|----------|
EOF
  
  # Check if main environment file exists
  if [[ ! -f "$ROOT_DIR/config/.env" ]]; then
    log_warn "Main environment file not found"
    echo "| Missing main environment file | The main environment file (config/.env) is missing | high |" >> "$report_file"
    increment_issue_counter "high"
    ((issues_found++))
    return $ERR_SUCCESS
  fi
  
  # Check for required secrets in environment file
  local required_secrets=("JWT_SECRET" "JWT_REFRESH_SECRET" "SESSION_SECRET" "CRYPT_SECRET" "CREDS_KEY" "CREDS_IV")
  
  for secret in "${required_secrets[@]}"; do
    if ! grep -q "$secret=" "$ROOT_DIR/config/.env"; then
      log_warn "Required secret not found in environment file: $secret"
      echo "| Missing required secret | The required secret $secret is not defined in the environment file | high |" >> "$report_file"
      increment_issue_counter "high"
      ((issues_found++))
    else
      # Check if the secret is not empty
      local value=$(grep "$secret=" "$ROOT_DIR/config/.env" | cut -d= -f2)
      if [[ -z "$value" ]]; then
        log_warn "Secret is empty: $secret"
        echo "| Empty secret value | The secret $secret has an empty value | high |" >> "$report_file"
        increment_issue_counter "high"
        ((issues_found++))
      fi
    fi
  done
  
  # Check for secure defaults
  if grep -q "ENABLE_AUTH=false" "$ROOT_DIR/config/.env"; then
    log_warn "Authentication is disabled in the environment file"
    echo "| Authentication disabled | Authentication is disabled (ENABLE_AUTH=false) | high |" >> "$report_file"
    increment_issue_counter "high"
    ((issues_found++))
  fi
  
  # Check for insecure defaults in LibreChat configuration
  if [[ -f "$ROOT_DIR/config/librechat/librechat.yaml" ]]; then
    # Check for insecure settings in LibreChat YAML
    if grep -q "allowRegistration: true" "$ROOT_DIR/config/librechat/librechat.yaml"; then
      log_warn "User registration is enabled in LibreChat configuration"
      echo "| Registration enabled | User registration is enabled in LibreChat configuration | medium |" >> "$report_file"
      increment_issue_counter "medium"
      ((issues_found++))
    fi
  fi
  
  # Check for Docker security settings if scan depth is thorough
  if [[ "$SCAN_DEPTH" == "thorough" ]]; then
    log_info "Performing thorough scan of Docker security settings..."
    
    # Check Docker Compose files for security settings
    local compose_files=$(find "$ROOT_DIR" -name "docker-compose.yml" -o -name "docker-compose.yaml")
    
    for file in $compose_files; do
      local rel_path=${file#"$ROOT_DIR/"}
      
      # Check for privileged containers
      if grep -q "privileged: true" "$file"; then
        log_warn "Privileged container found in $rel_path"
        echo "| Privileged container | A container is running in privileged mode in $rel_path | high |" >> "$report_file"
        increment_issue_counter "high"
        ((issues_found++))
      fi
      
      # Check for host network mode
      if grep -q "network_mode: host" "$file"; then
        log_warn "Host network mode found in $rel_path"
        echo "| Host network mode | A container is using host network mode in $rel_path | medium |" >> "$report_file"
        increment_issue_counter "medium"
        ((issues_found++))
      fi
      
      # Check for host volume mounts
      if grep -q "/:/host" "$file" || grep -q "/etc:/etc" "$file" || grep -q "/var:/var" "$file"; then
        log_warn "Sensitive host volume mount found in $rel_path"
        echo "| Sensitive host volume mount | A container is mounting sensitive host directories in $rel_path | high |" >> "$report_file"
        increment_issue_counter "high"
        ((issues_found++))
      fi
    done
  fi
  
  # Add summary to report
  cat >> "$report_file" << EOF

## Summary

- Total configuration security issues: $issues_found
EOF
  
  if [[ $issues_found -eq 0 ]]; then
    log_success "No configuration security issues found"
  else
    log_warn "Found $issues_found configuration security issues"
  fi
  
  return $ERR_SUCCESS
}

# Function to check network security
function check_network_security() {
  if [[ "$SKIP_NETWORK" == "true" ]]; then
    log_info "Skipping network security tests as requested"
    return $ERR_SUCCESS
  fi
  
  log_info "Checking network security..."
  
  local issues_found=0
  local report_file="$OUTPUT_DIR/network_security.txt"
  
  # Create report file header
  cat > "$report_file" << EOF
# Network Security Report
Generated: $(date)

## Network Security Issues

| Issue | Description | Severity |
|-------|-------------|----------|
EOF
  
  # Check if Docker is running
  if ! docker ps &>/dev/null; then
    log_warn "Docker is not running, skipping network security tests"
    echo "| Docker not running | Docker is not running, cannot perform network security tests | medium |" >> "$report_file"
    increment_issue_counter "medium"
    ((issues_found++))
    return $ERR_SUCCESS
  fi
  
  # Check exposed ports
  log_info "Checking exposed ports..."
  
  # Get list of exposed ports
  local exposed_ports=$(docker ps --format '{{.Ports}}' | grep -o '[0-9.]*:[0-9]*->[0-9]*/tcp' | cut -d: -f1,2 | tr ':' ' ' | awk '{print $2}')
  
  for port in $exposed_ports; do
    # Check if port is in the allowed range
    if [[ $port -lt 1024 ]]; then
      log_warn "Container port exposed on privileged port: $port"
      echo "| Privileged port exposure | Container port exposed on privileged port: $port | medium |" >> "$report_file"
      increment_issue_counter "medium"
      ((issues_found++))
    fi
    
    # Check if port is exposed to all interfaces
    local interface=$(docker ps --format '{{.Ports}}' | grep -o '[0-9.]*:'$port | cut -d: -f1)
    if [[ "$interface" == "0.0.0.0" ]]; then
      log_warn "Port $port is exposed to all network interfaces"
      echo "| Port exposed to all interfaces | Port $port is exposed to all network interfaces (0.0.0.0) | medium |" >> "$report_file"
      increment_issue_counter "medium"
      ((issues_found++))
    fi
  done
  
  # Check if containers are using the default bridge network
  log_info "Checking container networks..."
  
  local containers_on_default_bridge=$(docker network inspect bridge -f '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null)
  if [[ -n "$containers_on_default_bridge" ]]; then
    log_warn "Containers using default bridge network: $containers_on_default_bridge"
    echo "| Default bridge network | Containers using default bridge network: $containers_on_default_bridge | low |" >> "$report_file"
    increment_issue_counter "low"
    ((issues_found++))
  fi
  
  # Check for network security in Docker Compose files
  if [[ "$SCAN_DEPTH" == "thorough" ]]; then
    log_info "Performing thorough scan of Docker Compose network settings..."
    
    # Check Docker Compose files for network settings
    local compose_files=$(find "$ROOT_DIR" -name "docker-compose.yml" -o -name "docker-compose.yaml")
    
    for file in $compose_files; do
      local rel_path=${file#"$ROOT_DIR/"}
      
      # Check for containers with no network specified
      if grep -A 5 "services:" "$file" | grep -v "networks:" | grep -q "container_name:"; then
        log_warn "Container with no network specified found in $rel_path"
        echo "| Missing network specification | A container has no network specified in $rel_path | low |" >> "$report_file"
        increment_issue_counter "low"
        ((issues_found++))
      fi
    done
  fi
  
  # Add summary to report
  cat >> "$report_file" << EOF

## Summary

- Total network security issues: $issues_found
EOF
  
  if [[ $issues_found -eq 0 ]]; then
    log_success "No network security issues found"
  else
    log_warn "Found $issues_found network security issues"
  fi
  
  return $ERR_SUCCESS
}

# Function to generate security report
function generate_security_report() {
  log_info "Generating security report..."
  
  local report_file="$OUTPUT_DIR/security_report.md"
  
  # Create report file
  cat > "$report_file" << EOF
# LOCAL-LLM-Stack Security Audit Report

## Overview

This report presents the findings of a security audit conducted on the LOCAL-LLM-Stack system.

- **Scan Date:** $(date)
- **Scan Depth:** $SCAN_DEPTH
- **Total Issues Found:** $TOTAL_ISSUES
  - High Severity: $HIGH_SEVERITY_ISSUES
  - Medium Severity: $MEDIUM_SEVERITY_ISSUES
  - Low Severity: $LOW_SEVERITY_ISSUES

## Summary of Findings

EOF
  
  # Add file permissions summary
  if [[ -f "$OUTPUT_DIR/file_permissions.txt" ]]; then
    local issues_count=$(grep -c "^|" "$OUTPUT_DIR/file_permissions.txt" | awk '{print $1-1}')
    cat >> "$report_file" << EOF
### File Permissions

- **Issues Found:** $issues_count
- **Details:** [File Permissions Report](file_permissions.txt)

EOF
  fi
  
  # Add hard-coded credentials summary
  if [[ -f "$OUTPUT_DIR/hardcoded_credentials.txt" ]]; then
    local issues_count=$(grep -c "^|" "$OUTPUT_DIR/hardcoded_credentials.txt" | awk '{print $1-1}')
    cat >> "$report_file" << EOF
### Hard-coded Credentials

- **Issues Found:** $issues_count
- **Details:** [Hard-coded Credentials Report](hardcoded_credentials.txt)

EOF
  fi
  
  # Add secure configuration summary
  if [[ -f "$OUTPUT_DIR/secure_configuration.txt" ]]; then
    local issues_count=$(grep -c "^|" "$OUTPUT_DIR/secure_configuration.txt" | awk '{print $1-1}')
    cat >> "$report_file" << EOF
### Secure Configuration

- **Issues Found:** $issues_count
- **Details:** [Secure Configuration Report](secure_configuration.txt)

EOF
  fi
  
  # Add network security summary
  if [[ -f "$OUTPUT_DIR/network_security.txt" ]]; then
    local issues_count=$(grep -c "^|" "$OUTPUT_DIR/network_security.txt" | awk '{print $1-1}')
    cat >> "$report_file" << EOF
### Network Security

- **Issues Found:** $issues_count
- **Details:** [Network Security Report](network_security.txt)

EOF
  fi
  
  # Add recommendations
  cat >> "$report_file" << EOF
## Recommendations

EOF
  
  # Add recommendations based on issues found
  if [[ $HIGH_SEVERITY_ISSUES -gt 0 ]]; then
    cat >> "$report_file" << EOF
### High Priority

1. **Fix file permissions** for sensitive configuration files
2. **Remove hard-coded credentials** from all files
3. **Ensure all required secrets** are properly configured
4. **Disable privileged containers** if found
5. **Secure sensitive host volume mounts** if found

EOF
  fi
  
  if [[ $MEDIUM_SEVERITY_ISSUES -gt 0 ]]; then
    cat >> "$report_file" << EOF
### Medium Priority

1. **Review network exposure** and limit to necessary interfaces
2. **Configure secure defaults** for all components
3. **Ensure proper authentication** is enabled for all services
4. **Review Docker network configuration** for security issues

EOF
  fi
  
  if [[ $LOW_SEVERITY_ISSUES -gt 0 ]]; then
    cat >> "$report_file" << EOF
### Low Priority

1. **Make all shell scripts executable** for consistency
2. **Use custom Docker networks** instead of the default bridge
3. **Specify networks explicitly** in Docker Compose files

EOF
  fi
  
  # Add conclusion
  cat >> "$report_file" << EOF
## Conclusion

EOF
  
  if [[ $TOTAL_ISSUES -eq 0 ]]; then
    cat >> "$report_file" << EOF
No security issues were found during this audit. The system appears to be properly configured and secure.
EOF
  elif [[ $HIGH_SEVERITY_ISSUES -eq 0 ]]; then
    cat >> "$report_file" << EOF
No high severity issues were found during this audit. However, there are some medium and low severity issues that should be addressed to improve the overall security of the system.
EOF
  else
    cat >> "$report_file" << EOF
Several security issues were found during this audit, including high severity issues that should be addressed immediately. Please review the detailed reports and implement the recommended fixes.
EOF
  fi
  
  log_success "Security report generated: $report_file"
  return $ERR_SUCCESS
}

# Main function
function main() {
  log_info "Starting security tests"
  
  # Check file permissions
  check_file_permissions
  if [[ $? -ne 0 ]]; then
    log_error "File permissions check failed"
    exit $ERR_GENERAL
  fi
  
  # Check for hard-coded credentials
  check_hardcoded_credentials
  if [[ $? -ne 0 ]]; then
    log_error "Hard-coded credentials check failed"
    exit $ERR_GENERAL
  fi
  
  # Check for secure configuration
  check_secure_configuration
  if [[ $? -ne 0 ]]; then
    log_error "Secure configuration check failed"
    exit $ERR_GENERAL
  fi
  
  # Check network security
  check_network_security
  if [[ $? -ne 0 ]]; then
    log_error "Network security check failed"
    exit $ERR_GENERAL
  fi
  
  # Generate security report
  generate_security_report
  if [[ $? -ne 0 ]]; then
    log_error "Failed to generate security report"
    exit $ERR_GENERAL
  fi
  
  log_success "Security tests completed successfully"
  log_info "Security report: $OUTPUT_DIR/security_report.md"
  
  # Return appropriate exit code based on issues found
  if [[ $HIGH_SEVERITY_ISSUES -gt 0 ]]; then
    log_warn "High severity issues found: $HIGH_SEVERITY_ISSUES"
    exit 2
  elif [[ $MEDIUM_SEVERITY_ISSUES -gt 0 ]]; then
    log_warn "Medium severity issues found: $MEDIUM_SEVERITY_ISSUES"
    exit 1
  else
    log_success "No high or medium severity issues found"
    exit 0
  fi
}

# Run the main function
main