#!/bin/bash
# migrate_custom_modules.sh - Migrate custom user modules to the new standardized format
# This script helps users migrate their custom modules to the new standardized format
# while preserving their functionality and customizations.

# Get the absolute path of the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
LIB_DIR="$ROOT_DIR/lib"

# Source core libraries
source "$LIB_DIR/core/logging.sh"
source "$LIB_DIR/core/error.sh"
source "$LIB_DIR/core/validation.sh"
source "$LIB_DIR/core/config.sh"
source "$LIB_DIR/core/system.sh"

# Default options
VERBOSE=false
FORCE=false
BACKUP=true
DRY_RUN=false
CUSTOM_MODULES_DIR=""
TEMPLATE_MODULE_DIR="$ROOT_DIR/modules/template"

# Function to display usage information
function display_usage() {
  echo "Usage: $0 [OPTIONS] [MODULE_DIRS...]"
  echo "Migrate custom user modules to the new standardized format"
  echo ""
  echo "Options:"
  echo "  --verbose           Display detailed information during execution"
  echo "  --force             Force migration even if validation fails"
  echo "  --no-backup         Skip creating backups of existing modules"
  echo "  --dry-run           Show what would be done without making changes"
  echo "  --modules-dir DIR   Specify custom modules directory to migrate from"
  echo "  --help              Display this help message and exit"
  echo ""
  echo "Examples:"
  echo "  $0 --dry-run                      # Show what would be done without making changes"
  echo "  $0 --modules-dir /path/to/modules # Migrate from a custom modules directory"
  echo "  $0 custom-module1 custom-module2  # Migrate specific modules"
}

# Parse command line arguments
MODULES_TO_MIGRATE=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --verbose)
      VERBOSE=true
      shift
      ;;
    --force)
      FORCE=true
      shift
      ;;
    --no-backup)
      BACKUP=false
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --modules-dir)
      CUSTOM_MODULES_DIR="$2"
      shift 2
      ;;
    --help)
      display_usage
      exit 0
      ;;
    -*)
      log_error "Unknown option: $1"
      display_usage
      exit 1
      ;;
    *)
      MODULES_TO_MIGRATE+=("$1")
      shift
      ;;
  esac
done

# Set log level based on verbosity
if [[ "$VERBOSE" == "true" ]]; then
  set_log_level "debug"
else
  set_log_level "info"
fi

# Set source modules directory
if [[ -n "$CUSTOM_MODULES_DIR" ]]; then
  SOURCE_MODULES_DIR="$CUSTOM_MODULES_DIR"
  log_info "Using custom modules directory: $SOURCE_MODULES_DIR"
else
  SOURCE_MODULES_DIR="$ROOT_DIR/modules"
  log_info "Using default modules directory: $SOURCE_MODULES_DIR"
fi

# Log the start of the migration
log_info "Starting custom modules migration"
if [[ "$DRY_RUN" == "true" ]]; then
  log_warn "Running in dry-run mode. No changes will be made."
fi

# Function to create backup
function create_backup() {
  local module_name="$1"
  local module_dir="$SOURCE_MODULES_DIR/$module_name"
  
  if [[ "$BACKUP" == "false" ]]; then
    log_warn "Skipping backup as requested"
    return $ERR_SUCCESS
  fi
  
  log_info "Creating backup of module: $module_name"
  
  # Check if module directory exists
  if [[ ! -d "$module_dir" ]]; then
    log_error "Module directory not found: $module_dir"
    return $ERR_FILE_NOT_FOUND
  fi
  
  # Create backup directory with timestamp
  local timestamp=$(date +"%Y%m%d_%H%M%S")
  local backup_dir="$ROOT_DIR/backups/modules_$timestamp/$module_name"
  
  # Ensure backup directory exists
  mkdir -p "$backup_dir"
  
  # Backup module files
  cp -r "$module_dir/"* "$backup_dir/"
  
  log_success "Backup created successfully at $backup_dir"
  return $ERR_SUCCESS
}

