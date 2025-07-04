# GoProX Default Behavior

## Overview

When you run `goprox` without any specific processing options, the CLI automatically performs a **default SD card detection and management workflow**. This document details exactly what tasks are performed in this default mode.

## Default Behavior Trigger

The default behavior is triggered when **no processing options** are specified:

```zsh
goprox                    # Default behavior
goprox --verbose         # Default behavior with verbose output
goprox --dry-run         # Default behavior in dry-run mode
```

**Processing options that bypass default behavior:**
- `--archive` - Archive media files
- `--import` - Import media files  
- `--process` - Process imported files
- `--clean` - Clean source SD cards
- `--firmware` - Update firmware
- `--eject` - Eject SD cards
- `--enhanced` - Enhanced intelligent workflow
- `--rename-cards` - SD card renaming only

## Default Workflow: `_detect_and_rename_gopro_sd()`

The default behavior executes the `_detect_and_rename_gopro_sd()` function, which performs the following tasks:

### 1. SD Card Detection

**Scanning Process:**
- Scans all mounted volumes in `/Volumes/*`
- Skips system volumes (`Macintosh HD`, `.timemachine`, `Time Machine`)
- Identifies GoPro SD cards by checking for `MISC/version.txt` file
- Validates GoPro cards by checking for "camera type" in version file

**Information Extracted:**
- Camera type (e.g., "HERO11 Black", "GoPro Max")
- Camera serial number
- Current firmware version
- Volume UUID (using `diskutil info`)

### 2. SD Card Naming Analysis

**Naming Convention:**
- **Format:** `CAMERA_TYPE-SERIAL_LAST_4`
- **Example:** `HERO11-8034` (from HERO11 Black with serial ending in 8034)

**Naming Rules:**
- Removes "Black" from camera type names
- Replaces spaces with hyphens
- Removes special characters (keeps only A-Z, a-z, 0-9, hyphens)
- Uses last 4 digits of serial number
- Checks if current name already matches expected format
- **Automatically renames cards without prompting**

**Examples:**
- `HERO11 Black` + serial `C3461324698034` → `HERO11-8034`
- `GoPro Max` + serial `C3461324696013` → `GoPro-Max-6013`

### 3. Firmware Analysis

**Firmware Type Detection:**
- **Official firmware:** Standard GoPro firmware versions
- **Labs firmware:** Versions ending in `.7x` (e.g., `.70`, `.71`, `.72`)

**Firmware Update Check:**
- Scans local firmware database (`firmware/` and `firmware.labs/` directories)
- Compares current version with latest available version
- Identifies if firmware update is available
- Checks if firmware update files already exist on card

**Firmware Update Process:**
- Offers to download and prepare firmware update
- Downloads firmware to cache if not already cached
- Extracts firmware files to `UPDATE/` directory on SD card
- Creates firmware marker file (`.goprox.fwchecked`)
- Camera will install update on next power cycle

### 4. Interactive User Prompts

**Firmware Updates:**
```
Do you want to update to H22.01.02.32.00? (y/N)
```



**Safety Checks:**
- Confirms before any destructive operations
- Checks for naming conflicts (if target name already exists)
- Validates device permissions and access

### 5. Summary Reporting

**Final Summary:**
```
Summary: Found 2 GoPro SD card(s)
  - 1 already correctly named
  - 1 renamed
  - 1 firmware updates prepared
```

**Counts Reported:**
- Total GoPro cards found
- Cards already correctly named
- Cards successfully renamed
- Firmware updates prepared

## Enhanced Default Behavior: `--enhanced`

When using `--enhanced`, GoProX runs an intelligent media management workflow:

### Enhanced Workflow Features

**1. Smart Card Detection**
- Uses enhanced detection algorithms
- Analyzes card content and state
- Determines optimal processing workflows

**2. Intelligent Workflow Selection**
- Analyzes card state (new, archived, imported, cleaned)
- Recommends optimal processing sequence
- Considers content type and size

**3. Workflow Analysis**
- Displays detailed workflow plan
- Shows estimated duration
- Indicates priority level

**4. User Confirmation**
- Presents workflow summary
- Requests user approval
- Supports dry-run mode



## Mount Event Processing: `--mount`

When triggered by mount events, GoProX can automatically process newly mounted cards:

### Mount Processing Features

**1. Automatic Detection**
- Monitors for newly mounted volumes
- Validates GoPro SD card format
- Creates lock files to prevent conflicts

**2. Configurable Actions**
- Archive media files
- Import media files
- Clean processed cards
- Update firmware

