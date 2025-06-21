#!/bin/zsh
#
# search-alternative-sources.zsh: Search for alternative sources for missing firmware files
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
# Usage: ./scripts/firmware/search-alternative-sources.zsh [--model MODEL] [--version VERSION]

set -uo pipefail

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

echo "🔍 Alternative Firmware Source Search Tool"
echo "=========================================="

# Function to test a URL
test_url() {
  local url="$1"
  local description="$2"
  
  if $debug; then
    echo "Testing: $description"
    echo "URL: $url"
  fi
  
  # Use curl to check if file exists (HEAD request)
  if curl -s -I "$url" | grep -q "HTTP/2 200"; then
    local content_length=$(curl -s -I "$url" | grep -i "content-length:" | awk '{print $2}' | tr -d '\r')
    local last_modified=$(curl -s -I "$url" | grep -i "last-modified:" | sed 's/Last-Modified: //' | tr -d '\r')
    
    echo "✅ FOUND: $description"
    echo "   URL: $url"
    echo "   Size: $((content_length / 1024 / 1024))MB"
    echo "   Modified: $last_modified"
    echo ""
    return 0
  else
    if $debug; then
      echo "❌ Not found: $description"
    fi
    return 1
  fi
}

# Function to search for HERO11 Black H22.01.01.10.70
search_hero11_01_10_70() {
  echo "🔍 Searching for HERO11 Black H22.01.01.10.70..."
  echo ""
  
  # Test various URL patterns and sources
  
  # 1. GoPro Labs variations
  echo "Testing GoPro Labs variations..."
  test_url "https://media.githubusercontent.com/media/gopro/labs/master/docs/firmware/lfs/LABS_HERO11_01_10_70.zip" "GoPro Labs - Standard"
  test_url "https://media.githubusercontent.com/media/gopro/labs/master/docs/firmware/lfs/LABS_HERO11_01_10_70b.zip" "GoPro Labs - Beta"
  test_url "https://media.githubusercontent.com/media/gopro/labs/master/docs/firmware/lfs/LABS_HERO11_01_10_71.zip" "GoPro Labs - Next version"
  
  # 2. GitHub repositories
  echo "Testing GitHub repositories..."
  test_url "https://github.com/fxstein/GoProX/raw/main/firmware.labs/HERO11%20Black/H22.01.01.10.70/UPDATE.zip" "GitHub - This repo"
  test_url "https://raw.githubusercontent.com/fxstein/GoProX/main/firmware.labs/HERO11%20Black/H22.01.01.10.70/UPDATE.zip" "GitHub - Raw"
  
  # 3. Third-party hosting
  echo "Testing third-party hosting..."
  test_url "https://miscdata.com/goprolabs/LABS_HERO11_01_10_70.zip" "Miscdata.com"
  test_url "https://gopro-firmware.com/HERO11/H22.01.01.10.70.zip" "gopro-firmware.com"
  test_url "https://firmware.gopro.com/labs/HERO11_01_10_70.zip" "firmware.gopro.com"
  
  # 4. Archive.org (Wayback Machine)
  echo "Testing archive.org..."
  test_url "https://web.archive.org/web/*/https://media.githubusercontent.com/media/gopro/labs/master/docs/firmware/lfs/LABS_HERO11_01_10_70.zip" "Archive.org"
  
  # 5. Alternative naming patterns
  echo "Testing alternative naming patterns..."
  test_url "https://media.githubusercontent.com/media/gopro/labs/master/docs/firmware/lfs/HERO11_01_10_70.zip" "Alternative naming 1"
  test_url "https://media.githubusercontent.com/media/gopro/labs/master/docs/firmware/lfs/LABS_HERO11_01_10_70_UPDATE.zip" "Alternative naming 2"
  test_url "https://media.githubusercontent.com/media/gopro/labs/master/docs/firmware/lfs/LABS_HERO11_01_10_70_FIRMWARE.zip" "Alternative naming 3"
  
  # 6. Different directories
  echo "Testing different directories..."
  test_url "https://media.githubusercontent.com/media/gopro/labs/master/firmware/LABS_HERO11_01_10_70.zip" "Different directory 1"
  test_url "https://media.githubusercontent.com/media/gopro/labs/master/firmware/lfs/HERO11/LABS_HERO11_01_10_70.zip" "Different directory 2"
  
  # 7. Salesforce variations (with different session tokens)
  echo "Testing Salesforce variations..."
  test_url "https://gopro.my.salesforce.com/sfc/p/o0000000HJuF/a/3b000000NSsa/qxQE7Wj.A4RB_A8WE7xhOhAmrwvEcsqsmGROQ8zzmO4" "Salesforce - Original"
  test_url "https://gopro.my.salesforce.com/sfc/p/o0000000HJuF/a/3b000000NSsa/LABS_HERO11_01_10_70.zip" "Salesforce - Direct"
  
  # 8. GoPro's official CDN
  echo "Testing GoPro CDN..."
  test_url "https://gopro.com/content/dam/help/hero11-black/firmware/H22.01.01.10.70.zip" "GoPro CDN 1"
  test_url "https://gopro.com/firmware/labs/HERO11_01_10_70.zip" "GoPro CDN 2"
  test_url "https://gopro.com/support/firmware/HERO11/H22.01.01.10.70.zip" "GoPro CDN 3"
  
  echo "Search complete!"
}

# Main logic
if [[ -n "$target_model" && -n "$target_version" ]]; then
  echo "Searching for specific firmware: $target_model v$target_version"
  # Add specific search logic for other models/versions here
else
  # Default to searching for the known missing firmware
  search_hero11_01_10_70
fi

echo "Alternative source search complete! 🎉" 