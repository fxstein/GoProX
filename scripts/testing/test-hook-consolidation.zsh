#!/bin/zsh

# GoProX Hook Consolidation Test Script
# Tests the consolidated hook system and verifies legacy hooks are removed

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 Testing GoProX Hook Consolidation${NC}"
echo "====================================="
echo ""

# Test counters
tests_passed=0
tests_failed=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"
    
    echo -n "Testing: $test_name... "
    
    if eval "$test_command" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((tests_passed++))
    else
        echo -e "${RED}❌ FAIL${NC}"
        echo "   Expected: $expected_result"
        ((tests_failed++))
    fi
}

# Function to run a test that should fail
run_test_fail() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"
    
    echo -n "Testing: $test_name... "
    
    if ! eval "$test_command" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((tests_passed++))
    else
        echo -e "${RED}❌ FAIL${NC}"
        echo "   Expected: $expected_result"
        ((tests_failed++))
    fi
}

echo -e "${BLUE}📋 Test 1: Legacy Hook Removal${NC}"
echo "--------------------------------"

# Test 1.1: Legacy setup script removed
run_test_fail \
    "Legacy setup script removed" \
    "test -f scripts/maintenance/install-commit-hooks.zsh" \
    "install-commit-hooks.zsh should not exist"

# Test 1.2: Legacy hooks removed from .git/hooks
run_test_fail \
    "Legacy commit-msg hook removed" \
    "test -f .git/hooks/commit-msg" \
    "commit-msg should not exist in .git/hooks"

run_test_fail \
    "Legacy post-checkout hook removed" \
    "test -f .git/hooks/post-checkout" \
    "post-checkout should not exist in .git/hooks"

run_test_fail \
    "Legacy post-merge hook removed" \
    "test -f .git/hooks/post-merge" \
    "post-merge should not exist in .git/hooks"

run_test_fail \
    "Legacy post-commit hook removed" \
    "test -f .git/hooks/post-commit" \
    "post-commit should not exist in .git/hooks"

echo ""
echo -e "${BLUE}📋 Test 2: New Hook System Configuration${NC}"
echo "--------------------------------------------"

# Test 2.1: .githooks directory exists
run_test \
    ".githooks directory exists" \
    "test -d .githooks" \
    ".githooks directory should exist"

# Test 2.2: core.hooksPath configured
run_test \
    "core.hooksPath configured" \
    "git config --local core.hooksPath | grep -q '^\.githooks$'" \
    "core.hooksPath should be set to .githooks"

# Test 2.3: All required hooks exist
run_test \
    "commit-msg hook exists" \
    "test -f .githooks/commit-msg" \
    "commit-msg hook should exist in .githooks"

run_test \
    "pre-commit hook exists" \
    "test -f .githooks/pre-commit" \
    "pre-commit hook should exist in .githooks"

run_test \
    "post-commit hook exists" \
    "test -f .githooks/post-commit" \
    "post-commit hook should exist in .githooks"

run_test \
    "post-checkout hook exists" \
    "test -f .githooks/post-checkout" \
    "post-checkout hook should exist in .githooks"

run_test \
    "post-merge hook exists" \
    "test -f .githooks/post-merge" \
    "post-merge hook should exist in .githooks"

# Test 2.4: All hooks are executable
run_test \
    "commit-msg hook executable" \
    "test -x .githooks/commit-msg" \
    "commit-msg hook should be executable"

run_test \
    "pre-commit hook executable" \
    "test -x .githooks/pre-commit" \
    "pre-commit hook should be executable"

run_test \
    "post-commit hook executable" \
    "test -x .githooks/post-commit" \
    "post-commit hook should be executable"

run_test \
    "post-checkout hook executable" \
    "test -x .githooks/post-checkout" \
    "post-checkout hook should be executable"

run_test \
    "post-merge hook executable" \
    "test -x .githooks/post-merge" \
    "post-merge hook should be executable"

echo ""
echo -e "${BLUE}📋 Test 3: Hook Functionality${NC}"
echo "----------------------------"

# Test 3.1: Commit message validation (should pass with valid message)
echo -n "Testing: Commit message validation (valid)... "
if echo "test: valid commit message (refs #73)" | .githooks/commit-msg /dev/stdin >/dev/null 2>&1; then
    echo -e "${GREEN}✅ PASS${NC}"
    ((tests_passed++))
