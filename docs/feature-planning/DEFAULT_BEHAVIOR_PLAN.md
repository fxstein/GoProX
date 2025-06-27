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
```bash
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
```bash
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
```bash
# Archive directory structure
~/goprox/archives/
├── archive_20241201_143022/     # Full card backup
├── archive_20241201_143022.manifest
├── archive_20241201_150145/     # Incremental backup
├── archive_20241201_150145.manifest
└── .archive_config              # Retention policies
```

**Archive Configuration:**
```bash
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
8. `_create_optimized_archive()` - Archive creation with integrity checks
9. `_import_from_archive()` - Fast import from local archive
10. `_verify_archive_integrity()` - Archive integrity validation
11. `_manage_archive_lifecycle()` - Archive retention and cleanup
12. `_enforce_processing_order()` - Ensure correct operation sequence

### Configuration Enhancements
1. Extended config file format
2. User preference management
3. Workflow template system
4. Error logging and reporting
5. Archive management settings
6. Performance optimization preferences
7. Processing order enforcement
8. Archive retention policies

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
- 20-80% faster processing through archive optimization
- Reduced SD card wear through single-pass reading
- Improved parallel processing capabilities
- Better storage management and cleanup

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

## Testing Framework and CI/CD Integration

### Testing Strategy Overview

The enhanced default behavior must be thoroughly tested through our existing testing framework and CI/CD pipeline. Each behavior and feature will have dedicated test suites that validate functionality, performance, and error handling.

### Test Suite Organization

#### 1. Default Behavior Test Suite (`test-default-behavior.zsh`)

**Purpose**: Test the core default behavior when `goprox` is run without arguments.

**Test Cases**:
```bash
function test_default_behavior_no_cards() {
  # Test behavior when no SD cards are present
  # Expected: Informative message, clean exit
}

function test_default_behavior_single_card() {
  # Test behavior with one GoPro SD card
  # Expected: Detection, analysis, appropriate actions
}

function test_default_behavior_multiple_cards() {
  # Test behavior with multiple GoPro SD cards
  # Expected: Parallel processing, conflict avoidance
}

function test_default_behavior_mixed_cards() {
  # Test behavior with GoPro and non-GoPro cards
  # Expected: Only process GoPro cards, ignore others
}
```

#### 2. First-Time Setup Test Suite (`test-first-time-setup.zsh`)

**Purpose**: Test the guided first-time setup experience.

**Test Cases**:
```bash
function test_first_time_setup_flow() {
  # Test complete first-time setup process
  # Expected: Guided configuration, library creation, validation
}

function test_first_time_setup_custom_library() {
  # Test setup with custom library location
  # Expected: Custom path validation, directory creation
}

function test_first_time_setup_validation() {
  # Test configuration validation during setup
  # Expected: Error detection, user guidance, retry mechanisms
}

function test_first_time_setup_persistence() {
  # Test configuration file creation and persistence
  # Expected: Config file created, settings saved, backup created
}
```

#### 3. Processing Order Test Suite (`test-processing-order.zsh`)

**Purpose**: Validate the mandatory processing order (Archive → Import → Process → Clean).

**Test Cases**:
```bash
function test_processing_order_enforcement() {
  # Test that operations follow correct order
  # Expected: Archive first, then import, process, clean
}

function test_processing_order_interruption() {
  # Test behavior when processing is interrupted
  # Expected: Graceful handling, state preservation, recovery
}

function test_processing_order_parallel() {
  # Test parallel processing of multiple cards
  # Expected: Order maintained per card, no conflicts
}

function test_processing_order_skip_operations() {
  # Test when some operations are skipped
  # Expected: Order maintained for enabled operations
}
```

#### 4. Archive Optimization Test Suite (`test-archive-optimization.zsh`)

**Purpose**: Test the archive-first optimization strategy and performance improvements.

**Test Cases**:
```bash
function test_archive_creation() {
  # Test archive creation with integrity checks
  # Expected: Archive created, manifest generated, integrity verified
}

function test_import_from_archive() {
  # Test import from archive vs. direct import
  # Expected: Faster import, same results, integrity maintained
}

function test_archive_integrity() {
  # Test archive integrity verification
  # Expected: Corruption detection, fallback to original source
}

function test_archive_lifecycle() {
  # Test archive retention and cleanup
  # Expected: Proper retention, automatic cleanup, storage management
}

function test_archive_performance() {
  # Test performance improvements
  # Expected: Measurable speed improvements, resource optimization
}
```

#### 5. Smart Detection Test Suite (`test-smart-detection.zsh`)

**Purpose**: Test intelligent content detection and decision making.

**Test Cases**:
```bash
function test_card_state_detection() {
  # Test detection of different card states
  # Expected: Correct state identification, appropriate actions
}

function test_content_analysis() {
  # Test media content analysis
  # Expected: Accurate file counting, type detection, metadata extraction
}

function test_decision_making() {
  # Test smart workflow selection
  # Expected: Appropriate workflow chosen based on content and state
}

function test_incremental_processing() {
  # Test processing of previously handled cards
  # Expected: Only new content processed, existing content skipped
}
```

#### 6. User Experience Test Suite (`test-user-experience.zsh`)

**Purpose**: Test guided vs. automated modes and user interaction.

**Test Cases**:
```bash
function test_guided_mode() {
  # Test guided mode for new users
  # Expected: Clear explanations, confirmation prompts, helpful feedback
}

function test_automated_mode() {
  # Test automated mode for experienced users
  # Expected: Silent operation, automatic decisions, log generation
}

