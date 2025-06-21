#!/bin/zsh
#
# search-github.zsh: Search for firmware files across all GitHub repositories
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
# Usage: ./scripts/firmware/search-github.zsh [--debug] [--filename FILENAME]

set -uo pipefail

debug=false
target_filename=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --debug)
      debug=true
      shift
      ;;
    --filename)
      target_filename="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--debug] [--filename FILENAME]"
      exit 1
      ;;
  esac
done

echo "🔍 GitHub Firmware Search Tool"
echo "=============================="

# Function to search GitHub for a specific filename
search_github_file() {
  local filename="$1"
  local description="$2"
  
  echo "🔍 Searching for: $description"
  echo "Filename: $filename"
  echo ""
  
  # Search for the file using GitHub's search API
  local search_url="https://api.github.com/search/code?q=filename:$filename"
  
  if $debug; then
    echo "Search URL: $search_url"
  fi
  
  # Make the API request
  local response=$(curl -s -H "Accept: application/vnd.github.v3+json" "$search_url")
  
  # Check if we got a valid response
  if echo "$response" | grep -q '"total_count"'; then
    local total_count=$(echo "$response" | grep '"total_count"' | sed 's/.*"total_count": \([0-9]*\).*/\1/')
    
    if [[ "$total_count" -gt 0 ]]; then
      echo "✅ Found $total_count repositories with '$filename'"
      echo ""
      
      # Extract repository information
      echo "Repositories found:"
      echo "$response" | grep '"full_name"' | sed 's/.*"full_name": "\([^"]*\)".*/- \1/' | head -10
      
      if [[ "$total_count" -gt 10 ]]; then
        echo "... and $((total_count - 10)) more repositories"
      fi
      
      # Extract file URLs
      echo ""
      echo "File URLs:"
      echo "$response" | grep '"html_url"' | sed 's/.*"html_url": "\([^"]*\)".*/- \1/' | head -5
      
      if [[ "$total_count" -gt 5 ]]; then
        echo "... and $((total_count - 5)) more files"
      fi
      
      echo ""
      return 0
    else
      echo "❌ No repositories found with '$filename'"
      echo ""
      return 1
    fi
  else
    echo "❌ Error: Invalid response from GitHub API"
    if $debug; then
      echo "Response: $response"
    fi
    echo ""
    return 1
  fi
}

# Function to search for HERO11 Black H22.01.01.10.70 firmware
search_hero11_01_10_70() {
  echo "🔍 Searching for HERO11 Black H22.01.01.10.70 firmware across GitHub..."
  echo ""
  
  # Search for various possible filenames
  search_github_file "LABS_HERO11_01_10_70.zip" "GoPro Labs HERO11 01.10.70 firmware"
  search_github_file "H22.01.01.10.70.zip" "HERO11 firmware version H22.01.01.10.70"
  search_github_file "UPDATE.zip" "UPDATE.zip files in firmware directories"
  search_github_file "HERO11_01_10_70" "HERO11 01.10.70 firmware files"
  
  # Search for content in files
  echo "🔍 Searching for firmware content references..."
  echo ""
  
  # Search for references to this specific firmware version
  local content_search_url="https://api.github.com/search/code?q=H22.01.01.10.70+HERO11"
  local response=$(curl -s -H "Accept: application/vnd.github.v3+json" "$content_search_url")
  
  if echo "$response" | grep -q '"total_count"'; then
    local total_count=$(echo "$response" | grep '"total_count"' | sed 's/.*"total_count": \([0-9]*\).*/\1/')
    
    if [[ "$total_count" -gt 0 ]]; then
      echo "✅ Found $total_count files referencing H22.01.01.10.70"
      echo ""
      echo "Files found:"
      echo "$response" | grep '"html_url"' | sed 's/.*"html_url": "\([^"]*\)".*/- \1/' | head -10
      echo ""
    else
      echo "❌ No files found referencing H22.01.01.10.70"
      echo ""
    fi
  fi
}

# Function to search for GoPro firmware repositories
search_gopro_repos() {
  echo "🔍 Searching for GoPro firmware repositories..."
  echo ""
  
  # Search for repositories with "gopro" and "firmware"
  local repo_search_url="https://api.github.com/search/repositories?q=gopro+firmware"
  local response=$(curl -s -H "Accept: application/vnd.github.v3+json" "$repo_search_url")
  
  if echo "$response" | grep -q '"total_count"'; then
    local total_count=$(echo "$response" | grep '"total_count"' | sed 's/.*"total_count": \([0-9]*\).*/\1/')
    
    if [[ "$total_count" -gt 0 ]]; then
      echo "✅ Found $total_count GoPro firmware repositories"
      echo ""
      echo "Top repositories:"
      echo "$response" | grep '"full_name"' | sed 's/.*"full_name": "\([^"]*\)".*/- \1/' | head -10
      echo ""
    fi
  fi
}

# Main logic
if [[ -n "$target_filename" ]]; then
  echo "Searching for specific filename: $target_filename"
  search_github_file "$target_filename" "Custom search"
else
  # Default to searching for the missing HERO11 firmware
  search_hero11_01_10_70
  search_gopro_repos
fi

echo "GitHub search complete! 🎉" 