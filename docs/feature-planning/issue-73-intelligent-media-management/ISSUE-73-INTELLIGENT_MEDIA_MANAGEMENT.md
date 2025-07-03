# Issue #73: Intelligent Media Management Assistant

**Issue Title**: Enhanced Default Behavior: Intelligent Media Management Assistant  
**Status**: Open  
**Assignee**: fxstein  
**Labels**: enhancement, default-behavior, media-management, automation

## Overview

Transform GoProX into an intelligent media management assistant that automatically detects, processes, and manages GoPro media with minimal user intervention while maintaining full control when needed.

## Current State

GoProX currently requires manual configuration and explicit command execution for each operation. Users must:
- Manually specify source and library directories
- Run separate commands for archive, import, process, and clean
- Manually check for firmware updates
- Configure each operation individually
- Handle errors and edge cases manually

## Use Cases and Requirements

This section documents all use cases and requirements for the Intelligent Media Management system. Each use case serves as a validation checkpoint for implementation.

### **Use Case 1: SD Card Tracking Over Time**
**Description**: Track SD cards across multiple cameras and processing sessions over time.

**Requirements**:
- Record every time an SD card is inserted into any GoPro camera
- Track which specific camera used which specific SD card and when
- Support SD card reuse across multiple cameras
- Maintain complete history of all SD card usage
- Track processing computer and location for each usage

**Validation Criteria**:
- [ ] Can query complete history of any SD card across all cameras
- [ ] Can identify which camera is currently using a specific SD card
- [ ] Can track processing location and computer for each usage
- [ ] Can handle SD cards used in multiple cameras over time

### **Use Case 2: Camera Settings Management**
**Description**: Store and track camera settings per camera, with ability to write settings to SD cards.

**Requirements**:
- Store camera-specific settings in YAML configuration files
- Track settings changes over time with timestamps
- Write settings to SD cards during processing
- Associate settings with specific camera serial numbers
- Maintain settings history for audit purposes

**Validation Criteria**:
- [ ] Can store camera settings in `~/.goprox/cameras/<serial>/settings.yaml`
- [ ] Can track all settings changes with timestamps
- [ ] Can write settings to SD cards during processing
- [ ] Can retrieve settings history for any camera
- [ ] Can associate settings with specific camera serial numbers

### **Use Case 3: Archive Tracking and Metadata**
**Description**: Track archives with complete source attribution and location information.

**Requirements**:
- Create unique archive names that can be used to lookup source information
- Track source SD card and camera for every archive
- Record processing computer and location for each archive
- Associate archives with specific libraries
- Track archive size and media file count
- Support cloud storage location tracking

**Validation Criteria**:
- [ ] Can find archive by name and get complete source details
- [ ] Can track processing location and computer for each archive
- [ ] Can associate archives with libraries and cloud storage
- [ ] Can query archive statistics (size, file count)
- [ ] Can track archive migration between storage locations

### **Use Case 4: Media File Association**
**Description**: Associate every media file with its complete source chain.

**Requirements**:
- Link every media file to source SD card and camera
- Track original filename from SD card
- Associate media files with archives
- Link media files to specific libraries
- Maintain complete provenance chain: Media → Archive → SD Card → Camera

**Validation Criteria**:
- [ ] Can trace any media file back to source SD card and camera
- [ ] Can track original filename vs processed filename
- [ ] Can associate media files with archives and libraries
- [ ] Can query complete provenance chain for any media file
- [ ] Can handle media files from different sources in same library

### **Use Case 5: Multi-Library Support**
**Description**: Support multiple libraries with different storage setups and purposes.

**Requirements**:
- Support travel libraries (laptop + external SSDs)
- Support office libraries (RAID storage, Mac Mini)
- Support archive libraries (long-term storage)
- Track library locations and storage devices
- Support library migration and file movement
- Track library sync status across devices

**Validation Criteria**:
- [ ] Can create and manage travel, office, and archive libraries
- [ ] Can track library storage devices and locations
- [ ] Can migrate files between libraries with history
- [ ] Can track library sync status across devices
- [ ] Can handle library-specific storage configurations

### **Use Case 6: Deletion Tracking**
**Description**: Record file deletions while maintaining metadata forever.

**Requirements**:
- Mark files as deleted but keep all metadata
- Record deletion date and reason
- Prevent reprocessing of deleted files
- Maintain deletion history for audit purposes
- Support undelete operations if needed

