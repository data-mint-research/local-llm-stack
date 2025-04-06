#!/bin/bash
# generate_secrets_direct.sh - Generate secure secrets for LOCAL-LLM-Stack

# Source utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

echo -e "${BLUE}Generating secure secrets...${NC}"

# Ensure the config directory exists
if [[ ! -d "config" ]]; then
  echo -e "${YELLOW}Creating config directory...${NC}"
  mkdir -p config
fi

# Generate secure secrets
ADMIN_PASSWORD=$(generate_random_string 16)
GRAFANA_ADMIN_PASSWORD=$(generate_random_string 16)
JWT_SECRET=$(generate_random_string 64)
JWT_REFRESH_SECRET=$(generate_random_string 64)
SESSION_SECRET=$(generate_random_string 64)
CRYPT_SECRET=$(generate_random_string 64)
CREDS_KEY=$(generate_hex_string 64)
CREDS_IV=$(generate_hex_string 32)

# Create backup if the file exists
if [[ -f "config/.env" ]]; then
  BACKUP_FILE="config/.env.backup-$(date +%Y%m%d%H%M%S)"
  cp "config/.env" "$BACKUP_FILE" 2> /dev/null
  if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}Backup created at $BACKUP_FILE${NC}"
  else
    echo -e "${YELLOW}Warning: Could not create backup${NC}"
    BACKUP_FILE="No backup created"
  fi
else
  echo -e "${YELLOW}No existing configuration file to backup${NC}"
  BACKUP_FILE="No backup needed"
fi

# Create the .env file with the secrets directly
cat > config/.env << EOF
# LOCAL-LLM-Stack Configuration

# Component Versions
OLLAMA_VERSION=0.1.27
MONGODB_VERSION=6.0.6
MEILISEARCH_VERSION=latest
LIBRECHAT_VERSION=latest
TRAEFIK_VERSION=v2.10.4
NGINX_VERSION=1.25.3
PROMETHEUS_VERSION=v2.45.0
GRAFANA_VERSION=10.0.3

# Port Configuration
HOST_PORT_OLLAMA=11434
HOST_PORT_LIBRECHAT=3080
HOST_PORT_LOAD_BALANCER=8080
HOST_PORT_PROMETHEUS=9090
HOST_PORT_GRAFANA=3000

# Resource Limits
OLLAMA_CPU_LIMIT=0.75
OLLAMA_MEMORY_LIMIT=16G
MONGODB_MEMORY_LIMIT=2G
MEILISEARCH_MEMORY_LIMIT=1G
LIBRECHAT_CPU_LIMIT=0.50
LIBRECHAT_MEMORY_LIMIT=4G

# Default Models
DEFAULT_MODELS=tinyllama

# Security Settings
ADMIN_PASSWORD=$ADMIN_PASSWORD
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=$GRAFANA_ADMIN_PASSWORD
JWT_SECRET=$JWT_SECRET
JWT_REFRESH_SECRET=$JWT_REFRESH_SECRET
SESSION_SECRET=$SESSION_SECRET
CRYPT_SECRET=$CRYPT_SECRET
CREDS_KEY=$CREDS_KEY
CREDS_IV=$CREDS_IV

# Authentication Settings
ENABLE_AUTH=true
ALLOW_SOCIAL_LOGIN=false
ALLOW_REGISTRATION=true
ADMIN_EMAIL=admin@local.host
EOF
if [[ $? -eq 0 ]]; then
  echo -e "${GREEN}Secure secrets generated and saved to config/.env${NC}"

  # Update LibreChat .env file if it exists
  if [[ -f "config/librechat/.env" ]]; then
    echo -e "${BLUE}Updating LibreChat environment file with new secrets...${NC}"

    # Create backup of LibreChat .env file
    LIBRECHAT_BACKUP="config/librechat/.env.backup-$(date +%Y%m%d%H%M%S)"
    cp "config/librechat/.env" "$LIBRECHAT_BACKUP" 2> /dev/null

    # Update the JWT secrets in the LibreChat .env file
    sed -i "s/^JWT_SECRET=.*/JWT_SECRET=$JWT_SECRET/" config/librechat/.env
    sed -i "s/^JWT_REFRESH_SECRET=.*/JWT_REFRESH_SECRET=$JWT_REFRESH_SECRET/" config/librechat/.env

    echo -e "${GREEN}LibreChat environment file updated.${NC}"
  fi

  echo -e "${YELLOW}IMPORTANT: Keep these secrets safe!${NC}"
  echo -e "${YELLOW}LibreChat Admin password: $ADMIN_PASSWORD${NC}"
  echo -e "${YELLOW}Grafana Admin password: $GRAFANA_ADMIN_PASSWORD${NC}"
  if [[ "$BACKUP_FILE" != "No backup needed" && "$BACKUP_FILE" != "No backup created" ]]; then
    echo -e "${YELLOW}If you need to restore the original configuration, use:${NC}"
    echo -e "${YELLOW}cp $BACKUP_FILE config/.env${NC}"
  fi
else
  echo -e "${RED}Error: Failed to write configuration file${NC}"
  exit 1
fi
