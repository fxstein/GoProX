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
          "$RUN_WORKFLOW_TESTS" == false && "$RUN_LOGGER_TESTS" == false ]]; then
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
    
    if [[ "$RUN_LOGGER_TESTS" == true ]]; then
        test_suite "Logger Tests" test_logger_suite
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
main "$@" 