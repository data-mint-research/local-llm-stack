#!/bin/bash
# update_librechat_secrets.sh - Update LibreChat secrets from main config

# Source utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

echo -e "${BLUE}Checking LibreChat secrets...${NC}"

# Check if config/.env exists
if [[ ! -f "config/.env" ]]; then
  echo -e "${RED}Main configuration file not found.${NC}"
  exit 1
fi

# Check if config/librechat/.env exists
if [[ ! -f "config/librechat/.env" ]]; then
  echo -e "${RED}LibreChat configuration file not found.${NC}"
  exit 1
fi

# Get secrets from main config
jwt_secret=$(grep -E "^JWT_SECRET=" config/.env | cut -d= -f2)
jwt_refresh_secret=$(grep -E "^JWT_REFRESH_SECRET=" config/.env | cut -d= -f2)

# Get secrets from LibreChat config
librechat_jwt_secret=$(grep -E "^JWT_SECRET=" config/librechat/.env | cut -d= -f2)
librechat_jwt_refresh_secret=$(grep -E "^JWT_REFRESH_SECRET=" config/librechat/.env | cut -d= -f2)

# Debug output
echo -e "${YELLOW}Main JWT_SECRET: '$jwt_secret'${NC}"
echo -e "${YELLOW}LibreChat JWT_SECRET: '$librechat_jwt_secret'${NC}"

# Check if LibreChat secrets need to be updated
if [[ -z "$librechat_jwt_secret" || -z "$librechat_jwt_refresh_secret" ]]; then
  echo -e "${YELLOW}LibreChat JWT secrets are not set. Updating from main config...${NC}"

  # Create backup of LibreChat .env file
  LIBRECHAT_BACKUP="config/librechat/.env.backup-$(date +%Y%m%d%H%M%S)"
  cp "config/librechat/.env" "$LIBRECHAT_BACKUP" 2> /dev/null

  # Update the JWT secrets in the LibreChat .env file
  sed -i "s|^JWT_SECRET=.*|JWT_SECRET=$jwt_secret|" config/librechat/.env
  sed -i "s|^JWT_REFRESH_SECRET=.*|JWT_REFRESH_SECRET=$jwt_refresh_secret|" config/librechat/.env

  # Verify the update
  updated_jwt_secret=$(grep -E "^JWT_SECRET=" config/librechat/.env | cut -d= -f2)
  echo -e "${YELLOW}Updated JWT_SECRET: $updated_jwt_secret${NC}"

  echo -e "${GREEN}LibreChat JWT secrets updated.${NC}"
else
  echo -e "${GREEN}LibreChat JWT secrets are already set.${NC}"
fi
