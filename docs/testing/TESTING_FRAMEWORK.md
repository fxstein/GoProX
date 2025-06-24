# GoProX Comprehensive Testing Framework

## Overview

The GoProX testing framework provides a comprehensive, maintainable approach to testing that addresses the limitations of the current built-in tests. This framework supports both success and failure scenarios, granular testing, and reliable output comparison.

## Current Limitations Addressed

### 1. **Git-based Comparison**
- **Problem**: Current tests rely on `git diff` for output comparison, which is fragile and depends on git state
- **Solution**: Direct file and content comparison using assertion functions

### 2. **Single Monolithic Test**
- **Problem**: One large test that can't isolate specific functionality
- **Solution**: Granular test suites with individual test functions

### 3. **No Failure Testing**
- **Problem**: Only tests success scenarios
- **Solution**: Explicit testing of both success and failure cases

### 4. **No Configuration Testing**
- **Problem**: Can't test configuration file validation
- **Solution**: Dedicated configuration test suite

### 5. **No Unit Testing**
- **Problem**: Can't test individual functions
- **Solution**: Isolated test functions for specific functionality

### 6. **No Test Isolation**
- **Problem**: Tests affect each other
- **Solution**: Each test runs in its own temporary directory

### 7. **No Test Reporting**
- **Problem**: Limited feedback on what failed
- **Solution**: Detailed test reports with pass/fail statistics

## Framework Structure

```
scripts/testing/
├── test-framework.zsh      # Core testing framework
├── test-suites.zsh         # Specific test implementations
└── run-tests.zsh          # Main test runner
```

## Key Features

### 1. **Assertion Functions**
```zsh
assert_equal "expected" "actual" "message"
assert_not_equal "expected" "actual" "message"
assert_file_exists "path/to/file" "message"
assert_file_not_exists "path/to/file" "message"
assert_directory_exists "path/to/dir" "message"
assert_contains "text" "pattern" "message"
assert_exit_code 0 "$?" "message"
```

### 2. **Test Isolation**
- Each test runs in its own temporary directory
- Automatic cleanup after each test
- No interference between tests

### 3. **Comprehensive Reporting**
- Detailed test reports saved to `output/test-results/`
- Pass/fail statistics
- Test execution time tracking
- Colored output for easy reading

### 4. **Test Suites**
- **Configuration Tests**: Validate config file format and content
- **Parameter Processing Tests**: Test command-line argument handling
- **Storage Validation Tests**: Test storage hierarchy and permissions
- **Integration Tests**: Test complete workflows

## Usage

### Running All Tests
```zsh
./scripts/testing/run-tests.zsh
```

### Running Specific Test Suites
```zsh
./scripts/testing/run-tests.zsh --config      # Configuration tests only
./scripts/testing/run-tests.zsh --params      # Parameter tests only
./scripts/testing/run-tests.zsh --storage     # Storage tests only
./scripts/testing/run-tests.zsh --integration # Integration tests only
```

### Verbose Output
```zsh
./scripts/testing/run-tests.zsh --verbose
```

## Test Design Principles

### 1. **Test for Success AND Failure**
Every feature should have tests for both successful operation and failure scenarios:

```zsh
function test_config_validation() {
    # Test success case
    create_test_config "valid.conf" "library=\"~/test\""
    assert_file_exists "valid.conf"
    
    # Test failure case
    create_test_config "invalid.conf" "library="
    # Should detect missing value
}
```

### 2. **Isolated Tests**
Each test should be completely independent:

```zsh
function test_something() {
    # Create test-specific files
    create_test_media_file "test-file.jpg" "content"
    
    # Run test
    assert_file_exists "test-file.jpg"
    
    # Cleanup happens automatically
}
```

### 3. **Descriptive Test Names**
Test names should clearly indicate what is being tested:

```zsh
run_test "config_missing_library" test_config_missing_library "Test configuration with missing library"
```

### 4. **Comprehensive Coverage**
Test all code paths, including edge cases:

- Valid inputs
- Invalid inputs
- Boundary conditions
- Error conditions
- Missing dependencies

## Example Test Implementation

### Configuration Testing
```zsh
function test_config_valid_format() {
    local config_file="test-config.txt"
    local config_content='# GoProX Configuration File
source="."
library="~/test-goprox"
copyright="Test User"
geonamesacct=""
mountoptions=(--archive --import --clean --firmware)'
    
    create_test_config "$config_file" "$config_content"
    
    # Test that config file exists and has correct format
    assert_file_exists "$config_file" "Configuration file should be created"
    assert_contains "$(cat "$config_file")" "source=" "Config should contain source setting"
    assert_contains "$(cat "$config_file")" "library=" "Config should contain library setting"
    
    cleanup_test_files "$config_file"
}
```

### Parameter Processing Testing
```zsh
function test_params_missing_required() {
    # Test that missing required parameters are handled
    local output
    output=$(../goprox --import 2>&1)
    assert_exit_code 1 "$?" "Missing library should exit with code 1"
    assert_contains "$output" "Missing library" "Should show missing library error"
}
```

## Integration with Existing Tests

The framework can coexist with the current built-in tests. The built-in test can be enhanced to use the framework:

```zsh
# In goprox script, replace the current test section:
if [ "$test" = true ]; then
    # Use the comprehensive test framework
    source "./scripts/testing/run-tests.zsh"
    run_all_tests
    exit $?
fi
```

## Adding New Tests

### 1. **Create Test Function**
```zsh
function test_new_feature() {
    # Setup
    create_test_config "test.conf" "library=\"~/test\""
    
    # Test
    assert_file_exists "test.conf"
    
    # Cleanup happens automatically
}
```

### 2. **Add to Test Suite**
```zsh
function test_new_feature_suite() {
    run_test "new_feature_basic" test_new_feature "Test basic new feature functionality"
    run_test "new_feature_error" test_new_feature_error "Test new feature error handling"
}
```

### 3. **Register Suite**
```zsh
# In run-tests.zsh, add to main function:
test_suite "New Feature Tests" test_new_feature_suite
```

## Best Practices

### 1. **Test Organization**
- Group related tests into suites
- Use descriptive test names
- Include both positive and negative test cases

### 2. **Test Data**
- Use minimal, realistic test data
- Create test data programmatically
- Clean up test data automatically

### 3. **Assertions**
- Use specific assertion functions
- Provide clear error messages
- Test one thing per assertion

### 4. **Error Handling**
- Test error conditions explicitly
- Verify error messages
- Test exit codes

### 5. **Performance**
- Keep tests fast
- Avoid unnecessary file I/O
- Use temporary directories efficiently

## Future Enhancements

### 1. **Mock Support**
- Mock external dependencies (exiftool, jq)
- Test error conditions without real failures

### 2. **Performance Testing**
- Measure execution time
- Test with large datasets
- Memory usage monitoring

### 3. **Continuous Integration**
- GitHub Actions integration
- Automated test runs
- Test result reporting

### 4. **Coverage Reporting**
- Code coverage metrics
- Identify untested code paths
- Coverage thresholds

## Conclusion

This comprehensive testing framework addresses all the current limitations while providing a maintainable, extensible foundation for GoProX testing. It supports both success and failure scenarios, provides detailed reporting, and follows established testing best practices.

The framework is designed to be simple to use while providing powerful testing capabilities, making it easy to add new tests and maintain existing ones. 