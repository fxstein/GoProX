# Release Automation for Git-Flow

## Overview

This document describes the automated release process for the GoProX git-flow implementation, including the recent improvements to eliminate manual intervention.

## Current Implementation

### Automated Triggers

The release automation workflow now supports two trigger methods:

1. **Manual Trigger** (`workflow_dispatch`)
   - Allows manual release with custom version and previous version
   - Useful for hotfixes or special releases
   - Supports dry-run mode for testing

2. **Automatic Trigger** (`push` to `main`)
   - Triggers automatically when changes are pushed to `main`
   - Only activates when `goprox` file is modified (version bump)
   - Automatically detects current and previous versions
   - Skips if no version bump is detected

### Version Detection Logic

When triggered automatically, the workflow:

1. **Reads current version** from `goprox` file (`__version__='XX.XX.XX'`)
2. **Finds previous version** from git tags (latest tag)
3. **Validates version bump** - skips if versions are identical
4. **Checks for existing tags** - prevents duplicate releases
5. **Validates format** - ensures XX.XX.XX format

### Workflow Jobs

1. **validate-version** - Detects and validates version information
2. **run-tests** - Executes comprehensive test suite
3. **build-packages** - Creates release tarball and calculates SHA256
4. **generate-release-notes** - Creates detailed release notes
5. **create-release** - Publishes GitHub release (if not dry-run)
6. **update-homebrew** - Updates Homebrew formula (if not dry-run)
7. **dry-run-summary** - Shows summary for dry runs

## Git-Flow Integration

### Release Branch Workflow

1. **Create release branch** from `develop`
   ```zsh
   git checkout -b release/01.12.00
   ```

2. **Bump version** in `goprox` file
   ```zsh
   # Edit goprox file: __version__='01.12.00'
   ```

3. **Commit and push** version bump
   ```zsh
   git add goprox
   git commit -m "chore: bump version to 01.12.00 for release (refs #XX)"
   git push -u origin release/01.12.00
   ```

4. **Create PR** to `main`
   ```zsh
   gh pr create --base main --head release/01.12.00 --title "release: v01.12.00"
   ```

5. **Merge PR** - This automatically triggers the release process!

### Automatic Release Process

When the release PR is merged to `main`:

1. **Push trigger** activates release automation workflow
2. **Version detection** finds 01.12.00 as current, 01.11.00 as previous
3. **Validation** confirms version bump and format
4. **Tests** run to ensure quality
5. **Release** is automatically created and published
6. **Homebrew** is updated with new version

## Benefits

### Before (Manual Process)
- ✅ Create release branch
- ✅ Bump version
- ✅ Create PR
- ✅ Merge PR
- ❌ **Manual step**: Trigger release workflow
- ❌ **Manual step**: Enter version numbers
- ❌ **Manual step**: Wait for completion

### After (Automated Process)
- ✅ Create release branch
- ✅ Bump version
- ✅ Create PR
- ✅ Merge PR
- ✅ **Automatic**: Release workflow triggers
- ✅ **Automatic**: Version detection
- ✅ **Automatic**: Release creation and publishing

## Safety Features

### Version Validation
- **Format checking**: Ensures XX.XX.XX format
- **Duplicate prevention**: Checks for existing tags
- **Consistency**: Validates goprox file version
- **Bump detection**: Only releases on actual version changes

### Error Handling
- **Graceful skipping**: No release if no version bump
- **Clear logging**: Detailed output for debugging
- **Failure recovery**: Manual trigger still available
- **Dry-run support**: Test releases without publishing

### Rollback Capability
- **Manual trigger**: Can re-run with different parameters
- **Tag management**: Can delete and recreate tags if needed
- **Homebrew rollback**: Can revert Homebrew formula changes

## Configuration

### Required Secrets
- `GITHUB_TOKEN` - For creating releases and pushing to Homebrew
- `HOMEBREW_TOKEN` - For updating Homebrew formulas

### Workflow Files
- `.github/workflows/release-automation.yml` - Main release workflow
- `.github/workflows/release-channels.yml` - Multi-channel management

## Troubleshooting

### Common Issues

1. **No release triggered**
   - Check if `goprox` file was modified in the push
   - Verify version format is XX.XX.XX
   - Ensure previous version tag exists

2. **Version detection fails**
   - Check git tags exist and are properly formatted
   - Verify `goprox` file has correct version format
   - Ensure no duplicate tags exist

3. **Release creation fails**
   - Check GitHub token permissions
   - Verify no existing release for this version
   - Check workflow logs for specific errors

### Manual Override

If automatic release fails, you can always use manual trigger:

```zsh
gh workflow run release-automation.yml \
  --field version=01.12.00 \
  --field prev_version=01.11.00
```

## Future Enhancements

### Potential Improvements
1. **Branch protection**: Require specific branch patterns for automatic releases
2. **Approval gates**: Add manual approval for major releases
3. **Release channels**: Automatic beta/stable channel management
4. **Notification**: Slack/Discord notifications for release status
5. **Metrics**: Track release frequency and success rates

### Integration Opportunities
1. **Issue automation**: Auto-close issues mentioned in release notes
2. **Documentation**: Auto-update version in documentation
3. **Docker**: Auto-build and push Docker images
4. **Package managers**: Support for additional package managers

## Conclusion

The automated release process eliminates manual intervention while maintaining safety and control. The git-flow workflow is now fully automated from feature development through release publication, providing a seamless development experience. 