**Validation Criteria**:
- [ ] Can mark files as deleted while preserving metadata
- [ ] Can record deletion date and reason
- [ ] Can prevent reprocessing of deleted files
- [ ] Can query deletion history
- [ ] Can support undelete operations

### **Use Case 7: Travel vs Office Use Cases**
**Description**: Support different workflows for travel and office environments.

**Requirements**:
- Detect travel vs office environment automatically
- Support laptop + external SSD setup for travel
- Support RAID storage setup for office
- Sync metadata between travel and office environments
- Handle data migration from travel to office
- Track location and timezone information

**Validation Criteria**:
- [ ] Can detect and configure travel vs office environments
- [ ] Can sync metadata between travel and office
- [ ] Can migrate data from travel to office setups
- [ ] Can track location and timezone for all operations
- [ ] Can handle different storage configurations per environment

### **Use Case 8: External Storage Tracking**
**Description**: Track all external storage devices like SD cards, SSDs, and RAID arrays.

**Requirements**:
- Track SD cards with volume UUIDs
- Track external SSDs and RAID arrays
- Track cloud storage locations
- Monitor storage device usage across computers
- Track storage device capacity and format information

**Validation Criteria**:
- [ ] Can track all types of storage devices (SD, SSD, RAID, cloud)
- [ ] Can monitor device usage across multiple computers
- [ ] Can track device capacity and format information
- [ ] Can handle device mounting/unmounting
- [ ] Can track cloud storage providers and sync status

### **Use Case 9: Computer Tracking**
**Description**: Track all computers used for processing operations.

**Requirements**:
- Record all computers used for GoProX operations
- Track computer platform, OS version, and GoProX version
- Associate all operations with processing computer
- Track computer usage over time
- Support multiple computers in workflow

**Validation Criteria**:
- [ ] Can record computer information (hostname, platform, versions)
- [ ] Can associate all operations with processing computer
- [ ] Can track computer usage over time
- [ ] Can handle multiple computers in workflow
- [ ] Can query operations by computer

### **Use Case 10: Version Tracking**
**Description**: Track version changes for all devices and software.

**Requirements**:
- Track firmware versions for cameras
- Track software versions for computers
- Track hardware versions for storage devices
- Record version change history with timestamps
- Associate version changes with location and computer

**Validation Criteria**:
- [ ] Can track firmware versions for all cameras
- [ ] Can track software versions for all computers
- [ ] Can track hardware versions for all devices
- [ ] Can record version change history
- [ ] Can associate version changes with location and computer

### **Use Case 11: Timestamp Verification**
**Description**: Verify and track timestamps for all operations and media files.

**Requirements**:
- Record processing timestamps for all operations
- Compare media file timestamps with processing timestamps
- Track timezone information for all operations
- Verify timestamp accuracy and flag discrepancies
- Support timezone-aware processing

**Validation Criteria**:
- [ ] Can record processing timestamps for all operations
- [ ] Can compare media timestamps with processing timestamps
- [ ] Can track timezone information
- [ ] Can flag timestamp discrepancies
- [ ] Can support timezone-aware processing

### **Use Case 12: Geolocation Tracking**
**Description**: Track physical location of all operations for travel and timezone purposes.

**Requirements**:
- Record latitude/longitude for all operations
- Track timezone information for each location
- Support travel tracking and trip organization
- Associate location with media files and archives
- Handle location privacy concerns

**Validation Criteria**:
- [ ] Can record location for all operations
- [ ] Can track timezone information per location
- [ ] Can organize operations by travel trips
- [ ] Can associate location with media and archives
- [ ] Can handle location privacy (approximate vs precise)

### **Use Case 13: Cloud Integration Tracking**
**Description**: Track integration with external cloud services.

**Requirements**:
- Track GoPro Cloud uploads
- Track Apple Photos imports
- Record upload dates and sync status
- Track cloud storage providers
- Monitor cloud sync operations

**Validation Criteria**:
- [ ] Can track GoPro Cloud uploads with dates
- [ ] Can track Apple Photos imports with dates
- [ ] Can record cloud sync status
- [ ] Can track multiple cloud providers
- [ ] Can monitor cloud sync operations

### **Use Case 14: Metadata Cloud Sync**
**Description**: Sync metadata across multiple devices via cloud storage.

**Requirements**:
- Sync metadata database across devices
- Handle conflict resolution for concurrent modifications
- Track sync status and history
- Support offline operation with sync when online
- Maintain data integrity during sync

**Validation Criteria**:
- [ ] Can sync metadata across multiple devices
- [ ] Can handle conflict resolution
- [ ] Can track sync status and history
- [ ] Can support offline operation
- [ ] Can maintain data integrity during sync

