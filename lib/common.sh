#!/bin/bash
# common.sh - Common functions for LOCAL-LLM-STACK CLI

# Source utility functions and configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"
source "$SCRIPT_DIR/config.sh"

# Check if secrets are generated and generate them if needed
check_secrets() {
  echo -e "${BLUE}Checking if secrets are generated...${NC}"

  # Check if config/.env exists
  if [[ ! -f "config/.env" ]]; then
    echo -e "${YELLOW}Configuration file not found. Generating secrets...${NC}"
    "$SCRIPT_DIR/generate_secrets.sh"
    return
  fi

  # Check if any of the required secrets are empty in the main config file
  local jwt_secret=$(grep -E "^JWT_SECRET=" config/.env | cut -d= -f2)
  local jwt_refresh_secret=$(grep -E "^JWT_REFRESH_SECRET=" config/.env | cut -d= -f2)
  local session_secret=$(grep -E "^SESSION_SECRET=" config/.env | cut -d= -f2)

  # Also check the LibreChat .env file if it exists
  local librechat_jwt_secret=""
  local librechat_jwt_refresh_secret=""
  local librechat_needs_update=false

  if [[ -f "config/librechat/.env" ]]; then
    echo -e "${YELLOW}Found LibreChat .env file${NC}"

    # Get LibreChat JWT secrets
    librechat_jwt_secret=$(grep -E "^JWT_SECRET=" config/librechat/.env | cut -d= -f2)
    librechat_jwt_refresh_secret=$(grep -E "^JWT_REFRESH_SECRET=" config/librechat/.env | cut -d= -f2)

    # Debug output
    echo -e "${YELLOW}Main JWT_SECRET: '$jwt_secret'${NC}"
    echo -e "${YELLOW}LibreChat JWT_SECRET: '$librechat_jwt_secret'${NC}"
    echo -e "${YELLOW}LibreChat JWT_SECRET length: ${#librechat_jwt_secret}${NC}"

    # Check if LibreChat secrets are empty
    if [[ -z "$librechat_jwt_secret" ]]; then
      echo -e "${RED}LibreChat JWT_SECRET is empty${NC}"
      librechat_needs_update=true
    fi

    if [[ -z "$librechat_jwt_refresh_secret" ]]; then
      echo -e "${RED}LibreChat JWT_REFRESH_SECRET is empty${NC}"
      librechat_needs_update=true
    fi

    echo -e "${YELLOW}librechat_needs_update: $librechat_needs_update${NC}"
  else
    # Debug output for main config only
    echo -e "${YELLOW}JWT_SECRET: '$jwt_secret'${NC}"
    echo -e "${YELLOW}JWT_REFRESH_SECRET: '$jwt_refresh_secret'${NC}"
    echo -e "${YELLOW}SESSION_SECRET: '$session_secret'${NC}"
  fi

  # Check if main secrets need to be generated
  if [[ -z "$jwt_secret" || -z "$jwt_refresh_secret" || -z "$session_secret" ]]; then
    echo -e "${YELLOW}Some required secrets are not set in main config. Generating secrets...${NC}"
    "$SCRIPT_DIR/generate_secrets.sh"
  elif [[ "$librechat_needs_update" == "true" ]]; then
    echo -e "${YELLOW}LibreChat JWT secrets need to be updated. Updating from main config...${NC}"

    # Update LibreChat secrets from main config
    echo -e "${YELLOW}Setting JWT_SECRET to: $jwt_secret${NC}"
    sed -i "s|^JWT_SECRET=.*|JWT_SECRET=$jwt_secret|" config/librechat/.env
    sed -i "s|^JWT_REFRESH_SECRET=.*|JWT_REFRESH_SECRET=$jwt_refresh_secret|" config/librechat/.env

    # Verify the update
    local updated_jwt_secret=$(grep -E "^JWT_SECRET=" config/librechat/.env | cut -d= -f2)
    echo -e "${YELLOW}Updated JWT_SECRET: $updated_jwt_secret${NC}"

    echo -e "${GREEN}LibreChat JWT secrets updated.${NC}"
  else
    echo -e "${GREEN}All required secrets are set.${NC}"
  fi
}

