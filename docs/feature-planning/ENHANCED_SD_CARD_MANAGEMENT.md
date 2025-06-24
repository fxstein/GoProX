# Enhanced SD Card Management Feature Requirements

## Overview

Transform GoProX from a manual, directory-based tool to an intelligent, SD card-aware system that automatically detects, manages, and tracks GoPro SD cards across multiple operations.

## Core Requirements

### 1. Automatic SD Card Detection
- **Requirement**: Automatically identify all mounted GoPro SD cards when `goprox` is run from anywhere
- **Current State**: Manual detection via separate `rename-gopro-sd.zsh` script
- **Target State**: Built-in detection in main `goprox` workflow
- **Implementation**: 
  - Scan `/Volumes/` for GoPro SD cards using existing detection logic
  - Identify cards by volume name patterns and firmware files
  - Extract model and serial number information
  - Present detected cards to user with options

### 2. Automatic SD Card Renaming
- **Requirement**: Automatically rename SD cards to `HERO{model}-{last4digits}` format
- **Current State**: Manual execution via `rename-gopro-sd.zsh`
- **Target State**: Integrated into main workflow with user confirmation
- **Implementation**:
  - Use existing renaming logic from `rename-gopro-sd.zsh`
  - Apply renaming before any other operations
  - Handle cases where cards are already properly named
  - Provide user feedback and confirmation options

### 3. Multi-Card Workflow Support
- **Requirement**: Process multiple SD cards without manual `cd` operations
- **Current State**: User must navigate to each mount point manually
- **Target State**: Automatic iteration through detected cards
- **Implementation**:
  - Detect all GoPro cards at startup
  - Present list of cards to user
  - Allow selection of specific cards or "all cards"
  - Execute requested operations on each selected card
  - Provide progress feedback for each card

### 4. SD Card Tracking System
- **Requirement**: Create persistent tracking logs for all SD cards
- **Current State**: No tracking mechanism exists
- **Target State**: Comprehensive logging of all card interactions
- **Implementation**:
  - Generate unique identifier per card (model + serial + first seen date)
  - Log all operations performed on each card
  - Track card usage patterns and history
  - Enable card-specific reporting and analytics

## Technical Design Suggestions

### SD Card Unique Identification

**Proposed Identifier Format**: `{MODEL}_{SERIAL}_{FIRST_SEEN_DATE}`
- Example: `HERO11_5131_20241224`
- Ensures uniqueness even if serial numbers are duplicated
- Human-readable and sortable

**Alternative Format**: `{MODEL}_{SERIAL}_{UUID_SUFFIX}`
- Example: `HERO11_5131_a1b2c3d4`
- More robust for uniqueness
- Less human-readable

### Tracking Log Storage Structure

**Option 1: Dedicated Tracking Directory**
```
~/.goprox/
├── tracking/
│   ├── cards/
│   │   ├── HERO11_5131_20241224.json
│   │   ├── HERO10_8034_20241220.json
│   │   └── HERO9_4139_20241215.json
│   ├── operations/
│   │   ├── 2024/
│   │   │   ├── 12/
│   │   │   │   ├── 24_operations.log
│   │   │   │   └── 25_operations.log
│   │   │   └── 11/
│   │   └── 2023/
│   └── summary/
│       ├── monthly_summary_202412.json
│       └── yearly_summary_2024.json
```

**Option 2: Integrated with Library Structure**
```
~/goprox/
├── tracking/
│   ├── cards/
│   ├── operations/
│   └── summary/
├── archive/
├── imported/
├── processed/
└── deleted/
```

**Option 3: Database Approach**
```
~/.goprox/
├── tracking.db (SQLite database)
└── tracking_logs/
    └── {YYYY}/{MM}/operations.log
```

### Log Format Suggestions

