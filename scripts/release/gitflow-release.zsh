#!/bin/zsh
#
# gitflow-release.zsh: Git-flow native release process for GoProX
#
# Enhanced Logging: Implements robust logging to both console and output/release.log
# Git-Flow Integration: Native git-flow commands with branch validation and monitoring
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
# Usage: ./gitflow-release.zsh [options]
#
# Git-Flow Release Process:
# 1. Validate current branch and git-flow state
# 2. Create/update AI release summary
# 3. Start release branch (if not already on one)
# 4. Bump version and prepare release
# 5. Perform dry run validation
# 6. Finish release (merge to main and develop)
# 7. Monitor release automation
# 8. Clean up and report results

# --- Enhanced Logging Setup ---
LOGFILE="output/release.log"
mkdir -p output
: > "$LOGFILE"

# Gather repo, branch info for log prefix
LOG_REMOTE="$(git config --get remote.origin.url 2>/dev/null)"
LOG_REPO="$(echo "$LOG_REMOTE" | sed -E 's#.*github.com[:/](.*)\.git#\1#')"
LOG_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"

VERBOSE=0

log() {
  local level="$1"; shift
  local msg="$@"
  local ts="$(date '+%Y-%m-%d %H:%M:%S')"
  local prefix="[$ts][$LOG_REPO][$LOG_BRANCH][$level]"
  echo "$prefix $msg" | tee -a "$LOGFILE"
}
log_debug() {
  [[ $VERBOSE -eq 1 ]] && log "DEBUG" "$@"
}
print_status()   { log "INFO"    "$@"; }
print_success()  { log "SUCCESS" "$@"; }
print_warning()  { log "WARNING" "$@"; }
print_error()    { log "ERROR"   "$@"; }

# Error trapping
trap 'log "ERROR" "Script failed at line $LINENO: $BASH_COMMAND (exit code $?)"' ERR
set -e

