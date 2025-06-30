# GoProX Documentation

Welcome to the GoProX documentation! This directory contains comprehensive documentation for the GoProX project, organized by topic and purpose.

## 📚 Documentation Structure

### **Core Documentation**
- **[NEXT_STEPS.md](NEXT_STEPS.md)** - Current priorities, progress tracking, and next steps
- **[RELEASE_PROCESS.md](RELEASE_PROCESS.md)** - Release workflow and automation procedures
- **[HOMEBREW_MULTI_CHANNEL.md](HOMEBREW_MULTI_CHANNEL.md)** - Homebrew multi-channel system and installation options
- **[GITHUB_RESTORE_INFO.md](GITHUB_RESTORE_INFO.md)** - GitHub repository restoration information
- **[SD_CARD_DETECTION.md](SD_CARD_DETECTION.md)** - SD card detection and GoPro identification

### **Architecture & Design**
- **[architecture/](architecture/)** - Design principles and architectural decisions
  - [DESIGN_PRINCIPLES.md](architecture/DESIGN_PRINCIPLES.md) - Core design principles and patterns
- **[feature-planning/](feature-planning/)** - Detailed feature analysis and implementation strategies
  - [FEATURE_ANALYSIS.md](feature-planning/FEATURE_ANALYSIS.md) - Comprehensive feature analysis
  - [README.md](feature-planning/README.md) - Feature planning summary and links

### **Testing & Quality Assurance**
- **[testing/](testing/)** - Testing framework and quality assurance documentation
  - [TESTING_FRAMEWORK.md](testing/TESTING_FRAMEWORK.md) - Testing framework documentation
  - [CI_CD_SUCCESS.md](testing/CI_CD_SUCCESS.md) - CI/CD success summary
  - [YAML_LINTING_SETUP.md](testing/YAML_LINTING_SETUP.md) - YAML linting configuration

### **Release Management**
- **[release/](release/)** - Release notes and version history
  - Release notes for major versions and changes

### **Issue Tracking**
- **[issues/](issues/)** - Issue-related documentation and tracking
  - Git history rewrite issues
  - Release debug issues

### **GoPro-Specific Documentation**
- **[gopro/](gopro/)** - GoPro-specific technical documentation
  - [GOPRO_OFFICIAL_URL_FORMAT.md](gopro/GOPRO_OFFICIAL_URL_FORMAT.md) - Official firmware URL format
  - [GOPRO_LABS_URL_FORMAT.md](gopro/GOPRO_LABS_URL_FORMAT.md) - Labs firmware URL format

## 🚀 Quick Start

### **For New Contributors**
1. Start with [NEXT_STEPS.md](NEXT_STEPS.md) to understand current priorities
2. Read [DESIGN_PRINCIPLES.md](architecture/DESIGN_PRINCIPLES.md) for architectural guidelines
3. Review [TESTING_FRAMEWORK.md](testing/TESTING_FRAMEWORK.md) for testing standards

### **For Users**
1. Check [HOMEBREW_MULTI_CHANNEL.md](HOMEBREW_MULTI_CHANNEL.md) for installation options and channel selection
2. Check [SD_CARD_DETECTION.md](SD_CARD_DETECTION.md) for SD card setup
3. Review [RELEASE_PROCESS.md](RELEASE_PROCESS.md) for release information
4. Explore [gopro/](gopro/) for GoPro-specific technical details

### **For Developers**
1. Read [FEATURE_ANALYSIS.md](feature-planning/FEATURE_ANALYSIS.md) for feature overview
2. Check [CI_CD_SUCCESS.md](testing/CI_CD_SUCCESS.md) for CI/CD status
3. Review [YAML_LINTING_SETUP.md](testing/YAML_LINTING_SETUP.md) for code quality

## 📋 Documentation Standards

### **File Naming**
- Use descriptive, lowercase names with hyphens
- Include file extensions (`.md` for Markdown)
- Group related files in subdirectories

### **Content Structure**
- Start with a clear title and description
- Use consistent heading hierarchy
- Include links to related documentation
- Reference GitHub issues when applicable

### **Maintenance**
- Update documentation when features change
- Keep [NEXT_STEPS.md](NEXT_STEPS.md) current
- Validate links and references regularly
- Follow the progress assessment guidelines

## 🔗 Related Resources

- **[AI_INSTRUCTIONS.md](../AI_INSTRUCTIONS.md)** - AI assistant guidelines and project standards
- **[README.md](../README.md)** - Main project overview
- **[LICENSE](../LICENSE)** - Project license information
- **[GitHub Issues](https://github.com/fxstein/GoProX/issues)** - Issue tracking and feature requests

## 📝 Contributing to Documentation

When adding or updating documentation:

1. **Follow the structure** outlined in this README
2. **Update this file** if adding new sections or reorganizing
3. **Use consistent formatting** and linking
4. **Reference relevant issues** in commit messages
5. **Validate links** before committing

## 🎯 Current Focus

The project is currently focused on:
- **Foundation Infrastructure** (Platform abstraction, Configuration management)
- **Core Features** (Enhanced default behavior, Firmware management)
- **Testing & Quality** (CI/CD, Linting, Validation)

See [NEXT_STEPS.md](NEXT_STEPS.md) for detailed current priorities and progress.

## 🛠️ Developer Setup

To set up your development environment with all required dependencies, use the provided Brewfile:

```zsh
brew bundle --file=scripts/maintenance/Brewfile
```

This will install all necessary tools for development, linting, and testing (e.g., yamllint, jsonlint, jq, exiftool, node). Always use this Brewfile to ensure your environment matches project standards.

---

*This documentation is maintained as part of the GoProX project. For questions or contributions, please refer to the [GitHub repository](https://github.com/fxstein/GoProX).* 