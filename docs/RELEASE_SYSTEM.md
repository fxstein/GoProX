# GoProX Simplified Release System

## Overview

The GoProX project now includes a simplified top-level release script (`scripts/release/release.zsh`) that provides both interactive and batch modes for creating various types of releases. This system streamlines the release process while maintaining the flexibility needed for different release scenarios.

## Quick Start

### Interactive Mode (Recommended for Developers)
```zsh
./scripts/release/release.zsh
```

### Batch Mode (Recommended for AI/Automation)
```zsh
./scripts/release/release.zsh --batch dry-run --prev 01.50.00
```

## Release Types

The system supports different release types through the unified `gitflow-release.zsh` script:

- **Official releases**: From main/develop branches
- **Beta releases**: From release/* branches  
- **Development releases**: From feature/fix branches
- **Dry runs**: Simulated releases for testing

## Modes

### Interactive Mode
The default mode that guides users through the release process with prompts and sensible defaults.

**Features:**
- Menu-driven release type selection
- Automatic version suggestions
- Interactive confirmation
- Pre-populated defaults from current state

**Example Session:**
```zsh
$ ./scripts/release/release.zsh

┌─────────────────────────────────────────────────────────────────┐
│                   GoProX Release Status                        │
└─────────────────────────────────────────────────────────────────┘

📍 Current Version: 01.50.00
🏷️  Latest Tag: 01.50.00
🌿 Current Branch: develop

Select release type:
1) Official Release (production)
2) Beta Release (testing)
3) Development Release (feature testing)
4) Dry Run (test without release)

Enter choice (1-4): 1

Previous version for changelog [01.50.00]: 

Version bump type:
1) Major (X.00.00)
2) Minor (X.X.00) [default]
3) Patch (X.X.X)

Enter choice (1-3) [2]: 

Next version [01.51.00]: 

Monitor workflow completion? (y/N): y

Release Summary:
  Type: official
  Previous: 01.50.00
  Next: 01.51.00
  Bump: minor
  Monitor: y

Proceed with release? (y/N): y
```

### Batch Mode
Designed for automation and AI use, requiring all parameters to be specified upfront.

**Features:**
- No user interaction required
- All parameters must be specified
- Ideal for CI/CD and automation
- Consistent behavior across runs

**Examples:**
```zsh
# Dry run for testing
./scripts/release/release.zsh --batch dry-run --prev 01.50.00 --minor

# Beta release with specific version
./scripts/release/release.zsh --batch beta --prev 01.50.00 --version 01.51.00

# Official release with monitoring
./scripts/release/release.zsh --batch official --prev 01.50.00 --minor --monitor

# Development release
./scripts/release/release.zsh --batch dev --prev 01.50.00 --patch
```

## Command Line Options

### Mode Options
- `--interactive`: Explicit interactive mode (default)
- `--batch`: Batch mode for automation

### Version Options
- `--prev <version>`: Previous version for changelog (required)
- `--version <version>`: Specific version to release (optional)
- `--major`: Bump major version
- `--minor`: Bump minor version (default)
- `--patch`: Bump patch version

### Control Options
- `--monitor`: Monitor workflow completion
- `--help`, `-h`: Show help message

## Version Format

All versions must follow the format: `XX.XX.XX`

**Examples:**
- `01.50.00`
- `02.10.05`
- `00.99.01`

## Branch Requirements

### Official Releases
- **Allowed Branches**: `main`, `develop`, `release/*`
- **Purpose**: Production releases
- **Homebrew**: Updates default and versioned formulae

### Beta Releases
- **Allowed Branches**: `release/*`
- **Purpose**: Pre-release testing
- **Homebrew**: Updates beta channel only

### Development Releases
- **Allowed Branches**: `feature/*`, `fix/*`
- **Purpose**: Feature testing
- **Homebrew**: Updates development channel

### Dry Runs
- **Allowed Branches**: Any branch
- **Purpose**: Testing release process
- **Homebrew**: No updates (simulation)

## Prerequisites

### Required Tools
1. **Git**: Version control system
2. **GitHub CLI**: For GitHub operations
   ```zsh
   brew install gh
   gh auth login
   ```

### Required Scripts
- `scripts/release/full-release.zsh`
- `scripts/release/gitflow-release.zsh`

### Repository State
- Clean working directory (unless using `--allow-unclean`)
- Proper branch for release type
- AI summary file exists (for real releases)

## AI Summary File Requirements

Before creating a real release, the AI summary file must exist:
```
docs/release/latest-major-changes-since-<PREV_VERSION>.md
```

**Example:**
```
docs/release/latest-major-changes-since-01.50.00.md
```

## Error Handling

The script includes comprehensive error handling:

### Prerequisites Check
- Git repository validation
- GitHub CLI availability and authentication
- Required script existence

### Version Validation
- Format validation (XX.XX.XX)
- Semantic versioning compliance

### Branch Validation
- Appropriate branch for release type
- Clean working directory (configurable)

### Release Execution
- Command execution monitoring
- Exit code validation
- Detailed error reporting

## Integration with Existing Systems

### GitFlow Integration
The script integrates with the existing GitFlow release system:
- Uses `gitflow-release.zsh` for official/beta/dev releases
- Uses `full-release.zsh` for dry runs
- Maintains GitFlow branch conventions

### Homebrew Multi-Channel System
Supports the multi-channel Homebrew system:
- **Official**: Updates `goprox` and `goprox@X.XX` formulae
- **Beta**: Updates `goprox@beta` formula
- **Development**: Updates `goprox@latest` formula
- **Dry Run**: No Homebrew updates

### CI/CD Integration
Designed for CI/CD workflows:
- Batch mode for automation
- Consistent parameter handling
- Exit codes for success/failure
- Monitoring capabilities

## Best Practices

### For Developers
1. **Always use dry-run first**: Test the release process before creating real releases
2. **Use interactive mode**: For one-off releases and exploration
3. **Check branch requirements**: Ensure you're on the correct branch for the release type
4. **Monitor workflows**: Use `--monitor` for important releases

### For AI/Automation
1. **Use batch mode**: Ensures consistent behavior
2. **Specify all parameters**: Avoid relying on defaults
3. **Include monitoring**: For production releases
4. **Handle exit codes**: Check for success/failure

### For CI/CD
1. **Use dry-run for testing**: Validate release process
2. **Use batch mode**: No user interaction required
3. **Monitor releases**: Track workflow completion
4. **Handle errors**: Implement proper error handling

## Troubleshooting

### Common Issues

**"Not in a git repository"**
```bash
# Ensure you're in the GoProX project directory
cd /path/to/GoProX
```

**"GitHub CLI not authenticated"**
```bash
# Authenticate with GitHub
gh auth login
```

**"Invalid version format"**
```bash
# Use correct format: XX.XX.XX
./scripts/release/release.zsh --batch dry-run --prev 01.50.00
```

**"Branch not allowed for release type"**
```bash
# Switch to appropriate branch
git checkout develop  # for official releases
git checkout release/1.51  # for beta releases
```

**"AI summary file not found"**
```bash
# Create the required summary file
# docs/release/latest-major-changes-since-01.50.00.md
```

### Debug Mode
For troubleshooting, you can enable debug output:
```bash
# Set debug environment variable
DEBUG=1 ./scripts/release/release.zsh --batch dry-run --prev 01.50.00
```

## Migration from Legacy Scripts

### Old Commands → New Commands

**Full Release:**
```bash
# Old
./scripts/release/full-release.zsh --dry-run --prev 01.50.00

# New
./scripts/release/release.zsh --batch dry-run --prev 01.50.00
```

**GitFlow Release:**
```bash
# Old
./scripts/release/gitflow-release.zsh --prev 01.50.00

# New
./scripts/release/release.zsh --batch official --prev 01.50.00
```

### Benefits of New System
1. **Simplified Interface**: Single entry point for all release types
2. **Interactive Mode**: User-friendly for developers
3. **Batch Mode**: Automation-friendly for AI/CI
4. **Better Error Handling**: Comprehensive validation and error messages
5. **Consistent Behavior**: Standardized across all release types

## Future Enhancements

Potential improvements to the release system:

1. **Release Templates**: Predefined release configurations
2. **Release Scheduling**: Scheduled releases for specific times
3. **Release Notifications**: Slack/Discord integration
4. **Release Signing**: GPG signing of releases
5. **Multi-platform Support**: Support for different operating systems
6. **Release Analytics**: Track release metrics and success rates

## Support

For issues with the release system:

1. Check this documentation
2. Review error messages carefully
3. Test with dry-run mode
4. Create an issue in the repository
5. Check GitHub Actions logs for workflow issues

## Issue Reference Format

When referencing issues in commit messages and documentation, use the following format:

- **Single issue**: `(refs #n)` - e.g., `(refs #20)`
- **Multiple issues**: `(refs #n #n ...)` - e.g., `(refs #20 #25 #30)`

## Script Architecture

The release system uses a unified approach with these key scripts:

- `scripts/release/release.zsh` - Top-level simplified release script
- `scripts/release/gitflow-release.zsh` - Unified release backend (handles all operations)
- `scripts/release/trigger-workflow.zsh` - GitHub Actions workflow trigger
- `scripts/release/bump-version.zsh` - Version management utilities
- `scripts/release/monitor-release.zsh` - Workflow monitoring utilities 