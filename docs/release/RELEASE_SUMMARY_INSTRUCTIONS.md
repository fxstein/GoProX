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

### 1. Firmware Summary (MANDATORY - Top of Document)
- **MUST** include the current firmware support status at the very top of the release notes
- Run `./scripts/release/generate-firmware-summary.zsh` to generate the firmware table
- This provides users with immediate visibility into supported models and latest firmware versions
- Place this section before any other content

### 2. New GoPro Models
- List any new GoPro camera models added since the base release

### 3. Official Firmware
- List new official firmware releases added, grouped by model

### 4. Labs Firmware
- List new GoPro Labs firmware releases added, grouped by model

### 5. Core Functionality
- SD card management, firmware updates, tool improvements

### 6. Infrastructure
- CI/CD and process improvements (minor section)

## Formatting Requirements
- **DO NOT** include a main header (e.g., "# Major Changes Since vXX.XX.XX") – the main process creates this
- Start directly with the firmware summary table
- Use bullet points for all lists
- Group firmware by model and type (Official vs Labs)

## Example Structure
```markdown
## Supported GoPro Models

The following GoPro camera models are currently supported by GoProX:

| Model | Latest Official | Latest Labs |
|-------|-----------------|-------------|
| GoPro Max | H19.03.02.02.00 | H19.03.02.02.70 |
| HERO10 Black | H21.01.01.62.00 | H21.01.01.62.70 |
| HERO11 Black | H22.01.02.32.00 | H22.01.02.32.70 |

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