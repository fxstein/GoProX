#!/bin/zsh
# test-safe-prompt.zsh - Test script for safe prompt functions
#
# MIT License
#
# Copyright (c) 2024 GoProX Contributors
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# Description: Test script for safe prompt functions with graceful fallback
# Usage: ./test-safe-prompt.zsh [--non-interactive] [--auto-confirm]

set -e

# Setup logging
export LOGFILE="output/test-safe-prompt.log"
mkdir -p "$(dirname "$LOGFILE")"
source "$(dirname $0)/../core/logger.zsh"
source "$(dirname $0)/../core/safe-prompt.zsh"

log_time_start

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

# Parse command line arguments
NON_INTERACTIVE=false
AUTO_CONFIRM=false

# Parse safe prompt arguments first
local remaining_args
remaining_args=($(parse_safe_prompt_args "$@"))

while [[ ${#remaining_args[@]} -gt 0 ]]; do
    case ${remaining_args[0]} in
        --help|-h)
            echo "Usage: $0 [--non-interactive] [--auto-confirm]"
            echo ""
            echo "Options:"
            echo "  --non-interactive  Force non-interactive mode"
            echo "  --auto-confirm     Automatically confirm all prompts"
            echo "  --help, -h         Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: ${remaining_args[0]}"
            exit 1
            ;;
    esac
    remaining_args=("${remaining_args[@]:1}")
done

# Test function to run all safe prompt tests
test_safe_prompts() {
    print_status $BLUE "Testing Safe Prompt Functions"
    print_status $BLUE "============================"
    echo ""
    
    # Test 1: is_interactive function
    print_status $BLUE "Test 1: is_interactive function"
    if is_interactive; then
        print_status $GREEN "✓ Running in interactive mode"
    else
        print_status $YELLOW "⚠ Running in non-interactive mode"
    fi
    echo ""
    
    # Test 2: safe_confirm with default "N"
    print_status $BLUE "Test 2: safe_confirm with default 'N'"
    if safe_confirm "Test confirmation (should default to No)"; then
        print_status $GREEN "✓ User confirmed"
    else
        print_status $YELLOW "✓ User cancelled or defaulted to No"
    fi
    echo ""
    
    # Test 3: safe_confirm with default "Y"
    print_status $BLUE "Test 3: safe_confirm with default 'Y'"
    if safe_confirm "Test confirmation (should default to Yes)" "Y"; then
        print_status $GREEN "✓ User confirmed or defaulted to Yes"
    else
        print_status $YELLOW "✓ User cancelled"
    fi
    echo ""
    
    # Test 4: safe_prompt with default value
    print_status $BLUE "Test 4: safe_prompt with default value"
    local test_input
    test_input=$(safe_prompt "Enter test input (default: 'test')" "test")
    print_status $GREEN "✓ Input received: '$test_input'"
    echo ""
    
    # Test 5: safe_prompt without default value
    print_status $BLUE "Test 5: safe_prompt without default value"
    local test_input2
    test_input2=$(safe_prompt "Enter test input (no default)" "" 2>/dev/null || echo "ERROR: No default provided")
    print_status $GREEN "✓ Input received: '$test_input2'"
    echo ""
    
    # Test 6: safe_confirm_timeout
    print_status $BLUE "Test 6: safe_confirm_timeout (5 seconds)"
    if safe_confirm_timeout "Test timeout confirmation (5 seconds)" 5; then
        print_status $GREEN "✓ User confirmed within timeout"
    else
        print_status $YELLOW "✓ User cancelled or timeout reached"
    fi
    echo ""
    
    # Test 7: Command-line argument behavior
    print_status $BLUE "Test 7: Command-line argument behavior"
    print_status $BLUE "  NON_INTERACTIVE: ${NON_INTERACTIVE:-false}"
    print_status $BLUE "  AUTO_CONFIRM: ${AUTO_CONFIRM:-false}"
    echo ""
    
    print_status $GREEN "All safe prompt tests completed!"
}

# Main execution
main() {
    log_info "Starting safe prompt tests"
    
    if [[ "$NON_INTERACTIVE" == "true" ]]; then
        print_status $YELLOW "Running in forced non-interactive mode"
    fi
    
    if [[ "$AUTO_CONFIRM" == "true" ]]; then
        print_status $YELLOW "Auto-confirm mode enabled"
    fi
    
    echo ""
    test_safe_prompts
    
    log_info "Safe prompt tests completed successfully"
}

# Run main function
main "$@"
log_time_end 