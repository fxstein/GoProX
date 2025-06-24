# GoProX Automated Release Process

**NEW: The release script now uses strict parameter validation. Only the following options are accepted:**

- `-h`, `--help` — show help
- `--dry-run` — perform a dry run (no actual release)
- `--prev <version>` — specify previous version for changelog
- `--base <version>` — alias for `--prev` (backward compatibility)
- `--version <version>` — specify version to release (default: auto-increment)
- `--force` — force execution without confirmation
- `--major` — bump major version (default: minor)
- `--minor` — bump minor version (default)
- `--patch` — bump patch version

**Passing any unknown parameter will cause the script to fail with an error.**

_This matches the robust argument handling of the main `goprox` tool._

## Overview

The release process is now performed using the `full-release.zsh` script, which handles version bumping, workflow triggering, and monitoring in one automated step.

### 1. Full Release Script (`scripts/release/full-release.zsh`)

**Standard Usage:**

```zsh
./scripts/release/full-release.zsh --dry-run   # Recommended for test runs
./scripts/release/full-release.zsh             # For real releases (explicitly requested)
./scripts/release/full-release.zsh --dry-run --prev 00.52.00
./scripts/release/full-release.zsh --dry-run --base 00.52.00
```

- **Dry Run:** By default, always use `--dry-run` for test runs. This simulates the entire process without making changes or triggering a real release.
- **Real Release:** Only run without `--dry-run` when you intend to create a real release.

**What it does:**
- Bumps the version (simulated in dry-run mode)
- Triggers the release workflow (in dry-run or real mode)
- Monitors the workflow in real time and provides a summary

### 2. Legacy Scripts (for reference only)

The following scripts are now called internally by `full-release.zsh` and should not be run directly unless for advanced troubleshooting:
- `scripts/release/bump-version.zsh`
- `scripts/release/release.zsh`
- `scripts/release/monitor-release.zsh`

### 3. Monitoring Output

The monitor now always attaches to the latest workflow run and waits 15 seconds before starting to ensure it tracks the correct run.

## Example Workflow

**Test (Dry Run):**
```zsh
./scripts/release/full-release.zsh --dry-run
```

**Real Release:**
```zsh
./scripts/release/full-release.zsh
```

## Troubleshooting
- If you encounter errors, check the output for clear error messages.
- For advanced debugging, you may run the legacy scripts individually, but this is not recommended for standard releases.

## Changelog
- Unified release process under `full-release.zsh`
- Added robust dry-run support
- Improved monitoring and output visibility

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