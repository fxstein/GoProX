#!/bin/zsh
echo "Release script starting..." >&2
#
# release.zsh: Simplified top-level release script for GoProX
#
# Set script and project root directories FIRST
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Initialize logger variables before sourcing logger
LOG_VERBOSE=false
LOG_QUIET=false
LOGFILE=""  # Disable file logging temporarily

set -euo pipefail

# Source project logger
source "$SCRIPT_DIR/../core/logger.zsh"

# Configuration
GITFLOW_SCRIPT="$SCRIPT_DIR/gitflow-release.zsh"
OUTPUT_DIR="$PROJECT_ROOT/output"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Source safe prompt utilities
source "$SCRIPT_DIR/../core/safe-prompt.zsh"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

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

INTERACTIVE BEHAVIOR OPTIONS:
    --non-interactive  Force non-interactive mode
    --auto-confirm     Automatically confirm all prompts
    --default-yes      Default to 'yes' for all prompts

INTERACTIVE MODE EXAMPLES:
    ./release.zsh                    # Interactive mode
    ./release.zsh --interactive      # Explicit interactive mode
    ./release.zsh --non-interactive --auto-confirm  # Non-interactive with auto-confirm

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

# Function to safely call logger functions
safe_log() {
    local level="$1"
    local message="$2"
    
    case "$level" in
        info)
            log_info "$message" || echo "INFO: $message" >&2
            ;;
        success)
            log_success "$message" || echo "SUCCESS: $message" >&2
            ;;
        warning)
            log_warning "$message" || echo "WARNING: $message" >&2
            ;;
        error)
            log_error "$message" || echo "ERROR: $message" >&2
            ;;
        debug)
            log_debug "$message" || echo "DEBUG: $message" >&2
            ;;
        *)
            echo "UNKNOWN: $message" >&2
            ;;
    esac
}

