# Shell Script Style Guide

This document outlines the coding standards and best practices for shell scripts in the LOCAL-LLM-Stack project. Following these guidelines ensures consistency, readability, and maintainability across all shell scripts.

## Table of Contents

1. [File Structure](#file-structure)
2. [Naming Conventions](#naming-conventions)
3. [Formatting](#formatting)
4. [Comments and Documentation](#comments-and-documentation)
5. [Variables](#variables)
6. [Functions](#functions)
7. [Error Handling](#error-handling)
8. [Logging](#logging)
9. [Command Execution](#command-execution)
10. [Security Considerations](#security-considerations)
11. [Testing](#testing)

## File Structure

### Standard File Header

All shell scripts should begin with the following header:

```bash
#!/bin/bash
# filename.sh - Brief description of the script's purpose
# Additional details about the script if necessary

# Guard against multiple inclusion (for library scripts)
if [[ -n "$_FILENAME_SH_INCLUDED" ]]; then
  return 0
fi
_FILENAME_SH_INCLUDED=1

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/path/to/dependency.sh"
```

### Script Organization

Scripts should be organized in the following order:

1. Shebang and file header
2. Guard against multiple inclusion (for library scripts)
3. Source dependencies
4. Constants and global variables
5. Function definitions
6. Main execution logic (for executable scripts)

## Naming Conventions

### Files

- Use lowercase names with underscores for word separation
- Use the `.sh` extension for all shell scripts
- Name should reflect the script's purpose
- Library scripts should have descriptive names indicating their functionality

Examples:
```
generate_secrets.sh
update_config.sh
docker_utils.sh
```

### Variables

- Use uppercase for constants and global variables
- Use lowercase with underscores for local variables
- Use descriptive names that indicate the variable's purpose
- Prefix internal/private variables with underscore

Examples:
```bash
# Constants and globals
readonly MAX_RETRIES=3
DEFAULT_PORT=8080

# Local variables
local user_name="admin"
local temp_file="/tmp/config.tmp"

# Internal/private variables
_internal_counter=0
```

### Functions

- Use lowercase with underscores for word separation
- Use descriptive names that indicate the function's purpose
- Prefix internal/private functions with underscore

Examples:
```bash
# Public functions
function validate_input() { ... }
function start_service() { ... }

# Internal/private functions
function _parse_config_file() { ... }
```

## Formatting

### Indentation

- Use 2 spaces for indentation (not tabs)
- Align continuation lines with spaces

### Line Length

- Keep lines to a maximum of 80 characters where possible
- Break long commands using backslashes for continuation

### Spacing

- Place spaces around operators
- No space between function name and opening parenthesis
- One space after keywords like `if`, `for`, `while`
- No space after the opening parenthesis or before the closing parenthesis

Examples:
```bash
# Correct
if [[ $count -eq 0 ]]; then
  echo "Count is zero"
fi

# Correct function definition
function validate_input() {
  local input=$1
  # ...
}
```

### Braces and Brackets

- Always use double brackets `[[ ]]` for conditional expressions
- Always use curly braces `${}` when referencing variables
- Always use curly braces for all but the simplest command blocks

Examples:
```bash
# Variable reference
echo "${variable_name}"

# Conditional expression
if [[ "${count}" -eq 0 ]]; then
  echo "Count is zero"
fi
```

## Comments and Documentation

### Script Documentation

Every script should have:
- A brief description in the file header
- Usage information for executable scripts
- Version information if applicable

### Function Documentation

Every function should have:
- A brief description of its purpose
- Documentation of parameters
- Documentation of return values and exit codes

Example:
```bash
# Validates user input for configuration
# 
# Parameters:
#   $1 - Input string to validate
#   $2 - Type of validation (optional, default: "string")
#
# Returns:
#   0 - If validation succeeds
#   1 - If validation fails
function validate_input() {
  local input=$1
  local type=${2:-"string"}
  
  # Function implementation
}
```

### Inline Comments

- Use inline comments sparingly and only when necessary
- Place comments on their own line before the code they describe
- Keep comments up-to-date with code changes

## Variables

### Declaration and Assignment

- Always use local variables inside functions
- Quote variable values to prevent word splitting and globbing
- Use `readonly` for constants
- Use meaningful default values with `${var:-default}`

Examples:
```bash
# Global constant
readonly MAX_RETRIES=3

# Function with local variables
function process_file() {
  local file_path=$1
  local output_dir=${2:-"./output"}
  
  # Function implementation
}
```

### Variable Expansion

- Use `${variable}` instead of `$variable` for clarity
- Use `${variable:-default}` for default values
- Use `${variable:?error message}` to ensure variables are set

Examples:
```bash
# Default value
output_dir=${OUTPUT_DIR:-"./output"}

# Ensure variable is set
api_key=${API_KEY:?"API key must be set"}
```

## Functions

### Definition

- Use the `function` keyword for clarity
- Always use local variables
- Document parameters and return values
- Return meaningful exit codes

Example:
```bash
function process_file() {
  local file_path=$1
  local output_dir=${2:-"./output"}
  
  if [[ ! -f "${file_path}" ]]; then
    log_error "File not found: ${file_path}"
    return $ERR_FILE_NOT_FOUND
  fi
  
  # Process the file
  
  return $ERR_SUCCESS
}
```

### Usage

- Always check return values from functions
- Use meaningful variable names for function results

Example:
```bash
process_file "${input_file}" "${output_dir}"
if [[ $? -ne 0 ]]; then
  log_error "Failed to process file: ${input_file}"
  exit 1
fi
```

## Error Handling

### Exit Codes

- Use predefined error codes from the error.sh module
- Return appropriate error codes from functions
- Exit with appropriate error codes from scripts

### Error Checking

- Always check the return value of commands and functions
- Use the `handle_error` function for consistent error handling
- Use the `assert` function to validate conditions

Example:
```bash
# Check command result
docker ps &>/dev/null
if [[ $? -ne 0 ]]; then
  handle_error $ERR_DOCKER_ERROR "Docker is not running"
fi

# Check function result
validate_input "${user_input}"
if [[ $? -ne 0 ]]; then
  handle_error $ERR_VALIDATION_ERROR "Invalid input: ${user_input}"
fi

# Use assert
assert "[[ -f ${config_file} ]]" $ERR_FILE_NOT_FOUND "Config file not found: ${config_file}"
```

### Cleanup

- Use trap to ensure cleanup on exit
- Use the `set_cleanup_trap` function for consistent cleanup

Example:
```bash
function cleanup() {
  # Cleanup operations
  rm -f "${temp_file}"
  log_debug "Cleanup completed"
}

set_cleanup_trap cleanup
```

## Logging

### Log Levels

Use the appropriate log level for each message:
- `log_debug` - Detailed debugging information
- `log_info` - General information about script execution
- `log_success` - Successful operations
- `log_warn` - Warning messages that don't prevent execution
- `log_error` - Error messages that may prevent successful execution
- `log_fatal` - Critical errors that cause the script to exit

### Log Messages

- Be concise but descriptive
- Include relevant variable values
- Use consistent terminology

Example:
```bash
log_debug "Processing file: ${file_path}"
log_info "Starting backup process for ${database_name}"
log_success "Backup completed successfully: ${backup_file}"
log_warn "Configuration file not found, using defaults"
log_error "Failed to connect to database: ${database_name}"
log_fatal "Critical error: ${error_message}"
```

## Command Execution

### Command Substitution

- Use `$()` instead of backticks
- Check the exit status of commands

Example:
```bash
# Correct
user_id=$(id -u)
if [[ $? -ne 0 ]]; then
  handle_error $ERR_COMMAND_NOT_FOUND "Failed to get user ID"
fi

# Incorrect
user_id=`id -u`
```

### Error Redirection

- Redirect stderr to stdout when capturing command output
- Use `/dev/null` to suppress output when appropriate

Example:
```bash
# Capture all output
output=$(command 2>&1)

# Suppress all output
command &>/dev/null

# Suppress only stderr
command 2>/dev/null
```

## Security Considerations

### Input Validation

- Always validate user input
- Use the validation functions from validation.sh
- Be cautious with command substitution and eval

### Secrets Management

- Never hardcode secrets in scripts
- Use environment variables or secure storage for secrets
- Use the secrets management functions from the core library

### Permissions

- Set appropriate permissions for script files (e.g., 755 for executables)
- Check for required permissions before performing operations
- Use the `need_sudo` function to check if elevated privileges are required

## Testing

### Unit Testing

- Write unit tests for all functions
- Use the testing framework in lib/test/
- Test both success and failure cases

### Integration Testing

- Write integration tests for script workflows
- Test with realistic data and configurations
- Verify that scripts work together as expected

### Test Documentation

- Document test cases and expected results
- Include instructions for running tests
- Update tests when functionality changes