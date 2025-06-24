# Issue #29: Single File Summary

**Issue Title**: Feature: Single file summary  
**Status**: Open  
**Assignee**: fxstein  
**Labels**: enhancement

## Overview

Create the ability to pass a single image file to goprox (even without the path) and provide the full path and summary metadata together with warnings if e.g. system create date is not matching the EXIF create date.

## Current State Analysis

### Existing Capabilities
- Batch file processing
- EXIF data extraction
- Metadata analysis
- File path handling

### Current Limitations
- No single file analysis
- Requires full file paths
- No quick metadata summary
- Limited file validation

## Implementation Strategy

### Phase 1: Single File Detection (High Priority)
**Estimated Effort**: 1-2 days

#### 1.1 File Search Logic
```zsh
# Enhanced file search
scripts/analysis/find-file.zsh
```
- Search for files by name across library
- Handle partial filename matches
- Support multiple file formats
- Provide search results

#### 1.2 File Validation
```zsh
# File validation logic
scripts/analysis/validate-file.zsh
```
- Check file existence and accessibility
- Validate file format
- Extract basic metadata
- Handle error conditions

### Phase 2: Metadata Analysis (High Priority)
**Estimated Effort**: 2-3 days

#### 2.1 Enhanced Metadata Extraction
```zsh
# Comprehensive metadata analysis
scripts/analysis/extract-metadata.zsh
```
- Extract EXIF data
- Compare system vs EXIF timestamps
- Analyze file properties
- Generate summary report

#### 2.2 Warning System
```zsh
# Warning detection and reporting
scripts/analysis/detect-warnings.zsh
```
- Detect timestamp mismatches
- Identify metadata issues
- Flag potential problems
- Provide actionable advice

### Phase 3: User Interface Enhancement (Medium Priority)
**Estimated Effort**: 1-2 days

#### 3.1 Summary Display
```zsh
# Enhanced summary output
scripts/analysis/display-summary.zsh
```
- Format metadata for display
- Highlight important information
- Show warnings prominently
- Provide file location details

#### 3.2 Interactive Features
- Allow file selection from search results
- Provide detailed analysis options
- Support batch summary generation

## Technical Design

### File Search Algorithm
```zsh
# File search workflow
1. Parse input filename
2. Search in current directory
3. Search in library directories
4. Search in archive locations
5. Return matching files
6. Handle multiple matches
```

### Metadata Analysis Structure
```json
{
  "file_info": {
    "filename": "20221028112412_GoPro_Hero11_5131_G0327016.JPG",
    "full_path": "/Users/user/goprox/processed/JPEG/2022/20221011/P_20221028112412_GoPro_Hero11_5131_G0327016.jpg",
    "size": 5242880,
    "format": "JPEG",
    "dimensions": "4000x3000"
  },
  "timestamps": {
    "system_created": "2022-10-28T11:24:12Z",
    "exif_created": "2022-10-28T11:24:12Z",
    "system_modified": "2022-10-28T11:24:12Z",
    "exif_modified": "2022-10-28T11:24:12Z"
  },
  "camera_info": {
    "model": "HERO11 Black",
    "serial": "5131",
    "firmware": "H22.01.01.10.00"
  },
  "warnings": [
    {
      "type": "timestamp_mismatch",
      "message": "System create date differs from EXIF create date",
      "severity": "warning"
    }
  ]
}
```

### Warning Detection Logic
```zsh
# Warning detection workflow
1. Compare system vs EXIF timestamps
2. Check for missing metadata
3. Validate file integrity
4. Detect processing issues
5. Generate warning messages
```

## Integration Points

### Main goprox Script
- Add single file analysis commands
- Integrate with existing workflow
- Maintain backward compatibility

### File Processing System
- Leverage existing metadata extraction
- Use current file validation
- Extend processing capabilities

### Library Management
- Search across library structure
- Access processed file information
- Maintain file relationships

## Success Metrics

- **Accuracy**: 100% correct file identification
- **Performance**: <5 second analysis time
- **Usability**: Intuitive command interface
- **Coverage**: Support for all file formats

## Dependencies

- Existing metadata extraction
- File processing infrastructure
- Library search capabilities
- EXIF data handling

## Risk Assessment

### Low Risk
- Non-breaking changes
- Based on existing infrastructure
- Reversible implementation

### Medium Risk
- File search complexity
- Performance with large libraries
- User interface design

### High Risk
- File format variations
- Metadata extraction edge cases
- Search result ambiguity

### Mitigation Strategies
- Robust error handling
- Clear user feedback
- Performance optimization
- Extensive testing

## Testing Strategy

### Unit Testing
```zsh
# Test individual components
scripts/test/test-file-search.zsh
scripts/test/test-metadata-analysis.zsh
```
- Test file search logic
- Validate metadata extraction
- Check warning detection

### Integration Testing
```zsh
# Test complete workflow
scripts/test/test-single-file-summary.zsh
```
- Test end-to-end functionality
- Validate user interface
- Check performance

### User Acceptance Testing
- Test with real files
- Validate user experience
- Check edge cases

## Example Usage

```zsh
# Basic single file summary
goprox 20221028112412_GoPro_Hero11_5131_G0327016.JPG

# Search and analyze
goprox --find G0327016.JPG

# Detailed analysis
goprox --analyze 20221028112412_GoPro_Hero11_5131_G0327016.JPG --verbose

# Batch summary
goprox --summary *.JPG
```

## Next Steps

1. **Immediate**: Implement file search logic
2. **Week 1**: Add metadata analysis
3. **Week 2**: Implement warning system
4. **Week 3**: Enhance user interface
5. **Week 4**: Testing and documentation

## Related Issues

- #67: Enhanced default behavior (integration)
- #69: Enhanced SD card management (file discovery)
- #4: Automatic imports (file analysis)
- #10: Multi-tier storage (file location) 