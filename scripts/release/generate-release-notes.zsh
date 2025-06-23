#!/bin/zsh
#
# generate-release-notes.zsh: Generate release notes with issue-based summaries
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
# Usage: ./generate-release-notes.zsh <current_version> <previous_version> [output_file]
#
# This script generates release notes that summarize commits by issue:
# - Commits with issue references are grouped under issue headers with issue numbers and names
# - Commits without issue references are grouped under "Others"
# - Uses GitHub API to fetch issue titles when available

set -e

# At the top of the script, after set -e
SCRIPT_NAME="${0##*/}"

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
Usage: $SCRIPT_NAME <current_version> <previous_version> [output_file]

Arguments:
    current_version    The version being released (e.g., 00.61.00)
    previous_version   The previous version for changelog (e.g., 00.60.00)
    output_file        Optional output file (default: output/release_notes.md)

Examples:
    $SCRIPT_NAME 00.61.00 00.60.00
    $SCRIPT_NAME 00.61.00 00.60.00 output/my_release_notes.md

This script generates release notes that summarize commits by issue:
- Commits with issue references are grouped under issue headers with issue numbers and names
- Commits without issue references are grouped under "Others"
- Uses GitHub API to fetch issue titles when available
- Output files MUST be placed in the output/ directory
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
    
    # Check git history depth and configuration
    print_status "Git repository information:"
    echo "  Repository: $(git remote get-url origin 2>/dev/null || echo 'No remote')"
    echo "  Current branch: $(git branch --show-current)"
    echo "  Commit count: $(git rev-list --count HEAD 2>/dev/null || echo 'Unknown')"
    echo "  Latest tag: $(git describe --tags --abbrev=0 2>/dev/null || echo 'No tags')"
    
    # Check if gh CLI is available for GitHub API access
    if ! command -v gh &> /dev/null; then
        print_warning "GitHub CLI (gh) not found. Issue titles will not be fetched."
        print_warning "Install gh CLI for better release notes: https://cli.github.com/"
    fi
    
    print_success "Prerequisites check completed"
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

# Function to get issue title from GitHub API
get_issue_title() {
    local issue_number=$1
    local repo="fxstein/GoProX"
    
    if ! command -v gh &> /dev/null; then
        echo "Issue #$issue_number"
        return
    fi
    
    if ! gh auth status &> /dev/null; then
        echo "Issue #$issue_number"
        return
    fi
    
    # Try to get issue title from GitHub API
    local title=$(gh api "repos/$repo/issues/$issue_number" --jq '.title' 2>/dev/null || echo "")
    if [[ -n "$title" && "$title" != "null" && ! "$title" =~ "message.*Not Found" ]]; then
        echo "$title"
    else
        echo "Issue #$issue_number"
    fi
}

# Function to extract issue numbers from commit message
extract_issue_numbers() {
    local commit_msg="$1"
    # Extract issue numbers from various formats: #123, (refs #123), (refs #123 #456)
    # Return each number on a separate line to avoid concatenation
    echo "$commit_msg" | grep -o '#[0-9]*' | sed 's/#//' | sort -u
}

# Function to validate output file location
validate_output_location() {
    local output_file="$1"
    
    # Check if we're running in GitHub Actions
    if [[ -n "$GITHUB_WORKSPACE" ]]; then
        # In GitHub Actions, allow output to workspace root for artifacts
        print_status "Running in GitHub Actions - allowing workspace root output"
        return 0
    fi
    
    # For local development, ensure output file is in the output/ directory
    if [[ ! "$output_file" =~ ^output/ ]]; then
        print_error "Output file must be in the output/ directory"
        print_error "Current: $output_file"
        print_error "Expected: output/$(basename "$output_file")"
        exit 1
    fi
    
    # Ensure output directory exists
    mkdir -p "$(dirname "$output_file")"
}

