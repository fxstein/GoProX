#!/usr/bin/env zsh

# Git-Flow Release Script for GoProX
# Integrates with AI release summary system and provides git-flow native release capabilities
# Enhanced with full dry-run functionality from full-release.zsh

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RELEASE_DIR="$PROJECT_ROOT/docs/release"
OUTPUT_DIR="$PROJECT_ROOT/output"

# Set script name for error trap
export SCRIPT_NAME="gitflow-release"

# Source the logger
export LOGFILE="$OUTPUT_DIR/gitflow-release.log"
mkdir -p "$(dirname "$LOGFILE")"
source "$(dirname "$0")/../core/logger.zsh"

log_info "Starting git-flow release process"

# Function to display usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] [BASE_VERSION]

Git-Flow Release Script for GoProX (Enhanced with Full Dry-Run Support)

OPTIONS:
    --dry-run              Perform a dry run without making changes
    --preserve-summary     Preserve the AI summary file (default for dry-runs)
    --remove-summary       Force removal of AI summary file
    --allow-unclean        Allow uncommitted changes (feature branches only)
    --monitor              Automatically monitor workflow completion after release
    --monitor-timeout      Timeout for monitoring in minutes (default: 15)
    --force                Force execution without confirmation
    --major                Bump major version (default: minor)
    --minor                Bump minor version (default)
    --patch                Bump patch version
    --version <version>    Specify version to release (default: auto-increment)
    --prev <version>       Alias for BASE_VERSION (backward compatibility)
    --base <version>       Alias for BASE_VERSION (backward compatibility)
    --help                 Show this help message

BASE_VERSION:
    The base version to generate changes since (e.g., 01.01.01)

EXAMPLES:
    $0 --dry-run 01.01.01                    # Dry run from feature branch
    $0 01.01.01                              # Real release from develop
    $0 --dry-run --preserve-summary 01.01.01 # Dry run preserving summary
    $0 --monitor 01.01.01                    # Real release with monitoring
    $0 --dry-run --prev 01.50.00 --patch     # Dry run with patch bump
    $0 --prev 01.50.00 --version 01.51.00    # Specific version release

BRANCH REQUIREMENTS:
    - Feature branches: Only dry-run allowed
    - Develop branch: Dry-run and release allowed
    - Release branches: Dry-run and beta release allowed
    - Main branch: Official release only

DRY-RUN FEATURES:
    - Version bumping simulation
    - Workflow trigger simulation
    - Summary file handling simulation
    - Full process validation without actual changes
EOF
}

# Parse command line arguments
DRY_RUN=false
PRESERVE_SUMMARY=false
REMOVE_SUMMARY=false
ALLOW_UNCLEAN=false
MONITOR=false
MONITOR_TIMEOUT=15
BASE_VERSION=""
FORCE=false
BUMP_TYPE="minor"
SPECIFIC_VERSION=""
VERBOSE=0

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --preserve-summary)
            PRESERVE_SUMMARY=true
            shift
            ;;
        --remove-summary)
            REMOVE_SUMMARY=true
            shift
            ;;
        --allow-unclean)
            ALLOW_UNCLEAN=true
            shift
            ;;
        --monitor)
            MONITOR=true
            shift
            ;;
        --monitor-timeout)
            MONITOR_TIMEOUT="$2"
            shift 2
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --major)
            BUMP_TYPE="major"
            shift
            ;;
        --minor)
            BUMP_TYPE="minor"
            shift
            ;;
        --patch)
            BUMP_TYPE="patch"
            shift
            ;;
        --version)
            SPECIFIC_VERSION="$2"
            shift 2
            ;;
        --prev|--base)
            BASE_VERSION="$2"
            shift 2
            ;;
        --verbose|--debug)
            VERBOSE=1
            shift
            ;;
        --help)
            show_usage
            exit 0
            ;;
        -*)
            log_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
        *)
            if [[ -z "$BASE_VERSION" ]]; then
                BASE_VERSION="$1"
            else
                log_error "Multiple base versions specified: $BASE_VERSION and $1"
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate base version
if [[ -z "$BASE_VERSION" ]]; then
    log_error "Base version is required"
    show_usage
    exit 1
fi

