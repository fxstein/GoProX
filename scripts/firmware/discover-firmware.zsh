#!/bin/zsh
#
# discover-firmware.zsh: Discover firmware files using the GoPro Labs URL pattern
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
# Usage: ./scripts/firmware/discover-firmware.zsh [--debug] [--model MODEL] [--version VERSION]

set -uo pipefail

# GoPro Labs URL base
LABS_BASE_URL="https://media.githubusercontent.com/media/gopro/labs/master/docs/firmware/lfs"

# Known models and their patterns
declare -A MODELS=(
  ["HERO8"]="LABS_HERO8"
  ["HERO9"]="LABS_HERO9" 
  ["HERO10"]="LABS_HERO10"
  ["HERO11"]="LABS_HERO11"
  ["HERO12"]="LABS_HERO12"
  ["HERO13"]="LABS_HERO13"
  ["MINI11"]="LABS_MINI11"
  ["MAX"]="LABS_MAX"
)

debug=false
target_model=""
target_version=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --debug)
      debug=true
      shift
      ;;
    --model)
      target_model="$2"
      shift 2
      ;;
    --version)
      target_version="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--debug] [--model MODEL] [--version VERSION]"
      exit 1
      ;;
  esac
done

echo "🔍 GoPro Labs Firmware Discovery Tool"
echo "====================================="

# Function to test a single firmware URL
test_firmware_url() {
  local model="$1"
  local version="$2"
  local url="$LABS_BASE_URL/LABS_${model}_${version}.zip"
  
  if $debug; then
    echo "Testing: $url"
  fi
  
  # Use curl to check if file exists (HEAD request)
  if curl -s -I "$url" | grep -q "HTTP/2 200"; then
    local content_length=$(curl -s -I "$url" | grep -i "content-length:" | awk '{print $2}' | tr -d '\r')
    local last_modified=$(curl -s -I "$url" | grep -i "last-modified:" | sed 's/Last-Modified: //' | tr -d '\r')
    
    echo "✅ FOUND: $model v$version"
    echo "   URL: $url"
    echo "   Size: $((content_length / 1024 / 1024))MB"
    echo "   Modified: $last_modified"
    echo ""
    return 0
  else
    if $debug; then
      echo "❌ Not found: $url"
    fi
    return 1
  fi
}

# Function to test common version patterns
test_common_versions() {
  local model="$1"
  local base_version="$2"
  
  # Extract version components (e.g., "01_01_46" from "01_01_46_70")
  local version_base=$(echo "$base_version" | sed 's/_[0-9]*$//')
  
  # Test common build numbers
  local build_numbers=(70 71 72 73 74 75 76 77 78 79 80)
  local beta_builds=(70b 71b 72b 73b 74b 75b)
  
  echo "Testing common versions for $model based on $base_version..."
  
  # Test regular build numbers
  for build in "${build_numbers[@]}"; do
    test_firmware_url "$model" "${version_base}_${build}"
  done
  
  # Test beta build numbers
  for build in "${beta_builds[@]}"; do
    test_firmware_url "$model" "${version_base}_${build}"
  done
}

# Function to test specific firmware versions that might exist
test_specific_versions() {
  local model="$1"
  
  echo "Testing specific versions for $model..."
  
  # Test some common version patterns that might exist
  case "$model" in
    "HERO11")
      # Test some HERO11 versions that might exist
      test_firmware_url "$model" "01_01_10_70"
      test_firmware_url "$model" "01_01_10_71"
      test_firmware_url "$model" "01_01_10_72"
      test_firmware_url "$model" "01_01_20_71"
      test_firmware_url "$model" "01_01_20_72"
      test_firmware_url "$model" "01_02_10_71"
      test_firmware_url "$model" "01_02_10_72"
      test_firmware_url "$model" "01_02_32_71"
      test_firmware_url "$model" "01_02_32_72"
      ;;
    "HERO12")
      # Test some HERO12 versions that might exist
      test_firmware_url "$model" "01_02_32_71"
      test_firmware_url "$model" "01_02_32_72"
      test_firmware_url "$model" "01_02_32_73"
      ;;
    "HERO13")
      # Test some HERO13 versions that might exist
      test_firmware_url "$model" "01_02_02_71"
      test_firmware_url "$model" "01_02_02_72"
      test_firmware_url "$model" "01_02_02_73"
      ;;
    "HERO10")
      # Test some HERO10 versions that might exist
      test_firmware_url "$model" "01_01_46_71"
      test_firmware_url "$model" "01_01_46_72"
      test_firmware_url "$model" "01_01_62_71"
      test_firmware_url "$model" "01_01_62_72"
      ;;
    "MAX")
      # Test some MAX versions that might exist
      test_firmware_url "$model" "02_00_71"
      test_firmware_url "$model" "02_00_72"
      test_firmware_url "$model" "02_02_71"
      test_firmware_url "$model" "02_02_72"
      ;;
  esac
}

# Main discovery logic
if [[ -n "$target_model" && -n "$target_version" ]]; then
  # Test specific model and version
  echo "Testing specific firmware: $target_model v$target_version"
  test_firmware_url "$target_model" "$target_version"
else
  # Discover all possible firmware
  echo "Discovering firmware across all models..."
  echo ""
  
  for model in "${(@k)MODELS}"; do
    echo "🔍 Searching $model..."
    
    # Get known versions from our repository for this model
    known_versions=()
    if [[ -d "firmware.labs/$model Black" ]]; then
      for dir in firmware.labs/"$model Black"/*/; do
        if [[ -d "$dir" ]]; then
          version=$(basename "$dir")
          # Convert version format (e.g., H22.01.01.10.70 -> 01_01_10_70)
          clean_version=$(echo "$version" | sed 's/^H[0-9]*\.//' | sed 's/\./_/g')
          known_versions+=("$clean_version")
        fi
      done
    fi
    
    # Test known versions first
    for version in "${known_versions[@]}"; do
      test_firmware_url "$model" "$version"
    done
    
    # Test common version patterns for the first known version
    if [[ ${#known_versions[@]} -gt 0 ]]; then
      test_common_versions "$model" "${known_versions[1]}"
    fi
    
    # Test specific versions that might exist
    test_specific_versions "$model"
    
    echo ""
  done
fi

echo "Discovery complete! 🎉" 