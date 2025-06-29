#!/bin/zsh

# Create Branch Script for GoProX
# Automatically creates a separate branch for different types of work to maintain clean development

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUTPUT_DIR="$PROJECT_ROOT/output"

# Source the logger
export LOGFILE="$OUTPUT_DIR/create-branch.log"
mkdir -p "$(dirname "$LOGFILE")"
source "$(dirname "$0")/../core/logger.zsh"

# Function to get branch prefix based on type
get_branch_prefix() {
    local type="$1"
    case "$type" in
        bug|fix)
            echo "fix"
            ;;
        enhancement|feature|feat)
            echo "feat"
            ;;
        cleanup|refactor)
            echo "refactor"
            ;;
        release|rel)
            echo "rel"
            ;;
        hotfix|hot)
            echo "hot"
            ;;
        documentation|docs)
            echo "docs"
            ;;
        test|testing)
            echo "test"
            ;;
        *)
            echo "fix"  # default to fix for unknown types
            ;;
    esac
}

# Function to display usage
show_usage() {
    cat << 'EOF'
Usage: create-branch.zsh [OPTIONS] <work_description>

Create Branch Script for GoProX

OPTIONS:
    --type <type>           Type of work (bug, enhancement, feature, cleanup, etc.)
    --issue <number>        GitHub issue number (optional)
    --base <branch>         Base branch to create branch from (default: develop)
    --help                  Show this help message

WORK_DESCRIPTION:
    Brief description of the work (will be used in branch name)

EXAMPLES:
    create-branch.zsh "fix CI test failures" --type bug --issue 123
    create-branch.zsh "add hash-based branch display" --type enhancement --issue 20
    create-branch.zsh "update documentation" --type cleanup
    create-branch.zsh "add new feature" --type feature --base feature/new-feature

BRANCH NAMING:
    Branch will be named: <prefix>/<type>-<description-slug>-<timestamp>
    Examples: 
    - fix/bug-ci-test-failures-20250629-114500
    - feat/enhancement-add-hash-based-branch-display-20-20250629-114500
    - docs/cleanup-update-documentation-20250629-114500

SUPPORTED TYPES:
    bug, fix          -> fix/
    enhancement, feature, feat -> feat/
    cleanup, refactor -> refactor/
    release, rel      -> rel/
    hotfix, hot       -> hot/
    documentation, docs -> docs/
    test, testing     -> test/
EOF
}

# Parse command line arguments
WORK_TYPE="fix"
ISSUE_NUMBER=""
BASE_BRANCH="develop"
WORK_DESCRIPTION=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --type)
            WORK_TYPE="$2"
            shift 2
            ;;
        --issue)
            ISSUE_NUMBER="$2"
            shift 2
            ;;
        --base)
            BASE_BRANCH="$2"
            shift 2
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
            WORK_DESCRIPTION="$1"
            shift
            ;;
    esac
done

# Validate work description
if [[ -z "$WORK_DESCRIPTION" ]]; then
    log_error "Work description is required"
    show_usage
    exit 1
fi

# Get the appropriate branch prefix
BRANCH_PREFIX=$(get_branch_prefix "$WORK_TYPE")

log_info "Starting branch creation"
log_info "Work type: $WORK_TYPE"
log_info "Branch prefix: $BRANCH_PREFIX"
log_info "Issue number: $ISSUE_NUMBER"
log_info "Base branch: $BASE_BRANCH"
log_info "Work description: $WORK_DESCRIPTION"

# Display current branch information
source "$(dirname "$0")/../core/logger.zsh"
display_branch_info "Creating $BRANCH_PREFIX branch" "Base: $BASE_BRANCH, Type: $WORK_TYPE"

# Check if we're on the base branch
CURRENT_BRANCH=$(git branch --show-current)
if [[ "$CURRENT_BRANCH" != "$BASE_BRANCH" ]]; then
    echo ""
    echo "⚠️  You are not on the base branch ($BASE_BRANCH)"
    echo "📍 Current branch: $CURRENT_BRANCH"
    echo ""
    echo "Options:"
    echo "1. Switch to $BASE_BRANCH and continue"
    echo "2. Create branch from current branch ($CURRENT_BRANCH)"
    echo "3. Cancel"
    echo ""
    echo "Enter choice (1/2/3): "
    read -r choice
    
    case $choice in
        1)
            echo "Switching to $BASE_BRANCH..."
            git checkout "$BASE_BRANCH"
            git pull origin "$BASE_BRANCH"
            ;;
        2)
            BASE_BRANCH="$CURRENT_BRANCH"
            echo "Using current branch ($CURRENT_BRANCH) as base"
            ;;
        3)
            log_info "Branch creation cancelled"
            exit 0
            ;;
        *)
            log_error "Invalid choice"
            exit 1
            ;;
    esac
fi

# Generate branch name
TIMESTAMP=$(date '+%Y%m%d-%H%M%S')
DESCRIPTION_SLUG=$(echo "$WORK_DESCRIPTION" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-\|-$//g')

if [[ -n "$ISSUE_NUMBER" ]]; then
    BRANCH_NAME="${BRANCH_PREFIX}/${WORK_TYPE}-${DESCRIPTION_SLUG}-${ISSUE_NUMBER}-${TIMESTAMP}"
else
    BRANCH_NAME="${BRANCH_PREFIX}/${WORK_TYPE}-${DESCRIPTION_SLUG}-${TIMESTAMP}"
fi

log_info "Generated branch name: $BRANCH_NAME"

# Create and switch to the new branch
echo ""
echo "🌿 Creating $BRANCH_PREFIX Branch"
echo "================================="
echo "📍 BASE BRANCH: $BASE_BRANCH"
echo "📍 NEW BRANCH: $BRANCH_NAME"
echo "📍 WORK TYPE: $WORK_TYPE"
echo "📍 DESCRIPTION: $WORK_DESCRIPTION"
if [[ -n "$ISSUE_NUMBER" ]]; then
    echo "📍 ISSUE: #$ISSUE_NUMBER"
fi
echo "================================="
echo ""

git checkout -b "$BRANCH_NAME"

# Push the branch to remote
echo ""
echo "🚀 Pushing Branch to Remote"
echo "==========================="
echo "📍 BRANCH: $BRANCH_NAME"
echo "==========================="
echo ""

git push -u origin "$BRANCH_NAME"

# Display next steps
echo ""
echo "✅ $BRANCH_PREFIX Branch Created Successfully!"
echo ""
echo "📋 Next Steps:"
echo "   1. Make your changes in this branch"
echo "   2. Commit with descriptive messages"
echo "   3. Push changes: git push origin $BRANCH_NAME"
echo "   4. Create pull request to $BASE_BRANCH"
if [[ -n "$ISSUE_NUMBER" ]]; then
    echo "   5. Reference issue #$ISSUE_NUMBER in PR description"
fi
echo ""
echo "🔗 Branch URL: https://github.com/fxstein/GoProX/tree/$BRANCH_NAME"
echo ""

log_info "$BRANCH_PREFIX branch creation completed successfully" 