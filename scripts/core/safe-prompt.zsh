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

# Function to check if running in interactive mode
is_interactive() {
    local t0=0
    if [[ -t 0 ]]; then t0=1; fi
    echo "[DEBUG] is_interactive: -t 0: $t0" >&2
    [[ $t0 -eq 1 ]]
}

# Function to safely prompt for yes/no confirmation
# Usage: safe_confirm "prompt message" [default_answer]
# Returns: 0 for yes, 1 for no
safe_confirm() {
    local prompt="$1"
    local default_answer="${2:-N}"
    local auto_confirm="${AUTO_CONFIRM:-false}"
    local non_interactive="${NON_INTERACTIVE:-false}"
    
    echo "[DEBUG] safe_confirm called with prompt: '$prompt', default: '$default_answer'" >&2
    echo "[DEBUG] auto_confirm: '$auto_confirm', non_interactive: '$non_interactive'" >&2
    
    # Check if we should force non-interactive mode
    if [[ "$non_interactive" == "true" ]]; then
        echo "[DEBUG] Forced non-interactive mode" >&2
        log_warning "Forced non-interactive mode, using default answer: $default_answer"
        if [[ "$default_answer" =~ ^[Yy]$ ]]; then
            return 0
        else
            return 1
        fi
    fi
    
    # Check if running in interactive mode
    if is_interactive; then
        echo "[DEBUG] Running in interactive mode" >&2
        # Interactive mode - prompt user
        local reply
        read -q "reply?$prompt "
        echo
        echo "[DEBUG] User input: '$reply'" >&2
        
        if [[ $reply =~ ^[Yy]$ ]]; then
            log_info "User confirmed: $prompt"
            return 0
        else
            log_info "User cancelled: $prompt"
            return 1
        fi
    else
        echo "[DEBUG] Running in non-interactive mode" >&2
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

# Function to safely prompt for text input
# Usage: safe_prompt "prompt message" [default_value] [variable_name]
# Returns: The user input or default value
safe_prompt() {
    local prompt="${1:-}"
    local default_value="${2:-}"
    local variable_name="${3:-}"
    local auto_confirm="${AUTO_CONFIRM:-false}"
    local non_interactive="${NON_INTERACTIVE:-false}"
    
    echo "[DEBUG] safe_prompt called with prompt: '$prompt', default: '$default_value'" >&2
    echo "[DEBUG] auto_confirm: '$auto_confirm', non_interactive: '$non_interactive'" >&2
    
    # Check if we should force non-interactive mode
    if [[ "$non_interactive" == "true" ]]; then
        echo "[DEBUG] Forced non-interactive mode" >&2
        log_warning "Forced non-interactive mode, using default value: $default_value"
        if [[ -n "$variable_name" ]]; then
            eval "$variable_name=\"$default_value\""
        fi
        echo "$default_value"
        return 0
    fi
    
    # Check if running in interactive mode
    if is_interactive; then
        echo "[DEBUG] Running in interactive mode" >&2
        # Interactive mode - prompt user
        local reply
        if [[ -n "$default_value" ]]; then
            read "reply?$prompt [$default_value]: "
            if [[ -z "$reply" ]]; then
                reply="$default_value"
            fi
        else
            read "reply?$prompt: "
        fi
        
        echo "[DEBUG] User input: '$reply'" >&2
        log_info "User input: $reply"
        if [[ -n "$variable_name" ]]; then
            eval "$variable_name=\"$reply\""
        fi
        echo "$reply"
        return 0
    else
        echo "[DEBUG] Running in non-interactive mode" >&2
        # Non-interactive mode - use default or fail
        log_warning "Running in non-interactive mode, using default value"
        
        if [[ -n "$default_value" ]]; then
            log_info "Using default value: $default_value"
            if [[ -n "$variable_name" ]]; then
                eval "$variable_name=\"$default_value\""
            fi
            echo "$default_value"
            return 0
        else
            log_error "Interactive input required but not available. Use --auto-confirm or provide a default value."
            return 1
        fi
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

# Export functions for use in other scripts
export -f is_interactive
export -f safe_confirm
export -f safe_prompt
export -f safe_confirm_timeout

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