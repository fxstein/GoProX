# Issue #26: Delta Patch Compression

**Issue Title**: Feature: Delta patch compress optional files  
**Status**: Open  
**Assignee**: fxstein  
**Labels**: enhancement, further investigation

## Overview

Implement delta patch compression for optional files to significantly reduce storage requirements. Since the delta between `imported` and `processed` media is metadata only, delta patches can replace media files with significantly smaller delta files while allowing restoration of the original file later.

## Current State Analysis

### Existing Capabilities
- Three-layer storage: archive, imported, processed
- Metadata-only differences between imported and processed
- File lineage tracking
- Basic compression support

### Current Limitations
- High storage requirements (3 copies of data)
- No delta compression
- Manual storage management
- Inefficient space utilization

## Implementation Strategy

### Phase 1: Delta Patch System (High Priority)
**Estimated Effort**: 4-5 days

#### 1.1 Delta Generation
```zsh
# Delta patch creation
scripts/compression/create-delta.zsh
```
- Generate delta patches using xdelta3
- Compare imported vs processed files
- Create compressed delta files
- Validate patch integrity

#### 1.2 Delta Application
```zsh
# Delta patch application
scripts/compression/apply-delta.zsh
```
- Apply delta patches to restore files
- Validate restored file integrity
- Handle patch application errors
- Provide rollback capabilities

### Phase 2: Storage Management (High Priority)
**Estimated Effort**: 3-4 days

#### 2.1 Automated Compression
```zsh
# Automated delta compression
scripts/compression/compress-imported.zsh
```
- Automatically compress imported files
- Replace original files with delta patches
- Maintain file relationships
- Track compression metadata

#### 2.2 Storage Optimization
```zsh
# Storage optimization workflow
scripts/compression/optimize-storage.zsh
```
- Identify compression candidates
- Calculate space savings
- Execute compression operations
- Monitor storage usage

### Phase 3: Advanced Features (Medium Priority)
**Estimated Effort**: 3-4 days

#### 3.1 Compression Policies
```zsh
# Compression policy management
scripts/compression/manage-policies.zsh
```
- Configurable compression rules
- Age-based compression
- Size-based compression
- User-defined policies

#### 3.2 Recovery and Maintenance
```zsh
# Recovery and maintenance tools
scripts/compression/maintain-deltas.zsh
```
- Validate delta integrity
- Repair corrupted patches
- Rebuild missing deltas
- Clean up orphaned files

## Technical Design

### Delta Patch Format
```zsh
# Delta patch structure
imported/
├── 2022/
│   └── 20221011/
│       ├── 20221011151401_GoPro_Hero10_2442_G1541642.JPG.xdelta
│       └── 20221011151401_GoPro_Hero10_2442_G1541642.JPG.meta
```

### Delta Generation Process
```zsh
# Delta creation workflow
1. Identify imported file
2. Locate corresponding processed file
3. Generate delta using xdelta3
4. Validate delta integrity
5. Replace original with delta
6. Store metadata for restoration
```

### Compression Metadata
```json
{
  "delta_info": {
    "original_file": "20221011151401_GoPro_Hero10_2442_G1541642.JPG",
    "processed_file": "P_20221011151401_GoPro_Hero10_2442_G1541642.jpg",
    "delta_file": "20221011151401_GoPro_Hero10_2442_G1541642.JPG.xdelta",
    "original_size": 4718592,
    "delta_size": 14336,
    "compression_ratio": 99.7,
    "created": "2024-01-15T10:30:00Z",
    "checksum": "sha256:abc123..."
  }
}
```

## Integration Points

### Existing Storage System
- Integrate with current file structure
- Maintain backward compatibility
- Preserve file relationships

### Main goprox Script
- Add compression commands
- Integrate with processing workflow
- Provide user feedback

### File Processing
- Handle compressed files during processing
- Maintain processing capabilities
- Ensure data integrity

## Success Metrics

- **Storage Reduction**: 99% reduction in imported file storage
- **Performance**: <30 second delta generation
- **Reliability**: 100% successful restoration
- **Compatibility**: Seamless integration with existing workflow

## Dependencies

- xdelta3 compression tool
- Existing file processing system
- Storage management infrastructure
- File integrity validation

## Risk Assessment

### Low Risk
- Non-destructive compression
- Reversible implementation
- Based on proven technology

### Medium Risk
- Delta generation complexity
- Performance impact
- Storage management overhead

### High Risk
- Data corruption during compression
- Delta application failures
- Storage system complexity

### Mitigation Strategies
- Extensive testing and validation
- Robust error handling
- Backup and recovery procedures
- Gradual implementation

## Testing Strategy

### Unit Testing
```zsh
# Test individual components
scripts/test/test-delta-generation.zsh
scripts/test/test-delta-application.zsh
```
- Test delta creation
- Validate delta application
- Check integrity validation

### Integration Testing
```zsh
# Test complete workflow
scripts/test/test-compression-workflow.zsh
```
- Test end-to-end compression
- Validate restoration process
- Check performance impact

### Stress Testing
- Test with large files
- Validate memory usage
- Check disk space handling

## Example Usage

```zsh
# Compress imported files
goprox --compress-imported

# Restore specific file
goprox --restore 20221011151401_GoPro_Hero10_2442_G1541642.JPG

# Check compression status
goprox --compression-status

# Optimize storage
goprox --optimize-storage
```

## Next Steps

1. **Immediate**: Implement delta generation
2. **Week 1**: Add delta application logic
3. **Week 2**: Implement storage management
4. **Week 3**: Add advanced features
5. **Week 4**: Testing and optimization

## Related Issues

- #10: Multi-tier storage support (storage optimization)
- #66: Repository cleanup (organization)
- #67: Enhanced default behavior (integration)
- #69: Enhanced SD card management (storage efficiency) 