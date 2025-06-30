#!/bin/zsh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../core/logger.zsh"
source "$SCRIPT_DIR/../core/safe-prompt.zsh"

if safe_confirm "Proceed with safe_confirm test? (y/N)"; then
    echo "User confirmed."
else
    echo "User cancelled."
fi 