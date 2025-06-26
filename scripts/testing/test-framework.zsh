#!/bin/zsh

#
# test-framework.zsh: Comprehensive testing framework for GoProX
#
# Copyright (c) 2021-2025 by Oliver Ratzesberger
#
# This framework provides comprehensive testing capabilities for GoProX,
# including unit tests, integration tests, configuration tests, and
# both success and failure scenarios.

set -e

# Test framework configuration
TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="${TEST_ROOT}/test"
TEST_OUTPUT_DIR="${TEST_ROOT}/output/test-results"
TEST_TEMP_DIR="${TEST_ROOT}/output/test-temp"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test statistics
declare -i TEST_TOTAL=0
declare -i TEST_PASSED=0
declare -i TEST_FAILED=0
declare -i TEST_SKIPPED=0

# Test results tracking
declare -a TEST_RESULTS=()

# Initialize test framework
function test_init() {
    echo "🧪 GoProX Test Framework"
    echo "========================"
    
    # Create test output directories
    mkdir -p "$TEST_OUTPUT_DIR"
    mkdir -p "$TEST_TEMP_DIR"
    
    # Reset test statistics
    declare -i TEST_TOTAL=0
    declare -i TEST_PASSED=0
    declare -i TEST_FAILED=0
    declare -i TEST_SKIPPED=0
    TEST_RESULTS=()
    
    echo "Test output directory: $TEST_OUTPUT_DIR"
    echo "Test temp directory: $TEST_TEMP_DIR"
    echo ""
}

# Test assertion functions
function assert_equal() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Values should be equal}"
    
    if [[ "$expected" == "$actual" ]]; then
        return 0
    else
        echo "❌ Assertion failed: $message"
        echo "   Expected: '$expected'"
        echo "   Actual:   '$actual'"
        return 1
    fi
}

function assert_not_equal() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Values should not be equal}"
    
    if [[ "$expected" != "$actual" ]]; then
        return 0
    else
        echo "❌ Assertion failed: $message"
        echo "   Expected: not '$expected'"
        echo "   Actual:   '$actual'"
        return 1
    fi
}

function assert_file_exists() {
    local file="$1"
    local message="${2:-File should exist}"
    
    if [[ -f "$file" ]]; then
        return 0
    else
        echo "❌ Assertion failed: $message"
        echo "   File: '$file'"
        return 1
    fi
}

function assert_file_not_exists() {
    local file="$1"
    local message="${2:-File should not exist}"
    
    if [[ ! -f "$file" ]]; then
        return 0
    else
        echo "❌ Assertion failed: $message"
        echo "   File: '$file'"
        return 1
    fi
}

function assert_directory_exists() {
    local dir="$1"
    local message="${2:-Directory should exist}"
    
    if [[ -d "$dir" ]]; then
        return 0
    else
        echo "❌ Assertion failed: $message"
        echo "   Directory: '$dir'"
        return 1
    fi
}

function assert_contains() {
    local text="$1"
    local pattern="$2"
    local message="${3:-Text should contain pattern}"
    
    if [[ "$text" =~ $pattern ]]; then
        return 0
    else
        echo "❌ Assertion failed: $message"
        echo "   Text: '$text'"
        echo "   Pattern: '$pattern'"
        return 1
    fi
}

function assert_exit_code() {
    local expected_code="$1"
    local actual_code="$2"
    local message="${3:-Exit code should match}"
    
    if [[ "$expected_code" == "$actual_code" ]]; then
        return 0
    else
        echo "❌ Assertion failed: $message"
        echo "   Expected exit code: $expected_code"
        echo "   Actual exit code: $actual_code"
        return 1
    fi
}

# Test execution functions
function run_test() {
    local test_name="$1"
    local test_function="$2"
    local test_description="${3:-$test_name}"
    if [[ "$DEBUG" == true ]]; then
        echo "[DEBUG] run_test: function entered with test_name=$test_name, test_function=$test_function"
    fi
    if [[ "$DEBUG" == true ]]; then
        echo "[DEBUG] run_test: about to increment TEST_TOTAL"
    fi
    TEST_TOTAL=$((TEST_TOTAL + 1))
    if [[ "$DEBUG" == true ]]; then
        echo "[DEBUG] run_test: TEST_TOTAL incremented, about to echo test name"
    fi
    if [[ "$DEBUG" == true ]]; then
        echo "[DEBUG] run_test: about to run $test_function in $test_name"
    fi
    echo -n "Running test: $test_name... "
    if [[ "$DEBUG" == true ]]; then
        echo "[DEBUG] run_test: echo completed, about to create temp directory"
    fi
    # Create test-specific temp directory
    local test_temp_dir="$TEST_TEMP_DIR/$test_name"
    mkdir -p "$test_temp_dir"
    # Run test in subshell to isolate environment
    local test_result
    local subshell_output
    local subshell_exit
    if [[ "$DEBUG" == true ]]; then
        echo "[DEBUG] run_test: running test in current directory (project root)"
    fi
    if [[ "$DEBUG" == true ]]; then
        echo "[DEBUG] run_test: about to call $test_function"
    fi
    if $test_function; then
        subshell_exit=0
    else
        subshell_exit=$?
    fi
    if [[ "$DEBUG" == true ]]; then
        echo "[DEBUG] run_test: subshell exit code: $subshell_exit"
    fi
    if [[ $subshell_exit -eq 0 ]]; then
        echo "${GREEN}✅ PASS${NC}"
        TEST_PASSED=$((TEST_PASSED + 1))
        test_result="PASS"
    else
        echo "${RED}❌ FAIL${NC}"
        TEST_FAILED=$((TEST_FAILED + 1))
        test_result="FAIL"
    fi
    # Store test result
    TEST_RESULTS+=("$test_name:$test_result:$test_description")
    if [[ "$DEBUG" == true ]]; then
        echo "[DEBUG] run_test: TEST_RESULTS now:"
        typeset -p TEST_RESULTS
    fi
    # Cleanup test temp directory
    rm -rf "$test_temp_dir"
}

