#!/bin/zsh

read -q "reply?Proceed with operation? (y/N) "
echo
if [[ $reply =~ ^[Yy]$ ]]; then
    echo "User confirmed."
else
    echo "User cancelled."
fi 