# Start command implementation with improved user feedback
start_command() {
  local component=$1
  local module=$2

  if [[ -z "$component" ]]; then
    echo -e "${BLUE}Starting all components...${NC}"
    # Check if secrets are generated before starting
    check_secrets
    docker_compose_op "up" "$CORE_PROJECT" "$CORE_COMPOSE" ""
    echo -e "${GREEN}Core components started successfully.${NC}"
    echo -e "${YELLOW}Tip: Use 'llm status' to check component status${NC}"
  elif [[ "$component" == "--with" ]]; then
    if [[ -z "$module" ]]; then
      handle_error 1 "Module name is required with --with flag"
    fi

    if [[ ! -d "modules/$module" ]]; then
      handle_error 1 "Module not found: $module"
    fi

    echo -e "${BLUE}Starting core components with $module module...${NC}"
    docker_compose_op "up" "$CORE_PROJECT" "$CORE_COMPOSE" ""
    docker_compose_op "up" "$CORE_PROJECT-$module" "-f modules/$module/docker-compose.yml" ""
    echo -e "${GREEN}Core components and $module module started successfully.${NC}"
    echo -e "${YELLOW}Tip: Use 'llm status' to check component status${NC}"
  else
    echo -e "${BLUE}Starting $component component...${NC}"
    docker_compose_op "up" "$CORE_PROJECT-$component" "-f core/$component.yml" ""
    echo -e "${GREEN}$component component started successfully.${NC}"
  fi
}

# Stop command implementation with improved user feedback
stop_command() {
  local component=$1
  local module=$2

  if [[ -z "$component" ]]; then
    echo -e "${BLUE}Stopping all components...${NC}"
    docker_compose_op "down" "$CORE_PROJECT" "$CORE_COMPOSE" ""
    echo -e "${GREEN}All components stopped successfully.${NC}"
  elif [[ "$component" == "--with" ]]; then
    if [[ -z "$module" ]]; then
      handle_error 1 "Module name is required with --with flag"
    fi

    if [[ ! -d "modules/$module" ]]; then
      handle_error 1 "Module not found: $module"
    fi

    echo -e "${BLUE}Stopping core components and $module module...${NC}"
    docker_compose_op "down" "$CORE_PROJECT-$module" "-f modules/$module/docker-compose.yml" ""
    docker_compose_op "down" "$CORE_PROJECT" "$CORE_COMPOSE" ""
    echo -e "${GREEN}Core components and $module module stopped successfully.${NC}"
  else
    echo -e "${BLUE}Stopping $component component...${NC}"
    docker_compose_op "down" "$CORE_PROJECT-$component" "-f core/$component.yml" ""
    echo -e "${GREEN}$component component stopped successfully.${NC}"
  fi
}

# Debug command implementation with improved user guidance
debug_command() {
  local component=$1

  if [[ -z "$component" ]]; then
    echo -e "${BLUE}Starting all components in debug mode...${NC}"
    # Check if secrets are generated before starting
    check_secrets
    docker_compose_op "up" "$DEBUG_PROJECT" "$DEBUG_COMPOSE" ""
    echo -e "${GREEN}Core components started in debug mode.${NC}"
    echo -e "${YELLOW}LibreChat Node.js debugger is available at localhost:9229${NC}"
    echo -e "${YELLOW}Tip: Use VSCode's 'Attach to LibreChat' debug configuration to connect${NC}"
  elif [[ "$component" == "librechat" ]]; then
    echo -e "${BLUE}Starting LibreChat in debug mode...${NC}"
    docker_compose_op "up" "$DEBUG_PROJECT" "$DEBUG_COMPOSE" "librechat"
    echo -e "${GREEN}LibreChat started in debug mode.${NC}"
    echo -e "${YELLOW}Node.js debugger is available at localhost:9229${NC}"
    echo -e "${YELLOW}Tip: Use VSCode's 'Attach to LibreChat' debug configuration to connect${NC}"
  else
    echo -e "${RED}Debug mode is currently only supported for LibreChat.${NC}"
    echo -e "${YELLOW}Usage: llm debug [librechat]${NC}"
    exit 1
  fi
}

# Status command implementation with improved formatting
status_command() {
  echo -e "${BLUE}Checking status of all components...${NC}"

  # Get container status with better formatting
  echo "┌─────────────────────────┬────────────────────┬─────────────────────────────┐"
  echo "│ Container               │ Status             │ Ports                        │"
  echo "├─────────────────────────┼────────────────────┼─────────────────────────────┤"

  # Use docker ps with custom format and process with awk for table formatting
  docker ps --format "{{.Names}}|{{.Status}}|{{.Ports}}" \
    | awk -F'|' '{printf "│ %-23s │ %-18s │ %-29s │\n", $1, $2, $3}'

  echo "└─────────────────────────┴────────────────────┴─────────────────────────────┘"

  # Show helpful tips
  # Get port values with fallbacks
  local librechat_port="3080"
  local ollama_port="11434"

  # Try to read from config file if it exists
  if [[ -f "config/.env" ]]; then
    librechat_port=$(grep -E "^HOST_PORT_LIBRECHAT=" config/.env | cut -d= -f2 || echo "3080")
    ollama_port=$(grep -E "^HOST_PORT_OLLAMA=" config/.env | cut -d= -f2 || echo "11434")
  fi

  echo ""
  echo -e "${YELLOW}Tip: Access LibreChat at http://localhost:${librechat_port}${NC}"
  echo -e "${YELLOW}Tip: Ollama API is available at http://localhost:${ollama_port}${NC}"
}

