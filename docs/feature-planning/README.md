# GoProX Feature Planning Summary

This document provides a summary of all open feature and enhancement issues for GoProX, with links to detailed implementation strategy documents for each.

---

## Table of Contents

- [Issue #69: Enhanced SD Card Management](./ISSUE-69-ENHANCED_SD_CARD_MANAGEMENT.md)
- [Issue #68: AI Instructions Tracking and Evolution](./ISSUE-68-AI_INSTRUCTIONS_TRACKING.md)
- [Issue #67: Enhanced Default Behavior](./ISSUE-67-ENHANCED_DEFAULT_BEHAVIOR.md)
- [Issue #66: Repository Cleanup and Organization](./ISSUE-66-REPOSITORY_CLEANUP.md)
- [Issue #65: Firmware Automation](./ISSUE-65-FIRMWARE_AUTOMATION.md)
- [Issue #64: Exclude Firmware Zip Files](./ISSUE-64-EXCLUDE_FIRMWARE_ZIP.md)
- [Issue #63: SD Card Volume Renaming](./ISSUE-63-SD_CARD_RENAMING.md)
- [Issue #60: Firmware URL-Based Fetch](./ISSUE-60-FIRMWARE_URL_FETCH.md)
- [Issue #59: FreeBSD Port](./ISSUE-59-FREEBSD_PORT.md)
- [Issue #57: DJI Drone Support](./ISSUE-57-DJI_DRONE_SUPPORT.md)
- [Issue #38: Timezone Independent Tests](./ISSUE-38-TIMEZONE_INDEPENDENT_TESTS.md)
- [Issue #29: Single File Summary](./ISSUE-29-SINGLE_FILE_SUMMARY.md)
- [Issue #26: Delta Patch Compression](./ISSUE-26-DELTA_PATCH_COMPRESSION.md)
- [Issue #25: Downsample Videos](./ISSUE-25-DOWNSAMPLE_VIDEOS.md)
- [Issue #20: Git-flow Model Implementation](./ISSUE-20-GIT_FLOW_MODEL.md)
- [Issue #13: Propagate and Collect Deletes](./ISSUE-13-PROPAGATE_AND_COLLECT_DELETES.md)
- [Issue #11: AWS Glacier Support](./ISSUE-11-AWS_GLACIER_SUPPORT.md)
- [Issue #10: Multi-Tier Storage Support](./ISSUE-10-MULTI_TIER_STORAGE.md)
- [Issue #6: GPSTime Support](./ISSUE-6-GPSTIME.md)
- [Issue #2: Windows Platform Support](./ISSUE-2-WINDOWS_SUPPORT.md)

---

## Feature Summaries

### [Issue #69: Enhanced SD Card Management](./ISSUE-69-ENHANCED_SD_CARD_MANAGEMENT.md)
See the linked document for a detailed technical plan to transform GoProX into an intelligent, SD card-aware system with automatic detection, renaming, multi-card workflow, and persistent tracking.

### [Issue #68: AI Instructions Tracking and Evolution](./ISSUE-68-AI_INSTRUCTIONS_TRACKING.md)
Centralizes and evolves AI instructions for project automation, standards, and assistant behavior. Proposes a registry, validation, and evolution workflow.

### [Issue #67: Enhanced Default Behavior](./ISSUE-67-ENHANCED_DEFAULT_BEHAVIOR.md)
Describes the plan to make GoProX automatically detect and manage GoPro SD cards by default, integrating firmware management and user-friendly workflows.

### [Issue #66: Repository Cleanup and Organization](./ISSUE-66-REPOSITORY_CLEANUP.md)
Outlines a comprehensive cleanup and reorganization of the repository, including Git LFS, script organization, file header standards, and documentation updates.

### [Issue #65: Firmware Automation](./ISSUE-65-FIRMWARE_AUTOMATION.md)
Details automation for maintaining the latest firmware packages, including a central registry, automated scanning, and test install workflows.

### [Issue #64: Exclude Firmware Zip Files](./ISSUE-64-EXCLUDE_FIRMWARE_ZIP.md)
Explains how to exclude firmware zip files from release packages using .gitattributes and updates to the release process.

### [Issue #63: SD Card Volume Renaming](./ISSUE-63-SD_CARD_RENAMING.md)
Covers the implementation of standardized SD card volume renaming based on camera model and serial number.

### [Issue #60: Firmware URL-Based Fetch](./ISSUE-60-FIRMWARE_URL_FETCH.md)
Describes the redesign of firmware processing to use URL-based fetch and a local cache, reducing repository size and improving efficiency.

### [Issue #59: FreeBSD Port](./ISSUE-59-FREEBSD_PORT.md)
Proposes the creation of a FreeBSD port for GoProX, including packaging, dependency mapping, and size optimization.

### [Issue #57: DJI Drone Support](./ISSUE-57-DJI_DRONE_SUPPORT.md)
Plans for adding basic support for importing and processing DJI drone media, including detection logic and workflow integration.

### [Issue #38: Timezone Independent Tests](./ISSUE-38-TIMEZONE_INDEPENDENT_TESTS.md)
Addresses making the test option timezone independent for consistent results across environments.

### [Issue #29: Single File Summary](./ISSUE-29-SINGLE_FILE_SUMMARY.md)
Outlines the ability to analyze a single file and provide a summary of metadata, warnings, and file location.

### [Issue #26: Delta Patch Compression](./ISSUE-26-DELTA_PATCH_COMPRESSION.md)
Describes delta patch compression for optional files to reduce storage requirements while allowing restoration.

### [Issue #25: Downsample Videos](./ISSUE-25-DOWNSAMPLE_VIDEOS.md)
Covers the creation of video previews by downsampling and time-limiting videos for easier sharing and review.

### [Issue #20: Git-flow Model Implementation](./ISSUE-20-GIT_FLOW_MODEL.md)
Proposes migration to the git-flow model for better collaboration, stability, and release management.

### [Issue #13: Propagate and Collect Deletes](./ISSUE-13-PROPAGATE_AND_COLLECT_DELETES.md)
Details a system for propagating and collecting deletes from Apple Photos and other platforms to keep the library clean.

### [Issue #11: AWS Glacier Support](./ISSUE-11-AWS_GLACIER_SUPPORT.md)
Describes archiving media to AWS S3 Glacier for long-term, cost-effective storage.

### [Issue #10: Multi-Tier Storage Support](./ISSUE-10-MULTI_TIER_STORAGE.md)
Covers support for multi-tier storage setups, including mobile vs home/office configurations and automated migration.

### [Issue #6: GPSTime Support](./ISSUE-6-GPSTIME.md)
Plans for using GPS timestamps and timezone info for processed media files, enabling timecode synchronization.

### [Issue #2: Windows Platform Support](./ISSUE-2-WINDOWS_SUPPORT.md)
Proposes adapting GoProX for Windows, including installer, documentation, and community testing. 