# Function to validate module
function validate_module() {
  local module_name="$1"
  local module_dir="$SOURCE_MODULES_DIR/$module_name"
  
  log_info "Validating module: $module_name"
  
  # Check if module directory exists
  if [[ ! -d "$module_dir" ]]; then
    log_error "Module directory not found: $module_dir"
    return $ERR_FILE_NOT_FOUND
  fi
  
  # Check if docker-compose.yml exists
  if [[ ! -f "$module_dir/docker-compose.yml" ]]; then
    log_warn "docker-compose.yml not found in module: $module_name"
    if [[ "$FORCE" != "true" ]]; then
      log_error "Module validation failed. Use --force to migrate anyway."
      return $ERR_VALIDATION_ERROR
    fi
  fi
  
  # Check if README.md exists
  if [[ ! -f "$module_dir/README.md" ]]; then
    log_warn "README.md not found in module: $module_name"
  fi
  
  log_success "Module validated successfully: $module_name"
  return $ERR_SUCCESS
}

# Function to check if template module exists
function check_template_module() {
  log_info "Checking if template module exists..."
  
  # Check if template module directory exists
  if [[ ! -d "$TEMPLATE_MODULE_DIR" ]]; then
    log_error "Template module directory not found: $TEMPLATE_MODULE_DIR"
    return $ERR_FILE_NOT_FOUND
  fi
  
  # Check if template module has required files
  if [[ ! -f "$TEMPLATE_MODULE_DIR/docker-compose.yml" ]]; then
    log_error "Template module docker-compose.yml not found"
    return $ERR_FILE_NOT_FOUND
  fi
  
  if [[ ! -f "$TEMPLATE_MODULE_DIR/README.md" ]]; then
    log_error "Template module README.md not found"
    return $ERR_FILE_NOT_FOUND
  fi
  
  if [[ ! -d "$TEMPLATE_MODULE_DIR/api" ]]; then
    log_error "Template module api directory not found"
    return $ERR_FILE_NOT_FOUND
  fi
  
  if [[ ! -d "$TEMPLATE_MODULE_DIR/config" ]]; then
    log_error "Template module config directory not found"
    return $ERR_FILE_NOT_FOUND
  fi
  
  if [[ ! -d "$TEMPLATE_MODULE_DIR/scripts" ]]; then
    log_error "Template module scripts directory not found"
    return $ERR_FILE_NOT_FOUND
  fi
  
  if [[ ! -d "$TEMPLATE_MODULE_DIR/tests" ]]; then
    log_error "Template module tests directory not found"
    return $ERR_FILE_NOT_FOUND
  fi
  
  log_success "Template module exists and has all required files"
  return $ERR_SUCCESS
}

