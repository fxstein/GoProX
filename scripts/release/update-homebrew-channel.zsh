#!/bin/zsh

# Homebrew Multi-Channel Update Script
# Updates Homebrew formula for specific release channel
# Usage: ./update-homebrew-channel.zsh [latest|beta|official]

# Source logger
source "$(dirname "$0")/../../scripts/core/logger.zsh"

# Initialize logger
init_logger "homebrew-channel-update" "info"

log_info "Starting Homebrew channel update for channel: $1"

# Validate channel parameter
local channel="$1"
if [[ -z "$channel" ]]; then
    log_error "Error: Channel parameter required"
    echo "Usage: $0 [latest|beta|official]"
    exit 1
fi

# Validate channel value
case $channel in
    latest|beta|official)
        log_info "Valid channel specified: $channel"
        ;;
    *)
        log_error "Error: Invalid channel '$channel'. Use: latest, beta, or official"
        echo "Usage: $0 [latest|beta|official]"
        exit 1
        ;;
esac

# Check for required environment variables
if [[ -z "$HOMEBREW_TOKEN" ]]; then
    log_error "Error: HOMEBREW_TOKEN not set. Cannot update Homebrew formula."
    echo "Please add a Personal Access Token with 'repo' scope as HOMEBREW_TOKEN secret."
    exit 1
fi

# Set up variables based on channel
local version=""
local url=""
local formula_name=""
local formula_file=""

case $channel in
    latest)
        version="$(date +%Y%m%d)-dev"
        url="https://github.com/fxstein/GoProX/archive/develop.tar.gz"
        formula_name="goprox@latest"
        formula_file="Formula/goprox@latest.rb"
        log_info "Latest build channel - version: $version"
        ;;
    beta)
        version="$(git describe --tags --abbrev=0)-beta.$(date +%Y%m%d)"
        url="https://github.com/fxstein/GoProX/archive/$(git rev-parse HEAD).tar.gz"
        formula_name="goprox@beta"
        formula_file="Formula/goprox@beta.rb"
        log_info "Beta channel - version: $version"
        ;;
    official)
        version="$(git describe --tags --abbrev=0)"
        url="https://github.com/fxstein/GoProX/archive/v${version}.tar.gz"
        formula_name="goprox"
        formula_file="Formula/goprox.rb"
        log_info "Official channel - version: $version"
        ;;
esac

# Calculate SHA256
log_info "Calculating SHA256 for URL: $url"
local sha256=""
sha256=$(curl -sL "$url" | sha256sum | cut -d' ' -f1)

if [[ -z "$sha256" ]]; then
    log_error "Error: Failed to calculate SHA256 for URL: $url"
    exit 1
fi

log_info "SHA256 calculated: $sha256"

# Clone Homebrew tap repository
local temp_dir=$(mktemp -d)
log_info "Cloning Homebrew tap repository to: $temp_dir"

cd "$temp_dir"
git clone https://x-access-token:$HOMEBREW_TOKEN@github.com/fxstein/homebrew-fxstein.git
cd homebrew-fxstein

# Create or update formula file
log_info "Updating formula file: $formula_file"

case $channel in
    latest)
        cat > "$formula_file" << EOF
class GoproxLatest < Formula
  desc "GoPro media management tool (latest build)"
  homepage "https://github.com/fxstein/GoProX"
  version "$version"
  url "$url"
  sha256 "$sha256"
  
  depends_on "zsh"
  depends_on "exiftool"
  depends_on "jq"
  
  def install
    bin.install "goprox"
    man1.install "man/goprox.1"
  end
  
  test do
    system "#{bin}/goprox", "--version"
  end
end
EOF
        ;;
    beta)
        cat > "$formula_file" << EOF
class GoproxBeta < Formula
  desc "GoPro media management tool (beta)"
  homepage "https://github.com/fxstein/GoProX"
  version "$version"
  url "$url"
  sha256 "$sha256"
  
  depends_on "zsh"
  depends_on "exiftool"
  depends_on "jq"
  
  def install
    bin.install "goprox"
    man1.install "man/goprox.1"
  end
  
  test do
    system "#{bin}/goprox", "--version"
  end
end
EOF
        ;;
    official)
        cat > "$formula_file" << EOF
class Goprox < Formula
  desc "GoPro media management tool"
  homepage "https://github.com/fxstein/GoProX"
  version "$version"
  url "$url"
  sha256 "$sha256"
  
  depends_on "zsh"
  depends_on "exiftool"
  depends_on "jq"
  
  def install
    bin.install "goprox"
    man1.install "man/goprox.1"
  end
  
  test do
    system "#{bin}/goprox", "--version"
  end
end
EOF
        ;;
esac

# Commit and push changes
log_info "Committing formula update for $formula_name"

git config user.name "GoProX Release Bot"
git config user.email "release-bot@goprox.dev"

git add "$formula_file"
git commit -m "Update $formula_name to version $version

- Channel: $channel
- SHA256: $sha256
- URL: $url

Automated update from GoProX release process."

# Push changes
log_info "Pushing changes to Homebrew tap repository"
git push origin main

# Cleanup
cd /
rm -rf "$temp_dir"

log_info "Successfully updated $formula_name to version $version"
echo "✅ Updated $formula_name to version $version"
echo "📦 Formula: $formula_file"
echo "🔗 URL: $url"
echo "�� SHA256: $sha256" 