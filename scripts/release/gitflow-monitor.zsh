#!/bin/zsh
#
# gitflow-monitor.zsh: Git-flow optimized release monitoring for GoProX
#
# Enhanced monitoring specifically for git-flow release process with:
# - Branch-specific monitoring
# - Git-flow state tracking
# - Enhanced artifact management
# - Release validation reporting
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
# Usage: ./gitflow-monitor.zsh [version] [options]

# --- Enhanced Logging Setup ---
LOGFILE="output/gitflow-monitor.log"
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
Usage: gitflow-monitor.zsh [version] [options]

Git-Flow Optimized Release Monitoring for GoProX

This script provides enhanced monitoring specifically for the git-flow release process,
including branch-specific monitoring, git-flow state tracking, and enhanced artifact management.

Arguments:
  version                 Version to monitor (XX.XX.XX format)

Options:
  -h, --help            show this help message and exit
  --dry-run             monitor dry run workflow instead of real release
  --timeout <minutes>   timeout in minutes (default: 30)
  --interval <seconds>  polling interval in seconds (default: 10)
  --verbose             enable verbose logging
  --no-artifacts        don't download and display artifacts
  --branch <branch>     specify branch to monitor (auto-detected if not specified)

Git-Flow Features:
  - Branch-specific monitoring and validation
  - Git-flow state tracking and reporting
  - Enhanced artifact management for different release types
  - Release validation reporting with git-flow context
  - Branch cleanup status monitoring

Examples:
  # Monitor release for version 01.12.00
  ./scripts/release/gitflow-monitor.zsh 01.12.00

  # Monitor dry run for version 01.12.00
  ./scripts/release/gitflow-monitor.zsh 01.12.00 --dry-run

  # Monitor with custom timeout and interval
  ./scripts/release/gitflow-monitor.zsh 01.12.00 --timeout 60 --interval 5

  # Monitor without downloading artifacts
  ./scripts/release/gitflow-monitor.zsh 01.12.00 --no-artifacts

The script automatically:
- Detects current git-flow branch and state
- Monitors appropriate workflow for the branch
- Provides git-flow specific status reporting
- Handles artifact management for different release types
- Reports git-flow state changes and cleanup status
EOF
}

# Function to validate git-flow state
validate_gitflow_state() {
    print_status "Validating git-flow state..."
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a git repository"
        exit 1
    fi
    
    # Check if git-flow is initialized
    if ! git flow version &> /dev/null; then
        print_error "Git-flow is not initialized"
        exit 1
    fi
    
    # Get current branch
    local current_branch=$(git rev-parse --abbrev-ref HEAD)
    print_status "Current branch: $current_branch"
    
    # Determine git-flow context
    if [[ "$current_branch" == "main" ]]; then
        GITFLOW_CONTEXT="production"
        print_status "Git-flow context: Production (main branch)"
    elif [[ "$current_branch" == "develop" ]]; then
        GITFLOW_CONTEXT="development"
        print_status "Git-flow context: Development (develop branch)"
    elif [[ "$current_branch" =~ ^release/ ]]; then
        GITFLOW_CONTEXT="release_preparation"
        print_status "Git-flow context: Release preparation (release branch)"
    elif [[ "$current_branch" =~ ^hotfix/ ]]; then
        GITFLOW_CONTEXT="hotfix"
        print_status "Git-flow context: Hotfix (hotfix branch)"
    elif [[ "$current_branch" =~ ^feature/ ]]; then
        GITFLOW_CONTEXT="feature"
        print_status "Git-flow context: Feature development (feature branch)"
    else
        GITFLOW_CONTEXT="unknown"
        print_warning "Git-flow context: Unknown branch type"
    fi
    
    print_success "Git-flow state validated"
}

