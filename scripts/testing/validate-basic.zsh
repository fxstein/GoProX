#!/bin/zsh
# Simple GoProX Testing Setup Validation
# 
# This script validates the basic GoProX testing environment and core functionality.
# It ensures all dependencies are available and the GoProX script can execute properly.

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
            echo "Purpose: Validates basic GoProX testing environment and core functionality"
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

log_info "Validating test environment..."

# Ensure output directory exists for test artifacts (important for CI/CD)
mkdir -p output

# Check essential dependencies
test_check "zsh available" "command -v zsh >/dev/null" "Zsh shell is required for all tests"
test_check "exiftool available" "command -v exiftool >/dev/null" "ExifTool is required for media processing"
test_check "jq available" "command -v jq >/dev/null" "jq is required for JSON processing"

# Check GoProX environment
test_check "GoProX script exists" "test -f ./goprox" "Main GoProX script must be present"
test_check "GoProX script executable" "test -x ./goprox" "GoProX script must be executable"

# Check test environment
test_check "Test directory exists" "test -d test" "Test directory must exist"
test_check "Output directory writable" "test -w output" "Output directory must be writable"

log_info "Environment validation completed"
echo ""

# =============================================================================
# MAIN TEST LOGIC
# =============================================================================

log_info "Starting main test execution..."
echo ""

# 1. Basic Environment Tests
log_info "Section 1: Basic Environment"
test_check "GoProX help works" "./goprox --help >/dev/null 2>&1; test \$? -eq 1" "GoProX help command should work and exit with code 1"

# 2. Test Framework Tests
log_info "Section 2: Test Framework"
test_check "Test framework exists" "test -f scripts/testing/test-framework.zsh" "Core test framework script must exist"
test_check "Test suites exist" "test -f scripts/testing/test-suites.zsh" "Test suites script must exist"
test_check "Test runner exists" "test -f scripts/testing/run-tests.zsh" "Main test runner script must exist"
test_check "Test runner executable" "test -x scripts/testing/run-tests.zsh" "Test runner must be executable"

# 3. Test Media Tests
log_info "Section 3: Test Media"
test_check "Test originals directory" "test -d test/originals" "Test media directory must exist"
test_check "HERO9 test file" "test -f test/originals/HERO9/photos/GOPR4047.JPG" "HERO9 test media file must exist"
test_check "HERO10 test file" "test -f test/originals/HERO10/photos/GOPR1295.JPG" "HERO10 test media file must exist"
test_check "HERO11 test file" "test -f test/originals/HERO11/photos/G0010035.JPG" "HERO11 test media file must exist"

# 4. Git Configuration Tests
log_info "Section 4: Git Configuration"
test_check ".gitignore excludes imported" "grep -q 'test/imported/' .gitignore" "Git ignore should exclude test imported files"
test_check ".gitignore excludes processed" "grep -q 'test/processed/' .gitignore" "Git ignore should exclude test processed files"
test_check ".gitattributes includes media" "grep -q 'test/\*\*/\*\.jpg' .gitattributes" "Git attributes should track test media files"

# 5. File Comparison Framework Tests
log_info "Section 5: File Comparison Framework"
test_check "Comparison script exists" "test -f scripts/testing/test-file-comparison.zsh" "File comparison script must exist"
test_check "Comparison script executable" "test -x scripts/testing/test-file-comparison.zsh" "File comparison script must be executable"

# 6. Documentation Tests
log_info "Section 6: Documentation"
test_check "Test requirements doc" "test -f docs/testing/TEST_MEDIA_FILES_REQUIREMENTS.md" "Test requirements documentation must exist"
test_check "Test output management doc" "test -f docs/testing/TEST_OUTPUT_MANAGEMENT.md" "Test output management documentation must exist"

# 7. Basic GoProX Test
log_info "Section 7: Basic GoProX Test"

# Debug: Show current directory and test directory contents before running GoProX
log_debug "Current directory: $(pwd)"
log_debug "Test directory contents before GoProX run:"
if [[ "$DEBUG" == "true" ]]; then
    ls -la test/ 2>/dev/null || echo "test/ directory does not exist"
fi

log_info "Testing GoProX test mode execution"
log_debug "Testing script execution..."

# First, test if the script can be executed at all
if ./goprox --help >/dev/null 2>&1; then
    log_debug "Script can be executed (help works)"
else
    log_debug "Script cannot be executed (help fails)"
    log_debug "Trying to run script directly with zsh..."
    if zsh goprox --help >/dev/null 2>&1; then
        log_debug "Script works when run with zsh directly"
    else
        log_debug "Script fails even when run with zsh directly"
        log_debug "Trying to run script with bash to see error..."
        if [[ "$DEBUG" == "true" ]]; then
            bash goprox --help 2>&1 | head -5
        fi
    fi
fi

# Capture the actual output of GoProX test mode
log_info "Executing GoProX test mode"
GOPROX_OUTPUT=$(./goprox --test --verbose 2>&1)
GOPROX_EXIT_CODE=$?

if [[ $GOPROX_EXIT_CODE -eq 0 ]]; then
    log_success "✅ GoProX test mode - PASS"
    ((PASSED++))
    
    # Debug: Show test directory contents after running GoProX
    log_debug "Test directory contents after GoProX run:"
    if [[ "$DEBUG" == "true" ]]; then
        ls -la test/ 2>/dev/null || echo "test/ directory still does not exist"
    fi
    
    test_check "Test imported created" "test -d test/imported" "GoProX should create imported directory"
    test_check "Test processed created" "test -d test/processed" "GoProX should create processed directory"
else
    log_error "❌ GoProX test mode - FAIL"
    ((FAILED++))
    
    # Debug: Show the actual GoProX output
    log_debug "GoProX test mode failed with exit code $GOPROX_EXIT_CODE"
    log_debug "GoProX output (first 30 lines):"
    if [[ "$DEBUG" == "true" ]]; then
        echo "$GOPROX_OUTPUT" | head -30
    fi
fi

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
    log_success "🎉 All tests passed!"
    echo ""
    echo "${YELLOW}What was tested:${NC}"
    echo "✅ Basic environment setup and dependencies"
    echo "✅ GoProX script execution and core functionality"
    echo "✅ Test framework and media files"
    echo "✅ Git configuration and file tracking"
    echo "✅ Documentation and comparison tools"
    echo ""
    echo "${YELLOW}Next steps:${NC}"
    echo "1. Run integration tests for comprehensive validation"
    echo "2. Use test framework for development and regression testing"
    echo "3. Monitor CI/CD results in GitHub Actions"
    exit 0
else
    log_error "⚠️  Some tests failed. Please review the issues above."
    echo ""
    echo "${YELLOW}Recommendations:${NC}"
    echo "1. Check the failed test details above"
    echo "2. Verify environment setup and dependencies"
    echo "3. Check file permissions and paths"
    echo "4. Review test logs for more details"
    echo "5. Run with --debug for additional information"
    exit 1
fi 