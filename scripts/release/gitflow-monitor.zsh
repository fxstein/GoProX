#!/usr/bin/env zsh

# Git-Flow Monitor Script for GoProX
# Provides branch-aware status reporting and recommendations for git-flow release process

set -euo pipefail

# Source the logger
source "$(dirname "$0")/../core/logger.zsh"

# Configuration
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RELEASE_DIR="$PROJECT_ROOT/docs/release"
OUTPUT_DIR="$PROJECT_ROOT/output"

# Initialize logger
init_logger "$OUTPUT_DIR/gitflow-monitor.log" "INFO"

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
    --all                  Run all checks (default)
    --help                 Show this help message

EXAMPLES:
    $0                     # Run all checks
    $0 --verbose           # Run all checks with detailed output
    $0 --check-summary     # Only check AI summary status
EOF
}

# Parse command line arguments
VERBOSE=false
CHECK_SUMMARY=true
CHECK_WORKFLOW=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose)
            VERBOSE=true
            shift
            ;;
        --check-summary)
            CHECK_SUMMARY=true
            CHECK_WORKFLOW=false
            shift
            ;;
        --check-workflow)
            CHECK_WORKFLOW=true
            CHECK_SUMMARY=false
            shift
            ;;
        --all)
            CHECK_SUMMARY=true
            CHECK_WORKFLOW=true
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
    local workflow_runs=$(gh run list --limit 5 --json status,conclusion,workflowName,createdAt,headBranch 2>/dev/null || echo "[]")
    
    if [[ "$workflow_runs" == "[]" ]]; then
        echo "   No recent workflow runs found"
    else
        echo "$workflow_runs" | jq -r '.[] | "   \(.workflowName) (\(.headBranch)): \(.status) - \(.conclusion // "in_progress")"' 2>/dev/null || echo "   Error parsing workflow runs"
    fi
    
    echo ""
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
}

# Run main function
main

log_info "Git-flow monitor completed successfully" 