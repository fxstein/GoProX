#!/bin/zsh
# logger.zsh: Centralized logging module for GoProX scripts
#
# Usage:
#   export LOGFILE=relative/or/absolute/path/to/logfile.log  # Optional
#   export LOGFILE_OLD=relative/or/absolute/path/to/logfile.log.old  # Optional
#   export LOG_MAX_SIZE=16384  # Optional, bytes
#   source "$(dirname $0)/logger.zsh"
#   log_info "Message"
#   log_error "Error message"
#   log_debug "Debug message"
#   log_json "INFO" "Message"  # JSON log format
#
# If LOGFILE and LOGFILE_OLD are not set, defaults are output/goprox.log and output/goprox.log.old

# --- Configurable Variables ---
: "${LOGFILE:=output/goprox.log}"
: "${LOGFILE_OLD:=output/goprox.log.old}"
: "${LOG_MAX_SIZE:=1048576}"
mkdir -p "$(dirname "$LOGFILE")"
: > "$LOGFILE"

# --- Internal Helpers ---
function _log_rotate_if_needed() {
  if [[ -f "$LOGFILE" && $(stat -f%z "$LOGFILE") -ge $LOG_MAX_SIZE ]]; then
    mv "$LOGFILE" "$LOGFILE_OLD"
    : > "$LOGFILE"
  fi
}

function _log_write() {
  local level="$1"
  local msg="$2"
  local ts
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  _log_rotate_if_needed
  echo "[$ts] [$level] $msg" | tee -a "$LOGFILE"
}

function log_info()    { _log_write "INFO"    "$*"; }
function log_success() { _log_write "SUCCESS" "$*"; }
function log_warning() { _log_write "WARNING" "$*"; }
function log_error()   { _log_write "ERROR"   "$*"; }
function log_debug()   { [[ "$LOG_VERBOSE" == 1 ]] && _log_write "DEBUG" "$*"; }
function log_json()    {
  local level="$1"; shift
  local msg="$*"
  local ts
  ts="$(date '+%Y-%m-%dT%H:%M:%S')"
  _log_rotate_if_needed
  echo "{\"timestamp\":\"$ts\",\"level\":\"$level\",\"message\":\"$msg\"}" | tee -a "$LOGFILE"
}

function log_time_start() {
  export LOG_TIME_START=$(date +%s)
}
function log_time_end() {
  local end=$(date +%s)
  local duration=$((end - LOG_TIME_START))
  log_info "Elapsed time: ${duration}s"
}

# Set up error trap for debugging (only in interactive mode or when explicitly enabled)
if [[ "${INTERACTIVE:-}" == "true" || "${ENABLE_ERROR_TRAP:-}" == "true" ]]; then
    trap 'log_error "Error on line $LINENO"' ERR
fi

# --- Usage Example ---
# source scripts/core/logger.zsh
# log_info "Starting script"
# log_debug "Debug info"
# log_json "INFO" "Structured log message"
# log_time_start
# ... your code ...
# log_time_end
# log_trap_errors 

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

# Function to display branch info before critical operations
display_branch_warning() {
    local operation="$1"
    local target_branch="$2"
    local current_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
    
    if [[ "$current_branch" != "$target_branch" ]]; then
        echo ""
        echo "⚠️  BRANCH MISMATCH WARNING"
        echo "=========================="
        echo "📍 CURRENT BRANCH: $current_branch"
        echo "📍 EXPECTED BRANCH: $target_branch"
        echo "📍 OPERATION: $operation"
        echo "=========================="
        echo ""
        echo "❓ Do you want to continue anyway? (y/N)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log_error "Operation cancelled due to branch mismatch"
            exit 1
        fi
    fi
}

# Function to generate short branch hash (Git-style)
get_branch_hash() {
    local branch="$1"
    echo "$branch" | sha1sum | cut -c1-8
}

