# GoProX Automated Release Process

This document describes the automated release process for GoProX, which handles version bumping, testing, packaging, and distribution.

## Overview

The release process consists of several components:

1. **Release Automation Workflow** - GitHub Actions workflow that handles the entire release process
2. **Manual Release Scripts** - Helper scripts for manual release management
3. **Homebrew Integration** - Automatic updates to the Homebrew formula

## Components

### 1. Release Automation Workflow (`.github/workflows/release-automation.yml`)

**Trigger**: Manual dispatch via GitHub CLI or GitHub Actions UI

**Jobs**:
- **Validate Version**: Ensures version format is correct and matches the `goprox` file
- **Run Tests**: Executes GoProX tests to ensure quality
- **Build Packages**: Creates release tarball and calculates SHA256
- **Generate Release Notes**: Creates changelog from commits and issues
- **Create Release**: Creates GitHub release with assets and correct SHA256
- **Update Homebrew**: Updates the Homebrew formula with proper SHA256 validation
- **Dry Run Summary**: Shows what would happen in dry-run mode

**SHA256 Handling**:
The workflow now properly handles SHA256 calculations to prevent Homebrew upgrade failures:
- **GitHub Tarball SHA256**: Uses the GitHub-generated tarball SHA256 for Homebrew formula updates
- **Retry Mechanism**: Includes retry logic with delays to ensure GitHub tarball availability
- **Validation**: Validates SHA256 values to prevent empty or invalid responses
- **Propagation Delay**: Waits for GitHub release propagation before calculating SHA256

**Inputs**:
- `version`: Version to release (e.g., "00.61.00")
- `prev_version`: Previous version for changelog generation
- `dry_run`: Whether to perform a dry run (default: false)

### 2. Manual Release Scripts

All release-related scripts are located in the `scripts/release/` directory for better organization.

#### `scripts/release/release.zsh`

A comprehensive script for triggering releases manually.

**Features**:
- Automatic version detection from `goprox` file
- Automatic previous version detection from git tags
- Version format validation
- GitHub CLI integration
- Dry-run support
- Interactive confirmation (bypass with --force)

**Usage**:
```zsh
# Basic usage (auto-detects versions)
./scripts/release/release.zsh

# Specify versions manually
./scripts/release/release.zsh --version 00.61.00 --prev 00.60.00

# Dry run
./scripts/release/release.zsh --dry-run

# Force (skip confirmation)
./scripts/release/release.zsh --force

# Help
./scripts/release/release.zsh --help
```

#### `scripts/release/bump-version.zsh`

A script for bumping the version in the `goprox` file.

**Features**:
- Version format validation
- Automatic commit and push options
- Interactive confirmation (bypass with --force)
- Cross-platform sed compatibility
- **Auto-increment functionality** - Automatically increment patch version by 1
- **Backward compatibility** - Still supports manual version specification

**Usage**:
```zsh
# Auto-increment patch version (NEW!)
./scripts/release/bump-version.zsh --auto --push

# Manual version bump
./scripts/release/bump-version.zsh 00.61.00

# With custom commit message
./scripts/release/bump-version.zsh --message "Release v00.61.00 with new features" 00.61.00

# Auto-commit
./scripts/release/bump-version.zsh --commit 00.61.00

# Auto-commit and push
./scripts/release/bump-version.zsh --push 00.61.00

# Force (skip confirmation)
./scripts/release/bump-version.zsh --auto --push --force

# Help
./scripts/release/bump-version.zsh --help
```

**Auto-increment Mode**:
The `--auto` option automatically increments the patch version by 1. For example:
- Current version: `01.00.01` → New version: `01.00.02`
- Current version: `00.61.00` → New version: `00.61.01`

**Note:** The `--force` option skips the manual confirmation prompt and proceeds automatically. This is useful for automation or scripting scenarios.

#### `scripts/release/monitor-release.zsh`

A real-time monitoring script for tracking release workflow progress.

**Features**:
- Real-time workflow status monitoring
- Professional formatted output with box-drawing borders
- Job status tracking with emoji indicators
- Automatic summary generation
- Cursor IDE compatibility (no color codes)
- Summary file generation for reference

**Usage**:
```zsh
# Monitor the latest release workflow
./scripts/release/monitor-release.zsh

# Test output formatting
./scripts/release/monitor-release.zsh --test-output
```

