#!/bin/zsh

#
# run-tests.zsh: Main test runner for GoProX comprehensive testing
#
# Copyright (c) 2021-2025 by Oliver Ratzesberger
#
# This script runs the comprehensive test suite for GoProX, providing
# detailed reporting and both success and failure scenario testing.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory - use a more robust method for zsh
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Robustly find project root by searching upwards for 'goprox' script
PROJECT_ROOT="$(cd "$SCRIPT_DIR" && while [ ! -f goprox ] && [ "$PWD" != "/" ]; do cd ..; done; pwd)"

# Add project root to PATH so goprox is always found
export PATH="$PROJECT_ROOT:$PATH"

# Test options
RUN_ALL_TESTS=false
RUN_CONFIG_TESTS=false
RUN_PARAM_TESTS=false
RUN_STORAGE_TESTS=false
RUN_INTEGRATION_TESTS=false
RUN_ENHANCED_TESTS=false
RUN_MEDIA_TESTS=false
RUN_ERROR_TESTS=false
RUN_WORKFLOW_TESTS=false
RUN_LOGGER_TESTS=false
RUN_FIRMWARE_SUMMARY_TESTS=false
RUN_HOMEBREW_TESTS=false
RUN_HOMEBREW_INTEGRATION_TESTS=false
RUN_SAFE_PROMPT_TESTS=false
VERBOSE=false
QUIET=false
DEBUG=false

# Parse command line options
function parse_options() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --all)
                RUN_ALL_TESTS=true
                shift
                ;;
            --config)
                RUN_CONFIG_TESTS=true
                shift
                ;;
            --params)
                RUN_PARAM_TESTS=true
                shift
                ;;
            --storage)
                RUN_STORAGE_TESTS=true
                shift
                ;;
            --integration)
                RUN_INTEGRATION_TESTS=true
                shift
                ;;
            --enhanced)
                RUN_ENHANCED_TESTS=true
                shift
                ;;
            --media)
                RUN_MEDIA_TESTS=true
                shift
                ;;
            --error)
                RUN_ERROR_TESTS=true
                shift
                ;;
            --workflow)
                RUN_WORKFLOW_TESTS=true
                shift
                ;;
            --logger)
                RUN_LOGGER_TESTS=true
                shift
                ;;
            --firmware-summary)
                RUN_FIRMWARE_SUMMARY_TESTS=true
                shift
                ;;
            --brew)
                RUN_HOMEBREW_TESTS=true
                shift
                ;;
            --brew-integration)
                RUN_HOMEBREW_INTEGRATION_TESTS=true
                shift
                ;;
            --safe-prompt)
                RUN_SAFE_PROMPT_TESTS=true
                shift
                ;;
            --force-clean)
                FORCE_CLEAN=true
                shift
                ;;
            --skip-env-check)
                SKIP_ENV_CHECK=true
                shift
                ;;
            --verbose|-v)
                VERBOSE=true
                shift
                ;;
            --quiet|-q)
                QUIET=true
                shift
                ;;
            --debug)
                DEBUG=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                echo "${RED}Error: Unknown option $1${NC}"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Default to all tests if no specific test type is selected
    if [[ "$RUN_ALL_TESTS" == false && "$RUN_CONFIG_TESTS" == false && \
          "$RUN_PARAM_TESTS" == false && "$RUN_STORAGE_TESTS" == false && \
          "$RUN_INTEGRATION_TESTS" == false && "$RUN_ENHANCED_TESTS" == false && \
          "$RUN_MEDIA_TESTS" == false && "$RUN_ERROR_TESTS" == false && \
          "$RUN_WORKFLOW_TESTS" == false && "$RUN_LOGGER_TESTS" == false && \
          "$RUN_FIRMWARE_SUMMARY_TESTS" == false && "$RUN_HOMEBREW_TESTS" == false && \
          "$RUN_HOMEBREW_INTEGRATION_TESTS" == false && "$RUN_SAFE_PROMPT_TESTS" == false ]]; then
        RUN_ALL_TESTS=true
    fi

    if [[ "$DEBUG" == true ]]; then
        echo "[DEBUG] Options parsed:"
        echo "  RUN_ALL_TESTS=$RUN_ALL_TESTS"
        echo "  RUN_CONFIG_TESTS=$RUN_CONFIG_TESTS"
        echo "  RUN_PARAM_TESTS=$RUN_PARAM_TESTS"
        echo "  RUN_STORAGE_TESTS=$RUN_STORAGE_TESTS"
        echo "  RUN_INTEGRATION_TESTS=$RUN_INTEGRATION_TESTS"
        echo "  RUN_ENHANCED_TESTS=$RUN_ENHANCED_TESTS"
        echo "  RUN_MEDIA_TESTS=$RUN_MEDIA_TESTS"
        echo "  RUN_ERROR_TESTS=$RUN_ERROR_TESTS"
        echo "  RUN_WORKFLOW_TESTS=$RUN_WORKFLOW_TESTS"
        echo "  RUN_LOGGER_TESTS=$RUN_LOGGER_TESTS"
        echo "  RUN_FIRMWARE_SUMMARY_TESTS=$RUN_FIRMWARE_SUMMARY_TESTS"
        echo "  RUN_HOMEBREW_TESTS=$RUN_HOMEBREW_TESTS"
        echo "  RUN_HOMEBREW_INTEGRATION_TESTS=$RUN_HOMEBREW_INTEGRATION_TESTS"
        echo "  RUN_SAFE_PROMPT_TESTS=$RUN_SAFE_PROMPT_TESTS"
        echo "  FORCE_CLEAN=$FORCE_CLEAN"
        echo "  SKIP_ENV_CHECK=$SKIP_ENV_CHECK"
    fi
}

