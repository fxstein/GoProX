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

# Setup logging
export LOGFILE="output/firmware-validate.log"
mkdir -p "$(dirname "$LOGFILE")"
source "$(dirname $0)/../core/logger.zsh"

log_time_start

FIRMWARE_DIRS=(firmware firmware.labs)

debug=false
if [[ "${1:-}" == "--debug" ]]; then
  debug=true
  export LOG_VERBOSE=1
fi

log_info "Validating all firmware URLs in: ${FIRMWARE_DIRS[@]}"

# Collect all .url files into an array, handling spaces
urlfiles=()
for dir in $FIRMWARE_DIRS; do
  if [[ -d $dir ]]; then
    log_debug "Scanning directory: $dir"
    while IFS= read -r -d '' file; do
      urlfiles+="$file"
    done < <(find "$dir" -type f -name '*.url' -print0)
  fi
done

if $debug; then
  log_debug "URL files found: ${#urlfiles[@]}"
fi

valid=()
invalid=()
missing=()

for urlfile in "${urlfiles[@]}"; do
  if [[ ! -f "$urlfile" ]]; then
    log_error "Failed to read URL from $urlfile"
    invalid+="$urlfile"
    continue
  fi
  
  url=$(head -n 1 "$urlfile" | tr -d '\r\n')
  if [[ -z "$url" ]]; then
    log_warning "$urlfile: No URL found"
    missing+="$urlfile"
    continue
  fi
  
  log_debug "Validating URL: $url"
  
  # Check if URL is accessible
  if curl -s --head --fail "$url" > /dev/null 2>&1; then
    valid+="$urlfile"
    log_debug "Valid URL: $url"
  else
    log_warning "Invalid URL: $url (in $urlfile)"
    invalid+="$urlfile"
  fi
done

log_info "Validation summary:"
log_info "  Valid URLs: ${#valid[@]}"
log_info "  Invalid URLs: ${#invalid[@]}"
log_info "  Missing URLs: ${#missing[@]}"

if (( ${#invalid[@]} > 0 )); then
  log_warning "Invalid URLs:"
  for urlfile in $invalid; do
    log_warning "  $urlfile"
  done
fi

if (( ${#missing[@]} > 0 )); then
  log_warning "Missing URLs:"
  for urlfile in $missing; do
    log_warning "  $urlfile"
  done
fi

log_time_end
exit 0 