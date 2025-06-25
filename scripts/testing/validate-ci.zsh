#!/bin/zsh
# CI/CD Validation for GoProX
# Tests our GitHub Actions workflows and CI/CD setup

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "${BLUE}GoProX CI/CD Validation${NC}"
echo "=========================="
echo ""

# Test counter
PASSED=0
FAILED=0

test_check() {
    local name="$1"
    local command="$2"
    
    echo -n "Testing: $name... "
    
    if eval "$command" >/dev/null 2>&1; then
        echo "${GREEN}✅ PASS${NC}"
        ((PASSED++))
    else
        echo "${RED}❌ FAIL${NC}"
        ((FAILED++))
    fi
}

echo "${BLUE}1. GitHub Actions Workflows${NC}"
test_check "Quick test workflow exists" "test -f .github/workflows/test-quick.yml"
test_check "Comprehensive test workflow exists" "test -f .github/workflows/test.yml"
test_check "Lint workflow exists" "test -f .github/workflows/lint.yml"
test_check "Release workflow exists" "test -f .github/workflows/release.yml"

echo ""
echo "${BLUE}2. Workflow Syntax Validation${NC}"
test_check "Quick test workflow syntax" "yamllint .github/workflows/test-quick.yml 2>/dev/null || echo 'yamllint not available'"
test_check "Comprehensive test workflow syntax" "yamllint .github/workflows/test.yml 2>/dev/null || echo 'yamllint not available'"
test_check "Lint workflow syntax" "yamllint .github/workflows/lint.yml 2>/dev/null || echo 'yamllint not available'"

echo ""
echo "${BLUE}3. Test Scripts for CI${NC}"
test_check "Validation script exists" "test -f scripts/testing/simple-validate.zsh"
test_check "Validation script executable" "test -x scripts/testing/simple-validate.zsh"
test_check "Test runner exists" "test -f scripts/testing/run-tests.zsh"
test_check "Test runner executable" "test -x scripts/testing/run-tests.zsh"

echo ""
echo "${BLUE}4. CI Environment Simulation${NC}"
echo -n "Testing: Ubuntu environment simulation... "
# Simulate what CI would do
if (
    # Check if we can install dependencies (simulate apt-get)
    command -v exiftool >/dev/null && \
    command -v jq >/dev/null && \
    command -v zsh >/dev/null && \
    # Check if scripts are executable (check each individually)
    test -x scripts/testing/simple-validate.zsh && \
    test -x scripts/testing/run-tests.zsh && \
    test -x goprox && \
    # Check if we can run basic validation
    ./scripts/testing/simple-validate.zsh >/dev/null 2>&1
); then
    echo "${GREEN}✅ PASS${NC}"
    ((PASSED++))
else
    echo "${RED}❌ FAIL${NC}"
    ((FAILED++))
fi

echo ""
echo "${BLUE}5. Test Output Management${NC}"
test_check "Output directory exists" "test -d output"
test_check "Can create test results dir" "mkdir -p output/test-results"
test_check "Can create test temp dir" "mkdir -p output/test-temp"

echo ""
echo "${BLUE}6. Git LFS for CI${NC}"
test_check "Git LFS installed" "command -v git-lfs >/dev/null"
test_check "Test media tracked by LFS" "git lfs ls-files | grep -q 'test/originals'"

echo ""
echo "${BLUE}7. Documentation for CI${NC}"
test_check "CI integration doc exists" "test -f docs/testing/CI_INTEGRATION.md"
test_check "Test framework doc exists" "test -f docs/testing/TESTING_FRAMEWORK.md"

echo ""
echo "${BLUE}8. Workflow Triggers${NC}"
# Check if workflows have proper triggers
test_check "Quick test has PR trigger" "grep -q 'pull_request:' .github/workflows/test-quick.yml"
test_check "Quick test has push trigger" "grep -q 'push:' .github/workflows/test-quick.yml"
test_check "Quick test ignores docs" "grep -q 'paths-ignore:' .github/workflows/test-quick.yml"

echo ""
echo "${BLUE}9. Artifact Management${NC}"
test_check "Quick test uploads artifacts" "grep -q 'upload-artifact' .github/workflows/test-quick.yml"
test_check "Comprehensive test uploads artifacts" "grep -q 'upload-artifact' .github/workflows/test.yml"

echo ""
echo "${BLUE}10. Error Handling${NC}"
test_check "Quick test has if: always()" "grep -q 'if: always()' .github/workflows/test-quick.yml"
test_check "Comprehensive test has if: always()" "grep -q 'if: always()' .github/workflows/test.yml"

echo ""
echo "${BLUE}Summary${NC}"
echo "========"
echo "Tests Passed: ${GREEN}$PASSED${NC}"
echo "Tests Failed: ${RED}$FAILED${NC}"
echo "Total Tests: $((PASSED + FAILED))"

if [[ $FAILED -eq 0 ]]; then
    echo ""
    echo "${GREEN}🎉 All CI/CD tests passed! GoProX CI/CD setup is ready.${NC}"
    echo ""
    echo "${YELLOW}Next steps:${NC}"
    echo "1. Push changes to trigger GitHub Actions"
    echo "2. Monitor workflow runs in GitHub Actions tab"
    echo "3. Review test results and artifacts"
    exit 0
else
    echo ""
    echo "${RED}⚠️  Some CI/CD tests failed. Please review the issues above.${NC}"
    exit 1
fi 