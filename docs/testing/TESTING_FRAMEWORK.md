# GoProX Testing Framework

## Overview

The GoProX testing framework provides a comprehensive suite of tests to validate the GoProX CLI tool functionality, CI/CD infrastructure, and development environment. All test scripts follow a standardized structure with proper logging, environmental details, and configurable verbosity levels.

## Test Script Structure

### Standardized Template

All test scripts follow the `test-script-template.zsh` structure with these key components:

1. **Environmental Details** (Always output first)
2. **Configuration** (Command line argument parsing)
3. **Color Definitions** (Consistent color coding)
4. **Logging Functions** (Standardized output)
5. **Test Functions** (Reusable test utilities)
6. **Environment Validation** (Prerequisites check)
7. **Main Test Logic** (Actual test execution)
8. **Test Summary** (Results and recommendations)

### Environmental Details Output

Every test script outputs detailed environmental information at startup:

```
🔍 =========================================
🔍 GoProX Test Script: [script-name]
🔍 =========================================
🔍 Execution Details:
🔍   Script: [script-name]
🔍   Full Path: [absolute-path]
🔍   Working Directory: [current-directory]
🔍   User: [username]
🔍   Host: [hostname]
🔍   Shell: [shell-path]
🔍   ZSH Version: [zsh-version]
🔍   Date: [timestamp]
🔍   Git Branch: [current-branch]
🔍   Git Commit: [commit-hash]
🔍 =========================================
```

## Verbosity Modes

### Default Mode (Verbose)
- **Trigger**: Default behavior, `--verbose` flag
- **Output**: Detailed test progress with INFO level logging
- **Use Case**: Normal testing, CI/CD execution

### Debug Mode
- **Trigger**: `--debug` flag (implies --verbose)
- **Output**: All verbose output plus DEBUG level details
- **Use Case**: Troubleshooting, detailed investigation

### Quiet Mode
- **Trigger**: `--quiet` flag
- **Output**: Minimal output, only final results
- **Use Case**: Automated testing, batch execution

## Logging Levels

### INFO Level (Blue)
- Test progress and section headers
- Environment validation steps
- General execution flow

### SUCCESS Level (Green)
- Passed tests and successful operations
- Final success messages

### WARNING Level (Yellow)
- Non-critical issues or missing optional dependencies
- Recommendations and suggestions

### ERROR Level (Red)
- Failed tests and critical errors
- Issues that prevent successful execution

### DEBUG Level (Purple)
- Detailed command execution
- Internal state information
- Troubleshooting details

## Test Scripts

### Core Validation Scripts

#### `validate-basic.zsh`
**Purpose**: Basic GoProX testing environment and core functionality validation

**Tests**:
- Basic environment setup and dependencies
- GoProX script execution and core functionality
- Test framework and media files
- Git configuration and file tracking
- Documentation and comparison tools

**Usage**:
```bash
# Default verbose mode
./scripts/testing/validate-basic.zsh

# Debug mode for troubleshooting
./scripts/testing/validate-basic.zsh --debug

# Quiet mode for automation
./scripts/testing/validate-basic.zsh --quiet
```

#### `validate-integration.zsh`
**Purpose**: Comprehensive validation including testing setup and CI/CD infrastructure

**Tests**:
- Runs both `validate-basic.zsh` and `validate-ci.zsh`
- Provides unified summary and recommendations
- Orchestrates multiple validation scripts

**Usage**:
```bash
# Run comprehensive validation
./scripts/testing/validate-integration.zsh

# Debug mode for detailed output
./scripts/testing/validate-integration.zsh --debug
```

#### `validate-ci.zsh`
**Purpose**: GitHub Actions workflows and CI/CD infrastructure validation

**Tests**:
- GitHub Actions workflow configuration
- Workflow syntax and triggers
- Test script availability and permissions
- CI environment simulation
- Test output and artifact management
- Git LFS configuration
- Documentation and error handling

**Usage**:
```bash
# Validate CI/CD setup
./scripts/testing/validate-ci.zsh

# Debug mode for workflow analysis
./scripts/testing/validate-ci.zsh --debug
```

### Specialized Test Scripts

#### `test-regression.zsh`
**Purpose**: File comparison and regression testing with real media files

#### `test-integration.zsh`
**Purpose**: Advanced test scenarios and edge cases

#### `test-homebrew.zsh`
**Purpose**: Homebrew formula and multi-channel testing

#### `validate-setup.zsh`
**Purpose**: Release configuration and production readiness validation

## CI/CD Integration

### Workflow Structure

The CI/CD system uses a hierarchical approach:

1. **PR Tests** (`pr-tests.yml`)
   - Fast validation for pull requests
   - Runs `validate-basic.zsh`
   - Duration: ~2-3 minutes

2. **Integration Tests** (`integration-tests.yml`)
   - Full regression testing for main/develop
   - Runs `validate-integration.zsh` and `test-regression.zsh`
   - Duration: ~5-10 minutes

3. **Release Tests** (`release-tests.yml`)
   - Production validation for releases
   - Runs all integration tests plus specialized suites
   - Duration: ~10-15 minutes

### Test Execution in CI

All test scripts in CI:
- Run with explicit `zsh` execution
- Use `--verbose` mode by default
- Output environmental details for debugging
- Provide clear pass/fail results
- Upload artifacts for analysis

## Test Environment Requirements

### Dependencies
- **zsh**: Shell environment (version 5.0+)
- **exiftool**: Media metadata processing
- **jq**: JSON processing and validation
- **git**: Version control and LFS support

### Directory Structure
```
test/
├── originals/          # Test media files
│   ├── HERO9/         # HERO9 test data
│   ├── HERO10/        # HERO10 test data
│   └── HERO11/        # HERO11 test data
├── imported/          # Generated during tests
├── processed/         # Generated during tests
└── archive/          # Generated during tests
```

### Output Management
- All test artifacts go to `output/` directory
- Test results: `output/test-results/`
- Temporary files: `output/test-temp/`
- CI artifacts: Uploaded to GitHub Actions

## Best Practices

### Writing New Test Scripts

1. **Use the template**: Start with `test-script-template.zsh`
2. **Include environmental details**: Always output execution context
3. **Use standardized logging**: Follow the color-coded log levels
4. **Provide descriptions**: Add meaningful descriptions to all tests
5. **Handle errors gracefully**: Use proper exit codes and error messages
6. **Support all verbosity modes**: Implement --verbose, --debug, --quiet

### Test Script Guidelines

1. **Environment validation first**: Check prerequisites before main tests
2. **Clear section organization**: Group related tests logically
3. **Descriptive test names**: Use clear, action-oriented test names
4. **Proper exit codes**: 0 for success, 1 for failure
5. **Comprehensive summaries**: Include what was tested and next steps

### Debugging Test Failures

1. **Use debug mode**: Run with `--debug` for detailed output
2. **Check environmental details**: Verify execution context
3. **Review dependencies**: Ensure all required tools are available
4. **Check permissions**: Verify file and directory permissions
5. **Examine CI logs**: Look for environmental differences

## Troubleshooting

### Common Issues

#### Script Execution Failures
- **Symptom**: Script fails to execute in CI
- **Solution**: Ensure explicit `zsh` execution in workflows
- **Debug**: Check environmental details output

#### Permission Issues
- **Symptom**: "Permission denied" errors
- **Solution**: Run `chmod +x` on test scripts
- **Debug**: Check file permissions in environmental details

#### Missing Dependencies
- **Symptom**: "Command not found" errors
- **Solution**: Install required dependencies (zsh, exiftool, jq)
- **Debug**: Check dependency validation in environment section

#### Test Media Issues
- **Symptom**: Test media files not found
- **Solution**: Ensure Git LFS is properly configured
- **Debug**: Check test media validation in environmental details

### Debug Commands

```bash
# Check script execution
zsh ./scripts/testing/validate-basic.zsh --debug

# Validate environment
zsh ./scripts/testing/validate-ci.zsh --debug

# Test specific functionality
zsh ./scripts/testing/test-regression.zsh --debug

# Check CI simulation
zsh ./scripts/testing/validate-ci.zsh --debug | grep "Ubuntu environment"
```

## Future Enhancements

### Planned Improvements

1. **Parallel Test Execution**: Support for concurrent test runs
2. **Test Result Caching**: Cache results for faster re-runs
3. **Custom Test Suites**: Allow selective test execution
4. **Performance Metrics**: Track test execution times
5. **Test Coverage Reporting**: Measure code coverage

### Integration Opportunities

1. **IDE Integration**: VS Code and other IDE support
2. **Test Result Visualization**: Web-based test result display
3. **Automated Test Generation**: Generate tests from specifications
4. **Continuous Monitoring**: Real-time test health monitoring

## References

- [Test Script Template](../scripts/testing/test-template.zsh)
- [CI/CD Integration Guide](CI_INTEGRATION.md)
- [Test Media Requirements](TEST_MEDIA_FILES_REQUIREMENTS.md)
- [Test Output Management](TEST_OUTPUT_MANAGEMENT.md)
- [GitHub Actions Workflows](../../.github/workflows/) 