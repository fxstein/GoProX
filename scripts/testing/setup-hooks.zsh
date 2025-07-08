#!/bin/zsh

# Simple Hook Consolidation Test
# Quick verification that legacy hooks are removed and new system works

echo "🧪 Simple Hook Consolidation Test"
echo "================================"
echo ""

# Test 1: Legacy hooks removed
echo "📋 Test 1: Legacy Hook Removal"
echo "--------------------------------"

if [[ ! -f "scripts/maintenance/install-commit-hooks.zsh" ]]; then
    echo "✅ Legacy setup script removed"
else
    echo "❌ Legacy setup script still exists"
    exit 1
fi

if [[ ! -f ".git/hooks/commit-msg" ]]; then
    echo "✅ Legacy commit-msg hook removed"
else
    echo "❌ Legacy commit-msg hook still exists"
    exit 1
fi

if [[ ! -f ".git/hooks/post-checkout" ]]; then
    echo "✅ Legacy post-checkout hook removed"
else
    echo "❌ Legacy post-checkout hook still exists"
    exit 1
fi

if [[ ! -f ".git/hooks/post-merge" ]]; then
    echo "✅ Legacy post-merge hook removed"
else
    echo "❌ Legacy post-merge hook still exists"
    exit 1
fi

if [[ ! -f ".git/hooks/post-commit" ]]; then
    echo "✅ Legacy post-commit hook removed"
else
    echo "❌ Legacy post-commit hook still exists"
    exit 1
fi

echo ""
echo "📋 Test 2: New Hook System"
echo "--------------------------"

if [[ -d ".githooks" ]]; then
    echo "✅ .githooks directory exists"
else
    echo "❌ .githooks directory missing"
    exit 1
fi

if [[ "$(git config --local core.hooksPath)" == ".githooks" ]]; then
    echo "✅ core.hooksPath configured correctly"
else
    echo "❌ core.hooksPath not configured correctly"
    exit 1
fi

if [[ -f ".githooks/commit-msg" ]]; then
    echo "✅ commit-msg hook exists in .githooks"
else
    echo "❌ commit-msg hook missing from .githooks"
    exit 1
fi

if [[ -f ".githooks/pre-commit" ]]; then
    echo "✅ pre-commit hook exists in .githooks"
else
    echo "❌ pre-commit hook missing from .githooks"
    exit 1
fi

if [[ -f ".githooks/post-commit" ]]; then
    echo "✅ post-commit hook exists in .githooks"
else
    echo "❌ post-commit hook missing from .githooks"
    exit 1
fi

if [[ -f ".githooks/post-checkout" ]]; then
    echo "✅ post-checkout hook exists in .githooks"
else
    echo "❌ post-checkout hook missing from .githooks"
    exit 1
fi

if [[ -f ".githooks/post-merge" ]]; then
    echo "✅ post-merge hook exists in .githooks"
else
    echo "❌ post-merge hook missing from .githooks"
    exit 1
fi

echo ""
echo "📋 Test 3: Hook Functionality"
echo "----------------------------"

# Test commit message validation
if echo "test: valid commit message (refs #73)" | .githooks/commit-msg /dev/stdin >/dev/null 2>&1; then
    echo "✅ Commit message validation works (valid message)"
else
    echo "❌ Commit message validation failed (valid message)"
    exit 1
fi

if ! echo "test: invalid commit message" | .githooks/commit-msg /dev/stdin >/dev/null 2>&1; then
    echo "✅ Commit message validation works (invalid message rejected)"
else
    echo "❌ Commit message validation failed (invalid message accepted)"
    exit 1
fi

# Test pre-commit hook
if .githooks/pre-commit >/dev/null 2>&1; then
    echo "✅ Pre-commit hook runs successfully"
else
    echo "❌ Pre-commit hook failed"
    exit 1
fi

echo ""
echo "🎉 All tests passed! Hook consolidation successful!"
echo ""
echo "✅ Legacy hooks removed"
echo "✅ New hook system active"
echo "✅ Auto-configuration working"
echo "✅ Validation functional"
echo ""
echo "💡 Next: Test with fresh clone to verify auto-setup" 