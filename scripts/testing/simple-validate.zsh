#!/bin/zsh
# Simple GoProX Testing Setup Validation

# Ensure output directory exists for test artifacts (important for CI/CD)
mkdir -p output

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "${BLUE}GoProX Testing Setup Validation${NC}"
echo "=================================="
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

echo "${BLUE}1. Basic Environment${NC}"
test_check "GoProX script exists" "test -f ./goprox"
test_check "GoProX script is executable" "test -x ./goprox"
test_check "GoProX help works" "./goprox --help >/dev/null 2>&1; test \$? -eq 1"

echo ""
echo "${BLUE}2. Dependencies${NC}"
test_check "exiftool installed" "command -v exiftool >/dev/null"
test_check "jq installed" "command -v jq >/dev/null"
test_check "zsh available" "command -v zsh >/dev/null"

echo ""
echo "${BLUE}3. Test Framework${NC}"
test_check "Test framework exists" "test -f scripts/testing/test-framework.zsh"
test_check "Test suites exist" "test -f scripts/testing/test-suites.zsh"
test_check "Test runner exists" "test -f scripts/testing/run-tests.zsh"
test_check "Test runner executable" "test -x scripts/testing/run-tests.zsh"

echo ""
echo "${BLUE}4. Test Media${NC}"
test_check "Test originals directory" "test -d test/originals"
test_check "HERO9 test file" "test -f test/originals/HERO9/photos/GOPR4047.JPG"
test_check "HERO10 test file" "test -f test/originals/HERO10/photos/GOPR1295.JPG"
test_check "HERO11 test file" "test -f test/originals/HERO11/photos/G0010035.JPG"

echo ""
echo "${BLUE}5. Git Configuration${NC}"
test_check ".gitignore excludes imported" "grep -q 'test/imported/' .gitignore"
test_check ".gitignore excludes processed" "grep -q 'test/processed/' .gitignore"
test_check ".gitattributes includes media" "grep -q 'test/\*\*/\*\.jpg' .gitattributes"

echo ""
echo "${BLUE}6. File Comparison Framework${NC}"
test_check "Comparison script exists" "test -f scripts/testing/test-file-comparison.zsh"
test_check "Comparison script executable" "test -x scripts/testing/test-file-comparison.zsh"

echo ""
echo "${BLUE}7. Documentation${NC}"
test_check "Test requirements doc" "test -f docs/testing/TEST_MEDIA_FILES_REQUIREMENTS.md"
test_check "Test output management doc" "test -f docs/testing/TEST_OUTPUT_MANAGEMENT.md"

echo ""
echo "${BLUE}8. Basic GoProX Test${NC}"

# Debug: Show current directory and test directory contents before running GoProX
echo "${YELLOW}DEBUG: Current directory: $(pwd)${NC}"
echo "${YELLOW}DEBUG: Test directory contents before GoProX run:${NC}"
ls -la test/ 2>/dev/null || echo "test/ directory does not exist"

echo -n "Testing: GoProX test mode... "
# First, test if the script can be executed at all
echo "DEBUG: Testing script execution..."
if ./goprox --help >/dev/null 2>&1; then
    echo "DEBUG: Script can be executed (help works)"
else
    echo "DEBUG: Script cannot be executed (help fails)"
    echo "DEBUG: Trying to run script directly with zsh..."
    if zsh goprox --help >/dev/null 2>&1; then
        echo "DEBUG: Script works when run with zsh directly"
    else
        echo "DEBUG: Script fails even when run with zsh directly"
    fi
fi

# Capture the actual output of GoProX test mode
GOPROX_OUTPUT=$(./goprox --test --verbose 2>&1)
GOPROX_EXIT_CODE=$?

if [[ $GOPROX_EXIT_CODE -eq 0 ]]; then
    echo "${GREEN}✅ PASS${NC}"
    ((PASSED++))
    
    # Debug: Show test directory contents after running GoProX
    echo "${YELLOW}DEBUG: Test directory contents after GoProX run:${NC}"
    ls -la test/ 2>/dev/null || echo "test/ directory still does not exist"
    
    test_check "Test imported created" "test -d test/imported"
    test_check "Test processed created" "test -d test/processed"
else
    echo "${RED}❌ FAIL${NC}"
    ((FAILED++))
    
    # Debug: Show the actual GoProX output
    echo "${YELLOW}DEBUG: GoProX test mode failed with exit code $GOPROX_EXIT_CODE${NC}"
    echo "${YELLOW}DEBUG: GoProX output (first 30 lines):${NC}"
    echo "$GOPROX_OUTPUT" | head -30
fi

echo ""
echo "${BLUE}Summary${NC}"
echo "========"
echo "Tests Passed: ${GREEN}$PASSED${NC}"
echo "Tests Failed: ${RED}$FAILED${NC}"
echo "Total Tests: $((PASSED + FAILED))"

if [[ $FAILED -eq 0 ]]; then
    echo ""
    echo "${GREEN}🎉 All tests passed! GoProX testing setup is ready.${NC}"
    exit 0
else
    echo ""
    echo "${RED}⚠️  Some tests failed. Please review the issues above.${NC}"
    exit 1
fi 