# Function to show usage
show_usage() {
    local script_name="${0##*/}"
    cat << 'EOF'
Usage: gitflow-release.zsh [options]

Git-Flow Native Release Process for GoProX

This script performs the complete git-flow release process:
1. Validate git-flow state and current branch
2. Create/update AI release summary
3. Start release branch (if needed)
4. Bump version and prepare release
5. Perform dry run validation
6. Finish release (merge to main and develop)
7. Monitor release automation
8. Clean up and report results

Options:
  -h, --help            show this help message and exit
  --version <version>   specify version to release (XX.XX.XX format)
  --prev <version>      specify previous version for changelog
  --base <version>      alias for --prev (backward compatibility)
  --bump-type <type>    version bump type: major, minor, patch (default: minor)
  --dry-run-only        perform dry run only, don't finish release
  --skip-dry-run        skip dry run validation (not recommended)
  --force               force execution without confirmation
  --verbose             enable verbose logging
  --no-cleanup          don't clean up release branch after finish

Git-Flow Requirements:
  - Must be on develop branch to start release
  - Must be on release/* branch to finish release
  - develop branch must be up to date
  - No uncommitted changes in scripts/release/ or .github/workflows/

Examples:
  # Start a new release from develop
  ./scripts/release/gitflow-release.zsh --version 01.12.00 --prev 01.11.00

  # Finish a release from release branch
  ./scripts/release/gitflow-release.zsh --version 01.12.00 --prev 01.11.00

  # Dry run only (for testing)
  ./scripts/release/gitflow-release.zsh --version 01.12.00 --prev 01.11.00 --dry-run-only

  # Force release without confirmation
  ./scripts/release/gitflow-release.zsh --version 01.12.00 --prev 01.11.00 --force

The script automatically handles:
- Git-flow branch creation and management
- AI release summary creation and validation
- Version bumping and commit management
- Dry run validation before release
- Release automation monitoring
- Branch cleanup and reporting
EOF
}

# Function to validate git-flow prerequisites
validate_gitflow_prerequisites() {
    print_status "Validating git-flow prerequisites..."
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a git repository"
        exit 1
    fi
    
    # Check if gh CLI is available
    if ! command -v gh &> /dev/null; then
        print_error "GitHub CLI (gh) is not installed. Please install it first: https://cli.github.com/"
        exit 1
    fi
    
    if ! gh auth status &> /dev/null; then
        print_error "Not authenticated with GitHub CLI. Please run: gh auth login"
        exit 1
    fi
    
    # Check if git-flow is initialized
    if ! git flow version &> /dev/null; then
        print_error "Git-flow is not initialized. Please run: git flow init"
        exit 1
    fi
    
    # Check current branch
    local current_branch=$(git rev-parse --abbrev-ref HEAD)
    print_status "Current branch: $current_branch"
    
    # Validate branch for current operation
    if [[ "$current_branch" == "develop" ]]; then
        print_status "On develop branch - will start new release"
        RELEASE_OPERATION="start"
    elif [[ "$current_branch" =~ ^release/ ]]; then
        print_status "On release branch - will finish release"
        RELEASE_OPERATION="finish"
    elif [[ "$current_branch" == "main" ]]; then
        print_error "Cannot run release process from main branch"
        print_error "Use develop branch to start a release, or release/* branch to finish a release"
        exit 1
    else
        print_error "Invalid branch for release process: $current_branch"
        print_error "Must be on develop (to start) or release/* (to finish)"
        exit 1
    fi
    
    # Check for uncommitted changes
    if [[ -n $(git status --porcelain scripts/release/) ]]; then
        print_error "Uncommitted changes detected in scripts/release/"
        print_error "Please commit all changes before running release process"
        exit 1
    fi
    
    if [[ -n $(git status --porcelain .github/workflows/) ]]; then
        print_error "Uncommitted changes detected in .github/workflows/"
        print_error "Please commit all changes before running release process"
        exit 1
    fi
    
    # Check if develop is up to date (if starting from develop)
    if [[ "$RELEASE_OPERATION" == "start" ]]; then
        git fetch origin develop
        local local_develop=$(git rev-parse develop)
        local remote_develop=$(git rev-parse origin/develop)
        
        if [[ "$local_develop" != "$remote_develop" ]]; then
            print_error "Local develop branch is not up to date with remote"
            print_error "Please pull latest changes: git pull origin develop"
            exit 1
        fi
    fi
    
    print_success "Git-flow prerequisites validated"
}

# Function to create/update AI release summary
create_ai_release_summary() {
    local version="$1"
    local prev_version="$2"
    
    print_status "Creating/updating AI release summary..."
    
    local summary_file="docs/release/latest-major-changes-since-${prev_version}.md"
    
    # Check if summary file exists
    if [[ -f "$summary_file" ]]; then
        print_status "Found existing summary file: $summary_file"
        
        # Check if it needs updating
        if [[ -n $(git status --porcelain "$summary_file") ]]; then
            print_status "Summary file has uncommitted changes, committing..."
            git add "$summary_file"
            git commit -m "docs(release): update AI release summary for v$version (refs #68)"
            git push
            print_success "Summary file updated and committed"
        else
            print_status "Summary file is up to date"
        fi
    else
        print_error "AI release summary file not found: $summary_file"
        print_error "AI must create this file before running release process"
        print_error "File should contain summary of major changes since v$prev_version"
        exit 1
    fi
}

# Function to start release branch
start_release_branch() {
    local version="$1"
    
    print_status "Starting release branch for version $version..."
    
    # Create release branch using git-flow
    git flow release start "$version"
    
    print_success "Release branch created: release/$version"
}

# Function to bump version
bump_version() {
    local version="$1"
    local bump_type="$2"
    
    print_status "Bumping version to $version..."
    
    # Update version in goprox file
    local current_version=$(grep "__version__=" goprox | cut -d"'" -f2)
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/__version__='$current_version'/__version__='$version'/" goprox
    else
        # Linux
        sed -i "s/__version__='$current_version'/__version__='$version'/" goprox
    fi
    
    # Verify the change
    local updated_version=$(grep "__version__=" goprox | cut -d"'" -f2)
    if [[ "$updated_version" == "$version" ]]; then
        print_success "Version updated successfully in goprox file"
    else
        print_error "Failed to update version. Expected: $version, Got: $updated_version"
        exit 1
    fi
    
    # Commit version bump
    git add goprox
    git commit -m "chore: bump version to v$version for release (refs #20)"
    
    print_success "Version bumped and committed"
}

# Function to perform dry run validation
perform_dry_run() {
    local version="$1"
    local prev_version="$2"
    
    print_status "Performing dry run validation..."
    
    # Trigger dry run workflow
    gh workflow run release-automation.yml \
        -f version="$version" \
        -f prev_version="$prev_version" \
        -f dry_run="true"
    
    if [[ $? -eq 0 ]]; then
        print_success "Dry run workflow triggered successfully"
        
        # Monitor dry run
        print_status "Monitoring dry run progress..."
        ./scripts/release/monitor-release.zsh "$version" --dry-run
        
        print_success "Dry run completed successfully"
    else
        print_error "Failed to trigger dry run workflow"
        exit 1
    fi
}

# Function to finish release
finish_release() {
    local version="$1"
    local force="$2"
    
    print_status "Finishing release for version $version..."
    
    # Confirm before finishing (unless forced)
    if [[ "$force" != "true" ]]; then
        echo ""
        echo "About to finish release v$version:"
        echo "  - This will merge release/$version to main"
        echo "  - This will merge release/$version to develop"
        echo "  - This will create tag v$version"
        echo "  - This will trigger real release automation"
        echo ""
        read -q "REPLY?Continue? (y/N): "
        echo ""
        if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
            print_status "Release finish cancelled"
            exit 0
        fi
    fi
    
    # Finish release using git-flow
    git flow release finish "$version" -m "Release version $version"
    
    print_success "Release finished successfully"
    print_status "Release v$version has been merged to main and develop"
    print_status "Tag v$version has been created"
}

# Function to monitor release automation
monitor_release_automation() {
    local version="$1"
    
    print_status "Monitoring release automation for version $version..."
    
    # Wait a moment for workflow to start
    sleep 5
    
    # Monitor the release
    ./scripts/release/monitor-release.zsh "$version"
    
    if [[ $? -eq 0 ]]; then
        print_success "Release automation completed successfully"
    else
        print_error "Release automation failed"
        exit 1
    fi
}

# Function to clean up
cleanup_release() {
    local version="$1"
    local no_cleanup="$2"
    
    if [[ "$no_cleanup" == "true" ]]; then
        print_status "Skipping cleanup (--no-cleanup specified)"
        return
    fi
    
    print_status "Cleaning up release branch..."
    
    # Delete local release branch
    git branch -d "release/$version" 2>/dev/null || print_warning "Local release branch already deleted"
    
    # Delete remote release branch
    git push origin --delete "release/$version" 2>/dev/null || print_warning "Remote release branch already deleted"
    
    print_success "Release cleanup completed"
}

# Function to get current version
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

# Main script logic
main() {
    echo ""
    echo "┌─────────────────────────────────────────────────────────────────┐"
    echo "│                GoProX Git-Flow Release                         │"
    echo "└─────────────────────────────────────────────────────────────────┘"
    echo ""
    
    # Initialize variables
    version=""
    prev_version=""
    bump_type="minor"
    dry_run_only="false"
    skip_dry_run="false"
    force="false"
    verbose="false"
    no_cleanup="false"
    
    # Parse options using zparseopts for strict parameter validation
    declare -A opts
    zparseopts -D -E -F -A opts - \
                h -help \
                -version: \
                -prev: \
                -base: \
                -bump-type: \
                -dry-run-only \
                -skip-dry-run \
                -force \
                -verbose \
                -no-cleanup \
                || {
        # Unknown option
        print_error "Unknown option: $@"
        print_error "Use --help for usage information"
        exit 1
    }
    
    # Process parsed options
    for key val in "${(kv@)opts}"; do
        case $key in
            -h|--help)
                show_usage
                exit 0
                ;;
            --version)
                version="$val"
                ;;
            --prev|--base)
                prev_version="$val"
                ;;
            --bump-type)
                bump_type="$val"
                ;;
            --dry-run-only)
                dry_run_only="true"
                ;;
            --skip-dry-run)
                skip_dry_run="true"
                ;;
            --force)
                force="true"
                ;;
            --verbose)
                verbose="true"
                VERBOSE=1
                ;;
            --no-cleanup)
                no_cleanup="true"
                ;;
        esac
    done
    
    # Validate required parameters
    if [[ -z "$version" ]]; then
        print_error "Version is required. Use --version <version>"
        exit 1
    fi
    
    if [[ -z "$prev_version" ]]; then
        # Try to get from git tags
        prev_version=$(get_latest_tag | sed 's/v//')
        if [[ "$prev_version" == "none" ]]; then
            print_error "Previous version is required. Use --prev <version>"
            exit 1
        fi
        print_status "Using previous version from git tags: $prev_version"
    fi
    
    # Validate version format
    if [[ ! "$version" =~ ^[0-9]{2}\.[0-9]{2}\.[0-9]{2}$ ]]; then
        print_error "Version must be in format XX.XX.XX"
        exit 1
    fi
    
    if [[ ! "$prev_version" =~ ^[0-9]{2}\.[0-9]{2}\.[0-9]{2}$ ]]; then
        print_error "Previous version must be in format XX.XX.XX"
        exit 1
    fi
    
    # Validate bump type
    if [[ ! "$bump_type" =~ ^(major|minor|patch)$ ]]; then
        print_error "Bump type must be: major, minor, or patch"
        exit 1
    fi
    
    print_status "Release Configuration:"
    echo "  Version: $version"
    echo "  Previous Version: $prev_version"
    echo "  Bump Type: $bump_type"
    echo "  Dry Run Only: $dry_run_only"
    echo "  Skip Dry Run: $skip_dry_run"
    echo "  Force: $force"
    echo "  No Cleanup: $no_cleanup"
    echo ""
    
    # Validate git-flow prerequisites
    validate_gitflow_prerequisites
    
    # Create/update AI release summary
    create_ai_release_summary "$version" "$prev_version"
    
    # Handle different operations based on current branch
    if [[ "$RELEASE_OPERATION" == "start" ]]; then
        # Starting new release from develop
        print_status "Starting new release process..."
        
        # Start release branch
        start_release_branch "$version"
        
        # Bump version
        bump_version "$version" "$bump_type"
        
        # Push release branch
        git push -u origin "release/$version"
        
        print_success "Release branch created and pushed"
        print_status "Next steps:"
        echo "  1. Review and test the release branch"
        echo "  2. Run: ./scripts/release/gitflow-release.zsh --version $version --prev $prev_version"
        echo "     (from the release branch to finish the release)"
        
    elif [[ "$RELEASE_OPERATION" == "finish" ]]; then
        # Finishing release from release branch
        print_status "Finishing release process..."
        
        # Perform dry run validation (unless skipped)
        if [[ "$skip_dry_run" != "true" ]]; then
            perform_dry_run "$version" "$prev_version"
        else
            print_warning "Skipping dry run validation (--skip-dry-run specified)"
        fi
        
        # Finish release (unless dry run only)
        if [[ "$dry_run_only" != "true" ]]; then
            finish_release "$version" "$force"
            
            # Push changes
            git push origin main develop --tags
            
            # Monitor release automation
            monitor_release_automation "$version"
            
            # Clean up
            cleanup_release "$version" "$no_cleanup"
            
            print_success "Release v$version completed successfully!"
            echo ""
            print_status "Release Summary:"
            echo "  Version: $version"
            echo "  Status: Completed"
            echo "  Branch: Cleaned up"
            echo "  Automation: Finished"
            echo ""
            print_status "You can view the release at: https://github.com/fxstein/GoProX/releases"
        else
            print_success "Dry run completed successfully"
            print_status "Release branch is ready for finishing"
        fi
    fi
}

main "$@" 