# Interactive Tests Guide

## Overview

Interactive tests in GoProX are designed to test user-facing functionality that requires user input, such as prompts, confirmations, and interactive workflows. These tests are **automatically skipped** in CI/CD environments and non-interactive modes to prevent blocking automated test runs.

## Purpose

This guide explains how interactive tests work, how to run them, and how they integrate with the automated testing pipeline. It provides best practices for writing and maintaining interactive tests.

## Use When

- Understanding how interactive tests behave in different environments
- Writing new interactive tests
- Troubleshooting interactive test issues
- Setting up automated test runs that exclude interactive tests
- Running interactive tests locally for development

## Interactive Test Scripts

### Current Interactive Tests

| Script | Purpose | Auto-Skip Behavior | Additional Flags |
|--------|---------|-------------------|------------------|
| `test-interactive-prompt.zsh` | Basic interactive prompt testing | ✅ CI/non-interactive | None |
| `test-safe-confirm-interactive.zsh` | Safe confirmation function testing | ✅ CI/non-interactive | None |
| `test-safe-prompt.zsh` | Comprehensive safe prompt testing | ✅ CI/non-interactive | `--non-interactive`, `--auto-confirm` |

### Test Descriptions

#### `test-interactive-prompt.zsh`
- **Purpose**: Test basic interactive prompt functionality
- **Behavior**: Prompts user for confirmation and tests user input handling
- **Use Case**: Validating basic interactive prompt behavior

#### `test-safe-confirm-interactive.zsh`
- **Purpose**: Test safe confirmation functions with user interaction
- **Behavior**: Tests `safe_confirm` function with real user input
- **Use Case**: Validating interactive confirmation workflows

#### `test-safe-prompt.zsh`
- **Purpose**: Comprehensive testing of safe prompt functions
- **Behavior**: Tests multiple prompt types (confirm, input, timeout)
- **Use Case**: Full validation of safe prompt functionality
- **Special Features**: Supports `--non-interactive` and `--auto-confirm` flags

## Interactive Test Design Pattern

All interactive tests follow this standardized pattern:

```zsh
#!/bin/zsh
# INTERACTIVE TEST: Requires user input. Skipped in CI/non-interactive mode.

if [[ "$CI" == "true" || "$NON_INTERACTIVE" == "true" ]]; then
  echo "Skipping interactive test: $0 (non-interactive mode detected)"
  exit 0
fi

# ... test implementation ...
```

### Key Components

1. **Header Comment**: Clearly marks the test as interactive
2. **Skip Logic**: Checks for CI/non-interactive environment variables
3. **Graceful Exit**: Exits cleanly with status 0 when skipped
4. **Standardized Message**: Uses consistent skip message format

## Environment Variables

Interactive tests respect these environment variables:

### `CI=true`
- **Purpose**: Indicates running in CI/CD environment
- **Effect**: Automatically skips interactive tests
- **Set By**: GitHub Actions and other CI systems

### `NON_INTERACTIVE=true`
- **Purpose**: Forces non-interactive mode
- **Effect**: Skips interactive tests
- **Set By**: Manual configuration or automated test runners

### `AUTO_CONFIRM=true`
- **Purpose**: Auto-confirms all prompts (where supported)
- **Effect**: Bypasses user input requirements
- **Set By**: Manual configuration or test automation

## Running Interactive Tests

### Local Development (Interactive Mode)

For full interactive testing with user input:

```bash
# Run basic interactive prompt test
./scripts/testing/test-interactive-prompt.zsh

# Run safe confirmation test
./scripts/testing/test-safe-confirm-interactive.zsh

# Run comprehensive safe prompt test
./scripts/testing/test-safe-prompt.zsh
```

### Automated/CI Mode

For automated testing that skips interactive tests:

```bash
# Set environment to skip interactive tests
export NON_INTERACTIVE=true
./scripts/testing/test-interactive-prompt.zsh
# Output: "Skipping interactive test: ... (non-interactive mode detected)"

# Or use CI environment
export CI=true
./scripts/testing/test-safe-confirm-interactive.zsh
# Output: "Skipping interactive test: ... (non-interactive mode detected)"
```

### Automated Testing with Flags

Some interactive tests support flags for automated testing:

```bash
# Use built-in non-interactive flags
./scripts/testing/test-safe-prompt.zsh --non-interactive

# Auto-confirm all prompts
./scripts/testing/test-safe-prompt.zsh --auto-confirm

# Combine flags
./scripts/testing/test-safe-prompt.zsh --non-interactive --auto-confirm
```

## Integration with CI/CD

### Automatic Exclusion

Interactive tests are **automatically excluded** from CI/CD pipelines:

