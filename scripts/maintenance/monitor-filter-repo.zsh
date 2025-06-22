#!/bin/zsh

# Git Filter-Repo Progress Monitor
# This script monitors the progress of git filter-repo by tracking various metrics

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to get repository size
get_repo_size() {
    du -sh .git | cut -f1
}

# Function to get commit count
get_commit_count() {
    git rev-list --count HEAD 2>/dev/null || echo "0"
}

# Function to get process status
get_process_status() {
    local pid_file="output/.filter-repo.pid"
    if [[ -f "$pid_file" ]]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            echo "RUNNING ($pid)"
        else
            echo "COMPLETED"
        fi
    else
        echo "UNKNOWN"
    fi
}

# Function to show progress
show_progress() {
    local log_file="${1:-output/filter-repo.log}"
    local pid_file="output/.filter-repo.pid"
    
    # Ensure output directory exists
    mkdir -p output
    
    print_status "Starting progress monitor..."
    print_status "Log file: $log_file"
    print_status "PID file: $pid_file"
    
    # Get initial values
    local initial_size=$(get_repo_size)
    local initial_commits=$(get_commit_count)
    
    print_status "Initial repository size: $initial_size"
    print_status "Initial commit count: $initial_commits"
    
    local iteration=0
    
    while true; do
        clear
        echo "=== Git Filter-Repo Progress Monitor ==="
        echo "Time: $(date)"
        echo "Iteration: $iteration"
        echo ""
        
        # Process status
        local process_status=$(get_process_status)
        echo "Process Status: $process_status"
        
        # Repository metrics
        local current_size=$(get_repo_size)
        local current_commits=$(get_commit_count)
        
        echo "Repository Size: $current_size (was: $initial_size)"
        echo "Commit Count: $current_commits (was: $initial_commits)"
        
        # Calculate progress if possible
        if [[ "$current_commits" != "0" && "$initial_commits" != "0" ]]; then
            local progress=$((100 - (current_commits * 100 / initial_commits)))
            echo "Estimated Progress: ${progress}%"
        fi
        
        echo ""
        echo "=== Recent Log Output ==="
        if [[ -f "$log_file" ]]; then
            local log_size=$(wc -l < "$log_file" 2>/dev/null || echo "0")
            if [[ "$log_size" -gt 0 ]]; then
                tail -n 10 "$log_file"
            else
                echo "No log output yet..."
            fi
        else
            echo "Log file not found..."
        fi
        
        echo ""
        echo "=== Process Details ==="
        if [[ -f "$pid_file" ]]; then
            local pid=$(cat "$pid_file")
            ps -p "$pid" -o pid,ppid,state,time,pcpu,pmem,command 2>/dev/null || echo "Process not found"
        fi
        
        echo ""
        echo "Press Ctrl+C to stop monitoring"
        
        # Check if process completed
        if [[ "$process_status" == "COMPLETED" ]]; then
            print_success "Git filter-repo process completed!"
            echo ""
            echo "=== Final Results ==="
            echo "Final repository size: $(get_repo_size)"
            echo "Final commit count: $(get_commit_count)"
            echo ""
            echo "=== Final Log Output ==="
            if [[ -f "$log_file" ]]; then
                tail -n 20 "$log_file"
            fi
            break
        fi
        
        sleep 5
        ((iteration++))
    done
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    -l, --log-file FILE   Log file to monitor (default: "output/filter-repo.log")
    -h, --help            Show this help message

Examples:
    $0
    $0 --log-file "output/my-filter.log"
EOF
}

# Main script logic
main() {
    local log_file="output/filter-repo.log"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -l|--log-file)
                log_file="$2"
                shift 2
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a git repository"
        exit 1
    fi
    
    # Show progress
    show_progress "$log_file"
}

# Run main function with all arguments
main "$@" 