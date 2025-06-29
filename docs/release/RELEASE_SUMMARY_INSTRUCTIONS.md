# Release Summary Instructions

This document defines the required content and formatting for the major changes summary file used in all GoProX releases.

## File Location and Naming
- The summary file MUST be created/updated before any release or dry run.
- Path: `docs/release/latest-major-changes-since-<BASE>.md`
- Replace `<BASE>` with the previous version (no leading 'v').
- This file MUST exist before the release process starts.

## Content Prioritization
- **Primary focus:** GoProX functionality (SD card management, firmware updates, core goprox tool functionality)
- **Secondary focus:** CI/CD improvements, release process automation, and other infrastructure changes
- Always lead with user-facing features and core tool capabilities
- Keep process improvements as a minor part of the summary

## Required Content Sections
- **New GoPro Models**: List any new GoPro camera models added since the base release
- **Official Firmware**: List new official firmware releases added, grouped by model
- **Labs Firmware**: List new GoPro Labs firmware releases added, grouped by model
- **Core Functionality**: SD card management, firmware updates, tool improvements
- **Infrastructure**: CI/CD and process improvements (minor section)

## Formatting Requirements
- **DO NOT** include a main header (e.g., "# Major Changes Since vXX.XX.XX") – the main process creates this
- Start directly with section headers (e.g., `## New GoPro Models`)
- Use bullet points for all lists
- Group firmware by model and type (Official vs Labs)

## Example Structure
```markdown
## New GoPro Models
- HERO12 Black

## Official Firmware
- HERO12 Black
  - H23.01.02.32.00

## Labs Firmware
- HERO12 Black
  - H23.01.02.32.70

## Core Functionality
- **Centralized Logging System**: Implemented comprehensive logging module
- **Enhanced Release Process**: Added summary file preservation controls

## Infrastructure
- **CI/CD Integration**: Enhanced testing framework
- **Release Automation**: Improved full-release script
```

---

**This document is MANDATORY READING for all release and summary generation tasks.** 