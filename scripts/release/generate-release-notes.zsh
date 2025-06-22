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
    output_file        Optional output file (default: release_notes.md)

Examples:
    $SCRIPT_NAME 00.61.00 00.60.00
    $SCRIPT_NAME 00.61.00 00.60.00 my_release_notes.md

This script generates release notes that summarize commits by issue:
- Commits with issue references are grouped under issue headers with issue numbers and names
- Commits without issue references are grouped under "Others"
- Uses GitHub API to fetch issue titles when available
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
    if [[ -n "$title" ]]; then
        echo "Issue #$issue_number: $title"
    else
        echo "Issue #$issue_number"
    fi
}

# Function to extract issue numbers from commit message
extract_issue_numbers() {
    local commit_msg="$1"
    # Extract issue numbers from various formats: #123, (refs #123), (refs #123 #456)
    echo "$commit_msg" | grep -o '#[0-9]*' | sort -u | tr '\n' ' '
}

# Function to generate AI summary of addressed issues
generate_ai_summary() {
    local issue_numbers=$1
    local output_file=$2
    
    print_status "Generating AI summary for issues: $issue_numbers"
    
    # Check if AI summary script exists
    if [[ ! -f "scripts/release/generate-ai-summary.zsh" ]]; then
        print_warning "AI summary script not found, skipping AI summary"
        return 1
    fi
    
    # Make sure the script is executable
    chmod +x scripts/release/generate-ai-summary.zsh
    
    # Generate AI summary
    if ./scripts/release/generate-ai-summary.zsh "$issue_numbers" "$output_file"; then
        print_success "AI summary generated successfully"
        return 0
    else
        print_warning "Failed to generate AI summary, continuing without it"
        return 1
    fi
}

# Function to generate release notes
generate_release_notes() {
    local current_version=$1
    local previous_version=$2
    local output_file=$3
    
    print_status "Generating release notes from v${previous_version} to v${current_version}"
    
    # Get commits since last release
    local commit_range="v${previous_version}..HEAD"
    if ! git rev-parse "v${previous_version}" &>/dev/null; then
        print_warning "Previous version tag v${previous_version} not found, using all commits"
        commit_range="HEAD"
    fi
    
    # Get all commits in the range
    local commits=$(git log --oneline --no-merges "$commit_range" 2>/dev/null || git log --oneline --no-merges --all | head -20)
    
    if [[ -z "$commits" ]]; then
        print_warning "No commits found in range $commit_range"
        commits="No commits found"
    fi
    
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
            for issue_num in $issue_numbers; do
                # Remove # prefix for processing and clean up
                local clean_issue_num=${issue_num#\#}
                clean_issue_num=$(echo "$clean_issue_num" | tr -d ' ')
                
                # Only process if it's a valid number
                if [[ "$clean_issue_num" =~ ^[0-9]+$ ]]; then
                    issue_commits["$clean_issue_num"]+="$commit"$'\n'
                    
                    # Get issue title if not already cached
                    if [[ -z "${issue_titles[$clean_issue_num]}" ]]; then
                        issue_titles["$clean_issue_num"]=$(get_issue_title "$clean_issue_num")
                    fi
                fi
            done
        else
            # Commit has no issue references
            other_commits+=("$commit")
        fi
    done <<< "$commits"
    
    # Collect all unique issue numbers for AI summary
    local all_issue_numbers=""
    for issue_num in ${(k)issue_commits}; do
        if [[ "$issue_num" =~ ^[0-9]+$ ]]; then
            all_issue_numbers+="$issue_num "
        fi
    done
    all_issue_numbers=$(echo "$all_issue_numbers" | xargs)
    
    # Generate AI summary if we have issues
    local ai_summary_file=""
    if [[ -n "$all_issue_numbers" ]]; then
        ai_summary_file=$(mktemp)
        if generate_ai_summary "$all_issue_numbers" "$ai_summary_file"; then
            print_status "AI summary will be included in release notes"
        else
            ai_summary_file=""
        fi
    fi
    
    # Generate the release notes content
    print_status "Generating release notes content..."
    
    cat > "$output_file" << EOF
# GoProX v${current_version}

## Changes since v${previous_version}

EOF
    
    # Add AI summary if available
    if [[ -n "$ai_summary_file" && -f "$ai_summary_file" ]]; then
        echo "" >> "$output_file"
        cat "$ai_summary_file" >> "$output_file"
        echo "" >> "$output_file"
        rm -f "$ai_summary_file"
    fi
    
    # Add issue-based sections
    if [[ ${#issue_commits[@]} -gt 0 ]]; then
        echo "## Issues Addressed" >> "$output_file"
        echo "" >> "$output_file"
        
        # Sort issues by number - use zsh-compatible approach
        local sorted_issues=($(for k in ${(k)issue_commits}; do echo "$k"; done | sort -n))
        
        for issue_num in $sorted_issues; do
            local title="${issue_titles[$issue_num]}"
            echo "### $title" >> "$output_file"
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
    
    # Add other commits section
    if [[ ${#other_commits[@]} -gt 0 ]]; then
        echo "## Others" >> "$output_file"
        echo "" >> "$output_file"
        
        for commit in "${other_commits[@]}"; do
            echo "- $commit" >> "$output_file"
        done
        echo "" >> "$output_file"
    fi
    
    # Add installation and SHA256 sections
    cat >> "$output_file" << EOF
## Installation

\`\`\`bash
brew install fxstein/tap/goprox
\`\`\`

## SHA256

\`\`\`
TBD - Will be calculated during release
\`\`\`
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
    local output_file="${3:-release_notes.md}"
    
    # Validate versions
    validate_version "$current_version"
    validate_version "$previous_version"
    
    # Check prerequisites
    check_prerequisites
    
    # Generate release notes
    generate_release_notes "$current_version" "$previous_version" "$output_file"
}

# Run main function with all arguments
main "$@" 