# GoProX Default Behavior Enhancement Plan

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
```bash
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
   - **Empty SD Card**: Offer to format or skip
   - **Multiple Cards**: Process each independently

#### Enhanced SD Card Detection Logic

```bash
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
   New card, empty              → Offer format or skip
   Previously processed         → Check for new content only
   Has firmware update          → Offer update first
   Error state                  → Report and skip
   ```

3. **Batch Processing**
   - Process multiple cards simultaneously
   - Provide progress indicators
   - Handle errors gracefully
   - Continue processing other cards if one fails

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

## Implementation Strategy

### Phase 1: Foundation (Immediate Priority)
1. **Configuration System Enhancement**
   - Extend existing config file format
   - Add first-time setup wizard
   - Implement configuration validation

2. **Basic Smart Detection**
   - Enhance SD card detection logic
   - Add content analysis capabilities
   - Implement basic decision making

### Phase 2: Core Features (High Priority)
1. **Automated Processing**
   - Implement smart workflow selection
   - Add batch processing capabilities
   - Create progress reporting system

2. **User Experience**
   - Design guided vs. automated modes
   - Implement status reporting
   - Add error handling and recovery

### Phase 3: Advanced Features (Medium Priority)
1. **Intelligence and Automation**
   - Add workflow templates
   - Implement scheduled processing
   - Create multi-card coordination

2. **Integration and Monitoring**
   - Launch agent integration
   - Background monitoring
   - Notification system

## Technical Requirements

### New Functions to Implement
1. `_first_time_setup()` - Guided initial configuration
2. `_enhanced_sd_card_processing()` - Smart card processing
3. `_determine_card_state()` - Content analysis
4. `_smart_workflow_selection()` - Decision making
5. `_batch_processing()` - Multi-card handling
6. `_progress_reporting()` - Status updates
7. `_error_recovery()` - Error handling

### Configuration Enhancements
1. Extended config file format
2. User preference management
3. Workflow template system
4. Error logging and reporting

### Integration Points
1. Launch agent configuration
2. Background monitoring
3. Notification system
4. Logging framework (already implemented)

## Success Metrics

### User Experience
- Reduced time from first run to productive use
- Fewer manual interventions required
- Clearer feedback and status information
- Better error handling and recovery

### Technical Performance
- Faster processing of multiple cards
- More reliable detection and processing
- Better resource utilization
- Improved error recovery

### Adoption and Usage
- Higher user retention after first use
- Increased frequency of tool usage
- Reduced support requests
- Positive user feedback

## Migration Strategy

### Backward Compatibility
- Maintain existing command-line interface
- Preserve current configuration files
- Support existing workflow options
- Gradual migration path for users

### Testing and Validation
- Comprehensive testing with various SD card scenarios
- User acceptance testing with different experience levels
- Performance testing with large media collections
- Error scenario testing and recovery validation

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