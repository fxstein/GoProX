#!/bin/zsh

# GoProX Release Script
# This script helps trigger the automated release process

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
    -v, --version VERSION    Specify version to release (e.g., 00.61.00)
    -p, --prev VERSION       Specify previous version for changelog
    -d, --dry-run           Run in dry-run mode (no actual release)
    -h, --help              Show this help message

Examples:
    $0 --version 00.61.00 --prev 00.60.00
    $0 --version 00.61.00 --prev 00.60.00 --dry-run
    $0 -v 00.61.00 -p 00.60.00 -d

If no version is specified, the script will:
1. Read the current version from goprox file
2. Try to determine the previous version from git tags
3. Prompt for confirmation before proceeding
EOF
}

# Function to get current version from goprox file
get_current_version() {
    if [[ -f "goprox" ]]; then
        grep "__version__=" goprox | cut -d"'" -f2
    else
        print_error "goprox file not found in current directory"
        exit 1
    fi
}

# Function to get the latest git tag
get_latest_tag() {
    git describe --tags --abbrev=0 2>/dev/null || echo "none"
}

# Function to validate version format
validate_version() {
    local version=$1
    if [[ ! "$version" =~ ^[0-9]{2}\.[0-9]{2}\.[0-9]{2}$ ]]; then
        print_error "Invalid version format: $version"
        print_error "Version must be in format XX.XX.XX (e.g., 00.61.00)"
        exit 1
    fi
}

# Function to check if gh CLI is available
check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        print_error "GitHub CLI (gh) is not installed or not in PATH"
        print_error "Please install it from: https://cli.github.com/"
        exit 1
    fi
    
    if ! gh auth status &> /dev/null; then
        print_error "GitHub CLI is not authenticated"
        print_error "Please run: gh auth login"
        exit 1
    fi
}

# Function to trigger the workflow
trigger_workflow() {
    local version=$1
    local prev_version=$2
    local dry_run=$3
    
    print_status "Triggering release automation workflow..."
    print_status "Version: $version"
    print_status "Previous version: $prev_version"
    print_status "Dry run: $dry_run"
    
    gh workflow run release-automation.yml \
        -f version="$version" \
        -f prev_version="$prev_version" \
        -f dry_run="$dry_run"
    
    if [[ $? -eq 0 ]]; then
        print_success "Workflow triggered successfully!"
        print_status "You can monitor the progress at: https://github.com/fxstein/GoProX/actions"
    else
        print_error "Failed to trigger workflow"
        exit 1
    fi
}

# Main script logic
main() {
    local version=""
    local prev_version=""
    local dry_run="false"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--version)
                version="$2"
                shift 2
                ;;
            -p|--prev)
                prev_version="$2"
                shift 2
                ;;
            -d|--dry-run)
                dry_run="true"
                shift
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
    
    # Check if gh CLI is available
    check_gh_cli
    
    # If no version specified, get it from goprox file
    if [[ -z "$version" ]]; then
        version=$(get_current_version)
        print_status "Using current version from goprox: $version"
    fi
    
    # Validate version format
    validate_version "$version"
    
    # If no previous version specified, try to get it from git tags
    if [[ -z "$prev_version" ]]; then
        local latest_tag=$(get_latest_tag)
        if [[ "$latest_tag" != "none" ]]; then
            # Remove 'v' prefix if present
            prev_version=${latest_tag#v}
            print_status "Using previous version from latest tag: $prev_version"
        else
            print_warning "No git tags found. You'll need to specify the previous version manually."
            read -p "Enter previous version (e.g., 00.60.00): " prev_version
            if [[ -z "$prev_version" ]]; then
                print_error "Previous version is required"
                exit 1
            fi
            validate_version "$prev_version"
        fi
    fi
    
    # Validate previous version format
    validate_version "$prev_version"
    
    # Confirm the release
    echo
    print_status "Release Summary:"
    echo "  Current version: $version"
    echo "  Previous version: $prev_version"
    echo "  Dry run: $dry_run"
    echo
    
    if [[ "$dry_run" == "true" ]]; then
        print_warning "This is a DRY RUN - no actual release will be created"
    else
        print_warning "This will create a REAL release on GitHub"
    fi
    
    read -p "Proceed with release? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_status "Release cancelled"
        exit 0
    fi
    
    # Trigger the workflow
    trigger_workflow "$version" "$prev_version" "$dry_run"
}

# Run main function with all arguments
main "$@" 