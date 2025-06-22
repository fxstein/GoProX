#!/bin/zsh

# Setup pre-commit hooks for YAML linting
# This script installs pre-commit hooks to automatically lint YAML files

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "Not in a git repository"
    exit 1
fi

# Check if yamllint is installed
if ! command -v yamllint &> /dev/null; then
    print_warning "yamllint is not installed"
    echo "Installing yamllint..."
    if command -v brew &> /dev/null; then
        brew install yamllint
    elif command -v pip3 &> /dev/null; then
        pip3 install yamllint
    else
        print_error "Cannot install yamllint. Please install it manually:"
        echo "  brew install yamllint"
        echo "  or"
        echo "  pip3 install yamllint"
        exit 1
    fi
fi

# Create .git/hooks directory if it doesn't exist
mkdir -p .git/hooks

# Create pre-commit hook
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/zsh

# Pre-commit hook for YAML linting

# Check if yamllint is available
if ! command -v yamllint &> /dev/null; then
    echo "Warning: yamllint not found. Skipping YAML linting."
    exit 0
fi

# Get list of staged YAML files
yaml_files=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(yml|yaml)$')

if [[ -z "$yaml_files" ]]; then
    echo "No YAML files staged. Skipping linting."
    exit 0
fi

echo "Linting staged YAML files..."

# Lint each staged YAML file
for file in $yaml_files; do
    if [[ -f "$file" ]]; then
        echo "Linting $file..."
        if ! yamllint -c .yamllint "$file"; then
            echo "YAML linting failed for $file"
            echo "Please fix the issues and try again."
            exit 1
        fi
    fi
done

echo "YAML linting passed!"
EOF

# Make the hook executable
chmod +x .git/hooks/pre-commit

print_status "Pre-commit hook installed successfully!"
print_status "The hook will now automatically lint YAML files before each commit."
print_status "To disable temporarily, use: git commit --no-verify" 