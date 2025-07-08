# Contributing to GoProX

Thank you for your interest in contributing to GoProX! This document outlines the process and standards for contributing code, documentation, and ideas to the project.

## 🚀 Quick Start for Contributors

1. **Fork the repository** and clone your fork locally.
2. **Set up your development environment:**
   - Install all required dependencies using Homebrew:
     ```zsh
     brew bundle --file=scripts/maintenance/Brewfile
     ```
   - This will install all tools needed for development, linting, and testing (e.g., yamllint, jsonlint, jq, exiftool, node).
3. **Read the following key documents:**
   - [AI_INSTRUCTIONS.md](./AI_INSTRUCTIONS.md) — Project standards and AI assistant guidelines
   - [docs/architecture/DESIGN_PRINCIPLES.md](./docs/architecture/DESIGN_PRINCIPLES.md) — Design principles
   - [docs/testing/TESTING_FRAMEWORK.md](./docs/testing/TESTING_FRAMEWORK.md) — Testing framework and requirements
   - [docs/HOOK_SYSTEM_GUIDE.md](./docs/HOOK_SYSTEM_GUIDE.md) — Git hook system testing and troubleshooting
   - [docs/README.md](./docs/README.md) — Documentation structure and navigation

## 🛠️ Development Standards

- **Code Quality:**
  - All code must pass linting and validation before being committed (YAML, JSON, and shell scripts).
  - Use the pre-commit hook to catch issues early.
  - Follow the project's [Design Principles](./docs/architecture/DESIGN_PRINCIPLES.md).
  - **Hook System:** The project uses automatically configured Git hooks for quality assurance
    - Hooks are automatically set up when you clone the repository
    - Run `./scripts/testing/verify-hooks.zsh` for quick verification
    - Run `./scripts/maintenance/check-hook-health-simple.zsh` for comprehensive health check
    - See [Hook System Guide](./docs/HOOK_SYSTEM_GUIDE.md) for troubleshooting
- **Logging:**
  - Use the structured logger module (`scripts/core/logger.zsh`) for all output.
  - Replace `echo` statements with appropriate log levels (DEBUG, INFO, WARN, ERROR).
  - All logs are automatically directed to the `output/` directory.
  - Use JSON format for structured data and performance timing.
- **Testing:**
  - All new features and bug fixes must include or update tests.
  - Run the test suite with:
    ```zsh
    ./scripts/testing/run-tests.zsh
    ```
  - Include logger tests for new scripts that use logging functionality.
- **Documentation:**
  - Update or add documentation for any new features, changes, or scripts.
  - Use zsh code blocks for shell script examples.

## 🌿 Git-Flow Workflow

GoProX uses a git-flow workflow to ensure code quality, collaboration, and structured releases. This workflow supports both development and multi-channel release management.

### Branch Structure

**Main Branches:**
- `main` - Production-ready code, official releases
- `develop` - Integration branch for features and development

**Supporting Branches:**
- `feature/*` - New features and enhancements
- `release/*` - Release preparation and testing
- `hotfix/*` - Critical bug fixes for production

### Branch Naming Conventions

**Feature Branches:**
```zsh
feature/issue-XX-descriptive-name
feature/67-enhanced-default-behavior
feature/70-architecture-design-principles
```

**Release Branches:**
```zsh
release/01.11.00
release/01.12.00
```

**Hotfix Branches:**
```zsh
hotfix/critical-bug-fix
hotfix/security-patch
```

### Development Workflow

**1. Starting a New Feature:**
```zsh
# Ensure you're on develop branch
git checkout develop
git pull origin develop

# Create feature branch
git checkout -b feature/issue-XX-descriptive-name

# Make your changes, commit frequently
git add .
git commit -m "feat: add new feature (refs #XX)"

# Push feature branch
git push -u origin feature/issue-XX-descriptive-name
```

**2. Completing a Feature:**
```zsh
# Create pull request to develop branch
# Ensure all CI checks pass
# Get code review and approval
# Merge to develop
```

**3. Creating a Release:**
```zsh
# Create release branch from develop
git checkout develop
git pull origin develop
git checkout -b release/01.11.00

# Update version, documentation, release notes
# Test thoroughly
# Create pull request to main
```

