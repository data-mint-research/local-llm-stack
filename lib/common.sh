#!/bin/bash
# common.sh - Common functions for LOCAL-LLM-STACK CLI
# This file has been refactored to use the new core library

# Source core library modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/core/logging.sh"
source "$SCRIPT_DIR/core/error.sh"
source "$SCRIPT_DIR/core/config.sh"
source "$SCRIPT_DIR/core/system.sh"
source "$SCRIPT_DIR/core/docker.sh"
source "$SCRIPT_DIR/core/validation.sh"

# Start command implementation with improved user feedback
start_command() {
  local component=$1
  local module=$2

  if [[ -z "$component" ]]; then
    log_info "Starting all components..."
    # Check if secrets are generated before starting
    check_secrets
    docker_compose_op "up" "$CORE_PROJECT" "$CORE_COMPOSE" ""
    log_success "Core components started successfully."
    log_info "Tip: Use 'llm status' to check component status"
  elif [[ "$component" == "--with" ]]; then
    if [[ -z "$module" ]]; then
      handle_error $ERR_INVALID_ARGUMENT "Module name is required with --with flag"
    fi

    if [[ ! -d "modules/$module" ]]; then
      handle_error $ERR_MODULE_ERROR "Module not found: $module"
    fi

    log_info "Starting core components with $module module..."
    docker_compose_op "up" "$CORE_PROJECT" "$CORE_COMPOSE" ""
    docker_compose_op "up" "$CORE_PROJECT-$module" "-f modules/$module/docker-compose.yml" ""
    log_success "Core components and $module module started successfully."
    log_info "Tip: Use 'llm status' to check component status"
  else
    log_info "Starting $component component..."
    docker_compose_op "up" "$CORE_PROJECT-$component" "-f core/$component.yml" ""
    log_success "$component component started successfully."
  fi
}

# Stop command implementation with improved user feedback
stop_command() {
  local component=$1
  local module=$2

  if [[ -z "$component" ]]; then
    log_info "Stopping all components..."
    docker_compose_op "down" "$CORE_PROJECT" "$CORE_COMPOSE" ""
    log_success "All components stopped successfully."
  elif [[ "$component" == "--with" ]]; then
    if [[ -z "$module" ]]; then
      handle_error $ERR_INVALID_ARGUMENT "Module name is required with --with flag"
    fi

    if [[ ! -d "modules/$module" ]]; then
      handle_error $ERR_MODULE_ERROR "Module not found: $module"
    fi

    log_info "Stopping core components and $module module..."
    docker_compose_op "down" "$CORE_PROJECT-$module" "-f modules/$module/docker-compose.yml" ""
    docker_compose_op "down" "$CORE_PROJECT" "$CORE_COMPOSE" ""
    log_success "Core components and $module module stopped successfully."
  else
    log_info "Stopping $component component..."
    docker_compose_op "down" "$CORE_PROJECT-$component" "-f core/$component.yml" ""
    log_success "$component component stopped successfully."
  fi
}

# Debug command implementation with improved user guidance
debug_command() {
  local component=$1

  if [[ -z "$component" ]]; then
    log_info "Starting all components in debug mode..."
    # Check if secrets are generated before starting
    check_secrets
    docker_compose_op "up" "$DEBUG_PROJECT" "$DEBUG_COMPOSE" ""
    log_success "Core components started in debug mode."
    log_info "LibreChat Node.js debugger is available at localhost:9229"
    log_info "Tip: Use VSCode's 'Attach to LibreChat' debug configuration to connect"
  elif [[ "$component" == "librechat" ]]; then
    log_info "Starting LibreChat in debug mode..."
    docker_compose_op "up" "$DEBUG_PROJECT" "$DEBUG_COMPOSE" "librechat"
    log_success "LibreChat started in debug mode."
    log_info "Node.js debugger is available at localhost:9229"
    log_info "Tip: Use VSCode's 'Attach to LibreChat' debug configuration to connect"
  else
    log_error "Debug mode is currently only supported for LibreChat."
    log_info "Usage: llm debug [librechat]"
    exit 1
  fi
}

# Status command implementation with improved formatting
status_command() {
  log_info "Checking status of all components..."

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
  local librechat_port=$(get_config "HOST_PORT_LIBRECHAT" "3080")
  local ollama_port=$(get_config "HOST_PORT_OLLAMA" "11434")

  echo ""
  log_info "Tip: Access LibreChat at http://localhost:${librechat_port}"
  log_info "Tip: Ollama API is available at http://localhost:${ollama_port}"
}

# Models command implementation with improved user guidance
models_command() {
  local action=$1
  local model=$2

  # Get Ollama port with fallback
  local ollama_port=$(get_config "HOST_PORT_OLLAMA" "11434")
  local ollama_url="http://localhost:${ollama_port}"

  # Check if Ollama is running with helpful error message
  if ! curl -s -f "${ollama_url}/api/version" > /dev/null; then
    log_error "Ollama service is not running."
    log_info "Tip: Start Ollama with 'llm start ollama' first"
    exit 1
  fi

  case "$action" in
    list)
      log_info "Listing available models..."
      local response=$(curl -s -f "${ollama_url}/api/tags")
      if [[ $? -ne 0 ]]; then
        handle_error $ERR_NETWORK_ERROR "Failed to list models. Ollama API returned an error."
      fi

      # Format the output using jq if available, otherwise print raw
      if command_exists jq; then
        echo "$response" | jq -r '.'
      else
        echo "$response"
      fi

      # Show helpful tips
      echo ""
      log_info "Tip: Add a model with 'llm models add model_name'"
      ;;
    add)
      if [[ -z "$model" ]]; then
        handle_error $ERR_INVALID_ARGUMENT "Model name is required for add action"
      fi

      log_info "Adding model $model..."
      log_warn "This may take a while depending on the model size..."

      local response=$(curl -s -f -X POST "${ollama_url}/api/pull" -d "{\"name\":\"$model\"}")
      if [[ $? -ne 0 ]]; then
        handle_error $ERR_NETWORK_ERROR "Failed to add model $model. Ollama API returned an error."
      fi

      log_success "Model $model added successfully."
      log_info "Tip: Use 'llm models list' to see all available models"
      ;;
    remove)
      if [[ -z "$model" ]]; then
        handle_error $ERR_INVALID_ARGUMENT "Model name is required for remove action"
      fi

      log_info "Removing model $model..."
      local response=$(curl -s -f -X DELETE "${ollama_url}/api/delete" -d "{\"name\":\"$model\"}")
      if [[ $? -ne 0 ]]; then
        handle_error $ERR_NETWORK_ERROR "Failed to remove model $model. Ollama API returned an error."
      fi

      log_success "Model $model removed successfully."
      ;;
    *)
      log_info "Usage: llm models [list|add|remove] [model_name]"
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
      log_info "Showing configuration..."
      cat "$ENV_FILE"

      # Show helpful tips
      echo ""
      log_info "Tip: Edit configuration with 'llm config edit'"
      ;;
    edit)
      log_info "Creating backup of configuration..."
      local backup_file=$(backup_file "$ENV_FILE")
      if [[ $? -ne 0 ]]; then
        handle_error $ERR_FILE_NOT_FOUND "Failed to create backup of configuration file"
      fi

      log_info "Editing configuration..."
      ${EDITOR:-nano} "$ENV_FILE"

      log_warn "Note: If you made a mistake, you can restore from the backup:"
      log_warn "cp $backup_file $ENV_FILE"
      ;;
    *)
      log_info "Usage: llm config [show|edit]"
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
  # Use the core library function
  generate_secrets
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

# Load configuration
load_config

log_debug "Common functions module initialized"
