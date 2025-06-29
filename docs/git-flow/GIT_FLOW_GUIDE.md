# Git-Flow Training Guide for GoProX

> **Reference:** This guide supports [GitHub Issue #20: Git-flow Implementation](https://github.com/fxstein/GoProX/issues/20)

This guide provides comprehensive training materials for the git-flow workflow implementation in the GoProX project, including multi-channel release support.

## Overview

Git-flow is a branching model that provides a robust framework for managing larger projects. It's particularly well-suited for projects with scheduled release cycles and multiple contributors.

### Key Benefits for GoProX

- **Structured Development**: Clear separation between development and production code
- **Release Management**: Organized process for preparing and releasing software
- **Hotfix Support**: Quick fixes for production issues without disrupting development
- **Multi-Channel Releases**: Support for development, beta, and production channels
- **Code Quality**: Enforced review process and CI/CD integration

## Branch Structure

```
main (production)
├── develop (integration)
│   ├── feature/issue-67-enhanced-default-behavior
│   ├── feature/issue-70-architecture-design-principles
│   └── feature/issue-XX-descriptive-name
├── release/01.11.00 (release preparation)
└── hotfix/critical-fix (production fixes)
```

### Branch Purposes

**Main Branches:**
- `main` - Contains production-ready code, tagged releases
- `develop` - Integration branch for features, development builds

**Supporting Branches:**
- `feature/*` - New features and enhancements
- `release/*` - Release preparation and testing
- `hotfix/*` - Critical bug fixes for production

## Development Workflow

### 1. Feature Development

**Starting a New Feature:**
```zsh
# Ensure you're on develop and it's up to date
git checkout develop
git pull origin develop

# Create feature branch
git checkout -b feature/issue-XX-descriptive-name

# Make your changes
# ... work on feature ...

# Commit frequently with clear messages
git add .
git commit -m "feat: add new feature (refs #XX)"

# Push feature branch
git push -u origin feature/issue-XX-descriptive-name
```

**Completing a Feature:**
```zsh
# Create pull request to develop branch
# Ensure all CI checks pass
# Get code review and approval
# Merge to develop

# Clean up feature branch
git checkout develop
git pull origin develop
git branch -d feature/issue-XX-descriptive-name
git push origin --delete feature/issue-XX-descriptive-name
```

### 2. Release Preparation

**Creating a Release:**
```zsh
# Start from develop
git checkout develop
git pull origin develop

# Create release branch
git checkout -b release/01.11.00

# Update version numbers, documentation, release notes
# Test thoroughly
# Fix any last-minute issues

# Create pull request to main
# Get review and approval
# Merge to main and tag release
git checkout main
git merge release/01.11.00
git tag -a v01.11.00 -m "Release version 01.11.00"
git push origin main --tags

# Merge back to develop
git checkout develop
git merge release/01.11.00
git push origin develop

# Clean up release branch
git branch -d release/01.11.00
git push origin --delete release/01.11.00
```

### 3. Hotfix Process

**Creating a Hotfix:**
```zsh
# Start from main (production)
git checkout main
git pull origin main

# Create hotfix branch
git checkout -b hotfix/critical-fix

# Fix the issue
# ... make minimal changes to fix the problem ...

# Commit the fix
git add .
git commit -m "fix: critical bug fix (refs #XX)"

# Create pull request to main AND develop
# Get review and approval
# Merge to main first
git checkout main
git merge hotfix/critical-fix
git tag -a v01.11.01 -m "Hotfix version 01.11.01"
git push origin main --tags

# Then merge to develop
git checkout develop
git merge hotfix/critical-fix
git push origin develop

# Clean up hotfix branch
git branch -d hotfix/critical-fix
git push origin --delete hotfix/critical-fix
```

## Multi-Channel Release Management

### Release Channels

**1. Dev Build Channel (develop branch):**
- **Installation**: `brew install fxstein/tap/goprox@dev`
- **Source**: `develop` branch
- **Update Frequency**: On every develop push
- **Audience**: Developers, early adopters
- **Stability**: Development quality, may contain bugs

**2. Beta Channel (release branches):**
- **Installation**: `brew install fxstein/tap/goprox@beta`
- **Source**: `release/*` branches
- **Update Frequency**: On release branch creation and updates
- **Audience**: Beta testers, advanced users
- **Stability**: Release candidate quality, feature complete

**3. Official Channel (main branch):**
- **Installation**: `brew install fxstein/tap/goprox`
- **Source**: `main` branch (tagged releases)
- **Update Frequency**: On official releases only
- **Audience**: General users, production environments
- **Stability**: Production quality, thoroughly tested

### Channel Switching

**Upgrading Between Channels:**
```zsh
# Switch from official to beta
brew uninstall fxstein/tap/goprox
brew install fxstein/tap/goprox@beta

# Switch from beta to dev
brew uninstall fxstein/tap/goprox@beta
brew install fxstein/tap/goprox@dev

# Downgrade from dev to official
brew uninstall fxstein/tap/goprox@dev
brew install fxstein/tap/goprox
```

## Best Practices

### Commit Messages

- Use conventional commit format: `type: description (refs #XX)`
- Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`
- Reference issues using `(refs #XX)` format
- Keep descriptions clear and concise

**Examples:**
```zsh
git commit -m "feat: add enhanced SD card detection (refs #63)"
git commit -m "fix: resolve firmware download issue (refs #60)"
git commit -m "docs: update installation guide (refs #20)"
```

### Branch Naming

- **Feature branches**: `feature/issue-XX-descriptive-name`
- **Release branches**: `release/01.11.00`
- **Hotfix branches**: `hotfix/critical-fix`

### Code Review Process

1. **Create Pull Request**: Target the appropriate branch
2. **CI Checks**: Ensure all automated tests pass
3. **Code Review**: Get at least one approval
4. **Merge**: Only after all checks pass and review is approved

### Testing Requirements

- All features must include tests
- Run test suite before creating pull request
- Ensure CI/CD pipeline passes
- Test on multiple platforms if applicable

## Common Scenarios

### Scenario 1: New Feature Development

1. Create feature branch from develop
2. Implement feature with tests
3. Create pull request to develop
4. Get review and approval
5. Merge to develop
6. Clean up feature branch

### Scenario 2: Release Preparation

1. Create release branch from develop
2. Update version and documentation
3. Test thoroughly
4. Create pull request to main
5. Get review and approval
6. Merge to main and tag release
7. Merge back to develop
8. Clean up release branch

### Scenario 3: Critical Bug Fix

1. Create hotfix branch from main
2. Fix the issue with minimal changes
3. Create pull request to main AND develop
4. Get review and approval
5. Merge to main first, then develop
6. Tag hotfix release
7. Clean up hotfix branch

## Troubleshooting

### Merge Conflicts

**Resolving Conflicts:**
```zsh
# During merge, conflicts will be marked
git status  # See conflicted files
# Edit files to resolve conflicts
git add .   # Mark conflicts as resolved
git commit  # Complete the merge
```

### Branch Cleanup

**Cleaning Up Old Branches:**
```zsh
# Delete local branch
git branch -d branch-name

# Delete remote branch
git push origin --delete branch-name

# List all branches
git branch -a

# Clean up remote tracking branches
git remote prune origin
```

### Emergency Rollback

**Rolling Back a Release:**
```zsh
# Create hotfix from previous tag
git checkout main
git checkout -b hotfix/rollback-v01.11.00
git revert v01.11.00
git commit -m "revert: rollback to previous version (refs #XX)"
# Follow hotfix process
```

## Integration with CI/CD

### Automated Workflows

- **Feature branches**: Run tests and linting
- **Release branches**: Run full test suite and release preparation
- **Main branch**: Run production deployment and Homebrew updates

### Required Checks

- YAML linting
- Shell script validation
- Test suite execution
- Documentation validation
- Multi-channel Homebrew updates

## Monitoring and Verification

### Automated Workflow Monitoring

The git-flow release process includes comprehensive monitoring and verification capabilities:

#### **1. Release Monitoring**
```zsh
# Monitor a release process in real-time
./scripts/release/gitflow-monitor.zsh --monitor-release --base-version 01.10.00 --branch develop --dry-run

# Monitor a real release with automatic verification
./scripts/release/gitflow-monitor.zsh --monitor-release --base-version 01.10.00 --branch main
```

#### **2. Automatic Monitoring in Release Script**
```zsh
# Release with automatic workflow verification
./scripts/release/gitflow-release.zsh --monitor 01.10.00

# Custom timeout for monitoring (default: 15 minutes)
./scripts/release/gitflow-release.zsh --monitor --monitor-timeout 30 01.10.00
```

#### **3. Manual Workflow Verification**
```zsh
# Check current workflow status
./scripts/release/gitflow-monitor.zsh --check-workflow

# Check AI summary status
./scripts/release/gitflow-monitor.zsh --check-summary

# Run all checks
./scripts/release/gitflow-monitor.zsh --all
```

### GitHub Actions Integration

#### **Automatic Verification Workflow**
The `release-verification.yml` workflow automatically:
- Triggers after release workflows complete
- Verifies release process success
- Generates verification reports
- Comments on workflow runs with results

#### **Manual Verification**
You can manually trigger verification:
1. Go to GitHub Actions → Release Verification
2. Click "Run workflow"
3. Enter base version, branch, and dry-run status
4. Review verification results

### Verification Features

#### **Real-time Monitoring**
- Polls GitHub Actions API every 30 seconds
- Configurable timeout (default: 15 minutes)
- Detailed status reporting
- Automatic error detection

#### **Comprehensive Reporting**
- Workflow status and conclusion
- Branch-specific validation
- Error logs and debugging info
- Success/failure verification

#### **Integration Points**
- Pre-release validation
- Post-release verification
- Automated error handling
- Manual override capabilities

## Next Steps

1. **Practice**: Create test branches and practice the workflow
2. **Review**: Review this guide with the team
3. **Implementation**: Begin using git-flow for new features
4. **Monitoring**: Track success metrics and adjust as needed

## Resources

- [Git-Flow Implementation Plan](../feature-planning/issue-20-git-flow-model/GIT_FLOW_IMPLEMENTATION_PLAN.md)
- [CONTRIBUTING.md](../../CONTRIBUTING.md)
- [AI_INSTRUCTIONS.md](../../AI_INSTRUCTIONS.md)
- [Design Principles](../architecture/DESIGN_PRINCIPLES.md)

---

*This guide should be updated as the git-flow implementation evolves and team feedback is incorporated.* 