function skip_test() {
    local test_name="$1"
    local reason="${2:-No reason provided}"
    
    TEST_TOTAL=$((TEST_TOTAL + 1))
    TEST_SKIPPED=$((TEST_SKIPPED + 1))
    
    echo "⏭️  SKIP: $test_name ($reason)"
    TEST_RESULTS+=("$test_name:SKIP:$reason")
}

# Test suite management
function test_suite() {
    local suite_name="$1"
    local suite_function="$2"
    
    echo ""
    echo "${BLUE}📋 Test Suite: $suite_name${NC}"
    echo "================================"
    
    $suite_function
    
    echo ""
    echo "Suite completed: $suite_name"
    
    if [[ "$DEBUG" == true ]]; then
        echo "[DEBUG] test_suite: Completed $suite_name"
    fi
}

# Test reporting
function generate_test_report() {
    mkdir -p "$TEST_OUTPUT_DIR"
    if [[ "$DEBUG" == true ]]; then
        echo "[DEBUG] generate_test_report: called"
        echo "[DEBUG] TEST_RESULTS at start of generate_test_report:"
        typeset -p TEST_RESULTS
    fi
    local report_file="$TEST_OUTPUT_DIR/test-report-$(date +%Y%m%d-%H%M%S).txt"
    if [[ "$DEBUG" == true ]]; then
        echo "[DEBUG] generate_test_report: report_file will be $report_file"
    fi
    echo "📊 Test Report" > "$report_file"
    echo "==============" >> "$report_file"
    echo "Generated: $(date)" >> "$report_file"
    echo "" >> "$report_file"
    
    echo "Summary:" >> "$report_file"
    echo "  Total: $TEST_TOTAL" >> "$report_file"
    echo "  Passed: $TEST_PASSED" >> "$report_file"
    echo "  Failed: $TEST_FAILED" >> "$report_file"
    echo "  Skipped: $TEST_SKIPPED" >> "$report_file"
    echo "" >> "$report_file"
    
    echo "Detailed Results:" >> "$report_file"
    echo "=================" >> "$report_file"
    for result in "${TEST_RESULTS[@]}"; do
        IFS=':' read -r name test_status description <<< "$result"
        echo "  $name: $test_status - $description" >> "$report_file"
    done
    
    if [[ "$DEBUG" == true ]]; then
        echo "[DEBUG] generate_test_report: finished writing $report_file"
    fi
    echo ""
    echo "Test report saved to: $report_file"
}

function print_test_summary() {
    echo ""
    echo "📊 Test Summary"
    echo "==============="
    echo "Total: $TEST_TOTAL"
    echo "Passed: ${GREEN}$TEST_PASSED${NC}"
    echo "Failed: ${RED}$TEST_FAILED${NC}"
    echo "Skipped: ${YELLOW}$TEST_SKIPPED${NC}"
    
    if [[ $TEST_FAILED -eq 0 ]]; then
        echo ""
        echo "${GREEN}🎉 All tests passed!${NC}"
        return 0
    else
        echo ""
        echo "${RED}❌ Some tests failed!${NC}"
        return 1
    fi
}

# Utility functions for tests
function create_test_config() {
    local config_file="$1"
    local content="$2"
    
    echo "$content" > "$config_file"
}

function create_test_media_file() {
    local file_path="$1"
    local content="${2:-Test media content}"
    
    mkdir -p "$(dirname "$file_path")"
    echo "$content" > "$file_path"
}

function cleanup_test_files() {
    local test_dir="$1"
    
    if [[ -d "$test_dir" ]]; then
        rm -rf "$test_dir"
    fi
}

# Main test runner
function run_all_tests() {
    test_init
    
    # Run test suites
    test_suite "Configuration Tests" test_configuration_suite
    test_suite "Parameter Processing Tests" test_parameter_processing_suite
    test_suite "Storage Validation Tests" test_storage_validation_suite
    test_suite "Integration Tests" test_integration_suite
    
    # Generate report and summary
    generate_test_report
    print_test_summary
    
    return $TEST_FAILED
} 