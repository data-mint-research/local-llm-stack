#!/bin/bash
# config.sh - Configuration management for LOCAL-LLM-Stack
# This file has been refactored to use the new core library

# Source core library modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/core/logging.sh"
source "$SCRIPT_DIR/core/config.sh"

# This file now serves as a compatibility layer for scripts that still
# import config.sh directly. All functionality has been moved to the
# core/config.sh module.

log_debug "Config module initialized (compatibility layer)"