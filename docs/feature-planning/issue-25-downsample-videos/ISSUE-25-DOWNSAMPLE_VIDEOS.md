# Issue #25: Downsample Videos

**Issue Title**: Feature: Downsample videos  
**Status**: Open  
**Assignee**: Unassigned  
**Labels**: enhancement

## Overview

Create the ability to downscale and sample video files. Generate lower resolution and time-limited previews that are significantly smaller in size and can be easily shared with various applications and platforms.

## Current State Analysis

### Existing Capabilities
- Video file import and processing
- Basic file management
- No video downsampling or preview generation

### Current Limitations
- Large video file sizes
- No preview or sample generation
- No integration with sharing workflows

## Implementation Strategy

### Phase 1: Downsampling Script (High Priority)
**Estimated Effort**: 2-3 days

#### 1.1 Downsampling Script
```zsh
# Downsample video script
scripts/processing/downsample-video.zsh
```
- Use ffmpeg to downscale videos to 720p
- Lower frame rates and quality
- Limit to first 30 seconds of video
- Output to preview directory

#### 1.2 Preview Directory Structure
```zsh
# Preview directory
~/goprox/preview/
├── 2024/
│   └── 20240115/
│       ├── GX012299_preview.mp4
│       └── GL012297_preview.mp4
```

### Phase 2: Integration with Main Workflow (Medium Priority)
**Estimated Effort**: 2 days

#### 2.1 Main Script Integration
```zsh
# New command options
goprox --downsample
goprox --generate-preview
```
- Add preview generation to import or process steps
- Allow batch preview generation

#### 2.2 Sharing Workflow
- Integrate with sharing/export features
- Provide easy access to previews

## Technical Design

### Downsampling Command
```zsh
# ffmpeg downsampling command
ffmpeg -i input.mp4 -vf "scale=1280:720" -r 24 -t 30 -c:v libx264 -preset fast -crf 28 -c:a aac -b:a 128k output_preview.mp4
```
- Scale to 720p
- Limit to 30 seconds
- Lower frame rate to 24fps
- Use fast preset and higher CRF for smaller size

### Preview File Naming
- Append `_preview` to original filename
- Store in preview directory with date-based subfolders

## Integration Points

### Main goprox Script
- Add preview generation commands
- Integrate with import and process workflows
- Maintain backward compatibility

### File Management
- Organize previews by date and source
- Track preview generation status

### Sharing/Export
- Provide commands to export or share previews
- Integrate with external applications

## Success Metrics

- **Performance**: <1 minute per preview
- **Size Reduction**: 90%+ smaller than original
- **Usability**: Easy preview access and sharing
- **Coverage**: Support for all major video formats

## Dependencies

- ffmpeg installed
- Existing file management infrastructure
- Preview directory structure

## Risk Assessment

### Low Risk
- Non-destructive operation
- Based on proven tools (ffmpeg)
- Reversible implementation

### Medium Risk
- ffmpeg compatibility issues
- Performance with large files
- User interface design

### High Risk
- File format edge cases
- Preview quality issues
- Integration with sharing workflows

### Mitigation Strategies
- Extensive testing with various formats
- Robust error handling
- User feedback integration

## Testing Strategy

### Unit Testing
```zsh
# Test downsampling script
scripts/test/test-downsample-video.zsh
```
- Test with various video formats
- Validate preview quality
- Check performance

### Integration Testing
```zsh
# Test workflow integration
scripts/test/test-preview-workflow.zsh
```
- Test end-to-end preview generation
- Validate sharing/export features

### User Acceptance Testing
- Test with real video files
- Validate user experience
- Check edge cases

## Example Usage

```zsh
# Downsample a video
goprox --downsample GX012299.MP4

# Generate previews for all videos
goprox --generate-preview *.MP4

# Share a preview
goprox --share-preview GX012299_preview.mp4
```

## Next Steps

1. **Immediate**: Implement downsampling script
2. **Week 1**: Integrate with main workflow
3. **Week 2**: Add sharing/export features
4. **Week 3**: Testing and documentation

## Related Issues

- #66: Repository cleanup (organization)
- #67: Enhanced default behavior (integration)
- #69: Enhanced SD card management (preview support) 