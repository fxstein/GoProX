# GoProX – Major Changes Since v00.52.00

This document summarizes the major changes, enhancements, and fixes introduced in GoProX since version 00.52.00.

## Highlights
- Automated, issue-driven release notes and changelog generation
- Major improvements to firmware management, validation, and discovery
- Enhanced Homebrew installation, upgrade, and troubleshooting documentation
- Repository cleanup, organization, and new developer tools

## Issues Addressed

### Issue #68: Enhancement: AI Instructions Tracking and Evolution
- Release process and AI instructions are now tightly integrated and automated
- All release script changes require commit/push and dry run validation before real release
- Automated Markdown issue list generation and project awareness for AI

### Issue #66: Repository Cleanup and Organization
- Improved script headers and usage documentation
- Standardized organization of scripts and documentation

### Issue #65: Enhancement/Workflow: Automate maintenance of latest firmware packages (official & labs)
- Added firmware-tracker and firmware wiki table generator
- Improved automation for official and labs firmware packages

### Issue #64: Enhancement: Exclude firmware zip files from release packages via .gitattributes
- Firmware zip files are now excluded from release packages and tracked with Git LFS
- Enhanced filter-repo operations and performance monitoring

### Issue #63: Enhancement: Rename SD card volume label to HERO11-8909 format
- Added SD card volume renaming script and documentation

### Issue #62: Enhancement: Add firmware URL validation tool
- Added automated firmware URL validation script
- Improved error handling for HTTP redirects and license headers

### Issue #60: Feature: Redesign firmware processing to use URL-based fetch and local cache
- New scripts for adding and downloading firmware URLs
- All firmware updates now use direct URLs and local caching

### Issue #20: Workflow: Implement git-flow Model
- Unified, automated, and dry-run enabled full release process
- Release notes are now grouped by issue with titles and unreferenced commits under 'Other Commits'
- Major refactor of release automation, workflow, and documentation

## For a complete list of all changes and minor commits, see the full release notes or changelog. 