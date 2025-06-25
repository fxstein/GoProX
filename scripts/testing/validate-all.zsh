#!/bin/zsh
# Comprehensive GoProX Validation
# Validates both testing setup and CI/CD infrastructure

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo "${PURPLE}========================================${NC}"
echo "${PURPLE}GoProX Comprehensive Validation Suite${NC}"
echo "${PURPLE}========================================${NC}"
echo ""

# Track overall results
TOTAL_PASSED=0
TOTAL_FAILED=0

# Function to run validation and capture results
run_validation() {
    local script_name="$1"
    local description="$2"
    
    echo "${BLUE}Running: $description${NC}"
    echo "${BLUE}================================${NC}"
    
    # Run the validation script and capture output
    local output
    local exit_code
    output=$(./scripts/testing/$script_name 2>&1)
    exit_code=$?
    
    # Display output
    echo "$output"
    
    # Extract pass/fail counts from the output
    local passed=$(echo "$output" | grep "Tests Passed:" | grep -o '[0-9]*' | head -1)
    local failed=$(echo "$output" | grep "Tests Failed:" | grep -o '[0-9]*' | head -1)
    
    # Add to totals
    TOTAL_PASSED=$((TOTAL_PASSED + passed))
    TOTAL_FAILED=$((TOTAL_FAILED + failed))
    
    echo ""
    if [[ $exit_code -eq 0 ]]; then
        echo "${GREEN}✅ $description completed successfully${NC}"
    else
        echo "${RED}❌ $description had issues${NC}"
    fi
    echo ""
}

# Run both validations
run_validation "simple-validate.zsh" "Testing Setup Validation"
run_validation "validate-ci.zsh" "CI/CD Infrastructure Validation"

# Overall summary
echo "${PURPLE}========================================${NC}"
echo "${PURPLE}Overall Validation Summary${NC}"
echo "${PURPLE}========================================${NC}"
echo ""
echo "Total Tests Passed: ${GREEN}$TOTAL_PASSED${NC}"
echo "Total Tests Failed: ${RED}$TOTAL_FAILED${NC}"
echo "Total Tests: $((TOTAL_PASSED + TOTAL_FAILED))"
echo ""

if [[ $TOTAL_FAILED -eq 0 ]]; then
    echo "${GREEN}🎉 All validations passed! GoProX is ready for development and CI/CD.${NC}"
    echo ""
    echo "${YELLOW}What's working:${NC}"
    echo "✅ Complete testing framework with real media files"
    echo "✅ File comparison and regression testing"
    echo "✅ GitHub Actions CI/CD workflows"
    echo "✅ Git LFS for media file management"
    echo "✅ Comprehensive documentation"
    echo "✅ Test output management"
    echo ""
    echo "${YELLOW}Next steps:${NC}"
    echo "1. Push changes to trigger GitHub Actions"
    echo "2. Create pull requests to test CI/CD"
    echo "3. Monitor test results in GitHub Actions"
    echo "4. Use test framework for new feature development"
    exit 0
else
    echo "${RED}⚠️  Some validations failed. Please review the issues above.${NC}"
    echo ""
    echo "${YELLOW}Recommendations:${NC}"
    echo "1. Fix any failed tests before proceeding"
    echo "2. Ensure all dependencies are installed"
    echo "3. Check file permissions and paths"
    echo "4. Verify Git LFS configuration"
    exit 1
fi 