#!/bin/zsh
# CI/CD Validation for GoProX
# 
# This script validates the GitHub Actions workflows and CI/CD infrastructure.
# It ensures all workflows are properly configured and can execute successfully.

# =============================================================================
# ENVIRONMENTAL DETAILS (ALWAYS OUTPUT FIRST)
# =============================================================================
echo "🔍 ========================================="
echo "🔍 GoProX Test Script: $(basename "$0")"
echo "🔍 ========================================="
echo "🔍 Execution Details:"
echo "🔍   Script: $(basename "$0")"
echo "🔍   Full Path: $(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
echo "🔍   Working Directory: $(pwd)"
echo "🔍   User: $(whoami)"
echo "🔍   Host: $(hostname)"
echo "🔍   Shell: $SHELL"
echo "🔍   ZSH Version: $ZSH_VERSION"
echo "🔍   Date: $(date)"
echo "🔍   Git Branch: $(git branch --show-current 2>/dev/null || echo 'not a git repo')"
echo "🔍   Git Commit: $(git rev-parse --short HEAD 2>/dev/null || echo 'not a git repo')"
echo "🔍 ========================================="
echo ""

# =============================================================================
# CONFIGURATION
# =============================================================================

# Parse command line arguments
VERBOSE=true
DEBUG=false
QUIET=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --debug)
            DEBUG=true
            VERBOSE=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --quiet)
            QUIET=true
            VERBOSE=false
            DEBUG=false
            shift
            ;;
        --help|-h)
            echo "Usage: $(basename "$0") [options]"
            echo ""
            echo "Options:"
            echo "  --debug     Enable debug mode (implies --verbose)"
            echo "  --verbose   Enable verbose output (default)"
            echo "  --quiet     Disable verbose output"
            echo "  --help      Show this help message"
            echo ""
            echo "Test Script: $(basename "$0")"
            echo "Purpose: Validates GitHub Actions workflows and CI/CD infrastructure"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# =============================================================================
# COLOR DEFINITIONS
# =============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================

log_info() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo "${BLUE}[INFO]${NC} $1"
    fi
}

log_success() {
    echo "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo "${RED}[ERROR]${NC} $1"
}

log_debug() {
    if [[ "$DEBUG" == "true" ]]; then
        echo "${PURPLE}[DEBUG]${NC} $1"
    fi
}

# =============================================================================
# TEST FUNCTIONS
# =============================================================================

# Test counter
PASSED=0
FAILED=0

test_check() {
    local name="$1"
    local command="$2"
    local description="${3:-}"
    
    log_info "Testing: $name"
    if [[ -n "$description" ]]; then
        log_debug "Description: $description"
    fi
    
    if eval "$command" >/dev/null 2>&1; then
        log_success "✅ $name - PASS"
        ((PASSED++))
        return 0
    else
        log_error "❌ $name - FAIL"
        ((FAILED++))
        return 1
    fi
}

test_command() {
    local name="$1"
    local command="$2"
    local description="${3:-}"
    
    log_info "Executing: $name"
    if [[ -n "$description" ]]; then
        log_debug "Description: $description"
    fi
    
    log_debug "Command: $command"
    
    if eval "$command"; then
        log_success "✅ $name - PASS"
        ((PASSED++))
        return 0
    else
        log_error "❌ $name - FAIL"
        ((FAILED++))
        return 1
    fi
}

# =============================================================================
# ENVIRONMENT VALIDATION
# =============================================================================

log_info "Validating CI/CD test environment..."

# Check essential dependencies
test_check "zsh available" "command -v zsh >/dev/null" "Zsh shell is required for all tests"
test_check "exiftool available" "command -v exiftool >/dev/null" "ExifTool is required for media processing"
test_check "jq available" "command -v jq >/dev/null" "jq is required for JSON processing"

# Check GoProX environment
test_check "GoProX script exists" "test -f ./goprox" "Main GoProX script must be present"
test_check "GoProX script executable" "test -x ./goprox" "GoProX script must be executable"

# Check test environment
test_check "Test directory exists" "test -d test" "Test directory must exist"
test_check "Output directory writable" "test -w output 2>/dev/null || mkdir -p output" "Output directory must be writable"

log_info "Environment validation completed"
echo ""

# =============================================================================
# MAIN TEST LOGIC
# =============================================================================

log_info "Starting CI/CD validation execution..."
echo ""

# 1. GitHub Actions Workflows
log_info "Section 1: GitHub Actions Workflows"
test_check "PR test workflow exists" "test -f .github/workflows/pr-tests.yml" "PR tests workflow must exist"
test_check "Integration test workflow exists" "test -f .github/workflows/integration-tests.yml" "Integration tests workflow must exist"
test_check "Release test workflow exists" "test -f .github/workflows/release-tests.yml" "Release tests workflow must exist"
test_check "Lint workflow exists" "test -f .github/workflows/lint.yml" "Lint workflow must exist"

# 2. Workflow Syntax Validation
log_info "Section 2: Workflow Syntax Validation"
if command -v yamllint >/dev/null 2>&1; then
    test_check "PR test workflow syntax" "yamllint .github/workflows/pr-tests.yml" "PR test workflow must have valid YAML syntax"
    test_check "Integration test workflow syntax" "yamllint .github/workflows/integration-tests.yml" "Integration test workflow must have valid YAML syntax"
    test_check "Release test workflow syntax" "yamllint .github/workflows/release-tests.yml" "Release test workflow must have valid YAML syntax"
    test_check "Lint workflow syntax" "yamllint .github/workflows/lint.yml" "Lint workflow must have valid YAML syntax"
else
    log_warning "yamllint not available - skipping workflow syntax validation"
fi

