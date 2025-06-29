# Branch Cleanup Automation

This document describes the automated branch cleanup system for the GoProX project, which helps maintain a clean repository by automatically removing merged branches.

## Overview

The branch cleanup automation consists of two components:

1. **GitHub Actions Workflow** (`.github/workflows/branch-cleanup.yml`) - Automatically triggers on PR merges
2. **Local Script** (`scripts/maintenance/cleanup-merged-branches.zsh`) - Manual cleanup utility

## GitHub Actions Workflow

### Trigger Conditions

The workflow automatically triggers when:
- A pull request is **closed** (merged)
- The target branch is `develop` or `main`

### What It Does

1. **Deletes the source branch** - Removes the branch that was merged
2. **Finds related branches** - Looks for branches with similar names or containing the PR number
3. **Cleans up stale references** - Removes orphaned remote tracking branches
4. **Provides detailed logging** - Shows what was deleted and why

### Safety Features

- **Protected branches** - Never deletes `main`, `develop`, or `master`
- **Existence checks** - Verifies branches exist before attempting deletion
- **Error handling** - Gracefully handles missing branches
- **Detailed logging** - Shows exactly what actions were taken

### Permissions Required

The workflow requires:
- `contents: write` - To delete branches
- `actions: read` - To access workflow information

## Local Script Usage

### Basic Usage

```zsh
# Clean up all merged branches
./scripts/maintenance/cleanup-merged-branches.zsh

# Dry run to see what would be deleted
./scripts/maintenance/cleanup-merged-branches.zsh --dry-run

# Force delete branches (even if not fully merged)
./scripts/maintenance/cleanup-merged-branches.zsh --force
```

### Advanced Options

```zsh
# Only cleanup local branches
./scripts/maintenance/cleanup-merged-branches.zsh --local-only

# Only cleanup remote branches
./scripts/maintenance/cleanup-merged-branches.zsh --remote-only

# Combine options
./scripts/maintenance/cleanup-merged-branches.zsh --dry-run --local-only
```

### Environment Variables

You can also use environment variables for configuration:

```zsh
# Set environment variables
export DRY_RUN=true
export FORCE=true
export CLEANUP_REMOTE=false
export CLEANUP_LOCAL=true

# Run the script
./scripts/maintenance/cleanup-merged-branches.zsh
```

## Branch Protection

The following branches are automatically protected from deletion:

- `main`
- `develop` 
- `master`

## Integration with Git Flow

This automation works seamlessly with the Git Flow model:

1. **Feature branches** (`feat/*`) - Automatically cleaned up when merged to `develop`
2. **Release branches** (`rel/*`) - Automatically cleaned up when merged to `main`
3. **Hotfix branches** (`hot/*`) - Automatically cleaned up when merged to `main`
4. **Fix branches** (`fix/*`) - Automatically cleaned up when merged to `develop`

## Monitoring and Logs

### GitHub Actions Logs

- Workflow logs are available in the GitHub Actions tab
- Each step provides detailed output
- Failed deletions are logged with error messages

### Local Script Output

The local script provides detailed logging using the project's logger:

```
[INFO] Starting branch cleanup process...
[INFO] Current branch: feat/branch-cleanup-automation
[INFO] Found 3 merged branches
[INFO] Skipping current branch: feat/branch-cleanup-automation
[INFO] Skipping protected branch: develop
[INFO] Deleting local branch: feat/old-feature
[SUCCESS] Deleted local branch: feat/old-feature
[INFO] Deleting remote branch: feat/old-feature
[SUCCESS] Deleted remote branch: feat/old-feature
[INFO] Pruning stale remote references...
[SUCCESS] Stale remote references cleaned up
[SUCCESS] Branch cleanup completed!
[INFO] Summary:
[INFO]   - Branches processed: 3
[INFO]   - Branches deleted: 1
[INFO]   - Branches skipped: 2
[INFO]   - Current branch: feat/branch-cleanup-automation
```

## Troubleshooting

### Common Issues

1. **Permission denied** - Ensure the workflow has proper permissions
2. **Branch not found** - Branch may have already been deleted
3. **Protected branch** - Cannot delete main/develop/master branches

### Manual Cleanup

If the automation fails, you can manually clean up branches:

```zsh
# List all branches
git branch -a

# Delete local branch
git branch -d branch-name

# Delete remote branch
git push origin --delete branch-name

# Clean up stale references
git remote prune origin
```

## Configuration

### Customizing Protected Branches

To add more protected branches, edit the script:

```zsh
# In cleanup-merged-branches.zsh
PROTECTED_BRANCHES=("main" "develop" "master" "staging" "production")
```

### Workflow Customization

The GitHub Actions workflow can be customized by:

1. Adding more trigger conditions
2. Modifying the branch detection logic
3. Adding additional cleanup steps
4. Changing the notification system

## Best Practices

1. **Always use dry-run first** - Test the cleanup before running it
2. **Review logs** - Check what branches will be deleted
3. **Backup important work** - Ensure all changes are merged before cleanup
4. **Monitor automation** - Check GitHub Actions logs regularly
5. **Use descriptive branch names** - Makes it easier to identify related branches

## Future Enhancements

Potential improvements to consider:

1. **Slack/Discord notifications** - Notify team of cleanup actions
2. **Branch age filtering** - Only delete branches older than X days
3. **Custom branch patterns** - Support for project-specific naming conventions
4. **Integration with issue tracking** - Link cleanup to closed issues
5. **Scheduled cleanup** - Regular cleanup of stale branches 