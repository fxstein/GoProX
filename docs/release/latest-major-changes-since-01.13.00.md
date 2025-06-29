## Supported GoPro Models

The following GoPro camera models are currently supported by GoProX:

| Model | Latest Official | Latest Labs |
|-------|-----------------|-------------|
| GoPro Max | H19.03.02.02.00 | H19.03.02.02.70 |
| HERO10 Black | H21.01.01.62.00 | H21.01.01.62.70 |
| HERO11 Black | H22.01.02.32.00 | H22.01.02.32.70 |
| HERO11 Black Mini | H22.03.02.50.00 | H22.03.02.50.71b |
| HERO12 Black | H23.01.02.32.00 | H23.01.02.32.70 |
| HERO13 Black | H24.01.02.02.00 | H24.01.02.02.70 |
| HERO (2024) | H24.03.02.20.00 | - |
| HERO8 Black | HD8.01.02.51.00 | HD8.01.02.51.75 |
| HERO9 Black | HD9.01.01.72.00 | HD9.01.01.72.70 |
| The Remote | GP.REMOTE.FW.02.00.01 | - |

## Core Functionality

- **Enhanced CI/CD Test Workflow**: Restructured testing pipeline with proper unit test dependencies
  - Unit tests now run first and integration tests depend on their success
  - Improved error isolation and faster feedback on test failures
  - Consolidated unit test execution with new `run-unit-tests.zsh` script
  - Fixed CI compatibility issues with absolute path resolution

- **Comprehensive Testing Framework**: Enhanced test coverage and reliability
  - Logger unit tests with rotation and performance validation
  - Firmware summary generation tests with custom sorting
  - Proper test artifact management and reporting
  - Integration with CI/CD pipeline for automated validation

## Infrastructure

- **Git-Flow Release Process**: Implemented native git-flow release automation
  - Automated version bumping and workflow triggering
  - Integrated monitoring and verification system
  - Support for dry-run testing and real releases
  - Proper branch management and cleanup automation

- **Release Automation**: Enhanced release process with AI integration
  - Mandatory major changes summary file creation
  - Firmware summary table generation for release notes
  - Automated PR creation and management
  - Comprehensive release validation and monitoring

## Beta Release Notes

This is a beta release (01.50.00) that includes significant improvements to the CI/CD pipeline and testing framework. The changes focus on improving development workflow reliability and ensuring code quality through enhanced testing processes. 