#!/bin/zsh
# Comprehensive GoProX Validation
# 
# This script runs comprehensive validation including both testing setup and CI/CD infrastructure.
# It orchestrates multiple validation scripts and provides a unified summary.

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
            echo "Purpose: Runs comprehensive validation including testing setup and CI/CD infrastructure"
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

# Track overall results
TOTAL_PASSED=0
TOTAL_FAILED=0

# Function to run validation and capture results
run_validation() {
    local script_name="$1"
    local description="$2"
    
    log_info "Running validation: $description"
    log_debug "Script: $script_name"
    echo "${BLUE}================================${NC}"
    
    # Run the validation script and capture output
    local output
    local exit_code
    
    if [[ "$DEBUG" == "true" ]]; then
        output=$(./scripts/testing/$script_name --debug 2>&1)
    else
        output=$(./scripts/testing/$script_name --verbose 2>&1)
    fi
    exit_code=$?
    
    # Display output
    echo "$output"
    
    # Extract pass/fail counts from the output
    local passed=$(echo "$output" | grep "Tests Passed:" | grep -o '[0-9]*' | head -1)
    local failed=$(echo "$output" | grep "Tests Failed:" | grep -o '[0-9]*' | head -1)
    
    # Add to totals (default to 0 if not found)
    passed=${passed:-0}
    failed=${failed:-0}
    
    TOTAL_PASSED=$((TOTAL_PASSED + passed))
    TOTAL_FAILED=$((TOTAL_FAILED + failed))
    
    echo ""
    if [[ $exit_code -eq 0 ]]; then
        log_success "✅ $description completed successfully"
    else
        log_error "❌ $description had issues"
    fi
    echo ""
}

# =============================================================================
# ENVIRONMENT VALIDATION
# =============================================================================

log_info "Validating comprehensive test environment..."

# Check essential dependencies
test_check() {
    local name="$1"
    local command="$2"
    local description="${3:-}"
    
    log_debug "Testing: $name"
    if [[ -n "$description" ]]; then
        log_debug "Description: $description"
    fi
    
    if eval "$command" >/dev/null 2>&1; then
        log_debug "✅ $name - PASS"
        return 0
    else
        log_debug "❌ $name - FAIL"
        return 1
    fi
}

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

log_info "Starting comprehensive validation execution..."
echo ""

# Run both validations
run_validation "validate-basic.zsh" "Basic Environment Validation"
run_validation "validate-ci.zsh" "CI/CD Infrastructure Validation"

# =============================================================================
# TEST SUMMARY
# =============================================================================

echo "${CYAN}========================================"
echo "Comprehensive Validation Summary"
echo "========================================${NC}"
echo ""
echo "Total Tests Passed: ${GREEN}$TOTAL_PASSED${NC}"
echo "Total Tests Failed: ${RED}$TOTAL_FAILED${NC}"
echo "Total Tests: $((TOTAL_PASSED + TOTAL_FAILED))"
echo ""

if [[ $TOTAL_FAILED -eq 0 ]]; then
    log_success "🎉 All validations passed!"
    echo ""
    echo "${YELLOW}What was tested:${NC}"
    echo "✅ Complete testing framework with real media files"
    echo "✅ File comparison and regression testing"
    echo "✅ GitHub Actions CI/CD workflows"
    echo "✅ Git LFS for media file management"
    echo "✅ Comprehensive documentation"
    echo "✅ Test output management"
    echo "✅ CI/CD infrastructure validation"
    echo ""
    echo "${YELLOW}Next steps:${NC}"
    echo "1. Push changes to trigger GitHub Actions"
    echo "2. Create pull requests to test CI/CD"
    echo "3. Monitor test results in GitHub Actions"
    echo "4. Use test framework for new feature development"
    exit 0
else
    log_error "⚠️  Some validations failed. Please review the issues above."
    echo ""
    echo "${YELLOW}Recommendations:${NC}"
    echo "1. Fix any failed tests before proceeding"
    echo "2. Ensure all dependencies are installed"
    echo "3. Check file permissions and paths"
    echo "4. Verify Git LFS configuration"
    echo "5. Run with --debug for additional information"
    exit 1
fi 