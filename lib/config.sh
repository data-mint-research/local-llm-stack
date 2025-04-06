#!/bin/bash
# config.sh - Configuration management for LOCAL-LLM-Stack

# Docker compose project names
CORE_PROJECT="local-llm-stack"
DEBUG_PROJECT="$CORE_PROJECT-debug"

# Docker compose files
CORE_COMPOSE="-f core/docker-compose.yml"
DEBUG_COMPOSE="$CORE_COMPOSE -f core/docker-compose.debug.yml"

# Load configuration from .env file
load_config() {
  if [[ -f "config/.env" ]]; then
    # Load variables without exporting them
    while IFS='=' read -r key value || [[ -n "$key" ]]; do
      # Skip comments and empty lines
      [[ $key =~ ^#.*$ ]] || [[ -z "$key" ]] && continue
      # Remove quotes from value if present
      value="${value%\"}"
      value="${value#\"}"
      # Export the variable
      export "$key=$value"
    done < "config/.env"
  fi
}

# Initialize configuration
load_config