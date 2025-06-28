# Issue #63: SD Card Volume Renaming

**Issue Title**: Enhancement: Rename SD card volume label to HERO11-8909 format  
**Status**: Open  
**Assignee**: fxstein  
**Labels**: enhancement

## Overview

Add functionality to rename the SD card volume label of a particular camera to the following format: HERO11-8909, where the short version of the model is followed by a dash and the last 4 digits of its serial number.

## Current State Analysis

### Existing Capabilities
- Basic SD card detection
- Firmware version extraction
- Camera model identification
- Serial number detection

### Current Limitations
- No automatic volume renaming
- Manual process required
- Inconsistent naming across cards
- No validation of naming format

## Implementation Strategy

### Phase 1: Core Renaming Functionality (High Priority)
**Estimated Effort**: 2-3 days

#### 1.1 Renaming Script Enhancement
```zsh
# Enhanced renaming functionality
scripts/sd-card/rename-volume.zsh
```
- Detect camera model and serial number
- Generate standardized volume name
- Execute volume renaming
- Validate renaming success

#### 1.2 Naming Convention Implementation
```zsh
# Naming format: {SHORT_MODEL}-{LAST_4_SERIAL}
# Examples:
# HERO11-8909 (from HERO11 Black with serial ending in 8909)
# HERO10-8034 (from HERO10 Black with serial ending in 8034)
# MAX-6013 (from GoPro Max with serial ending in 6013)
```

### Phase 2: Integration with Main Workflow (High Priority)
**Estimated Effort**: 1-2 days

#### 2.1 Main Script Integration
```zsh
# New command options
goprox --rename-volume
goprox --auto-rename
goprox --firmware --rename
```

#### 2.2 Automatic Detection
- Detect when volume name doesn't match convention
- Offer automatic renaming
- Provide user confirmation options

### Phase 3: Advanced Features (Medium Priority)
**Estimated Effort**: 2-3 days

#### 3.1 Multi-Card Support
```zsh
# Rename multiple cards
goprox --rename-all
goprox --rename-cards HERO11-8909 HERO10-8034
```

#### 3.2 Validation and Recovery
- Validate new volume name format
- Check for naming conflicts
- Provide rollback capabilities

## Technical Design

### Volume Naming Convention
**Format**: `{SHORT_MODEL}-{LAST_4_SERIAL}`

**Model Mapping**:
```zsh
# Model name mappings
HERO11 Black -> HERO11
HERO10 Black -> HERO10
HERO9 Black -> HERO9
HERO8 Black -> HERO8
GoPro Max -> MAX
The Remote -> REMOTE
```

**Serial Number Processing**:
- Extract full serial number from camera
- Take last 4 digits
- Handle leading zeros appropriately

### Renaming Process
```zsh
# Renaming workflow
1. Detect mounted GoPro SD card
2. Extract camera model and serial number
3. Generate standardized volume name
4. Check for naming conflicts
5. Execute volume renaming
6. Verify renaming success
7. Update tracking information
```

### Error Handling
```zsh
# Error scenarios
- Missing serial number
- Unsupported camera model
- Volume already correctly named
- Permission issues
- Naming conflicts
```

## Integration Points

### Main goprox Script
- Add renaming commands to main workflow
- Integrate with existing detection logic
- Maintain backward compatibility

### Firmware Management
- Combine with firmware operations
- Rename before firmware updates
- Track renaming in firmware logs

### SD Card Detection
- Enhance existing detection scripts
- Add renaming validation
- Update mount point processing

## Success Metrics

- **Reliability**: 99% successful renaming
- **Consistency**: 100% standardized naming
- **Performance**: <5 second renaming time
- **User Adoption**: Seamless integration

## Dependencies

- Existing SD card detection logic
- Firmware version extraction
- Camera model identification
- Volume management permissions

## Risk Assessment

### Low Risk
- Based on existing detection logic
- Non-destructive operation
- Reversible implementation

### Medium Risk
- Permission requirements
- Naming conflicts
- User interface complexity

### High Risk
- System-level volume operations
- Cross-platform compatibility
- Error recovery scenarios

### Mitigation Strategies
- Extensive testing on different systems
- Graceful error handling
- User confirmation for critical operations
- Backup and recovery procedures

## Testing Strategy

### Unit Testing
```zsh
# Test individual components
scripts/test/test-volume-renaming.zsh
```
- Test naming convention logic
- Validate serial number extraction
- Check model mapping

### Integration Testing
```zsh
# Test full workflow
scripts/test/test-renaming-workflow.zsh
```
- Test complete renaming process
- Validate error handling
- Check integration points

### User Acceptance Testing
- Test with real SD cards
- Validate user experience
- Check edge cases

## Example Usage

```zsh
# Basic renaming
goprox --rename-volume

# Rename with specific card
goprox --rename-volume /Volumes/GOPRO

# Auto-rename during firmware update
goprox --firmware --auto-rename

# Rename all detected cards
goprox --rename-all
```

## Next Steps

1. **Immediate**: Implement core renaming logic
2. **Week 1**: Add main script integration
3. **Week 2**: Implement validation and error handling
4. **Week 3**: Add multi-card support
5. **Week 4**: Testing and documentation

## Related Issues

- #67: Enhanced default behavior (integration)
- #69: Enhanced SD card management (advanced features)
- #60: Firmware URL-based fetch (workflow integration)
- #4: Automatic imports (future enhancement) 