**Output Features**:
- **Workflow Status**: Shows current status, conclusion, duration, branch, and commit
- **Job Progress**: Real-time job status with visual indicators (✅ ❌ 🔄 ⏳)
- **Summary Box**: Professional formatted summary with next steps
- **File Output**: Saves summary to `output/release-summary.txt` for reference

**Job Status Indicators**:
- ✅ **Success**: Job completed successfully
- ❌ **Failure**: Job failed
- 🔄 **Running**: Job currently in progress
- ⏳ **Waiting**: Job queued or waiting

#### `scripts/release/lint-yaml.zsh`

A YAML linting script for maintaining code quality.

**Features**:
- Lint GitHub Actions workflows and other YAML files
- Auto-fix capabilities for common issues
- Strict mode for CI/CD environments
- Project-specific linting rules

**Usage**:
```zsh
# Lint workflow files only
./scripts/release/lint-yaml.zsh

# Lint and attempt to fix issues
./scripts/release/lint-yaml.zsh --fix

# Lint all YAML files in the project
./scripts/release/lint-yaml.zsh --all

# Use strict mode (fail on warnings)
./scripts/release/lint-yaml.zsh --strict
```

#### `scripts/release/setup-pre-commit.zsh`

A script for setting up pre-commit hooks for YAML linting.

**Features**:
- Installs `yamllint` if not present
- Creates pre-commit hook for YAML validation
- Prevents commits with YAML syntax issues

**Usage**:
```zsh
# Install pre-commit hook
./scripts/release/setup-pre-commit.zsh
```

## Release Workflow

### Automatic Release (Recommended)

1. **Bump Version**: Use the auto-increment version bump script
   ```zsh
   ./scripts/release/bump-version.zsh --auto --push
   ```

2. **Trigger Release**: Use the release script to create the GitHub release
   ```zsh
   ./scripts/release/release.zsh
   ```

3. **Monitor**: Watch the GitHub Actions tab for progress

### Manual Release

1. **Bump Version**: Update the version in `goprox` file
   ```zsh
   # Auto-increment (recommended)
   ./scripts/release/bump-version.zsh --auto --push
   
   # Or manual version
   ./scripts/release/bump-version.zsh --push 00.61.00
   ```

2. **Trigger Release**: Use the release script (if not using --push above)
   ```zsh
   ./scripts/release/release.zsh --version 00.61.00 --prev 00.60.00
   ```

### Dry Run

Always test the release process with a dry run first:

```zsh
./scripts/release/release.zsh --dry-run
```

This will:
- Validate the version
- Run tests
- Build packages
- Generate release notes
- Show what would happen without creating an actual release

## Version Format

Versions must follow the format: `XX.XX.XX`

Examples:
- `00.61.00`
- `01.00.00`
- `02.15.30`

## Prerequisites

### For Releases

1. **GitHub Actions**: Must be enabled for the repository
2. **GitHub CLI**: Must be installed and authenticated
   ```zsh
   brew install gh
   gh auth login
   ```
3. **Homebrew Tap**: The `fxstein/homebrew-fxstein` repository must exist
4. **Scripts**: Make sure the scripts are executable
   ```zsh
   chmod +x scripts/release/*.zsh
   ```

## Output Directory

The project uses an `output/` directory for transient files that are generated during script execution:

- **`output/release-summary.txt`**: Summary files from release monitoring
- **`output/filter-repo.log`**: Log files from git filter-repo operations
- **`output/.filter-repo.pid`**: PID files for background processes

This directory is automatically created by scripts and is ignored by git (added to `.gitignore`).

## Troubleshooting

### Common Issues

1. **Version Format Error**
   - Ensure version follows `XX.XX.XX` format
   - Check for extra spaces or characters

2. **GitHub CLI Not Authenticated**
   ```zsh
   gh auth status
   gh auth login
   ```

3. **Workflow Fails**
   - Check GitHub Actions logs for specific errors
   - Ensure all dependencies are available
   - Verify Homebrew tap repository exists

4. **Homebrew Update Fails**
   - Check if `fxstein/homebrew-fxstein` repository exists
   - Verify GitHub token has write access to the tap repository

5. **SHA256 Mismatch Errors**
   - **Problem**: `Error: SHA256 mismatch` when running `brew upgrade goprox`
   - **Cause**: Homebrew formula has incorrect SHA256 for the GitHub tarball
   - **Solution**: 
     - Clear Homebrew cache: `rm /Users/username/Library/Caches/Homebrew/downloads/*--GoProX-*.tar.gz`
     - Update Homebrew: `brew update`
     - Try upgrade again: `brew upgrade goprox`
   - **Prevention**: The automated workflow now uses correct GitHub tarball SHA256

