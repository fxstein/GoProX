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
   - [docs/README.md](./docs/README.md) — Documentation structure and navigation

## 🛠️ Development Standards

- **Code Quality:**
  - All code must pass linting and validation before being committed (YAML, JSON, and shell scripts).
  - Use the pre-commit hook to catch issues early.
  - Follow the project's [Design Principles](./docs/architecture/DESIGN_PRINCIPLES.md).
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