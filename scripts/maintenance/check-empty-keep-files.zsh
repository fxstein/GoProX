#!/bin/zsh

# Source the logger module
SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/../core/logger.zsh"

# Check that all .keep files in the firmware tree are empty
non_empty=()
for file in firmware/**/*.keep(.N); do
  if [[ -s $file ]]; then
    non_empty+=$file
  fi
done

if (( ${#non_empty} > 0 )); then
  log_error "Non-empty .keep files detected: ${(j:, :)non_empty}"
  echo "\e[31mERROR: The following .keep files are not empty:\e[0m"
  for f in $non_empty; do
    echo "  $f (size: $(stat -f %z "$f") bytes)"
  done
  echo "\e[33mPlease ensure all .keep files in the firmware tree are empty before committing.\e[0m"
  exit 1
fi

log_info ".keep file check passed: all .keep files are empty."
exit 0 