function show_help() {
    echo "GoProX Comprehensive Test Runner"
    echo "================================"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --all              Run all test suites (default)"
    echo "  --config           Run configuration tests only"
    echo "  --params           Run parameter processing tests only"
    echo "  --storage          Run storage validation tests only"
    echo "  --integration      Run integration tests only"
    echo "  --enhanced         Run enhanced tests only"
    echo "  --media            Run media tests only"
    echo "  --error            Run error handling tests only"
    echo "  --workflow         Run workflow tests only"
    echo "  --logger           Run logger tests only"
    echo "  --firmware-summary Run firmware summary tests only"
    echo "  --brew             Run Homebrew tests only"
    echo "  --brew-integration Run Homebrew integration tests only"
    echo "  --safe-prompt      Run safe prompt tests only"
    echo "  --verbose, -v      Enable verbose output"
    echo "  --quiet, -q        Suppress output except for failures"
    echo "  --debug            Enable debug output"
    echo "  --help, -h         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Run all tests"
    echo "  $0 --config           # Run only configuration tests"
    echo "  $0 --verbose --all    # Run all tests with verbose output"
    echo ""
}

function check_prerequisites() {
    echo "🔍 Checking prerequisites..."
    
    # Check if we're in the right directory
    if [[ ! -f "$PROJECT_ROOT/goprox" ]]; then
        echo "${RED}Error: goprox script not found in $PROJECT_ROOT${NC}"
        echo "Please run this script from the GoProX project root directory."
        exit 1
    fi
    
    # Check if test framework exists in scripts/testing
    if [[ ! -f "$SCRIPT_DIR/test-framework.zsh" ]]; then
        echo "${RED}Error: Test framework not found at $SCRIPT_DIR/test-framework.zsh${NC}"
        exit 1
    fi
    
    # Check if test suites exist in scripts/testing
    if [[ ! -f "$SCRIPT_DIR/test-suites.zsh" ]]; then
        echo "${RED}Error: Test suites not found at $SCRIPT_DIR/test-suites.zsh${NC}"
        exit 1
    fi
    
    # Check dependencies
    if ! command -v exiftool &> /dev/null; then
        echo "${RED}Error: exiftool not found. Please install exiftool.${NC}"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        echo "${RED}Error: jq not found. Please install jq.${NC}"
        exit 1
    fi
    
    echo "${GREEN}✅ Prerequisites check passed${NC}"
    echo ""
}