# Models command implementation with improved user guidance
models_command() {
  local action=$1
  local model=$2

  # Get Ollama port with fallback
  local ollama_port="11434"

  # Try to read from config file if it exists
  if [[ -f "config/.env" ]]; then
    ollama_port=$(grep -E "^HOST_PORT_OLLAMA=" config/.env | cut -d= -f2 || echo "11434")
  fi

  local ollama_url="http://localhost:${ollama_port}"

  # Check if Ollama is running with helpful error message
  if ! curl -s -f "${ollama_url}/api/version" > /dev/null; then
    echo -e "${RED}Error: Ollama service is not running.${NC}"
    echo -e "${YELLOW}Tip: Start Ollama with 'llm start ollama' first${NC}"
    exit 1
  fi

  case "$action" in
    list)
      echo -e "${BLUE}Listing available models...${NC}"
      local response=$(curl -s -f "${ollama_url}/api/tags")
      if [[ $? -ne 0 ]]; then
        handle_error 1 "Failed to list models. Ollama API returned an error."
      fi

      # Format the output using jq if available, otherwise print raw
      if command_exists jq; then
        echo "$response" | jq -r '.'
      else
        echo "$response"
      fi

      # Show helpful tips
      echo ""
      echo -e "${YELLOW}Tip: Add a model with 'llm models add model_name'${NC}"
      ;;
    add)
      if [[ -z "$model" ]]; then
        handle_error 1 "Model name is required for add action"
      fi

      echo -e "${BLUE}Adding model $model...${NC}"
      echo -e "${YELLOW}This may take a while depending on the model size...${NC}"

      local response=$(curl -s -f -X POST "${ollama_url}/api/pull" -d "{\"name\":\"$model\"}")
      if [[ $? -ne 0 ]]; then
        handle_error 1 "Failed to add model $model. Ollama API returned an error."
      fi

      echo -e "${GREEN}Model $model added successfully.${NC}"
      echo -e "${YELLOW}Tip: Use 'llm models list' to see all available models${NC}"
      ;;
    remove)
      if [[ -z "$model" ]]; then
        handle_error 1 "Model name is required for remove action"
      fi

      echo -e "${BLUE}Removing model $model...${NC}"
      local response=$(curl -s -f -X DELETE "${ollama_url}/api/delete" -d "{\"name\":\"$model\"}")
      if [[ $? -ne 0 ]]; then
        handle_error 1 "Failed to remove model $model. Ollama API returned an error."
      fi

      echo -e "${GREEN}Model $model removed successfully.${NC}"
      ;;
    *)
      echo -e "${YELLOW}Usage: llm models [list|add|remove] [model_name]${NC}"
      echo ""
      echo "Examples:"
      echo "  llm models list           List all available models"
      echo "  llm models add llama3     Add the Llama 3 model"
      echo "  llm models remove mistral Remove the Mistral model"
      exit 1
      ;;
  esac
}

# Config command implementation with improved user guidance
config_command() {
  local action=$1

  case "$action" in
    show)
      echo -e "${BLUE}Showing configuration...${NC}"
      cat config/.env

      # Show helpful tips
      echo ""
      echo -e "${YELLOW}Tip: Edit configuration with 'llm config edit'${NC}"
      ;;
    edit)
      echo -e "${BLUE}Creating backup of configuration...${NC}"
      local backup_file=$(backup_file "config/.env")
      if [[ $? -ne 0 ]]; then
        handle_error 1 "Failed to create backup of configuration file"
      fi

      echo -e "${BLUE}Editing configuration...${NC}"
      ${EDITOR:-nano} config/.env

      echo -e "${YELLOW}Note: If you made a mistake, you can restore from the backup:${NC}"
      echo -e "${YELLOW}cp $backup_file config/.env${NC}"
      ;;
    *)
      echo -e "${YELLOW}Usage: llm config [show|edit]${NC}"
      echo ""
      echo "Examples:"
      echo "  llm config show    Show current configuration"
      echo "  llm config edit    Edit configuration in your default editor"
      exit 1
      ;;
  esac
}

