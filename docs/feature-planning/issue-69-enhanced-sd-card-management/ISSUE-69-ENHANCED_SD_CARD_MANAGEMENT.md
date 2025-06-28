# Issue #69: Enhanced SD Card Management

**Issue Title**: Enhancement: Enhanced SD Card Management  
**Status**: Open  
**Assignee**: fxstein  
**Labels**: enhancement

## Overview

Transform GoProX from a manual, directory-based tool to an intelligent, SD card-aware system that automatically detects, manages, and tracks GoPro SD cards across multiple operations.

## Current State Analysis

### Existing Capabilities
- Manual SD card detection via `rename-gopro-sd.zsh` script
- Basic firmware management and detection
- Individual card processing workflows

### Limitations
- No automatic multi-card detection
- Manual navigation required for each card
- No persistent tracking system
- No unified workflow for multiple cards

## Implementation Strategy

### Phase 1: Core Detection Enhancement (High Priority)
**Estimated Effort**: 2-3 days

#### 1.1 Enhanced Detection Engine
```zsh
# New detection module
scripts/sd-card/detect-cards.zsh
```
- Scan `/Volumes/` for all GoPro SD cards
- Extract model, serial, and firmware information
- Generate unique card identifiers
- Return structured data for processing

#### 1.2 Multi-Card Workflow Integration
```zsh
# New workflow commands
goprox --auto-detect --import --archive --clean
goprox --auto-detect --firmware
goprox --auto-detect --process-all
```
- Detect all cards at startup
- Present interactive selection menu
- Execute operations on selected cards
- Provide progress feedback

### Phase 2: Tracking System (Medium Priority)
**Estimated Effort**: 3-4 days

#### 2.1 Card Tracking Database
```zsh
# Storage structure
~/.goprox/tracking/
├── cards/
│   ├── HERO11_5131_20241224.json
│   └── HERO10_8034_20241220.json
├── operations/
│   └── 2024/12/24_operations.log
└── summary/
    └── monthly_summary_202412.json
```

#### 2.2 Tracking Commands
```zsh
goprox --tracking --card HERO11_5131_20241224
goprox --tracking --report monthly
goprox --tracking --export json
```

### Phase 3: Advanced Features (Low Priority)
**Estimated Effort**: 4-5 days

#### 3.1 Smart Defaults
- Learn user preferences
- Suggest optimal workflows
- Automatic operation sequencing

#### 3.2 Analytics Dashboard
- Card usage patterns
- Performance metrics
- Storage optimization suggestions

## Technical Design

### Card Identification Format
**Primary Format**: `{MODEL}_{SERIAL}_{FIRST_SEEN_DATE}`
- Example: `HERO11_5131_20241224`
- Ensures uniqueness and readability
- Sortable by date

### Log Format
**Card Metadata (JSON)**:
```json
{
  "card_id": "HERO11_5131_20241224",
  "model": "HERO11 Black",
  "serial": "5131",
  "first_seen": "2024-12-24T10:30:00Z",
  "last_seen": "2024-12-25T14:22:00Z",
  "total_operations": 15,
  "volume_names": ["HERO11-5131", "GOPRO"],
  "firmware_versions": ["H22.01.02.32.00"],
  "operations_summary": {
    "import": 8,
    "archive": 6,
    "firmware": 2,
    "clean": 5
  }
}
```

**Operation Log (Structured Text)**:
```
2024-12-25T14:22:00Z | HERO11_5131_20241224 | import | /Volumes/HERO11-5131 | SUCCESS | 127 files imported
```

## Integration Points

### Main goprox Workflow
- Add `--auto-detect` flag to main script
- Integrate detection logic into existing operations
- Maintain backward compatibility

### Existing Scripts
- Enhance `rename-gopro-sd.zsh` with multi-card support
- Integrate with firmware management scripts
- Extend mount point processing

## Success Metrics

- **Usability**: Reduce manual steps by 80%
- **Reliability**: 99% successful card detection and renaming
- **Performance**: <5 second detection time for 10+ cards
- **Tracking**: 100% operation logging accuracy

## Dependencies

- Issue #67 (Enhanced default behavior) - provides foundation
- Issue #63 (SD card renaming) - core functionality
- Issue #60 (Firmware URL-based fetch) - firmware integration

## Risk Assessment

### Low Risk
- Detection logic based on existing proven code
- Backward compatibility maintained
- Incremental implementation possible

### Medium Risk
- Multi-card workflow complexity
- Performance with large numbers of cards
- User interface design decisions

### Mitigation Strategies
- Extensive testing with multiple card scenarios
- Performance profiling and optimization
- User feedback integration

## Next Steps

1. **Immediate**: Review and approve technical design
2. **Week 1**: Implement Phase 1 detection enhancement
3. **Week 2**: Add multi-card workflow support
4. **Week 3**: Implement basic tracking system
5. **Week 4**: Testing and refinement

## Related Issues

- #67: Enhanced default behavior (foundation)
- #63: SD card renaming (core functionality)
- #60: Firmware URL-based fetch (integration)
- #10: Multi-tier storage support (future enhancement) 