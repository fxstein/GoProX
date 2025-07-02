#!/bin/zsh

# Quick Hook System Verification
# Run this to verify hooks are working correctly

echo "🔍 Quick Hook System Verification"
echo "================================"

# Check core configuration
echo -n "📋 Core Configuration: "
if [[ "$(git config --local core.hooksPath)" == ".githooks" ]]; then
    echo "✅ OK"
else
    echo "❌ FAIL - hooksPath not configured"
    exit 1
fi

# Check hook files exist
echo -n "📋 Hook Files: "
if [[ -f ".githooks/commit-msg" && -f ".githooks/pre-commit" && -f ".githooks/post-commit" ]]; then
    echo "✅ OK"
else
    echo "❌ FAIL - missing hook files"
    exit 1
fi

# Test commit message validation
echo -n "📋 Commit Validation: "
if echo "test: valid message (refs #73)" | .githooks/commit-msg /dev/stdin >/dev/null 2>&1; then
    echo "✅ OK"
else
    echo "❌ FAIL - validation not working"
    exit 1
fi

# Test pre-commit hook
echo -n "📋 Pre-commit Hook: "
if .githooks/pre-commit >/dev/null 2>&1; then
    echo "✅ OK"
else
    echo "❌ FAIL - pre-commit hook error"
    exit 1
fi

echo ""
echo "🎉 Hook system verification complete!"
echo "✅ All checks passed" 