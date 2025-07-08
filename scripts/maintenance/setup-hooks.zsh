#!/bin/zsh

# GoProX Git Hooks Auto-Setup Script
# This script configures Git hooks for the GoProX repository
# 
# NOTE: Hooks are automatically configured on clone/merge via .githooks/post-checkout
# and .githooks/post-merge hooks. This script is only needed for manual setup.

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 GoProX Git Hooks Setup${NC}"
echo "=============================="

# Check if we're in a Git repository
if [[ ! -d ".git" ]]; then
    echo -e "${YELLOW}⚠️  Not in a Git repository. Skipping hooks setup.${NC}"
    exit 0
fi

# Check if .githooks directory exists
if [[ ! -d ".githooks" ]]; then
    echo -e "${YELLOW}⚠️  .githooks directory not found. This should not happen in a proper GoProX repository.${NC}"
    exit 1
fi

# Check if hooks are already configured
current_hooks_path=$(git config --local core.hooksPath 2>/dev/null || echo "")
if [[ "$current_hooks_path" == ".githooks" ]]; then
    echo -e "${GREEN}✅ Git hooks already configured to use .githooks${NC}"
    echo ""
    echo "Hooks are active and will enforce:"
    echo "  • Commit messages must reference GitHub issues (refs #123)"
    echo "  • Pre-commit checks will run before each commit"
    echo "  • YAML files will be linted (if yamllint is installed)"
    echo "  • Logger usage will be checked in zsh scripts"
    echo "  • TODO/FIXME comments will be flagged"
    echo "  • Large files (>10MB) will be flagged"
    echo ""
    echo "Optional: Install yamllint for YAML linting:"
    echo "  brew install yamllint"
    echo "  or: pip3 install yamllint"
    exit 0
else
    echo -e "${BLUE}🔧 Configuring Git to use .githooks directory...${NC}"
    git config --local core.hooksPath .githooks
    echo -e "${GREEN}✅ Git hooks configured successfully!${NC}"
    echo ""
    echo "Hooks are now active and will enforce:"
    echo "  • Commit messages must reference GitHub issues (refs #123)"
    echo "  • Pre-commit checks will run before each commit"
    echo "  • YAML files will be linted (if yamllint is installed)"
    echo "  • Logger usage will be checked in zsh scripts"
    echo "  • TODO/FIXME comments will be flagged"
    echo "  • Large files (>10MB) will be flagged"
    echo ""
    echo "Optional: Install yamllint for YAML linting:"
    echo "  brew install yamllint"
    echo "  or: pip3 install yamllint"
fi

echo ""
echo -e "${GREEN}🎉 Git hooks setup completed!${NC}"
echo ""
echo "Note: For new clones, hooks are automatically configured via .githooks/post-checkout"
echo "This script is only needed for manual setup or troubleshooting." 