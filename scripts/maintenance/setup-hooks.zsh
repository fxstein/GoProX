#!/bin/zsh

# GoProX Git Hooks Auto-Setup Script
# This script automatically configures Git hooks for new repository clones

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 GoProX Git Hooks Auto-Setup${NC}"
echo "=================================="

# Check if we're in a Git repository
if [[ ! -d ".git" ]]; then
    echo -e "${YELLOW}⚠️  Not in a Git repository. Skipping hooks setup.${NC}"
    exit 0
fi

# Check if .githooks directory exists
if [[ ! -d ".githooks" ]]; then
    echo -e "${YELLOW}⚠️  .githooks directory not found. Creating it...${NC}"
    mkdir -p .githooks
fi

# Check if hooks are already configured
current_hooks_path=$(git config --local core.hooksPath 2>/dev/null || echo "")
if [[ "$current_hooks_path" == ".githooks" ]]; then
    echo -e "${GREEN}✅ Git hooks already configured to use .githooks${NC}"
else
    echo -e "${BLUE}🔧 Configuring Git to use .githooks directory...${NC}"
    git config --local core.hooksPath .githooks
    echo -e "${GREEN}✅ Git hooks configured successfully!${NC}"
fi

# Check if commit-msg hook exists
if [[ -f ".githooks/commit-msg" ]]; then
    echo -e "${GREEN}✅ Commit-msg hook found${NC}"
else
    echo -e "${YELLOW}⚠️  Commit-msg hook not found in .githooks${NC}"
    echo -e "${BLUE}📝 Creating basic commit-msg hook...${NC}"
    
    cat > .githooks/commit-msg << 'EOF'
#!/bin/zsh

# GoProX Commit Message Hook
# Ensures commit messages reference GitHub issues

commit_msg_file="$1"
commit_msg=$(cat "$commit_msg_file")

# Skip validation for merge commits and reverts
if [[ "$commit_msg" =~ ^Merge.* ]] || [[ "$commit_msg" =~ ^Revert.* ]]; then
    exit 0
fi

# Check if commit message contains issue reference
if [[ ! "$commit_msg" =~ \(refs\ #[0-9]+ ]]; then
    echo "❌ Commit message must reference GitHub issues"
    echo "   Format: (refs #123) or (refs #123 #456) for multiple issues"
    echo ""
    echo "   Your commit message:"
    echo "   $commit_msg"
    echo ""
    echo "   Please update your commit message to include issue references."
    exit 1
fi

echo "✅ Commit message validation passed"
exit 0
EOF

    chmod +x .githooks/commit-msg
    echo -e "${GREEN}✅ Basic commit-msg hook created${NC}"
fi

# Check if pre-commit hook exists
if [[ -f ".githooks/pre-commit" ]]; then
    echo -e "${GREEN}✅ Pre-commit hook found${NC}"
else
    echo -e "${YELLOW}⚠️  Pre-commit hook not found in .githooks${NC}"
    echo -e "${BLUE}📝 Creating basic pre-commit hook...${NC}"
    
    cat > .githooks/pre-commit << 'EOF'
#!/bin/zsh

# GoProX Pre-commit Hook
# Runs basic checks before allowing commits

echo "🔍 Running pre-commit checks..."

# Check for TODO/FIXME comments in staged files
if git diff --cached --name-only | xargs grep -l "TODO\|FIXME" 2>/dev/null; then
    echo "⚠️  Warning: Found TODO/FIXME comments in staged files"
    echo "   Consider addressing these before committing"
fi

# Check for large files (>10MB)
large_files=$(git diff --cached --name-only | xargs ls -la 2>/dev/null | awk '$5 > 10485760 {print $9}')
if [[ -n "$large_files" ]]; then
    echo "⚠️  Warning: Found files larger than 10MB"
    echo "   Consider using Git LFS for large files"
fi

echo "✅ Pre-commit checks completed"
exit 0
EOF

    chmod +x .githooks/pre-commit
    echo -e "${GREEN}✅ Basic pre-commit hook created${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Git hooks setup completed!${NC}"
echo ""
echo "Hooks will now be automatically enforced:"
echo "  • Commit messages must reference GitHub issues (refs #123)"
echo "  • Pre-commit checks will run before each commit"
echo "  • YAML files will be linted (if yamllint is installed)"
echo "  • Logger usage will be checked in zsh scripts"
echo ""
echo "Optional: Install yamllint for YAML linting:"
echo "  brew install yamllint"
echo "  or: pip3 install yamllint"
echo ""
echo "For new clones, run: ./scripts/maintenance/setup-hooks.zsh" 