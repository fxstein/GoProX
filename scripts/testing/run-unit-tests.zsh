#!/bin/zsh

#
# run-unit-tests.zsh: Run all unit tests for GoProX
#
# Copyright (c) 2021-2025 by Oliver Ratzesberger
#
# This script runs all unit tests including logger and firmware summary tests.
# It's designed for CI/CD workflows where unit tests must pass before integration tests.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "${BLUE}🧪 GoProX Unit Test Runner${NC}"
echo "=============================="
echo ""

# Change to project root
cd "$PROJECT_ROOT"

# Pass through all command line arguments to the main test runner
local test_args="$@"

# Run logger unit tests
echo "${YELLOW}Running Logger Unit Tests...${NC}"
if "$SCRIPT_DIR/run-tests.zsh" --logger $test_args; then
    echo "${GREEN}✅ Logger unit tests passed${NC}"
else
    echo "${RED}❌ Logger unit tests failed${NC}"
    exit 1
fi

echo ""

# Run firmware summary unit tests
echo "${YELLOW}Running Firmware Summary Unit Tests...${NC}"
if "$SCRIPT_DIR/run-tests.zsh" --firmware-summary $test_args; then
    echo "${GREEN}✅ Firmware summary unit tests passed${NC}"
else
    echo "${RED}❌ Firmware summary unit tests failed${NC}"
    exit 1
fi

echo ""
echo "${GREEN}🎉 All unit tests passed!${NC}" 