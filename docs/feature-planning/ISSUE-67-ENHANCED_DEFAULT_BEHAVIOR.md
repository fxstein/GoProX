# Issue #67: Enhanced Default Behavior

**Issue Title**: Enhanced default behavior: Automatic GoPro SD card detection and firmware management  
**Status**: Open  
**Assignee**: fxstein  
**Labels**: enhancement

## Overview

Enhanced the default behavior of goprox to automatically detect and manage GoPro SD cards when run without parameters. This provides a comprehensive GoPro SD card management experience in a single command.

## Current State Analysis

### Existing Capabilities
- Manual SD card detection via separate scripts
- Individual firmware management commands
- Volume renaming functionality
- Mount point processing

### Current Limitations
- Users must run multiple commands
- No automatic detection on startup
- Manual navigation required
- No unified workflow

## Implementation Strategy

### Phase 1: Core Detection Integration (High Priority)
**Estimated Effort**: 1-2 days

#### 1.1 Default Behavior Enhancement
```zsh
# New default workflow
goprox  # Automatically detects and manages SD cards
```
- Scan all mounted volumes for GoPro SD cards
- Extract camera information (type, serial, firmware)
- Detect firmware type automatically
- Check for newer firmware versions

#### 1.2 Smart Detection Features
```zsh
# Enhanced detection logic
scripts/sd-card/enhanced-detection.zsh
```
- Automatic firmware type detection (official vs Labs)
- Volume naming convention enforcement
- Duplicate processing prevention
- Comprehensive action summary

### Phase 2: User Experience Enhancement (Medium Priority)
**Estimated Effort**: 1-2 days

#### 2.1 Interactive Prompts
```zsh
# User interaction flow
Found GoPro SD card: HERO11-8909
  Camera type: HERO11 Black
  Serial number: C3471325208909
  Firmware version: H22.01.01.10.70
  Firmware type: labs
  [Y/n] Update firmware? 
  [Y/n] Rename volume?
```

#### 2.2 Progress Feedback
- Real-time operation status
- Error handling and recovery
- Summary of all actions taken

### Phase 3: Advanced Features (Low Priority)
**Estimated Effort**: 2-3 days

#### 3.1 Batch Processing
- Process multiple cards simultaneously
- Parallel operation execution
- Resource management

#### 3.2 Configuration Options
- Custom detection patterns
- User preference storage
- Advanced filtering options

## Technical Design

### Firmware Type Detection
**Official firmware**: Ends with `.00` (e.g., H22.01.01.10.00)  
**Labs firmware**: Ends with `.70` to `.79` (e.g., H22.01.01.10.70)

### Volume Naming Convention
**Format**: `{SHORT_MODEL}-{LAST_4_SERIAL}`  
**Example**: `HERO11-8909` (from HERO11 Black with serial ending in 8909)

### Detection Logic
```zsh
# Enhanced detection algorithm
1. Scan /Volumes/ for potential GoPro cards
2. Check for firmware files and version information
3. Extract camera model and serial number
4. Determine firmware type (official vs Labs)
5. Check for newer firmware availability
6. Propose volume renaming if needed
7. Offer firmware updates if available
```

## Integration Points

### Main goprox Script
- Integrate detection into main workflow
- Maintain backward compatibility
- Add new command-line options

### Existing Scripts
- Enhance `rename-gopro-sd.zsh` functionality
- Integrate with firmware management
- Extend mount point processing

### Configuration System
- Store user preferences
- Cache firmware information
- Track processing history

## Success Metrics

- **Usability**: Single command workflow
- **Reliability**: 99% successful detection
- **Performance**: <3 second detection time
- **User Adoption**: Seamless integration

## Dependencies

- Issue #63 (SD card renaming) - core functionality
- Issue #60 (Firmware URL-based fetch) - firmware integration
- Existing mount point processing

## Risk Assessment

### Low Risk
- Based on existing proven detection logic
- Backward compatibility maintained
- Incremental implementation possible

### Medium Risk
- User interface complexity
- Performance with multiple cards
- Error handling edge cases

### Mitigation Strategies
- Extensive testing with various card types
- User feedback integration
- Graceful error recovery

## Example Output

```
Scanning for GoPro SD cards...
Found GoPro SD card: HERO11-8909
  Camera type: HERO11 Black
  Serial number: C3471325208909
  Firmware version: H22.01.01.10.70
  Firmware type: labs
  Firmware update already prepared (UPDATE directory exists)

Summary: Found 1 GoPro SD card(s)
  - 1 already correctly named
SD card detection finished.
```

## Next Steps

1. **Immediate**: Review and approve technical design
2. **Week 1**: Implement core detection integration
3. **Week 2**: Add user interaction features
4. **Week 3**: Testing and refinement
5. **Week 4**: Documentation and release

## Related Issues

- #69: Enhanced SD card management (advanced features)
- #63: SD card renaming (core functionality)
- #60: Firmware URL-based fetch (integration)
- #4: Automatic imports (future enhancement) 