# Function to get current branch with hash display
get_branch_display() {
    local current_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
    local branch_hash=$(get_branch_hash "$current_branch")
    
    # For short branches (≤15 chars), show full name
    # For longer branches, show type prefix + hash
    if [[ ${#current_branch} -le 15 ]]; then
        echo "$current_branch"
    else
        # Extract branch type prefix
        local branch_type=""
        if [[ "$current_branch" =~ ^fix/ ]]; then
            branch_type="fix"
        elif [[ "$current_branch" =~ ^feature/ ]]; then
            branch_type="feat"
        elif [[ "$current_branch" =~ ^release/ ]]; then
            branch_type="rel"
        elif [[ "$current_branch" =~ ^hotfix/ ]]; then
            branch_type="hot"
        elif [[ "$current_branch" == "develop" ]]; then
            branch_type="dev"
        elif [[ "$current_branch" == "main" ]]; then
            branch_type="main"
        else
            branch_type="br"
        fi
        
        echo "${branch_type}/${branch_hash}"
    fi
}

# Function to get full branch name from hash (for debugging)
get_full_branch_name() {
    local hash="$1"
    local current_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
    local current_hash=$(get_branch_hash "$current_branch")
    
    if [[ "$current_hash" == "$hash" ]]; then
        echo "$current_branch"
    else
        echo "unknown"
    fi
}

# Enhanced logging functions with branch awareness
log_info() {
    local message="$1"
    local branch_display=$(get_branch_display)
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [[ -n "$LOGFILE" ]]; then
        echo "[$timestamp] [$branch_display] [INFO] $message" >> "$LOGFILE"
    fi
    echo "[$timestamp] [$branch_display] [INFO] $message" >&2
}

log_error() {
    local message="$1"
    local branch_display=$(get_branch_display)
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [[ -n "$LOGFILE" ]]; then
        echo "[$timestamp] [$branch_display] [ERROR] $message" >> "$LOGFILE"
    fi
    echo "[$timestamp] [$branch_display] [ERROR] $message" >&2
}

log_warn() {
    local message="$1"
    local branch_display=$(get_branch_display)
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [[ -n "$LOGFILE" ]]; then
        echo "[$timestamp] [$branch_display] [WARN] $message" >> "$LOGFILE"
    fi
    echo "[$timestamp] [$branch_display] [WARN] $message" >&2
}

log_debug() {
    local message="$1"
    local branch_display=$(get_branch_display)
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [[ -n "$LOGFILE" ]]; then
        echo "[$timestamp] [$branch_display] [DEBUG] $message" >> "$LOGFILE"
    fi
    echo "[$timestamp] [$branch_display] [DEBUG] $message" >&2
}

# Test function to demonstrate branch type prefixes
test_branch_display() {
    echo "=== Branch Type Prefix Examples ==="
    
    # Test different branch name patterns
    local test_branches=(
        "fix/bug-description-123-20250629-120000"
        "feature/new-awesome-feature-456-20250629-120000"
        "release/01.12.1-dev"
        "hotfix/critical-security-fix-789-20250629-120000"
        "develop"
        "main"
        "custom/unknown-branch-type"
    )
    
    for branch in "${test_branches[@]}"; do
        local hash=$(get_branch_hash "$branch")
        local display=$(get_branch_display_for_test "$branch")
        echo "Branch: $branch"
        echo "  Display: $display"
        echo "  Hash: $hash"
        echo ""
    done
}

# Helper function for testing (simulates get_branch_display with a specific branch)
get_branch_display_for_test() {
    local current_branch="$1"
    local branch_hash=$(get_branch_hash "$current_branch")
    
    if [[ ${#current_branch} -le 15 ]]; then
        echo "$current_branch"
    else
        local branch_type=""
        if [[ "$current_branch" =~ ^fix/ ]]; then
            branch_type="fix"
        elif [[ "$current_branch" =~ ^feature/ ]]; then
            branch_type="feat"
        elif [[ "$current_branch" =~ ^release/ ]]; then
            branch_type="rel"
        elif [[ "$current_branch" =~ ^hotfix/ ]]; then
            branch_type="hot"
        elif [[ "$current_branch" == "develop" ]]; then
            branch_type="dev"
        elif [[ "$current_branch" == "main" ]]; then
            branch_type="main"
        else
            branch_type="br"
        fi
        
        echo "${branch_type}/${branch_hash}"
    fi
} 