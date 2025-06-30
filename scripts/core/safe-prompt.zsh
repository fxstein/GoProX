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
    [[ -t 0 ]] && [[ -t 1 ]]
}

# Function to safely prompt for yes/no confirmation
# Usage: safe_confirm "prompt message" [default_answer]
# Returns: 0 for yes, 1 for no
safe_confirm() {
    local prompt="$1"
    local default_answer="${2:-N}"
    local auto_confirm="${AUTO_CONFIRM:-false}"
    local non_interactive="${NON_INTERACTIVE:-false}"
    
    # Check if we should force non-interactive mode
    if [[ "$non_interactive" == "true" ]]; then
        log_warn "Forced non-interactive mode, using default answer: $default_answer"
        if [[ "$default_answer" =~ ^[Yy]$ ]]; then
            return 0
        else
            return 1
        fi
    fi
    
    # Check if running in interactive mode
    if is_interactive; then
        # Interactive mode - prompt user
        local reply
        read -q "reply?$prompt "
        echo
        
        if [[ $reply =~ ^[Yy]$ ]]; then
            log_info "User confirmed: $prompt"
            return 0
        else
            log_info "User cancelled: $prompt"
            return 1
        fi
    else
        # Non-interactive mode - use default or environment variable
        log_warn "Running in non-interactive mode, using default behavior"
        
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
    local prompt="$1"
    local default_value="$2"
    local variable_name="$3"
    local auto_confirm="${AUTO_CONFIRM:-false}"
    local non_interactive="${NON_INTERACTIVE:-false}"
    
    # Check if we should force non-interactive mode
    if [[ "$non_interactive" == "true" ]]; then
        log_warn "Forced non-interactive mode, using default value: $default_value"
        if [[ -n "$variable_name" ]]; then
            eval "$variable_name=\"$default_value\""
        fi
        echo "$default_value"
        return 0
    fi
    
    # Check if running in interactive mode
    if is_interactive; then
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
        
        log_info "User input: $reply"
        if [[ -n "$variable_name" ]]; then
            eval "$variable_name=\"$reply\""
        fi
        echo "$reply"
        return 0
    else
        # Non-interactive mode - use default or fail
        log_warn "Running in non-interactive mode, using default value"
        
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
        log_warn "Forced non-interactive mode, using default answer: $default_answer"
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
        log_warn "Running in non-interactive mode, using default behavior"
        
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

# Function to parse safe prompt command line arguments
# Usage: parse_safe_prompt_args "$@"
parse_safe_prompt_args() {
    local args=("$@")
    local i=0
    
    while [[ $i -lt ${#args[@]} ]]; do
        case "${args[$i]}" in
            --non-interactive)
                NON_INTERACTIVE=true
                # Remove the argument from the array
                args=("${args[@]:0:$i}" "${args[@]:$((i+1))}")
                ;;
            --auto-confirm)
                AUTO_CONFIRM=true
                # Remove the argument from the array
                args=("${args[@]:0:$i}" "${args[@]:$((i+1))}")
                ;;
            --default-yes)
                DEFAULT_YES=true
                # Remove the argument from the array
                args=("${args[@]:0:$i}" "${args[@]:$((i+1))}")
                ;;
            --help|-h)
                echo "Safe Prompt Options:"
                echo "  --non-interactive  Force non-interactive mode"
                echo "  --auto-confirm     Automatically confirm all prompts"
                echo "  --default-yes      Default to 'yes' for all prompts"
                echo "  --help, -h         Show this help"
                ;;
            *)
                ((i++))
                ;;
        esac
    done
    
    # Return the remaining arguments
    printf '%s\n' "${args[@]}"
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

export -f parse_safe_prompt_args
export -f show_safe_prompt_usage 