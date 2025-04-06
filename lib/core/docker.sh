#!/bin/bash
# docker.sh - Docker and Docker Compose operations for LOCAL-LLM-Stack
# This module provides functions for managing Docker containers and services

# Guard against multiple inclusion
if [[ -n "$_DOCKER_SH_INCLUDED" ]]; then
  return 0
fi
_DOCKER_SH_INCLUDED=1

# Use a different variable name for the script directory
DOCKER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DOCKER_DIR/logging.sh"
source "$DOCKER_DIR/error.sh"
source "$DOCKER_DIR/system.sh"

# Check if Docker is installed and running
check_docker() {
  log_debug "Checking if Docker is installed and running"
  
  # Check if docker command exists
  if ! command_exists "docker"; then
    log_error "Docker is not installed"
    return $ERR_DEPENDENCY_ERROR
  fi
  
  # Check if docker daemon is running
  if ! docker info &>/dev/null; then
    log_error "Docker daemon is not running"
    log_info "Tip: Start Docker with 'sudo systemctl start docker' or equivalent for your system"
    return $ERR_DOCKER_ERROR
  fi
  
  log_debug "Docker is installed and running"
  return $ERR_SUCCESS
}

# Check if Docker Compose is installed
check_docker_compose() {
  log_debug "Checking if Docker Compose is installed"
  
  # Check for docker-compose command (v1) or docker compose subcommand (v2)
  if command_exists "docker-compose"; then
    log_debug "Docker Compose v1 is installed"
    return $ERR_SUCCESS
  elif docker compose version &>/dev/null; then
    log_debug "Docker Compose v2 is installed"
    return $ERR_SUCCESS
  else
    log_error "Docker Compose is not installed"
    return $ERR_DEPENDENCY_ERROR
  fi
}

# Get the appropriate Docker Compose command
get_docker_compose_cmd() {
  if command_exists "docker-compose"; then
    echo "docker-compose"
  else
    echo "docker compose"
  fi
}

# Docker Compose operation helper
docker_compose_op() {
  local operation=$1      # up, down, etc.
  local project=$2        # project name
  local compose_files=$3  # compose file arguments (-f file1.yml -f file2.yml)
  local service=${4:-""}  # optional service name
  
  log_info "Running docker-compose $operation for $project"
  
  # Check Docker and Docker Compose
  check_docker
  if [[ $? -ne 0 ]]; then
    return $ERR_DOCKER_ERROR
  fi
  
  check_docker_compose
  if [[ $? -ne 0 ]]; then
    return $ERR_DEPENDENCY_ERROR
  fi
  
  # Show a spinner for long-running operations
  if [[ "$operation" == "up" ]]; then
    log_info "This may take a moment..."
  fi
  
  # Get the appropriate Docker Compose command
  local compose_cmd=$(get_docker_compose_cmd)
  
  # Build the command
  local cmd="$compose_cmd $compose_files -p $project $operation"
  
  # Add detached mode for 'up' operation
  if [[ "$operation" == "up" ]]; then
    cmd="$cmd -d"
  fi
  
  # Add service if specified
  if [[ -n "$service" ]]; then
    cmd="$cmd $service"
  fi
  
  log_debug "Executing: $cmd"
  
  # Execute the command
  eval "$cmd"
  local status=$?
  
  if [[ $status -eq 0 ]]; then
    log_success "Docker Compose operation completed successfully"
  else
    log_error "Docker Compose operation failed with status $status"
    return $ERR_DOCKER_ERROR
  fi
  
  return $ERR_SUCCESS
}

# Check if a container is running
container_is_running() {
  local container=$1
  
  log_debug "Checking if container is running: $container"
  
  if docker ps --format '{{.Names}}' | grep -q "^$container$"; then
    log_debug "Container is running: $container"
    return $ERR_SUCCESS
  else
    log_debug "Container is not running: $container"
    return $ERR_GENERAL
  fi
}