# Function to migrate module structure
function migrate_module_structure() {
  local module_name="$1"
  local module_dir="$SOURCE_MODULES_DIR/$module_name"
  
  log_info "Migrating module structure: $module_name"
  
  # Create API directory if it doesn't exist
  if [[ ! -d "$module_dir/api" ]]; then
    log_info "Creating API directory..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
      log_info "Dry run: Would create API directory"
    else
      mkdir -p "$module_dir/api"
      
      # Create module API file
      if [[ ! -f "$module_dir/api/module_api.sh" ]]; then
        cp "$TEMPLATE_MODULE_DIR/api/module_api.sh" "$module_dir/api/module_api.sh"
        # Update module name in the API file
        sed -i "s/template/$module_name/g" "$module_dir/api/module_api.sh"
        chmod +x "$module_dir/api/module_api.sh"
      fi
    fi
  fi
  
  # Create config directory if it doesn't exist
  if [[ ! -d "$module_dir/config" ]]; then
    log_info "Creating config directory..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
      log_info "Dry run: Would create config directory"
    else
      mkdir -p "$module_dir/config"
      
      # Create env.conf file if it doesn't exist
      if [[ ! -f "$module_dir/config/env.conf" ]]; then
        cp "$TEMPLATE_MODULE_DIR/config/env.conf" "$module_dir/config/env.conf"
        # Update module name in the env.conf file
        sed -i "s/template/$module_name/g" "$module_dir/config/env.conf"
      fi
    fi
  fi
  
  # Create scripts directory if it doesn't exist
  if [[ ! -d "$module_dir/scripts" ]]; then
    log_info "Creating scripts directory..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
      log_info "Dry run: Would create scripts directory"
    else
      mkdir -p "$module_dir/scripts"
      
      # Create setup.sh file if it doesn't exist
      if [[ ! -f "$module_dir/scripts/setup.sh" ]]; then
        cp "$TEMPLATE_MODULE_DIR/scripts/setup.sh" "$module_dir/scripts/setup.sh"
        # Update module name in the setup.sh file
        sed -i "s/template/$module_name/g" "$module_dir/scripts/setup.sh"
        chmod +x "$module_dir/scripts/setup.sh"
      fi
    fi
  fi
  
  # Create tests directory if it doesn't exist
  if [[ ! -d "$module_dir/tests" ]]; then
    log_info "Creating tests directory..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
      log_info "Dry run: Would create tests directory"
    else
      mkdir -p "$module_dir/tests/unit"
      mkdir -p "$module_dir/tests/integration"
      
      # Create unit test file if it doesn't exist
      if [[ ! -f "$module_dir/tests/unit/test_module.sh" ]]; then
        cp "$TEMPLATE_MODULE_DIR/tests/unit/test_module.sh" "$module_dir/tests/unit/test_module.sh"
        # Update module name in the test file
        sed -i "s/template/$module_name/g" "$module_dir/tests/unit/test_module.sh"
        chmod +x "$module_dir/tests/unit/test_module.sh"
      fi
      
      # Create integration test file if it doesn't exist
      if [[ ! -f "$module_dir/tests/integration/test_integration.sh" ]]; then
        cp "$TEMPLATE_MODULE_DIR/tests/integration/test_integration.sh" "$module_dir/tests/integration/test_integration.sh"
        # Update module name in the test file
        sed -i "s/template/$module_name/g" "$module_dir/tests/integration/test_integration.sh"
        chmod +x "$module_dir/tests/integration/test_integration.sh"
      fi
    fi
  fi
  
  # Create README.md if it doesn't exist
  if [[ ! -f "$module_dir/README.md" ]]; then
    log_info "Creating README.md..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
      log_info "Dry run: Would create README.md"
    else
      cp "$TEMPLATE_MODULE_DIR/README.md" "$module_dir/README.md"
      # Update module name in the README.md file
      sed -i "s/Template Module/$module_name Module/g" "$module_dir/README.md"
      sed -i "s/template/$module_name/g" "$module_dir/README.md"
    fi
  fi
  
  log_success "Module structure migrated successfully: $module_name"
  return $ERR_SUCCESS
}

# Function to migrate docker-compose.yml
function migrate_docker_compose() {
  local module_name="$1"
  local module_dir="$SOURCE_MODULES_DIR/$module_name"
  
  log_info "Migrating docker-compose.yml: $module_name"
  
  # Check if docker-compose.yml exists
  if [[ ! -f "$module_dir/docker-compose.yml" ]]; then
    log_warn "docker-compose.yml not found in module: $module_name"
    
    if [[ "$DRY_RUN" == "true" ]]; then
      log_info "Dry run: Would create docker-compose.yml"
    else
      cp "$TEMPLATE_MODULE_DIR/docker-compose.yml" "$module_dir/docker-compose.yml"
      # Update module name in the docker-compose.yml file
      sed -i "s/template/$module_name/g" "$module_dir/docker-compose.yml"
    fi
    
    return $ERR_SUCCESS
  fi
  
  # Check if docker-compose.yml needs to be updated
  local needs_update=false
  
  # Check if docker-compose.yml has the correct version
  if ! grep -q "version:" "$module_dir/docker-compose.yml"; then
    needs_update=true
  fi
  
  # Check if docker-compose.yml has the correct network configuration
  if ! grep -q "networks:" "$module_dir/docker-compose.yml"; then
    needs_update=true
  fi
  
  # Update docker-compose.yml if needed
  if [[ "$needs_update" == "true" ]]; then
    log_info "docker-compose.yml needs to be updated"
    
    if [[ "$DRY_RUN" == "true" ]]; then
      log_info "Dry run: Would update docker-compose.yml"
    else
      # Create a backup of the original file
      cp "$module_dir/docker-compose.yml" "$module_dir/docker-compose.yml.bak"
      
      # Extract service definitions from the original file
      local services=$(sed -n '/services:/,/^[a-z]/p' "$module_dir/docker-compose.yml" | sed '$d')
      
      # Create a new docker-compose.yml file with the correct structure
      cat > "$module_dir/docker-compose.yml" << EOF
version: '3.8'

$services

networks:
  default:
    name: llm-stack-network
    external: true
EOF
    fi
  else
    log_info "docker-compose.yml is already up to date"
  fi
  
  log_success "docker-compose.yml migrated successfully: $module_name"
  return $ERR_SUCCESS
}

