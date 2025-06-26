#!/bin/zsh
#
# generate-issues-markdown.zsh: Generate a Markdown file listing all GitHub issues for the current repo, grouped by open/closed.
#
# Usage: ./scripts/maintenance/generate-issues-markdown.zsh
#
# Output: output/github_issues.md

set -e

# Setup logging
export LOGFILE="output/issues-markdown.log"
mkdir -p "$(dirname "$LOGFILE")"
source "$(dirname $0)/../core/logger.zsh"

log_time_start

OUTPUT="output/github_issues.md"
REPO="fxstein/GoProX"

mkdir -p output

log_info "Generating GitHub issues markdown for $REPO"

echo "# GitHub Issues for $REPO" > "$OUTPUT"
echo "" >> "$OUTPUT"

# Open Issues
log_info "Processing open issues"
echo "## Open Issues" >> "$OUTPUT"
gh issue list --state open --limit 100 --repo "$REPO" --json number,title --jq '.[] | "- [#" + (.number|tostring) + "](https://github.com/'"$REPO"'/issues/" + (.number|tostring) + "): " + .title' >> "$OUTPUT"
echo "" >> "$OUTPUT"

# Closed Issues
log_info "Processing closed issues"
echo "## Closed Issues" >> "$OUTPUT"
gh issue list --state closed --limit 100 --repo "$REPO" --json number,title --jq '.[] | "- [#" + (.number|tostring) + "](https://github.com/'"$REPO"'/issues/" + (.number|tostring) + "): " + .title' >> "$OUTPUT"
echo "" >> "$OUTPUT"

log_success "Markdown file generated at $OUTPUT"
log_time_end 