# Function to check prerequisites
check_prerequisites() {
    safe_log info "Checking prerequisites..."
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        safe_log error "Not in a git repository"
        exit 1
    fi
    
    # Check if gh CLI is available
    if ! command -v gh &> /dev/null; then
        safe_log error "GitHub CLI (gh) is not installed. Please install it first: https://cli.github.com/"
        exit 1
    fi
    
    if ! gh auth status &> /dev/null; then
        safe_log error "Not authenticated with GitHub CLI. Please run: gh auth login"
        exit 1
    fi
    
    # Check if required scripts exist
    if [[ ! -f "$GITFLOW_SCRIPT" ]]; then
        safe_log error "gitflow-release.zsh script not found: $GITFLOW_SCRIPT"
        exit 1
    fi
    
    safe_log success "All prerequisites met"
    safe_log debug "Prerequisites check completed, proceeding to main logic"
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
    
    echo "Interactive mode called with release_type: '$release_type'" >&2
    safe_log debug "Starting interactive mode with release_type: '$release_type'"
    
    echo "About to call display_status..." >&2
    display_status
    echo "display_status completed" >&2
    
    # Determine release type if not specified
    if [[ -z "$release_type" ]]; then
        echo "No release type specified, prompting user..." >&2
        safe_log debug "No release type specified, prompting user"
        echo "Select release type:"
        echo "1) Official Release (production)"
        echo "2) Beta Release (testing)"
        echo "3) Development Release (feature testing)"
        echo "4) Dry Run (test without release)"
        echo ""
        local choice
        echo "About to call safe_prompt for release type choice..." >&2
        safe_log debug "About to call safe_prompt for release type choice"
        choice=$(safe_prompt "Enter choice (1-4)" "1")
        echo "safe_prompt returned: '$choice'" >&2
        safe_log debug "safe_prompt returned: '$choice'"
        
        case "$choice" in
            1) release_type="official" ;;
            2) release_type="beta" ;;
            3) release_type="dev" ;;
            4) release_type="dry-run" ;;
            *) safe_log error "Invalid choice: '$choice'"; exit 1 ;;
        esac
        echo "Selected release type: '$release_type'" >&2
        safe_log debug "Selected release type: '$release_type'"
    fi
    
    # Get previous version
    local current_version=$(get_current_version)
    local latest_tag=$(get_latest_tag)
    local suggested_prev="$latest_tag"
    
    if [[ "$suggested_prev" == "none" ]]; then
        suggested_prev="$current_version"
    fi
    
    echo ""
    log_debug "About to call safe_prompt for previous version"
    prev_version=$(safe_prompt "Previous version for changelog" "$suggested_prev")
    log_debug "safe_prompt returned prev_version: '$prev_version'"
    
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
    local bump_choice
    log_debug "About to call safe_prompt for bump choice"
    bump_choice=$(safe_prompt "Enter choice (1-3)" "2")
    log_debug "safe_prompt returned bump_choice: '$bump_choice'"
    
    local bump_type="minor"
    case "$bump_choice" in
        1) bump_type="major" ;;
        2|"") bump_type="minor" ;;
        3) bump_type="patch" ;;
        *) log_error "Invalid choice: '$bump_choice'"; exit 1 ;;
    esac
    log_debug "Selected bump type: '$bump_type'"
    
    # Suggest next version
    local suggested_version=$(suggest_next_version "$current_version" "$bump_type")
    
    echo ""
    log_debug "About to call safe_prompt for next version"
    next_version=$(safe_prompt "Next version" "$suggested_version")
    log_debug "safe_prompt returned next_version: '$next_version'"
    
    # Validate next version
    if ! validate_version "$next_version"; then
        exit 1
    fi
    
    # Ask about monitoring
    echo ""
    local monitor_choice
    log_debug "About to call safe_prompt for monitor choice"
    monitor_choice=$(safe_prompt "Monitor workflow completion? (y/N)" "N")
    log_debug "safe_prompt returned monitor_choice: '$monitor_choice'"
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
    
    log_debug "About to call safe_confirm for final confirmation"
    if ! safe_confirm "Proceed with release? (y/N)"; then
        log_info "Release cancelled"
        exit 0
    fi
    log_debug "User confirmed release"
    
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
        "official"|"beta"|"dev"|"dry-run")
            # Use gitflow release script for all operations
            cmd="$GITFLOW_SCRIPT --prev $prev_version"
            
            if [[ "$release_type" == "dry-run" ]]; then
                cmd="$cmd --dry-run"
            elif [[ "$release_type" == "beta" ]]; then
                # For beta releases, ensure we're on a release branch
                cmd="$cmd"
            elif [[ "$release_type" == "dev" ]]; then
                # For dev releases, ensure we're on a feature/fix branch
                cmd="$cmd"
            fi
            
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
    echo "Main function called with arguments: $@" >&2
    
    # Initialize variables
    echo "Initializing variables..." >&2
    local PREV_VERSION=""
    local VERSION=""
    local VERSION_TYPE="minor"
    local INTERACTIVE=false
    local NON_INTERACTIVE=false
    local AUTO_CONFIRM=false
    local DEFAULT_YES=false
    local BATCH_MODE=false
    local MONITOR=false
    local DRY_RUN=false
    local FORCE_CLEAN=false
    local CONFIG_FILE=""
    local VERBOSE=false
    local QUIET=false
    
    echo "Variables initialized, starting option parsing" >&2
    
    # Parse options using zparseopts for strict parameter validation
    echo "About to call zparseopts with arguments: $@" >&2
    declare -A opts
    zparseopts -D -E -F -A opts - \
                h -help \
                v -verbose \
                q -quiet \
                -interactive \
                -non-interactive \
                -auto-confirm \
                -default-yes \
                -batch \
                -prev: \
                -version: \
                -minor \
                -major \
                -patch \
                -monitor \
                -dry-run \
                -force-clean \
                --config: \
                || {
        # Unknown option
        echo "zparseopts failed" >&2
        log_error "Unknown option: $@"
        exit 1
    }
    echo "zparseopts completed successfully" >&2
    
    # Process parsed options
    echo "Processing parsed options..." >&2
    for key val in "${(kv@)opts}"; do
        case $key in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                ;;
            -q|--quiet)
                QUIET=true
                ;;
            --interactive)
                INTERACTIVE=true
                ;;
            --non-interactive)
                NON_INTERACTIVE=true
                ;;
            --auto-confirm)
                AUTO_CONFIRM=true
                ;;
            --default-yes)
                DEFAULT_YES=true
                ;;
            --batch)
                BATCH_MODE=true
                ;;
            --prev)
                PREV_VERSION="$val"
                ;;
            --version)
                VERSION="$val"
                ;;
            --minor)
                VERSION_TYPE="minor"
                ;;
            --major)
                VERSION_TYPE="major"
                ;;
            --patch)
                VERSION_TYPE="patch"
                ;;
            --monitor)
                MONITOR=true
                ;;
            --dry-run)
                DRY_RUN=true
                ;;
            --force-clean)
                FORCE_CLEAN=true
                ;;
            --config)
                CONFIG_FILE="$val"
                ;;
        esac
    done
    echo "Options processed" >&2
    
    # Parse command line arguments
    echo "Parsing command line arguments..." >&2
    local release_type=""
    local prev_version="$PREV_VERSION"
    local next_version="$VERSION"
    local bump_type="${VERSION_TYPE:-minor}"
    local monitor_flag=""
    
    # Set monitor flag if MONITOR is true
    if [[ "${MONITOR:-false}" == "true" ]]; then
        monitor_flag="--monitor"
    fi
    
    while [[ ${#@} -gt 0 ]]; do
        case ${@[1]} in
            official|beta|dev|dry-run)
                release_type="${@[1]}"
                shift
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
            --help|-h)
                show_usage
                exit 0
                ;;
            -*)
                log_error "Unknown option: ${@[1]}"
                show_usage
                exit 1
                ;;
            *)
                if [[ -z "$release_type" ]]; then
                    release_type="${@[1]}"
                else
                    log_error "Unexpected argument: ${@[1]}"
                    show_usage
                    exit 1
                fi
                shift
                ;;
        esac
    done
    echo "Command line arguments parsed" >&2
    
    # Check prerequisites
    echo "About to call check_prerequisites..." >&2
    echo "Checking prerequisites..." >&2
    check_prerequisites
    echo "Prerequisites checked" >&2
    echo "About to execute based on mode..." >&2
    
    # Execute based on mode
    echo "Executing based on mode..." >&2
    if [[ "${BATCH_MODE:-false}" == "true" ]]; then
        echo "Running batch mode" >&2
        batch_mode "$release_type" "$prev_version" "$next_version" "$bump_type" "$monitor_flag"
    else
        echo "Running interactive mode" >&2
        interactive_mode "$release_type"
    fi
}

# Run main function
echo "About to call main function" >&2
echo "Arguments: $@" >&2
echo "Function exists: $(type main 2>/dev/null || echo 'NO')" >&2
main "$@"
echo "Main function call completed" >&2 