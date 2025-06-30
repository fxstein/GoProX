#!/bin/zsh
#
# release.zsh: Simplified top-level release script for GoProX
#
# Supports both interactive and batch modes for creating various types of releases:
# - Official releases (from main/develop)
# - Beta releases (from release branches)
# - Development releases (from feature branches)
# - Dry runs for testing
#
# Interactive Mode: Asks for input with sensible defaults
# Batch Mode: Accepts all parameters for AI/automation use
#
# Copyright (c) 2021-2025 by Oliver Ratzesberger
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR" && pwd)"
RELEASE_SCRIPT="$PROJECT_ROOT/scripts/release/full-release.zsh"
GITFLOW_SCRIPT="$PROJECT_ROOT/scripts/release/gitflow-release.zsh"
OUTPUT_DIR="$PROJECT_ROOT/output"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    echo -e "${PURPLE}[DEBUG]${NC} $1"
}

# Function to show usage
show_usage() {
    cat << 'EOF'
Usage: ./release.zsh [OPTIONS] [RELEASE_TYPE]

Simplified GoProX Release Script

RELEASE TYPES:
    official     Official release (from main/develop)
    beta         Beta release (from release branches)
    dev          Development release (from feature branches)
    dry-run      Test run without actual release

OPTIONS:
    --interactive    Interactive mode (default if no parameters)
    --batch          Batch mode (requires all parameters)
    --prev <version> Previous version for changelog
    --version <ver>  Specific version to release
    --major          Bump major version
    --minor          Bump minor version (default)
    --patch          Bump patch version
    --force          Skip confirmations
    --monitor        Monitor workflow completion
    --help           Show this help

INTERACTIVE MODE EXAMPLES:
    ./release.zsh                    # Interactive mode
    ./release.zsh --interactive      # Explicit interactive mode

BATCH MODE EXAMPLES:
    ./release.zsh --batch dry-run --prev 01.50.00
    ./release.zsh --batch beta --prev 01.50.00 --version 01.51.00
    ./release.zsh --batch official --prev 01.50.00 --minor --monitor

RELEASE TYPE BEHAVIOR:
    official: Creates official release with Homebrew updates
    beta:     Creates beta release for testing
    dev:      Creates development release for feature testing
    dry-run:  Simulates release process without actual release

BRANCH REQUIREMENTS:
    - Official: main, develop, or release/* branches
    - Beta: release/* branches
    - Dev: feature/* or fix/* branches
    - Dry-run: any branch (for testing)
EOF
}

# Function to get current version
get_current_version() {
    if [[ -f "goprox" ]]; then
        grep "__version__=" goprox | cut -d"'" -f2
    else
        log_error "goprox file not found in current directory"
        exit 1
    fi
}

# Function to get latest git tag
get_latest_tag() {
    git describe --tags --abbrev=0 2>/dev/null || echo "none"
}

# Function to get current branch
get_current_branch() {
    git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown"
}

# Function to validate version format
validate_version() {
    local version="$1"
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log_error "Invalid version format: $version. Expected format: XX.XX.XX"
        return 1
    fi
    return 0
}

# Function to suggest next version
suggest_next_version() {
    local current_version="$1"
    local bump_type="${2:-minor}"
    
    IFS='.' read -r major minor patch <<< "$current_version"
    
    case "$bump_type" in
        major)
            echo "$((major + 1)).00.00"
            ;;
        minor)
            echo "$major.$((minor + 1)).00"
            ;;
        patch)
            echo "$major.$minor.$((patch + 1))"
            ;;
        *)
            log_error "Invalid bump type: $bump_type"
            return 1
            ;;
    esac
}

# Function to check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Not in a git repository"
        exit 1
    fi
    
    # Check if gh CLI is available
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) is not installed. Please install it first: https://cli.github.com/"
        exit 1
    fi
    
    if ! gh auth status &> /dev/null; then
        log_error "Not authenticated with GitHub CLI. Please run: gh auth login"
        exit 1
    fi
    
    # Check if required scripts exist
    if [[ ! -f "$RELEASE_SCRIPT" ]]; then
        log_error "full-release.zsh script not found: $RELEASE_SCRIPT"
        exit 1
    fi
    
    if [[ ! -f "$GITFLOW_SCRIPT" ]]; then
        log_error "gitflow-release.zsh script not found: $GITFLOW_SCRIPT"
        exit 1
    fi
    
    log_success "All prerequisites met"
}

# Function to display current status
display_status() {
    local current_version=$(get_current_version)
    local latest_tag=$(get_latest_tag)
    local current_branch=$(get_current_branch)
    
    echo ""
    echo "┌─────────────────────────────────────────────────────────────────┐"
    echo "│                   GoProX Release Status                        │"
    echo "└─────────────────────────────────────────────────────────────────┘"
    echo ""
    echo "📍 Current Version: $current_version"
    echo "🏷️  Latest Tag: $latest_tag"
    echo "🌿 Current Branch: $current_branch"
    echo ""
}

# Function for interactive mode
interactive_mode() {
    local release_type="$1"
    
    display_status
    
    # Determine release type if not specified
    if [[ -z "$release_type" ]]; then
        echo "Select release type:"
        echo "1) Official Release (production)"
        echo "2) Beta Release (testing)"
        echo "3) Development Release (feature testing)"
        echo "4) Dry Run (test without release)"
        echo ""
        read -p "Enter choice (1-4): " choice
        
        case "$choice" in
            1) release_type="official" ;;
            2) release_type="beta" ;;
            3) release_type="dev" ;;
            4) release_type="dry-run" ;;
            *) log_error "Invalid choice"; exit 1 ;;
        esac
    fi
    
    # Get previous version
    local current_version=$(get_current_version)
    local latest_tag=$(get_latest_tag)
    local suggested_prev="$latest_tag"
    
    if [[ "$suggested_prev" == "none" ]]; then
        suggested_prev="$current_version"
    fi
    
    echo ""
    read -p "Previous version for changelog [$suggested_prev]: " prev_version
    prev_version="${prev_version:-$suggested_prev}"
    
    # Validate previous version
    if ! validate_version "$prev_version"; then
        exit 1
    fi
    
    # Get version bump type
    echo ""
    echo "Version bump type:"
    echo "1) Major (X.00.00)"
    echo "2) Minor (X.X.00) [default]"
    echo "3) Patch (X.X.X)"
    echo ""
    read -p "Enter choice (1-3) [2]: " bump_choice
    
    local bump_type="minor"
    case "$bump_choice" in
        1) bump_type="major" ;;
        2|"") bump_type="minor" ;;
        3) bump_type="patch" ;;
        *) log_error "Invalid choice"; exit 1 ;;
    esac
    
    # Suggest next version
    local suggested_version=$(suggest_next_version "$current_version" "$bump_type")
    
    echo ""
    read -p "Next version [$suggested_version]: " next_version
    next_version="${next_version:-$suggested_version}"
    
    # Validate next version
    if ! validate_version "$next_version"; then
        exit 1
    fi
    
    # Ask about monitoring
    echo ""
    read -p "Monitor workflow completion? (y/N): " monitor_choice
    local monitor_flag=""
    if [[ "${monitor_choice,,}" == "y" ]]; then
        monitor_flag="--monitor"
    fi
    
    # Confirm release
    echo ""
    echo "Release Summary:"
    echo "  Type: $release_type"
    echo "  Previous: $prev_version"
    echo "  Next: $next_version"
    echo "  Bump: $bump_type"
    echo "  Monitor: ${monitor_choice:-N}"
    echo ""
    
    read -p "Proceed with release? (y/N): " confirm
    if [[ "${confirm,,}" != "y" ]]; then
        log_info "Release cancelled"
        exit 0
    fi
    
    # Execute release
    execute_release "$release_type" "$prev_version" "$next_version" "$bump_type" "$monitor_flag"
}

# Function for batch mode
batch_mode() {
    local release_type="$1"
    local prev_version="$2"
    local next_version="$3"
    local bump_type="${4:-minor}"
    local monitor_flag="${5:-}"
    
    # Validate required parameters
    if [[ -z "$release_type" || -z "$prev_version" ]]; then
        log_error "Batch mode requires release_type and prev_version"
        show_usage
        exit 1
    fi
    
    # Validate versions
    if ! validate_version "$prev_version"; then
        exit 1
    fi
    
    if [[ -n "$next_version" ]] && ! validate_version "$next_version"; then
        exit 1
    fi
    
    # Execute release
    execute_release "$release_type" "$prev_version" "$next_version" "$bump_type" "$monitor_flag"
}

# Function to execute the actual release
execute_release() {
    local release_type="$1"
    local prev_version="$2"
    local next_version="$3"
    local bump_type="$4"
    local monitor_flag="$5"
    
    log_info "Executing $release_type release..."
    log_info "Previous version: $prev_version"
    log_info "Next version: $next_version"
    log_info "Bump type: $bump_type"
    
    # Build command based on release type
    local cmd=""
    
    case "$release_type" in
        "official"|"beta"|"dev")
            # Use gitflow release script
            cmd="$GITFLOW_SCRIPT --prev $prev_version"
            
            if [[ -n "$next_version" ]]; then
                cmd="$cmd --version $next_version"
            fi
            
            if [[ "$release_type" == "beta" ]]; then
                cmd="$cmd --beta"
            elif [[ "$release_type" == "dev" ]]; then
                cmd="$cmd --dev"
            fi
            
            if [[ -n "$monitor_flag" ]]; then
                cmd="$cmd $monitor_flag"
            fi
            ;;
        
        "dry-run")
            # Use full release script with dry-run
            cmd="$RELEASE_SCRIPT --dry-run --prev $prev_version"
            
            if [[ -n "$next_version" ]]; then
                cmd="$cmd --version $next_version"
            fi
            
            case "$bump_type" in
                major) cmd="$cmd --major" ;;
                minor) cmd="$cmd --minor" ;;
                patch) cmd="$cmd --patch" ;;
            esac
            
            if [[ -n "$monitor_flag" ]]; then
                cmd="$cmd --monitor"
            fi
            ;;
        
        *)
            log_error "Invalid release type: $release_type"
            exit 1
            ;;
    esac
    
    log_info "Executing: $cmd"
    echo ""
    
    # Execute the command
    eval "$cmd"
    
    if [[ $? -eq 0 ]]; then
        log_success "$release_type release completed successfully"
    else
        log_error "$release_type release failed"
        exit 1
    fi
}

# Main script logic
main() {
    # Parse command line arguments
    local mode="interactive"
    local release_type=""
    local prev_version=""
    local next_version=""
    local bump_type="minor"
    local monitor_flag=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --interactive)
                mode="interactive"
                shift
                ;;
            --batch)
                mode="batch"
                shift
                ;;
            --prev)
                prev_version="$2"
                shift 2
                ;;
            --version)
                next_version="$2"
                shift 2
                ;;
            --major)
                bump_type="major"
                shift
                ;;
            --minor)
                bump_type="minor"
                shift
                ;;
            --patch)
                bump_type="patch"
                shift
                ;;
            --monitor)
                monitor_flag="--monitor"
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                if [[ -z "$release_type" ]]; then
                    release_type="$1"
                else
                    log_error "Unexpected argument: $1"
                    show_usage
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Check prerequisites
    check_prerequisites
    
    # Execute based on mode
    if [[ "$mode" == "batch" ]]; then
        batch_mode "$release_type" "$prev_version" "$next_version" "$bump_type" "$monitor_flag"
    else
        interactive_mode "$release_type"
    fi
}

# Run main function
main "$@" 