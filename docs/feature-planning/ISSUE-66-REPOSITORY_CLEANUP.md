# Issue #66: Repository Cleanup and Organization

**Issue Title**: Repository Cleanup and Organization  
**Status**: Open  
**Assignee**: fxstein  
**Labels**: enhancement, workflow

## Overview

Comprehensive cleanup and reorganization of the GoProX repository to improve maintainability, reduce size, and establish consistent standards.

## Current State Analysis

### Repository Size Issues
- Current size: ~5.1GB
- Large test files and media content
- Inconsistent file organization
- Missing size management strategies

### Organization Problems
- Scripts scattered across root directory
- Inconsistent naming conventions
- Missing file header standards
- No clear directory structure

## Implementation Strategy

### Phase 1: Git LFS Implementation (High Priority)
**Estimated Effort**: 2-3 days

#### 1.1 LFS Configuration
```zsh
# .gitattributes configuration
*.zip filter=lfs diff=lfs merge=lfs -text
*.mp4 filter=lfs diff=lfs merge=lfs -text
*.mov filter=lfs diff=lfs merge=lfs -text
*.jpg filter=lfs diff=lfs merge=lfs -text
*.jpeg filter=lfs diff=lfs merge=lfs -text
*.png filter=lfs diff=lfs merge=lfs -text
*.dng filter=lfs diff=lfs merge=lfs -text
```

#### 1.2 Migration Process
```zsh
# Migration script
scripts/maintenance/migrate-to-lfs.zsh
```
- Identify large files for LFS migration
- Migrate existing files to LFS
- Update .gitattributes
- Clean up repository history

### Phase 2: Script Organization (High Priority)
**Estimated Effort**: 1-2 days

#### 2.1 Directory Structure
```zsh
# New organization
scripts/
├── firmware/
│   ├── add-firmware.zsh
│   ├── discover-firmware.zsh
│   └── download-missing-firmware.zsh
├── release/
│   ├── bump-version.zsh
│   ├── generate-release-notes.zsh
│   └── release.zsh
├── maintenance/
│   ├── cleanup-repository.zsh
│   └── validate-standards.zsh
└── test/
    ├── run-tests.zsh
    └── validate-installation.zsh
```

#### 2.2 Naming Conventions
- Use kebab-case for script names
- Consistent file extensions (.zsh)
- Descriptive names that indicate purpose

### Phase 3: File Header Standards (Medium Priority)
**Estimated Effort**: 1-2 days

#### 3.1 Header Template
```zsh
#!/usr/bin/env zsh
#
# GoProX - [Script Name]
# Version: [version]
# Author: [author]
# Description: [brief description]
# Usage: [usage instructions]
# Dependencies: [list of dependencies]
#
# Copyright (c) [year] [author]
# Licensed under MIT License
```

#### 3.2 Implementation
- Create header template
- Update existing scripts
- Validate compliance

### Phase 4: Documentation Updates (Medium Priority)
**Estimated Effort**: 1-2 days

#### 4.1 README Updates
- Document new directory structure
- Update installation instructions
- Add contribution guidelines

#### 4.2 Developer Documentation
- Setup instructions for new contributors
- Development workflow documentation
- Testing procedures

## Technical Design

### Git LFS Configuration
**File Types for LFS**:
- Media files: .mp4, .mov, .jpg, .jpeg, .png, .dng
- Archives: .zip, .tar.gz
- Large data files: >10MB

**Exclusions**:
- Source code files
- Documentation
- Configuration files

### Directory Structure
```
GoProX/
├── goprox                    # Main script
├── scripts/                  # All utility scripts
│   ├── firmware/            # Firmware management
│   ├── release/             # Release automation
│   ├── maintenance/         # Repository maintenance
│   └── test/               # Testing utilities
├── docs/                    # Documentation
├── firmware/               # Firmware files (LFS)
├── firmware.labs/          # Labs firmware (LFS)
├── test/                   # Test data (LFS)
└── output/                 # Generated output
```

### File Size Management
**Target Repository Size**: <1GB  
**Strategy**: 
- Move large files to LFS
- Archive old test data
- Implement size monitoring

## Integration Points

### CI/CD Pipeline
- Add LFS validation
- Check file size limits
- Validate naming conventions

### Development Workflow
- Pre-commit hooks for standards
- Automated testing
- Documentation validation

### Release Process
- Include LFS files in releases
- Validate package size
- Check for missing dependencies

## Success Metrics

- **Repository Size**: Reduced to <1GB
- **Organization**: Clear directory structure
- **Standards**: 100% compliance with naming conventions
- **Performance**: Improved clone/pull times

## Dependencies

- Git LFS installation and configuration
- Existing script functionality
- Documentation structure

## Risk Assessment

### Low Risk
- LFS migration is well-documented
- Script reorganization is reversible
- Standards can be implemented incrementally

### Medium Risk
- LFS migration complexity
- Breaking existing workflows
- Performance impact of LFS

### Mitigation Strategies
- Thorough testing of LFS setup
- Gradual migration approach
- Performance monitoring

## Next Steps

1. **Immediate**: Set up Git LFS
2. **Week 1**: Migrate large files to LFS
3. **Week 2**: Reorganize script directory structure
4. **Week 3**: Implement file header standards
5. **Week 4**: Update documentation and validate

## Related Issues

- #60: Firmware URL-based fetch (reduces firmware file size)
- #64: Exclude firmware zip files (complements LFS)
- #20: Git-flow model (workflow standards)
- #68: AI instructions tracking (documentation standards) 