# Validate version format
if [[ ! "$BASE_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    log_error "Invalid version format: $BASE_VERSION. Expected format: XX.XX.XX"
    exit 1
fi

log_info "Base version: $BASE_VERSION"
log_info "Dry run: $DRY_RUN"
log_info "Preserve summary: $PRESERVE_SUMMARY"
log_info "Remove summary: $REMOVE_SUMMARY"
log_info "Allow unclean: $ALLOW_UNCLEAN"
log_info "Monitor: $MONITOR"
log_info "Monitor timeout: $MONITOR_TIMEOUT minutes"
log_info "Force: $FORCE"
log_info "Bump type: $BUMP_TYPE"
log_info "Specific version: $SPECIFIC_VERSION"

# Function to get current version
get_current_version() {
    if [[ -f "goprox" ]]; then
        grep "__version__=" goprox | cut -d"'" -f2
    else
        log_error "goprox file not found in current directory"
        exit 1
    fi
}

# Function to increment version (from bump-version.zsh)
increment_version() {
    local current_version=$1
    local bump_type=$2
    local major=$(echo "$current_version" | cut -d. -f1)
    local minor=$(echo "$current_version" | cut -d. -f2)
    local patch=$(echo "$current_version" | cut -d. -f3)

    if [[ "$bump_type" == "major" ]]; then
        major=$(printf "%02d" $((10#$major + 1)))
        minor="00"
        patch="00"
        log_info "Bumping MAJOR version: $major.00.00"
    elif [[ "$bump_type" == "minor" ]]; then
        minor=$(printf "%02d" $((10#$minor + 1)))
        patch="00"
        log_info "Bumping MINOR version: $major.$minor.00"
    else
        patch=$(printf "%02d" $((10#$patch + 1)))
        log_info "Bumping PATCH version: $major.$minor.$patch"
    fi
    printf "%02d.%02d.%02d" $major $minor $patch
}

# Function to validate version format
validate_version() {
    local version=$1
    if [[ ! "$version" =~ ^[0-9]{2}\.[0-9]{2}\.[0-9]{2}$ ]]; then
        log_error "Invalid version format: $version"
        log_error "Version must be in format XX.XX.XX (e.g., 00.61.00)"
        return 1
    fi
    return 0
}

# Function to update version in goprox file
update_version() {
    local new_version=$1
    local current_version=$(get_current_version)
    local dry_run=$2
    
    if [[ "$dry_run" == "true" ]]; then
        log_info "DRY RUN: Would update version from $current_version to $new_version"
        return 0
    fi
    
    log_info "Updating version from $current_version to $new_version"
    
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
        log_success "Version updated successfully in goprox file"
    else
        log_error "Failed to update version. Expected: $new_version, Got: $updated_version"
        exit 1
    fi
}

# Get current branch and validate git-flow requirements
CURRENT_BRANCH=$(git branch --show-current)
log_info "Current branch: $CURRENT_BRANCH"

# Display prominent branch information
display_branch_info "Git-Flow Release Process" "Base Version: $BASE_VERSION, Dry Run: $DRY_RUN"

# Branch validation logic
if [[ "$DRY_RUN" == true ]]; then
    # Allow dry-run on any branch, but warn if not a standard branch
    if [[ ! "$CURRENT_BRANCH" =~ ^(develop|main|release/|feature/) ]]; then
        echo ""
        echo "⚠️  WARNING: Running dry-run release on non-standard branch: $CURRENT_BRANCH"
        echo "   This is allowed for validation, but real releases are only permitted on develop, release/*, or main."
        echo ""
    fi
    log_info "Dry-run branch validation passed"
else
    # Real releases: enforce strict branch checks
    if [[ "$CURRENT_BRANCH" =~ ^feature/ ]]; then
        log_error "Real releases are not allowed from feature branches. Use develop, release/*, or main."
        exit 1
    fi
    if [[ ! "$CURRENT_BRANCH" =~ ^(develop|main|release/) ]]; then
        log_error "Unsupported branch for git-flow release: $CURRENT_BRANCH"
        log_error "Supported branches: develop, release/*, main"
        exit 1
    fi
    log_info "Branch validation passed"
fi

# Check for uncommitted changes
if [[ "$ALLOW_UNCLEAN" == "false" ]]; then
    if ! git diff-index --quiet HEAD --; then
        log_error "Uncommitted changes detected. Use --allow-unclean to proceed."
        git status --porcelain
        exit 1
    fi
fi

# Determine summary file name
SUMMARY_FILE="$RELEASE_DIR/latest-major-changes-since-$BASE_VERSION.md"

# Check if summary file exists
if [[ ! -f "$SUMMARY_FILE" ]]; then
    log_error "AI summary file not found: $SUMMARY_FILE"
    log_error "Please create the AI summary file before proceeding"
    exit 1
fi

log_info "AI summary file found: $SUMMARY_FILE"

# Determine new version based on branch and operation
determine_new_version() {
    local base_version="$1"
    local branch="$2"
    local dry_run="$3"
    local specific_version="$4"
    local bump_type="$5"
    
    # If specific version is provided, use it
    if [[ -n "$specific_version" ]]; then
        if ! validate_version "$specific_version"; then
            exit 1
        fi
        echo "$specific_version"
        return 0
    fi
    
    # Parse base version
    IFS='.' read -r major minor patch <<< "$base_version"
    
    case "$branch" in
        feature/*)
            # Feature branches: increment patch for testing
            echo "$major.$minor.$((patch + 1))-feature"
            ;;
        fix/*)
            # Fix branches: increment patch for testing
            echo "$major.$minor.$((patch + 1))-fix"
            ;;
        develop)
            if [[ "$dry_run" == "true" ]]; then
                echo "$major.$minor.$((patch + 1))-dev-dry"
            else
                echo "$major.$minor.$((patch + 1))-dev"
            fi
            ;;
        release/*)
            if [[ "$dry_run" == "true" ]]; then
                echo "$major.$minor.$((patch + 1))-beta-dry"
            else
                echo "$major.$minor.$((patch + 1))-beta"
            fi
            ;;
        main)
            # Main branch: official release with proper bump
            local current_version=$(get_current_version)
            increment_version "$current_version" "$bump_type"
            ;;
        *)
            # Unknown branch type: use generic suffix
            if [[ "$dry_run" == "true" ]]; then
                echo "$major.$minor.$((patch + 1))-unknown-dry"
            else
                echo "$major.$minor.$((patch + 1))-unknown"
            fi
            ;;
    esac
}

NEW_VERSION=$(determine_new_version "$BASE_VERSION" "$CURRENT_BRANCH" "$DRY_RUN" "$SPECIFIC_VERSION" "$BUMP_TYPE")
log_info "New version: $NEW_VERSION"

# Update version in goprox script
update_version "$NEW_VERSION" "$DRY_RUN"

# Function to get the current commit SHA
get_current_commit_sha() {
    git rev-parse HEAD
}

# Function to trigger release workflow (from full-release.zsh)
trigger_release_workflow() {
    local dry_run="$1"
    local prev_version="$2"
    local new_version="$3"
    
    if [[ "$dry_run" == "true" ]]; then
        log_info "DRY RUN: Would trigger release workflow"
        log_info "  Previous version: $prev_version"
        log_info "  New version: $new_version"
        return 0
    fi
    
    log_info "Triggering release workflow..."
    
    # Build release script arguments
    local release_args=(--force)
    if [[ -n "$prev_version" ]]; then
        release_args+=(--prev "$prev_version")
    fi
    release_args+=(--version "$new_version")
    
    # Execute release script
    local release_output
    if ! release_output=$(./scripts/release/trigger-workflow.zsh "${release_args[@]}" 2>&1); then
        log_error "Release workflow trigger failed"
        echo "$release_output"
        return 1
    fi
    
    echo "$release_output"
    log_success "Release workflow triggered successfully"
    return 0
}

# Function to monitor GitHub Actions workflows
monitor_github_actions() {
    local timeout_minutes="$1"
    local commit_sha="$2"
    local branch="$3"
    local dry_run="$4"
    
    log_info "Starting GitHub Actions monitoring for commit: $commit_sha"
    log_info "Branch: $branch, Timeout: ${timeout_minutes} minutes"
    
    # For dry runs, we don't expect workflows to be triggered
    if [[ "$dry_run" == "true" ]]; then
        log_info "Dry run detected - no workflows expected to be triggered"
        return 0
    fi
    
    local start_time=$(date +%s)
    local timeout_seconds=$((timeout_minutes * 60))
    local poll_interval=30  # Check every 30 seconds
    local max_attempts=$((timeout_seconds / poll_interval))
    local attempt=0
    
    echo ""
    echo "🔍 Monitoring GitHub Actions Workflows"
    echo "======================================"
    echo "Commit: $commit_sha"
    echo "Branch: $branch"
    echo "Timeout: ${timeout_minutes} minutes"
    echo ""
    
    while [[ $attempt -lt $max_attempts ]]; do
        attempt=$((attempt + 1))
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        local remaining=$((timeout_seconds - elapsed))
        
        echo -n "[$(date '+%H:%M:%S')] Checking workflows (attempt $attempt/$max_attempts, ${remaining}s remaining)... "
        
        # Get recent workflow runs for this commit
        local workflow_status
        if ! workflow_status=$(gh run list --limit 10 --json status,conclusion,workflowName,headSha,createdAt,url,number 2>/dev/null); then
            echo "❌ Failed to fetch workflow status"
            log_error "Failed to fetch GitHub Actions workflow status"
            return 1
        fi
        
        # Filter workflows for this specific commit
        local relevant_workflows=$(echo "$workflow_status" | jq -r --arg sha "$commit_sha" '.[] | select(.headSha == $sha) | "\(.number)|\(.workflowName)|\(.status)|\(.conclusion)"' 2>/dev/null)
        
        if [[ -z "$relevant_workflows" ]]; then
            echo "⏳ No workflows found yet for this commit"
            if [[ $attempt -eq 1 ]]; then
                echo "   This is normal for the first few checks - workflows may take time to start"
            fi
        else
            local all_completed=true
            local any_failed=false
            local workflow_count=0
            
            echo ""
            echo "   📊 Workflow Status:"
            
            while IFS='|' read -r run_number workflow_name wf_status conclusion; do
                [[ -z "$run_number" ]] && continue
                workflow_count=$((workflow_count + 1))
                
                case "$wf_status" in
                    "completed")
                        case "$conclusion" in
                            "success")
                                echo "   ✅ $workflow_name (#$run_number) - Completed successfully"
                                ;;
                            "failure"|"cancelled"|"timed_out")
                                echo "   ❌ $workflow_name (#$run_number) - Failed ($conclusion)"
                                any_failed=true
                                ;;
                            *)
                                echo "   ⚠️  $workflow_name (#$run_number) - Completed with unknown status ($conclusion)"
                                ;;
                        esac
                        ;;
                    "in_progress"|"queued"|"waiting")
                        echo "   🔄 $workflow_name (#$run_number) - $wf_status"
                        all_completed=false
                        ;;
                    *)
                        echo "   ❓ $workflow_name (#$run_number) - Unknown status ($wf_status)"
                        all_completed=false
                        ;;
                esac
            done <<< "$relevant_workflows"
            
            # Check if all workflows are completed
            if [[ "$all_completed" == "true" ]]; then
                if [[ "$any_failed" == "true" ]]; then
                    echo ""
                    echo "❌ Some workflows failed! Manual intervention required."
                    echo ""
                    echo "📋 Failed Workflow Details:"
                    echo "$relevant_workflows" | while IFS='|' read -r run_number workflow_name wf_status conclusion; do
                        [[ -z "$run_number" ]] && continue
                        if [[ "$conclusion" != "success" ]]; then
                            echo "   Workflow: $workflow_name (#$run_number)"
                            echo "   Status: $conclusion"
                            echo "   Logs: https://github.com/fxstein/GoProX/actions/runs/$run_number"
                            echo ""
                        fi
                    done
                    
                    log_error "GitHub Actions workflows failed for commit $commit_sha"
                    return 1
                else
                    echo ""
                    echo "✅ All workflows completed successfully!"
                    log_info "All GitHub Actions workflows completed successfully for commit $commit_sha"
                    return 0
                fi
            fi
        fi
        
        # Wait before next check
        if [[ $attempt -lt $max_attempts ]]; then
            sleep $poll_interval
        fi
    done
    
    echo ""
    echo "⏰ Timeout reached! Workflows may still be running."
    echo ""
    echo "📋 Manual verification required:"
    echo "   1. Check GitHub Actions: https://github.com/fxstein/GoProX/actions"
    echo "   2. Look for workflows for commit: $commit_sha"
    echo "   3. Verify all workflows complete successfully"
    echo "   4. Check for any error messages in the workflow logs"
    
    log_error "GitHub Actions monitoring timed out after ${timeout_minutes} minutes"
    return 1
}

# Handle summary file cleanup
handle_summary_cleanup() {
    local dry_run="$1"
    local preserve_summary="$2"
    local remove_summary="$3"
    local summary_file="$4"
    local base_version="$5"
    local monitor_timeout="$6"
    
    # Determine if we should remove the summary file
    local should_remove=false
    
    if [[ "$remove_summary" == "true" ]]; then
        should_remove=true
    elif [[ "$preserve_summary" == "false" && "$dry_run" == "false" ]]; then
        should_remove=true
    fi
    
    if [[ "$should_remove" == "true" ]]; then
        if [[ "$dry_run" == "true" ]]; then
            log_info "DRY RUN: Would remove summary file"
        else
            # Rename summary file to versioned format
            local versioned_file="$RELEASE_DIR/$(basename "$summary_file" .md)-$NEW_VERSION.md"
            
            display_branch_info "Archiving Summary" "Version: $NEW_VERSION, File: $versioned_file"
            
            mv "$summary_file" "$versioned_file"
            git add "$versioned_file"
            git commit -m "docs(release): archive AI summary for version $NEW_VERSION (refs #20)"
            
            # Get commit SHA after commit
            local commit_sha=$(get_current_commit_sha)
            
            display_branch_info "Pushing Summary Archive" "Commit: $commit_sha"
            
            git push origin "$CURRENT_BRANCH"
            
            # Monitor GitHub Actions workflows after summary cleanup push
            echo ""
            echo "🚀 Triggered GitHub Actions - Monitoring workflows..."
            if ! monitor_github_actions "$monitor_timeout" "$commit_sha" "$CURRENT_BRANCH" "$dry_run"; then
                log_error "GitHub Actions monitoring failed after summary cleanup"
                echo ""
                echo "❌ Release process failed due to workflow errors!"
                echo "   Please fix the workflow issues and retry the release."
                exit 1
            fi
        fi
    else
        log_info "Preserving summary file"
    fi
}

# Commit and push changes if not dry run
commit_and_push() {
    local dry_run="$1"
    local summary_file="$2"
    local monitor_timeout="$3"
    
    if [[ "$dry_run" == "true" ]]; then
        log_info "DRY RUN: Would commit and push changes"
        return 0
    fi
    
    # Check if there are any changes to commit
    if git diff-index --quiet HEAD --; then
        log_info "No changes to commit - version already up to date"
        return 1  # Signal to caller that nothing was committed
    fi
    
    # Add and commit changes
    display_branch_info "Committing Changes" "Version: $NEW_VERSION"
    
    git add "$PROJECT_ROOT/goprox" "$summary_file"
    git commit -m "chore(release): bump version to $NEW_VERSION (refs #20)"
    
    # Get commit SHA after commit
    local commit_sha=$(get_current_commit_sha)
    
    # Push to current branch
    display_branch_info "Pushing to Remote" "Commit: $commit_sha"
    
    git push origin "$CURRENT_BRANCH"
    
    log_info "Committed and pushed version $NEW_VERSION"
    
    # Monitor GitHub Actions workflows after push
    echo ""
    echo "🚀 Triggered GitHub Actions - Monitoring workflows..."
    if ! monitor_github_actions "$monitor_timeout" "$commit_sha" "$CURRENT_BRANCH" "$dry_run"; then
        log_error "GitHub Actions monitoring failed after commit and push"
        echo ""
        echo "❌ Release process failed due to workflow errors!"
        echo "   Please fix the workflow issues and retry the release."
        exit 1
    fi
    return 0
}

# Main release process
main_release_process() {
    local dry_run="$1"
    local base_version="$2"
    local new_version="$3"
    local monitor_timeout="$4"
    
    echo ""
    echo "┌─────────────────────────────────────────────────────────────────┐"
    echo "│                   GoProX Release Process                       │"
    echo "└─────────────────────────────────────────────────────────────────┘"
    echo ""
    
    local current_version=$(get_current_version)
    log_info "Starting release process for version: $current_version"
    
    # Step 1: Version bump (already done above)
    log_info "Step 1: Version bump completed - new version: $new_version"
    
    # Step 2: Trigger release workflow
    log_info "Step 2: Triggering release workflow..."
    if ! trigger_release_workflow "$dry_run" "$base_version" "$new_version"; then
        log_error "Release workflow trigger failed"
        exit 1
    fi
    
    # Step 3: Commit and push changes
    log_info "Step 3: Committing and pushing changes..."
    if ! commit_and_push "$dry_run" "$SUMMARY_FILE" "$monitor_timeout"; then
        log_info "No changes to commit or archive; release process is already up to date."
    else
        # Step 4: Handle summary cleanup
        if [[ "$dry_run" == "false" || "$REMOVE_SUMMARY" == "true" ]]; then
            handle_summary_cleanup "$dry_run" "$PRESERVE_SUMMARY" "$REMOVE_SUMMARY" "$SUMMARY_FILE" "$base_version" "$monitor_timeout"
        fi
    fi
    
    # Step 5: Monitor the release (if requested)
    if [[ "$MONITOR" == "true" ]]; then
        if [[ "$dry_run" == "true" ]]; then
            log_info "Step 5: Skipping monitoring (dry-run mode)"
        else
            log_info "Step 5: Monitoring release process..."
            # Monitoring is already done in commit_and_push and handle_summary_cleanup
        fi
    fi
    
    # Display completion message
    if [[ "$dry_run" == "true" ]]; then
        log_success "Dry-run release process completed!"
        echo ""
        log_info "Dry-Run Summary:"
        echo "  Version: $new_version"
        echo "  Status: Simulated successfully"
        echo "  Monitor: Skipped (dry-run)"
        echo ""
        log_info "All dry-run checks passed. Ready for real release."
    else
        log_success "Release process completed!"
        echo ""
        log_info "Release Summary:"
        echo "  Version: $new_version"
        echo "  Status: Completed"
        echo "  Monitor: Finished"
        echo ""
        log_info "You can view the release at: https://github.com/fxstein/GoProX/releases"
    fi
}

# Execute main release process
main_release_process "$DRY_RUN" "$BASE_VERSION" "$NEW_VERSION" "$MONITOR_TIMEOUT"

# Display next steps
show_next_steps() {
    local branch="$1"
    local dry_run="$2"
    local new_version="$3"
    
    echo ""
    echo "🎉 Git-Flow Release Process Complete!"
    echo ""
    echo "Branch: $branch"
    echo "Version: $new_version"
    echo "Mode: $([[ "$dry_run" == "true" ]] && echo "Dry Run" || echo "Real Release")"
    echo ""
    
    case "$branch" in
        feature/*)
            echo "📋 Next Steps:"
            echo "  1. Test the changes in this feature branch"
            echo "  2. Create a pull request to develop"
            echo "  3. Merge when ready"
            ;;
        develop)
            if [[ "$dry_run" == "true" ]]; then
                echo "📋 Next Steps:"
                echo "  1. Review the dry-run results"
                echo "  2. Create a release branch: git checkout -b release/$new_version"
                echo "  3. Run: $0 $BASE_VERSION"
            else
                echo "📋 Next Steps:"
                echo "  1. Create a release branch: git checkout -b release/$new_version"
                echo "  2. Run: $0 $BASE_VERSION"
                echo "  3. Create pull request to main"
            fi
            ;;
        release/*)
            if [[ "$dry_run" == "true" ]]; then
                echo "📋 Next Steps:"
                echo "  1. Review the dry-run results"
                echo "  2. Run: $0 $BASE_VERSION (for real beta release)"
            else
                echo "📋 Next Steps:"
                echo "  1. Create pull request to main"
                echo "  2. Merge for official release"
            fi
            ;;
        main)
            echo "📋 Next Steps:"
            echo "  1. Official release complete!"
            echo "  2. Create a new develop branch for next development cycle"
            ;;
    esac
}

show_next_steps "$CURRENT_BRANCH" "$DRY_RUN" "$NEW_VERSION"

log_info "Git-flow release process completed successfully" 