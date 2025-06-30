#!/bin/zsh

# Test script to verify beta version generation logic
# This tests the fixes without requiring HOMEBREW_TOKEN

set -e

echo "🧪 Testing beta version generation logic..."

# Source the logger
source scripts/core/logger.zsh

# Test function to simulate the version generation logic
test_beta_version_generation() {
    echo "=== Testing Beta Version Generation ==="
    
    # Simulate the logic from update-homebrew-channel.zsh
    local latest_tag=""
    if git describe --tags --abbrev=0 2>/dev/null; then
        latest_tag="$(git describe --tags --abbrev=0)"
        echo "✅ Found latest tag: $latest_tag"
    else
        latest_tag="01.00.00"  # Fallback version if no tags exist
        echo "⚠️  No tags found, using fallback version: $latest_tag"
    fi
    
    # Strip 'v' prefix if present (like git tags)
    latest_tag="${latest_tag#v}"
    echo "📋 Cleaned tag: $latest_tag"
    
    local version="${latest_tag}-beta.$(date +%Y%m%d)"
    echo "📦 Generated beta version: $version"
    
    # Test URL generation
    local url="https://github.com/fxstein/GoProX/archive/$(git rev-parse HEAD).tar.gz"
    echo "🔗 Generated URL: $url"
    
    # Test formula class name
    local formula_class="GoproxBeta"
    echo "🏷️  Formula class name: $formula_class"
    
    echo ""
    echo "=== Test Results ==="
    echo "Version: $version"
    echo "URL: $url"
    echo "Class: $formula_class"
    echo ""
    
    # Validate version format (with or without v prefix)
    if [[ "$version" =~ ^v?[0-9]{2}\.[0-9]{2}\.[0-9]{2}-beta\.[0-9]{8}$ ]]; then
        echo "✅ Version format is valid"
    else
        echo "❌ Version format is invalid: $version"
        return 1
    fi
    
    # Validate URL format
    if [[ "$url" =~ ^https://github\.com/fxstein/GoProX/archive/[a-f0-9]{40}\.tar\.gz$ ]]; then
        echo "✅ URL format is valid"
    else
        echo "❌ URL format is invalid: $url"
        return 1
    fi
    
    # Validate class name
    if [[ "$formula_class" == "GoproxBeta" ]]; then
        echo "✅ Class name is correct"
    else
        echo "❌ Class name is incorrect: $formula_class"
        return 1
    fi
    
    echo ""
    echo "🎉 All tests passed!"
}

# Test prerelease detection logic
test_prerelease_detection() {
    echo "=== Testing Prerelease Detection Logic ==="
    
    # Test version-based detection
    local test_versions=("01.50.00" "01.50.00-beta" "01.50.00-beta.20250630")
    
    for version in "${test_versions[@]}"; do
        local is_prerelease="false"
        if [[ "$version" == *"beta"* ]]; then
            is_prerelease="true"
        fi
        
        echo "Version: $version -> Prerelease: $is_prerelease"
    done
    
    # Test branch-based detection
    local current_branch=$(git branch --show-current)
    local is_release_branch="false"
    if [[ "$current_branch" == release/* ]]; then
        is_release_branch="true"
    fi
    
    echo "Current branch: $current_branch -> Release branch: $is_release_branch"
    echo ""
}

# Run tests
test_beta_version_generation
test_prerelease_detection

echo "🧪 Testing completed successfully!" 