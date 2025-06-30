# Test Environment Management Guide

## Overview

This guide ensures that GoProX tests run in clean, predictable environments to avoid endless debugging sessions caused by environment contamination.

## The Problem

Tests can fail or behave unexpectedly when:
- GitHub CLI is authenticated in the test environment
- Environment variables like `HOMEBREW_TOKEN` are set
- CI/CD variables leak into test execution
- Previous test runs leave artifacts

## Solutions

### 1. Isolated Test Environments

Use `create_isolated_test_env()` for tests that need guaranteed clean environments:

```zsh
test_my_function() {
    local isolated_dir
    isolated_dir=$(create_isolated_test_env "my_test_name")
    
    # Run your test in the isolated environment
    output=$("$TEST_SCRIPT" arg1 arg2 2>&1) || exit_code=$?
    
    # Assertions
    assert_exit_code 1 "$exit_code"
    
    # Clean up
    cleanup_isolated_test_env "$isolated_dir"
}
```

### 2. Environment Validation

The test runner automatically validates the environment before running tests:

```bash
# Normal run - will fail if environment is not clean
./scripts/testing/run-tests.zsh --brew

# Force clean mode - continues even with dirty environment
./scripts/testing/run-tests.zsh --brew --force-clean

# Skip environment check entirely
./scripts/testing/run-tests.zsh --brew --skip-env-check
```

### 3. Manual Environment Validation

Check your environment manually:

```zsh
source scripts/testing/test-framework.zsh
validate_clean_test_environment "manual_check"
```

## Best Practices

### For Test Writers

1. **Always use isolated environments** for authentication-dependent tests
2. **Clean up after tests** - use `cleanup_isolated_test_env()`
3. **Test both success and failure paths** - don't assume authentication will always be available
4. **Use descriptive test names** in `create_isolated_test_env()`

### For CI/CD

1. **Set `TEST_ISOLATED_MODE=true`** in CI environments
2. **Unset authentication variables** before running tests
3. **Use `--force-clean`** flag in CI pipelines

### For Local Development

1. **Run `gh auth logout`** before testing if you don't need authentication
2. **Unset environment variables** that might interfere:
   ```bash
   unset HOMEBREW_TOKEN GITHUB_TOKEN GH_TOKEN
   ```
3. **Use `--skip-env-check`** for quick iterations during development

## Environment Variables to Watch

These variables can interfere with tests:

- `HOMEBREW_TOKEN` - Homebrew authentication
- `GITHUB_TOKEN` - GitHub API authentication  
- `GH_TOKEN` - GitHub CLI token
- `GITHUB_ACTIONS` - CI/CD environment indicator
- `CI` - Generic CI indicator
- `CD` - Continuous deployment indicator

## Debugging Environment Issues

If tests are failing unexpectedly:

1. **Check environment validation output**:
   ```bash
   ./scripts/testing/run-tests.zsh --brew --verbose
   ```

2. **Manually validate environment**:
   ```zsh
   source scripts/testing/test-framework.zsh
   validate_clean_test_environment "debug"
   ```

3. **Use isolated mode for specific tests**:
   ```zsh
   # In your test
   local isolated_dir=$(create_isolated_test_env "debug_test")
   # ... test code ...
   cleanup_isolated_test_env "$isolated_dir"
   ```

## Test Runner Options

| Option | Description |
|--------|-------------|
| `--force-clean` | Continue even if environment is not clean |
| `--skip-env-check` | Skip environment validation entirely |
| `--verbose` | Show detailed output including environment info |
| `--debug` | Enable debug mode for troubleshooting |

## Examples

### Clean Authentication Test
```zsh
test_authentication_failure() {
    local isolated_dir=$(create_isolated_test_env "auth_failure")
    
    # This should fail due to no authentication
    output=$("$TEST_SCRIPT" dev 2>&1) || exit_code=$?
    
    assert_contains "$output" "Error: No authentication available"
    assert_exit_code 1 "$exit_code"
    
    cleanup_isolated_test_env "$isolated_dir"
}
```

### CI/CD Test Run
```bash
# In CI pipeline
unset HOMEBREW_TOKEN GITHUB_TOKEN GH_TOKEN
./scripts/testing/run-tests.zsh --all --force-clean
```

### Local Development
```bash
# Quick test iteration
./scripts/testing/run-tests.zsh --brew --skip-env-check

# Full validation
./scripts/testing/run-tests.zsh --brew --verbose
```

## Troubleshooting

### "Test environment is not clean" Error

**Cause**: Environment has authentication or CI variables set

**Solutions**:
1. Use `--force-clean` flag
2. Unset problematic variables: `unset HOMEBREW_TOKEN GITHUB_TOKEN`
3. Log out of GitHub CLI: `gh auth logout`
4. Use `--skip-env-check` for development

### Tests Pass Locally but Fail in CI

**Cause**: Different environment variables between local and CI

**Solutions**:
1. Use isolated test environments in all tests
2. Set `TEST_ISOLATED_MODE=true` in CI
3. Explicitly unset variables in CI before tests

### Inconsistent Test Results

**Cause**: Tests depend on external state (authentication, files, etc.)

**Solutions**:
1. Always use `create_isolated_test_env()` for stateful tests
2. Mock external dependencies
3. Clean up after each test
4. Test both success and failure scenarios

## Summary

- **Always use isolated environments** for authentication tests
- **Validate environment** before running tests
- **Clean up** after tests complete
- **Test both success and failure paths**
- **Use appropriate flags** for different scenarios

Following these practices will eliminate environment-related debugging sessions and ensure reliable, predictable test results.

**Note:** Only tokens and project-wide settings should use environment variables. Interactive control (e.g., non-interactive, auto-confirm) must be set via command-line arguments, not environment variables. 