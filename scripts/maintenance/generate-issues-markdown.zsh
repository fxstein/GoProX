#!/bin/zsh
#
# generate-issues-markdown.zsh: Generate a Markdown file listing all GitHub issues for the current repo, grouped by open/closed.
#
# Usage: ./scripts/maintenance/generate-issues-markdown.zsh
#
# Output: output/github_issues.md

set -e

OUTPUT="output/github_issues.md"
REPO="fxstein/GoProX"

mkdir -p output

echo "# GitHub Issues for $REPO" > "$OUTPUT"
echo "" >> "$OUTPUT"

# Open Issues
echo "## Open Issues" >> "$OUTPUT"
gh issue list --state open --limit 100 --repo "$REPO" --json number,title --jq '.[] | "- [#" + (.number|tostring) + "](https://github.com/'"$REPO"'/issues/" + (.number|tostring) + "): " + .title' >> "$OUTPUT"
echo "" >> "$OUTPUT"

# Closed Issues
echo "## Closed Issues" >> "$OUTPUT"
gh issue list --state closed --limit 100 --repo "$REPO" --json number,title --jq '.[] | "- [#" + (.number|tostring) + "](https://github.com/'"$REPO"'/issues/" + (.number|tostring) + "): " + .title' >> "$OUTPUT"
echo "" >> "$OUTPUT"

echo "Markdown file generated at $OUTPUT" 