# Function to migrate module scripts
function migrate_module_scripts() {
  local module_name="$1"
  local module_dir="$SOURCE_MODULES_DIR/$module_name"
  
  log_info "Migrating module scripts: $module_name"
  
  # Find all shell scripts in the module directory
  local shell_scripts=$(find "$module_dir" -name "*.sh" -type f)
  
  for script in $shell_scripts; do
    log_info "Checking script: $script"
    
    # Check if script has the correct shebang
    if ! grep -q "#!/bin/bash" "$script"; then
      log_info "Script needs shebang update: $script"
      
      if [[ "$DRY_RUN" == "true" ]]; then
        log_info "Dry run: Would update shebang in $script"
      else
        # Add shebang if it doesn't exist
        sed -i '1s/^/#!/bin/bash\n/' "$script"
      fi
    fi
    
    # Check if script is executable
    if [[ ! -x "$script" ]]; then
      log_info "Script needs executable permission: $script"
      
      if [[ "$DRY_RUN" == "true" ]]; then
        log_info "Dry run: Would make $script executable"
      else
        chmod +x "$script"
      fi
    fi
    
    # Check if script sources core libraries
    if ! grep -q "source.*core/logging.sh" "$script" && ! grep -q "source.*core/error.sh" "$script"; then
      log_info "Script needs core libraries: $script"
      
      if [[ "$DRY_RUN" == "true" ]]; then
        log_info "Dry run: Would add core libraries to $script"
      else
        # Add core libraries if they don't exist
        sed -i '2i\
# Get the absolute path of the script directory\
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"\
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"\
\
# Source core libraries\
source "$ROOT_DIR/lib/core/logging.sh"\
source "$ROOT_DIR/lib/core/error.sh"\
' "$script"
      fi
    fi
  done
  
  log_success "Module scripts migrated successfully: $module_name"
  return $ERR_SUCCESS
}

# Function to validate migrated module
function validate_migrated_module() {
  local module_name="$1"
  local module_dir="$SOURCE_MODULES_DIR/$module_name"
  
  log_info "Validating migrated module: $module_name"
  
  # Check if required directories exist
  for dir in api config scripts tests; do
    if [[ ! -d "$module_dir/$dir" ]]; then
      log_error "Required directory not found: $dir"
      if [[ "$FORCE" != "true" ]]; then
        return $ERR_VALIDATION_ERROR
      fi
    fi
  done
  
  # Check if required files exist
  if [[ ! -f "$module_dir/docker-compose.yml" ]]; then
    log_error "docker-compose.yml not found"
    if [[ "$FORCE" != "true" ]]; then
      return $ERR_VALIDATION_ERROR
    fi
  fi
  
  if [[ ! -f "$module_dir/README.md" ]]; then
    log_error "README.md not found"
    if [[ "$FORCE" != "true" ]]; then
      return $ERR_VALIDATION_ERROR
    fi
  fi
  
  # Check if API file exists
  if [[ ! -f "$module_dir/api/module_api.sh" ]]; then
    log_error "module_api.sh not found"
    if [[ "$FORCE" != "true" ]]; then
      return $ERR_VALIDATION_ERROR
    fi
  fi
  
  # Check if setup script exists
  if [[ ! -f "$module_dir/scripts/setup.sh" ]]; then
    log_error "setup.sh not found"
    if [[ "$FORCE" != "true" ]]; then
      return $ERR_VALIDATION_ERROR
    fi
  fi
  
  # Check if test files exist
  if [[ ! -f "$module_dir/tests/unit/test_module.sh" ]]; then
    log_error "test_module.sh not found"
    if [[ "$FORCE" != "true" ]]; then
      return $ERR_VALIDATION_ERROR
    fi
  fi
  
  if [[ ! -f "$module_dir/tests/integration/test_integration.sh" ]]; then
    log_error "test_integration.sh not found"
    if [[ "$FORCE" != "true" ]]; then
      return $ERR_VALIDATION_ERROR
    fi
  fi
  
  log_success "Migrated module validated successfully: $module_name"
  return $ERR_SUCCESS
}

