#!/bin/zsh
# INTERACTIVE TEST: Requires user input. Skipped in CI/non-interactive mode.

if [[ "$CI" == "true" || "$NON_INTERACTIVE" == "true" ]]; then
  echo "Skipping interactive test: $0 (non-interactive mode detected)"
  exit 0
fi

read -q "reply?Proceed with operation? (y/N) "
echo
if [[ $reply =~ ^[Yy]$ ]]; then
    echo "User confirmed."
else
    echo "User cancelled."
fi 