6. **Release Workflow SHA256 Failures**
   - **Problem**: Workflow fails during SHA256 calculation
   - **Cause**: GitHub tarball not immediately available after release creation
   - **Solution**: The workflow now includes retry mechanisms and propagation delays
   - **Manual Fix**: If workflow fails, wait 5-10 minutes and retry the workflow

### Debug Mode

For debugging, you can run individual components:

```zsh
# Test version detection
grep "__version__=" goprox

# Test package creation
tar -czf test.tar.gz --exclude='.git' --exclude='.github' .

# Test SHA256 calculation
shasum -a 256 test.tar.gz
```

## Security Considerations

1. **GitHub Token**: The workflow uses `GITHUB_TOKEN` which has limited permissions
2. **Homebrew Tap**: Requires separate authentication for the tap repository
3. **Version Validation**: All versions are validated before processing
4. **Dry Run**: Always use dry-run mode for testing

## Future Enhancements

Potential improvements to the release process:

1. **Slack/Discord Notifications**: Notify team when releases are created
2. **Release Notes Templates**: More sophisticated changelog generation
3. **Multi-platform Packages**: Support for different operating systems
4. **Release Signing**: GPG signing of release packages
5. **Automated Testing**: More comprehensive test suites
6. **Release Scheduling**: Scheduled releases for specific times

## Support

For issues with the release process:

1. Check the GitHub Actions logs
2. Review this documentation
3. Test with dry-run mode
4. Create an issue in the repository

## Changelog

- **v1.0.0**: Initial automated release process
- Added version bump detection
- Added comprehensive release automation
- Added manual release scripts
- Added Homebrew integration
- **v1.1.0**: Enhanced release reliability and automation
- Added auto-increment functionality to bump-version script (`--auto` option)
- Fixed SHA256 mismatch issues in automated workflow
- Added retry mechanisms and propagation delays for GitHub tarball availability
- Improved SHA256 validation and error handling
- Enhanced Homebrew formula update reliability
- Updated documentation with troubleshooting guides

## Issue Reference Format

When referencing issues in commit messages and documentation, use the following format:

- **Single issue**: `(refs #n)` - e.g., `(refs #20)`
- **Multiple issues**: `(refs #n #n ...)` - e.g., `(refs #20 #25 #30)`

## YAML Linting Automation

To maintain code quality and prevent YAML syntax issues, the project includes automated YAML linting:

### 1. GitHub Actions Linting Workflow

A dedicated workflow (`.github/workflows/lint.yml`) automatically lints YAML files on every PR and push:
- Runs on all `.yml` and `.yaml` files
- Uses `yamllint` with project-specific rules
- Provides warnings for style issues
- Fails on critical syntax errors

### 2. Local Development Tools

#### Pre-commit Hook
Install automatic linting before commits:
```zsh
./scripts/release/setup-pre-commit.zsh
```

This will:
- Install `yamllint` if not present
- Create a pre-commit hook that lints staged YAML files
- Prevent commits with YAML issues

#### Manual Linting Script
Lint YAML files on demand:
```zsh
# Lint workflow files only
./scripts/release/lint-yaml.zsh

# Lint and attempt to fix issues
./scripts/release/lint-yaml.zsh --fix

# Lint all YAML files in the project
./scripts/release/lint-yaml.zsh --all

# Use strict mode (fail on warnings)
./scripts/release/lint-yaml.zsh --strict
```

### 3. YAML Linting Rules

The project uses a custom `.yamllint` configuration with:
- **Line length**: 120 characters (warning)
- **Document start**: Required (warning)
- **Trailing spaces**: Error
- **Truthy values**: Warning (convert 'true'/'false' to true/false)
- **Indentation**: 2 spaces (error)
- **Empty lines**: Max 1 (warning)

### 4. IDE Integration

For Cursor IDE and other editors:
- Install `yamllint` extension/plugin
- Configure to use the project's `.yamllint` file
- Enable real-time linting feedback

## Version Bumping

### Automatic Version Bumping

The `bump-version.zsh` script can automatically increment the version:

```zsh
./scripts/release/bump-version.zsh --auto
```

**Important**: The `--auto` flag alone only increments the version and updates the file. It does NOT automatically commit or push the changes.

To automatically commit and push:
```zsh
./scripts/release/bump-version.zsh --auto --push
```