- **GitHub Actions**: `CI=true` environment variable is set automatically
- **Local automation**: Set `NON_INTERACTIVE=true` for automated runs
- **Test runners**: Interactive tests are skipped in batch execution

### CI/CD Workflow Integration

```yaml
# Example GitHub Actions workflow
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Tests
        run: |
          # CI=true is automatically set by GitHub Actions
          ./scripts/testing/validate-basic.zsh
          ./scripts/testing/test-integration.zsh
          # Interactive tests are automatically skipped
```

### Test Runner Integration

```bash
# Example test runner script
#!/bin/bash
export NON_INTERACTIVE=true

echo "Running automated test suite..."
./scripts/testing/validate-basic.zsh
./scripts/testing/test-integration.zsh
./scripts/testing/test-regression.zsh
# Interactive tests are automatically skipped
```

## Best Practices

### Writing Interactive Tests

1. **Always include skip logic**: Every interactive test must check for CI/non-interactive mode
2. **Clear documentation**: Mark tests as interactive in the header comment
3. **Provide alternatives**: Support flags for automated testing when possible
4. **Graceful degradation**: Tests should exit cleanly when skipped
5. **Consistent messaging**: Use standardized skip messages

### Example: New Interactive Test

```zsh
#!/bin/zsh
# INTERACTIVE TEST: Requires user input. Skipped in CI/non-interactive mode.

if [[ "$CI" == "true" || "$NON_INTERACTIVE" == "true" ]]; then
  echo "Skipping interactive test: $0 (non-interactive mode detected)"
  exit 0
fi

# Test implementation
echo "This is an interactive test that requires user input"
read -p "Enter your name: " name
echo "Hello, $name!"

# Optional: Support non-interactive flags
if [[ "$1" == "--non-interactive" ]]; then
  echo "Running in non-interactive mode with default values"
  name="Test User"
  echo "Hello, $name!"
fi
```

### Testing Interactive Tests

```bash
# Test interactive behavior
./scripts/testing/test-interactive-prompt.zsh

# Test skip behavior
NON_INTERACTIVE=true ./scripts/testing/test-interactive-prompt.zsh

# Test CI skip behavior
CI=true ./scripts/testing/test-interactive-prompt.zsh
```

## Troubleshooting

### Common Issues

#### Test Hangs in CI
- **Symptom**: Interactive test blocks CI execution
- **Cause**: Missing skip logic in interactive test
- **Solution**: Add CI/non-interactive mode check
- **Debug**: Check if `CI=true` or `NON_INTERACTIVE=true` is set

#### Test Fails in Non-Interactive Mode
- **Symptom**: Test fails when run with `NON_INTERACTIVE=true`
- **Cause**: Test doesn't handle non-interactive mode properly
- **Solution**: Add proper skip logic or non-interactive alternatives
- **Debug**: Run with `--debug` flag to see execution flow

#### User Input Not Working
- **Symptom**: Test doesn't accept user input
- **Cause**: Test running in non-interactive environment
- **Solution**: Ensure test is running in interactive terminal
- **Debug**: Check `is_interactive` function or terminal type

### Debug Commands

```bash
# Check environment variables
echo "CI: $CI"
echo "NON_INTERACTIVE: $NON_INTERACTIVE"

# Test skip logic
CI=true ./scripts/testing/test-interactive-prompt.zsh

# Test interactive behavior
./scripts/testing/test-interactive-prompt.zsh

# Debug with verbose output
./scripts/testing/test-safe-prompt.zsh --debug
```

## Future Enhancements

### Planned Improvements

1. **Enhanced Flag Support**: More interactive tests supporting `--non-interactive` and `--auto-confirm`
2. **Test Result Reporting**: Better reporting for skipped interactive tests
3. **Interactive Test Categories**: Categorize interactive tests by type (prompt, confirmation, input)
4. **Mock User Input**: Support for mocking user input in automated tests

### Integration Opportunities

1. **IDE Integration**: VS Code and other IDE support for interactive tests
2. **Test Result Visualization**: Web-based display of interactive test results
3. **Automated Test Generation**: Generate interactive test scenarios
4. **Continuous Monitoring**: Real-time monitoring of interactive test health

## References

- [Testing Framework](TESTING_FRAMEWORK.md#interactive-tests)
- [Test Script Template](../scripts/testing/test-template.zsh)
- [CI/CD Integration Guide](CI_CD_INTEGRATION.md)
- [Safe Prompt Functions](../scripts/core/safe-prompt.zsh)

---

**Last Updated**: January 2025  
**Maintainer**: GoProX Development Team  
**Version**: 1.0.0 