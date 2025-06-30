#!/bin/zsh

# Simple test to verify main function works
main() {
    echo "Main function called with: $@"
    echo "This is a test"
}

echo "About to call main function"
main "$@"
echo "Main function completed" 