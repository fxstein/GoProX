#!/bin/zsh

# Test script for Homebrew update with GitHub CLI token loading
# Usage: ./test-homebrew-update.zsh [channel]

set -e

echo "🧪 Testing Homebrew update with GitHub CLI token loading..."

# Load environment variables (will try GitHub CLI first)
source ./load-env.zsh

# Check if token is loaded
if [[ -z "$HOMEBREW_TOKEN" ]]; then
    echo "❌ HOMEBREW_TOKEN not found in environment"
    echo ""
    echo "🔧 Setup Instructions:"
    echo "1. Install GitHub CLI: brew install gh"
    echo "2. Authenticate: gh auth login"
    echo "3. Verify: gh auth status"
    echo ""
    echo "Alternative: Add token to .env file:"
    echo "HOMEBREW_TOKEN=ghp_your_token_here"
    exit 1
fi

# Validate token format (basic check)
if [[ ! "$HOMEBREW_TOKEN" =~ ^gh[po]_[a-zA-Z0-9]{36}$ ]]; then
    echo "⚠️  Token format doesn't look like a valid GitHub token"
    echo "Expected format: ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx or gho_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    echo "Current token: ${HOMEBREW_TOKEN:0:10}..."
    echo "Continue anyway? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Get channel from argument or default to beta
local channel="${1:-beta}"
echo "📦 Testing Homebrew update for channel: $channel"

# Show what we're about to do
echo "🚀 About to run: ./scripts/release/update-homebrew-channel.zsh $channel"
echo "This will update the Homebrew formula for $channel channel"
echo "Continue? (y/N)"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Test cancelled"
    exit 0
fi

# Test the update script
echo "🚀 Running Homebrew update script..."
./scripts/release/update-homebrew-channel.zsh "$channel"

echo "✅ Homebrew update test completed!" 