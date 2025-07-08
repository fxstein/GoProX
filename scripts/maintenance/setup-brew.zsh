#!/bin/zsh

# GoProX Homebrew Dependency Setup Script
# Installs all Homebrew dependencies from the project Brewfile

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_status "🔧 GoProX Homebrew Dependency Setup"
print_status "===================================="

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    print_error "Homebrew is not installed. Please install Homebrew first: https://brew.sh/"
    exit 1
fi

BREWFILE="scripts/maintenance/Brewfile"

if [[ ! -f "$BREWFILE" ]]; then
    print_error "Brewfile not found at $BREWFILE"
    exit 1
fi

print_status "Running: brew bundle --file=$BREWFILE"
brew bundle --file="$BREWFILE"

print_success "All Homebrew dependencies installed!" 