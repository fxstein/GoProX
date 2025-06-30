#!/bin/zsh

#
# run-homebrew-tests.zsh: Test runner for Homebrew multi-channel system
#
# Copyright (c) 2021-2025 by Oliver Ratzesberger
#
# This script runs the Homebrew multi-channel system tests, including
# unit tests and integration tests with mocked external dependencies.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Test options
RUN_UNIT_TESTS=false
RUN_INTEGRATION_TESTS=false
RUN_ALL_TESTS=false
VERBOSE=false
DEBUG=false

# Parse command line options
function parse_options() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --all)
                RUN_ALL_TESTS=true
                shift
                ;;
            --unit)
                RUN_UNIT_TESTS=true
                shift
                ;;
            --integration)
                RUN_INTEGRATION_TESTS=true
                shift
                ;;
            --verbose|-v)
                VERBOSE=true
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
    if [[ "$RUN_ALL_TESTS" == false && "$RUN_UNIT_TESTS" == false && "$RUN_INTEGRATION_TESTS" == false ]]; then
        RUN_ALL_TESTS=true
    fi
}

function show_help() {
    echo "Homebrew Multi-Channel Test Runner"
    echo "=================================="
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --all              Run all Homebrew tests (default)"
    echo "  --unit             Run unit tests only"
    echo "  --integration      Run integration tests only"
    echo "  --verbose, -v      Enable verbose output"
    echo "  --debug            Enable debug output"
    echo "  --help, -h         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Run all Homebrew tests"
    echo "  $0 --unit             # Run only unit tests"
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
    
    # Check if test framework exists
    if [[ ! -f "$SCRIPT_DIR/test-framework.zsh" ]]; then
        echo "${RED}Error: Test framework not found at $SCRIPT_DIR/test-framework.zsh${NC}"
        exit 1
    fi
    
    # Check if Homebrew test files exist
    if [[ ! -f "$SCRIPT_DIR/test-homebrew-multi-channel.zsh" ]]; then
        echo "${RED}Error: Homebrew unit tests not found${NC}"
        exit 1
    fi
    
    if [[ ! -f "$SCRIPT_DIR/test-homebrew-integration.zsh" ]]; then
        echo "${RED}Error: Homebrew integration tests not found${NC}"
        exit 1
    fi
    
    # Check if update script exists
    if [[ ! -f "$SCRIPT_DIR/../release/update-homebrew-channel.zsh" ]]; then
        echo "${RED}Error: update-homebrew-channel.zsh not found${NC}"
        exit 1
    fi
    
    echo "${GREEN}✅ Prerequisites check passed${NC}"
    echo ""
}

function run_homebrew_tests() {
    # Change to project root for testing
    cd "$PROJECT_ROOT"
    
    # Export debug flag for subscripts
    export DEBUG
    
    # Run unit tests
    if [[ "$RUN_ALL_TESTS" == true || "$RUN_UNIT_TESTS" == true ]]; then
        echo "${BLUE}🧪 Running Homebrew Unit Tests${NC}"
        echo "=================================="
        source "$SCRIPT_DIR/test-homebrew-multi-channel.zsh"
        run_homebrew_multi_channel_tests
        echo ""
    fi
    
    # Run integration tests
    if [[ "$RUN_ALL_TESTS" == true || "$RUN_INTEGRATION_TESTS" == true ]]; then
        echo "${BLUE}🧪 Running Homebrew Integration Tests${NC}"
        echo "=========================================="
        source "$SCRIPT_DIR/test-homebrew-integration.zsh"
        run_homebrew_integration_tests
        echo ""
    fi
}

function main() {
    echo "${BLUE}🍺 Homebrew Multi-Channel Test Runner${NC}"
    echo "==========================================="
    echo ""
    
    # Parse command line options
    parse_options "$@"
    
    # Check prerequisites
    check_prerequisites
    
    # Run tests
    local start_time=$(date +%s)
    run_homebrew_tests
    local exit_code=$?
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo ""
    echo "⏱️  Homebrew test execution completed in ${duration} seconds"
    
    if [[ $exit_code -eq 0 ]]; then
        echo "${GREEN}🎉 All Homebrew tests passed!${NC}"
    else
        echo "${RED}❌ Some Homebrew tests failed!${NC}"
    fi
    
    exit $exit_code
}

# Run main function with all arguments
main "$@" 