**Card Metadata (JSON)**
```json
{
  "card_id": "HERO11_5131_20241224",
  "model": "HERO11 Black",
  "serial": "5131",
  "first_seen": "2024-12-24T10:30:00Z",
  "last_seen": "2024-12-25T14:22:00Z",
  "total_operations": 15,
  "volume_names": [
    "HERO11-5131",
    "GOPRO",
    "NO NAME"
  ],
  "firmware_versions": [
    "H22.01.02.32.00",
    "H22.01.02.10.00"
  ],
  "operations_summary": {
    "import": 8,
    "archive": 6,
    "firmware": 2,
    "clean": 5
  }
}
```

**Operation Log (Structured Text)**
```
2024-12-25T14:22:00Z | HERO11_5131_20241224 | import | /Volumes/HERO11-5131 | SUCCESS | 127 files imported
2024-12-25T14:22:00Z | HERO11_5131_20241224 | archive | /Volumes/HERO11-5131 | SUCCESS | 2.1GB archived
2024-12-25T14:22:00Z | HERO11_5131_20241224 | clean | /Volumes/HERO11-5131 | SUCCESS | 127 files removed
```

### Integration Points

**1. Main goprox Workflow**
```zsh
# New workflow
goprox --auto-detect --import --archive --clean
goprox --auto-detect --firmware
goprox --auto-detect --process-all
```

**2. Card Selection Options**
```zsh
# Interactive selection
goprox --auto-detect --select

# Specific card
goprox --auto-detect --card HERO11_5131_20241224 --import

# All cards
goprox --auto-detect --all --import
```

**3. Tracking Commands**
```zsh
# View card history
goprox --tracking --card HERO11_5131_20241224

# Generate reports
goprox --tracking --report monthly
goprox --tracking --report yearly

# Export tracking data
goprox --tracking --export json
```

## Implementation Phases

### Phase 1: Standalone Testing
1. **Enhanced Detection Script**
   - Improve `rename-gopro-sd.zsh` with better detection
   - Add multi-card support
   - Test with various card types and scenarios

2. **Tracking Prototype**
   - Create standalone tracking script
   - Test different storage formats
   - Validate log structure and performance

3. **Integration Testing**
   - Test detection + renaming + tracking workflow
   - Validate with multiple cards simultaneously
   - Performance testing with large numbers of files

### Phase 2: Core Integration
1. **Main goprox Integration**
   - Add `--auto-detect` flag to main script
   - Integrate detection logic
   - Add card selection mechanisms

2. **Workflow Enhancement**
   - Modify existing operations to work with detected cards
   - Add progress reporting for multi-card operations
   - Implement error handling for individual card failures

### Phase 3: Advanced Features
1. **Tracking Dashboard**
   - Add tracking commands to main script
   - Create reporting and analytics features
   - Implement data export capabilities

2. **Smart Defaults**
   - Learn user preferences for card operations
   - Suggest optimal workflows based on card history
   - Implement automatic operation sequencing

## Questions for Iteration

1. **Storage Location**: Which tracking storage structure do you prefer?
2. **Card Identification**: Should we use date-based or UUID-based identifiers?
3. **Log Format**: JSON vs structured text vs database approach?
4. **Integration Level**: How deeply should this integrate with existing workflows?
5. **User Interface**: How much automation vs user control do you want?
6. **Performance**: What's the acceptable overhead for tracking operations?
7. **Data Retention**: How long should we keep tracking data?
8. **Privacy**: Should tracking data be encrypted or anonymized?

## Success Metrics

- **Usability**: Reduce manual steps by 80%
- **Reliability**: 99% successful card detection and renaming
- **Performance**: <5 second detection time for 10+ cards
- **Tracking**: 100% operation logging accuracy
- **User Adoption**: Seamless integration with existing workflows

## Next Steps

1. **Review and refine requirements**
2. **Choose preferred technical approaches**
3. **Create detailed implementation plan**
4. **Begin Phase 1 standalone testing**
5. **Iterate based on testing results**
6. **Plan Phase 2 integration** 