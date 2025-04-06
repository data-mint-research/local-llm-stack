#!/bin/bash
# utils.sh - Utility functions for LOCAL-LLM-Stack
# This file has been refactored to use the new core library

# Source core library modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/core/logging.sh"
source "$SCRIPT_DIR/core/error.sh"
source "$SCRIPT_DIR/core/system.sh"

# This file now serves as a compatibility layer for scripts that still
# import utils.sh directly. All functionality has been moved to the
# core library modules.

log_debug "Utils module initialized (compatibility layer)"
