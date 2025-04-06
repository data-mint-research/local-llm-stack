#!/bin/bash
# extract-docs.sh - Extract documentation from code and update YAML files
# This script extracts information from shell scripts, Docker Compose files, and other
# source files to update the machine-readable documentation.

# Get the absolute path of the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source paths
CORE_DIR="$ROOT_DIR/lib/core"
DOCKER_COMPOSE_FILE="$ROOT_DIR/core/docker-compose.yml"
MAIN_SCRIPT="$ROOT_DIR/llm"

# Output paths
COMPONENTS_FILE="$ROOT_DIR/docs/system/components.yaml"
INTERFACES_FILE="$ROOT_DIR/docs/system/interfaces.yaml"
RELATIONSHIPS_FILE="$ROOT_DIR/docs/system/relationships.yaml"

# Temporary files
COMPONENTS_TMP="$COMPONENTS_FILE.tmp"
INTERFACES_TMP="$INTERFACES_FILE.tmp"
RELATIONSHIPS_TMP="$RELATIONSHIPS_FILE.tmp"

# Create backup of existing files
backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup="$file.bak"
        cp "$file" "$backup"
        echo "Created backup: $backup"
    fi
}

# Extract shell functions from a file
extract_shell_functions() {
    local file="$1"
    local output_file="$INTERFACES_TMP"
    local file_name=$(basename "$file")
    
    echo "Extracting functions from $file_name"
    
    # Check if shell_functions section already exists in the file
    if ! grep -q "shell_functions:" "$output_file"; then
        echo "# Shell Functions" >> "$output_file"
        echo "shell_functions:" >> "$output_file"
    fi
    
    # Add file entry
    echo "  - file: \"${file#$ROOT_DIR/}\"" >> "$output_file"
    echo "    functions:" >> "$output_file"
    
    # Extract function definitions
    grep -n "^[[:space:]]*function[[:space:]]\+[a-zA-Z0-9_]\+[[:space:]]*()[[:space:]]*{" "$file" | \
    while IFS=':' read -r line_num line_content; do
        # Extract function name
        func_name=$(echo "$line_content" | sed -E 's/^[[:space:]]*function[[:space:]]+([a-zA-Z0-9_]+)[[:space:]]*\(\)[[:space:]]*\{.*/\1/')
        
        # Extract function description from comments above
        description=""
        start_line=$((line_num - 1))
        while [[ $start_line -gt 0 ]]; do
            prev_line=$(sed -n "${start_line}p" "$file")
            if [[ "$prev_line" =~ ^[[:space:]]*#[[:space:]]*(.*) ]]; then
                if [[ -z "$description" ]]; then
                    description="${BASH_REMATCH[1]}"
                else
                    description="${BASH_REMATCH[1]} $description"
                fi
                start_line=$((start_line - 1))
            else
                break
            fi
        done
        
        # If no description found, use a generic one
        if [[ -z "$description" ]]; then
            description="Function $func_name in ${file#$ROOT_DIR/}"
        fi
        
        # Write function info to output file
        echo "      - name: \"$func_name\"" >> "$output_file"
        echo "        description: \"$description\"" >> "$output_file"
        
        # Extract parameters by looking for local var=$1, etc.
        echo "        parameters:" >> "$output_file"
        
        # Look for parameters in the next 20 lines after function definition
        end_line=$((line_num + 20))
        sed -n "${line_num},${end_line}p" "$file" | \
        grep -E "local[[:space:]]+[a-zA-Z0-9_]+=[[:space:]]*\\\$[0-9]+" | \
        while read -r param_line; do
            # Extract parameter name and position
            if [[ "$param_line" =~ local[[:space:]]+([a-zA-Z0-9_]+)=[[:space:]]*\\\$([0-9]+) ]]; then
                param_name="${BASH_REMATCH[1]}"
                param_pos="${BASH_REMATCH[2]}"
                
                echo "          - name: \"$param_name\"" >> "$output_file"
                echo "            type: \"string\"" >> "$output_file"
                echo "            required: true" >> "$output_file"
                echo "            description: \"Parameter $param_name (position $param_pos)\"" >> "$output_file"
            fi
        done
        
        # Look for return statement to document return value
        returns=""
        sed -n "${line_num},${end_line}p" "$file" | \
        grep -E "return[[:space:]]+[a-zA-Z0-9_]+" | \
        while read -r return_line; do
            if [[ "$return_line" =~ return[[:space:]]+([a-zA-Z0-9_]+) ]]; then
                return_val="${BASH_REMATCH[1]}"
                if [[ "$return_val" =~ ^[0-9]+$ ]]; then
                    returns="Error code $return_val"
                elif [[ "$return_val" =~ ERR_ ]]; then
                    returns="Error code ($return_val)"
                else
                    returns="$return_val"
                fi
            fi
        done
        
        if [[ -n "$returns" ]]; then
            echo "        returns: \"$returns\"" >> "$output_file"
        else
            echo "        returns: \"No explicit return value\"" >> "$output_file"
        fi
    done
}

# Extract CLI commands from the main script
extract_cli_commands() {
    local file="$MAIN_SCRIPT"
    local output_file="$INTERFACES_TMP"
    
    echo "Extracting CLI commands from $(basename "$file")"
    
    # Check if cli_interfaces section already exists in the file
    if ! grep -q "cli_interfaces:" "$output_file"; then
        echo "# CLI Interfaces" >> "$output_file"
        echo "cli_interfaces:" >> "$output_file"
    fi
    
    # Add component entry
    echo "  - component: \"llm_script\"" >> "$output_file"
    echo "    commands:" >> "$output_file"
    
    # Extract commands from the case statement in main function
    sed -n '/case[[:space:]]*"$command"[[:space:]]*in/,/esac/p' "$file" | \
    grep -E "^[[:space:]]*[a-zA-Z0-9_-]+\)" | \
    while read -r line; do
        # Extract command name
        cmd_name=$(echo "$line" | sed -E 's/^[[:space:]]*([a-zA-Z0-9_-]+)\).*/\1/')
        
        # Look for the command function
        cmd_function="${cmd_name}_command"
        
        # Write command info to output file
        echo "      - name: \"$cmd_name\"" >> "$output_file"
        echo "        description: \"${cmd_name^} command\"" >> "$output_file"
        echo "        function: \"$cmd_function\"" >> "$output_file"
        echo "        parameters: []" >> "$output_file"
    done
}

# Extract components from Docker Compose file
extract_docker_components() {
    local file="$DOCKER_COMPOSE_FILE"
    local output_file="$COMPONENTS_TMP"
    
    echo "Extracting components from $(basename "$file")"
    
    # Check if components section already exists in the file
    if ! grep -q "components:" "$output_file"; then
        echo "# LOCAL-LLM-Stack Components Documentation" >> "$output_file"
        echo "# This file documents all system components in a machine-readable format" >> "$output_file"
        echo "" >> "$output_file"
        echo "components:" >> "$output_file"
    fi
    
    # Extract services from Docker Compose file
    sed -n '/services:/,/^[a-z]/p' "$file" | \
    grep -E "^[[:space:]]+[a-zA-Z0-9_-]+:" | \
    while read -r line; do
        # Extract service name
        service_name=$(echo "$line" | sed -E 's/^[[:space:]]+([a-zA-Z0-9_-]+):.*/\1/')
        
        # Skip if not a real service
        if [[ "$service_name" == "services" ]]; then
            continue
        fi
        
        echo "  - type: \"container\"" >> "$output_file"
        echo "    name: \"$service_name\"" >> "$output_file"
        
        # Extract image
        image=$(grep -A 2 "^[[:space:]]\+$service_name:" "$file" | grep "image:" | sed -E 's/^[[:space:]]+image:[[:space:]]+(.+)$/\1/')
        if [[ -n "$image" ]]; then
            # Extract base image and version variable
            if [[ "$image" =~ (.+):\$\{([A-Z_]+):-([^}]+)\} ]]; then
                base_image="${BASH_REMATCH[1]}"
                version_var="${BASH_REMATCH[2]}"
                default_version="${BASH_REMATCH[3]}"
                echo "    image: \"$base_image\"" >> "$output_file"
                echo "    version_var: \"$version_var\"" >> "$output_file"
                echo "    default_version: \"$default_version\"" >> "$output_file"
            else
                echo "    image: \"$image\"" >> "$output_file"
            fi
        fi
        
        # Extract purpose based on service name
        case "$service_name" in
            ollama)
                echo "    purpose: \"Provides local LLM inference capabilities\"" >> "$output_file"
                ;;
            librechat)
                echo "    purpose: \"Provides web interface for interacting with LLMs\"" >> "$output_file"
                ;;
            mongodb)
                echo "    purpose: \"Provides database storage for LibreChat\"" >> "$output_file"
                ;;
            meilisearch)
                echo "    purpose: \"Provides search capabilities for LibreChat\"" >> "$output_file"
                ;;
            *)
                echo "    purpose: \"$service_name service\"" >> "$output_file"
                ;;
        esac
        
        # Extract ports
        if grep -A 10 "^[[:space:]]\+$service_name:" "$file" | grep -q "ports:"; then
            echo "    ports:" >> "$output_file"
            grep -A 10 "^[[:space:]]\+$service_name:" "$file" | \
            sed -n '/ports:/,/^[[:space:]]\{2\}[a-z]/p' | \
            grep -E "^[[:space:]]+- " | \
            while read -r port_line; do
                port_mapping=$(echo "$port_line" | sed -E 's/^[[:space:]]+- "?\$\{([A-Z_]+):-([0-9]+)\}:([0-9]+)"?$/\1 \2 \3/')
                if [[ -n "$port_mapping" ]]; then
                    read -r var_name default_external internal <<< "$port_mapping"
                    echo "      - internal: $internal" >> "$output_file"
                    echo "        external_var: \"$var_name\"" >> "$output_file"
                    echo "        default_external: $default_external" >> "$output_file"
                    echo "        protocol: \"tcp\"" >> "$output_file"
                    echo "        purpose: \"Service port\"" >> "$output_file"
                fi
            done
        fi
        
        # Extract volumes
        if grep -A 20 "^[[:space:]]\+$service_name:" "$file" | grep -q "volumes:"; then
            echo "    volumes:" >> "$output_file"
            grep -A 20 "^[[:space:]]\+$service_name:" "$file" | \
            sed -n '/volumes:/,/^[[:space:]]\{2\}[a-z]/p' | \
            grep -E "^[[:space:]]+- " | \
            while read -r volume_line; do
                volume_mapping=$(echo "$volume_line" | sed -E 's/^[[:space:]]+- (.+):(.+)$/\1 \2/')
                if [[ -n "$volume_mapping" ]]; then
                    read -r host_path container_path <<< "$volume_mapping"
                    echo "      - host_path: \"$host_path\"" >> "$output_file"
                    echo "        container_path: \"$container_path\"" >> "$output_file"
                    
                    # Determine purpose based on path
                    if [[ "$container_path" == *"/data"* ]]; then
                        echo "        purpose: \"data_storage\"" >> "$output_file"
                    elif [[ "$container_path" == *"/config"* || "$container_path" == *".yaml" || "$container_path" == *".yml" ]]; then
                        echo "        purpose: \"configuration\"" >> "$output_file"
                    elif [[ "$container_path" == *".env" ]]; then
                        echo "        purpose: \"environment_variables\"" >> "$output_file"
                    elif [[ "$container_path" == *"/models"* || "$container_path" == *"/.ollama"* ]]; then
                        echo "        purpose: \"model_storage\"" >> "$output_file"
                    else
                        echo "        purpose: \"storage\"" >> "$output_file"
                    fi
                fi
            done
        fi
        
        # Extract environment variables
        if grep -A 50 "^[[:space:]]\+$service_name:" "$file" | grep -q "environment:"; then
            echo "    environment_variables:" >> "$output_file"
            grep -A 50 "^[[:space:]]\+$service_name:" "$file" | \
            sed -n '/environment:/,/^[[:space:]]\{2\}[a-z]/p' | \
            grep -E "^[[:space:]]+- " | \
            while read -r env_line; do
                env_var=$(echo "$env_line" | sed -E 's/^[[:space:]]+- (.+)$/\1/')
                if [[ -n "$env_var" && "$env_var" =~ (.+)=(.+) ]]; then
                    name="${BASH_REMATCH[1]}"
                    value="${BASH_REMATCH[2]}"
                    echo "      - name: \"$name\"" >> "$output_file"
                    echo "        value: \"$value\"" >> "$output_file"
                    
                    # Determine purpose based on name
                    if [[ "$name" == *"HOST"* ]]; then
                        echo "        purpose: \"Host configuration\"" >> "$output_file"
                    elif [[ "$name" == *"PORT"* ]]; then
                        echo "        purpose: \"Port configuration\"" >> "$output_file"
                    elif [[ "$name" == *"URI"* || "$name" == *"URL"* ]]; then
                        echo "        purpose: \"Connection URL\"" >> "$output_file"
                    elif [[ "$name" == *"SECRET"* || "$name" == *"KEY"* || "$name" == *"PASSWORD"* ]]; then
                        echo "        purpose: \"Security credential\"" >> "$output_file"
                    elif [[ "$name" == *"ENABLE"* || "$name" == *"ALLOW"* ]]; then
                        echo "        purpose: \"Feature flag\"" >> "$output_file"
                    else
                        echo "        purpose: \"Configuration\"" >> "$output_file"
                    fi
                fi
            done
        fi
        
        # Extract resource limits
        if grep -A 20 "^[[:space:]]\+$service_name:" "$file" | grep -q "resources:"; then
            echo "    resource_limits:" >> "$output_file"
            
            # Extract CPU limit
            cpu_limit=$(grep -A 20 "^[[:space:]]\+$service_name:" "$file" | \
                       grep -A 10 "resources:" | \
                       grep -A 5 "limits:" | \
                       grep "cpus:" | \
                       sed -E 's/^[[:space:]]+cpus:[[:space:]]+"?\$\{([A-Z_]+):-([0-9.]+)\}"?$/\1 \2/')
            
            if [[ -n "$cpu_limit" ]]; then
                read -r var_name default_value <<< "$cpu_limit"
                echo "      cpu_var: \"$var_name\"" >> "$output_file"
                echo "      cpu_default: $default_value" >> "$output_file"
            fi
            
            # Extract memory limit
            memory_limit=$(grep -A 20 "^[[:space:]]\+$service_name:" "$file" | \
                          grep -A 10 "resources:" | \
                          grep -A 5 "limits:" | \
                          grep "memory:" | \
                          sed -E 's/^[[:space:]]+memory:[[:space:]]+\$\{([A-Z_]+):-([0-9A-Za-z]+)\}$/\1 \2/')
            
            if [[ -n "$memory_limit" ]]; then
                read -r var_name default_value <<< "$memory_limit"
                echo "      memory_var: \"$var_name\"" >> "$output_file"
                echo "      memory_default: \"$default_value\"" >> "$output_file"
            fi
        fi
        
        # Extract health check
        if grep -A 20 "^[[:space:]]\+$service_name:" "$file" | grep -q "healthcheck:"; then
            echo "    health_check:" >> "$output_file"
            
            # Extract test command
            test_cmd=$(grep -A 20 "^[[:space:]]\+$service_name:" "$file" | \
                      grep -A 10 "healthcheck:" | \
                      grep -A 5 "test:" | \
                      sed -n '2p' | \
                      sed -E 's/^[[:space:]]+(.+),$/\1/')
            
            if [[ -n "$test_cmd" ]]; then
                echo "      command: $test_cmd" >> "$output_file"
            fi
            
            # Extract interval
            interval=$(grep -A 20 "^[[:space:]]\+$service_name:" "$file" | \
                      grep -A 10 "healthcheck:" | \
                      grep "interval:" | \
                      sed -E 's/^[[:space:]]+interval:[[:space:]]+(.+)$/\1/')
            
            if [[ -n "$interval" ]]; then
                echo "      interval: \"$interval\"" >> "$output_file"
            fi
            
            # Extract timeout
            timeout=$(grep -A 20 "^[[:space:]]\+$service_name:" "$file" | \
                     grep -A 10 "healthcheck:" | \
                     grep "timeout:" | \
                     sed -E 's/^[[:space:]]+timeout:[[:space:]]+(.+)$/\1/')
            
            if [[ -n "$timeout" ]]; then
                echo "      timeout: \"$timeout\"" >> "$output_file"
            fi
            
            # Extract retries
            retries=$(grep -A 20 "^[[:space:]]\+$service_name:" "$file" | \
                     grep -A 10 "healthcheck:" | \
                     grep "retries:" | \
                     sed -E 's/^[[:space:]]+retries:[[:space:]]+(.+)$/\1/')
            
            if [[ -n "$retries" ]]; then
                echo "      retries: $retries" >> "$output_file"
            fi
            
            # Extract start period
            start_period=$(grep -A 20 "^[[:space:]]\+$service_name:" "$file" | \
                          grep -A 10 "healthcheck:" | \
                          grep "start_period:" | \
                          sed -E 's/^[[:space:]]+start_period:[[:space:]]+(.+)$/\1/')
            
            if [[ -n "$start_period" ]]; then
                echo "      start_period: \"$start_period\"" >> "$output_file"
            fi
        fi
    done
}