### **Use Case 15: Library Migration and File Movement**
**Description**: Track movement of files between libraries and storage locations.

**Requirements**:
- Track file movements between libraries
- Record migration reasons and timestamps
- Associate migrations with computers and locations
- Support bulk migration operations
- Maintain migration history for audit

**Validation Criteria**:
- [ ] Can track file movements between libraries
- [ ] Can record migration reasons and timestamps
- [ ] Can associate migrations with computers and locations
- [ ] Can support bulk migration operations
- [ ] Can maintain complete migration history

## Implementation Strategy

### Phase 1: Intelligent Detection and Setup
**Priority**: High

#### 1.1 Automatic GoPro Detection
Implement intelligent GoPro SD card detection:
- Automatic mount point detection
- Camera model identification
- Firmware version checking
- Media file discovery and validation

#### 1.2 Smart Default Configuration
Create intelligent default behavior:
- Automatic library structure creation
- Optimal processing settings based on content
- Environment-aware configuration
- Multi-system synchronization

### Phase 2: Automated Workflow Management
**Priority**: High

#### 2.1 Intelligent Processing Pipeline
Implement automated processing workflows:
- Archive-first processing strategy
- Smart import and processing decisions
- Automatic cleanup and optimization
- Error recovery and retry mechanisms

#### 2.2 Context-Aware Operations
Add intelligent context awareness:
- Travel vs. office environment detection
- Multi-card workflow management
- Storage optimization and management
- Performance monitoring and optimization

### Phase 3: Advanced Intelligence Features
**Priority**: Medium

#### 3.1 Predictive Processing
- Content analysis and categorization
- Processing priority optimization
- Storage requirement prediction
- Performance optimization recommendations

#### 3.2 User Experience Enhancement
- Interactive progress reporting
- Intelligent error handling and recovery
- Contextual help and guidance
- Workflow optimization suggestions

## Technical Design

### Metadata Storage System (SQLite Database)

**Rationale**: A lightweight, self-contained SQLite database provides the foundation for intelligent media management by tracking cameras, SD cards, and media files with full support for SD card reuse across multiple cameras.

#### Database Schema Design