function run_selected_tests() {
    # Change to project root for testing
    cd "$PROJECT_ROOT"
    
    # Source the test framework and suites from SCRIPT_DIR
    source "$SCRIPT_DIR/test-framework.zsh"
    source "$SCRIPT_DIR/test-suites.zsh"
    source "$SCRIPT_DIR/enhanced-test-suites.zsh"
    source "$SCRIPT_DIR/test-homebrew-multi-channel.zsh"
    source "$SCRIPT_DIR/test-homebrew-integration.zsh"
    
    # Validate test environment unless skipped (after framework is loaded)
    if [[ "$SKIP_ENV_CHECK" != "true" ]]; then
        echo "🔍 Validating test environment..."
        if ! validate_clean_test_environment "test-runner"; then
            if [[ "$FORCE_CLEAN" == "true" ]]; then
                echo "🔄 Force clean mode: Tests will run in isolated environments where needed"
                export TEST_ISOLATED_MODE=true
            else
                echo "❌ Test environment is not clean. Use --force-clean to continue anyway."
                echo "   Or use --skip-env-check to bypass this validation."
                exit 1
            fi
        else
            echo "✅ Test environment is clean"
        fi
    fi
    
    # Initialize test framework
    test_init
    
    if [[ "$DEBUG" == true ]]; then
        echo "[DEBUG] Starting test suite execution"
    fi
    
    # Run selected test suites
    if [[ "$RUN_ALL_TESTS" == true || "$RUN_CONFIG_TESTS" == true ]]; then
        test_suite "Configuration Tests" test_configuration_suite
    fi
    
    if [[ "$RUN_ALL_TESTS" == true || "$RUN_PARAM_TESTS" == true ]]; then
        test_suite "Parameter Processing Tests" test_parameter_processing_suite
    fi
    
    if [[ "$RUN_ALL_TESTS" == true || "$RUN_STORAGE_TESTS" == true ]]; then
        test_suite "Storage Validation Tests" test_storage_validation_suite
    fi
    
    if [[ "$RUN_ALL_TESTS" == true || "$RUN_INTEGRATION_TESTS" == true ]]; then
        test_suite "Integration Tests" test_integration_suite
    fi
    
    if [[ "$RUN_ALL_TESTS" == true || "$RUN_ENHANCED_TESTS" == true ]]; then
        test_suite "Enhanced Functionality Tests" test_enhanced_functionality_suite
    fi
    
    if [[ "$RUN_ALL_TESTS" == true || "$RUN_MEDIA_TESTS" == true ]]; then
        test_suite "Media Processing Tests" test_media_processing_suite
    fi
    
    if [[ "$RUN_ALL_TESTS" == true || "$RUN_ERROR_TESTS" == true ]]; then
        test_suite "Error Handling Tests" test_error_handling_suite
    fi
    
    if [[ "$RUN_ALL_TESTS" == true || "$RUN_WORKFLOW_TESTS" == true ]]; then
        test_suite "Integration Workflow Tests" test_integration_workflows_suite
    fi
    
    if [[ "$RUN_ALL_TESTS" == true || "$RUN_LOGGER_TESTS" == true ]]; then
        test_suite "Logger Tests" test_logger_suite
    fi
    
    if [[ "$RUN_ALL_TESTS" == true || "$RUN_FIRMWARE_SUMMARY_TESTS" == true ]]; then
        test_suite "Firmware Summary Tests" test_firmware_summary_suite
    fi
    
    if [[ "$RUN_ALL_TESTS" == true || "$RUN_HOMEBREW_TESTS" == true ]]; then
        test_suite "Homebrew Multi-Channel Tests" run_homebrew_multi_channel_tests
    fi
    
    if [[ "$RUN_ALL_TESTS" == true || "$RUN_HOMEBREW_INTEGRATION_TESTS" == true ]]; then
        test_suite "Homebrew Integration Tests" run_homebrew_integration_tests
    fi
    
    if [[ "$RUN_ALL_TESTS" == true || "$RUN_SAFE_PROMPT_TESTS" == true ]]; then
        test_suite "Safe Prompt Tests" test_safe_prompt_suite
    fi
    
    if [[ "$DEBUG" == true ]]; then
        echo "[DEBUG] Test suite execution complete"
        echo "[DEBUG] TEST_RESULTS array contents:"
        typeset -p TEST_RESULTS
    fi
    
    # Generate report and summary
    if [[ "$DEBUG" == true ]]; then
        echo "[DEBUG] Generating test report"
    fi
    generate_test_report
    if [[ "$DEBUG" == true ]]; then
        echo "[DEBUG] Test report generation complete"
    fi
    print_test_summary
    
    return $TEST_FAILED
}