# Extract relationships from Docker Compose file
extract_relationships() {
    local file="$DOCKER_COMPOSE_FILE"
    local output_file="$RELATIONSHIPS_TMP"
    
    echo "Extracting relationships from $(basename "$file")"
    
    # Check if relationships section already exists in the file
    if ! grep -q "relationships:" "$output_file"; then
        echo "# LOCAL-LLM-Stack Relationships Documentation" >> "$output_file"
        echo "# This file documents all system relationships in a machine-readable format" >> "$output_file"
        echo "" >> "$output_file"
        echo "relationships:" >> "$output_file"
    fi
    
    # Extract dependencies from Docker Compose file
    grep -n "depends_on:" "$file" | \
    while IFS=':' read -r line_num line_content; do
        # Get the service name (source)
        source_service=""
        current_line=$line_num
        while [[ $current_line -gt 0 ]]; do
            prev_line=$(sed -n "${current_line}p" "$file")
            if [[ "$prev_line" =~ ^[[:space:]]+([a-zA-Z0-9_-]+): ]]; then
                source_service="${BASH_REMATCH[1]}"
                break
            fi
            current_line=$((current_line - 1))
        done
        
        if [[ -z "$source_service" ]]; then
            continue
        fi
        
        # Extract target services
        end_line=$((line_num + 10))
        sed -n "${line_num},${end_line}p" "$file" | \
        grep -E "^[[:space:]]+[[:space:]]+[a-zA-Z0-9_-]+:" | \
        while read -r dep_line; do
            target_service=$(echo "$dep_line" | sed -E 's/^[[:space:]]+[[:space:]]+([a-zA-Z0-9_-]+):.*/\1/')
            
            # Write dependency relationship
            echo "  - source: \"$source_service\"" >> "$output_file"
            echo "    target: \"$target_service\"" >> "$output_file"
            echo "    type: \"depends_on\"" >> "$output_file"
            echo "    description: \"$source_service requires $target_service\"" >> "$output_file"
            
            # Determine interface based on services
            if [[ "$target_service" == "mongodb" ]]; then
                echo "    interface: \"mongodb_driver\"" >> "$output_file"
            elif [[ "$target_service" == "ollama" || "$target_service" == "meilisearch" ]]; then
                echo "    interface: \"http_api\"" >> "$output_file"
            else
                echo "    interface: \"service\"" >> "$output_file"
            fi
            
            echo "    required: true" >> "$output_file"
            
            # Check for condition
            condition=$(grep -A 2 "^[[:space:]]\+[[:space:]]\+$target_service:" "$file" | \
                       grep "condition:" | \
                       sed -E 's/^[[:space:]]+condition:[[:space:]]+(.+)$/\1/')
            
            if [[ -n "$condition" ]]; then
                # Write startup dependency
                echo "  - source: \"$source_service\"" >> "$output_file"
                echo "    target: \"$target_service\"" >> "$output_file"
                echo "    type: \"startup_dependency\"" >> "$output_file"
                echo "    description: \"$source_service must start after $target_service is $condition\"" >> "$output_file"
                echo "    condition: \"$condition\"" >> "$output_file"
            fi
            
            # Write reverse relationship (provides service)
            echo "  - source: \"$target_service\"" >> "$output_file"
            echo "    target: \"$source_service\"" >> "$output_file"
            echo "    type: \"provides_service_to\"" >> "$output_file"
            echo "    description: \"$target_service provides service to $source_service\"" >> "$output_file"
            
            # Determine interface based on services
            if [[ "$target_service" == "mongodb" ]]; then
                echo "    interface: \"mongodb_driver\"" >> "$output_file"
            elif [[ "$target_service" == "ollama" || "$target_service" == "meilisearch" ]]; then
                echo "    interface: \"http_api\"" >> "$output_file"
            else
                echo "    interface: \"service\"" >> "$output_file"
            fi
            
            echo "    required: false" >> "$output_file"
        done
    done
    
    # Extract network relationships
    grep -n "networks:" "$file" | \
    while IFS=':' read -r line_num line_content; do
        # Skip the top-level networks section
        if [[ "$line_content" =~ ^networks: ]]; then
            continue
        fi
        
        # Get the service name
        service_name=""
        current_line=$line_num
        while [[ $current_line -gt 0 ]]; do
            prev_line=$(sed -n "${current_line}p" "$file")
            if [[ "$prev_line" =~ ^[[:space:]]+([a-zA-Z0-9_-]+): ]]; then
                service_name="${BASH_REMATCH[1]}"
                break
            fi
            current_line=$((current_line - 1))
        done
        
        if [[ -z "$service_name" ]]; then
            continue
        fi
        
        # Extract network names
        end_line=$((line_num + 5))
        sed -n "${line_num},${end_line}p" "$file" | \
        grep -E "^[[:space:]]+[[:space:]]+- " | \
        while read -r net_line; do
            network_name=$(echo "$net_line" | sed -E 's/^[[:space:]]+[[:space:]]+- (.+)$/\1/')
            
            # Write network relationship
            echo "  - source: \"$service_name\"" >> "$output_file"
            echo "    target: \"$network_name\"" >> "$output_file"
            echo "    type: \"depends_on\"" >> "$output_file"
            echo "    description: \"$service_name requires the $network_name for communication\"" >> "$output_file"
            echo "    required: true" >> "$output_file"
        done
    done
}

