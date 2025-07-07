#!/bin/zsh
# Test Script Template for GoProX
# 
# This template provides:
# - Standardized environmental details output
# - Verbose mode by default, debug mode when needed
# - Consistent color coding and formatting
# - Proper exit code handling
# - Test result tracking

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
            echo "Purpose: [DESCRIBE WHAT THIS TEST DOES]"
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

log_info "Starting main test execution..."
echo ""

# [INSERT MAIN TEST LOGIC HERE]
# Example:
# test_check "Feature X works" "test -f some_file" "Verify feature X functionality"
# test_command "Run process Y" "./some_script.sh" "Execute process Y and verify output"

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
    echo "✅ [LIST WHAT WAS TESTED]"
    echo ""
    echo "${YELLOW}Next steps:${NC}"
    echo "1. [SUGGEST NEXT STEPS]"
    echo "2. [SUGGEST NEXT STEPS]"
    exit 0
else
    log_error "⚠️  Some tests failed. Please review the issues above."
    echo ""
    echo "${YELLOW}Recommendations:${NC}"
    echo "1. Check the failed test details above"
    echo "2. Verify environment setup"
    echo "3. Check dependencies and permissions"
    echo "4. Review test logs for more details"
    exit 1
fi 