#!/bin/zsh
#
# full-release.zsh: Complete automated release process for GoProX
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

set -e

# Remove color codes for Cursor IDE compatibility
print_status() {
    echo "[INFO] $1"
}

print_success() {
    echo "[SUCCESS] $1"
}

print_warning() {
    echo "[WARNING] $1"
}

print_error() {
    echo "[ERROR] $1"
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0

This script performs the complete GoProX release process:
1. Bump version with --auto --push --force
2. Trigger release workflow
3. Monitor the release process

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
    
    # Argument parsing
    dry_run="false"
    prev_version=""
    version=""
    force="false"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                dry_run="true"
                shift
                ;;
            --prev|-p)
                prev_version="$2"
                shift 2
                ;;
            --version|-v)
                version="$2"
                shift 2
                ;;
            --force|-f)
                force="true"
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_warning "Unknown argument: $1"
                shift
                ;;
        esac
    done

    # Check for uncommitted changes in scripts/release/
    if [[ -n $(git status --porcelain scripts/release/) ]]; then
        print_error "Uncommitted changes detected in scripts/release/. Please commit all changes in the release tree before running a release."
        exit 1
    fi

    check_prerequisites

    local current_version=$(get_current_version)
    print_status "Starting release process for version: $current_version"
    
    # Step 1: Bump version
    print_status "Step 1: Bumping version..."
    bump_args=(--auto --push --force)
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

    # --- Major changes summary file handling ---
    if [[ -n "$prev_version" ]]; then
        local base_version="$prev_version"
        local summary_file="docs/release/latest-major-changes-since-${base_version}.md"
        local new_summary_file="docs/release/${intended_new_version}-major-changes-since-${base_version}.md"
        if [[ -f "$summary_file" ]]; then
            if [[ -f "$new_summary_file" ]]; then
                print_warning "$new_summary_file already exists. Overwriting with latest summary."
                rm -f "$new_summary_file"
            fi
            print_status "Renaming $summary_file to $new_summary_file"
            mv "$summary_file" "$new_summary_file"
            git add "$new_summary_file"
            git rm "$summary_file" 2>/dev/null || true
            git commit -m "docs(release): rename major changes summary for release $intended_new_version (refs #68)"
            git push
            print_success "Committed and pushed $new_summary_file"
        else
            if [[ "$dry_run" == "true" ]]; then
                print_warning "No major changes summary file found for base $base_version (dry run). Please create docs/release/latest-major-changes-since-${base_version}.md before running the release."
            else
                print_error "No major changes summary file found for base $base_version (real release). AI must create docs/release/latest-major-changes-since-${base_version}.md before resubmitting the release job."
                exit 1
            fi
        fi
    fi
    # --- End major changes summary file handling ---
    
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
}

main "$@" 