```sql
-- Computers/Devices table (tracks all computers used for processing)
CREATE TABLE computers (
    id INTEGER PRIMARY KEY,
    hostname TEXT UNIQUE NOT NULL,
    platform TEXT NOT NULL, -- 'macOS', 'Linux', 'Windows'
    os_version TEXT,
    goprox_version TEXT,
    first_seen_date TEXT,
    last_seen_date TEXT,
    notes TEXT
);

-- Cameras table (enhanced with settings tracking)
CREATE TABLE cameras (
    id INTEGER PRIMARY KEY,
    serial_number TEXT UNIQUE NOT NULL,
    camera_type TEXT NOT NULL,
    model_name TEXT,
    first_seen_date TEXT,
    last_seen_date TEXT,
    firmware_version TEXT,
    wifi_mac TEXT,
    settings_config_path TEXT, -- Path to camera-specific YAML config
    notes TEXT
);

-- Camera Settings History (tracks settings changes over time)
CREATE TABLE camera_settings_history (
    id INTEGER PRIMARY KEY,
    camera_id INTEGER,
    settings_date TEXT NOT NULL,
    settings_config TEXT, -- JSON/YAML of settings
    operation_type TEXT NOT NULL, -- 'detected', 'written', 'updated'
    computer_id INTEGER,
    notes TEXT,
    FOREIGN KEY (camera_id) REFERENCES cameras(id),
    FOREIGN KEY (computer_id) REFERENCES computers(id)
);

-- Storage Devices table (SD cards, SSDs, RAID arrays, etc.)
CREATE TABLE storage_devices (
    id INTEGER PRIMARY KEY,
    device_type TEXT NOT NULL, -- 'sd_card', 'ssd', 'raid', 'cloud'
    volume_uuid TEXT UNIQUE,
    volume_name TEXT,
    device_name TEXT,
    capacity_gb INTEGER,
    first_seen_date TEXT,
    last_seen_date TEXT,
    format_type TEXT,
    mount_point TEXT,
    is_removable BOOLEAN DEFAULT TRUE,
    is_cloud_storage BOOLEAN DEFAULT FALSE,
    cloud_provider TEXT, -- 'gopro_cloud', 'icloud', 'dropbox', etc.
    notes TEXT
);

-- Storage Device Usage History (tracks device usage across computers)
CREATE TABLE storage_device_usage (
    id INTEGER PRIMARY KEY,
    storage_device_id INTEGER,
    computer_id INTEGER,
    usage_start_date TEXT NOT NULL,
    usage_end_date TEXT, -- NULL if currently in use
    mount_point TEXT,
    notes TEXT,
    FOREIGN KEY (storage_device_id) REFERENCES storage_devices(id),
    FOREIGN KEY (computer_id) REFERENCES computers(id)
);

-- SD Card Usage History (tracks which camera used which card when)
CREATE TABLE sd_card_usage (
    id INTEGER PRIMARY KEY,
    storage_device_id INTEGER, -- References storage_devices where device_type='sd_card'
    camera_id INTEGER,
    usage_start_date TEXT NOT NULL,
    usage_end_date TEXT, -- NULL if currently in use
    detected_firmware_version TEXT,
    processing_computer_id INTEGER,
    processing_location_lat REAL,
    processing_location_lon REAL,
    processing_timezone TEXT,
    notes TEXT,
    FOREIGN KEY (storage_device_id) REFERENCES storage_devices(id),
    FOREIGN KEY (camera_id) REFERENCES cameras(id),
    FOREIGN KEY (processing_computer_id) REFERENCES computers(id)
);

-- Media Libraries table (tracks different library setups)
CREATE TABLE media_libraries (
    id INTEGER PRIMARY KEY,
    library_name TEXT UNIQUE NOT NULL,
    library_type TEXT NOT NULL, -- 'travel', 'office', 'archive', 'cloud'
    root_path TEXT,
    storage_device_id INTEGER,
    computer_id INTEGER,
    created_date TEXT,
    last_accessed_date TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    sync_status TEXT DEFAULT 'local', -- 'local', 'syncing', 'synced'
    notes TEXT,
    FOREIGN KEY (storage_device_id) REFERENCES storage_devices(id),
    FOREIGN KEY (computer_id) REFERENCES computers(id)
);

-- Archives table (tracks archive locations and metadata)
CREATE TABLE archives (
    id INTEGER PRIMARY KEY,
    archive_name TEXT UNIQUE NOT NULL,
    archive_path TEXT NOT NULL,
    source_sd_card_id INTEGER,
    source_camera_id INTEGER,
    processing_computer_id INTEGER,
    processing_date TEXT NOT NULL,
    processing_location_lat REAL,
    processing_location_lon REAL,
    processing_timezone TEXT,
    archive_size_bytes INTEGER,
    media_file_count INTEGER,
    library_id INTEGER,
    cloud_storage_id INTEGER, -- References storage_devices where device_type='cloud'
    cloud_sync_date TEXT,
    notes TEXT,
    FOREIGN KEY (source_sd_card_id) REFERENCES storage_devices(id),
    FOREIGN KEY (source_camera_id) REFERENCES cameras(id),
    FOREIGN KEY (processing_computer_id) REFERENCES computers(id),
    FOREIGN KEY (library_id) REFERENCES media_libraries(id),
    FOREIGN KEY (cloud_storage_id) REFERENCES storage_devices(id)
);

-- Media files table (enhanced with library and archive tracking)
CREATE TABLE media_files (
    id INTEGER PRIMARY KEY,
    filename TEXT NOT NULL,
    original_filename TEXT, -- Original filename from SD card
    file_path TEXT NOT NULL,
    camera_id INTEGER,
    source_sd_card_id INTEGER,
    source_archive_id INTEGER,
    library_id INTEGER,
    file_type TEXT NOT NULL, -- 'photo', 'video', 'lrv', 'thm'
    file_size_bytes INTEGER,
    creation_date TEXT,
    modification_date TEXT,
    media_creation_date TEXT, -- Date from media file metadata
    media_modification_date TEXT, -- Date from media file metadata
    duration_seconds REAL, -- for videos
    resolution TEXT, -- '4K', '1080p', etc.
    fps REAL, -- for videos
    gps_latitude REAL,
    gps_longitude REAL,
    gps_altitude REAL,
    metadata_extracted BOOLEAN DEFAULT FALSE,
    processing_status TEXT DEFAULT 'new', -- 'new', 'processed', 'archived', 'deleted'
    is_deleted BOOLEAN DEFAULT FALSE,
    deletion_date TEXT,
    deletion_reason TEXT,
    gopro_cloud_uploaded BOOLEAN DEFAULT FALSE,
    gopro_cloud_upload_date TEXT,
    apple_photos_imported BOOLEAN DEFAULT FALSE,
    apple_photos_import_date TEXT,
    notes TEXT,
    FOREIGN KEY (camera_id) REFERENCES cameras(id),
    FOREIGN KEY (source_sd_card_id) REFERENCES storage_devices(id),
    FOREIGN KEY (source_archive_id) REFERENCES archives(id),
    FOREIGN KEY (library_id) REFERENCES media_libraries(id)
);

-- Processing history table (enhanced with location and computer tracking)
CREATE TABLE processing_history (
    id INTEGER PRIMARY KEY,
    media_file_id INTEGER,
    operation_type TEXT NOT NULL, -- 'import', 'archive', 'process', 'firmware_check', 'delete', 'move'
    operation_date TEXT NOT NULL,
    computer_id INTEGER,
    operation_location_lat REAL,
    operation_location_lon REAL,
    operation_timezone TEXT,
    status TEXT NOT NULL, -- 'success', 'failed', 'skipped'
    details TEXT,
    FOREIGN KEY (media_file_id) REFERENCES media_files(id),
    FOREIGN KEY (computer_id) REFERENCES computers(id)
);

-- Library Migration History (tracks file movements between libraries)
CREATE TABLE library_migrations (
    id INTEGER PRIMARY KEY,
    media_file_id INTEGER,
    source_library_id INTEGER,
    destination_library_id INTEGER,
    migration_date TEXT NOT NULL,
    computer_id INTEGER,
    migration_location_lat REAL,
    migration_location_lon REAL,
    migration_timezone TEXT,
    migration_reason TEXT,
    notes TEXT,
    FOREIGN KEY (media_file_id) REFERENCES media_files(id),
    FOREIGN KEY (source_library_id) REFERENCES media_libraries(id),
    FOREIGN KEY (destination_library_id) REFERENCES media_libraries(id),
    FOREIGN KEY (computer_id) REFERENCES computers(id)
);

-- Device Version History (tracks version changes for all devices)
CREATE TABLE device_version_history (
    id INTEGER PRIMARY KEY,
    device_type TEXT NOT NULL, -- 'camera', 'sd_card', 'ssd', 'computer'
    device_id INTEGER, -- References appropriate table based on device_type
    version_type TEXT NOT NULL, -- 'firmware', 'software', 'hardware'
    old_version TEXT,
    new_version TEXT,
    change_date TEXT NOT NULL,
    computer_id INTEGER,
    change_location_lat REAL,
    change_location_lon REAL,
    change_timezone TEXT,
    notes TEXT,
    FOREIGN KEY (computer_id) REFERENCES computers(id)
);

-- Metadata Sync Status (tracks cloud sync of metadata)
CREATE TABLE metadata_sync_status (
    id INTEGER PRIMARY KEY,
    sync_date TEXT NOT NULL,
    computer_id INTEGER,
    sync_type TEXT NOT NULL, -- 'upload', 'download', 'merge'
    sync_status TEXT NOT NULL, -- 'success', 'failed', 'partial'
    records_synced INTEGER,
    sync_location_lat REAL,
    sync_location_lon REAL,
    sync_timezone TEXT,
    notes TEXT,
    FOREIGN KEY (computer_id) REFERENCES computers(id)
);
```

