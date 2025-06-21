#!/bin/zsh

# download_missing_firmware.zsh: Download firmware files for all firmware directories that have a download.url but no firmware archive
# Usage: ./download_missing_firmware.zsh [--debug]

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
    downloaded+="$zipfile"
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