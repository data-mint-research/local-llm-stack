#!/bin/bash
# utils.sh - Utility functions for LOCAL-LLM-Stack

# Set text colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# More efficient string generation using OpenSSL
generate_random_string() {
  local length=$1
  openssl rand -base64 $((length * 2)) | tr -dc 'a-zA-Z0-9' | head -c $length
}

generate_hex_string() {
  local length=$1
  openssl rand -hex $((length / 2))
}

# Error handling function with improved messages
handle_error() {
  local exit_code=$1
  local error_message=$2
  echo -e "${RED}Error: ${error_message}${NC}" >&2

  # Provide helpful suggestions based on error context
  case "$error_message" in
    *"docker"*)
      echo -e "${YELLOW}Tip: Make sure Docker is running with 'docker ps'${NC}" >&2
      ;;
    *"permission"*)
      echo -e "${YELLOW}Tip: You may need to run with sudo or fix permissions${NC}" >&2
      ;;
    *"not found"*)
      echo -e "${YELLOW}Tip: Check if the path is correct${NC}" >&2
      ;;
  esac

  exit $exit_code
}

# Docker compose helper with improved feedback
docker_compose_op() {
  local operation=$1 # up or down
  local project=$2
  local compose_files=$3
  local service=${4:-""} # optional service name

  echo -e "${BLUE}Running docker-compose $operation for $project...${NC}"

  # Show a spinner for long-running operations
  if [[ "$operation" == "up" ]]; then
    echo -e "${YELLOW}This may take a moment...${NC}"
  fi

  # Execute docker-compose with proper error handling
  # Use absolute paths for compose files
  if [[ "$operation" == "up" ]]; then
    cd "$SCRIPT_DIR/.." && docker-compose $compose_files -p $project $operation -d $service
  else
    cd "$SCRIPT_DIR/.." && docker-compose $compose_files -p $project $operation $service
  fi
  local status=$?

  if [[ $status -eq 0 ]]; then
    echo -e "${GREEN}Operation completed successfully.${NC}"
  else
    echo -e "${RED}Operation failed with status $status.${NC}"
  fi

  return $status
}

# Update environment variables in a file
update_env_vars() {
  local env_file=$1
  shift
  local vars=("$@")

  # Check if file exists and is writable
  if [[ ! -f "$env_file" ]]; then
    echo -e "${YELLOW}Creating new file: $env_file${NC}"
    # Create the file with the variables
    for var in "${vars[@]}"; do
      echo "$var" >> "$env_file" 2> /dev/null || {
        echo -e "${RED}Error: Could not write to $env_file${NC}"
        return 1
      }
    done
    return 0
  fi

  # Check if file is writable
  if [[ ! -w "$env_file" ]]; then
    echo -e "${RED}Error: File $env_file is not writable${NC}"
    return 1
  fi

  # Create a temporary file
  local tmp_file="$env_file.tmp"

  # Build the awk script dynamically
  local awk_script="{"
  for var in "${vars[@]}"; do
    IFS='=' read -r name value <<< "$var"
    # Add a flag to track if the variable was found
    awk_script+="found_$name=0; "
    # Replace existing variable
    awk_script+="if (/^$name=/) { print \"$name=$value\"; found_$name=1; next; } "
  done
  # Print all other lines
  awk_script+="print; "
  # End of file processing
  awk_script+="} END {"
  # Add any variables that weren't found
  for var in "${vars[@]}"; do
    IFS='=' read -r name value <<< "$var"
    awk_script+="if (found_$name==0) { print \"$name=$value\"; } "
  done
  awk_script+="}"

  # Execute the awk command
  awk "$awk_script" "$env_file" > "$tmp_file" 2> /dev/null && mv "$tmp_file" "$env_file" 2> /dev/null || {
    echo -e "${RED}Error: Could not update $env_file${NC}"
    return 1
  }
  return $?
}

# Check if a command exists
command_exists() {
  command -v "$1" > /dev/null 2>&1
}

# Get available disk space in GB
get_disk_space() {
  local dir=$1
  df -BG "$dir" | awk 'NR==2 {print $4}' | sed 's/G//'
}

# Check if we need sudo for file operations
need_sudo() {
  local dir=$1
  if [[ ! -w "$dir" ]] || find "$dir" -not -writable -print -quit | grep -q .; then
    return 0
  else
    return 1
  fi
}

# Create a backup of a file
backup_file() {
  local file=$1
  local backup="${file}.backup-$(date +%Y%m%d%H%M%S)"

  cp "$file" "$backup"
  if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}Backup created at $backup${NC}"
    echo "$backup"
    return 0
  else
    echo -e "${RED}Failed to create backup of $file${NC}"
    return 1
  fi
}
