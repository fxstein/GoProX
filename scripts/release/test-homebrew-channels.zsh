#!/bin/zsh

# Homebrew Multi-Channel Test Script
# Tests all Homebrew channels to ensure they work correctly
# Usage: ./test-homebrew-channels.zsh [--dry-run]

# Source logger
SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/../../scripts/core/logger.zsh"

# Configuration
DRY_RUN=${DRY_RUN:-false}
TEST_CHANNELS=("dev" "beta" "official")
TEMP_DIR=$(mktemp -d)

# Function to display help
show_help() {
    echo "Homebrew Multi-Channel Test Script"
    echo ""
    echo "Usage: $0 [--dry-run]"
    echo ""
    echo "Options:"
    echo "  --dry-run    - Test without making actual changes"
    echo "  --help, -h   - Show this help message"
    echo ""
    echo "This script tests all Homebrew channels to ensure they work correctly."
    echo "It validates formula generation, URL accessibility, and SHA256 calculation."
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

log_info "Starting Homebrew multi-channel test (DRY_RUN: $DRY_RUN)"

# Function to test a single channel
test_channel() {
    local channel="$1"
    local version=""
    local url=""
    local formula_name=""
    
    log_info "Testing channel: $channel"
    
    case $channel in
        dev)
            version="$(date +%Y%m%d)-dev"
            url="https://codeload.github.com/fxstein/GoProX/tar.gz/develop"
            formula_name="goprox@dev"
            ;;
        beta)
            version="$(git describe --tags --abbrev=0)-beta.$(date +%Y%m%d)"
            url="https://codeload.github.com/fxstein/GoProX/tar.gz/$(git rev-parse HEAD)"
            formula_name="goprox@beta"
            ;;
        official)
            version="$(git describe --tags --abbrev=0)"
            # Remove leading 'v' if present for the URL
            tag="${version#v}"
            url="https://codeload.github.com/fxstein/GoProX/tar.gz/v${tag}"
            formula_name="goprox"
            ;;
    esac
    
    log_info "  Version: $version"
    log_info "  URL: $url"
    log_info "  Formula: $formula_name"
    
    # Test URL accessibility
    log_info "  Testing URL accessibility..."
    if curl -s --head "$url" | head -n 1 | grep "HTTP/.* 200" > /dev/null; then
        log_success "  ✅ URL is accessible"
    else
        log_error "  ❌ URL is not accessible: $url"
        return 1
    fi
    
    # Test SHA256 calculation
    log_info "  Testing SHA256 calculation..."
    local sha256=$(curl -sL "$url" | sha256sum | cut -d' ' -f1)
    if [[ -n "$sha256" && ${#sha256} -eq 64 ]]; then
        log_success "  ✅ SHA256 calculated successfully: ${sha256:0:8}..."
    else
        log_error "  ❌ SHA256 calculation failed"
        return 1
    fi
    
    # Test formula generation
    log_info "  Testing formula generation..."
    local formula_file="$TEMP_DIR/${formula_name}.rb"
    
    case $channel in
        dev)
            cat > "$formula_file" << EOF
class GoproxDev < Formula
  desc "GoPro media management tool (dev build)"
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
    
    if [[ -f "$formula_file" ]]; then
        log_success "  ✅ Formula generated successfully"
        
        # Test formula syntax
        if ruby -c "$formula_file" > /dev/null 2>&1; then
            log_success "  ✅ Formula syntax is valid"
        else
            log_error "  ❌ Formula syntax is invalid"
            return 1
        fi
    else
        log_error "  ❌ Formula generation failed"
        return 1
    fi
    
    log_success "Channel $channel test completed successfully"
    return 0
}

# Function to test channel switching
test_channel_switching() {
    log_info "Testing channel switching scenarios..."
    
    local scenarios=(
        "official-to-beta"
        "beta-to-dev"
        "dev-to-official"
        "official-to-dev"
    )
    
    for scenario in "${scenarios[@]}"; do
        log_info "  Testing scenario: $scenario"
        
        case $scenario in
            "official-to-beta")
                echo "brew uninstall fxstein/tap/goprox"
                echo "brew install fxstein/tap/goprox@beta"
                ;;
            "beta-to-dev")
                echo "brew uninstall fxstein/tap/goprox@beta"
                echo "brew install fxstein/tap/goprox@dev"
                ;;
            "dev-to-official")
                echo "brew uninstall fxstein/tap/goprox@dev"
                echo "brew install fxstein/tap/goprox"
                ;;
            "official-to-dev")
                echo "brew uninstall fxstein/tap/goprox"
                echo "brew install fxstein/tap/goprox@dev"
                ;;
        esac
        
        log_success "  ✅ Scenario $scenario commands generated"
    done
}

# Main test execution
main() {
    log_info "Starting comprehensive Homebrew multi-channel test"
    
    local failed_channels=()
    local successful_channels=()
    
    # Test each channel
    for channel in "${TEST_CHANNELS[@]}"; do
        if test_channel "$channel"; then
            successful_channels+=("$channel")
        else
            failed_channels+=("$channel")
        fi
        echo ""
    done
    
    # Test channel switching
    test_channel_switching
    
    # Generate test report
    echo ""
    log_info "=== Test Report ==="
    log_info "Successful channels: ${successful_channels[*]}"
    log_info "Failed channels: ${failed_channels[*]}"
    
    if [[ ${#failed_channels[@]} -eq 0 ]]; then
        log_success "✅ All channels tested successfully!"
        echo ""
        echo "🎉 Multi-channel Homebrew integration is working correctly!"
        echo "📦 Channels available:"
        echo "  • Official: brew install fxstein/tap/goprox"
        echo "  • Beta: brew install fxstein/tap/goprox@beta"
        echo "  • Dev: brew install fxstein/tap/goprox@dev"
        echo ""
        echo "🔄 Channel switching commands:"
        test_channel_switching
    else
        log_error "❌ Some channels failed testing: ${failed_channels[*]}"
        exit 1
    fi
}

# Cleanup function
cleanup() {
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
        log_info "Cleaned up temporary directory: $TEMP_DIR"
    fi
}

# Set up cleanup trap
trap cleanup EXIT

# Run main function
main "$@" 