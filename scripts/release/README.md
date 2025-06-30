# GoProX Release Scripts

This directory contains all scripts related to the GoProX release, versioning, and automation system.

## 🚀 Main Entry Point: `release.zsh`

- **Location:** `scripts/release/release.zsh`
- **Purpose:** Unified, user-friendly script for creating official, beta, dev, and dry-run releases.
- **Modes:** Interactive and batch (automation/CI)

### Usage Examples

Interactive mode (recommended for developers):
```zsh
./scripts/release/release.zsh
```

Batch mode (for automation or advanced users):
```zsh
./scripts/release/release.zsh --batch dry-run --prev 01.50.00
./scripts/release/release.zsh --batch official --prev 01.50.00 --minor --monitor
./scripts/release/release.zsh --batch beta --prev 01.50.00 --version 01.51.00
./scripts/release/release.zsh --batch dev --prev 01.50.00 --patch
```

For full details, see:
- [Release System Documentation](../../docs/RELEASE_SYSTEM.md)
- [Release Process Guide](../../docs/RELEASE_PROCESS.md)

---

## 🛠️ Helper & Automation Scripts

- **`gitflow-release.zsh`**: Unified backend for all release types; handles version bumping, workflow triggering, and summary file management.
- **`bump-version.zsh`**: Safely increments or sets the version in the main `goprox` script, with commit/push options.
- **`monitor-release.zsh`**: Monitors GitHub Actions workflows for release completion and outputs status.
- **`trigger-workflow.zsh`**: Triggers the main GitHub Actions release workflow (used internally).
- **`generate-release-notes.zsh`**: Generates release notes for inclusion in GitHub releases and documentation.
- **`lint-yaml.zsh`**: Lints YAML files for syntax and style issues (used in CI and pre-commit hooks).
- **`setup-pre-commit.zsh`**: Installs pre-commit hooks for YAML linting and other checks.
- **`test-homebrew-channels.zsh`**: Tests Homebrew multi-channel release logic.
- **`update-homebrew-channel.zsh`**: Updates Homebrew tap formulae for new releases.

---

## 📚 More Information

- [Release System Documentation](../../docs/RELEASE_SYSTEM.md)
- [Release Process Guide](../../docs/RELEASE_PROCESS.md)
- [Homebrew Multi-Channel System](../../docs/HOMEBREW_MULTI_CHANNEL.md) 