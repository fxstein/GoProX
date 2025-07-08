#!/bin/zsh

# GoProX Hook Health Check
# Independent verification of hook system health
# Run this script to verify hooks are working correctly

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🏥 GoProX Hook Health Check${NC}"
echo "================================"
echo ""

# Health check counters
checks_passed=0
checks_failed=0
warnings=0

# Function to run a health check
run_check() {
    local check_name="$1"
    local check_command="$2"
    local severity="${3:-error}" # error, warning, or info
    
    echo -n "🔍 $check_name... "
    
    if eval "$check_command" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ HEALTHY${NC}"
        ((checks_passed++))
    else
        if [[ "$severity" == "error" ]]; then
            echo -e "${RED}❌ FAILED${NC}"
            ((checks_failed++))
        elif [[ "$severity" == "warning" ]]; then
            echo -e "${YELLOW}⚠️  WARNING${NC}"
            ((warnings++))
        else
            echo -e "${BLUE}ℹ️  INFO${NC}"
        fi
    fi
}

echo -e "${BLUE}📋 Configuration Health${NC}"
echo "---------------------------"

# Check 1: core.hooksPath configuration
run_check \
    "Git hooks path configured" \
    "git config --local core.hooksPath | grep -q '^\.githooks$'" \
    "error"

# Check 2: .githooks directory exists
run_check \
    ".githooks directory exists" \
    "test -d .githooks" \
    "error"

echo ""
echo -e "${BLUE}📋 Hook File Health${NC}"
echo "----------------------"

# Check 3-7: All required hooks exist and are executable
for hook in commit-msg pre-commit post-commit post-checkout post-merge; do
    run_check \
        "$hook hook exists" \
        "test -f .githooks/$hook" \
        "error"
    
    run_check \
        "$hook hook executable" \
        "test -x .githooks/$hook" \
        "error"
done

echo ""
echo -e "${BLUE}📋 Hook Functionality Health${NC}"
echo "-------------------------------"

# Check 8: Commit message validation (test with valid message)
run_check \
    "Commit message validation (valid)" \
    "echo 'test: valid commit message (refs #73)' | .githooks/commit-msg /dev/stdin" \
    "error"

# Check 9: Commit message validation (test with invalid message)
run_check \
    "Commit message validation (invalid rejected)" \
    "! echo 'test: invalid commit message' | .githooks/commit-msg /dev/stdin" \
    "error"

# Check 10: Pre-commit hook runs without error
run_check \
    "Pre-commit hook execution" \
    ".githooks/pre-commit" \
    "error"

echo ""
echo -e "${BLUE}📋 Auto-Configuration Health${NC}"
echo "--------------------------------"

# Check 11: Auto-configuration works (non-destructive test)
echo -n "🔍 Auto-configuration test... "
# Save current hooksPath
current_hooks_path=$(git config --local core.hooksPath 2>/dev/null || echo "")
# Temporarily unset hooksPath
git config --local --unset core.hooksPath 2>/dev/null || true
# Run post-merge hook
if .githooks/post-merge >/dev/null 2>&1; then
    # Check if hooksPath was set
    if git config --local core.hooksPath | grep -q '^\.githooks$'; then
        echo -e "${GREEN}✅ HEALTHY${NC}"
        ((checks_passed++))
    else
        echo -e "${RED}❌ FAILED${NC}"
        ((checks_failed++))
    fi
else
    echo -e "${RED}❌ FAILED${NC}"
    ((checks_failed++))
fi
# Restore original hooksPath if it was different
if [[ -n "$current_hooks_path" ]]; then
    git config --local core.hooksPath "$current_hooks_path" >/dev/null 2>&1
fi

echo ""
echo -e "${BLUE}📋 Dependencies Health${NC}"
echo "-------------------------"

# Check 12: yamllint availability (optional)
run_check \
    "yamllint available for YAML linting" \
    "command -v yamllint" \
    "warning"

# Check 13: Git version compatibility
echo -n "🔍 Git version compatibility... "
git_version=$(git --version | cut -d' ' -f3)
if [[ "$git_version" =~ ^[2-9]\.[0-9]+\.[0-9]+ ]]; then
    echo -e "${GREEN}✅ HEALTHY${NC} (Git $git_version)"
    ((checks_passed++))
else
    echo -e "${YELLOW}⚠️  WARNING${NC} (Git $git_version - consider upgrading)"
    ((warnings++))
fi

echo ""
echo -e "${BLUE}📋 Health Summary${NC}"
echo "=================="

if [[ $checks_failed -eq 0 ]]; then
    echo -e "${GREEN}🎉 Hook system is HEALTHY!${NC}"
    echo "   • $checks_passed checks passed"
    if [[ $warnings -gt 0 ]]; then
        echo -e "   • ${YELLOW}$warnings warnings${NC} (non-critical)"
    fi
    echo ""
    echo -e "${GREEN}✅ All critical checks passed${NC}"
    echo "   • Configuration is correct"
    echo "   • All hooks are present and executable"
    echo "   • Validation is working"
    echo "   • Auto-configuration is functional"
    echo ""
    echo -e "${BLUE}💡 Recommendations:${NC}"
    if [[ $warnings -gt 0 ]]; then
        echo "   • Consider installing yamllint for YAML linting"
        echo "   • Consider upgrading Git if version is old"
    fi
    echo "   • Run this check periodically to ensure health"
    echo "   • Run after major changes to hook system"
    exit 0
else
    echo -e "${RED}❌ Hook system has ISSUES!${NC}"
    echo "   • $checks_passed checks passed"
    echo -e "   • ${RED}$checks_failed checks failed${NC}"
    if [[ $warnings -gt 0 ]]; then
        echo -e "   • ${YELLOW}$warnings warnings${NC}"
    fi
    echo ""
    echo -e "${RED}🚨 Critical issues detected${NC}"
    echo "   • Please fix failed checks before committing"
    echo "   • Run: ./scripts/maintenance/setup-hooks.zsh to repair"
    echo "   • Check the hook system documentation"
    exit 1
fi 