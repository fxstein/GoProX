#!/bin/zsh
#
# add-firmware.zsh: Add a firmware URL to the correct firmware tree location
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
# Usage: ./add-firmware.zsh --url <firmware_url>

set -uo pipefail

# Prefix table by model: sourced from the first firmware directory for each model, or H99.99 if not found
typeset -A PREFIX_TABLE
PREFIX_TABLE=(
  "GoPro Max" "H19.03"
  "HERO (2024)" "H24.xx"
  "HERO8 Black" "HD8.01"
  "HERO9 Black" "HD9.01"
  "HERO10 Black" "H21.01"
  "HERO11 Black" "H22.01"
  "HERO11 Black Mini" "H22.03"
  "HERO12 Black" "H23.01"
  "HERO13 Black" "H24.01"
  "The Remote" "GP.REM"
)

# Helper: print error and exit
function die() { echo "[ERROR] $1" >&2; exit 1; }

# Parse arguments
url=""
for ((i=1; i<=$#; i++)); do
  if [[ "${@[i]}" == "--url" ]]; then
    ((i++))
    url="${@[i]}"
  fi
  if [[ "${@[i]}" == "-h" || "${@[i]}" == "--help" ]]; then
    echo "Usage: $0 [--url <firmware_url>]"
    exit 0
  fi
done

# If no URL provided, prompt interactively
if [[ -z "$url" ]]; then
  echo -n "Enter firmware URL: "
  url=""
  while read -r line; do
    # Stop reading on empty line
    [[ -z "$line" ]] && break
    url+="$line"
  done
fi

# Remove all whitespace and newlines from the URL
url=$(echo "$url" | tr -d '\n' | tr -d '\r' | xargs)

[[ -z "$url" ]] && die "No URL provided."

# Determine if this is labs or official
is_labs=false
if echo "$url" | grep -qiE 'labs|LABS|githubusercontent|miscdata'; then
  is_labs=true
fi

# Try to parse camera type and version
camera=""
version=""

if $is_labs; then
  fname=$(basename "$url")
  # Handle LABS_HERO12_02_32_70.zip, LABS_HERO11_02_10_70_01.zip, LABS_MINI11_02_50_71b.zip, and LABS_MAX_02_02_70.zip
  if echo "$fname" | grep -qE '^LABS_(HERO|MINI|MAX)[0-9]*(_[0-9]{2,}[a-zA-Z]*)+\.zip$'; then
    if echo "$fname" | grep -qE '^LABS_MAX'; then
      camera="GoPro Max"
      vparts=$(echo "$fname" | sed -E 's/^LABS_MAX_//; s/\.zip$//')
      vdot=$(echo "$vparts" | tr '_' '.')
      prefix="${PREFIX_TABLE[$camera]:-H99.99}"
      version="$prefix.$vdot"
    else
      camtype=$(echo "$fname" | awk -F'_' '{print $2}' | sed 's/HERO//; s/MINI//')
      if echo "$fname" | grep -qE '^LABS_MINI'; then
        camera="HERO${camtype} Black Mini"
      else
        camera="HERO${camtype} Black"
      fi
      vparts=$(echo "$fname" | sed -E 's/^LABS_(HERO|MINI)[0-9]+_//; s/\.zip$//')
      vdot=$(echo "$vparts" | tr '_' '.')
      prefix="${PREFIX_TABLE[$camera]:-H99.99}"
      version="$prefix.$vdot"
    fi
  else
    # Fallback: try to extract from URL path
    if echo "$url" | grep -qE 'HERO[0-9]+'; then
      camera="HERO$(echo "$url" | grep -oE 'HERO[0-9]+' | head -1 | grep -oE '[0-9]+') Black"
      vdot=$(echo "$url" | grep -oE '([0-9]{2}\.[0-9]{2}\.[0-9]{2}(\.[0-9]{2})?)' | head -1)
      prefix="${PREFIX_TABLE[$camera]:-H99.99}"
      version="$prefix.$vdot"
    elif echo "$url" | grep -qE 'MINI[0-9]+'; then
      camnum=$(echo "$url" | grep -oE 'MINI[0-9]+' | head -1 | grep -oE '[0-9]+')
      camera="HERO${camnum} Black Mini"
      vdot=$(echo "$url" | grep -oE '([0-9]{2}\.[0-9]{2}\.[0-9]{2}(\.[0-9]{2})?)' | head -1)
      prefix="${PREFIX_TABLE[$camera]:-H99.99}"
      version="$prefix.$vdot"
    elif echo "$url" | grep -qE 'Max'; then
      camera="GoPro Max"
      vdot=$(echo "$url" | grep -oE '([0-9]{2}\.[0-9]{2}\.[0-9]{2}(\.[0-9]{2})?)' | head -1)
      prefix="${PREFIX_TABLE[$camera]:-H99.99}"
      version="$prefix.$vdot"
    fi
  fi
else
  # Official: parse from path (e.g., .../H22.01/camera_fw/02.32.00/UPDATE.zip or .../H22.01/camera_fw/01.01.10.00/UPDATE.zip)
  if echo "$url" | grep -qE '/((HD[0-9]{1}|H[0-9]{2})\.[0-9]{2})/camera_fw/([0-9]{2}(\.[0-9]{2}){2,})/UPDATE.zip'; then
    prefix=$(echo "$url" | grep -oE '/((HD[0-9]{1}|H[0-9]{2})\.[0-9]{2})/camera_fw/' | grep -oE '(HD[0-9]{1}|H[0-9]{2})\.[0-9]{2}')
    vdot=$(echo "$url" | grep -oE '/camera_fw/([0-9]{2}(\.[0-9]{2}){2,})/UPDATE.zip' | grep -oE '[0-9]{2}(\.[0-9]{2}){2,}')
    if echo "$url" | grep -qE 'HERO12[ ]*Black|H23.01'; then
      camera="HERO12 Black"
    elif echo "$url" | grep -qE 'HERO11[ ]*Black[ ]*Mini|H22.03'; then
      camera="HERO11 Black Mini"
    elif echo "$url" | grep -qE 'HERO11|H22.01'; then
      camera="HERO11 Black"
    elif echo "$url" | grep -qE 'HERO10|H21.01'; then
      camera="HERO10 Black"
    elif echo "$url" | grep -qE 'HERO9|HD9.01'; then
      camera="HERO9 Black"
    elif echo "$url" | grep -qE 'HERO8|HD8.01'; then
      camera="HERO8 Black"
    elif echo "$url" | grep -qE 'GoPro Max|H19.03'; then
      camera="GoPro Max"
    elif echo "$url" | grep -qE 'HERO[0-9]+'; then
      camera="HERO$(echo "$url" | grep -oE 'HERO[0-9]+' | head -1 | grep -oE '[0-9]+') Black"
    elif echo "$url" | grep -qE 'Max'; then
      camera="GoPro Max"
    elif echo "$url" | grep -qE 'Remote'; then
      camera="The Remote"
    elif echo "$url" | grep -qE 'H24\.03'; then
      camera="HERO (2024)"
    elif echo "$url" | grep -qE 'H24\.01'; then
      camera="HERO13 Black"
    fi
    prefix="${PREFIX_TABLE[$camera]:-H99.99}"
    version="$prefix.$vdot"
  elif echo "$url" | grep -qE '/(H[0-9]{2}\.[0-9]{2})/camera_fw/([0-9]{2}\.[0-9]{2}\.[0-9]{2})/UPDATE.zip'; then
    # Handle HERO (2024) format: /H24.03/camera_fw/02.20.00/UPDATE.zip
    prefix=$(echo "$url" | grep -oE '/(H[0-9]{2}\.[0-9]{2})/camera_fw/' | grep -oE 'H[0-9]{2}\.[0-9]{2}')
    vdot=$(echo "$url" | grep -oE '/camera_fw/([0-9]{2}\.[0-9]{2}\.[0-9]{2})/UPDATE.zip' | grep -oE '[0-9]{2}\.[0-9]{2}\.[0-9]{2}')
    if echo "$url" | grep -qE 'H24\.'; then
      camera="HERO (2024)"
    fi
    prefix="${PREFIX_TABLE[$camera]:-H99.99}"
    version="$prefix.$vdot"
  elif echo "$url" | grep -qE '/([Hh][0-9]{2}\.[0-9]{2}\.[0-9]{2}\.[0-9]{2}\.[0-9]{2})/camera_fw/'; then
    vdot=$(echo "$url" | grep -oE '/([Hh][0-9]{2}\.[0-9]{2}\.[0-9]{2}\.[0-9]{2}\.[0-9]{2})/camera_fw/' | grep -oE '[0-9]{2}\.[0-9]{2}\.[0-9]{2}\.[0-9]{2}\.[0-9]{2}')
    if echo "$url" | grep -qE 'HERO[0-9]+'; then
      camera="HERO$(echo "$url" | grep -oE 'HERO[0-9]+' | head -1 | grep -oE '[0-9]+') Black"
    elif echo "$url" | grep -qE 'Max'; then
      camera="GoPro Max"
    elif echo "$url" | grep -qE 'Remote'; then
      camera="The Remote"
    fi
    prefix="${PREFIX_TABLE[$camera]:-H99.99}"
    version="$prefix.$vdot"
  elif echo "$url" | grep -qE '/([A-Z0-9.]+)/camera_fw/'; then
    vdot=$(echo "$url" | grep -oE '/([A-Z0-9.]+)/camera_fw/' | grep -oE '[0-9]{2}\.[0-9]{2}\.[0-9]{2}(\.[0-9]{2})?')
    if echo "$url" | grep -qE 'HERO[0-9]+'; then
      camera="HERO$(echo "$url" | grep -oE 'HERO[0-9]+' | head -1 | grep -oE '[0-9]+') Black"
    elif echo "$url" | grep -qE 'Max'; then
      camera="GoPro Max"
    elif echo "$url" | grep -qE 'Remote'; then
      camera="The Remote"
    fi
    prefix="${PREFIX_TABLE[$camera]:-H99.99}"
    version="$prefix.$vdot"
  fi
fi

# If camera is empty but version is set, try .bin parsing as fallback
if [[ -z "$camera" && -n "$version" ]]; then
  camera=""
  version=""
fi

# Try .bin parsing for The Remote firmware
if [[ -z "$camera" ]] && echo "$url" | grep -qiE '\.bin$'; then
  fname=$(basename "$url")
  if echo "$fname" | grep -qE 'REMOTE.*FW.*[0-9]{2}.*[0-9]{2}.*[0-9]{2}'; then
    camera="The Remote"
    version=$(echo "$fname" | sed -E 's/^.*FW[^0-9]*//; s/\.bin$//' | tr '._' '.')
    version="GP.REMOTE.FW.$version"
  elif echo "$url" | grep -qE 'Remote|remote|GP\.REMOTE\.FW'; then
    camera="The Remote"
    vdot=$(echo "$url" | grep -oE '([0-9]{2}\.[0-9]{2}\.[0-9]{2})' | head -1)
    if [[ -n "$vdot" ]]; then
      version="GP.REMOTE.FW.$vdot"
    else
      die "Could not parse Remote firmware version from URL"
    fi
  fi
fi

[[ -z "$camera" || -z "$version" ]] && die "Could not parse camera type or firmware version from URL."

# Determine base directory
if $is_labs; then
  base="firmware.labs"
else
  base="firmware"
fi

dir="$base/$camera/$version"

# Create directories and .keep files
if [[ ! -d "$base/$camera" ]]; then
  mkdir -p "$base/$camera" || die "Failed to create $base/$camera"
  touch "$base/$camera/.keep"
fi
if [[ ! -d "$dir" ]]; then
  mkdir -p "$dir" || die "Failed to create $dir"
  touch "$dir/.keep"
fi

# Write download.url
urlfile="$dir/download.url"
echo "$url" > "$urlfile"

# Download the firmware file into the same directory
zipname="UPDATE.zip"
if [[ "$camera" == "The Remote" ]]; then
  # For The Remote, use .bin extension and extract filename from URL
  fname=$(basename "$url")
  if [[ "$fname" == *.bin ]]; then
    zipname="$fname"
  else
    zipname="REMOTE.UPDATE.bin"
  fi
fi
zipfile="$dir/$zipname"
echo "Downloading firmware to $zipfile ..."
if curl -L --fail -o "$zipfile" "$url"; then
  echo "Downloaded firmware to $zipfile"
else
  echo "[ERROR] Failed to download firmware from $url" >&2
  rm -f "$zipfile"
fi

echo "Added firmware URL for $camera $version at $urlfile" 