# Issue #13: Propagate and Collect Deletes

**Issue Title**: Feature: Propagate and Collect Deletes  
**Status**: Open  
**Assignee**: fxstein  
**Labels**: enhancement

## Overview

Enable GoProX to propagate and collect deletes from Apple Photos and other platforms, ensuring that deleted media files are not re-imported or retained in the library. Maintain a persistent list of deleted files and automate their removal from the library structure.

## Current State Analysis

### Existing Capabilities
- Import and process media files
- Integration with Apple Photos (manual)
- File tracking and metadata management
- Basic library structure (archive, imported, processed)

### Current Limitations
- No automated delete propagation
- Deleted files remain in library
- Risk of re-importing deleted files
- No persistent deleted files list

## Implementation Strategy

### Phase 1: Deleted Files Extraction (High Priority)
**Estimated Effort**: 2-3 days

#### 1.1 Apple Photos SQLite Query
```sql
SELECT 
  zAddAssetAttr.ZORIGINALFILENAME AS 'zAddAssetAttr-Original Filename'
FROM ZASSET zAsset
  JOIN ZADDITIONALASSETATTRIBUTES zAddAssetAttr ON zAddAssetAttr.Z_PK = zAsset.ZADDITIONALATTRIBUTES
WHERE zAsset.ZTRASHEDSTATE = 1
ORDER BY zAddAssetAttr.ZORIGINALFILENAME;
```
- Extract list of recently deleted files
- Filter for GoProX-specific files
- Store results in deleted list

#### 1.2 Deleted List Storage
```zsh
# Deleted files list structure
~/goprox/deleted/
├── 2024/
│   └── deleted_2024.txt
├── 2023/
│   └── deleted_2023.txt
```
- Group deleted files by year
- Maintain persistent record
- Update on each import

### Phase 2: Library Cleanup Automation (High Priority)
**Estimated Effort**: 2-3 days

#### 2.1 Cleanup Script
```zsh
# Cleanup deleted files
scripts/maintenance/cleanup-deleted.zsh
```
- Remove deleted files from processed/imported
- Prevent re-import of deleted files
- Log cleanup actions

#### 2.2 Integration with Import Workflow
- Check deleted list before import
- Skip files present in deleted list
- Update deleted list on new deletions

### Phase 3: Cross-Platform Support (Medium Priority)
**Estimated Effort**: 2-3 days

#### 3.1 Platform Abstraction
- Support for other photo management platforms
- Abstract deleted file extraction logic
- Maintain consistent deleted list format

#### 3.2 User Interface
- Provide commands to view deleted files
- Allow manual addition/removal
- Display cleanup logs

## Technical Design

### Deleted List Format
```txt
IMG_0922.PNG
P_20220923092015_GoPro_Max_6013_GS__4797.jpg
P_20220923092019_GoPro_Max_6013_GS__4798.jpg
P_20220923092026_GoPro_Hero11_8909_GOPR0089.jpg
```

### Cleanup Workflow
```zsh
# Cleanup workflow
1. Extract deleted files from Photos
2. Update deleted list
3. Remove files from processed/imported
4. Prevent re-import of deleted files
5. Log actions
```

### Integration Points

### Main goprox Script
- Integrate cleanup and deleted list checks
- Maintain backward compatibility
- Provide user feedback

### Import Workflow
- Check deleted list before import
- Update deleted list on new deletions
- Log skipped files

### User Interface
- Commands to view/manage deleted files
- Display cleanup logs
- Manual override options

## Success Metrics

- **Reliability**: 100% deleted files removed
- **Consistency**: No re-import of deleted files
- **Performance**: <10 second cleanup for 10,000 files
- **User Experience**: Seamless integration

## Dependencies

- Apple Photos SQLite database access
- File system operations
- Import workflow integration
- User interface enhancements

## Risk Assessment

### Low Risk
- Non-destructive operation
- Reversible implementation
- Based on standard file operations

### Medium Risk
- Platform-specific differences
- SQLite schema changes
- Performance with large libraries

### High Risk
- Data loss from incorrect deletions
- Cross-platform compatibility
- User error in manual overrides

### Mitigation Strategies
- Extensive testing and validation
- Robust error handling
- User confirmation for critical actions
- Backup and recovery procedures

## Testing Strategy

### Unit Testing
```zsh
# Test deleted list extraction
scripts/test/test-deleted-extraction.zsh
```
- Test SQLite query logic
- Validate deleted list format
- Check file removal

### Integration Testing
```zsh
# Test cleanup workflow
scripts/test/test-cleanup-workflow.zsh
```
- Test end-to-end cleanup
- Validate import workflow integration
- Check performance

### User Acceptance Testing
- Test with real Photos libraries
- Validate user experience
- Check edge cases

## Example Usage

```zsh
# Run cleanup
goprox --cleanup-deleted

# View deleted files
goprox --list-deleted

# Add file to deleted list
goprox --add-deleted IMG_1234.JPG

# Remove file from deleted list
goprox --remove-deleted IMG_1234.JPG
```

## Next Steps

1. **Immediate**: Implement deleted list extraction
2. **Week 1**: Add cleanup automation
3. **Week 2**: Integrate with import workflow
4. **Week 3**: Add cross-platform support
5. **Week 4**: Testing and documentation

## Related Issues

- #66: Repository cleanup (organization)
- #67: Enhanced default behavior (integration)
- #69: Enhanced SD card management (library hygiene)
- #10: Multi-tier storage (deleted file management) 