This will:
1. Increment the patch version (e.g., 01.00.03 → 01.00.04)
2. Update the `__version__` variable in `goprox`
3. Create a commit with the version bump
4. Push the commit to the repository
5. Create a tag for the new version

### Manual Version Bumping

For specific version numbers:

```zsh
./scripts/release/bump-version.zsh --version 01.00.04
```

To commit and push manually:
```zsh
./scripts/release/bump-version.zsh --version 01.00.04 --push
```

### Bump Script Options

- **`--auto`**: Auto-increment patch version (does not commit/push)
- **`--commit`**: Automatically commit the version change
- **`--push`**: Automatically commit AND push the version change
- **`--message "custom message"`**: Use custom commit message
- **`--help`**: Show usage information

**Note**: Always use `--push` when preparing for a release to ensure the version bump is pushed to the repository before triggering the release workflow.

## Release Process

### 1. Version Bump

First, bump the version using the automatic or manual method above. **Remember to use `--push` to ensure the version is committed and pushed to the repository.**

### 2. Automated Release Workflow

The GitHub Actions workflow (`release-automation.yml`) handles:

- **Validation**: Checks version format and consistency
- **Testing**: Runs GoProX tests
- **Packaging**: Creates release tarball
- **Release Notes**: Generates changelog from commits
- **GitHub Release**: Creates the release with assets
- **Homebrew Update**: Updates the Homebrew formula with correct SHA256

### 3. Workflow Inputs

When manually triggering the workflow:

- **version**: The version to release (e.g., 01.00.04)
- **prev_version**: Previous version for changelog (e.g., 01.00.03)
- **dry_run**: Set to 'true' for testing without creating a release

### 4. Monitoring Release Progress

Use the monitor script to track release workflow progress in real-time:

```zsh
# Monitor the latest release workflow
./scripts/release/monitor-release.zsh
```

The monitor provides:
- **Real-time status updates** with professional formatting
- **Job progress tracking** with visual indicators
- **Automatic summary generation** when workflow completes
- **Summary file output** for reference (`output/release-summary.txt`)

**Job Status Indicators**:
- ✅ **Success**: Job completed successfully
- ❌ **Failure**: Job failed
- 🔄 **Running**: Job currently in progress
- ⏳ **Waiting**: Job queued or waiting

### 5. SHA256 Calculation Fix

The workflow now correctly calculates SHA256 by:
1. Waiting for GitHub release propagation (60 seconds)
2. Downloading the tarball from codeload URL (same as Homebrew)
3. Calculating SHA256 from the actual downloaded file
4. Updating the Homebrew formula with the correct hash

## Testing

### Dry Run

Test the release process without creating an actual release:

1. Bump version: `./scripts/release/bump-version.zsh --auto --push`
2. Trigger workflow with `dry_run: true`
3. Review the generated artifacts and logs

### Full Release

1. Bump version: `./scripts/release/bump-version.zsh --auto --push`
2. Trigger workflow with `dry_run: false`
3. Monitor the workflow execution
4. Verify Homebrew formula update

## Troubleshooting

### SHA256 Mismatches

If Homebrew reports SHA256 mismatches:

1. Check that the workflow used the codeload URL
2. Verify the wait time was sufficient (60 seconds)
3. Ensure the HOMEBREW_TOKEN secret is set
4. Check the workflow logs for retry attempts

### Workflow Failures

Common issues and solutions:

- **Version validation fails**: Ensure version format is XX.XX.XX
- **Tests fail**: Fix any test issues before releasing
- **Homebrew update fails**: Check HOMEBREW_TOKEN permissions

### Version Bump Issues

- **Version not pushed**: Remember to use `--push` flag with bump script
- **Version already exists**: Check if the version was already bumped and pushed
- **Git status issues**: Ensure working directory is clean before bumping

### YAML Linting Issues

- **Pre-commit hook fails**: Run `./scripts/release/lint-yaml.zsh --fix` to auto-fix issues
- **IDE shows warnings**: Install yamllint extension and configure to use `.yamllint`
- **Workflow linting fails**: Check the GitHub Actions logs for specific YAML issues

## Manual Steps (if needed)

If the automated workflow fails, manual steps may be required:

1. Create GitHub release manually
2. Download the GitHub-generated tarball
3. Calculate SHA256: `curl -sL "https://codeload.github.com/fxstein/GoProX/tar.gz/refs/tags/vXX.XX.XX" | shasum -a 256`
4. Update Homebrew formula manually
5. Test Homebrew installation: `brew install fxstein/tap/goprox`