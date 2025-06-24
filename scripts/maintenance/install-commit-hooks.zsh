#!/bin/zsh

#
# install-commit-hooks.zsh: Install Git commit hooks for GoProX development
#
# Copyright (c) 2021-2025 by Oliver Ratzesberger
#
# This script installs the necessary Git hooks to ensure code quality
# and consistency in the GoProX project.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "Installing GoProX Git commit hooks..."

# Check if we're in a git repository
if [[ ! -d ".git" ]]; then
    echo "${RED}Error: Not in a git repository${NC}"
    echo "Please run this script from the root of the GoProX repository."
    exit 1
fi

# Create hooks directory if it doesn't exist
mkdir -p .git/hooks

# Install commit-msg hook
if [[ -f ".git/hooks/commit-msg" ]]; then
    echo "${YELLOW}Backing up existing commit-msg hook...${NC}"
    mv .git/hooks/commit-msg .git/hooks/commit-msg.backup.$(date +%s)
fi

# Create the commit-msg hook
cat > .git/hooks/commit-msg << 'EOF'
#!/bin/zsh

# GoProX Pre-commit Hook
# Ensures all commits reference GitHub issues

# Get the commit message from the commit-msg file
commit_msg_file="$1"
commit_msg=$(cat "$commit_msg_file")

# Check if this is a merge commit or revert (allow without issue reference)
if [[ "$commit_msg" =~ ^(Merge|Revert|Reverted) ]]; then
    echo "Merge/revert commit detected, skipping issue reference check"
    exit 0
fi

# Check if commit message contains GitHub issue reference
# Pattern: (refs #n) or (refs #n #n ...) where n is a number
if [[ "$commit_msg" =~ \(refs\ #[0-9]+(\ #[0-9]+)*\) ]]; then
    echo "✅ Commit message contains GitHub issue reference"
    exit 0
else
    echo "❌ ERROR: Commit message must reference a GitHub issue"
    echo ""
    echo "Please include a GitHub issue reference in your commit message:"
    echo "  (refs #123) for a single issue"
    echo "  (refs #123 #456) for multiple issues"
    echo ""
    echo "Examples:"
    echo "  feat: add new configuration option (refs #70)"
    echo "  fix: resolve parameter parsing issue (refs #45 #67)"
    echo ""
    echo "Current commit message:"
    echo "---"
    echo "$commit_msg"
    echo "---"
    echo ""
    echo "Please amend your commit with a proper issue reference."
    exit 1
fi
EOF

# Make the hook executable
chmod +x .git/hooks/commit-msg

echo "${GREEN}✅ Git commit hooks installed successfully!${NC}"
echo ""
echo "The commit-msg hook will now ensure that all commits reference GitHub issues."
echo "Format: (refs #123) or (refs #123 #456) for multiple issues"
echo ""
echo "Merge commits and reverts are automatically allowed without issue references." 