#### Implementation Benefits

1. **Single File Storage**: One `.db` file in `~/.goprox/metadata.db`
2. **SD Card Reuse Support**: Complete tracking of cards used across multiple cameras
3. **Standard Tools**: Can be queried with `sqlite3` command-line tool
4. **Backup Friendly**: Single file to backup/restore
5. **Version Control**: Can track schema changes in Git
6. **Performance**: Indexed queries for fast lookups
7. **Atomic Operations**: ACID compliance for data integrity

#### Integration with GoProX Workflow

```zsh
# Add to scripts/core/metadata.zsh
init_metadata_db() {
    local db_path="$HOME/.goprox/metadata.db"
    sqlite3 "$db_path" << 'EOF'
    -- Create tables if they don't exist
    CREATE TABLE IF NOT EXISTS cameras (...);
    CREATE TABLE IF NOT EXISTS sd_cards (...);
    CREATE TABLE IF NOT EXISTS sd_card_usage (...);
    CREATE TABLE IF NOT EXISTS media_files (...);
    CREATE TABLE IF NOT EXISTS processing_history (...);
EOF
}

record_camera_detection() {
    local serial_number="$1"
    local camera_type="$2"
    local firmware_version="$3"
    
    sqlite3 "$HOME/.goprox/metadata.db" << EOF
    INSERT OR REPLACE INTO cameras (serial_number, camera_type, firmware_version, last_seen_date)
    VALUES ('$serial_number', '$camera_type', '$firmware_version', datetime('now'));
EOF
}

record_sd_card_usage() {
    local volume_uuid="$1"
    local camera_serial="$2"
    local firmware_version="$3"
    
    sqlite3 "$HOME/.goprox/metadata.db" << EOF
    -- End any previous usage of this SD card
    UPDATE sd_card_usage 
    SET usage_end_date = datetime('now') 
    WHERE sd_card_id = (SELECT id FROM sd_cards WHERE volume_uuid = '$volume_uuid')
    AND usage_end_date IS NULL;
    
    -- Start new usage
    INSERT INTO sd_card_usage (sd_card_id, camera_id, usage_start_date, detected_firmware_version)
    VALUES (
        (SELECT id FROM sd_cards WHERE volume_uuid = '$volume_uuid'),
        (SELECT id FROM cameras WHERE serial_number = '$camera_serial'),
        datetime('now'),
        '$firmware_version'
    );
EOF
}
```