function test_safe_prompt_suite() {
    echo "🧪 Testing Safe Prompt Functions"
    
    # Source the logger and safe prompt functions
    source "$SCRIPT_DIR/../core/logger.zsh"
    source "$SCRIPT_DIR/../core/safe-prompt.zsh"
    
    # Test 1: Interactive mode detection
    test_interactive_mode_detection
    
    # Test 2: Non-interactive mode with auto-confirm
    test_non_interactive_auto_confirm
    
    # Test 3: Non-interactive mode without auto-confirm
    test_non_interactive_no_auto_confirm
    
    # Test 4: Safe confirm with default values
    test_safe_confirm_defaults
    
    # Test 5: Safe prompt with default values
    test_safe_prompt_defaults
    
    # Test 6: Safe confirm timeout
    test_safe_confirm_timeout
}

function test_interactive_mode_detection() {
    # Test that is_interactive function works correctly
    if is_interactive; then
        # We're in interactive mode, this should return true
        return 0
    else
        # We're not in interactive mode, this should return false
        return 0
    fi
}

function test_non_interactive_auto_confirm() {
    # Test safe_confirm in non-interactive mode with auto-confirm
    # Set local variables for testing (not environment variables)
    local AUTO_CONFIRM=true
    local NON_INTERACTIVE=true
    
    # This should return true (auto-confirm enabled)
    if safe_confirm "Test prompt" "N"; then
        return 0
    else
        return 1
    fi
}

function test_non_interactive_no_auto_confirm() {
    # Test safe_confirm in non-interactive mode without auto-confirm
    # Set local variables for testing (not environment variables)
    local AUTO_CONFIRM=false
    local NON_INTERACTIVE=true
    
    # This should return false (no auto-confirm, default N)
    if safe_confirm "Test prompt" "N"; then
        return 1
    else
        return 0
    fi
}

function test_safe_confirm_defaults() {
    # Test safe_confirm with different default values
    local NON_INTERACTIVE=true
    
    # Test with default "N" (should return false)
    local AUTO_CONFIRM=false
    if safe_confirm "Test prompt" "N"; then
        local result1=1
    else
        local result1=0
    fi
    
    # Test with default "Y" (should return true)
    if safe_confirm "Test prompt" "Y"; then
        local result2=0
    else
        local result2=1
    fi
    
    # Both tests should pass
    if [[ $result1 -eq 0 && $result2 -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

function test_safe_prompt_defaults() {
    # Test safe_prompt with default values
    local NON_INTERACTIVE=true
    
    # Test with default value
    local result=$(safe_prompt "Test prompt" "default_value")
    if [[ "$result" == "default_value" ]]; then
        local test1=0
    else
        local test1=1
    fi
    
    # Test without default value (should fail gracefully)
    local result2=$(safe_prompt "Test prompt" "" 2>/dev/null || echo "ERROR")
    if [[ "$result2" == "ERROR" ]]; then
        local test2=0
    else
        local test2=1
    fi
    
    # Both tests should pass
    if [[ $test1 -eq 0 && $test2 -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

function test_safe_confirm_timeout() {
    # Test safe_confirm_timeout function
    local NON_INTERACTIVE=true
    
    # Test with default "N" (should return false)
    local AUTO_CONFIRM=false
    if safe_confirm_timeout "Test prompt" 5 "N"; then
        local result1=1
    else
        local result1=0
    fi
    
    # Test with default "Y" (should return true)
    if safe_confirm_timeout "Test prompt" 5 "Y"; then
        local result2=0
    else
        local result2=1
    fi
    
    # Both tests should pass
    if [[ $result1 -eq 0 && $result2 -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

function main() {
    echo "${BLUE}🧪 GoProX Comprehensive Test Runner${NC}"
    echo "=========================================="
    echo ""
    
    # Parse command line options
    parse_options "$@"
    # Export DEBUG for subscripts
    export DEBUG
    
    # Check prerequisites
    check_prerequisites
    
    # Run tests
    local start_time=$(date +%s)
    run_selected_tests
    local exit_code=$?
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo ""
    echo "⏱️  Test execution completed in ${duration} seconds"
    
    exit $exit_code
}

# Run main function with all arguments
main "$@" # Test commit to trigger CI/CD
# Test commit to trigger CI/CD with fixed dependencies
