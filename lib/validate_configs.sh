#!/bin/bash
# validate_configs.sh - Validate all configuration files
# This script validates all configuration files against the schema

# Source core library modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/core/logging.sh"
source "$SCRIPT_DIR/core/error.sh"
source "$SCRIPT_DIR/core/system.sh"
source "$SCRIPT_DIR/core/config.sh"
source "$SCRIPT_DIR/core/validate_config.sh"

log_info "Validating all configuration files..."

# Validate all configuration files
validate_all_configs
if [[ $? -ne 0 ]]; then
  handle_error $ERR_VALIDATION_ERROR "Configuration validation failed"
fi

log_success "All configuration files are valid"