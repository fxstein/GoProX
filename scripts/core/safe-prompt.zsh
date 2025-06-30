#!/bin/zsh
# safe-prompt.zsh - Safe interactive prompt utility with graceful fallback
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
# Description: Provides safe interactive prompts with graceful fallback for non-interactive environments
# Usage: source "./scripts/core/safe-prompt.zsh"

# Source the logger
source "$(dirname "$0")/logger.zsh"

# Function to check if running in interactive mode
is_interactive() {
    local t0=0
    if [[ -t 0 ]]; then t0=1; fi
    log_debug "is_interactive: -t 0: $t0"
    [[ $t0 -eq 1 ]]
}

# Function to safely prompt for yes/no confirmation
# Usage: safe_confirm "prompt message" [default_answer]
# Returns: 0 for yes, 1 for no
safe_confirm() {
    local prompt="$1"
    local default_answer="${2:-N}"
    
    # Check if we should auto-confirm
    if [[ "${AUTO_CONFIRM:-false}" == "true" ]]; then
        log_debug "Auto-confirm enabled, returning true"
        return 0
    fi
    
    # Check if we should force non-interactive mode
    if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
        log_debug "Forced non-interactive mode"
        return 1
    fi
    
    # Check if we're in an interactive environment
    local t0
    t0=$(test -t 0 && echo "1" || echo "0")
    log_debug "is_interactive: -t 0: $t0"
    
    if [[ "$t0" == "1" ]]; then
        log_debug "Running in interactive mode"
        echo -n "$prompt " >&2
        read -r reply
        log_debug "User input: '$reply'"
        
        # Handle empty input (use default)
        if [[ -z "$reply" ]]; then
            reply="$default_answer"
        fi
        
        # Return true for yes, false for no
        [[ "$reply" =~ ^[Yy]$ ]]
    else
        log_debug "Running in non-interactive mode"
        return 1
    fi
}

# Function to safely prompt for text input
# Usage: safe_prompt "prompt message" [default_value] [variable_name]
# Returns: The user input or default value
safe_prompt() {
    local prompt="$1"
    local default_value="${2:-}"
    local variable_name="${3:-}"
    
    # Check if we should auto-confirm
    if [[ "${AUTO_CONFIRM:-false}" == "true" ]]; then
        log_debug "Auto-confirm enabled, returning default: '$default_value'"
        echo "$default_value"
        return 0
    fi
    
    # Check if we should force non-interactive mode
    if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
        log_debug "Forced non-interactive mode"
        echo "$default_value"
        return 0
    fi
    
    # Check if we're in an interactive environment
    local t0
    t0=$(test -t 0 && echo "1" || echo "0")
    log_debug "is_interactive: -t 0: $t0"
    
    if [[ "$t0" == "1" ]]; then
        log_debug "Running in interactive mode"
        
        # Build the prompt with default value if provided
        local full_prompt="$prompt"
        if [[ -n "$default_value" ]]; then
            full_prompt="$prompt [$default_value]"
        fi
        
        echo -n "$full_prompt: " >&2
        read -r reply
        log_debug "User input: '$reply'"
        
        # Return user input or default if empty
        if [[ -z "$reply" ]]; then
            echo "$default_value"
        else
            echo "$reply"
        fi
    else
        log_debug "Running in non-interactive mode"
        echo "$default_value"
    fi
}

# Function to safely prompt with timeout
# Usage: safe_confirm_timeout "prompt message" [timeout_seconds] [default_answer]
# Returns: 0 for yes, 1 for no
safe_confirm_timeout() {
    local prompt="$1"
    local timeout="${2:-30}"
    local default_answer="${3:-N}"
    local auto_confirm="${AUTO_CONFIRM:-false}"
    local non_interactive="${NON_INTERACTIVE:-false}"
    
    # Check if we should force non-interactive mode
    if [[ "$non_interactive" == "true" ]]; then
        log_warning "Forced non-interactive mode, using default answer: $default_answer"
        if [[ "$default_answer" =~ ^[Yy]$ ]]; then
            return 0
        else
            return 1
        fi
    fi
    
    # Check if running in interactive mode
    if is_interactive; then
        # Interactive mode - prompt user with timeout
        local reply
        if read -t"$timeout" -s -q "reply?$prompt "; then
            echo "Yes"
            log_info "User confirmed: $prompt"
            return 0
        else
            echo "No"
            log_info "User cancelled or timeout reached: $prompt"
            return 1
        fi
    else
        # Non-interactive mode - use default or environment variable
        log_warning "Running in non-interactive mode, using default behavior"
        
        if [[ "$auto_confirm" == "true" ]]; then
            log_info "Auto-confirm enabled, proceeding with operation"
            return 0
        elif [[ "$default_answer" =~ ^[Yy]$ ]]; then
            log_info "Default answer is yes, proceeding"
            return 0
        else
            log_error "Interactive input required but not available. Use --auto-confirm to proceed automatically."
            return 1
        fi
    fi
}

# Function to show safe prompt usage
show_safe_prompt_usage() {
    echo "Safe Prompt Usage:"
    echo "=================="
    echo ""
    echo "Command Line Arguments:"
    echo "  --non-interactive  Force non-interactive mode"
    echo "  --auto-confirm     Automatically confirm all prompts"
    echo "  --default-yes      Default to 'yes' for all prompts"
    echo ""
    echo "Examples:"
    echo "  $0 --non-interactive --auto-confirm"
    echo "  $0 --default-yes"
    echo ""
    echo "Note: Environment variables are not supported for interactive control."
    echo "Use command-line arguments for explicit, local control."
} 