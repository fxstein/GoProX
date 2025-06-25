#!/bin/zsh
# Validate GoProX Testing Setup
# Simple script to validate our current CI/CD and testing infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_header() {
    echo ""
    echo "${BLUE}================================${NC}"
    echo "${BLUE}$1${NC}"
    echo "${BLUE}================================${NC}"
}

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -n "Testing: $test_name... "
    
    if eval "$test_command" >/dev/null 2>&1; then
        echo "${GREEN}✅ PASS${NC}"
        ((TESTS_PASSED++))
    else
        echo "${RED}❌ FAIL${NC}"
        ((TESTS_FAILED++))
    fi
}

print_header "GoProX Testing Setup Validation"

# 1. Basic Environment Tests
print_header "1. Environment Validation"

run_test "GoProX script exists" "test -f ./goprox"
run_test "GoProX script is executable" "test -x ./goprox"
run_test "GoProX help works" "./goprox --help >/dev/null"
run_test "GoProX version works" "./goprox --version >/dev/null"

# 2. Dependencies Tests
print_header "2. Dependencies Validation"

run_test "exiftool is installed" "command -v exiftool >/dev/null"
run_test "jq is installed" "command -v jq >/dev/null"
run_test "zsh is available" "command -v zsh >/dev/null"

# 3. Test Framework Tests
print_header "3. Test Framework Validation"

run_test "Test framework script exists" "test -f scripts/testing/test-framework.zsh"
run_test "Test suites script exists" "test -f scripts/testing/test-suites.zsh"
run_test "Enhanced test suites exists" "test -f scripts/testing/enhanced-test-suites.zsh"
run_test "Test runner script exists" "test -f scripts/testing/run-tests.zsh"
run_test "Test runner is executable" "test -x scripts/testing/run-tests.zsh"

# 4. Test Media Validation
print_header "4. Test Media Validation"

run_test "Test originals directory exists" "test -d test/originals"
run_test "HERO9 test files exist" "test -f test/originals/HERO9/photos/GOPR4047.JPG"
run_test "HERO10 test files exist" "test -f test/originals/HERO10/photos/GOPR1295.JPG"
run_test "HERO11 test files exist" "test -f test/originals/HERO11/photos/G0010035.JPG"
run_test "GoPro Max test files exist" "test -f test/originals/GoPro_Max/photos/GS__3336.JPG"

# 5. Git LFS Validation
print_header "5. Git LFS Validation"

run_test "Git LFS is installed" "command -v git-lfs >/dev/null"
run_test "Test media files are tracked by LFS" "git lfs ls-files | grep -q 'test/originals'"

# 6. Output Directory Validation
print_header "6. Output Directory Validation"

run_test "Output directory exists" "test -d output"
run_test "Can create test results directory" "mkdir -p output/test-results"

# 7. Basic GoProX Functionality Test
print_header "7. Basic GoProX Functionality"

print_status $YELLOW "Running GoProX test mode..."
if ./goprox --test >/dev/null 2>&1; then
    print_status $GREEN "✅ GoProX test mode works"
    ((TESTS_PASSED++))
    
    # Check if test outputs were created
    run_test "Test imported files created" "test -d test/imported"
    run_test "Test processed files created" "test -d test/processed"
else
    print_status $RED "❌ GoProX test mode failed"
    ((TESTS_FAILED++))
fi

# 8. File Comparison Framework Test
print_header "8. File Comparison Framework"

run_test "Comparison script exists" "test -f scripts/testing/test-file-comparison.zsh"
run_test "Comparison script is executable" "test -x scripts/testing/test-file-comparison.zsh"

# Test baseline creation
print_status $YELLOW "Testing baseline creation..."
if ./scripts/testing/test-file-comparison.zsh baseline >/dev/null 2>&1; then
    print_status $GREEN "✅ Baseline creation works"
    ((TESTS_PASSED++))
    
    # Check if baseline was created
    run_test "Baseline directory created" "test -d output/regression-baseline"
    run_test "Baseline files exist" "find output/regression-baseline -name 'baseline-info.txt' | head -1 | xargs test -f"
else
    print_status $RED "❌ Baseline creation failed"
    ((TESTS_FAILED++))
fi

# 9. Git Configuration Test
print_header "9. Git Configuration"

run_test ".gitignore excludes test outputs" "grep -q 'test/imported/' .gitignore"
run_test ".gitignore excludes processed files" "grep -q 'test/processed/' .gitignore"
run_test ".gitattributes includes media files" "grep -q 'test/\*\*/\*\.jpg' .gitattributes"

# 10. Documentation Validation
print_header "10. Documentation Validation"

run_test "Test requirements doc exists" "test -f docs/testing/TEST_MEDIA_FILES_REQUIREMENTS.md"
run_test "Test output management doc exists" "test -f docs/testing/TEST_OUTPUT_MANAGEMENT.md"
run_test "Setup script exists" "test -f scripts/testing/setup-test-media.zsh"

# Summary
print_header "Validation Summary"

echo "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo "Total Tests: $((TESTS_PASSED + TESTS_FAILED))"

if [[ $TESTS_FAILED -eq 0 ]]; then
    print_status $GREEN "🎉 All tests passed! GoProX testing setup is ready."
    exit 0
else
    print_status $RED "⚠️  Some tests failed. Please review the issues above."
    exit 1
fi 