# Generate secrets command with improved user guidance
generate_secrets_command() {
  # Use the script for better reliability
  "$SCRIPT_DIR/generate_secrets.sh"
}

# Define commands and descriptions as associative array
declare -A COMMANDS=(
  ["start"]="Start the stack or specific components"
  ["stop"]="Stop the stack or specific components"
  ["status"]="Show status of all components"
  ["debug"]="Start components in debug mode"
  ["models"]="Manage models"
  ["config"]="View/edit configuration"
  ["generate-secrets"]="Generate secure secrets for configuration"
  ["help"]="Show help for any command"
)

# Help command implementation with improved formatting
help_command() {
  local command=$1

  if [[ -z "$command" ]]; then
    echo "Usage: llm [command] [options]"
    echo ""
    echo "Commands:"
    # Sort commands for consistent display
    for cmd in $(echo "${!COMMANDS[@]}" | tr ' ' '\n' | sort); do
      printf "  %-15s %s\n" "$cmd" "${COMMANDS[$cmd]}"
    done
    echo ""
    echo "Run 'llm help [command]' for more information on a command."
  else
    case "$command" in
      start)
        echo "Usage: llm start [component|--with module]"
        echo ""
        echo "Start the stack or specific components."
        echo ""
        echo "Options:"
        echo "  component       Name of the component to start (e.g., ollama, librechat)"
        echo "  --with module   Start with a specific module (e.g., monitoring, security)"
        echo ""
        echo "Examples:"
        echo "  llm start                 Start all components"
        echo "  llm start ollama          Start only the Ollama component"
        echo "  llm start --with monitoring  Start with the monitoring module"
        ;;
      stop)
        echo "Usage: llm stop [component|--with module]"
        echo ""
        echo "Stop the stack or specific components."
        echo ""
        echo "Options:"
        echo "  component       Name of the component to stop (e.g., ollama, librechat)"
        echo "  --with module   Stop with a specific module (e.g., monitoring, security)"
        echo ""
        echo "Examples:"
        echo "  llm stop                  Stop all components"
        echo "  llm stop librechat        Stop only the LibreChat component"
        echo "  llm stop --with monitoring  Stop core components and monitoring module"
        ;;
      status)
        echo "Usage: llm status"
        echo ""
        echo "Show status of all components."
        echo ""
        echo "This command displays the status of all running containers,"
        echo "including their names, status, and exposed ports."
        ;;
      debug)
        echo "Usage: llm debug [component]"
        echo ""
        echo "Start components in debug mode."
        echo ""
        echo "Options:"
        echo "  component       Name of the component to debug (currently only 'librechat' is supported)"
        echo ""
        echo "Examples:"
        echo "  llm debug                Start all components in debug mode"
        echo "  llm debug librechat      Start only LibreChat in debug mode"
        echo ""
        echo "When started in debug mode, the Node.js debugger will be available at localhost:9229."
        echo "You can connect to it using VSCode's 'Attach to LibreChat' debug configuration."
        ;;
      models)
        echo "Usage: llm models [list|add|remove] [model_name]"
        echo ""
        echo "Manage models."
        echo ""
        echo "Actions:"
        echo "  list            List available models"
        echo "  add model_name  Add a new model"
        echo "  remove model_name Remove a model"
        echo ""
        echo "Examples:"
        echo "  llm models list           List all available models"
        echo "  llm models add llama3     Add the Llama 3 model"
        echo "  llm models remove mistral Remove the Mistral model"
        ;;
      config)
        echo "Usage: llm config [show|edit]"
        echo ""
        echo "View or edit configuration."
        echo ""
        echo "Actions:"
        echo "  show            Show current configuration"
        echo "  edit            Edit configuration in your default editor"
        echo ""
        echo "Examples:"
        echo "  llm config show    Show current configuration"
        echo "  llm config edit    Edit configuration in your default editor"
        ;;
      generate-secrets)
        echo "Usage: llm generate-secrets"
        echo ""
        echo "Generate secure random secrets for the configuration."
        echo ""
        echo "This command will:"
        echo "  1. Create a backup of the current configuration"
        echo "  2. Generate secure random values for all secret fields"
        echo "  3. Update the configuration file with these values"
        echo "  4. Display the admin password (save this somewhere secure)"
        ;;
      *)
        echo "Unknown command: $command"
        echo "Run 'llm help' for a list of available commands."
        ;;
    esac
  fi
}
