#!/bin/zsh
#
# bump-version.zsh: Bump the version in the goprox file and optionally commit/push
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
#
# Usage: ./bump-version.zsh [OPTIONS] [NEW_VERSION]
#
# GoProX Version Bump Script
# This script helps bump the version in the goprox file

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
Usage: $0 [OPTIONS] [NEW_VERSION]

Options:
    -a, --auto              Automatically increment patch version by 1
    -m, --message MESSAGE    Commit message (default: "Bump version to vNEW_VERSION")
    -c, --commit            Automatically commit the change
    -p, --push             Automatically push the commit (implies --commit)
    -h, --help             Show this help message
    --dry-run              Dry run mode: print what would be done but do not modify files, commit, or push

Arguments:
    NEW_VERSION            New version in format XX.XX.XX (e.g., 00.61.00)
                          Required unless --auto is used

Examples:
    $0 --auto --push                    # Auto increment and push
    $0 00.61.00                        # Manual version bump
    $0 --message "Release v00.61.00 with new features" 00.61.00
    $0 --commit 00.61.00
    $0 --push 00.61.00
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

# Function to increment version
increment_version() {
    local current_version=$1
    local major=$(echo "$current_version" | cut -d. -f1)
    local minor=$(echo "$current_version" | cut -d. -f2)
    local patch=$(echo "$current_version" | cut -d. -f3)
    
    # Increment patch version
    local new_patch=$((10#$patch + 1))
    
    # Format with leading zeros
    printf "%02d.%02d.%02d" $major $minor $new_patch
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

# Function to update version in goprox file
update_version() {
    local new_version=$1
    local current_version=$(get_current_version)
    
    print_status "Updating version from $current_version to $new_version"
    
    # Update the version in goprox file
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/__version__='$current_version'/__version__='$new_version'/" goprox
    else
        # Linux
        sed -i "s/__version__='$current_version'/__version__='$new_version'/" goprox
    fi
    
    # Verify the change
    local updated_version=$(get_current_version)
    if [[ "$updated_version" == "$new_version" ]]; then
        print_success "Version updated successfully in goprox file"
    else
        print_error "Failed to update version. Expected: $new_version, Got: $updated_version"
        exit 1
    fi
}

# Function to commit the change
commit_change() {
    local new_version=$1
    local commit_message=$2
    
    if [[ -z "$commit_message" ]]; then
        commit_message="Bump version to v$new_version"
    fi
    
    print_status "Committing version change..."
    
    git add goprox
    git commit -m "$commit_message"
    
    print_success "Version change committed"
}

# Function to push the commit
push_commit() {
    print_status "Pushing commit..."
    
    git push
    
    print_success "Commit pushed successfully"
}

# Main script logic
main() {
    local new_version=""
    local commit_message=""
    local auto_commit=false
    local auto_push=false
    local auto_increment=false
    local force=false
    local dry_run=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -a|--auto)
                auto_increment=true
                shift
                ;;
            -m|--message)
                commit_message="$2"
                shift 2
                ;;
            -c|--commit)
                auto_commit=true
                shift
                ;;
            -p|--push)
                auto_commit=true
                auto_push=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            --force)
                force=true
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            -*)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                if [[ -z "$new_version" ]]; then
                    new_version="$1"
                else
                    print_error "Multiple versions specified: $new_version and $1"
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a git repository"
        exit 1
    fi
    
    # Get current version
    local current_version=$(get_current_version)
    print_status "Current version: $current_version"
    
    # Handle auto increment
    if [[ "$auto_increment" == "true" ]]; then
        if [[ -n "$new_version" ]]; then
            print_error "Cannot specify both --auto and a version number"
            show_usage
            exit 1
        fi
        new_version=$(increment_version "$current_version")
        print_status "Auto-incrementing to: $new_version"
    else
        # Check if version was provided
        if [[ -z "$new_version" ]]; then
            print_error "No version specified. Use --auto for automatic increment or specify a version"
            show_usage
            exit 1
        fi
    fi
    
    # Validate version format
    validate_version "$new_version"
    
    print_status "New version: $new_version"
    
    # Check if version is actually changing
    if [[ "$current_version" == "$new_version" ]]; then
        print_warning "Version is already $new_version"
        exit 0
    fi
    
    if [[ "$dry_run" == true ]]; then
        print_status "[DRY RUN] Would update version from $current_version to $new_version in goprox file."
        if [[ "$auto_commit" == "true" ]]; then
            print_status "[DRY RUN] Would commit version change."
            if [[ "$auto_push" == "true" ]]; then
                print_status "[DRY RUN] Would push commit to remote."
            fi
        fi
        print_success "[DRY RUN] Version bump simulation completed successfully!"
        exit 0
    fi
    
    # Confirm the version bump
    if [[ "$force" != true ]]; then
    echo
    print_status "Version Bump Summary:"
    echo "  Current version: $current_version"
    echo "  New version: $new_version"
    echo "  Auto commit: $auto_commit"
    echo "  Auto push: $auto_push"
    echo
        echo -n "Proceed with version bump? (y/N): "
        read confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_status "Version bump cancelled"
        exit 0
        fi
    else
        print_status "--force specified, proceeding without confirmation."
    fi
    
    # Update the version
    update_version "$new_version"
    
    # Commit if requested
    if [[ "$auto_commit" == "true" ]]; then
        commit_change "$new_version" "$commit_message"
        # Push if requested
        if [[ "$auto_push" == "true" ]]; then
            push_commit
        fi
    else
        print_status "Version updated. Don't forget to commit the change:"
        echo "  git add goprox"
        echo "  git commit -m \"Bump version to v$new_version\""
        if [[ "$auto_push" == "true" ]]; then
            echo "  git push"
        fi
    fi
    
    print_success "Version bump completed successfully!"
}

# Run main function with all arguments
main "$@" 