#!/bin/zsh
# Prevent accidental deletion of firmware files in firmware/ tree
# Place this script in .git/hooks/pre-commit or call from your pre-commit hook

# Only allow deletes if override is set
if [[ "$GOPROX_ALLOW_FIRMWARE_DELETE" != "1" ]]; then
  # Get list of staged deleted files in firmware/
  deleted=$(git diff --cached --name-status | awk '/^D/ && $2 ~ /^firmware\// {print $2}')
  if [[ -n "$deleted" ]]; then
    echo "\e[31mERROR: Attempted to delete files from the firmware tree!\e[0m"
    echo "The following files are staged for deletion from firmware/:"
    echo "$deleted"
    echo "\e[33mAborting commit. If this is intentional, set GOPROX_ALLOW_FIRMWARE_DELETE=1.\e[0m"
    exit 1
  fi
fi

exit 0 