else
    echo -e "${RED}❌ FAIL${NC}"
    ((tests_failed++))
fi

# Test 3.2: Commit message validation (should fail with invalid message)
echo -n "Testing: Commit message validation (invalid)... "
if ! echo "test: invalid commit message" | .githooks/commit-msg /dev/stdin >/dev/null 2>&1; then
    echo -e "${GREEN}✅ PASS${NC}"
    ((tests_passed++))
else
    echo -e "${RED}❌ FAIL${NC}"
    ((tests_failed++))
fi

# Test 3.3: Pre-commit hook runs without error
echo -n "Testing: Pre-commit hook execution... "
if .githooks/pre-commit >/dev/null 2>&1; then
    echo -e "${GREEN}✅ PASS${NC}"
    ((tests_passed++))
else
    echo -e "${RED}❌ FAIL${NC}"
    ((tests_failed++))
fi

echo ""
echo -e "${BLUE}📋 Test 4: Auto-Configuration Simulation${NC}"
echo "----------------------------------------"

# Test 4.1: Simulate post-checkout auto-configuration
echo -n "Testing: Post-checkout auto-configuration... "
# Temporarily unset hooksPath
git config --local --unset core.hooksPath 2>/dev/null || true
# Run post-checkout hook
if .githooks/post-checkout HEAD HEAD 0000000000000000000000000000000000000000 >/dev/null 2>&1; then
    # Check if hooksPath was set
    if git config --local core.hooksPath | grep -q '^\.githooks$'; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((tests_passed++))
    else
        echo -e "${RED}❌ FAIL${NC}"
        ((tests_failed++))
    fi
else
    echo -e "${RED}❌ FAIL${NC}"
    ((tests_failed++))
fi

# Test 4.2: Simulate post-merge auto-configuration
echo -n "Testing: Post-merge auto-configuration... "
# Temporarily unset hooksPath
git config --local --unset core.hooksPath 2>/dev/null || true
# Run post-merge hook
if .githooks/post-merge >/dev/null 2>&1; then
    # Check if hooksPath was set
    if git config --local core.hooksPath | grep -q '^\.githooks$'; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((tests_passed++))
    else
        echo -e "${RED}❌ FAIL${NC}"
        ((tests_failed++))
    fi
else
    echo -e "${RED}❌ FAIL${NC}"
    ((tests_failed++))
fi

echo ""
echo -e "${BLUE}📋 Test 5: Setup Script Functionality${NC}"
echo "------------------------------------"

# Test 5.1: Setup script exists
run_test \
    "Setup script exists" \
    "test -f scripts/maintenance/setup-hooks.zsh" \
    "setup-hooks.zsh should exist"

# Test 5.2: Setup script is executable
run_test \
    "Setup script executable" \
    "test -x scripts/maintenance/setup-hooks.zsh" \
    "setup-hooks.zsh should be executable"

# Test 5.3: Setup script runs without error
echo -n "Testing: Setup script execution... "
if ./scripts/maintenance/setup-hooks.zsh >/dev/null 2>&1; then
    echo -e "${GREEN}✅ PASS${NC}"
    ((tests_passed++))
else
    echo -e "${RED}❌ FAIL${NC}"
    ((tests_failed++))
fi

echo ""
echo -e "${BLUE}📋 Test Results Summary${NC}"
echo "========================"

if [[ $tests_failed -eq 0 ]]; then
    echo -e "${GREEN}🎉 All $tests_passed tests passed!${NC}"
    echo ""
    echo -e "${GREEN}✅ Hook consolidation successful!${NC}"
    echo "   • Legacy hooks removed"
    echo "   • New hook system active"
    echo "   • Auto-configuration working"
    echo "   • Setup script functional"
    echo ""
    echo -e "${BLUE}💡 Next steps:${NC}"
    echo "   • Test with fresh clone"
    echo "   • Verify hooks work in CI/CD"
    echo "   • Proceed to Phase 2 enhancements"
    exit 0
else
    echo -e "${RED}❌ $tests_failed tests failed, $tests_passed tests passed${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  Hook consolidation incomplete${NC}"
    echo "   Please review failed tests and fix issues"
    exit 1
fi 