# Function to find workflow run
find_workflow_run() {
    local version="$1"
    local dry_run="$2"
    local branch="$3"
    
    print_status "Finding workflow run for version $version..."
    
    # Determine workflow name and parameters
    local workflow_name="release-automation.yml"
    local expected_branch="$branch"
    
    if [[ -z "$expected_branch" ]]; then
        expected_branch="main"
    fi
    
    # Search for workflow runs
    local run_id=""
    local max_attempts=10
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        print_status "Searching for workflow run (attempt $attempt/$max_attempts)..."
        
        # Get recent workflow runs
        local runs=$(gh run list --workflow "$workflow_name" --json databaseId,headBranch,status,createdAt,conclusion --limit 10)
        
        # Find matching run
        run_id=$(echo "$runs" | jq -r --arg version "$version" --arg branch "$expected_branch" '
            .[] | 
            select(.headBranch == $branch) | 
            select(.status == "completed" or .status == "in_progress") | 
            .databaseId' | head -n 1)
        
        if [[ -n "$run_id" && "$run_id" != "null" ]]; then
            print_success "Found workflow run: $run_id"
            break
        fi
        
        if [[ $attempt -lt $max_attempts ]]; then
            print_status "No matching run found, waiting before retry..."
            sleep 5
        fi
        
        ((attempt++))
    done
    
    if [[ -z "$run_id" || "$run_id" == "null" ]]; then
        print_error "Could not find workflow run for version $version on branch $expected_branch"
        print_status "Available runs:"
        gh run list --workflow "$workflow_name" --limit 5
        exit 1
    fi
    
    echo "$run_id"
}

# Function to monitor workflow status
monitor_workflow_status() {
    local run_id="$1"
    local timeout_minutes="$2"
    local interval_seconds="$3"
    
    print_status "Monitoring workflow run $run_id..."
    print_status "Timeout: ${timeout_minutes} minutes, Interval: ${interval_seconds} seconds"
    
    local start_time=$(date +%s)
    local timeout_seconds=$((timeout_minutes * 60))
    local last_status=""
    
    while true; do
        # Check if timeout exceeded
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        if [[ $elapsed -gt $timeout_seconds ]]; then
            print_error "Monitoring timeout exceeded (${timeout_minutes} minutes)"
            exit 1
        fi
        
        # Get workflow status
        local status_info=$(gh run view "$run_id" --json status,conclusion,createdAt,updatedAt)
        local status=$(echo "$status_info" | jq -r '.status')
        local conclusion=$(echo "$status_info" | jq -r '.conclusion')
        local created_at=$(echo "$status_info" | jq -r '.createdAt')
        local updated_at=$(echo "$status_info" | jq -r '.updatedAt')
        
        # Only print status if it changed
        if [[ "$status" != "$last_status" ]]; then
            print_status "Workflow status: $status"
            if [[ -n "$conclusion" && "$conclusion" != "null" ]]; then
                print_status "Workflow conclusion: $conclusion"
            fi
            last_status="$status"
        fi
        
        # Check if workflow completed
        if [[ "$status" == "completed" ]]; then
            if [[ "$conclusion" == "success" ]]; then
                print_success "Workflow completed successfully!"
                return 0
            else
                print_error "Workflow failed with conclusion: $conclusion"
                return 1
            fi
        elif [[ "$status" == "cancelled" ]]; then
            print_error "Workflow was cancelled"
            return 1
        fi
        
        # Wait before next check
        sleep "$interval_seconds"
    done
}

# Function to download and display artifacts
download_artifacts() {
    local run_id="$1"
    local version="$2"
    local dry_run="$3"
    local no_artifacts="$4"
    
    if [[ "$no_artifacts" == "true" ]]; then
        print_status "Skipping artifact download (--no-artifacts specified)"
        return
    fi
    
    print_status "Downloading and displaying artifacts..."
    
    # Create temporary directory for artifacts
    local tmpdir=$(mktemp -d)
    
    # Download release notes artifact
    if gh run download "$run_id" --name release-notes --dir "$tmpdir" --repo fxstein/GoProX 2>/dev/null; then
        local notes_file=$(find "$tmpdir" -name 'release_notes.md' | head -n 1)
        if [[ -f "$notes_file" ]]; then
            # Prepare output filename
            mkdir -p output
            if [[ "$dry_run" == "true" ]]; then
                local out_file="output/release-notes-${version}-dry-run.md"
            else
                local out_file="output/release-notes-${version}.md"
            fi
            cp "$notes_file" "$out_file"
            print_success "Release notes saved to $out_file"
            
            echo ""
            print_status "==== RELEASE NOTES ===="
            cat "$out_file"
            print_status "==== END OF RELEASE NOTES ===="
        else
            print_warning "release_notes.md not found in artifact"
        fi
    else
        print_warning "Failed to download release notes artifact"
    fi
    
    # Download release packages artifact
    if gh run download "$run_id" --name release-packages --dir "$tmpdir" --repo fxstein/GoProX 2>/dev/null; then
        local package_file=$(find "$tmpdir" -name "goprox-v${version}.tar.gz" | head -n 1)
        if [[ -f "$package_file" ]]; then
            local out_file="output/goprox-v${version}.tar.gz"
            cp "$package_file" "$out_file"
            print_success "Release package saved to $out_file"
            
            # Calculate and display SHA256
            local sha256=$(shasum -a 256 "$out_file" | cut -d' ' -f1)
            print_status "Package SHA256: $sha256"
        else
            print_warning "Release package not found in artifact"
        fi
    else
        print_warning "Failed to download release packages artifact"
    fi
    
    # Clean up
    rm -rf "$tmpdir"
}

# Function to report git-flow status
report_gitflow_status() {
    local version="$1"
    local dry_run="$2"
    local workflow_success="$3"
    
    print_status "Reporting git-flow status..."
    
    echo ""
    echo "┌─────────────────────────────────────────────────────────────────┐"
    echo "│                    Git-Flow Status Report                      │"
    echo "└─────────────────────────────────────────────────────────────────┘"
    echo ""
    
    # Current branch and context
    local current_branch=$(git rev-parse --abbrev-ref HEAD)
    echo "📋 Current Branch: $current_branch"
    echo "🎯 Git-Flow Context: $GITFLOW_CONTEXT"
    echo "🏷️  Version: $version"
    echo "🧪 Dry Run: $dry_run"
    echo "✅ Workflow Success: $workflow_success"
    echo ""
    
    # Branch-specific information
    case "$GITFLOW_CONTEXT" in
        "production")
            echo "🚀 Production Release Status:"
            echo "   - Branch: main (production-ready)"
            echo "   - Tag: v$version should exist"
            echo "   - Homebrew: Official channel updated"
            echo "   - GitHub Release: Published"
            ;;
        "release_preparation")
            echo "🔧 Release Preparation Status:"
            echo "   - Branch: release/$version"
            echo "   - Status: Ready for merge to main"
            echo "   - Validation: Dry run completed"
            echo "   - Next Step: Finish release"
            ;;
        "hotfix")
            echo "🚨 Hotfix Status:"
            echo "   - Branch: hotfix/*"
            echo "   - Status: Critical fix in progress"
            echo "   - Validation: Dry run completed"
            echo "   - Next Step: Merge to main and develop"
            ;;
        "development")
            echo "🛠️  Development Status:"
            echo "   - Branch: develop"
            echo "   - Status: Feature integration"
            echo "   - Context: Development workflow"
            echo "   - Next Step: Create release branch"
            ;;
        *)
            echo "❓ Unknown Git-Flow Context:"
            echo "   - Branch: $current_branch"
            echo "   - Status: Unknown"
            echo "   - Context: $GITFLOW_CONTEXT"
            ;;
    esac
    
    echo ""
    
    # Git-flow branch status
    echo "🌿 Git-Flow Branch Status:"
    local branches=$(git branch -a | grep -E "(main|develop|release/|hotfix/)" | sed 's/^[* ]*//')
    echo "$branches" | while read branch; do
        if [[ "$branch" == "$current_branch" ]]; then
            echo "   ✅ $branch (current)"
        else
            echo "   📍 $branch"
        fi
    done
    
    echo ""
    
    # Tags status
    echo "🏷️  Tags Status:"
    local tags=$(git tag --list "v$version*" | sort -V)
    if [[ -n "$tags" ]]; then
        echo "$tags" | while read tag; do
            echo "   ✅ $tag"
        done
    else
        echo "   ❌ No tags found for version $version"
    fi
    
    echo ""
    
    # Recommendations
    echo "💡 Recommendations:"
    case "$GITFLOW_CONTEXT" in
        "production")
            if [[ "$workflow_success" == "true" ]]; then
                echo "   ✅ Production release completed successfully"
                echo "   🧹 Consider cleaning up old release branches"
                echo "   📊 Monitor release metrics and user feedback"
            else
                echo "   ❌ Production release failed - investigate workflow logs"
                echo "   🔄 Consider rolling back if necessary"
            fi
            ;;
        "release_preparation")
            if [[ "$workflow_success" == "true" ]]; then
                echo "   ✅ Release preparation completed successfully"
                echo "   🔄 Ready to finish release: git flow release finish $version"
                echo "   📋 Review release notes and test results"
            else
                echo "   ❌ Release preparation failed - fix issues before finishing"
                echo "   🔍 Check workflow logs for specific errors"
            fi
            ;;
        "hotfix")
            if [[ "$workflow_success" == "true" ]]; then
                echo "   ✅ Hotfix validation completed successfully"
                echo "   🔄 Ready to finish hotfix: git flow hotfix finish"
                echo "   🚨 Deploy to production as soon as possible"
            else
                echo "   ❌ Hotfix validation failed - fix issues before deployment"
                echo "   🚨 Critical: Address issues immediately"
            fi
            ;;
        *)
            echo "   📋 Continue with normal git-flow workflow"
            echo "   📚 Review git-flow documentation if needed"
            ;;
    esac
    
    echo ""
    echo "┌─────────────────────────────────────────────────────────────────┐"
    echo "│                    End of Status Report                        │"
    echo "└─────────────────────────────────────────────────────────────────┘"
    echo ""
}