# Function to generate release notes
generate_release_notes() {
    local current_version=$1
    local previous_version=$2
    local output_file=$3
    
    print_status "Generating release notes from v${previous_version} to v${current_version}"
    
    # Get commits since last release with better error handling
    local commit_range="v${previous_version}..HEAD"
    local commits=""
    
    # First, verify the previous version tag exists
    if ! git rev-parse "v${previous_version}" &>/dev/null; then
        print_error "Previous version tag v${previous_version} not found"
        print_error "Available tags:"
        git tag --list "v*" | head -10
        exit 1
    fi
    
    # Try to get commits in the range
    print_status "Getting commits in range: $commit_range"
    commits=$(git log --oneline --no-merges "$commit_range" 2>/dev/null)
    
    if [[ -z "$commits" ]]; then
        print_warning "No commits found in range $commit_range"
        print_status "Checking if we're on the correct branch..."
        
        # Check current branch and available branches
        local current_branch=$(git branch --show-current)
        print_status "Current branch: $current_branch"
        
        # Try to get commits from the current branch since the tag
        commits=$(git log --oneline --no-merges "v${previous_version}..$current_branch" 2>/dev/null)
        
        if [[ -z "$commits" ]]; then
            print_error "No commits found between v${previous_version} and current HEAD"
            print_error "This might indicate a shallow clone or missing history"
            print_error "Available commits since tag:"
            git log --oneline "v${previous_version}" | head -5
            exit 1
        fi
    fi
    
    print_success "Found $(echo "$commits" | wc -l | tr -d ' ') commits in range"
    
    # Parse commits and group by issues
    typeset -A issue_commits
    typeset -A issue_titles
    typeset -a other_commits
    
    print_status "Parsing commits and grouping by issues..."
    
    IFS=''
    while read -r commit; do
        if [[ -z "$commit" ]]; then
            continue
        fi
        
        local commit_hash=$(echo "$commit" | cut -d' ' -f1)
        local commit_msg=$(echo "$commit" | cut -d' ' -f2-)
        local issue_numbers=$(extract_issue_numbers "$commit_msg")
        
        if [[ -n "$issue_numbers" ]]; then
            # Commit has issue references
            while IFS= read -r issue_num; do
                if [[ -n "$issue_num" ]]; then
                    # Clean up the issue number
                    local clean_issue_num=$(echo "$issue_num" | tr -d ' ')
                    
                    # Only process if it's a valid number
                    if [[ "$clean_issue_num" =~ ^[0-9]+$ ]]; then
                        # Ensure clean key without quotes
                        local key="$clean_issue_num"
                        issue_commits[$key]+="$commit"$'\n'
                        
                        # Get issue title if not already cached
                        if [[ -z "${issue_titles[$key]}" ]]; then
                            issue_titles[$key]=$(get_issue_title "$clean_issue_num")
                        fi
                    fi
                fi
            done <<< "$issue_numbers"
        else
            # Commit has no issue references
            other_commits+=("$commit")
        fi
    done <<< "$commits"
    
    # Generate the release notes content
    print_status "Generating release notes content..."
    
    cat > "$output_file" << EOF
# GoProX v${current_version}

## Changes since v${previous_version}

EOF
    
    # Insert major changes summary if available
    local summary_file="docs/release/${current_version}-major-changes-since-${previous_version}.md"
    if [[ -f "$summary_file" ]]; then
        print_status "Inserting major changes summary from $summary_file"
        cat "$summary_file" >> "$output_file"
        echo "" >> "$output_file"
    fi
    
    # Add issue-based sections
    if [[ ${#issue_commits[@]} -gt 0 ]]; then
        echo "## Issues Addressed" >> "$output_file"
        echo "" >> "$output_file"
        
        # Sort issues by number in descending order
        local sorted_issues=(${(on)${(k)issue_commits}})
        sorted_issues=(${(Oa)sorted_issues})
        
        for issue_num in $sorted_issues; do
            local title="${issue_titles[$issue_num]}"
            
            # Format the header properly
            if [[ "$title" =~ ^Issue\ #[0-9]+$ ]]; then
                # Fallback format when no title was found
                local header="$title"
            else
                # Use the actual title from GitHub API
                local header="Issue #$issue_num: $title"
            fi
            
            echo "### $header" >> "$output_file"
            echo "" >> "$output_file"
            
            # Add commits for this issue - use zsh-compatible approach
            local commits_for_issue="${issue_commits[$issue_num]}"
            
            while IFS= read -r commit; do
                if [[ -n "$commit" ]]; then
                    echo "- $commit" >> "$output_file"
                fi
            done <<< "$commits_for_issue"
            echo "" >> "$output_file"
        done
    fi
    
    # Add other commits section after issues
    if [[ ${#other_commits[@]} -gt 0 ]]; then
        echo "## Other Commits" >> "$output_file"
        echo "" >> "$output_file"
        for commit in "${other_commits[@]}"; do
            if [[ -n "$commit" ]]; then
                echo "- $commit" >> "$output_file"
            fi
        done
        echo "" >> "$output_file"
    fi
    
    # Add improved installation section
    cat >> "$output_file" << 'EOF'
## Installation

The recommended way to install or update GoProX is via Homebrew:

```zsh
brew install fxstein/fxstein/goprox
```

Or, add the tap manually and then install:

```zsh
brew tap fxstein/fxstein
brew install goprox
```

To upgrade to the latest version:

```zsh
brew upgrade goprox
```

If you encounter issues, you can uninstall and reinstall:

```zsh
brew uninstall goprox
brew install goprox
```

> **Note:** Homebrew installs to `/opt/homebrew/bin/goprox` on Apple Silicon and `/usr/local/bin/goprox` on Intel Macs.

For configuration and advanced setup, see the project README or run:

```zsh
goprox --setup
```
EOF
    
    print_success "Release notes generated: $output_file"
    
    # Show summary
    local total_issues=${#issue_commits[@]}
    local total_others=${#other_commits[@]}
    
    echo ""
    print_status "Release Notes Summary:"
    echo "  Issues addressed: $total_issues"
    echo "  Other commits: $total_others"
    echo "  Output file: $output_file"
    echo ""
    
    # Show preview
    print_status "Release notes preview:"
    echo "----------------------------------------"
    head -20 "$output_file"
    if [[ $(wc -l < "$output_file") -gt 20 ]]; then
        echo "..."
        echo "----------------------------------------"
        tail -10 "$output_file"
    fi
    echo "----------------------------------------"
}

# Main script logic
main() {
    # Parse command line arguments
    if [[ $# -lt 2 ]]; then
        print_error "Missing required arguments"
        show_usage
        exit 1
    fi
    
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        show_usage
        exit 0
    fi
    
    local current_version="$1"
    local previous_version="$2"
    local output_file="${3:-output/release_notes.md}"
    
    # Validate versions
    validate_version "$current_version"
    validate_version "$previous_version"
    
    # Check prerequisites
    check_prerequisites
    
    # Validate output file location
    validate_output_location "$output_file"
    
    # Generate release notes
    generate_release_notes "$current_version" "$previous_version" "$output_file"
}

# Run main function with all arguments
main "$@" 