# Get container status with better formatting
get_container_status() {
  local filter=${1:-""}
  
  log_debug "Getting container status with filter: $filter"
  
  # Check Docker
  check_docker
  if [[ $? -ne 0 ]]; then
    return $ERR_DOCKER_ERROR
  fi
  
  # Build the docker ps command
  local cmd="docker ps --format \"{{.Names}}|{{.Status}}|{{.Ports}}\""
  
  # Add filter if specified
  if [[ -n "$filter" ]]; then
    cmd="$cmd --filter \"name=$filter\""
  fi
  
  # Execute the command and format the output
  log_debug "Executing: $cmd"
  eval "$cmd" | awk -F'|' '{printf "%-30s %-20s %-30s\n", $1, $2, $3}'
  
  return $ERR_SUCCESS
}

# Pull a Docker image with progress feedback
docker_pull() {
  local image=$1
  
  log_info "Pulling Docker image: $image"
  
  # Check Docker
  check_docker
  if [[ $? -ne 0 ]]; then
    return $ERR_DOCKER_ERROR
  fi
  
  # Pull the image
  docker pull "$image"
  local status=$?
  
  if [[ $status -eq 0 ]]; then
    log_success "Docker image pulled successfully: $image"
  else
    log_error "Failed to pull Docker image: $image"
    return $ERR_DOCKER_ERROR
  fi
  
  return $ERR_SUCCESS
}

# Check if a Docker image exists locally
docker_image_exists() {
  local image=$1
  
  log_debug "Checking if Docker image exists: $image"
  
  # Check Docker
  check_docker
  if [[ $? -ne 0 ]]; then
    return $ERR_DOCKER_ERROR
  fi
  
  # Check if the image exists
  if docker image inspect "$image" &>/dev/null; then
    log_debug "Docker image exists: $image"
    return $ERR_SUCCESS
  else
    log_debug "Docker image does not exist: $image"
    return $ERR_GENERAL
  fi
}

# Get Docker container logs
docker_logs() {
  local container=$1
  local tail=${2:-"100"}
  
  log_debug "Getting logs for container: $container (tail: $tail)"
  
  # Check Docker
  check_docker
  if [[ $? -ne 0 ]]; then
    return $ERR_DOCKER_ERROR
  fi
  
  # Check if the container exists
  if ! docker ps -a --format '{{.Names}}' | grep -q "^$container$"; then
    log_error "Container does not exist: $container"
    return $ERR_GENERAL
  fi
  
  # Get the logs
  docker logs --tail "$tail" "$container"
  
  return $ERR_SUCCESS
}

# Execute a command in a running container
docker_exec() {
  local container=$1
  local command=$2
  
  log_debug "Executing command in container: $container, command: $command"
  
  # Check Docker
  check_docker
  if [[ $? -ne 0 ]]; then
    return $ERR_DOCKER_ERROR
  fi
  
  # Check if the container is running
  if ! container_is_running "$container"; then
    log_error "Container is not running: $container"
    return $ERR_GENERAL
  fi
  
  # Execute the command
  docker exec "$container" $command
  local status=$?
  
  if [[ $status -ne 0 ]]; then
    log_error "Command execution failed in container: $container"
    return $ERR_DOCKER_ERROR
  fi
  
  return $ERR_SUCCESS
}

# Get Docker network information
docker_network_info() {
  local network=$1
  
  log_debug "Getting information for Docker network: $network"
  
  # Check Docker
  check_docker
  if [[ $? -ne 0 ]]; then
    return $ERR_DOCKER_ERROR
  fi
  
  # Get network info
  docker network inspect "$network"
  local status=$?
  
  if [[ $status -ne 0 ]]; then
    log_error "Failed to get network information: $network"
    return $ERR_DOCKER_ERROR
  fi
  
  return $ERR_SUCCESS
}

log_debug "Docker operations module initialized"