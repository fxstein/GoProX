# Test Output Management Strategy

## Overview
The `test/imported` and `test/processed` directories contain generated output files that are excluded from git via `.gitignore`. This document explains the strategy for managing these files and compensating for the loss of git-based file comparison capabilities.

## Why Exclude Generated Files?

### Benefits
- **Repository Size**: Prevents large binary files from bloating the git repository
- **Clean History**: Avoids committing temporary test artifacts
- **CI/CD Efficiency**: Reduces clone times and storage requirements
- **Focus**: Keeps the repository focused on source code and test inputs

### Challenges
- **No Git Diff**: Cannot use `git diff` to compare test outputs
- **No History**: Cannot track changes in test outputs over time
- **No Collaboration**: Team members cannot easily share test results

## Compensation Strategy

### 1. File Comparison Framework
We've created `scripts/testing/test-file-comparison.zsh` to provide comprehensive file comparison capabilities:

#### Features
- **Metadata Extraction**: Extract file sizes, hashes, EXIF data, and timestamps
- **File Comparison**: Compare individual files for size, hash, and metadata differences
- **Directory Structure Analysis**: Compare directory structures and file counts
- **Regression Testing**: Create baselines and compare against them

#### Usage Examples
```zsh
# Create a regression baseline
./scripts/testing/test-file-comparison.zsh baseline

# Run regression test against baseline
./scripts/testing/test-file-comparison.zsh test /path/to/baseline

# Compare two files
./scripts/testing/test-file-comparison.zsh compare file1.jpg file2.jpg

# Compare directory structures
./scripts/testing/test-file-comparison.zsh structure dir1 dir2

# Extract metadata from a file
./scripts/testing/test-file-comparison.zsh metadata test.jpg
```

### 2. Regression Testing Workflow

#### Creating Baselines
1. Run GoProX tests to generate output files
2. Create a baseline using the comparison framework
3. Store baseline in `output/regression-baseline/`
4. Commit baseline metadata (not the actual files)

#### Running Regression Tests
1. Run GoProX tests to generate new output files
2. Compare against a previous baseline
3. Generate detailed comparison reports
4. Store results in `output/regression-results/`

#### Baseline Management
- Baselines are timestamped for easy identification
- Multiple baselines can be maintained for different scenarios
- Baselines include metadata, not the actual files
- Baselines can be committed to git for version control

### 3. Alternative Comparison Methods

#### Manual Comparison
```zsh
# Compare file sizes
ls -lh test/processed/2021/20210902/

# Compare file hashes
shasum -a 256 test/processed/2021/20210902/*.jpg

# Compare EXIF data
exiftool test/processed/2021/20210902/*.jpg | grep -E "(File Size|Image Size|Create Date)"
```

#### Automated Scripts
- Use `find` and `stat` to compare file properties
- Use `exiftool` to compare metadata
- Use `diff` to compare text-based reports

### 4. CI/CD Integration

#### GitHub Actions Workflow
```yaml
- name: Run GoProX Tests
  run: ./goprox --test

- name: Create Test Baseline
  run: ./scripts/testing/test-file-comparison.zsh baseline

- name: Upload Test Results
  uses: actions/upload-artifact@v2
  with:
    name: test-results
    path: output/regression-results/
```

#### Baseline Storage
- Store baselines as GitHub artifacts
- Use GitHub releases to maintain baseline history
- Archive old baselines to reduce storage costs

## Best Practices

### 1. Baseline Creation
- Create baselines after successful test runs
- Include system information and GoProX version
- Document any special test conditions
- Use descriptive baseline names

### 2. Regression Testing
- Run regression tests regularly (daily/weekly)
- Compare against multiple baselines
- Investigate any differences found
- Update baselines when changes are intentional

### 3. File Organization
- Keep test outputs organized by date
- Use consistent naming conventions
- Clean up old test outputs regularly
- Archive important test results

### 4. Documentation
- Document baseline creation procedures
- Maintain a log of baseline changes
- Document known differences between baselines
- Keep comparison reports for reference

## Migration from Git-Based Comparison

### Before (with git)
```zsh
# Compare current vs previous commit
git diff HEAD~1 test/processed/

# View file history
git log --follow test/processed/2021/20210902/P_*.jpg

# Revert to previous state
git checkout HEAD~1 test/processed/
```

### After (with comparison framework)
```zsh
# Create baseline
./scripts/testing/test-file-comparison.zsh baseline

# Compare against baseline
./scripts/testing/test-file-comparison.zsh test /path/to/baseline

# View comparison report
cat output/regression-results/latest/comparison-report.txt
```

## Future Enhancements

### 1. Automated Baseline Updates
- Automatically update baselines when tests pass
- Maintain rolling baseline history
- Alert on significant changes

### 2. Visual Comparison Tools
- Generate before/after image comparisons
- Create visual diff reports
- Integrate with image comparison tools

### 3. Performance Monitoring
- Track processing time changes
- Monitor file size trends
- Alert on performance regressions

### 4. Integration with External Tools
- Integrate with image analysis tools
- Connect to metadata databases
- Export results to monitoring systems

## Conclusion

While excluding generated test files from git removes some convenient comparison capabilities, the compensation strategy provides:

1. **Better Performance**: Faster git operations and smaller repository
2. **Comprehensive Comparison**: More detailed analysis than git diff
3. **Regression Testing**: Systematic approach to detecting changes
4. **Flexibility**: Custom comparison logic for specific needs
5. **Scalability**: Handles large files and complex comparisons

The key is to establish good practices for baseline management and regular regression testing to maintain confidence in the test suite.

## Logger Output Management

### Logger File Organization
The logger module generates structured JSON logs that are automatically managed:

#### Log File Locations
- **Application Logs**: `output/logs/goprox-YYYY-MM-DD.log`
- **Test Logs**: `output/test-results/logger-test-YYYY-MM-DD.log`
- **Performance Logs**: `output/logs/performance-YYYY-MM-DD.log`
- **Error Logs**: `output/logs/errors-YYYY-MM-DD.log`

#### Log File Management
- **Automatic Rotation**: Log files are rotated daily
- **Size Limits**: Log files are limited to prevent disk space issues
- **Retention Policy**: Old log files are automatically cleaned up
- **Structured Format**: All logs are JSON-formatted for easy parsing

#### Logger Integration with Test Framework
```zsh
# Logger tests generate structured output
./scripts/testing/run-tests.zsh --logger

# View logger test results
cat output/test-results/logger-test-$(date +%Y-%m-%d).log

# Analyze logger performance
jq '.level == "INFO" and .message | contains("performance")' output/logs/goprox-$(date +%Y-%m-%d).log
```

### Logger Output Comparison
The logger generates consistent, structured output that can be compared across test runs:

#### Baseline Creation for Logger Tests
```zsh
# Create logger baseline
./scripts/testing/test-file-comparison.zsh baseline output/logs/

# Compare logger output
./scripts/testing/test-file-comparison.zsh test /path/to/baseline output/logs/
```

#### Logger Output Validation
- **JSON Format Validation**: Ensure logs are valid JSON
- **Log Level Verification**: Confirm appropriate log levels are used
- **Performance Timing**: Validate timing data accuracy
- **Error Tracking**: Verify error logging and recovery 