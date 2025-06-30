#!/bin/zsh
#
# Simple, reliable logger for GoProX
# All output goes to stderr to avoid interfering with interactive prompts
#

# Simple logging functions - no fallbacks, no complexity
log_info() {
    echo "[INFO] $*" >&2
}

log_success() {
    echo "[SUCCESS] $*" >&2
}

log_warning() {
    echo "[WARNING] $*" >&2
}

log_error() {
    echo "[ERROR] $*" >&2
}

log_debug() {
    if [[ "${DEBUG:-}" == "1" || "${DEBUG:-}" == "true" ]]; then
        echo "[DEBUG] $*" >&2
    fi
}

# Function to prominently display current branch information
display_branch_info() {
    local operation="$1"
    local additional_info="$2"
    
    local current_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
    local git_status=$(git status --porcelain 2>/dev/null | wc -l)
    local status_text=""
    
    if [[ $git_status -gt 0 ]]; then
        status_text="⚠️  UNCOMMITTED CHANGES: $git_status files"
    else
        status_text="✅ Clean working directory"
    fi
    
    echo ""
    echo "🌿 BRANCH INFORMATION"
    echo "===================="
    echo "📍 CURRENT BRANCH: $current_branch"
    echo "📍 OPERATION: $operation"
    echo "📍 STATUS: $status_text"
    if [[ -n "$additional_info" ]]; then
        echo "📍 INFO: $additional_info"
    fi
    echo "===================="
    echo ""
}