#### Comprehensive Use Case Support

The enhanced metadata schema supports all the following use cases:

##### **1. SD Card Tracking Over Time**
- **Requirement**: Track SD cards across multiple cameras and processing sessions
- **Support**: `storage_devices` table with `device_type='sd_card'` + `sd_card_usage` history
- **Query**: Complete history of which camera used which card when

##### **2. Camera Settings Management**
- **Requirement**: Store and track camera settings per camera, write to SD cards
- **Support**: `camera_settings_history` table tracks all settings changes
- **Implementation**: YAML config files stored in `~/.goprox/cameras/<serial>/settings.yaml`

##### **3. Archive Tracking and Metadata**
- **Requirement**: Track archives with source card/camera and location
- **Support**: `archives` table with full source tracking and library association
- **Query**: Find archive by name → get source card/camera/processing details

##### **4. Media File Association**
- **Requirement**: Associate every media file with source card, camera, and archive
- **Support**: `media_files` table with multiple source references
- **Tracking**: Complete chain: Media → Archive → SD Card → Camera

##### **5. Archive and Library Management**
- **Requirement**: Track archives, libraries, and cloud storage locations
- **Support**: `archives`, `media_libraries`, and cloud storage in `storage_devices`
- **Features**: Library migration tracking, cloud sync status

##### **6. Deletion Tracking**
- **Requirement**: Record deletions but keep metadata forever
- **Support**: `is_deleted`, `deletion_date`, `deletion_reason` in `media_files`
- **Benefit**: Prevents reprocessing deleted files while maintaining history

##### **7. Multi-Library Support**
- **Requirement**: Track multiple libraries (travel, office, archive)
- **Support**: `media_libraries` table with library types and storage devices
- **Migration**: `library_migrations` table tracks file movements

##### **8. Travel vs Office Use Cases**
- **Requirement**: Support travel (laptop + SSDs) vs office (RAID) setups
- **Support**: Library types ('travel', 'office'), storage device tracking
- **Sync**: Metadata sync status tracking for cloud availability

##### **9. External Storage Tracking**
- **Requirement**: Track SSDs, RAID devices like SD cards
- **Support**: Unified `storage_devices` table handles all device types
- **Usage**: `storage_device_usage` tracks device usage across computers

##### **10. Computer Tracking**
- **Requirement**: Track all computers used for processing
- **Support**: `computers` table with platform and version info
- **History**: All operations linked to processing computer

##### **11. Version Tracking**
- **Requirement**: Track versions of all devices (firmware, software, hardware)
- **Support**: `device_version_history` table for all version changes
- **Scope**: Cameras, SD cards, SSDs, computers, any device

##### **12. Timestamp Verification**
- **Requirement**: Verify media timestamps and record processing times
- **Support**: `media_creation_date` vs `creation_date` comparison
- **Processing**: All operations timestamped with computer and location

##### **13. Geolocation Tracking**
- **Requirement**: Record physical location of all operations
- **Support**: Latitude/longitude/timezone in all relevant tables
- **Use Case**: Travel tracking, timezone association with media

##### **14. Cloud Integration Tracking**
- **Requirement**: Track GoPro Cloud uploads and Apple Photos imports
- **Support**: `gopro_cloud_uploaded`, `apple_photos_imported` flags
- **History**: Upload dates and sync status tracking

