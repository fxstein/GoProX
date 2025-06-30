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

- **Enhanced SD Card Management**: Improved GoPro SD card detection and processing
  - Better camera model identification and metadata extraction
  - Enhanced firmware version detection and update capabilities
  - Improved error handling for various GoPro camera models
  - More robust SD card mounting and unmounting processes

- **Firmware Management System**: Streamlined firmware update process
  - Automatic firmware version checking on SD card mount
  - Support for both official and GoPro Labs firmware
  - Intelligent firmware update recommendations
  - Enhanced firmware compatibility validation

- **Media Processing Pipeline**: Optimized media file handling
  - Improved EXIF data extraction and processing
  - Enhanced file organization and naming conventions
  - Better handling of various media formats (JPG, MP4, LRV, THM)
  - Streamlined import and archive processes

## Infrastructure

- **Git-Flow Release Process**: Implemented comprehensive release automation
  - Automated version bumping and workflow triggering
  - Integrated monitoring and verification system
  - Support for dry-run testing and real releases
  - Proper branch management and cleanup automation

- **Enhanced CI/CD Pipeline**: Improved testing and validation framework
  - Restructured testing pipeline with proper unit test dependencies
  - Unit tests run first, integration tests depend on their success
  - Improved error isolation and faster feedback on test failures
  - Fixed CI compatibility issues with absolute path resolution

- **Release Automation**: Enhanced release process with AI integration
  - Mandatory major changes summary file creation
  - Automated PR creation and management
  - Comprehensive release validation and monitoring
  - Improved release note generation and formatting

## Beta Release Notes

This beta release (01.50.00) focuses on improving the core GoProX functionality with enhanced SD card management, firmware handling, and media processing capabilities. The changes prioritize user experience improvements while maintaining the robust infrastructure that supports the development workflow. 