# 3. Test Scripts for CI
log_info "Section 3: Test Scripts for CI"
test_check "Basic validation script exists" "test -f scripts/testing/validate-basic.zsh" "Basic validation script must exist"
test_check "Basic validation script executable" "test -x scripts/testing/validate-basic.zsh" "Basic validation script must be executable"
test_check "Integration validation script exists" "test -f scripts/testing/validate-integration.zsh" "Integration validation script must exist"
test_check "Integration validation script executable" "test -x scripts/testing/validate-integration.zsh" "Integration validation script must be executable"

# 4. CI Environment Simulation
log_info "Section 4: CI Environment Simulation"
log_info "Testing Ubuntu environment simulation..."

# Simulate what CI would do
if (
    # Check if we can install dependencies (simulate apt-get)
    command -v exiftool >/dev/null && \
    command -v jq >/dev/null && \
    command -v zsh >/dev/null && \
    # Check if scripts are executable (check each individually)
    test -x scripts/testing/validate-basic.zsh && \
    test -x scripts/testing/validate-integration.zsh && \
    test -x goprox && \
    # Check if we can run basic validation
    ./scripts/testing/validate-basic.zsh --quiet >/dev/null 2>&1
); then
    log_success "✅ Ubuntu environment simulation - PASS"
    ((PASSED++))
else
    log_error "❌ Ubuntu environment simulation - FAIL"
    ((FAILED++))
fi

# 5. Test Output Management
log_info "Section 5: Test Output Management"
test_check "Output directory exists" "test -d output" "Output directory must exist for CI artifacts"
test_check "Can create test results dir" "mkdir -p output/test-results" "Must be able to create test results directory"
test_check "Can create test temp dir" "mkdir -p output/test-temp" "Must be able to create test temp directory"

# 6. Git LFS for CI
log_info "Section 6: Git LFS for CI"
if command -v git-lfs >/dev/null 2>&1; then
    test_check "Git LFS installed" "command -v git-lfs >/dev/null" "Git LFS should be available for media files"
    test_check "Test media tracked by LFS" "git lfs ls-files | grep -q 'test/originals'" "Test media files should be tracked by Git LFS"
else
    log_warning "Git LFS not available - skipping LFS validation"
fi

# 7. Documentation for CI
log_info "Section 7: Documentation for CI"
test_check "CI integration doc exists" "test -f docs/testing/CI_CD_INTEGRATION.md" "CI integration documentation should exist"
test_check "Test framework doc exists" "test -f docs/testing/TESTING_FRAMEWORK.md" "Test framework documentation should exist"

# 8. Workflow Triggers
log_info "Section 8: Workflow Triggers"
# Check if workflows have proper triggers
test_check "PR test has PR trigger" "grep -q 'pull_request:' .github/workflows/pr-tests.yml" "PR test workflow should trigger on pull requests"
test_check "Integration test has push trigger" "grep -q 'push:' .github/workflows/integration-tests.yml" "Integration test workflow should trigger on pushes"
test_check "Release test has release trigger" "grep -q 'release:' .github/workflows/release-tests.yml" "Release test workflow should trigger on releases"

# 9. Artifact Management
log_info "Section 9: Artifact Management"
test_check "PR test uploads artifacts" "grep -q 'upload-artifact' .github/workflows/pr-tests.yml" "PR test workflow should upload artifacts"
test_check "Integration test uploads artifacts" "grep -q 'upload-artifact' .github/workflows/integration-tests.yml" "Integration test workflow should upload artifacts"
test_check "Release test uploads artifacts" "grep -q 'upload-artifact' .github/workflows/release-tests.yml" "Release test workflow should upload artifacts"

# 10. Error Handling
log_info "Section 10: Error Handling"
test_check "PR test has if: always()" "grep -q 'if: always()' .github/workflows/pr-tests.yml" "PR test workflow should handle failures gracefully"
test_check "Integration test has if: always()" "grep -q 'if: always()' .github/workflows/integration-tests.yml" "Integration test workflow should handle failures gracefully"
test_check "Release test has if: always()" "grep -q 'if: always()' .github/workflows/release-tests.yml" "Release test workflow should handle failures gracefully"

# =============================================================================
# TEST SUMMARY
# =============================================================================

echo ""
echo "${CYAN}========================================"
echo "Test Summary: $(basename "$0")"
echo "========================================${NC}"
echo "Tests Passed: ${GREEN}$PASSED${NC}"
echo "Tests Failed: ${RED}$FAILED${NC}"
echo "Total Tests: $((PASSED + FAILED))"
echo ""

if [[ $FAILED -eq 0 ]]; then
    log_success "🎉 All CI/CD tests passed!"
    echo ""
    echo "${YELLOW}What was tested:${NC}"
    echo "✅ GitHub Actions workflow configuration"
    echo "✅ Workflow syntax and triggers"
    echo "✅ Test script availability and permissions"
    echo "✅ CI environment simulation"
    echo "✅ Test output and artifact management"
    echo "✅ Git LFS configuration"
    echo "✅ Documentation and error handling"
    echo ""
    echo "${YELLOW}Next steps:${NC}"
    echo "1. Push changes to trigger GitHub Actions"
    echo "2. Monitor workflow runs in GitHub Actions tab"
    echo "3. Review test results and artifacts"
    echo "4. Verify CI/CD pipeline functionality"
    exit 0
else
    log_error "⚠️  Some CI/CD tests failed. Please review the issues above."
    echo ""
    echo "${YELLOW}Recommendations:${NC}"
    echo "1. Check the failed test details above"
    echo "2. Verify workflow YAML syntax"
    echo "3. Check file permissions and paths"
    echo "4. Ensure all dependencies are available"
    echo "5. Run with --debug for additional information"
    exit 1
fi 