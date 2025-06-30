# Issue #64: Exclude Firmware Zip Files

**Issue Title**: Enhancement: Exclude firmware zip files from release packages via .gitattributes  
**Status**: Open  
**Assignee**: fxstein  
**Labels**: enhancement

## Overview

Modify .gitattributes so that all zip files in the firmware and firmware.labs trees are excluded from future release packages. This will significantly reduce package size now that live fetch and caching from URLs for firmware files has been implemented.

## Current State Analysis

### Existing Capabilities
- URL-based firmware fetching (Issue #60)
- Local firmware caching system
- Release package generation
- Firmware tree structure

### Current Limitations
- Firmware zip files included in release packages
- Large package sizes due to firmware files
- Inefficient distribution method
- Redundant storage

## Implementation Strategy

### Phase 1: .gitattributes Configuration (High Priority)
**Estimated Effort**: 1 day

#### 1.1 Export-Ignore Configuration
```gitattributes
# Exclude firmware zip files from release packages
firmware/**/*.zip export-ignore
firmware.labs/**/*.zip export-ignore

# Keep download.url files for reference
!firmware/**/download.url
!firmware.labs/**/download.url
```

#### 1.2 Validation Script
```zsh
# Validate .gitattributes configuration
scripts/maintenance/validate-gitattributes.zsh
```
- Check export-ignore rules
- Verify file exclusions
- Test release package generation

### Phase 2: Release Process Updates (High Priority)
**Estimated Effort**: 1 day

#### 2.1 Release Script Enhancement
```zsh
# Update release script
scripts/release/trigger-workflow.zsh
```
- Ensure firmware zip files are excluded
- Validate package contents
- Update documentation

#### 2.2 Package Validation
```zsh
# Package validation script
scripts/release/validate-package.zsh
```
- Check for excluded files
- Verify package size reduction
- Validate functionality

### Phase 3: Documentation Updates (Medium Priority)
**Estimated Effort**: 1 day

#### 3.1 Process Documentation
- Update release process documentation
- Document new package structure
- Explain firmware fetching mechanism

#### 3.2 User Communication
- Update README with new process
- Document firmware installation process
- Provide troubleshooting guidance

## Technical Design

### .gitattributes Rules
```gitattributes
# Firmware file exclusions
firmware/**/*.zip export-ignore
firmware.labs/**/*.zip export-ignore

# Preserve URL files
!firmware/**/download.url export-ignore
!firmware.labs/**/download.url export-ignore

# Preserve README files
!firmware/**/README.txt export-ignore
!firmware.labs/**/README.txt export-ignore
```

### Package Structure
**Before**:
```
goprox-v01.01.00.tar.gz
├── goprox
├── firmware/
│   ├── HERO11 Black/
│   │   ├── H22.01.02.32.00/
│   │   │   ├── UPDATE.zip (50MB)
│   │   │   └── download.url
│   │   └── ...
│   └── ...
└── ...
```

**After**:
```
goprox-v01.01.00.tar.gz
├── goprox
├── firmware/
│   ├── HERO11 Black/
│   │   ├── H22.01.02.32.00/
│   │   │   └── download.url
│   │   └── ...
│   └── ...
└── ...
```

### Size Impact Analysis
**Estimated Size Reduction**:
- Current package size: ~100MB
- After exclusion: ~10MB
- Reduction: ~90%

## Integration Points

### Release Automation
- GitHub Actions workflow updates
- Package validation in CI/CD
- Size monitoring

### Firmware System
- Integration with Issue #60 (URL-based fetch)
- Cache management
- Download verification

### User Experience
- Installation process updates
- Documentation updates
- Error handling

## Success Metrics

- **Package Size**: 90% reduction in release package size
- **Functionality**: 100% firmware functionality maintained
- **Performance**: Improved download and installation times
- **Reliability**: No impact on firmware operations

## Dependencies

- Issue #60 (Firmware URL-based fetch) - foundation
- Existing release process
- .gitattributes configuration

## Risk Assessment

### Low Risk
- Non-breaking change
- Reversible implementation
- Based on proven technology

### Medium Risk
- User confusion about missing files
- Installation process changes
- Documentation updates required

### Mitigation Strategies
- Clear documentation updates
- User communication
- Fallback mechanisms

## Testing Strategy

### Package Validation
```zsh
# Test package generation
scripts/test/test-package-exclusion.zsh
```
- Generate test packages
- Verify file exclusions
- Validate functionality

### Installation Testing
```zsh
# Test installation process
scripts/test/test-installation.zsh
```
- Test fresh installation
- Verify firmware functionality
- Check cache behavior

## Next Steps

1. **Immediate**: Update .gitattributes file
2. **Day 1**: Test package generation
3. **Day 2**: Update release process
4. **Day 3**: Update documentation
5. **Day 4**: Validate with test release

## Related Issues

- #60: Firmware URL-based fetch (enables this change)
- #65: Firmware automation (complements this)
- #66: Repository cleanup (organization)
- #67: Enhanced default behavior (integration) 