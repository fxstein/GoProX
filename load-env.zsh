#!/bin/zsh

# Load environment variables, using GitHub CLI for tokens when available
# Usage: source load-env.zsh

echo "🔐 Loading environment variables..."

# Try to get HOMEBREW_TOKEN from GitHub CLI first
if command -v gh &> /dev/null; then
    echo "🔍 Checking GitHub CLI for authentication..."
    
    # Check if GitHub CLI is authenticated
    if gh auth status &> /dev/null; then
        echo "✅ GitHub CLI is authenticated"
        
        # Get token from GitHub CLI
        local gh_token=""
        if gh_token=$(gh auth token 2>/dev/null); then
            export HOMEBREW_TOKEN="$gh_token"
            echo "✅ Loaded HOMEBREW_TOKEN from GitHub CLI"
        else
            echo "⚠️  Could not get token from GitHub CLI"
        fi
    else
        echo "⚠️  GitHub CLI not authenticated. Run 'gh auth login' first."
    fi
else
    echo "⚠️  GitHub CLI not found. Install with: brew install gh"
fi

# Load additional variables from .env file if it exists
if [[ -f .env ]]; then
    echo "📄 Loading additional variables from .env file..."
    
    # Read .env file and export variables
    while IFS= read -r line; do
        # Skip comments and empty lines
        if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "$line" ]]; then
            continue
        fi
        
        # Only export if not already set (GitHub CLI takes precedence)
        local var_name="${line%%=*}"
        if [[ -z "${(P)var_name}" ]]; then
            export "$line"
            echo "✅ Loaded: $var_name"
        else
            echo "⏭️  Skipped: $var_name (already set from GitHub CLI)"
        fi
    done < .env
else
    echo "ℹ️  No .env file found (optional for additional variables)"
fi

echo "🔐 Environment variables loaded successfully!" 