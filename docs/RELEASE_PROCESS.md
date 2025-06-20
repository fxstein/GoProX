# GoProX Automated Release Process

This document describes the automated release process for GoProX, which handles version bumping, testing, packaging, and distribution.

## Overview

The release process consists of several components:

1. **Version Bump Detection** - Automatically detects when the version in `goprox` changes
2. **Release Automation Workflow** - GitHub Actions workflow that handles the entire release process
3. **Manual Release Scripts** - Helper scripts for manual release management
4. **Homebrew Integration** - Automatic updates to the Homebrew formula

## Components

### 1. Version Bump Detection (`.github/workflows/version-bump.yml`)

**Trigger**: Push to `main` branch that modifies the `goprox` file

**What it does**:
- Compares the version in the current `goprox` file with the previous commit
- If a version change is detected, automatically triggers the release automation workflow
- Passes the new and previous versions as parameters

**Usage**: Automatic - no manual intervention required

### 2. Release Automation Workflow (`.github/workflows/release-automation.yml`)

**Trigger**: Manual dispatch or automatic from version bump detection

**Jobs**:
- **Validate Version**: Ensures version format is correct and matches the `goprox` file
- **Run Tests**: Executes GoProX tests to ensure quality
- **Build Packages**: Creates release tarball and calculates SHA256
- **Generate Release Notes**: Creates changelog from commits and issues
- **Create Release**: Creates GitHub release with assets
- **Update Homebrew**: Updates the Homebrew formula in the tap repository
- **Dry Run Summary**: Shows what would happen in dry-run mode

**Inputs**:
- `version`: Version to release (e.g., "00.61.00")
- `prev_version`: Previous version for changelog generation
- `dry_run`: Whether to perform a dry run (default: false)

### 3. Manual Release Scripts

#### `scripts/release.zsh`

A comprehensive script for triggering releases manually.

**Features**:
- Automatic version detection from `goprox` file
- Automatic previous version detection from git tags
- Version format validation
- GitHub CLI integration
- Dry-run support
- Interactive confirmation

**Usage**:
```zsh
# Basic usage (auto-detects versions)
./scripts/release.zsh

# Specify versions manually
./scripts/release.zsh --version 00.61.00 --prev 00.60.00

# Dry run
./scripts/release.zsh --dry-run

# Help
./scripts/release.zsh --help
```

#### `scripts/bump-version.zsh`

A script for bumping the version in the `goprox` file.

**Features**:
- Version format validation
- Automatic commit and push options
- Interactive confirmation
- Cross-platform sed compatibility

**Usage**:
```zsh
# Basic version bump
./scripts/bump-version.zsh 00.61.00

# With custom commit message
./scripts/bump-version.zsh --message "Release v00.61.00 with new features" 00.61.00

# Auto-commit
./scripts/bump-version.zsh --commit 00.61.00

# Auto-commit and push
./scripts/bump-version.zsh --push 00.61.00

# Help
./scripts/bump-version.zsh --help
```

## Release Workflow

### Automatic Release (Recommended)

1. **Bump Version**: Use the version bump script
   ```zsh
   ./scripts/bump-version.zsh --push 00.61.00
   ```

2. **Automatic Trigger**: The version bump detection workflow automatically triggers the release process

3. **Monitor**: Watch the GitHub Actions tab for progress

### Manual Release

1. **Bump Version**: Update the version in `goprox` file
2. **Commit**: Commit the version change
3. **Trigger Release**: Use the release script
   ```zsh
   ./scripts/release.zsh --version 00.61.00 --prev 00.60.00
   ```

### Dry Run

Always test the release process with a dry run first:

```zsh
./scripts/release.zsh --dry-run
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

### For Automatic Releases

1. **GitHub Actions**: Must be enabled for the repository
2. **GitHub CLI**: Must be installed and authenticated
3. **Homebrew Tap**: The `fxstein/homebrew-fxstein` repository must exist

### For Manual Releases

1. **GitHub CLI**: Must be installed and authenticated
   ```zsh
   brew install gh
   gh auth login
   ```

2. **Scripts**: Make sure the scripts are executable
   ```zsh
   chmod +x scripts/*.zsh
   ```

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