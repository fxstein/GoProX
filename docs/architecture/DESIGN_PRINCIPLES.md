# GoProX Design Principles

> **Reference:** This document is anchored by [GitHub Issue #70: Architecture: Establish Design Principles and Architectural Documentation Framework](https://github.com/fxstein/GoProX/issues/70). All architectural and design principles, as well as significant decisions, should be tracked and discussed in this issue.

This document establishes the foundational architectural decisions and design patterns that should be consistently applied across the entire GoProX project. These principles guide all design decisions and ensure consistency, maintainability, and user experience.

## Core Principles

### 1. Simplicity First

**Principle:** Design for simplicity in both usage and operation, especially for non-expert users.

**Rationale:** GoProX serves users who want to manage their GoPro media without becoming command-line experts. The tool should be intuitive and straightforward to use.

**Implementation Guidelines:**
- Prefer simple, clear command-line interfaces over complex options
- Use descriptive, self-explanatory parameter names
- Provide sensible defaults that work for most users
- Minimize the number of steps required for common operations
- Design error messages that guide users toward solutions

**Examples in GoProX:**
- Default source directory is current directory (`.`)
- Default library location is `~/goprox`
- Simple command structure: `goprox --import` vs complex nested options
- Automatic detection and validation of GoPro SD cards

### 2. Consistent Parameter Processing

**Principle:** All scripts in the project must use the same parameter processing approach as the main `goprox` script.

**Rationale:** Consistency in how options are parsed, validated, and handled ensures predictable behavior across all project components and reduces cognitive load for users and developers.

**Implementation Requirements:**
- Use `zparseopts` for strict parameter validation
- Support both short (`-v`) and long (`--verbose`) option formats
- Provide clear error messages for invalid options
- Use consistent option naming conventions across all scripts
- Support option aliases where appropriate (e.g., `--base` and `--prev`)

**Current Implementation Pattern:**
```zsh
# Parse options using zparseopts for strict parameter validation
declare -A opts
zparseopts -D -E -F -A opts - \
            h -help \
            v -verbose \
            q -quiet \
            --config: \
            || {
    # Unknown option
    _error "Unknown option: $@"
    exit 1
}

# Process parsed options
for key val in "${(kv@)opts}"; do
    case $key in
        -h|--help)
            _help
            exit 0
            ;;
        -v|--verbose)
            loglevel=1
            ;;
        # ... other options
    esac
done
```

**Scripts That Must Follow This Pattern:**
- `goprox` (main script)
- `scripts/release/*.zsh`
- `scripts/maintenance/*.zsh`
- `scripts/firmware/*.zsh`
- Any new scripts added to the project

### 3. Human-Readable Configuration

**Principle:** Configuration files should be easily readable and editable by humans without requiring knowledge of structured data formats.

**Rationale:** While YAML and JSON offer benefits for complex configurations, GoProX prioritizes accessibility. Users should be able to view, understand, and modify their configuration without learning new syntax.

**Implementation Guidelines:**
- Use simple key=value pairs in configuration files
- Support comments in configuration files where possible
- Provide clear documentation for each configuration option
- Use descriptive variable names
- Maintain backward compatibility when possible
- Include examples of all possible entries as comments at the very top of the configuration file

**Current Implementation:**
```bash
# ~/.goprox configuration file
# Example configuration with all possible entries:
# source=.
# library="~/goprox"
# copyright="Your Name or Organization"
# geonamesacct="your_geonames_username"
# mountoptions=(--archive --import --clean --firmware)

source=.
library="~/goprox"
copyright="My Name"
geonamesacct=""
mountoptions=(--archive --import --clean --firmware)
```

**Benefits:**
- No special tools or knowledge required to edit
- Easy to copy/paste between systems
- Simple to version control
- Clear and unambiguous syntax
- Users can see all available options at a glance
- Examples show proper syntax and formatting

### 3a. Configuration-Driven Release Management

**Principle:** All release and CI/CD automation is managed through configuration files, ensuring traceability, auditability, and flexibility in the release process.

**Rationale:** By centralizing release management settings (such as the current release tracking issue) in a dedicated YAML config file, GoProX ensures that all version bump and release automation is both reproducible and easily auditable. This approach supports compliance with commit standards and enables seamless updates to release management practices.

**Implementation Guidelines:**
- Store all release management and CI/CD configuration in the `config/` directory
- Use YAML for internal automation/config files (not end-user facing)
- Track the current release management issue in `config/release-issue.yaml` (e.g., `release_issue: 72`)
- All version bump and release commits must reference the current release management issue from this config
- Update the config file whenever a new release management issue is created
- Document this process in both AI_INSTRUCTIONS.md and CONTRIBUTING.md

**Benefits:**
- Ensures every release and version bump is traceable to a single management issue
- Simplifies updates to release tracking and automation
- Supports compliance with project commit message standards
- Provides a clear audit trail for all release activities

**Reference:**
- [Release Management and Tracking Issue #72](https://github.com/fxstein/GoProX/issues/72)
- See also: `config/release-issue.yaml`

### 4. Progressive Enhancement

**Principle:** Start with simple, working functionality and enhance it progressively based on user needs and feedback.

**Rationale:** This approach ensures that core functionality is always available and working, while advanced features can be added without breaking the fundamental user experience.

**Implementation Guidelines:**
- Core features should work with minimal configuration
- Advanced features should be opt-in
- New features should not break existing workflows
- Provide clear upgrade paths for users

**Examples:**
- Basic import/process works with defaults
- Advanced filtering and time-shifting are optional
- Firmware management is an enhancement, not a requirement
- GeoNames integration is optional

### 5. Platform Consistency

**Principle:** Maintain consistent behavior across supported platforms while respecting platform-specific conventions.

**Rationale:** Users may work across different systems, and the tool should provide a predictable experience regardless of platform.

**Implementation Guidelines:**
- Use platform-appropriate default paths
- Respect platform-specific file system conventions
- Provide platform-specific documentation where needed
- Test functionality across all supported platforms

**Current Platform Support:**
- macOS (primary platform)
- Linux (secondary platform)
- Windows (planned)

### 6. Error Handling and Recovery

**Principle:** Provide clear, actionable error messages and graceful recovery from failures.

**Rationale:** Users should understand what went wrong and how to fix it, rather than being left with cryptic error messages.

**Implementation Guidelines:**
- Use descriptive error messages that explain the problem
- Provide specific guidance on how to resolve issues
- Implement graceful degradation when possible
- Log errors with sufficient detail for debugging
- Validate inputs early and provide clear feedback

**Current Implementation:**
- Validation of dependencies (exiftool, jq)
- Storage hierarchy validation with automatic creation
- Clear error messages with suggested solutions
- Logging at multiple levels (debug, info, warning, error)

### 7. Documentation-Driven Development

**Principle:** Document design decisions and architectural choices as they are made.

**Rationale:** Clear documentation helps maintain consistency across the project and provides context for future development decisions.

**Implementation Guidelines:**
- Document architectural decisions in this document
- Update documentation when making significant changes
- Provide examples and use cases in documentation
- Keep documentation close to the code it describes

### 8. Comprehensive Testing Framework

**Principle:** All new features and capabilities must have dedicated tests that are executed on demand and during build processes.

**Rationale:** Comprehensive testing ensures code quality, prevents regressions, and provides confidence in the reliability of the software. It enables safe refactoring and helps catch issues early in the development cycle.

**Implementation Requirements:**
- Every new feature must include dedicated test cases
- Tests must be executable on demand via command-line
- Tests must be integrated into CI/CD build processes
- Test coverage should include both positive and negative scenarios
- Tests must be documented with clear descriptions of what they validate
- Failed tests must provide clear, actionable error messages
- Test data should be version-controlled and minimal

**Current Implementation:**
- GoProX includes a `--test` option for running comprehensive tests
- Test data is stored in `test/` directory with sample media files
- Tests validate import, process, archive, and firmware functionality
- Tests compare output against expected results using git diff

**Test Categories Required:**
- **Unit Tests:** Test individual functions and components in isolation
- **Integration Tests:** Test interactions between components
- **Functional Tests:** Test complete workflows and user scenarios
- **Regression Tests:** Ensure existing functionality continues to work
- **Platform Tests:** Validate behavior across supported platforms
- **Configuration Tests:** Test various configuration scenarios
- **Error Handling Tests:** Verify proper error messages and recovery

**Testing Standards:**
- Tests must be deterministic and repeatable
- Tests should not depend on external services unless explicitly testing integration
- Test execution time should be reasonable (under 5 minutes for full suite)
- Tests must clean up after themselves
- Test output should be clear and actionable

**Examples in GoProX:**
- `goprox --test` runs the complete test suite
- Tests validate file renaming, metadata extraction, and directory structure
- Tests ensure firmware detection and processing works correctly
- Tests verify configuration loading and validation

### 9. Local Linting and Format Validation

**Principle:** Catch file format and syntax errors locally before they reach CI/CD pipelines, using automated tools and pre-commit hooks.

**Rationale:** Preventing format and syntax errors at the local development level reduces CI/CD failures, improves developer productivity, and maintains code quality standards. It ensures that issues are caught and fixed early in the development cycle rather than after pushing to remote repositories.

**Implementation Requirements:**
- Implement pre-commit hooks for file format validation
- Use industry-standard linting tools for each file type
- Provide automated fixers for common formatting issues
- Ensure linting tools are available in both local and CI environments
- Configure linting rules to match project standards
- Provide clear error messages that guide developers to solutions

**Current Implementation:**
- YAML linting with `yamllint` for GitHub Actions workflow files
- Pre-commit hook (`.git/hooks/pre-commit`) validates staged workflow files
- Automated YAML fixer script (`scripts/maintenance/fix-yaml-formatting.zsh`)
- Comprehensive documentation for linting setup and troubleshooting
- Integration with existing commit message validation hooks

**Linting Standards:**
- **YAML Files:** Use `yamllint` with project-specific configuration
- **Shell Scripts:** Use `shellcheck` for syntax and best practices validation
- **Configuration Files:** Validate syntax and format consistency
- **Documentation:** Ensure proper Markdown formatting and structure
- **JSON Files:** Validate syntax and schema compliance where applicable

**Pre-commit Hook Requirements:**
- Only validate staged files to minimize execution time
- Provide specific file type detection and appropriate linting
- Block commits with format errors while allowing clean commits
- Include helpful error messages with line numbers and suggestions
- Support both automatic fixes and manual resolution guidance

**Automated Fixer Requirements:**
- Create backups before making changes
- Fix common issues automatically (trailing spaces, newlines, etc.)
- Report which issues were fixed and which require manual attention
- Provide clear guidance for manual fixes when automation isn't possible
- Maintain file integrity and avoid introducing new issues

**Benefits:**
- **Reduced CI/CD Failures:** Prevents format errors from reaching remote pipelines
- **Improved Developer Experience:** Clear, immediate feedback on format issues
- **Consistent Code Quality:** Enforces project standards across all contributors
- **Faster Development Cycles:** Catch issues early, avoid CI/CD delays
- **Automated Maintenance:** Reduce manual formatting work through automated fixers

**Examples in GoProX:**
- YAML workflow files are validated before commits
- Pre-commit hook prevents commits with YAML syntax errors
- Automated fixer removes trailing spaces and ensures proper newlines
- Clear error messages guide developers to specific line numbers and issues
- Integration with existing commit message validation workflow

### 10. Homebrew Standardization for Dependencies

**Principle:** Always standardize on Homebrew (brew) for installation of all local dependencies on supported platforms.

**Rationale:** Using a single, widely adopted package manager ensures consistency, simplifies onboarding, and reduces environment drift. Homebrew is the de facto standard for macOS and is well-supported on Linux, making it the preferred choice for managing dependencies in the GoProX project.

**Implementation Guidelines:**
- All required tools and dependencies (e.g., yamllint, jsonlint, exiftool, jq) should be installed via Homebrew whenever possible
- Documentation and setup scripts must reference Homebrew as the installation method
- Avoid mixing package managers (e.g., npm, pip, apt) for core dependencies unless absolutely necessary
- If a dependency is not available via Homebrew, document the alternative installation method and rationale
- Ensure CI/CD and local environments use the same dependency installation approach for consistency

## Decision Recording Process

When making significant design or architectural decisions:

1. **Consider the principles:** Does the decision align with our established principles?
2. **Document the decision:** Add it to this document with rationale and implementation guidelines
3. **Update AI Instructions:** Ensure the AI assistant is aware of new principles
4. **Communicate changes:** Notify the team of new design decisions

## Review and Evolution

This document should be reviewed and updated as the project evolves. New principles may be added, and existing ones may be refined based on:

- User feedback and experience
- Technical requirements and constraints
- Platform support needs
- Performance and scalability requirements

## Questions for New Features

When implementing new features, consider these questions:

1. **Simplicity:** Is this the simplest way to achieve the goal?
2. **Consistency:** Does this follow our established patterns?
3. **Accessibility:** Can users understand and modify this without special knowledge?
4. **Platform Support:** Does this work consistently across supported platforms?
5. **Error Handling:** How will this fail gracefully and provide clear feedback?
6. **Documentation:** Is this decision worth documenting for future reference?

---

*This document should be consulted when making any significant design decisions in the GoProX project. When in doubt, prioritize simplicity and user experience over technical elegance.* 