**3. Interactive Ejection**
- Offers to eject cards after processing
- 30-second timeout for response
- Requires sudo for unmounting

## Configuration Integration

### Default Settings

**Library Configuration:**
- Uses configured library path from config file
- Validates library structure and permissions
- Creates library directories if needed

**Processing Preferences:**
- Copyright information
- GeoNames account settings
- Firmware update preferences

**Mount Event Configuration:**
- Configurable mount event actions
- Automatic processing options
- Ejection preferences

## Error Handling

### Safety Mechanisms

**1. Validation Checks**
- Verifies GoPro card format
- Checks file system permissions
- Validates configuration settings

**2. Conflict Resolution**
- Checks for naming conflicts
- Validates target paths
- Prevents overwriting existing data

**3. Error Recovery**
- Graceful handling of failures
- Detailed error reporting
- Rollback capabilities

## Logging and Output

### Output Levels

**Quiet Mode (`--quiet`):**
- Only error messages
- Minimal output

**Normal Mode:**
- Info messages
- Progress indicators
- Summary reports

**Verbose Mode (`--verbose`):**
- Detailed debug information
- Step-by-step progress
- Extended logging

**Debug Mode (`--debug`):**
- Full debug output
- Internal state information
- Performance metrics

## Examples

### Basic Default Behavior
```zsh
$ goprox
Scanning for GoPro SD cards...
Found GoPro SD card: GOPRO
  Camera type: HERO11 Black
  Serial number: C3461324698034
  Firmware version: H22.01.01.20.00
  Firmware type: official
  Newer official firmware available: H22.01.01.20.00 → H22.01.02.32.00

Do you want to update to H22.01.02.32.00? (y/N): y
Updating firmware...
Firmware update prepared. Camera will install upgrade during next power on.

Auto-renaming 'GOPRO' to 'HERO11-8034'...
Successfully renamed 'GOPRO' to 'HERO11-8034'

Summary: Found 1 GoPro SD card(s)
  - 1 renamed
  - 1 firmware updates prepared
SD card detection finished.
```

### Enhanced Default Behavior
```zsh
$ goprox --enhanced
🎥 GoProX Intelligent Media Management Assistant
================================================

Scanning for GoPro SD cards and analyzing optimal workflows...

📋 Workflow Analysis
===================
Card: HERO11-8034 (HERO11 Black)
  State: New with media
  Content: 45 photos, 12 videos (2.3 GB)
  Recommended: Archive → Import → Process → Clean

Estimated duration: 5-10 minutes
Proceed with workflow execution? [Y/n]: Y
```

### Dry-Run Mode
```zsh
$ goprox --dry-run --verbose
🚦 DRY RUN MODE ENABLED
======================
All actions will be simulated. No files will be modified or deleted.

Scanning for GoPro SD cards...
Found GoPro SD card: GOPRO
  Camera type: HERO11 Black
  Serial number: C3461324698034
  Firmware version: H22.01.01.20.00
  Proposed new name: HERO11-8034
  [DRY RUN] Would rename 'GOPRO' to 'HERO11-8034'
```

## Best Practices

### When to Use Default Behavior

**Use default behavior for:**
- Quick card inspection and naming
- Firmware update management
- Basic card organization
- Initial setup and configuration

**Use enhanced behavior for:**
- Complete media processing workflows
- Intelligent workflow optimization
- Multi-card management
- Automated processing

**Use specific options for:**
- Targeted operations (archive only, import only)
- Batch processing workflows
- Custom processing sequences
- Automated scripts

**Firmware Management:**
- `goprox --firmware` - Update firmware (stays with current type)
- `goprox --firmware-labs` - Update to labs firmware (preferred)
- `goprox --rename-cards --firmware-labs` - Rename and update to labs firmware

### Safety Considerations

**Always:**
- Review proposed changes before confirming
- Use `--dry-run` for testing
- Backup important data before processing
- Check firmware compatibility

**Avoid:**
- Running without reviewing changes
- Skipping confirmation prompts
- Processing cards with important unbacked-up data
- Interrupting firmware updates

## Troubleshooting

### Common Issues

**No cards detected:**
- Ensure cards are properly mounted
- Check card format and structure
- Verify GoPro card format (MISC/version.txt)

**Permission errors:**
- Check file system permissions
- Ensure proper user access
- Verify sudo access for volume operations

**Firmware issues:**
- Check internet connectivity
- Verify firmware cache directory
- Ensure sufficient card space

**Naming conflicts:**
- Check for existing volume names
- Use unique serial numbers
- Verify target name availability 