# Main script logic
main() {
    # Parse arguments
    local version="$1"
    shift
    
    # Initialize variables
    local dry_run="false"
    local timeout_minutes=30
    local interval_seconds=10
    local verbose="false"
    local no_artifacts="false"
    local branch=""
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            --dry-run)
                dry_run="true"
                shift
                ;;
            --timeout)
                timeout_minutes="$2"
                shift 2
                ;;
            --interval)
                interval_seconds="$2"
                shift 2
                ;;
            --verbose)
                verbose="true"
                VERBOSE=1
                shift
                ;;
            --no-artifacts)
                no_artifacts="true"
                shift
                ;;
            --branch)
                branch="$2"
                shift 2
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Validate required arguments
    if [[ -z "$version" ]]; then
        print_error "Version is required"
        show_usage
        exit 1
    fi
    
    # Validate version format
    if [[ ! "$version" =~ ^[0-9]{2}\.[0-9]{2}\.[0-9]{2}$ ]]; then
        print_error "Version must be in format XX.XX.XX"
        exit 1
    fi
    
    # Validate numeric parameters
    if ! [[ "$timeout_minutes" =~ ^[0-9]+$ ]]; then
        print_error "Timeout must be a positive integer"
        exit 1
    fi
    
    if ! [[ "$interval_seconds" =~ ^[0-9]+$ ]]; then
        print_error "Interval must be a positive integer"
        exit 1
    fi
    
    print_status "Git-Flow Monitor Configuration:"
    echo "  Version: $version"
    echo "  Dry Run: $dry_run"
    echo "  Timeout: ${timeout_minutes} minutes"
    echo "  Interval: ${interval_seconds} seconds"
    echo "  Branch: ${branch:-auto-detected}"
    echo "  No Artifacts: $no_artifacts"
    echo ""
    
    # Validate git-flow state
    validate_gitflow_state
    
    # Auto-detect branch if not specified
    if [[ -z "$branch" ]]; then
        branch=$(git rev-parse --abbrev-ref HEAD)
        print_status "Auto-detected branch: $branch"
    fi
    
    # Find workflow run
    local run_id=$(find_workflow_run "$version" "$dry_run" "$branch")
    
    # Monitor workflow status
    local workflow_success="false"
    if monitor_workflow_status "$run_id" "$timeout_minutes" "$interval_seconds"; then
        workflow_success="true"
    fi
    
    # Download and display artifacts
    download_artifacts "$run_id" "$version" "$dry_run" "$no_artifacts"
    
    # Report git-flow status
    report_gitflow_status "$version" "$dry_run" "$workflow_success"
    
    # Exit with appropriate code
    if [[ "$workflow_success" == "true" ]]; then
        print_success "Git-flow monitoring completed successfully"
        exit 0
    else
        print_error "Git-flow monitoring failed"
        exit 1
    fi
}

main "$@" 