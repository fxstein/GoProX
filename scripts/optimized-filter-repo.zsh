#!/bin/zsh

# Optimized Git Filter-Repo Script
# This script runs git filter-repo with maximum performance settings and monitoring

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    -p, --path PATTERN     Path pattern to filter (default: "*.zip")
    -i, --invert          Invert the path filter (default: true)
    -f, --force           Force operation (default: true)
    -v, --verbose         Verbose output (default: true)
    -b, --background      Run in background (default: true)
    -l, --log-file FILE   Log file for output (default: "filter-repo.log")
    -h, --help            Show this help message

Examples:
    $0
    $0 --path "*.zip" --invert --force --verbose
    $0 --log-file "my-filter.log"
EOF
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a git repository"
        exit 1
    fi
    
    # Check if git filter-repo is installed
    if ! command -v git-filter-repo &> /dev/null; then
        print_error "git-filter-repo is not installed"
        print_error "Install it with: brew install git-filter-repo"
        exit 1
    fi
    
    # Check if we have a clean working directory
    if ! git diff-index --quiet HEAD --; then
        print_warning "Working directory is not clean"
        print_warning "Consider committing or stashing changes first"
        echo -n "Continue anyway? (y/N): "
        read confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            print_status "Operation cancelled"
            exit 0
        fi
    fi
    
    print_success "Prerequisites check passed"
}

# Function to create backup
create_backup() {
    local backup_dir="backup-$(date +%Y%m%d-%H%M%S)"
    print_status "Creating backup in $backup_dir..."
    
    mkdir -p "$backup_dir"
    cp -r .git "$backup_dir/"
    
    print_success "Backup created: $backup_dir"
}

# Function to run git filter-repo
run_filter_repo() {
    local path_pattern="$1"
    local invert="$2"
    local force="$3"
    local verbose="$4"
    local background="$5"
    local log_file="$6"
    
    print_status "Starting git filter-repo with optimized settings..."
    print_status "Path pattern: $path_pattern"
    print_status "Invert: $invert"
    print_status "Force: $force"
    print_status "Verbose: $verbose"
    print_status "Background: $background"
    print_status "Log file: $log_file"
    
    # Build the command
    local cmd="git filter-repo"
    
    if [[ "$path_pattern" != "" ]]; then
        cmd="$cmd --path-glob '$path_pattern'"
    fi
    
    if [[ "$invert" == "true" ]]; then
        cmd="$cmd --invert-paths"
    fi
    
    if [[ "$force" == "true" ]]; then
        cmd="$cmd --force"
    fi
    
    if [[ "$verbose" == "true" ]]; then
        cmd="$cmd --verbose"
    fi
    
    # Add performance optimizations
    cmd="$cmd --replace-refs update-no-add"
    
    print_status "Command: $cmd"
    
    if [[ "$background" == "true" ]]; then
        print_status "Running in background..."
        print_status "Monitor progress with: tail -f $log_file"
        
        # Run in background and capture output
        nohup bash -c "$cmd" > "$log_file" 2>&1 &
        
        local pid=$!
        echo $pid > .filter-repo.pid
        
        print_success "Git filter-repo started with PID: $pid"
        print_status "Log file: $log_file"
        print_status "PID file: .filter-repo.pid"
        
        # Show initial log output
        sleep 2
        if [[ -f "$log_file" ]]; then
            print_status "Initial output:"
            tail -n 10 "$log_file"
        fi
        
    else
        print_status "Running in foreground..."
        eval "$cmd"
    fi
}

# Function to monitor progress
monitor_progress() {
    local log_file="$1"
    local pid_file=".filter-repo.pid"
    
    if [[ ! -f "$pid_file" ]]; then
        print_error "PID file not found. Process may not be running."
        return 1
    fi
    
    local pid=$(cat "$pid_file")
    
    print_status "Monitoring git filter-repo process (PID: $pid)..."
    print_status "Press Ctrl+C to stop monitoring (process will continue in background)"
    
    # Monitor the process and log file
    while kill -0 "$pid" 2>/dev/null; do
        if [[ -f "$log_file" ]]; then
            clear
            echo "=== Git Filter-Repo Progress Monitor ==="
            echo "PID: $pid"
            echo "Log file: $log_file"
            echo "Time: $(date)"
            echo ""
            echo "=== Recent Log Output ==="
            tail -n 20 "$log_file"
            echo ""
            echo "=== Process Status ==="
            ps -p "$pid" -o pid,ppid,state,time,pcpu,pmem,command
        fi
        sleep 5
    done
    
    print_success "Git filter-repo process completed!"
    
    # Show final output
    if [[ -f "$log_file" ]]; then
        print_status "Final output:"
        tail -n 20 "$log_file"
    fi
    
    # Clean up PID file
    rm -f "$pid_file"
}

# Main script logic
main() {
    local path_pattern="*.zip"
    local invert="true"
    local force="true"
    local verbose="true"
    local background="true"
    local log_file="filter-repo.log"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--path)
                path_pattern="$2"
                shift 2
                ;;
            -i|--invert)
                invert="$2"
                shift 2
                ;;
            -f|--force)
                force="$2"
                shift 2
                ;;
            -v|--verbose)
                verbose="$2"
                shift 2
                ;;
            -b|--background)
                background="$2"
                shift 2
                ;;
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
    
    # Check prerequisites
    check_prerequisites
    
    # Show summary
    echo
    print_status "Git Filter-Repo Summary:"
    echo "  Path pattern: $path_pattern"
    echo "  Invert paths: $invert"
    echo "  Force: $force"
    echo "  Verbose: $verbose"
    echo "  Background: $background"
    echo "  Log file: $log_file"
    echo
    
    # Confirm operation
    echo -n "Proceed with git filter-repo? (y/N): "
    read confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_status "Operation cancelled"
        exit 0
    fi
    
    # Create backup
    create_backup
    
    # Run git filter-repo
    run_filter_repo "$path_pattern" "$invert" "$force" "$verbose" "$background" "$log_file"
    
    # Monitor progress if running in background
    if [[ "$background" == "true" ]]; then
        echo
        echo -n "Monitor progress now? (Y/n): "
        read monitor
        if [[ ! "$monitor" =~ ^[Nn]$ ]]; then
            monitor_progress "$log_file"
        else
            print_status "To monitor progress later, run: tail -f $log_file"
            print_status "To check process status: ps aux | grep filter-repo"
        fi
    fi
}

# Run main function with all arguments
main "$@" 