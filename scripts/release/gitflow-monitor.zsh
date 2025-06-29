#!/usr/bin/env zsh

# Git-Flow Monitor Script for GoProX
# Provides branch-aware status reporting and recommendations for git-flow release process

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RELEASE_DIR="$PROJECT_ROOT/docs/release"
OUTPUT_DIR="$PROJECT_ROOT/output"

# Source the logger
export LOGFILE="$OUTPUT_DIR/gitflow-monitor.log"
mkdir -p "$(dirname "$LOGFILE")"
source "$(dirname "$0")/../core/logger.zsh"

log_info "Starting git-flow monitor"

# Function to display usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Git-Flow Monitor Script for GoProX

OPTIONS:
    --verbose              Show detailed information
    --check-summary        Check AI summary file status
    --check-workflow       Check GitHub Actions workflow status
    --monitor-release      Monitor a release process (requires --base-version and --branch)
    --base-version         Base version for release monitoring (e.g., 01.10.00)
    --branch               Branch for release monitoring (e.g., develop, release/01.10.01)
    --dry-run              Indicate if this is a dry-run release
    --all                  Run all checks (default)
    --help                 Show this help message

EXAMPLES:
    $0                     # Run all checks
    $0 --verbose           # Run all checks with detailed output
    $0 --check-summary     # Only check AI summary status
    $0 --monitor-release --base-version 01.10.00 --branch develop --dry-run  # Monitor dry-run release
    $0 --monitor-release --base-version 01.10.00 --branch main              # Monitor real release
EOF
}

# Parse command line arguments
VERBOSE=false
CHECK_SUMMARY=true
CHECK_WORKFLOW=true
MONITOR_RELEASE=false
BASE_VERSION=""
BRANCH=""
DRY_RUN="false"

while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose)
            VERBOSE=true
            shift
            ;;
        --check-summary)
            CHECK_SUMMARY=true
            CHECK_WORKFLOW=false
            MONITOR_RELEASE=false
            shift
            ;;
        --check-workflow)
            CHECK_WORKFLOW=true
            CHECK_SUMMARY=false
            MONITOR_RELEASE=false
            shift
            ;;
        --monitor-release)
            MONITOR_RELEASE=true
            CHECK_SUMMARY=false
            CHECK_WORKFLOW=false
            shift
            ;;
        --base-version)
            BASE_VERSION="$2"
            shift 2
            ;;
        --branch)
            BRANCH="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN="true"
            shift
            ;;
        --all)
            CHECK_SUMMARY=true
            CHECK_WORKFLOW=true
            MONITOR_RELEASE=false
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
            log_error "Unexpected argument: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate monitor-release options
if [[ "$MONITOR_RELEASE" == "true" ]]; then
    if [[ -z "$BASE_VERSION" ]]; then
        log_error "Monitor release requires --base-version"
        show_usage
        exit 1
    fi
    if [[ -z "$BRANCH" ]]; then
        log_error "Monitor release requires --branch"
        show_usage
        exit 1
    fi
fi

# Get current branch and git status
CURRENT_BRANCH=$(git branch --show-current)
CURRENT_VERSION=$(grep "__version__=" "$PROJECT_ROOT/goprox" | sed "s/__version__='//;s/'//")

log_info "Current branch: $CURRENT_BRANCH"
log_info "Current version: $CURRENT_VERSION"