##### **15. Metadata Cloud Sync**
- **Requirement**: Sync metadata across devices via cloud
- **Support**: `metadata_sync_status` table tracks sync operations
- **Features**: Upload/download/merge operations with location tracking

#### Query Examples for Intelligent Management

```sql
-- Find all cameras that used a specific SD card
SELECT DISTINCT c.camera_type, c.serial_number, scu.usage_start_date, scu.usage_end_date
FROM cameras c
JOIN sd_card_usage scu ON c.id = scu.camera_id
JOIN storage_devices sd ON scu.storage_device_id = sd.id
WHERE sd.volume_uuid = 'B18F461B-A942-3CA5-A096-CBD7D6F7A5AD'
ORDER BY scu.usage_start_date;

-- Get media statistics by camera
SELECT c.camera_type, COUNT(m.id) as file_count, SUM(m.file_size_bytes) as total_size 
FROM cameras c 
LEFT JOIN media_files m ON c.id = m.camera_id 
GROUP BY c.id;

-- Find SD cards currently in use
SELECT sd.volume_name, c.camera_type, c.serial_number, scu.usage_start_date
FROM storage_devices sd
JOIN sd_card_usage scu ON sd.id = scu.storage_device_id
JOIN cameras c ON scu.camera_id = c.id
WHERE sd.device_type = 'sd_card' AND scu.usage_end_date IS NULL;

-- Find archive by name and get source details
SELECT a.archive_name, c.camera_type, c.serial_number, sd.volume_name, a.processing_date
FROM archives a
JOIN cameras c ON a.source_camera_id = c.id
JOIN storage_devices sd ON a.source_sd_card_id = sd.id
WHERE a.archive_name = 'HERO10-2024-01-15-Archive';

-- Track library migrations
SELECT m.filename, sl.library_name as source_lib, dl.library_name as dest_lib, lm.migration_date
FROM library_migrations lm
JOIN media_files m ON lm.media_file_id = m.id
JOIN media_libraries sl ON lm.source_library_id = sl.id
JOIN media_libraries dl ON lm.destination_library_id = dl.id
ORDER BY lm.migration_date DESC;

-- Find deleted files to avoid reprocessing
SELECT filename, deletion_date, deletion_reason
FROM media_files 
WHERE is_deleted = TRUE;

-- Track device version changes
SELECT device_type, version_type, old_version, new_version, change_date
FROM device_version_history
ORDER BY change_date DESC;

-- Find media by location (travel use case)
SELECT m.filename, a.processing_location_lat, a.processing_location_lon, a.processing_timezone
FROM media_files m
JOIN archives a ON m.source_archive_id = a.id
WHERE a.processing_location_lat IS NOT NULL;
```

#### Potential Gaps and Considerations

##### **Data Volume Considerations**
- **Large Media Collections**: With thousands of media files, query performance becomes critical
- **Solution**: Implement proper indexing on frequently queried columns
- **Recommendation**: Consider partitioning strategies for very large datasets

##### **Geolocation Privacy**
- **Requirement**: Track location for timezone and travel use cases
- **Consideration**: Privacy implications of storing precise coordinates
- **Solution**: Store approximate location (city/region level) or make precise location opt-in

##### **Cloud Sync Complexity**
- **Requirement**: Sync metadata across multiple devices
- **Challenge**: Conflict resolution when same data modified on multiple devices
- **Solution**: Implement merge strategies and conflict detection

##### **File Path Management**
- **Requirement**: Track file locations across different storage devices
- **Challenge**: Paths change when devices are mounted differently
- **Solution**: Use relative paths or implement path normalization

##### **Backup and Recovery**
- **Requirement**: Metadata must be backed up and recoverable
- **Challenge**: Single SQLite file becomes critical dependency
- **Solution**: Implement automated backup to cloud storage with versioning

##### **Performance Optimization**
- **Requirement**: Fast queries for large datasets
- **Consideration**: Complex joins across multiple tables
- **Solution**: Strategic indexing and query optimization

##### **Schema Evolution**
- **Requirement**: Schema must evolve as new use cases emerge
- **Challenge**: Backward compatibility and migration
- **Solution**: Versioned schema migrations with rollback capability

##### **Integration Points**
- **Requirement**: Integrate with existing GoProX workflows
- **Challenge**: Minimal disruption to current functionality
- **Solution**: Gradual integration with feature flags

