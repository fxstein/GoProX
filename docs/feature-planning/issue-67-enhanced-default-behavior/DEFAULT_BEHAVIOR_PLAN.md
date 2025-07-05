# GoProX Default Behavior Enhancement Plan

> **Reference:** This document is part of [GitHub Issue #73: Enhanced Default Behavior: Intelligent Media Management Assistant](https://github.com/fxstein/GoProX/issues/73). All default behavior enhancements and related work should be tracked and discussed in this issue.

> **Note:** Project-wide or context environment variables (e.g., TRAVEL_MODE, OFFICE_MODE) are allowed, but interactive control (e.g., non-interactive, auto-confirm) must be set via command-line arguments, not environment variables.

## Core Principles (Project Standards Alignment)

- **No Automatic Destructive Actions**: GoProX must never modify user data or media files automatically. All destructive or modifying actions (including re-processing) require explicit user consent and a dedicated option. (See AI_INSTRUCTIONS.md)
- **Structured Logging**: All scripts, helpers, and migration tools must use the centralized logger module for all output, including migration logs and error reporting. No `echo` or `printf` for operational output. (See DESIGN_PRINCIPLES.md)
- **Consistent Parameter Processing**: All scripts, helpers, and migration tools must use strict parameter processing with `zparseopts`, supporting both short and long options, and providing clear error messages. (See DESIGN_PRINCIPLES.md)
- **Human-Readable Configuration**: All configuration files must remain simple, key=value, and preserve comments and readability through all migrations. (See DESIGN_PRINCIPLES.md)
- **Testing and Validation**: All new features, helpers, migrations, and behaviors must have dedicated tests, be integrated into CI/CD, and follow the project's testing framework. (See AI_INSTRUCTIONS.md)

## Overview

This document outlines the current default behavior of GoProX and proposes an enhanced default behavior system that provides a more intuitive, automated, and user-friendly experience. The goal is to make GoProX work seamlessly out-of-the-box while maintaining the flexibility for advanced users.

## Current Default Behavior Analysis

### What Happens When You Run `goprox` Without Arguments

Currently, when `goprox` is run without any arguments, it executes the `_detect_and_rename_gopro_sd()` function, which:

1. **Scans for GoPro SD Cards**: Searches `/Volumes/*` for mounted volumes
2. **Identifies GoPro Cards**: Looks for `MISC/version.txt` files containing "camera type"
3. **Extracts Camera Information**: Reads camera type, serial number, and firmware version
4. **Proposes Volume Renaming**: Suggests renaming volumes to `CAMERA_TYPE-SERIAL_LAST_4` format
5. **Checks Firmware Updates**: Identifies if newer firmware is available (official or labs)
6. **Interactive Prompts**: Asks user for confirmation on rename and firmware update actions

### Current Limitations

1. **No First-Time Setup**: No guided initial configuration
2. **Limited Automation**: Requires manual confirmation for every action
3. **No Media Processing**: Doesn't automatically import or process media files
4. **No Library Management**: Doesn't set up or manage the media library
5. **No Persistent Configuration**: Doesn't remember user preferences
6. **No Error Recovery**: Limited handling of edge cases and failures

## Proposed Enhanced Default Behavior

### Phase 1: First-Time Run Experience

#### Initial Setup Flow
When `goprox` is run for the first time on a system (no config file exists):

1. **Welcome and Introduction**
   ```
   Welcome to GoProX v01.10.00!
   
   GoProX is your GoPro media management assistant. Let's get you set up.
   ```

2. **Library Configuration**
   - Suggest default library location: `~/goprox`
   - Allow user to specify custom location
   - Create library structure automatically
   - Validate write permissions

3. **Processing Preferences**
   - Ask about automatic import preferences
   - Configure default processing options
   - Set up copyright information
   - Choose firmware update preferences

4. **SD Card Detection Setup**
   - Explain automatic SD card detection
   - Configure mount event handling
   - Set up launch agent for automatic processing

5. **Configuration Persistence**
   - Save all preferences to `~/.goprox`
   - Create backup of configuration
   - Provide configuration validation

#### Configuration File Structure
```zsh
# GoProX Configuration File
LIBRARY=~/goprox
COPYRIGHT=""
GEONAMES_ACCOUNT=""

# Default Processing Options
AUTO_IMPORT=true
AUTO_PROCESS=true
AUTO_ARCHIVE=true
AUTO_CLEAN=true
AUTO_FIRMWARE_CHECK=true

# SD Card Preferences
AUTO_RENAME_SD_CARDS=true
FIRMWARE_TYPE=official  # official, labs, or both
PROMPT_FOR_CONFIRMATION=false

# Mount Event Configuration
MOUNT_OPTIONS=(--archive --import --clean --firmware)
ENABLE_LAUNCH_AGENT=true

# Advanced Options
LOG_LEVEL=2
QUIET_MODE=false
```

### Phase 2: Subsequent Run Behavior

#### Normal Operation Flow
When `goprox` is run on subsequent occasions:

1. **Configuration Validation**
   - Check if config file exists and is valid
   - Validate library directory and permissions
   - Verify dependencies are installed

2. **SD Card Detection and Processing**
   - Scan for mounted GoPro SD cards
   - For each detected card:
     - Check if it's been processed before
     - Determine appropriate actions based on content
     - Execute configured workflows

3. **Smart Decision Making**
   - **New SD Card with Media**: Import and process automatically
   - **Previously Processed Card**: Check for new content only
   - **Empty SD Card**: Offer to clean (remove media files) or skip
   - **Multiple Cards**: Process each independently

#### Enhanced SD Card Detection Logic

```zsh
function _enhanced_sd_card_processing() {
  for volume in /Volumes/*; do
    if _is_gopro_card "$volume"; then
      local card_state=$(_determine_card_state "$volume")
      
      case $card_state in
        "new_with_media")
          _process_new_card_with_media "$volume"
          ;;
        "new_empty")
          _handle_empty_card "$volume"
          ;;
        "previously_processed")
          _check_for_new_content "$volume"
          ;;
        "needs_firmware_update")
          _offer_firmware_update "$volume"
          ;;
        "error_state")
          _handle_card_error "$volume"
          ;;
      esac
    fi
  done
}
```

### Phase 3: Smart Content Detection

#### Media Content Analysis
For each detected SD card, analyze the content:

1. **Content Detection**
   - Count media files (JPG, MP4, 360, etc.)
   - Check for existing processed markers
   - Determine if card is empty or has content

2. **Processing Decision Matrix**
   ```
   Card State                    Action
   ──────────────────────────────────────────────────────────
   New card with media          → Import + Process + Archive
   New card, empty              → Offer clean or skip
   Previously processed         → Check for new content only
   Has firmware update          → Offer update first
   Error state                  → Report and skip
   ```

3. **Batch Processing**
   - Process multiple cards simultaneously
   - Provide progress indicators
   - Handle errors gracefully
   - Continue processing other cards if one fails

### Phase 3.5: Processing Order and Performance Optimization

#### Mandatory Processing Order
When performing any tasks in interactive or batch mode, the following order must be strictly enforced:

**Standard Processing Order:**
1. **Archive** - Create backup of original files
2. **Import** - Copy files to library structure
3. **Process** - Apply metadata, copyright, and transformations
4. **Clean** - Remove processed files from source

#### Archive-First Optimization Strategy

**Problem**: Reading from SD cards is the slowest part of the process, especially with large media collections.

**Solution**: Leverage the archive created in step 1 to perform subsequent operations, significantly improving performance.

#### Implementation Details

**Archive Creation Phase:**
```zsh
function _create_optimized_archive() {
  local source="$1"
  local archive_dir="$2"
  
  # Create timestamped archive directory
  local timestamp=$(date +%Y%m%d_%H%M%S)
  local archive_path="${archive_dir}/archive_${timestamp}"
  
  # Use rsync for efficient copying with progress
  rsync -av --progress "$source/" "$archive_path/"
  
  # Create archive manifest for integrity verification
  find "$archive_path" -type f -exec sha256sum {} \; > "${archive_path}.manifest"
  
  echo "$archive_path"
}
```

**Archive-Based Import:**
```zsh
function _import_from_archive() {
  local archive_path="$1"
  local library="$2"
  
  # Import from archive instead of SD card
  # This is much faster as archive is on local storage
  rsync -av --progress "$archive_path/" "$library/imported/"
  
  # Verify integrity using manifest
  _verify_archive_integrity "$archive_path"
}
```

**Performance Benefits:**
- **SD Card Read**: Single pass through SD card (archive creation)
- **Subsequent Operations**: Read from fast local storage (archive)
- **Parallel Processing**: Multiple operations can read from archive simultaneously
- **Error Recovery**: Archive provides backup for retry operations

#### Processing Flow Examples

**New Card with Media (Optimized):**
```
1. Archive: Copy all files from SD card to local archive (slow)
2. Import: Copy from archive to library (fast)
3. Process: Read from archive, write to library (fast)
4. Clean: Remove from SD card (fast)
```

**Previously Processed Card (Incremental):**
```
1. Archive: Copy only new files to archive (fast)
2. Import: Copy new files from archive (fast)
3. Process: Process new files from archive (fast)
4. Clean: Remove processed files from SD card (fast)
```

#### Archive Management

**Archive Lifecycle:**
1. **Creation**: During archive phase of processing
2. **Utilization**: During import and process phases
3. **Retention**: Keep for configurable period (default: 30 days)
4. **Cleanup**: Automatic removal of old archives

**Archive Storage Strategy:**
```zsh
# Archive directory structure
~/goprox/archives/
├── archive_20241201_143022/     # Full card backup
├── archive_20241201_143022.manifest
├── archive_20241201_150145/     # Incremental backup
├── archive_20241201_150145.manifest
└── .archive_config              # Retention policies
```

**Archive Configuration:**
```zsh
# Archive settings in config file
ARCHIVE_RETENTION_DAYS=30
ARCHIVE_COMPRESSION=true
ARCHIVE_VERIFICATION=true
ARCHIVE_CLEANUP_AUTO=true
```

#### Error Handling and Recovery

**Archive Integrity:**
- Verify archive integrity before using for import
- Re-create archive if corruption detected
- Use original SD card as fallback if archive fails

**Partial Processing Recovery:**
- Resume processing from archive if interrupted
- Skip already processed files based on markers
- Maintain processing state across restarts

**Storage Management:**
- Monitor archive storage usage
- Implement automatic cleanup of old archives
- Provide manual archive management tools

#### Performance Monitoring

**Metrics to Track:**
- Archive creation time vs. direct import time
- Storage space utilization
- Archive hit/miss ratios
- Overall processing time improvements

**Expected Performance Gains:**
- **First Run**: 20-30% faster due to single SD card read
- **Subsequent Runs**: 50-70% faster due to archive reuse
- **Large Collections**: 60-80% faster due to local storage access

### Phase 4: User Experience Enhancements

#### Interactive vs. Automated Modes
Provide two operation modes:

1. **Guided Mode** (Default for new users)
   - Clear explanations of what's happening
   - Confirmation prompts for important actions
   - Progress indicators and status updates
   - Helpful error messages and recovery suggestions

2. **Automated Mode** (For experienced users)
   - Silent operation with minimal output
   - Automatic decision making based on configuration
   - Log file generation for review
   - Email notifications for completion/failures

#### Status and Progress Reporting
```
GoProX v01.10.00 - Media Management Assistant

🔍 Scanning for GoPro SD cards...
✅ Found 2 GoPro SD cards

📱 HERO11-1234 (previously processed)
   └─ Checking for new content...
   └─ Found 15 new photos, 3 new videos
   └─ Importing media files...
   └─ Processing metadata...
   └─ ✅ Complete: 18 files processed

📱 HERO12-5678 (new card)
   └─ Detected 45 photos, 12 videos
   └─ Importing to library...
   └─ Processing with copyright info...
   └─ Archiving original files...
   └─ ✅ Complete: 57 files imported

📊 Summary: 2 cards processed, 75 files handled
⏱️  Total time: 2m 34s
```

### Phase 5: Advanced Features

#### Intelligent Workflow Management
1. **Workflow Templates**
   - Quick import (import only)
   - Full processing (import + process + archive)
   - Archive only (for already imported cards)
   - Firmware update only

2. **Scheduled Processing**
   - Background monitoring for new cards
   - Automatic processing at specific times
   - Integration with macOS launch agents

3. **Multi-Card Coordination**
   - Process multiple cards in parallel
   - Avoid conflicts when multiple cards are present
   - Prioritize cards based on content or user preference

#### Error Handling and Recovery
1. **Graceful Degradation**
   - Continue processing other cards if one fails
   - Provide clear error messages and recovery steps
   - Log all errors for debugging

2. **Data Protection**
   - Verify file integrity before processing
   - Create backups of important metadata
   - Prevent accidental data loss

3. **Recovery Tools**
   - Resume interrupted processing
   - Repair corrupted metadata
   - Recover from failed operations

#### SD Card Cleaning and Optional Formatting

**Default Behavior: Clean, Don't Format**
GoProX follows a conservative approach to SD card management, prioritizing data safety and camera compatibility.

**Standard SD Card Cleaning:**
```zsh
function _clean_sd_card() {
  local card_path="$1"
  
  # Preserve camera metadata only (not macOS system files)
  local preserve_patterns=(
    "MISC/version.txt"           # Camera identification
    "DCIM/"                      # Camera directory structure
    "MISC/"                      # Camera system files
  )
  
  # Remove only media files, preserve camera structure
  find "$card_path" -type f \( -name "*.JPG" -o -name "*.MP4" -o -name "*.LRV" -o -name "*.THM" \) -delete
  
  # Clean empty directories (except preserved ones)
  _clean_empty_directories "$card_path" "$preserve_patterns"
  
  echo "✅ SD card cleaned: Media files removed, camera metadata preserved"
}
```

**Optional Formatting with Metadata Preservation:**
For advanced users who need a completely fresh SD card, GoProX provides an optional formatting feature that preserves and restores only camera metadata (not macOS system files).

**Formatting Workflow:**
```zsh
function _format_sd_card_with_metadata_preservation() {
  local card_path="$1"
  
  # Step 1: Extract camera metadata (camera files only, not macOS files)
  local metadata_backup="$(_extract_camera_metadata "$card_path")"
  
  # Step 2: Perform low-level format (user confirmation required)
  read -q "REPLY?⚠️  This will completely erase the SD card. Continue? (y/N) "
  echo
  
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Format the card (requires elevated privileges)
    _perform_sd_card_format "$card_path"
    
    # Step 3: Restore camera metadata (macOS files will be recreated automatically)
    _restore_camera_metadata "$card_path" "$metadata_backup"
    
    echo "✅ SD card formatted and camera metadata restored"
  else
    echo "❌ Formatting cancelled"
    rm -rf "$metadata_backup"
  fi
}
```

**Metadata Extraction and Restoration:**
```zsh
function _extract_camera_metadata() {
  local card_path="$1"
  local backup_dir="/tmp/goprox_metadata_$(date +%s)"
  
  mkdir -p "$backup_dir"
  
  # Extract critical camera files only (not macOS system files)
  if [[ -f "$card_path/MISC/version.txt" ]]; then
    cp -r "$card_path/MISC" "$backup_dir/"
  fi
  
  # Extract camera directory structure only
  if [[ -d "$card_path/DCIM" ]]; then
    find "$card_path/DCIM" -type d -exec mkdir -p "$backup_dir/DCIM/{}" \;
  fi
  
  # Note: macOS files (.Spotlight-V100, .fseventsd, .Trashes) are NOT preserved
  # They will be recreated automatically when the card is mounted
  
  echo "$backup_dir"
}

function _restore_camera_metadata() {
  local card_path="$1"
  local backup_dir="$2"
  
  # Restore camera metadata only
  if [[ -d "$backup_dir/MISC" ]]; then
    cp -r "$backup_dir/MISC" "$card_path/"
  fi
  
  # Restore camera directory structure only
  if [[ -d "$backup_dir/DCIM" ]]; then
    find "$backup_dir/DCIM" -type d -exec mkdir -p "$card_path/DCIM/{}" \;
  fi
  
  # macOS system files (.Spotlight-V100, .fseventsd, .Trashes) are NOT restored
  # They will be recreated automatically by macOS when the card is mounted
  
  # Clean up backup
  rm -rf "$backup_dir"
}
```

**Configuration Options:**
```zsh
# SD card management preferences
SD_CARD_CLEANING_MODE="preserve_metadata"  # clean, format, or preserve_metadata
SD_CARD_FORMAT_CONFIRMATION=true           # Require confirmation for formatting
SD_CARD_METADATA_BACKUP=true               # Always backup metadata before format
SD_CARD_QUICK_CLEAN=true                   # Enable quick clean for empty cards
```

**User Interface:**
```zsh
# Empty SD card handling
function _handle_empty_sd_card() {
  local card_path="$1"
  
  echo "📱 Empty SD card detected: $(basename "$card_path")"
  echo "Options:"
  echo "  1. Clean (remove any remaining files, preserve camera metadata)"
  echo "  2. Format (complete erase with metadata preservation) ⚠️"
  echo "  3. Skip (leave card unchanged)"
  
  read -p "Choose option (1-3): " choice
  
  case $choice in
    1) _clean_sd_card "$card_path" ;;
    2) _format_sd_card_with_metadata_preservation "$card_path" ;;
    3) echo "Skipping card" ;;
    *) echo "Invalid choice, skipping card" ;;
  esac
}
```

**Safety Features:**
- **Metadata Preservation**: Always backup and restore camera identification files
- **Confirmation Required**: Formatting requires explicit user confirmation
- **Fallback Protection**: If metadata restoration fails, card remains usable
- **Logging**: All formatting operations are logged for audit purposes
- **Recovery**: Metadata backup is retained until successful restoration

### Phase 6: Multi-System User Scenarios

#### Professional Workflow Environments

Professional photographers and videographers often work across multiple systems and environments. GoProX must adapt its default behavior based on the current environment and user context.

#### Environment Detection and Adaptation

**System Environment Detection:**
```zsh
function _detect_environment() {
  local environment="unknown"
  
  # Check for travel/field indicators
  if [[ -n "$(system_profiler SPUSBDataType | grep -i 'external')" ]]; then
    environment="travel"
  elif [[ -n "$(df -h | grep -E '/Volumes/.*[0-9]{3,}GB')" ]]; then
    environment="travel"  # Large external storage detected
  elif [[ -f "$HOME/.goprox/environment" ]]; then
    environment=$(cat "$HOME/.goprox/environment")
  else
    # Default to office if no indicators found
    environment="office"
  fi
  
  echo "$environment"
}
```

#### Travel/Field Environment Defaults

**Scenario**: Photographer/videographer traveling with laptop and external storage

**Environment Characteristics:**
- Limited storage space on laptop
- External storage for temporary media
- Need for quick processing and review
- Limited time for full processing
- Focus on backup and basic organization

**Default Behaviors:**
```zsh
# Travel environment configuration
TRAVEL_MODE=true
LIBRARY="$HOME/goprox/travel"
ARCHIVE_DIR="$HOME/goprox/travel/archives"
PROCESSING_MODE="quick"
AUTO_CLEAN=true
AUTO_ARCHIVE=true
AUTO_PROCESS=false  # Skip heavy processing
COPYRIGHT=""
GEONAMES=false
FIRMWARE_CHECK=true
RENAME_CARDS=true

# Travel-specific processing order
TRAVEL_PROCESSING_ORDER=(
  "archive"    # Always backup first
  "import"     # Quick import to travel library
  "clean"      # Clean SD card for reuse
)
```

**Travel Mode Workflow:**
1. **Archive First**: Create backup to external storage
2. **Quick Import**: Import to travel library with minimal processing
3. **Clean SD Card**: Remove processed files to free up card space
4. **Skip Heavy Processing**: Defer metadata processing, geonames, etc.
5. **Generate Travel Summary**: Create quick overview of imported content

#### Office/Studio Environment Defaults

**Scenario**: Same user back in office with permanent storage and processing capabilities

**Environment Characteristics:**
- Large storage capacity
- High-performance processing
- Time for comprehensive processing
- Integration with permanent library
- Full metadata and organization

**Default Behaviors:**
```zsh
# Office environment configuration
OFFICE_MODE=true
LIBRARY="$HOME/goprox/permanent"
ARCHIVE_DIR="$HOME/goprox/permanent/archives"
PROCESSING_MODE="comprehensive"
AUTO_CLEAN=true
AUTO_ARCHIVE=true
AUTO_PROCESS=true
COPYRIGHT="$(cat ~/.goprox/copyright)"
GEONAMES=true
FIRMWARE_CHECK=true
RENAME_CARDS=true

# Office-specific processing order
OFFICE_PROCESSING_ORDER=(
  "archive"    # Backup to permanent storage
  "import"     # Import to permanent library
  "process"    # Full metadata processing
  "geonames"   # Add location data
  "clean"      # Clean source after verification
)
```

**Office Mode Workflow:**
1. **Comprehensive Archive**: Backup to permanent storage with integrity checks
2. **Full Import**: Import to permanent library with organization
3. **Complete Processing**: Apply metadata, copyright, geonames
4. **Integration**: Merge with existing library structure
5. **Verification**: Verify all files before cleaning source

#### Environment Transition Management

**Travel to Office Transition:**
```zsh
function _handle_travel_to_office_transition() {
  local travel_library="$HOME/goprox/travel"
  local office_library="$HOME/goprox/permanent"
  
  # Detect travel content that needs processing
  if [[ -d "$travel_library/imported" ]] && [[ -n "$(ls -A "$travel_library/imported")" ]]; then
    echo "🔄 Detected travel content requiring office processing..."
    
    # Offer to process travel content
    read -q "REPLY?Process travel content with full office workflow? (y/N) "
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      _process_travel_content "$travel_library" "$office_library"
    fi
  fi
}
```

**Travel Content Processing:**
```zsh
function _process_travel_content() {
  local travel_library="$1"
  local office_library="$2"
  
  # Process travel content with full office workflow
  for session in "$travel_library/imported"/*; do
    if [[ -d "$session" ]]; then
      echo "📁 Processing travel session: $(basename "$session")"
      
      # Apply full processing workflow
      _archive_from_travel "$session" "$office_library"
      _import_to_office "$session" "$office_library"
      _process_with_metadata "$session" "$office_library"
      _add_geonames "$session" "$office_library"
      
      # Mark as processed
      touch "$session/.office_processed"
    fi
  done
  
  # Clean up travel library after successful processing
  _cleanup_travel_library "$travel_library"
}
```

#### Multi-System Configuration Management

**Configuration Synchronization:**
```zsh
# Configuration file structure for multi-system users
~/.goprox/
├── config                    # Base configuration
├── environment              # Current environment (travel/office)
├── travel_config           # Travel-specific overrides
├── office_config           # Office-specific overrides
├── copyright               # Copyright information
├── geonames_account        # Geonames account details
└── sync_status             # Last sync timestamp
```

**Environment-Specific Overrides:**
```zsh
# Travel configuration overrides
source ~/.goprox/travel_config 2>/dev/null || {
  # Default travel settings
  LIBRARY="$HOME/goprox/travel"
  PROCESSING_MODE="quick"
  AUTO_PROCESS=false
}

# Office configuration overrides
source ~/.goprox/office_config 2>/dev/null || {
  # Default office settings
  LIBRARY="$HOME/goprox/permanent"
  PROCESSING_MODE="comprehensive"
  AUTO_PROCESS=true
}
```

#### Smart Environment Switching

**Automatic Environment Detection:**
```zsh
function _switch_environment() {
  local new_environment="$1"
  local current_environment="$(_detect_environment)"
  
  if [[ "$new_environment" != "$current_environment" ]]; then
    echo "🔄 Switching from $current_environment to $new_environment mode..."
    
    # Save current environment
    echo "$new_environment" > "$HOME/.goprox/environment"
    
    # Load environment-specific configuration
    _load_environment_config "$new_environment"
    
    # Handle any pending transitions
    if [[ "$current_environment" == "travel" ]] && [[ "$new_environment" == "office" ]]; then
      _handle_travel_to_office_transition
    fi
    
    echo "✅ Switched to $new_environment mode"
  fi
}
```

#### Professional Workflow Templates

**Travel Template**: `--template travel`
- Quick backup and import
- Minimal processing
- SD card cleanup
- Travel library organization

**Office Template**: `--template office`
- Comprehensive processing
- Full metadata application
- Permanent library integration
- Quality verification

**Hybrid Template**: `--template hybrid`
- Smart environment detection
- Adaptive processing based on context
- Seamless transition handling

#### Multi-System User Experience

**Environment-Aware Status Reporting:**
```
GoProX v01.10.00 - Media Management Assistant
🌍 Environment: Travel Mode

🔍 Scanning for GoPro SD cards...
✅ Found 1 GoPro SD card

📱 HERO11-1234 (new card)
   └─ Travel processing mode detected
   └─ Creating backup to external storage...
   └─ Quick import to travel library...
   └─ Cleaning SD card for reuse...
   └─ ✅ Complete: 45 files backed up

📊 Summary: 1 card processed in travel mode
💡 Tip: Run 'goprox --switch-office' when back in studio for full processing
```

**Transition Notifications:**
```
🔄 Travel to Office Transition Detected

Found 3 travel sessions requiring full processing:
- Session_20241201_143022 (45 files)
- Session_20241201_150145 (32 files)
- Session_20241201_160230 (18 files)

Would you like to process these with full office workflow? (y/N)
```

#### Configuration Examples

**Travel Configuration:**
```zsh
# ~/.goprox/travel_config
LIBRARY="$HOME/goprox/travel"
ARCHIVE_DIR="/Volumes/ExternalStorage/goprox/backups"
PROCESSING_MODE="quick"
AUTO_PROCESS=false
AUTO_CLEAN=true
COPYRIGHT=""
GEONAMES=false
FIRMWARE_CHECK=true
RENAME_CARDS=true
```

**Office Configuration:**
```zsh
# ~/.goprox/office_config
LIBRARY="$HOME/goprox/permanent"
ARCHIVE_DIR="$HOME/goprox/permanent/archives"
PROCESSING_MODE="comprehensive"
AUTO_PROCESS=true
AUTO_CLEAN=true
COPYRIGHT="$(cat ~/.goprox/copyright)"
GEONAMES=true
FIRMWARE_CHECK=true
RENAME_CARDS=true
```

## Multi-Library Support

### Overview

Multi-library support enables users to maintain multiple independent media libraries on a single system, each with its own configuration, processing rules, and organization structure. This feature addresses the needs of professional users who work on different projects, time periods, or storage locations.

### Use Cases

**Professional Workflows:**
- **Project-based libraries**: Separate libraries for different client projects
- **Time-based libraries**: Annual or seasonal media collections
- **Storage-based libraries**: Libraries on different storage devices or locations
- **Workflow-based libraries**: Different processing workflows for different types of content

**Personal Organization:**
- **Event libraries**: Separate collections for special events or trips
- **Device libraries**: Different libraries for different cameras or devices
- **Archive libraries**: Long-term storage with minimal processing
- **Active libraries**: Current projects with full processing

### Library Management System

#### Library Configuration Structure

**Multi-Library Configuration:**
```zsh
# ~/.goprox/libraries.conf - Library registry
# Format: library_name|path|description|default_processing|created_date
personal|~/goprox/personal|Personal media collection|comprehensive|2024-01-15
client_project_a|~/goprox/clients/project_a|Client A project media|quick|2024-02-20
travel_2024|~/goprox/travel/2024|2024 travel collection|archive_only|2024-03-10
archive|~/goprox/archive|Long-term archive|minimal|2024-01-01
```

**Library-Specific Configuration:**
```zsh
# ~/.goprox/libraries/personal.conf
LIBRARY=~/goprox/personal
COPYRIGHT="My Name"
GEONAMES_ACCOUNT="my_geonames"
PROCESSING_MODE=comprehensive
AUTO_IMPORT=true
AUTO_PROCESS=true
AUTO_ARCHIVE=true
AUTO_CLEAN=true

# ~/.goprox/libraries/client_project_a.conf
LIBRARY=~/goprox/clients/project_a
COPYRIGHT="Client A"
GEONAMES_ACCOUNT=""
PROCESSING_MODE=quick
AUTO_IMPORT=true
AUTO_PROCESS=false
AUTO_ARCHIVE=true
AUTO_CLEAN=true
```

#### Library Selection and Switching

**Library Selection Interface:**
```zsh
function _select_library() {
  local libraries=($(_get_available_libraries))
  
  if [[ ${#libraries[@]} -eq 0 ]]; then
    echo "No libraries configured. Creating default library..."
    _create_default_library
    return
  fi
  
  echo "📚 Available Libraries:"
  for i in {1..${#libraries[@]}}; do
    local library_info="$(_get_library_info "${libraries[$i]}")"
    echo "  $i. $library_info"
  done
  
  read -p "Select library (1-${#libraries[@]}): " choice
  
  if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le ${#libraries[@]} ]]; then
    local selected_library="${libraries[$choice]}"
    _switch_to_library "$selected_library"
    echo "✅ Switched to library: $selected_library"
  else
    echo "❌ Invalid selection"
    return 1
  fi
}
```

**Library Switching Function:**
```zsh
function _switch_to_library() {
  local library_name="$1"
  local library_config="$HOME/.goprox/libraries/${library_name}.conf"
  
  if [[ ! -f "$library_config" ]]; then
    log_error "Library configuration not found: $library_config"
    return 1
  fi
  
  # Load library-specific configuration
  source "$library_config"
  
  # Update current library reference
  echo "$library_name" > "$HOME/.goprox/current_library"
  
  # Validate library structure
  _validate_library_structure "$LIBRARY"
  
  log_info "Switched to library: $library_name ($LIBRARY)"
}
```

### Library Operations

#### Library Creation and Management

**Create New Library:**
```zsh
function _create_library() {
  local library_name="$1"
  local library_path="$2"
  local description="$3"
  local processing_mode="$4"
  
  # Validate library name
  if [[ ! "$library_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    log_error "Invalid library name: $library_name"
    return 1
  fi
  
  # Create library directory structure
  mkdir -p "$library_path"/{imported,processed,archives,metadata}
  
  # Create library configuration
  _create_library_config "$library_name" "$library_path" "$description" "$processing_mode"
  
  # Register library in main registry
  _register_library "$library_name" "$library_path" "$description" "$processing_mode"
  
  log_info "Created library: $library_name at $library_path"
}
```

**Library Configuration Template:**
```zsh
function _create_library_config() {
  local library_name="$1"
  local library_path="$2"
  local description="$3"
  local processing_mode="$4"
  
  local config_file="$HOME/.goprox/libraries/${library_name}.conf"
  
  cat > "$config_file" << EOF
# GoProX Library Configuration: $library_name
# Description: $description
# Created: $(date +%Y-%m-%d)

LIBRARY="$library_path"
COPYRIGHT=""
GEONAMES_ACCOUNT=""
PROCESSING_MODE="$processing_mode"

# Processing Options
AUTO_IMPORT=true
AUTO_PROCESS=true
AUTO_ARCHIVE=true
AUTO_CLEAN=true
AUTO_FIRMWARE_CHECK=true

# Library-Specific Settings
LIBRARY_NAME="$library_name"
LIBRARY_DESCRIPTION="$description"
CREATED_DATE="$(date +%Y-%m-%d)"
LAST_ACCESS="$(date +%Y-%m-%d)"
EOF
}
```

#### Library Validation and Maintenance

**Library Structure Validation:**
```zsh
function _validate_library_structure() {
  local library_path="$1"
  
  local required_dirs=("imported" "processed" "archives" "metadata")
  local missing_dirs=()
  
  for dir in "${required_dirs[@]}"; do
    if [[ ! -d "$library_path/$dir" ]]; then
      missing_dirs+=("$dir")
    fi
  done
  
  if [[ ${#missing_dirs[@]} -gt 0 ]]; then
    log_warn "Missing library directories: ${missing_dirs[*]}"
    read -q "REPLY?Create missing directories? (y/N) "
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      for dir in "${missing_dirs[@]}"; do
        mkdir -p "$library_path/$dir"
        log_info "Created directory: $library_path/$dir"
      done
    else
      log_error "Library structure validation failed"
      return 1
    fi
  fi
  
  log_info "Library structure validated: $library_path"
}
```

### Integration with Default Behavior

#### Multi-Library Default Behavior

**First-Time Setup with Library Selection:**
```zsh
function _first_time_setup_with_libraries() {
  echo "Welcome to GoProX v01.10.00!"
  echo "GoProX is your GoPro media management assistant."
  echo ""
  
  # Ask about library preferences
  echo "How would you like to organize your media?"
  echo "1. Single library (recommended for most users)"
  echo "2. Multiple libraries (for professional workflows)"
  
  read -p "Choose option (1-2): " choice
  
  case $choice in
    1)
      _setup_single_library
      ;;
    2)
      _setup_multi_library
      ;;
    *)
      echo "Invalid choice, setting up single library"
      _setup_single_library
      ;;
  esac
}
```

**Multi-Library Setup:**
```zsh
function _setup_multi_library() {
  echo "Setting up multi-library system..."
  
  # Create libraries directory
  mkdir -p "$HOME/.goprox/libraries"
  
  # Create default libraries
  _create_library "personal" "$HOME/goprox/personal" "Personal media collection" "comprehensive"
  _create_library "archive" "$HOME/goprox/archive" "Long-term archive" "minimal"
  
  # Set personal as default
  _switch_to_library "personal"
  
  echo "✅ Multi-library system configured"
  echo "📚 Default libraries created:"
  echo "  - personal: $HOME/goprox/personal"
  echo "  - archive: $HOME/goprox/archive"
  echo ""
  echo "Use 'goprox --library <name>' to switch between libraries"
}
```

#### Library-Aware Processing

**Library-Aware SD Card Processing:**
```zsh
function _process_sd_card_with_library_selection() {
  local card_path="$1"
  
  # Check if multiple libraries are available
  local libraries=($(_get_available_libraries))
  
  if [[ ${#libraries[@]} -gt 1 ]]; then
    echo "📱 GoPro SD card detected: $(basename "$card_path")"
    echo "📚 Select target library:"
    
    for i in {1..${#libraries[@]}}; do
      local library_info="$(_get_library_info "${libraries[$i]}")"
      echo "  $i. $library_info"
    done
    
    read -p "Select library (1-${#libraries[@]}): " choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le ${#libraries[@]} ]]; then
      local selected_library="${libraries[$choice]}"
      _switch_to_library "$selected_library"
      _process_sd_card "$card_path"
    else
      echo "❌ Invalid selection, using current library"
      _process_sd_card "$card_path"
    fi
  else
    # Single library, process normally
    _process_sd_card "$card_path"
  fi
}
```

### Command-Line Interface

#### Library Management Commands

**Library Command Structure:**
```zsh
# Library management commands
goprox --library list                    # List all libraries
goprox --library create <name> <path>    # Create new library
goprox --library switch <name>           # Switch to library
goprox --library info <name>             # Show library information
goprox --library validate <name>         # Validate library structure
goprox --library delete <name>           # Delete library (with confirmation)

# Processing with specific library
goprox --library <name> --import         # Import to specific library
goprox --library <name> --process        # Process in specific library
goprox --library <name> --archive        # Archive to specific library
```

### Configuration and Persistence

#### Library Registry Management

**Library Registry Functions:**
```zsh
function _get_available_libraries() {
  local registry_file="$HOME/.goprox/libraries.conf"
  
  if [[ -f "$registry_file" ]]; then
    cut -d'|' -f1 "$registry_file"
  else
    echo "default"
  fi
}

function _register_library() {
  local name="$1"
  local path="$2"
  local description="$3"
  local processing_mode="$4"
  
  local registry_file="$HOME/.goprox/libraries.conf"
  local entry="$name|$path|$description|$processing_mode|$(date +%Y-%m-%d)"
  
  echo "$entry" >> "$registry_file"
  
  log_info "Registered library: $name"
}

function _get_library_info() {
  local library_name="$1"
  local registry_file="$HOME/.goprox/libraries.conf"
  
  if [[ -f "$registry_file" ]]; then
    local line=$(grep "^$library_name|" "$registry_file")
    if [[ -n "$line" ]]; then
      local path=$(echo "$line" | cut -d'|' -f2)
      local description=$(echo "$line" | cut -d'|' -f3)
      echo "$library_name: $description ($path)"
    else
      echo "$library_name: Not found in registry"
    fi
  else
    echo "$library_name: Default library"
  fi
}
```

### Testing and Validation

#### Multi-Library Test Suite

**Library Management Tests:**
```zsh
function test_library_creation() {
  # Test library creation and configuration
  # Expected: Library created, config generated, structure validated
}

function test_library_switching() {
  # Test switching between libraries
  # Expected: Config loaded, environment updated, validation passed
}

function test_library_validation() {
  # Test library structure validation
  # Expected: Missing directories detected, auto-creation works
}

function test_multi_library_processing() {
  # Test processing with library selection
  # Expected: Correct library selected, processing completed
}
```

### Future Implementation Considerations

**Implementation Requirements:**
- **Library isolation**: Each library must be completely independent
- **Configuration inheritance**: Global settings with library-specific overrides
- **Cross-library operations**: Ability to move/copy between libraries
- **Library backup/restore**: Complete library backup and restoration
- **Library synchronization**: Sync libraries across multiple systems
- **Library analytics**: Usage statistics and storage management
- **Library templates**: Pre-configured library types for common workflows

**Technical Considerations:**
- **Storage management**: Handle libraries on different storage devices
- **Performance optimization**: Efficient library switching and validation
- **Error handling**: Graceful handling of missing or corrupted libraries
- **Migration support**: Upgrade library structures across versions
- **Integration testing**: Comprehensive testing of multi-library scenarios

## Future Considerations

### Potential Enhancements
1. **Machine Learning Integration**
   - Learn user preferences over time
   - Predict optimal processing workflows
   - Automatic workflow optimization

2. **Cloud Integration**
   - Backup to cloud storage
   - Sync across multiple devices
   - Remote processing capabilities

3. **Advanced Analytics**
   - Processing statistics and trends
   - Performance optimization suggestions
   - Usage pattern analysis

### Scalability Considerations
- Support for larger media collections
- Multi-user environments
- Network storage integration
- Distributed processing capabilities

## Conclusion

The enhanced default behavior will transform GoProX from a command-line tool into an intelligent media management assistant. By providing a guided first-time experience, smart automation, and clear feedback, users will be able to focus on their creative work rather than managing technical details.

The implementation will be phased to ensure stability and user adoption, with each phase building upon the previous one to create a comprehensive and user-friendly system.

**Implementation Requirements:**
- All new helpers, environment switchers, and migration tools must use the logger for all output (including status, errors, and logs).
- All new helpers and scripts must use strict parameter processing with `zparseopts`.
- All new helpers and behaviors must have dedicated tests and CI/CD validation.

**Migration Requirements:**
- All migration helpers and scripts must use the logger for all output (including migration logs and errors).
- All migration helpers and scripts must use strict parameter processing with `zparseopts`.
- All migration helpers and scripts must have dedicated tests and CI/CD validation.
- All configuration migrations must preserve comments and human readability in config files. 