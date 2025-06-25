#!/bin/zsh

# GoProX YAML Formatting Fixer
# Automatically fixes common YAML formatting issues in workflow files

set -e

echo "🔧 GoProX YAML Formatting Fixer"
echo "================================"
echo ""

# Check if yamllint is available
if ! command -v yamllint >/dev/null 2>&1; then
    echo "❌ ERROR: yamllint is not installed"
    echo "Please install yamllint: pip install yamllint"
    exit 1
fi

# Get all workflow files
workflow_files=(.github/workflows/*.yml)

if [[ ${#workflow_files[@]} -eq 0 ]]; then
    echo "❌ No workflow files found in .github/workflows/"
    exit 1
fi

echo "📋 Found ${#workflow_files[@]} workflow files:"
for file in $workflow_files; do
    echo "  - $file"
done
echo ""

# Function to fix common YAML issues
fix_yaml_file() {
    local file="$1"
    local temp_file="${file}.tmp"
    local original_file="${file}.bak"
    
    echo "🔧 Fixing $file..."
    
    # Create backup
    cp "$file" "$original_file"
    
    # Read the file and apply fixes
    {
        # Remove trailing spaces and ensure newline at end
        cat "$file" | sed 's/[[:space:]]*$//' | sed '$a\'
    } > "$temp_file"
    
    # Replace original with fixed version
    mv "$temp_file" "$file"
    
    echo "  ✅ Fixed trailing spaces and ensured newline at end"
}

# Fix each workflow file
for file in $workflow_files; do
    fix_yaml_file "$file"
done

echo ""
echo "🔍 Running YAML linting to check results..."

# Run yamllint to check if issues are resolved
lint_errors=0
for file in $workflow_files; do
    echo "  Checking $file..."
    if ! yamllint -f parsable -c .yamllint "$file" >/dev/null 2>&1; then
        echo "  ⚠️  Still has issues:"
        yamllint -f parsable -c .yamllint "$file" | head -5
        lint_errors=$((lint_errors + 1))
    else
        echo "  ✅ All issues resolved"
    fi
done

echo ""
if [[ $lint_errors -eq 0 ]]; then
    echo "🎉 All YAML formatting issues have been automatically fixed!"
    echo "✅ All workflow files now pass yamllint validation"
    
    # Clean up backups
    for file in $workflow_files; do
        rm -f "${file}.bak"
    done
    echo "🗑️  Cleaned up backup files"
else
    echo "⚠️  Some issues remain that require manual fixing:"
    echo "   - Key ordering issues"
    echo "   - Unquoted string values"
    echo "   - Line length issues"
    echo ""
    echo "You can run 'yamllint -f parsable -c .yamllint .github/workflows/' to see remaining issues."
    echo "Backup files (.bak) have been preserved in case you need to revert."
fi

echo ""
echo "📝 Next steps:"
echo "1. Review the changes: git diff .github/workflows/"
echo "2. Test the pre-commit hook: .git/hooks/pre-commit"
echo "3. Commit the changes when ready" 