**4. Hotfix Process:**
```zsh
# Create hotfix branch from main
git checkout main
git pull origin main
git checkout -b hotfix/critical-fix

# Fix the issue
git commit -m "fix: critical bug fix (refs #XX)"

# Create pull request to main AND develop
```

### Multi-Channel Release Support

GoProX supports a sophisticated multi-channel Homebrew system that provides different installation options for various user needs:

**1. Official Channel (main branch):**
```zsh
brew install fxstein/tap/goprox
```
- **Formula**: `goprox.rb` with class `Goprox`
- **Purpose**: Latest stable release for general users
- **Updates**: On official releases from main branch

**2. Beta Channel (release branches):**
```zsh
brew install fxstein/tap/goprox@beta
```
- **Formula**: `goprox@beta.rb` with class `GoproxBeta`
- **Purpose**: Pre-release testing for beta testers
- **Updates**: On beta releases from release branches

**3. Versioned Channels (specific versions):**
```zsh
brew install fxstein/tap/goprox@1.50
```
- **Formula**: `goprox@1.50.rb` with class `GoproxAT150`
- **Purpose**: Specific version installation for compatibility
- **Updates**: Created for each official release, maintained indefinitely

**4. Development Channel (develop branch):**
```zsh
brew install fxstein/tap/goprox@latest
```
- **Formula**: `goprox@latest.rb` with class `GoproxLatest`
- **Purpose**: Latest development builds for developers
- **Updates**: On every develop branch push

### Formula Naming Conventions

The system follows Homebrew's official naming conventions:
- **Default formula**: `goprox.rb` → class `Goprox`
- **Beta formula**: `goprox@beta.rb` → class `GoproxBeta`
- **Versioned formulae**: `goprox@1.50.rb` → class `GoproxAT150` (using `AT` for `@`)
- **Development formula**: `goprox@latest.rb` → class `GoproxLatest`

### Release Process Integration

The release automation system automatically:
1. **Official Releases**: Updates both `goprox` (default) and `goprox@X.XX` (versioned) formulae
2. **Beta Releases**: Updates only `goprox@beta` formula when triggered from release branches
3. **Development Builds**: Updates `goprox@latest` formula on develop branch pushes

### Pull Request Process

**Standard Feature PR:**
1. Create feature branch from develop
2. Implement feature with tests
3. Create pull request to develop
4. Require code review and CI checks
5. Merge after approval

**Release PR:**
1. Create release branch from develop
2. Update version and documentation
3. Create pull request to main
4. Require code review and CI checks
5. Merge to main and tag release
6. Merge back to develop

**Hotfix PR:**
1. Create hotfix branch from main
2. Fix the critical issue
3. Create pull request to main AND develop
4. Require code review and CI checks
5. Merge to both branches

### Code Review Requirements

- All pull requests require at least one review
- CI checks must pass before merging
- Code must follow project standards and design principles
- Tests must be included for new features
- Documentation must be updated

### Branch Protection

- `main` branch: Requires PR reviews, CI checks, up-to-date branches
- `develop` branch: Requires PR reviews, CI checks, allows force pushes for admins
- Feature branches: No restrictions, but CI checks run automatically

## 📝 Commit Message Guidelines

- Use imperative mood (e.g., "add feature", "fix bug").
- Reference issues using the format `(refs #n)`.
- Summarize changes clearly and concisely.
- Example:
  ```
  feat: add enhanced SD card detection (refs #63)
  ```

## 🤖 AI Assistant

- The AI assistant follows [AI_INSTRUCTIONS.md](./AI_INSTRUCTIONS.md) for all work, suggestions, and communication.
- If you interact with the AI, ensure it references and follows project standards.

## 📚 Useful Links

- [AI_INSTRUCTIONS.md](./AI_INSTRUCTIONS.md)
- [docs/README.md](./docs/README.md)
- [docs/architecture/DESIGN_PRINCIPLES.md](./docs/architecture/DESIGN_PRINCIPLES.md)
- [docs/testing/TESTING_FRAMEWORK.md](./docs/testing/TESTING_FRAMEWORK.md)
- [GitHub Issues](https://github.com/fxstein/GoProX/issues)

## 🙏 Thanks for contributing!

Your contributions help make GoProX better for everyone. If you have questions, open an issue or start a discussion on GitHub. 