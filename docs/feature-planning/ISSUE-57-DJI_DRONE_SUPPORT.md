# Issue #57: DJI Drone Support

**Issue Title**: Feature: Add basic support for DJI drone import  
**Status**: Open  
**Assignee**: fxstein  
**Labels**: enhancement, further investigation

## Overview

Enable the import from DJI drone SD cards similar to the GoPro media. Since there is no version text file on the SD cards of DJI drones, it requires some directory/filename logic to identify as a DJI drone.

## Current State Analysis

### Existing Capabilities
- GoPro SD card detection and import
- Media file processing
- Directory structure analysis
- EXIF data extraction

### Current Limitations
- No DJI drone support
- GoPro-specific detection logic
- No cross-platform media handling
- Limited camera type recognition

## Implementation Strategy

### Phase 1: DJI Detection Logic (High Priority)
**Estimated Effort**: 2-3 days

#### 1.1 DJI Directory Structure Analysis
```zsh
# DJI SD card structure
.
├── DCIM
│   └── 100MEDIA
├── LOST.DIR
└── MISC
    ├── GIS
    ├── IDX
    └── THM
        └── 100
            ├── DJI_0001.SCR
            ├── DJI_0001.THM
            ├── DJI_0002.SCR
            └── ...
```

#### 1.2 Detection Script Enhancement
```zsh
# Enhanced detection logic
scripts/detection/detect-media-cards.zsh
```
- Scan for DJI-specific directory structure
- Identify DJI file patterns
- Extract drone information where possible
- Handle multiple drone types

### Phase 2: Import Workflow Integration (High Priority)
**Estimated Effort**: 2-3 days

#### 2.1 DJI Import Commands
```zsh
# New DJI-specific commands
goprox --dji --import
goprox --dji --detect
goprox --auto-detect --import  # Enhanced to include DJI
```

#### 2.2 Media Processing
```zsh
# DJI media processing
scripts/import/process-dji-media.zsh
```
- Handle DJI-specific file formats
- Extract metadata where available
- Apply consistent naming conventions
- Integrate with existing workflow

### Phase 3: Advanced Features (Medium Priority)
**Estimated Effort**: 3-4 days

#### 3.1 Drone Type Detection
```zsh
# Drone identification logic
scripts/detection/identify-drone.zsh
```
- Detect specific DJI models
- Extract serial numbers if available
- Handle different DJI generations

#### 3.2 Metadata Enhancement
- Extract flight data from GIS files
- Process telemetry information
- Handle DJI-specific EXIF data

## Technical Design

### DJI Detection Algorithm
```zsh
# DJI detection workflow
1. Check for MISC/GIS directory
2. Look for DJI_*.THM files
3. Verify DCIM/100MEDIA structure
4. Check for DJI-specific file patterns
5. Extract available metadata
6. Classify as DJI drone media
```

### File Pattern Recognition
**DJI File Patterns**:
- `DJI_*.THM` - Thumbnail files
- `DJI_*.SCR` - Screen capture files
- `dji.gis` - GPS/telemetry data
- `IDX_BLOCK` - Index files

### Import Structure
```zsh
# DJI import directory structure
~/goprox/
├── imported/
│   └── 2024/
│       └── 20240115/
│           ├── DJI_0001.MP4
│           ├── DJI_0002.JPG
│           └── DJI_0003.DNG
├── processed/
│   └── DJI/
│       └── 2024/
│           └── 20240115/
│               ├── P_DJI_0001.mp4
│               ├── P_DJI_0002.jpg
│               └── P_DJI_0003.dng
└── archive/
    └── DJI/
        └── 2024/
            └── 20240115/
```

## Integration Points

### Existing Import System
- Extend current import workflow
- Maintain consistent naming
- Preserve existing functionality

### Main goprox Script
- Add DJI-specific commands
- Integrate with auto-detection
- Maintain backward compatibility

### Media Processing
- Handle DJI file formats
- Extract available metadata
- Apply consistent processing

## Success Metrics

- **Detection**: 95% accurate DJI detection
- **Compatibility**: Support for major DJI models
- **Performance**: Comparable to GoPro processing
- **User Experience**: Seamless integration

## Dependencies

- Existing import infrastructure
- Media file processing capabilities
- EXIF data extraction
- Directory structure analysis

## Risk Assessment

### Low Risk
- Non-breaking changes
- Based on existing infrastructure
- Reversible implementation

### Medium Risk
- DJI file format variations
- Metadata extraction complexity
- Performance impact

### High Risk
- DJI firmware changes
- File format evolution
- Compatibility issues

### Mitigation Strategies
- Extensive testing with various DJI models
- Robust error handling
- Fallback mechanisms
- User feedback integration

## Testing Strategy

### Detection Testing
```zsh
# Test DJI detection
scripts/test/test-dji-detection.zsh
```
- Test with various DJI models
- Validate detection accuracy
- Check edge cases

### Import Testing
```zsh
# Test DJI import workflow
scripts/test/test-dji-import.zsh
```
- Test complete import process
- Validate file processing
- Check metadata extraction

### Integration Testing
- Test with real DJI SD cards
- Validate workflow integration
- Check performance impact

## Example Usage

```zsh
# Basic DJI import
goprox --dji --import

# Auto-detect and import
goprox --auto-detect --import

# DJI-specific detection
goprox --dji --detect

# Process DJI media
goprox --dji --process
```

## Next Steps

1. **Immediate**: Implement DJI detection logic
2. **Week 1**: Add import workflow integration
3. **Week 2**: Implement media processing
4. **Week 3**: Add advanced features
5. **Week 4**: Testing and documentation

## Related Issues

- #67: Enhanced default behavior (integration)
- #69: Enhanced SD card management (multi-device)
- #4: Automatic imports (DJI support)
- #10: Multi-tier storage (DJI media) 