function test_progress_reporting() {
  # Test status and progress reporting
  # Expected: Clear progress indicators, accurate status updates
}

function test_error_handling() {
  # Test error handling and recovery
  # Expected: Clear error messages, recovery suggestions, graceful degradation
}
```

### CI/CD Integration

#### GitHub Actions Workflow Updates

**New Test Jobs**:
```yaml
jobs:
  test-default-behavior:
    name: "Test Default Behavior"
    runs-on: "ubuntu-latest"
    steps:
      - name: "Checkout code"
        uses: actions/checkout@v4
      
      - name: "Setup test environment"
        run: |
          # Create mock SD card structures
          # Setup test media files
          # Configure test scenarios
      
      - name: "Run default behavior tests"
        run: |
          ./scripts/testing/run-tests.zsh --default-behavior
      
      - name: "Upload test results"
        uses: actions/upload-artifact@v4
        with:
          name: "default-behavior-test-results"
          path: "output/test-results/"

  test-performance:
    name: "Test Performance Optimization"
    runs-on: "ubuntu-latest"
    steps:
      - name: "Performance testing"
        run: |
          ./scripts/testing/run-tests.zsh --performance
      
      - name: "Generate performance report"
        run: |
          ./scripts/testing/generate-performance-report.zsh
```

#### Test Data Management

**Test Media Files**:
```bash
test/media/
├── sd_cards/
│   ├── HERO11-1234/          # Mock GoPro SD card
│   │   ├── MISC/
│   │   │   └── version.txt   # Camera info
│   │   ├── photos/
│   │   │   ├── G0010001.JPG
│   │   │   └── G0010002.JPG
│   │   └── videos/
│   │       └── G0010001.MP4
│   ├── HERO12-5678/          # Another mock card
│   └── empty_card/           # Empty SD card
├── libraries/
│   ├── test_library_1/       # Existing library
│   └── test_library_2/       # Another library
└── archives/
    └── existing_archives/    # Pre-existing archives
```

#### Automated Test Scenarios

**Scenario Matrix**:
```bash
# Test scenarios for CI/CD
scenarios=(
  "no_cards"
  "single_card_new"
  "single_card_processed"
  "single_card_empty"
  "multiple_cards"
  "mixed_cards"
  "corrupted_card"
  "insufficient_space"
  "permission_denied"
  "interrupted_processing"
  "archive_corruption"
  "network_failure"
)
```

### Performance Testing

#### Benchmark Tests

**Performance Metrics**:
```bash
function benchmark_processing_speed() {
  # Measure processing time for different scenarios
  # Compare archive vs. direct processing
  # Track resource utilization
}

function benchmark_memory_usage() {
  # Monitor memory consumption during processing
  # Detect memory leaks
  # Optimize resource usage
}

function benchmark_storage_io() {
  # Measure I/O performance
  # Compare SD card vs. archive vs. library speeds
  # Optimize storage operations
}
```

#### Load Testing

**Load Test Scenarios**:
```bash
function test_large_collections() {
  # Test with 1000+ files
  # Test with 100GB+ data
  # Test with multiple large cards
}

function test_concurrent_processing() {
  # Test multiple cards simultaneously
  # Test parallel operations
  # Test resource contention
}
```

### Integration Testing

#### End-to-End Testing

**Complete Workflow Tests**:
```bash
function test_complete_workflow() {
  # Test entire workflow from detection to completion
  # Validate all intermediate states
  # Verify final results
}

function test_error_recovery() {
  # Test recovery from various failure points
  # Validate state restoration
  # Verify data integrity
}
```

#### Cross-Platform Testing

**Platform Compatibility**:
```bash
function test_macos_compatibility() {
  # Test on macOS (primary platform)
  # Validate macOS-specific features
  # Test launch agent integration
}

function test_linux_compatibility() {
  # Test on Linux (CI/CD environment)
  # Validate cross-platform compatibility
  # Test Linux-specific adaptations
}
```

### Test Reporting and Monitoring

#### Test Results Structure

**Test Report Format**:
```json
{
  "test_suite": "default-behavior",
  "timestamp": "2024-12-01T14:30:00Z",
  "scenarios": [
    {
      "name": "single_card_new",
      "status": "passed",
      "duration": "45.2s",
      "performance": {
        "archive_time": "12.3s",
        "import_time": "8.7s",
        "process_time": "15.2s",
        "clean_time": "2.1s"
      },
      "assertions": [
        {"name": "card_detected", "status": "passed"},
        {"name": "archive_created", "status": "passed"},
        {"name": "files_imported", "status": "passed"}
      ]
    }
  ],
  "summary": {
    "total_scenarios": 12,
    "passed": 11,
    "failed": 1,
    "performance_improvement": "65%"
  }
}
```

#### CI/CD Monitoring

**Automated Alerts**:
- Test failure notifications
- Performance regression alerts
- Coverage threshold violations
- Resource usage warnings

**Quality Gates**:
- All tests must pass
- Performance benchmarks must be met
- Code coverage must exceed 90%
- No critical security vulnerabilities

### Test Maintenance

#### Test Data Management

**Test Data Lifecycle**:
```bash
function update_test_data() {
  # Update test media files
  # Add new camera models
  # Update firmware versions
  # Maintain test data freshness
}

function cleanup_test_data() {
  # Remove old test artifacts
  # Clean up temporary files
  # Maintain storage efficiency
}
```

#### Test Suite Evolution

**Continuous Improvement**:
- Add tests for new features
- Update tests for behavior changes
- Remove obsolete test cases
- Optimize test execution time

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