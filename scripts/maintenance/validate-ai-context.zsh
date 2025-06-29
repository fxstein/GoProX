#!/usr/bin/env zsh

# AI Context Validation Script
# Ensures all required documents are available and accessible before AI work begins

set -euo pipefail

# Source the logger
export LOGFILE="output/ai-context-validation.log"
mkdir -p "$(dirname "$LOGFILE")"
source "$(dirname "$0")/../core/logger.zsh"

log_info "Starting AI context validation"

# Configuration
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Required documents
REQUIRED_DOCS=(
    "AI_INSTRUCTIONS.md"
    "docs/architecture/DESIGN_PRINCIPLES.md"
    "docs/release/RELEASE_SUMMARY_INSTRUCTIONS.md"
    "docs/NEXT_STEPS.md"
)

# Optional documents (should exist but not critical)
OPTIONAL_DOCS=(
    "docs/testing/TESTING_FRAMEWORK.md"
    "docs/release/RELEASE_PROCESS.md"
    "CONTRIBUTING.md"
    "README.md"
)

echo "🔍 AI Context Validation"
echo "======================="
echo ""

# Check required documents
echo "📋 Required Documents:"
echo "---------------------"
all_required_exist=true

for doc in "${REQUIRED_DOCS[@]}"; do
    if [[ -f "$PROJECT_ROOT/$doc" ]]; then
        echo "✅ $doc"
        log_info "Required document found: $doc"
    else
        echo "❌ $doc (MISSING)"
        log_error "Required document missing: $doc"
        all_required_exist=false
    fi
done

echo ""

# Check optional documents
echo "📋 Optional Documents:"
echo "---------------------"
for doc in "${OPTIONAL_DOCS[@]}"; do
    if [[ -f "$PROJECT_ROOT/$doc" ]]; then
        echo "✅ $doc"
        log_info "Optional document found: $doc"
    else
        echo "⚠️  $doc (not found)"
        log_warning "Optional document not found: $doc"
    fi
done

echo ""

# Check document sizes and last modified dates
echo "📊 Document Details:"
echo "-------------------"
for doc in "${REQUIRED_DOCS[@]}"; do
    if [[ -f "$PROJECT_ROOT/$doc" ]]; then
        local size=$(wc -c < "$PROJECT_ROOT/$doc")
        local modified=$(stat -f "%Sm" "$PROJECT_ROOT/$doc" 2>/dev/null || stat -c "%y" "$PROJECT_ROOT/$doc" 2>/dev/null)
        echo "📄 $doc ($(numfmt --to=iec $size), modified: $modified)"
    fi
done

echo ""

# Validation result
if [[ "$all_required_exist" == "true" ]]; then
    echo "✅ All required documents are available"
    echo ""
    echo "📖 AI Assistant Reading Checklist:"
    echo "=================================="
    echo "1. Read AI_INSTRUCTIONS.md (this file)"
    echo "2. Read docs/architecture/DESIGN_PRINCIPLES.md"
    echo "3. Read docs/release/RELEASE_SUMMARY_INSTRUCTIONS.md (if working on releases)"
    echo "4. Read docs/NEXT_STEPS.md (if starting new work)"
    echo ""
    echo "🔒 MANDATORY READING CONFIRMATION REQUIRED:"
    echo "==========================================="
    echo "You MUST provide a reading confirmation with summaries before any work."
    echo "See docs/ai/READING_CONFIRMATION_TEMPLATE.md for the required format."
    echo ""
    echo "❌ NO WORK WITHOUT CONFIRMATION - You must read and summarize all documents first!"
    log_info "AI context validation completed successfully"
    exit 0
else
    echo "❌ Some required documents are missing"
    echo "   Please ensure all required documents exist before proceeding"
    log_error "AI context validation failed - missing required documents"
    exit 1
fi 