# Function to migrate a single module
function migrate_module() {
  local module_name="$1"
  
  log_info "Migrating module: $module_name"
  
  # Skip template module
  if [[ "$module_name" == "template" ]]; then
    log_info "Skipping template module"
    return $ERR_SUCCESS
  fi
  
  # Validate module
  validate_module "$module_name"
  if [[ $? -ne 0 && "$FORCE" != "true" ]]; then
    log_error "Module validation failed: $module_name"
    return $ERR_VALIDATION_ERROR
  fi
  
  # Create backup
  create_backup "$module_name"
  if [[ $? -ne 0 ]]; then
    log_error "Backup creation failed: $module_name"
    return $ERR_GENERAL
  fi
  
  # Migrate module structure
  migrate_module_structure "$module_name"
  if [[ $? -ne 0 ]]; then
    log_error "Module structure migration failed: $module_name"
    return $ERR_GENERAL
  fi
  
  # Migrate docker-compose.yml
  migrate_docker_compose "$module_name"
  if [[ $? -ne 0 ]]; then
    log_error "docker-compose.yml migration failed: $module_name"
    return $ERR_GENERAL
  fi
  
  # Migrate module scripts
  migrate_module_scripts "$module_name"
  if [[ $? -ne 0 ]]; then
    log_error "Module scripts migration failed: $module_name"
    return $ERR_GENERAL
  fi
  
  # Validate migrated module
  validate_migrated_module "$module_name"
  if [[ $? -ne 0 && "$FORCE" != "true" ]]; then
    log_error "Migrated module validation failed: $module_name"
    return $ERR_VALIDATION_ERROR
  fi
  
  log_success "Module migrated successfully: $module_name"
  return $ERR_SUCCESS
}

# Main function
function main() {
  log_info "Starting custom modules migration"
  
  # Check if template module exists
  check_template_module
  if [[ $? -ne 0 ]]; then
    log_error "Template module check failed"
    exit $ERR_DEPENDENCY_ERROR
  fi
  
  # If no specific modules are provided, find all modules
  if [[ ${#MODULES_TO_MIGRATE[@]} -eq 0 ]]; then
    log_info "No specific modules provided, finding all modules..."
    
    # Find all module directories
    for module_dir in "$SOURCE_MODULES_DIR"/*; do
      if [[ -d "$module_dir" ]]; then
        local module_name=$(basename "$module_dir")
        if [[ "$module_name" != "template" ]]; then
          MODULES_TO_MIGRATE+=("$module_name")
        fi
      fi
    done
    
    log_info "Found ${#MODULES_TO_MIGRATE[@]} modules to migrate"
  fi
  
  # Migrate each module
  for module_name in "${MODULES_TO_MIGRATE[@]}"; do
    migrate_module "$module_name"
    if [[ $? -ne 0 ]]; then
      log_error "Module migration failed: $module_name"
      if [[ "$FORCE" != "true" ]]; then
        exit $ERR_GENERAL
      fi
    fi
  done
  
  log_success "Custom modules migration completed successfully"
  log_info "The following tasks have been completed:"
  log_info "1. Backed up existing modules"
  log_info "2. Migrated module structures"
  log_info "3. Migrated docker-compose.yml files"
  log_info "4. Migrated module scripts"
  log_info "5. Validated migrated modules"
  
  log_warn "IMPORTANT: Please review the migrated modules and test them to ensure everything works correctly"
  log_info "For more information, see the migration guide: docs/migration_guide.md"
}

# Run the main function
main