# Function to check git status
check_git_status() {
    echo "🔍 Git Status Check"
    echo "=================="
    
    # Check if we're on a supported branch
    case "$CURRENT_BRANCH" in
        feature/*|develop|release/*|main)
            echo "✅ Branch: $CURRENT_BRANCH (supported for git-flow)"
            ;;
        *)
            echo "⚠️  Branch: $CURRENT_BRANCH (not a standard git-flow branch)"
            ;;
    esac
    
    # Check for uncommitted changes
    if git diff-index --quiet HEAD --; then
        echo "✅ Working directory is clean"
    else
        echo "⚠️  Uncommitted changes detected:"
        if [[ "$VERBOSE" == "true" ]]; then
            git status --porcelain
        else
            git status --porcelain | head -5
            if [[ $(git status --porcelain | wc -l) -gt 5 ]]; then
                echo "   ... and $(( $(git status --porcelain | wc -l) - 5 )) more files"
            fi
        fi
    fi
    
    # Check if we're up to date with remote
    git fetch origin >/dev/null 2>&1
    LOCAL_COMMIT=$(git rev-parse HEAD)
    REMOTE_COMMIT=$(git rev-parse origin/$CURRENT_BRANCH 2>/dev/null || echo "none")
    
    if [[ "$LOCAL_COMMIT" == "$REMOTE_COMMIT" ]]; then
        echo "✅ Branch is up to date with remote"
    else
        echo "⚠️  Branch is not up to date with remote"
        if [[ "$VERBOSE" == "true" ]]; then
            echo "   Local:  $LOCAL_COMMIT"
            echo "   Remote: $REMOTE_COMMIT"
        fi
    fi
    
    echo ""
}

# Function to check AI summary files
check_ai_summaries() {
    echo "📋 AI Summary Files Check"
    echo "========================="
    
    # Find all AI summary files
    SUMMARY_FILES=($(find "$RELEASE_DIR" -name "latest-major-changes-since-*.md" -type f))
    
    if [[ ${#SUMMARY_FILES[@]} -eq 0 ]]; then
        echo "❌ No AI summary files found"
        echo "   Expected: docs/release/latest-major-changes-since-XX.XX.XX.md"
        return 1
    fi
    
    echo "✅ Found ${#SUMMARY_FILES[@]} AI summary file(s):"
    
    for file in "${SUMMARY_FILES[@]}"; do
        local base_version=$(basename "$file" .md | sed 's/latest-major-changes-since-//')
        local file_size=$(wc -c < "$file")
        local last_modified=$(stat -f "%Sm" "$file" 2>/dev/null || stat -c "%y" "$file" 2>/dev/null)
        
        echo "   📄 $base_version ($(numfmt --to=iec $file_size), modified: $last_modified)"
        
        if [[ "$VERBOSE" == "true" ]]; then
            echo "      Path: $file"
            # Show first few lines
            echo "      Preview:"
            head -3 "$file" | sed 's/^/         /'
            echo ""
        fi
    done
    
    # Check if any summary files match current version
    local version_matches=false
    for file in "${SUMMARY_FILES[@]}"; do
        local base_version=$(basename "$file" .md | sed 's/latest-major-changes-since-//')
        if [[ "$base_version" == "$CURRENT_VERSION" ]]; then
            version_matches=true
            break
        fi
    done
    
    if [[ "$version_matches" == "true" ]]; then
        echo "✅ Found summary file matching current version ($CURRENT_VERSION)"
    else
        echo "⚠️  No summary file found for current version ($CURRENT_VERSION)"
    fi
    
    echo ""
}

# Function to check GitHub Actions workflow status
check_workflow_status() {
    echo "🚀 GitHub Actions Workflow Check"
    echo "==============================="
    
    # Check if we have GitHub CLI installed
    if ! command -v gh >/dev/null 2>&1; then
        echo "⚠️  GitHub CLI not installed - cannot check workflow status"
        echo "   Install with: brew install gh"
        echo ""
        return 0
    fi
    
    # Check if we're authenticated
    if ! gh auth status >/dev/null 2>&1; then
        echo "⚠️  GitHub CLI not authenticated - cannot check workflow status"
        echo "   Run: gh auth login"
        echo ""
        return 0
    fi
    
    # Get recent workflow runs
    echo "📊 Recent workflow runs:"
    
    # Get the last 5 workflow runs
    local workflow_runs=$(gh run list --limit 5 --json status,conclusion,workflowName,createdAt,headBranch,url,id 2>/dev/null || echo "[]")
    
    if [[ "$workflow_runs" == "[]" ]]; then
        echo "   No recent workflow runs found"
    else
        echo "$workflow_runs" | jq -r '.[] | "   \(.workflowName) (\(.headBranch)): \(.status) - \(.conclusion // "in_progress") [ID: \(.id)]"' 2>/dev/null || echo "   Error parsing workflow runs"
    fi
    
    # Check for specific release-related workflows
    echo ""
    echo "🔍 Release Workflow Status:"
    
    # Look for release workflows in the last 10 runs
    local release_runs=$(gh run list --limit 10 --json status,conclusion,workflowName,createdAt,headBranch,url,id 2>/dev/null | jq -r '.[] | select(.workflowName | contains("Release") or contains("release")) | "\(.workflowName) (\(.headBranch)): \(.status) - \(.conclusion // "in_progress") [ID: \(.id)]"' 2>/dev/null || echo "   No release workflows found")
    
    if [[ -z "$release_runs" ]]; then
        echo "   No recent release workflows found"
    else
        echo "$release_runs"
    fi
    
    echo ""
}

# Function to verify release workflow completion
verify_release_workflow() {
    local expected_branch="$1"
    local expected_workflow="$2"
    local timeout_minutes="${3:-10}"
    
    echo "🔍 Verifying Release Workflow Completion"
    echo "======================================="
    echo "Expected branch: $expected_branch"
    echo "Expected workflow: $expected_workflow"
    echo "Timeout: ${timeout_minutes} minutes"
    echo ""
    
    # Check if we have GitHub CLI
    if ! command -v gh >/dev/null 2>&1; then
        echo "❌ GitHub CLI not available for workflow verification"
        return 1
    fi
    
    if ! gh auth status >/dev/null 2>&1; then
        echo "❌ GitHub CLI not authenticated for workflow verification"
        return 1
    fi
    
    local start_time=$(date +%s)
    local end_time=$((start_time + (timeout_minutes * 60)))
    local check_interval=30  # Check every 30 seconds
    
    echo "⏳ Waiting for workflow completion..."
    
    while [[ $(date +%s) -lt $end_time ]]; do
        # Get the most recent workflow run for the expected branch
        local latest_run=$(gh run list --limit 1 --json status,conclusion,workflowName,headBranch,url,id --jq ".[] | select(.headBranch == \"$expected_branch\" and (.workflowName | contains(\"$expected_workflow\")))" 2>/dev/null)
        
        if [[ -n "$latest_run" ]]; then
            local status=$(echo "$latest_run" | jq -r '.status')
            local conclusion=$(echo "$latest_run" | jq -r '.conclusion // "null"')
            local workflow_name=$(echo "$latest_run" | jq -r '.workflowName')
            local run_id=$(echo "$latest_run" | jq -r '.id')
            local run_url=$(echo "$latest_run" | jq -r '.url')
            
            echo "📊 Found workflow: $workflow_name (ID: $run_id)"
            echo "   Status: $status"
            echo "   Conclusion: $conclusion"
            echo "   URL: $run_url"
            
            if [[ "$status" == "completed" ]]; then
                if [[ "$conclusion" == "success" ]]; then
                    echo "✅ Release workflow completed successfully!"
                    echo "   Run ID: $run_id"
                    echo "   URL: $run_url"
                    return 0
                elif [[ "$conclusion" == "failure" ]]; then
                    echo "❌ Release workflow failed!"
                    echo "   Run ID: $run_id"
                    echo "   URL: $run_url"
                    echo ""
                    echo "📋 Recent workflow logs:"
                    gh run view "$run_id" --log --limit 20 2>/dev/null || echo "   Unable to fetch logs"
                    return 1
                elif [[ "$conclusion" == "cancelled" ]]; then
                    echo "⚠️  Release workflow was cancelled"
                    echo "   Run ID: $run_id"
                    echo "   URL: $run_url"
                    return 1
                fi
            else
                echo "⏳ Workflow still running... (status: $status)"
            fi
        else
            echo "⏳ Waiting for workflow to start..."
        fi
        
        sleep $check_interval
    done
    
    echo "⏰ Timeout reached after ${timeout_minutes} minutes"
    echo "❌ Release workflow verification failed"
    return 1
}

# Function to monitor release process
monitor_release_process() {
    local base_version="$1"
    local branch="$2"
    local dry_run="$3"
    
    echo "🚀 Release Process Monitor"
    echo "========================="
    echo "Base version: $base_version"
    echo "Branch: $branch"
    echo "Mode: $([[ "$dry_run" == "true" ]] && echo "Dry Run" || echo "Real Release")"
    echo ""
    
    # Determine expected workflow based on branch and mode
    local expected_workflow=""
    case "$branch" in
        feature/*)
            expected_workflow="Comprehensive Testing"
            ;;
        develop)
            if [[ "$dry_run" == "true" ]]; then
                expected_workflow="Comprehensive Testing"
            else
                expected_workflow="Multi-Channel Release Management"
            fi
            ;;
        release/*)
            if [[ "$dry_run" == "true" ]]; then
                expected_workflow="Comprehensive Testing"
            else
                expected_workflow="Multi-Channel Release Management"
            fi
            ;;
        main)
            expected_workflow="Multi-Channel Release Management"
            ;;
        *)
            echo "⚠️  Unknown branch type for monitoring: $branch"
            return 1
            ;;
    esac
    
    echo "Expected workflow: $expected_workflow"
    echo ""
    
    # If this is a real release, verify workflow completion
    if [[ "$dry_run" == "false" ]]; then
        echo "🔍 Starting workflow verification..."
        if verify_release_workflow "$branch" "$expected_workflow" 15; then
            echo "✅ Release process completed successfully!"
            return 0
        else
            echo "❌ Release process failed or timed out"
            return 1
        fi
    else
        echo "ℹ️  Dry run mode - skipping workflow verification"
        echo "   To verify manually, check: https://github.com/fxstein/GoProX/actions"
        return 0
    fi
}

# Function to provide branch-specific recommendations
provide_recommendations() {
    echo "💡 Branch-Specific Recommendations"
    echo "================================="
    
    case "$CURRENT_BRANCH" in
        feature/*)
            echo "🎯 Feature Branch Recommendations:"
            echo "   • Use: scripts/release/gitflow-release.zsh --dry-run --allow-unclean <base_version>"
            echo "   • Test your changes thoroughly"
            echo "   • Create pull request to develop when ready"
            echo "   • Ensure AI summary file exists for target version"
            ;;
        develop)
            echo "🎯 Develop Branch Recommendations:"
            echo "   • Use: scripts/release/gitflow-release.zsh --dry-run <base_version> (for testing)"
            echo "   • Use: scripts/release/gitflow-release.zsh <base_version> (for real release)"
            echo "   • Create release branch after successful release"
            echo "   • Ensure all feature branches are merged"
            ;;
        release/*)
            echo "🎯 Release Branch Recommendations:"
            echo "   • Use: scripts/release/gitflow-release.zsh --dry-run <base_version> (for testing)"
            echo "   • Use: scripts/release/gitflow-release.zsh <base_version> (for beta release)"
            echo "   • Create pull request to main for official release"
            echo "   • Test thoroughly before merging to main"
            ;;
        main)
            echo "🎯 Main Branch Recommendations:"
            echo "   • Use: scripts/release/gitflow-release.zsh <base_version> (for official release)"
            echo "   • Ensure release branch is merged"
            echo "   • Create new develop branch for next cycle"
            echo "   • Tag the release after successful deployment"
            ;;
        *)
            echo "🎯 General Recommendations:"
            echo "   • Switch to a supported git-flow branch"
            echo "   • Use: scripts/release/gitflow-release.zsh --help for usage"
            echo "   • Ensure AI summary file exists"
            ;;
    esac
    
    echo ""
}

# Function to check release readiness
check_release_readiness() {
    echo "✅ Release Readiness Check"
    echo "========================="
    
    local ready=true
    local issues=()
    
    # Check if we have uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        ready=false
        issues+=("Uncommitted changes detected")
    fi
    
    # Check if we're up to date with remote
    git fetch origin >/dev/null 2>&1
    LOCAL_COMMIT=$(git rev-parse HEAD)
    REMOTE_COMMIT=$(git rev-parse origin/$CURRENT_BRANCH 2>/dev/null || echo "none")
    
    if [[ "$LOCAL_COMMIT" != "$REMOTE_COMMIT" ]]; then
        ready=false
        issues+=("Branch not up to date with remote")
    fi
    
    # Check if we have AI summary files
    SUMMARY_FILES=($(find "$RELEASE_DIR" -name "latest-major-changes-since-*.md" -type f))
    if [[ ${#SUMMARY_FILES[@]} -eq 0 ]]; then
        ready=false
        issues+=("No AI summary files found")
    fi
    
    # Check branch-specific requirements
    case "$CURRENT_BRANCH" in
        feature/*)
            # Feature branches need --allow-unclean for releases
            echo "⚠️  Feature branch: Use --allow-unclean flag for releases"
            ;;
        main)
            # Main branch should not have uncommitted changes
            if ! git diff-index --quiet HEAD --; then
                ready=false
                issues+=("Main branch has uncommitted changes")
            fi
            ;;
    esac
    
    if [[ "$ready" == "true" ]]; then
        echo "✅ Ready for release"
    else
        echo "❌ Not ready for release:"
        for issue in "${issues[@]}"; do
            echo "   • $issue"
        done
    fi
    
    echo ""
}

# Main execution
main() {
    echo "🚀 GoProX Git-Flow Monitor"
    echo "=========================="
    echo ""
    
    # Handle release monitoring mode
    if [[ "$MONITOR_RELEASE" == "true" ]]; then
        monitor_release_process "$BASE_VERSION" "$BRANCH" "$DRY_RUN"
        return $?
    fi
    
    # Standard monitoring mode
    check_git_status
    
    if [[ "$CHECK_SUMMARY" == "true" ]]; then
        check_ai_summaries
    fi
    
    if [[ "$CHECK_WORKFLOW" == "true" ]]; then
        check_workflow_status
    fi
    
    provide_recommendations
    check_release_readiness
    
    echo "📝 Monitor complete. Use --verbose for detailed information."
    echo ""
    echo "💡 For release monitoring, use:"
    echo "   $0 --monitor-release --base-version <version> --branch <branch> [--dry-run]"
}

# Run main function
main

log_info "Git-flow monitor completed successfully" 