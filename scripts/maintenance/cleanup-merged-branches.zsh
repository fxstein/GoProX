#!/bin/zsh
# cleanup-merged-branches.zsh
# Clean up local and remote branches that have been merged

set -e

# Source the logger
SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/../core/logger.zsh"

# Configuration
DRY_RUN=${DRY_RUN:-false}
FORCE=${FORCE:-false}
CLEANUP_REMOTE=${CLEANUP_REMOTE:-true}
CLEANUP_LOCAL=${CLEANUP_LOCAL:-true}

# Branch patterns to protect
PROTECTED_BRANCHES=("main" "develop" "master")

# Function to check if branch is protected
is_protected_branch() {
    local branch="$1"
    for protected in "${PROTECTED_BRANCHES[@]}"; do
        if [[ "$branch" == "$protected" ]]; then
            return 0
        fi
    done
    return 1
}

# Function to check if branch exists
branch_exists() {
    local branch="$1"
    git show-ref --verify --quiet refs/heads/"$branch"
}

# Function to check if remote branch exists
remote_branch_exists() {
    local branch="$1"
    git ls-remote --heads origin "$branch" | grep -q "$branch"
}

# Function to delete local branch
delete_local_branch() {
    local branch="$1"
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN: Would delete local branch: $branch"
    else
        log_info "Deleting local branch: $branch"
        git branch -d "$branch" || {
            if [[ "$FORCE" == "true" ]]; then
                log_warn "Force deleting local branch: $branch"
                git branch -D "$branch"
            else
                log_error "Failed to delete local branch: $branch (use --force to force delete)"
                return 1
            fi
        }
        log_success "Deleted local branch: $branch"
    fi
}

# Function to delete remote branch
delete_remote_branch() {
    local branch="$1"
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN: Would delete remote branch: $branch"
    else
        log_info "Deleting remote branch: $branch"
        git push origin --delete "$branch" || {
            log_error "Failed to delete remote branch: $branch"
            return 1
        }
        log_success "Deleted remote branch: $branch"
    fi
}

# Function to cleanup merged branches
cleanup_merged_branches() {
    log_info "Starting branch cleanup process..."
    
    # Get current branch
    local current_branch=$(git branch --show-current)
    log_info "Current branch: $current_branch"
    
    # Get merged branches
    local merged_branches=()
    while IFS= read -r branch; do
        if [[ -n "$branch" ]]; then
            merged_branches+=("$branch")
        fi
    done < <(git branch --merged | sed 's/^[ *]*//' | grep -v "^$")
    
    log_info "Found ${#merged_branches[@]} merged branches"
    
    local deleted_count=0
    local skipped_count=0
    
    # Process each merged branch
    for branch in "${merged_branches[@]}"; do
        # Skip current branch
        if [[ "$branch" == "$current_branch" ]]; then
            log_info "Skipping current branch: $branch"
            ((skipped_count++))
            continue
        fi
        
        # Skip protected branches
        if is_protected_branch "$branch"; then
            log_info "Skipping protected branch: $branch"
            ((skipped_count++))
            continue
        fi
        
        # Delete local branch
        if [[ "$CLEANUP_LOCAL" == "true" ]]; then
            if delete_local_branch "$branch"; then
                ((deleted_count++))
            fi
        fi
        
        # Delete remote branch if it exists
        if [[ "$CLEANUP_REMOTE" == "true" ]] && remote_branch_exists "$branch"; then
            if delete_remote_branch "$branch"; then
                log_info "Remote branch $branch marked for deletion"
            fi
        fi
    done
    
    # Cleanup stale remote references
    if [[ "$CLEANUP_REMOTE" == "true" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "DRY RUN: Would prune stale remote references"
        else
            log_info "Pruning stale remote references..."
            git remote prune origin
            log_success "Stale remote references cleaned up"
        fi
    fi
    
    # Summary
    log_success "Branch cleanup completed!"
    log_info "Summary:"
    log_info "  - Branches processed: ${#merged_branches[@]}"
    log_info "  - Branches deleted: $deleted_count"
    log_info "  - Branches skipped: $skipped_count"
    log_info "  - Current branch: $current_branch"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warn "This was a dry run. No branches were actually deleted."
    fi
}

# Function to show help
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Clean up local and remote branches that have been merged.

OPTIONS:
    --dry-run              Show what would be deleted without actually deleting
    --force                Force delete branches even if not fully merged
    --local-only           Only cleanup local branches
    --remote-only          Only cleanup remote branches
    --help                 Show this help message

EXAMPLES:
    $0                     # Clean up all merged branches
    $0 --dry-run          # Show what would be deleted
    $0 --force            # Force delete branches
    $0 --local-only       # Only cleanup local branches

ENVIRONMENT VARIABLES:
    DRY_RUN=true          # Same as --dry-run
    FORCE=true            # Same as --force
    CLEANUP_REMOTE=false  # Same as --local-only
    CLEANUP_LOCAL=false   # Same as --remote-only

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --local-only)
            CLEANUP_REMOTE=false
            shift
            ;;
        --remote-only)
            CLEANUP_LOCAL=false
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    log_error "Not in a git repository"
    exit 1
fi

# Check if we have a remote configured
if [[ "$CLEANUP_REMOTE" == "true" ]] && ! git remote get-url origin > /dev/null 2>&1; then
    log_error "No remote 'origin' configured"
    exit 1
fi

# Run the cleanup
cleanup_merged_branches 