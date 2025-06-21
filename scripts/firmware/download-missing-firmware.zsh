#!/bin/zsh
#
# download-missing-firmware.zsh: Download firmware files for all firmware directories that have a download.url but no firmware archive
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
#
# Usage: ./scripts/download-missing-firmware.zsh [--debug]

set -uo pipefail

FIRMWARE_DIRS=(firmware firmware.labs)

debug=false
if [[ "${1:-}" == "--debug" ]]; then
  debug=true
fi

echo "\nChecking for missing firmware archives in: ${FIRMWARE_DIRS[@]}\n"

downloaded=()
skipped=()
failed=()

# Collect all .url files into an array, handling spaces
urlfiles=()
for dir in $FIRMWARE_DIRS; do
  if [[ -d $dir ]]; then
    while IFS= read -r -d '' file; do
      urlfiles+="$file"
    done < <(find "$dir" -type f -name '*.url' -print0)
  fi

done

for urlfile in "${urlfiles[@]}"; do
  fwdir="$(dirname "$urlfile")"
  # Determine expected zip name
  if [[ "$fwdir" == *"The Remote"* ]]; then
    zipname="REMOTE.UPDATE.zip"
  else
    zipname="UPDATE.zip"
  fi
  zipfile="$fwdir/$zipname"
  if [[ -f "$zipfile" ]]; then
    if $debug; then
      echo "[SKIP] $zipfile already exists."
    fi
    skipped+="$zipfile"
    continue
  fi
  url=$(head -n 1 "$urlfile" | tr -d '\r\n')
  if [[ -z "$url" ]]; then
    echo "[ERROR] No URL in $urlfile"
    failed+="$urlfile (empty url)"
    continue
  fi
  echo "[DOWNLOAD] $zipfile <- $url"
  if curl -L --fail -o "$zipfile" "$url"; then
    # Validate that the downloaded file is actually a ZIP archive
    if file "$zipfile" | grep -q "Zip archive"; then
      downloaded+="$zipfile"
    else
      echo "[ERROR] Downloaded file is not a valid ZIP archive: $zipfile"
      echo "[ERROR] File type: $(file "$zipfile")"
      failed+="$urlfile (invalid file type)"
      rm -f "$zipfile"
    fi
  else
    echo "[ERROR] Failed to download $url -> $zipfile"
    failed+="$urlfile (download failed)"
    rm -f "$zipfile"
  fi
  sleep 1  # be nice to servers

done

echo "\nSummary:"
echo "  Downloaded: ${#downloaded[@]}"
echo "  Skipped (already present): ${#skipped[@]}"
echo "  Failed: ${#failed[@]}"

if (( ${#failed[@]} > 0 )); then
  echo "\nFailed downloads:"
  for entry in $failed; do
    echo "  $entry"
  done
fi

exit 0 