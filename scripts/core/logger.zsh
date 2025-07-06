#!/bin/zsh
#
# Enhanced logger for GoProX with file logging support
# Output goes to stderr and optionally to log files based on configuration
#

# Logger configuration
LOGGER_INITIALIZED=false
LOG_FILE_ENABLED=false
LOG_FILE_PATH=""
LOG_MAX_SIZE=${LOG_MAX_SIZE:-1048576}  # 1MB default
LOG_LEVEL="info"

# Function to initialize logger with configuration
init_logger() {
    if [[ "$LOGGER_INITIALIZED" == "true" ]]; then
        return 0
    fi
    
    # Source config module if available
    if [[ -f "./scripts/core/config.zsh" ]]; then
        source "./scripts/core/config.zsh"
        
        # Load configuration (without using logger functions to avoid recursion)
        if [[ -f "config/goprox-settings.yaml" ]]; then
            # Use default values for now to avoid recursion
            LOG_LEVEL="info"
            LOG_FILE_ENABLED="true"
            LOG_FILE_PATH="output/goprox.log"
        else
            # Use default values
            LOG_LEVEL="info"
            LOG_FILE_ENABLED="true"
            LOG_FILE_PATH="output/goprox.log"
        fi
        
        # Initialize log file if enabled
        if [[ "$LOG_FILE_ENABLED" == "true" && -n "$LOG_FILE_PATH" ]]; then
            init_log_file "$LOG_FILE_PATH"
        fi
    fi
    
    LOGGER_INITIALIZED=true
}

# Function to initialize log file
init_log_file() {
    local log_file="$1"
    
    # Create output directory if it doesn't exist
    local log_dir=$(dirname "$log_file")
    if [[ ! -d "$log_dir" ]]; then
        mkdir -p "$log_dir"
    fi
    
    # Check if log rotation is needed
    if [[ -f "$log_file" ]]; then
        local file_size=$(stat -f%z "$log_file" 2>/dev/null || echo "0")
        if [[ $file_size -gt $LOG_MAX_SIZE ]]; then
            rotate_log_file "$log_file"
        fi
    fi
    
    # Create log file if it doesn't exist
    if [[ ! -f "$log_file" ]]; then
        touch "$log_file"
    fi
}

# Function to rotate log file
rotate_log_file() {
    local log_file="$1"
    local backup_file="${log_file}.old"
    
    # Remove old backup if it exists
    if [[ -f "$backup_file" ]]; then
        rm "$backup_file"
    fi
    
    # Move current log to backup
    if [[ -f "$log_file" ]]; then
        mv "$log_file" "$backup_file"
    fi
    
    # Create new log file
    touch "$log_file"
}

# Function to write log message
write_log_message() {
    local level="$1"
    local message="$2"
    
    # Check log level
    if ! should_log_level "$level"; then
        return 0
    fi
    
    local ts=$(get_timestamp)
    local branch=$(get_branch_display)
    local formatted_message="[$ts] [$branch] [$level] $message"
    
    # Always write to stderr
    echo "$formatted_message" >&2
    
    # Write to log file if enabled
    if [[ "$LOG_FILE_ENABLED" == "true" && -n "$LOG_FILE_PATH" && -f "$LOG_FILE_PATH" ]]; then
        echo "$formatted_message" >> "$LOG_FILE_PATH"
        
        # Check if rotation is needed
        local file_size=$(stat -f%z "$LOG_FILE_PATH" 2>/dev/null || echo "0")
        if [[ $file_size -gt $LOG_MAX_SIZE ]]; then
            rotate_log_file "$LOG_FILE_PATH"
        fi
    fi
}

# Function to check if log level should be written
should_log_level() {
    local level="$1"
    local level_num=0
    
    case "$level" in
        "DEBUG") level_num=0 ;;
        "INFO") level_num=1 ;;
        "SUCCESS") level_num=1 ;;
        "WARNING") level_num=2 ;;
        "ERROR") level_num=3 ;;
        *) level_num=1 ;;
    esac
    
    local config_level_num=1
    case "$LOG_LEVEL" in
        "debug") config_level_num=0 ;;
        "info") config_level_num=1 ;;
        "warning") config_level_num=2 ;;
        "error") config_level_num=3 ;;
        *) config_level_num=1 ;;
    esac
    
    [[ $level_num -ge $config_level_num ]]
}

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

# Enhanced logging functions with file support
log_info() {
    init_logger
    write_log_message "INFO" "$*"
}

log_success() {
    init_logger
    write_log_message "SUCCESS" "$*"
}

log_warning() {
    init_logger
    write_log_message "WARNING" "$*"
}

log_error() {
    init_logger
    write_log_message "ERROR" "$*"
}

log_debug() {
    if [[ "${DEBUG:-}" == "1" || "${DEBUG:-}" == "true" ]]; then
        init_logger
        write_log_message "DEBUG" "$*"
    fi
}

# JSON logging function for structured output
log_json() {
    local level="$1"
    local message="$2"
    local context="${3:-{}}"
    
    init_logger
    
    if ! should_log_level "$level"; then
        return 0
    fi
    
    local ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local branch=$(get_branch_display)
    local json_message=$(cat <<EOF
{
  "timestamp": "$ts",
  "level": "$level",
  "branch": "$branch",
  "message": "$message",
  "context": $context
}
EOF
)
    
    # Write to stderr
    echo "$json_message" >&2
    
    # Write to log file if enabled
    if [[ "$LOG_FILE_ENABLED" == "true" && -n "$LOG_FILE_PATH" && -f "$LOG_FILE_PATH" ]]; then
        echo "$json_message" >> "$LOG_FILE_PATH"
        
        # Check if rotation is needed
        local file_size=$(stat -f%z "$LOG_FILE_PATH" 2>/dev/null || echo "0")
        if [[ $file_size -gt $LOG_MAX_SIZE ]]; then
            rotate_log_file "$LOG_FILE_PATH"
        fi
    fi
}

# Performance timing functions
declare -A TIMER_START

log_time_start() {
    local operation="${1:-default}"
    TIMER_START["$operation"]=$(date +%s.%N)
    log_debug "Timer started for operation: $operation"
}

log_time_end() {
    local operation="${1:-default}"
    local end_time=$(date +%s.%N)
    local start_time="${TIMER_START[$operation]:-0}"
    
    if [[ "$start_time" != "0" ]]; then
        local duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
        log_info "Operation '$operation' completed in ${duration}s"
        unset TIMER_START["$operation"]
    else
        log_warning "Timer for operation '$operation' was not started"
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

# Logger is initialized on first use, not automatically
