#!/bin/zsh
#
# full-release.zsh: Complete automated release process for GoProX
#
# Enhanced Logging: Implements robust logging to both console and output/release.log, with verbosity control and error trapping (see Issue #71)
#
# Logging Usage:
#   - All log messages are written to both stdout and output/release.log
#   - Use --verbose to enable debug-level logging
#   - On error, logs the last command and line number
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
# Usage: ./full-release.zsh
#
# GoProX Full Release Script
# This script performs the complete release process:
# 1. Bump version with --auto --push --force
# 2. Trigger the release workflow
# 3. Monitor the release process

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
Usage: full-release.zsh [options]

This script performs the complete GoProX release process:
1. Bump version with --auto --push --force
2. Trigger release workflow
3. Monitor the release process

Options:
  -h, --help            show this help message and exit
  --dry-run             perform a dry run (no actual release)
  --prev <version>      specify previous version for changelog
  --base <version>      alias for --prev (backward compatibility)
  --version <version>   specify version to release (default: auto-increment)
  --force               force execution without confirmation
  --major               bump major version (default: minor)
  --minor               bump minor version (default)
  --patch               bump patch version
  --preserve-summary    preserve summary file (override default behavior)
  --remove-summary      rename/remove summary file (override default behavior)
  --allow-unclean       allow uncommitted changes for dry runs only (not default)

Summary File Behavior:
  Default: Dry-runs preserve summary file, real releases rename it
  --preserve-summary: Force preserve even for real releases
  --remove-summary: Force rename even for dry-runs

Examples:
  ./scripts/release/full-release.zsh --dry-run --prev 00.52.00
  ./scripts/release/full-release.zsh --dry-run --base 00.52.00
  ./scripts/release/full-release.zsh --prev 00.52.00 --version 01.00.15
  ./scripts/release/full-release.zsh --dry-run --prev 01.00.13 --patch
  ./scripts/release/full-release.zsh --prev 00.52.00 --preserve-summary
  ./scripts/release/full-release.zsh --dry-run --prev 00.52.00 --remove-summary

