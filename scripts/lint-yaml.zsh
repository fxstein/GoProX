#!/bin/zsh

# YAML Linting Script
# This script lints YAML files and optionally fixes common issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[HEADER]${NC} $1"
}

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    -f, --fix          Attempt to fix common YAML issues
    -s, --strict       Use strict linting rules (fail on warnings)
    -w, --workflows    Only lint workflow files
    -a, --all          Lint all YAML files in the project
    -h, --help         Show this help message

Examples:
    $0                    # Lint workflow files with default rules
    $0 --fix             # Lint and attempt to fix issues
    $0 --strict          # Use strict rules (fail on warnings)
    $0 --all             # Lint all YAML files in the project
    $0 --workflows --fix # Lint and fix only workflow files

EOF
}

# Default values
FIX_MODE=false
STRICT_MODE=true
WORKFLOWS_ONLY=true
LINT_ALL=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--fix)
            FIX_MODE=true
            shift
            ;;
        -s|--strict)
            STRICT_MODE=true
            shift
            ;;
        -w|--workflows)
            WORKFLOWS_ONLY=true
            LINT_ALL=false
            shift
            ;;
        -a|--all)
            LINT_ALL=true
            WORKFLOWS_ONLY=false
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Check if yamllint is installed
if ! command -v yamllint &> /dev/null; then
    print_error "yamllint is not installed"
    echo "Please install it with:"
    echo "  brew install yamllint"
    echo "  or"
    echo "  pip3 install yamllint"
    exit 1
fi

# Function to fix common YAML issues
fix_yaml_issues() {
    local file=$1
    print_status "Attempting to fix common issues in $file"
    
    # Create a backup
    cp "$file" "${file}.backup"
    
    # Fix trailing spaces
    sed -i '' 's/[[:space:]]*$//' "$file"
    
    # Add document start if missing
    if ! head -1 "$file" | grep -q "^---"; then
        sed -i '' '1i\
---
' "$file"
    fi
    
    # Fix truthy values (convert 'true'/'false' strings to true/false)
    sed -i '' "s/: 'true'/: true/g" "$file"
    sed -i '' "s/: 'false'/: false/g" "$file"
    
    # Add newline at end of file if missing
    if [[ $(tail -c1 "$file" | wc -l) -eq 0 ]]; then
        echo "" >> "$file"
    fi
    
    print_status "Applied fixes to $file"
}

# Function to lint a single file
lint_file() {
    local file=$1
    local fix_mode=$2
    
    if [[ ! -f "$file" ]]; then
        print_warning "File not found: $file"
        return 1
    fi
    
    print_status "Linting $file"
    
    # Run yamllint
    if yamllint -c .yamllint "$file"; then
        print_status "✓ $file passed linting"
        return 0
    else
        print_warning "✗ $file has linting issues"
        
        if [[ "$fix_mode" == "true" ]]; then
            fix_yaml_issues "$file"
            
            # Re-lint after fixes
            if yamllint -c .yamllint "$file"; then
                print_status "✓ $file passed linting after fixes"
                return 0
            else
                print_error "✗ $file still has issues after fixes"
                return 1
            fi
        fi
        
        return 1
    fi
}

# Main script logic
main() {
    print_header "YAML Linting Script"
    echo "Mode: $([[ "$FIX_MODE" == "true" ]] && echo "Fix" || echo "Check only")"
    echo "Scope: $([[ "$WORKFLOWS_ONLY" == "true" ]] && echo "Workflows only" || echo "All YAML files")"
    echo "Strict: $([[ "$STRICT_MODE" == "true" ]] && echo "Yes" || echo "No")"
    echo ""
    
    # Determine which files to lint
    if [[ "$WORKFLOWS_ONLY" == "true" ]]; then
        # Use find to get workflow files, handling cases where files don't exist
        files=($(find .github/workflows -name "*.yml" -o -name "*.yaml" 2>/dev/null || true))
    elif [[ "$LINT_ALL" == "true" ]]; then
        files=($(find . -name "*.yml" -o -name "*.yaml" | grep -v node_modules | grep -v .git))
    else
        files=($(find .github/workflows -name "*.yml" -o -name "*.yaml" 2>/dev/null || true))
    fi
    
    # Filter out non-existent files
    existing_files=()
    for file in $files; do
        if [[ -f "$file" ]]; then
            existing_files+=("$file")
        fi
    done
    
    if [[ ${#existing_files[@]} -eq 0 ]]; then
        print_warning "No YAML files found to lint"
        exit 0
    fi
    
    print_status "Found ${#existing_files[@]} YAML file(s) to lint"
    echo ""
    
    # Lint each file
    failed_files=()
    for file in $existing_files; do
        if ! lint_file "$file" "$FIX_MODE"; then
            failed_files+=("$file")
        fi
        echo ""
    done
    
    # Summary
    print_header "Linting Summary"
    echo "Total files: ${#existing_files[@]}"
    echo "Passed: $((${#existing_files[@]} - ${#failed_files[@]}))"
    echo "Failed: ${#failed_files[@]}"
    
    if [[ ${#failed_files[@]} -gt 0 ]]; then
        echo ""
        print_warning "Failed files:"
        for file in $failed_files; do
            echo "  - $file"
        done
        
        if [[ "$STRICT_MODE" == "true" ]]; then
            print_error "Linting failed due to strict mode"
            exit 1
        else
            print_warning "Some files have issues, but continuing due to non-strict mode"
            exit 0
        fi
    else
        print_status "All files passed linting!"
        exit 0
    fi
}

# Run main function
main "$@" 