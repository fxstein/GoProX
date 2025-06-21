#!/bin/zsh

#
# validate-firmware-urls.zsh: Validate all firmware download URLs in the firmware trees
#
# Copyright (c) 2021-2025 by Oliver Ratzesberger
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

# Usage: ./validate-firmware-urls.zsh [--debug]

set -uo pipefail

FIRMWARE_DIRS=(firmware firmware.labs)

debug=false
if [[ "${1:-}" == "--debug" ]]; then
  debug=true
fi

echo "\nValidating all firmware URLs in: ${FIRMWARE_DIRS[@]}\n"

broken_urls=()

total=0
ok=0
fail=0

# Collect all .url files into an array, handling spaces
urlfiles=()
for dir in $FIRMWARE_DIRS; do
  if [[ -d $dir ]]; then
    while IFS= read -r -d '' file; do
      urlfiles+="$file"
    done < <(find "$dir" -type f -name '*.url' -print0)
  fi
done

if $debug; then
  echo "DEBUG: urlfiles found: ${#urlfiles[@]}"
  for f in "${urlfiles[@]}"; do
    echo "DEBUG: $f"
  done
fi

set +e
for urlfile in "${urlfiles[@]}"; do
  if $debug; then
    echo "DEBUG: Entering validation loop for: $urlfile"
  fi
  if ! url=$(head -n 1 "$urlfile" | tr -d '\r\n'); then
    if $debug; then
      echo "[ERROR] Failed to read URL from $urlfile"
    fi
    broken_urls+="$urlfile (read error)"
    (( fail++ ))
    if ! $debug; then
      echo -n "X"
    fi
    continue
  fi
  (( total++ ))
  if [[ -z "$url" ]]; then
    if $debug; then
      echo "[MISSING] $urlfile: No URL found"
    fi
    broken_urls+="$urlfile (empty)"
    (( fail++ ))
    if ! $debug; then
      echo -n "X"
    fi
    continue
  fi
  if $debug; then
    echo -n "Checking $urlfile ... "
  fi
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 "$url")
  if [[ "$http_code" == "200" || "$http_code" == "302" ]]; then
    if $debug; then
      echo "OK"
    else
      echo -n "."
    fi
    (( ok++ ))
  else
    if $debug; then
      echo "BROKEN ($http_code)"
    else
      echo -n "X"
    fi
    broken_urls+="$urlfile ($http_code)"
    (( fail++ ))
  fi
done
set -e

echo ""
echo "\nSummary:"
echo "  Total URLs checked: $total"
echo "  OK: $ok"
echo "  Broken: $fail"

if (( fail > 0 )); then
  echo "\nBroken URLs:"
  for entry in $broken_urls; do
    echo "  $entry"
  done
  exit 1
else
  echo "\nAll firmware URLs are valid."
  exit 0
fi 