The script is fully automated and requires no user interaction.
EOF
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
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
    
    # Check if required scripts exist
    if [[ ! -f "scripts/release/bump-version.zsh" ]]; then
        print_error "bump-version.zsh script not found"
        exit 1
    fi
    
    if [[ ! -f "scripts/release/release.zsh" ]]; then
        print_error "release.zsh script not found"
        exit 1
    fi
    
    if [[ ! -f "scripts/release/monitor-release.zsh" ]]; then
        print_error "monitor-release.zsh script not found"
        exit 1
    fi
    
    print_success "All prerequisites met"
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
    echo "│                   GoProX Full Release                          │"
    echo "└─────────────────────────────────────────────────────────────────┘"
    echo ""
    
    # Initialize variables
    dry_run="false"
    prev_version=""
    version=""
    force="false"
    bump_type="minor"
    preserve_summary="false"
    remove_summary="false"
    allow_unclean="false"
    
    # Parse options using zparseopts for strict parameter validation
    declare -A opts
    zparseopts -D -E -F -A opts - \
                h -help \
                -dry-run \
                -prev: \
                -base: \
                -version: \
                -force \
                -major \
                -minor \
                -patch \
                -verbose \
                -debug \
                -preserve-summary \
                -remove-summary \
                -allow-unclean \
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
            --dry-run)
                dry_run="true"
                ;;
            --prev|--base)
                prev_version="$val"
                ;;
            --version)
                version="$val"
                ;;
            --force)
                force="true"
                ;;
            --major)
                bump_type="major"
                ;;
            --minor)
                bump_type="minor"
                ;;
            --patch)
                bump_type="patch"
                ;;
            -verbose|-debug)
                VERBOSE=1
                ;;
            --preserve-summary)
                preserve_summary="true"
                ;;
            --remove-summary)
                remove_summary="true"
                ;;
            --allow-unclean)
                allow_unclean="true"
                ;;
        esac
    done

    # Check for uncommitted changes in scripts/release/
    if [[ -n $(git status --porcelain scripts/release/) ]]; then
        if [[ "$dry_run" == "true" && "$allow_unclean" == "true" ]]; then
            print_warning "Uncommitted changes detected in scripts/release/, but --allow-unclean is set and this is a dry run. Proceeding anyway."
        else
            print_error "Uncommitted changes detected in scripts/release/. Please commit all changes in the release tree before running a release."
            exit 1
        fi
    fi
    # Check for uncommitted changes in .github/workflows
    if [[ -n $(git status --porcelain .github/workflows/) ]]; then
        if [[ "$dry_run" == "true" && "$allow_unclean" == "true" ]]; then
            print_warning "Uncommitted changes detected in .github/workflows/, but --allow-unclean is set and this is a dry run. Proceeding anyway."
        else
            print_error "Uncommitted changes detected in .github/workflows/. Please commit all changes in the workflow tree before running a release."
            exit 1
        fi
    fi

    # --- Major changes summary file check (existence only) ---
    local base_version=""
    local summary_file=""
    local new_summary_file=""
    local should_rename=false
    if [[ -n "$prev_version" ]]; then
        base_version="$prev_version"
        summary_file="docs/release/latest-major-changes-since-${base_version}.md"
        # new_summary_file will be set after version bump
        if [[ ! -f "$summary_file" ]]; then
            print_error "No major changes summary file found for base $base_version"
            print_error "AI must create docs/release/latest-major-changes-since-${base_version}.md before any release or dry run"
            print_error "This file must contain a summary of major changes since version $base_version"
            exit 1
        fi
        print_success "Found required summary file: $summary_file"
    fi
    # --- End major changes summary file check ---

    check_prerequisites

    local current_version=$(get_current_version)
    print_status "Starting release process for version: $current_version"
    
    # Step 1: Bump version
    print_status "Step 1: Bumping version..."
    bump_args=(--$bump_type --push --force)
    if [[ "$dry_run" == "true" ]]; then
        bump_args+=(--dry-run)
    fi
    bump_output=$(./scripts/release/bump-version.zsh "${bump_args[@]}" 2>&1)
    echo "$bump_output"
    if [[ $? -ne 0 ]]; then
        print_error "Version bump failed"
        exit 1
    fi

    # Parse intended new version from bump-version output
    intended_new_version=$(echo "$bump_output" | grep -Eo 'Auto-incrementing to: [0-9]+\.[0-9]+\.[0-9]+' | awk '{print $4}' | tail -n1)
    if [[ -z "$intended_new_version" ]]; then
        intended_new_version=$(get_current_version)
        print_warning "Could not parse intended new version, falling back to current version: $intended_new_version"
    fi
    print_success "Intended new version: $intended_new_version"

    # Set new_summary_file for later use
    if [[ -n "$base_version" ]]; then
        new_summary_file="docs/release/${intended_new_version}-major-changes-since-${base_version}.md"
    fi

    # Commit and push the latest summary file before triggering the release workflow
    if [[ -n "$base_version" ]]; then
        local summary_file="docs/release/latest-major-changes-since-${base_version}.md"
        if [[ -f "$summary_file" ]]; then
            if [[ -n $(git status --porcelain "$summary_file") ]]; then
                print_status "Committing and pushing updated summary file: $summary_file"
                git add "$summary_file"
                git commit -m "docs(release): update latest major changes summary for release (refs #68)"
                git push
                print_success "Summary file committed and pushed"
            else
                print_status "Summary file $summary_file is already up to date in git"
            fi
        fi
    fi

    # Step 2: Trigger release workflow
    print_status "Step 2: Triggering release workflow..."
    release_args=(--force)
    if [[ "$dry_run" == "true" ]]; then
        release_args+=(--dry-run)
    fi
    if [[ -n "$prev_version" ]]; then
        release_args+=(--prev "$prev_version")
    fi
    if [[ -n "$version" ]]; then
        release_args+=(--version "$version")
    fi
    release_output=$(./scripts/release/release.zsh "${release_args[@]}" 2>&1)
    echo "$release_output"
    if [[ $? -ne 0 ]]; then
        print_error "Release workflow trigger failed"
        exit 1
    fi
    print_success "Release workflow triggered successfully"
    
    # Step 3: Monitor the release
    print_status "Step 3: Monitoring release process..."
    print_status "Monitoring workflow for version: $intended_new_version"
    ./scripts/release/monitor-release.zsh "$intended_new_version"
    if [[ $? -ne 0 ]]; then
        print_error "Release monitoring failed"
        exit 1
    fi
    print_success "Release process completed!"
    echo ""
    print_status "Release Summary:"
    echo "  Version: $intended_new_version"
    echo "  Status: Completed"
    echo "  Monitor: Finished"
    echo ""
    print_status "You can view the release at: https://github.com/fxstein/GoProX/releases"

    # Fetch and display the latest release notes artifact
    print_status "Fetching release notes artifact for version: $intended_new_version..."
    # Wait for the workflow to complete (polling for completion)
    run_id=""
    for i in {1..30}; do
        run_id=$(gh run list --workflow release-automation.yml --json databaseId,headBranch,status,createdAt --limit 1 --jq '.[0] | select(.headBranch=="main") | .databaseId')
        if [[ -n "$run_id" ]]; then
            wf_status=$(gh run view "$run_id" --json status,conclusion --jq '.status')
            if [[ "$wf_status" == "completed" ]]; then
                break
            fi
        fi
        sleep 10
    done
    if [[ -z "$run_id" ]]; then
        print_error "Could not find a recent workflow run."
        exit 1
    fi
    print_success "Workflow run $run_id completed. Downloading release notes artifact..."

    # Download the release-notes artifact
    tmpdir=$(mktemp -d)
    gh run download "$run_id" --name release-notes --dir "$tmpdir" --repo fxstein/GoProX
    if [[ $? -ne 0 ]]; then
        print_error "Failed to download release notes artifact."
        exit 1
    fi
    # Find the release_notes.md file
    notes_file=$(find "$tmpdir" -name 'release_notes.md' | head -n 1)
    if [[ ! -f "$notes_file" ]]; then
        print_error "release_notes.md not found in artifact."
        exit 1
    fi
    # Prepare output filename
    mkdir -p output
    if [[ "$dry_run" == "true" ]]; then
        out_file="output/release-notes-${intended_new_version}-dry-run.md"
    else
        out_file="output/release-notes-${intended_new_version}.md"
    fi
    cp "$notes_file" "$out_file"
    print_success "Release notes saved to $out_file"
    echo
    print_status "==== RELEASE NOTES ===="
    cat "$out_file"
    print_status "==== END OF RELEASE NOTES ===="
    # Clean up
    rm -rf "$tmpdir"

    # --- Major changes summary file handling (only after successful release) ---
    if [[ -n "$base_version" && -f "$summary_file" ]]; then
        # Determine whether to rename the summary file based on flags and run type
        should_rename=false
        # Default behavior: dry-runs preserve, real releases rename
        if [[ "$dry_run" == "true" ]]; then
            should_rename=false  # Default: preserve for dry-runs
        else
            should_rename=true   # Default: rename for real releases
        fi
        # Override with explicit flags
        if [[ "$preserve_summary" == "true" ]]; then
            should_rename=false
            print_status "Forcing summary file preservation (--preserve-summary)"
        fi
        if [[ "$remove_summary" == "true" ]]; then
            should_rename=true
            print_status "Forcing summary file rename (--remove-summary)"
        fi
        # Handle conflicting flags
        if [[ "$preserve_summary" == "true" && "$remove_summary" == "true" ]]; then
            print_error "Conflicting flags: --preserve-summary and --remove-summary cannot be used together"
            exit 1
        fi
        if [[ "$should_rename" == "true" ]]; then
            # Always remove the target file if it exists to ensure clean rename
            if [[ -f "$new_summary_file" ]]; then
                print_warning "$new_summary_file already exists. Removing existing file."
                rm -f "$new_summary_file"
                if [[ -f "$new_summary_file" ]]; then
                    print_error "Failed to remove existing file: $new_summary_file"
                    exit 1
                fi
            fi
            print_status "Renaming $summary_file to $new_summary_file"
            # Perform the rename operation with explicit error checking
            if mv "$summary_file" "$new_summary_file" 2>/dev/null; then
                # Verify the rename actually succeeded
                if [[ -f "$new_summary_file" && ! -f "$summary_file" ]]; then
                    print_success "Successfully renamed summary file"
                    # Handle git operations with better error handling
                    if git add "$new_summary_file" 2>/dev/null; then
                        print_status "Added new summary file to git"
                    else
                        print_warning "Failed to add new summary file to git (may already be tracked)"
                    fi
                    # Remove old file from git if it exists
                    if git rm "$summary_file" 2>/dev/null; then
                        print_status "Removed old summary file from git"
                    else
                        print_warning "Old summary file not in git (already removed or never tracked)"
                    fi
                    # Commit the changes
                    if git commit -m "docs(release): rename major changes summary for release $intended_new_version (refs #68)" 2>/dev/null; then
                        print_status "Committed summary file rename"
                        # Push the changes
                        if git push 2>/dev/null; then
                            print_success "Pushed summary file changes"
                        else
                            print_warning "Failed to push summary file changes (may already be up to date)"
                        fi
                    else
                        print_warning "Failed to commit summary file rename (no changes to commit)"
                    fi
                    print_success "Committed and pushed $new_summary_file"
                else
                    print_error "Rename operation appeared to succeed but file verification failed"
                    print_error "Expected: $new_summary_file to exist and $summary_file to not exist"
                    exit 1
                fi
            else
                print_error "Failed to rename summary file from $summary_file to $new_summary_file"
                print_error "This may be due to file system permissions or the target file being locked"
                exit 1
            fi
        else
            # Preserve the summary file
            print_status "Preserving summary file: $summary_file"
            print_success "Summary file will remain available for future runs"
        fi
    fi
    # --- End major changes summary file handling ---
}

main "$@" 