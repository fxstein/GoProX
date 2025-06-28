# Issue #10: Multi-Tier Storage Support

**Issue Title**: Feature: Multi Tier Storage Support  
**Status**: Open  
**Assignee**: fxstein  
**Labels**: enhancement

## Overview

Enable GoProX to support multi-tier storage setups, allowing different parts of the library (archive, imported, processed) to reside on different storage devices. Add support for mobile vs home/office configurations and automate migration between tiers.

## Current State Analysis

### Existing Capabilities
- Single storage hierarchy
- Manual configuration for library location
- Symbolic link support for subfolders
- Basic import and processing workflows

### Current Limitations
- No automated multi-tier support
- Manual migration between devices
- No environment detection (mobile vs home)
- No cloud archival integration

## Implementation Strategy

### Phase 1: Multi-Tier Configuration (High Priority)
**Estimated Effort**: 2-3 days

#### 1.1 Configuration System
```zsh
# Multi-tier config file
~/.goprox/config.yaml
```
- Define storage locations for each tier
- Support for archive, imported, processed, deleted
- Allow user customization

#### 1.2 Environment Detection
```zsh
# Environment detection logic
scripts/storage/detect-environment.zsh
```
- Detect connected storage devices
- Auto-select mobile or home configuration
- Provide user feedback

### Phase 2: Migration Workflow (Medium Priority)
**Estimated Effort**: 2-3 days

#### 2.1 Migration Script
```zsh
# Migration workflow
scripts/storage/migrate-media.zsh
```
- Migrate media between tiers
- Handle device availability
- Track migration status
- Provide rollback options

#### 2.2 Cloud Archival Integration
- Integrate with AWS Glacier (Issue #11)
- Support for long-term archival
- Automate archival of old media

### Phase 3: Advanced Features (Medium Priority)
**Estimated Effort**: 2-3 days

#### 3.1 Policy Management
- Define migration and archival policies
- Age-based, size-based, or usage-based rules
- User-defined policies

#### 3.2 Reporting and Analytics
- Track storage usage by tier
- Generate migration and archival reports
- Provide user feedback and recommendations

## Technical Design

### Configuration File Format
```yaml
# Example config.yaml
storage:
  archive: /Volumes/ArchiveDrive/goprox/archive
  imported: /Volumes/MobileSSD/goprox/imported
  processed: /Volumes/HomeSSD/goprox/processed
  deleted: /Volumes/MobileSSD/goprox/deleted
```

### Environment Detection Logic
```zsh
# Detection workflow
1. Scan for known storage devices
2. Match device UUIDs or labels
3. Select appropriate configuration
4. Notify user of environment
```

### Migration Workflow
```zsh
# Migration process
1. Identify files to migrate
2. Copy files to target tier
3. Validate integrity
4. Remove originals if successful
5. Update tracking metadata
```

## Integration Points

### Main goprox Script
- Add commands for migration and environment selection
- Integrate with import and processing workflows
- Maintain backward compatibility

### Storage Management
- Support for multiple storage devices
- Automate migration and archival
- Track device availability

### Cloud Archival
- Integrate with AWS Glacier (Issue #11)
- Automate archival of old media
- Provide retrieval options

## Success Metrics

- **Flexibility**: Support for any storage configuration
- **Reliability**: 99% successful migrations
- **Performance**: <1 minute per GB migrated
- **User Experience**: Seamless environment switching

## Dependencies

- Device detection logic
- File system operations
- Cloud archival integration
- User configuration management

## Risk Assessment

### Low Risk
- Non-destructive operation
- Reversible implementation
- Based on standard file operations

### Medium Risk
- Device detection complexity
- Migration performance
- User configuration errors

### High Risk
- Data loss during migration
- Device unavailability
- Cloud integration issues

### Mitigation Strategies
- Extensive testing and validation
- Robust error handling
- User confirmation for critical actions
- Backup and recovery procedures

## Testing Strategy

### Unit Testing
```zsh
# Test configuration and migration
scripts/test/test-storage-config.zsh
scripts/test/test-migration-workflow.zsh
```
- Test config parsing
- Validate migration logic
- Check device detection

### Integration Testing
```zsh
# Test end-to-end workflow
scripts/test/test-multi-tier-storage.zsh
```
- Test with multiple devices
- Validate environment switching
- Check cloud archival integration

### User Acceptance Testing
- Test with real storage setups
- Validate user experience
- Check edge cases

## Example Usage

```zsh
# Migrate imported files to archive
goprox --migrate imported archive

# Switch to mobile environment
goprox --set-environment mobile

# Archive old files to Glacier
goprox --archive-glacier-old
```

## Next Steps

1. **Immediate**: Implement configuration system
2. **Week 1**: Add environment detection
3. **Week 2**: Implement migration workflow
4. **Week 3**: Integrate cloud archival
5. **Week 4**: Testing and documentation

## Related Issues

- #11: AWS Glacier support (cloud archival)
- #13: Propagate and collect deletes (deleted tier)
- #66: Repository cleanup (organization)
- #67: Enhanced default behavior (integration)
- #69: Enhanced SD card management (multi-device) 