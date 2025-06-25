#!/bin/zsh

# GoProX YAML Formatting Fixer
# Automatically fixes common YAML formatting issues in workflow files

set -e

echo "🔧 Fixing YAML formatting issues..."

# Check if yamllint is available
if ! command -v yamllint >/dev/null 2>&1; then
    echo "❌ ERROR: yamllint is not installed"
    echo "Please install yamllint: pip install yamllint"
    exit 1
fi

# Find all workflow files
workflow_files=($(find .github/workflows/ -name "*.yml" 2>/dev/null))

if [[ ${#workflow_files[@]} -eq 0 ]]; then
    echo "❌ No workflow files found in .github/workflows/"
    exit 1
fi

echo "📋 Found ${#workflow_files[@]} workflow file(s)"

# Fix common issues
fixed_files=0
for file in "${workflow_files[@]}"; do
    echo "🔧 Processing $file..."
    
    # Create a backup
    cp "$file" "${file}.bak"
    
    # Fix trailing spaces
    sed -i '' 's/[[:space:]]*$//' "$file"
    
    # Ensure newline at end of file
    if [[ $(tail -c1 "$file" 2>/dev/null | wc -l) -eq 0 ]]; then
        echo "" >> "$file"
    fi
    
    # Check if file was actually modified
    if ! diff -q "${file}.bak" "$file" >/dev/null 2>&1; then
        echo "  ✅ Fixed formatting issues in $file"
        fixed_files=$((fixed_files + 1))
    else
        echo "  ℹ️  No changes needed for $file"
    fi
    
    # Remove backup
    rm "${file}.bak"
done

echo ""
echo "✅ Fixed formatting in $fixed_files file(s)"

# Run final lint check
echo ""
echo "🔍 Running final YAML lint check..."
lint_errors=0
for file in "${workflow_files[@]}"; do
    if ! yamllint -f parsable -c .yamllint "$file" >/dev/null 2>&1; then
        echo "❌ YAML linting still failed for $file:"
        yamllint -f parsable -c .yamllint "$file"
        lint_errors=$((lint_errors + 1))
    else
        echo "  ✅ $file passed YAML linting"
    fi
done

if [[ $lint_errors -gt 0 ]]; then
    echo ""
    echo "⚠️  Some YAML issues remain that require manual fixing:"
    echo "  - Key ordering issues"
    echo "  - Unquoted strings"
    echo "  - Line length issues"
    echo ""
    echo "You can run 'yamllint -f parsable -c .yamllint .github/workflows/' to see all remaining issues."
    exit 1
fi

echo ""
echo "🎉 All YAML files are now properly formatted!" 