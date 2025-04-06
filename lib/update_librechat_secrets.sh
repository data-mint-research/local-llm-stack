#!/bin/bash
# update_librechat_secrets.sh - Update LibreChat secrets from main config
# This file has been refactored to use the new core library

# Source core library modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/core/logging.sh"
source "$SCRIPT_DIR/core/error.sh"
source "$SCRIPT_DIR/core/system.sh"
source "$SCRIPT_DIR/core/config.sh"
source "$SCRIPT_DIR/core/secrets.sh"

log_info "Checking LibreChat secrets..."

# Check if config/.env exists
if [[ ! -f "$ENV_FILE" ]]; then
  handle_error $ERR_FILE_NOT_FOUND "Main configuration file not found"
fi

# Check if config/librechat/.env exists
librechat_env="$CONFIG_DIR/librechat/.env"
if [[ ! -f "$librechat_env" ]]; then
  handle_error $ERR_FILE_NOT_FOUND "LibreChat configuration file not found"
fi

# Get secrets from main config
jwt_secret=$(get_config "JWT_SECRET")
jwt_refresh_secret=$(get_config "JWT_REFRESH_SECRET")

# Get secrets from LibreChat config
librechat_jwt_secret=$(grep -E "^JWT_SECRET=" "$librechat_env" | cut -d= -f2)
librechat_jwt_refresh_secret=$(grep -E "^JWT_REFRESH_SECRET=" "$librechat_env" | cut -d= -f2)

# Debug output
log_debug "Main JWT_SECRET: '$jwt_secret'"
log_debug "LibreChat JWT_SECRET: '$librechat_jwt_secret'"

# Check if LibreChat secrets need to be updated
if [[ -z "$librechat_jwt_secret" || -z "$librechat_jwt_refresh_secret" ]]; then
  log_warn "LibreChat JWT secrets are not set. Updating from main config..."

  # Create backup of LibreChat .env file
  LIBRECHAT_BACKUP=$(backup_file "$librechat_env")

  # Use update_librechat_config function instead of manual sed commands
  update_librechat_config
  if [[ $? -ne 0 ]]; then
    handle_error $ERR_GENERAL "Failed to update LibreChat configuration with secrets"
  fi

  # Verify the update
  updated_jwt_secret=$(grep -E "^JWT_SECRET=" "$librechat_env" | cut -d= -f2)
  log_debug "Updated JWT_SECRET: $updated_jwt_secret"

  log_success "LibreChat JWT secrets updated."
else
  log_success "LibreChat JWT secrets are already set."
fi
