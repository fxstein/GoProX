#!/bin/zsh
#
# Simple, reliable logger for GoProX
# All output goes to stderr to avoid interfering with interactive prompts
#

# Function to get current branch with hash display
get_branch_display() {
    local current_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
    local branch_hash=$(echo "$current_branch" | sha1sum | cut -c1-8 2>/dev/null || echo "unknown")
    
    # For short branches (≤15 chars), show full name
    # For longer branches, show type prefix + hash
    if [[ ${#current_branch} -le 15 ]]; then
        echo "$current_branch"
    else
        # Extract branch type prefix
        local branch_type=""
        if [[ "$current_branch" =~ ^fix/ ]]; then
            branch_type="fix"
        elif [[ "$current_branch" =~ ^feat/ ]]; then
            branch_type="feat"
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
            branch_type="other"
        fi
        echo "${branch_type}/${branch_hash}"
    fi
}

# Function to get formatted timestamp
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Simple logging functions with formatting
log_info() {
    local ts=$(get_timestamp)
    local branch=$(get_branch_display)
    echo "[$ts] [$branch] [INFO] $*" >&2
}

log_success() {
    local ts=$(get_timestamp)
    local branch=$(get_branch_display)
    echo "[$ts] [$branch] [SUCCESS] $*" >&2
}

log_warning() {
    local ts=$(get_timestamp)
    local branch=$(get_branch_display)
    echo "[$ts] [$branch] [WARNING] $*" >&2
}

log_error() {
    local ts=$(get_timestamp)
    local branch=$(get_branch_display)
    echo "[$ts] [$branch] [ERROR] $*" >&2
}

log_debug() {
    if [[ "${DEBUG:-}" == "1" || "${DEBUG:-}" == "true" ]]; then
        local ts=$(get_timestamp)
        local branch=$(get_branch_display)
        echo "[$ts] [$branch] [DEBUG] $*" >&2
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