# Main function
main() {
    echo "Starting documentation extraction..."
    
    # Create backup of existing files
    backup_file "$COMPONENTS_FILE"
    backup_file "$INTERFACES_FILE"
    backup_file "$RELATIONSHIPS_FILE"
    
    # Initialize temporary files
    echo "# API Interfaces" > "$INTERFACES_TMP"
    echo "api_interfaces:" >> "$INTERFACES_TMP"
    
    # Extract information from source files
    extract_docker_components
    extract_relationships
    extract_cli_commands
    
    # Extract shell functions from core library files
    for file in "$CORE_DIR"/*.sh; do
        extract_shell_functions "$file"
    done
    
    # Validate the extracted documentation
    if "$SCRIPT_DIR/validate-docs.sh"; then
        # Replace the old files with the new ones
        mv "$COMPONENTS_TMP" "$COMPONENTS_FILE"
        mv "$INTERFACES_TMP" "$INTERFACES_FILE"
        mv "$RELATIONSHIPS_TMP" "$RELATIONSHIPS_FILE"
        echo "Documentation updated successfully"
    else
        echo "Documentation validation failed"
        echo "Temporary files not applied. Check $COMPONENTS_TMP, $INTERFACES_TMP, and $RELATIONSHIPS_TMP"
        exit 1
    fi
}

# Run the main function
main