### Intelligent Detection System
```zsh
# Automatic GoPro detection
function detect_gopro_cards() {
    # Scan for mounted GoPro SD cards
    # Identify camera models and firmware
    # Validate media content
    # Return structured card information
}

function analyze_media_content() {
    local source_dir="$1"
    # Analyze media files and metadata
    # Determine optimal processing strategy
    # Identify special requirements
    # Return processing recommendations
}
```

### Smart Default Configuration
```zsh
# Environment-aware configuration
function detect_environment() {
    # Detect travel vs. office environment
    # Identify available storage
    # Determine network connectivity
    # Return environment configuration
}

function create_smart_config() {
    local environment="$1"
    local media_analysis="$2"
    # Create optimal configuration
    # Set processing parameters
    # Configure storage strategy
    # Return configuration object
}
```

### Automated Workflow Engine
```zsh
# Intelligent processing pipeline
function execute_smart_workflow() {
    local gopro_cards="$1"
    local config="$2"
    
    # Execute archive-first strategy
    # Process based on content analysis
    # Handle errors and recovery
    # Provide progress feedback
}
```

## Integration Points

### SD Card Management
- Automatic mount point detection
- Multi-card workflow coordination
- Storage optimization and management
- Firmware update automation

### Media Processing
- Intelligent import strategies
- Content-aware processing
- Performance optimization
- Quality assurance and validation

### User Interface
- Interactive progress reporting
- Contextual help and guidance
- Error handling and recovery
- Workflow optimization suggestions

## Success Metrics

- **Automation**: 90% reduction in manual intervention
- **Efficiency**: 50% faster processing workflows
- **Reliability**: 99% successful automated operations
- **User Experience**: Intuitive, guided workflows
- **Performance**: Optimized resource utilization
- **Metadata Intelligence**: Complete tracking of cameras, SD cards, and media files
- **SD Card Reuse**: Full support for cards used across multiple cameras
- **Data Integrity**: ACID-compliant metadata storage with backup/restore capabilities

## Dependencies

- Enhanced default behavior implementation
- Intelligent detection algorithms
- Automated workflow engine
- User interface improvements
- **SQLite database system for metadata storage**
- **Metadata extraction and tracking functions**
- **SD card reuse detection algorithms**

## Risk Assessment

### Low Risk
- Non-destructive automation
- Gradual rollout and testing
- Fallback to manual operations
- User control maintained

### Medium Risk
- Algorithm complexity and accuracy
- Performance impact of intelligence
- User acceptance and adoption
- Integration complexity

### Mitigation Strategies
- Comprehensive testing and validation
- Performance monitoring and optimization
- User feedback and iteration
- Clear documentation and training

## Implementation Checklist

### Phase 1: Intelligent Detection
- [ ] Implement GoPro card detection
- [ ] Create media content analysis
- [ ] Build environment detection
- [ ] Develop smart configuration
- [ ] Test detection accuracy
- [ ] **Implement enhanced SQLite metadata database**
- [ ] **Create comprehensive device tracking (cameras, computers, storage)**
- [ ] **Add camera settings management and YAML configs**
- [ ] **Implement geolocation and timezone tracking**

### Phase 2: Automated Workflows
- [ ] Create intelligent processing pipeline
- [ ] Implement archive-first strategy
- [ ] Add error recovery mechanisms
- [ ] Build progress reporting
- [ ] Test workflow reliability
- [ ] **Integrate metadata tracking into all workflows**
- [ ] **Add processing history with location tracking**
- [ ] **Implement SD card reuse detection**
- [ ] **Create archive and library management**
- [ ] **Add deletion tracking to prevent reprocessing**

### Phase 3: Advanced Features
- [ ] Add predictive processing
- [ ] Implement user experience enhancements
- [ ] Create optimization recommendations
- [ ] Build contextual help system
- [ ] Document intelligent features
- [ ] **Add comprehensive metadata query and reporting tools**
- [ ] **Implement backup and restore for metadata**
- [ ] **Create metadata analytics and insights**
- [ ] **Add cloud sync for metadata across devices**
- [ ] **Implement library migration tracking**
- [ ] **Add device version history tracking**
- [ ] **Create travel vs office use case support**

## Next Steps

1. **Immediate**: Implement intelligent detection system
2. **Short term**: Create automated workflow engine
3. **Medium term**: Add advanced intelligence features
4. **Long term**: Continuous improvement and optimization

## Related Issues

- #67: Enhanced Default Behavior
- #69: Enhanced SD Card Management
- #70: Architecture Design Principles

---

*This enhancement transforms GoProX into an intelligent, automated media management assistant while maintaining user control and flexibility.* 