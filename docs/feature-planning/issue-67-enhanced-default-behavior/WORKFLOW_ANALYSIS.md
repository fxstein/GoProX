# GoProX Workflow Analysis: System Readiness and Content-Based Decision Trees

**Reference**: This document extends [Issue #67: Enhanced Default Behavior](ISSUE-67-ENHANCED_DEFAULT_BEHAVIOR.md) with systematic workflow analysis.

## Overview

This document establishes the framework for intelligent workflow selection based on two critical factors:
1. **System Readiness**: What storage and processing capabilities are available
2. **Content Analysis**: What media content requires processing

## System Readiness Assessment

### Storage Validation Requirements

Before any workflow can be executed, the system must validate storage availability:

```zsh
# Required storage validation
_validate_storage() {
  # Validate library root
  _test_library_component "library" "${library/#\~/$HOME}"
  
  # Validate required subdirectories
  _test_library_component "archive" "${library/#\~/$HOME}/archive"
  _test_library_component "imported" "${library/#\~/$HOME}/imported" 
  _test_library_component "processed" "${library/#\~/$HOME}/processed"
  _test_library_component "deleted" "${library/#\~/$HOME}/deleted"
}
```

### Workflow Capability Matrix

| Storage Component | Archive Tasks | Import Tasks | Process Tasks | Clean Tasks |
|------------------|---------------|--------------|---------------|-------------|
| Library Root     | ❌ Required   | ❌ Required   | ❌ Required    | ❌ Required  |
| Archive Dir      | ❌ Required   | ✅ Optional   | ✅ Optional    | ✅ Optional  |
| Import Dir       | ✅ Optional   | ❌ Required   | ❌ Required    | ✅ Optional  |
| Process Dir      | ✅ Optional   | ✅ Optional   | ❌ Required    | ✅ Optional  |
| Deleted Dir      | ✅ Optional   | ✅ Optional   | ✅ Optional    | ❌ Required  |

### System Readiness States

#### State 1: Full Capability
- ✅ All storage components available
- ✅ All workflows possible
- **Available Options**: Archive, Import, Process, Clean, any combination

#### State 2: Limited Capability  
- ✅ Library root + Archive + Import available
- ❌ Process directory missing
- **Available Options**: Archive, Import, Clean, Archive+Import, Archive+Import+Clean
- **Unavailable**: Process workflows

#### State 3: Archive-Only Capability
- ✅ Library root + Archive available  
- ❌ Import/Process directories missing
- **Available Options**: Archive, Archive+Clean
- **Unavailable**: Import, Process workflows

#### State 4: Import-Only Capability
- ✅ Library root + Import available
- ❌ Archive directory missing
- **Available Options**: Import, Import+Clean
- **Unavailable**: Archive workflows

#### State 5: Minimal Capability
- ✅ Library root only
- ❌ All subdirectories missing
- **Available Options**: None (requires setup)
- **Action Required**: Run `goprox --setup`

## Content Analysis Framework

### Media Content Assessment

#### Content Types Detected
```zsh
# Media file detection
local media_files=$(find "$volume" -type f \( -name "*.MP4" -o -name "*.JPG" -o -name "*.LRV" -o -name "*.THM" \) 2>/dev/null | wc -l | tr -d ' ')
local new_media_count=$(find "$volume" -type f \( -name "*.MP4" -o -name "*.JPG" -o -name "*.LRV" -o -name "*.THM" \) -newermt "$last_archived" 2>/dev/null | wc -l | tr -d ' ')
```

#### Content States

##### State A: New Media Present
- **Condition**: `new_media_count > 0`
- **Requirement**: Processing needed
- **Workflow Options**: Archive, Import, Archive+Import, Archive+Clean, Archive+Import+Clean

##### State B: No New Media
- **Condition**: `new_media_count = 0`
- **Requirement**: No processing needed
- **Workflow Options**: None (skip processing)

##### State C: Never Archived
- **Condition**: No archive marker found
- **Requirement**: Full processing recommended
- **Workflow Options**: Archive+Import+Clean (recommended), Archive+Clean, Import+Clean

##### State D: Previously Processed
- **Condition**: Archive marker exists, no new media
- **Requirement**: Maintenance only
- **Workflow Options**: Clean (if needed), Skip

## Workflow Decision Trees

### Primary Decision Tree

```
System Readiness Assessment
├── State 5: Minimal Capability
│   └── Action: Run goprox --setup
├── State 4: Import-Only Capability  
│   └── Content Analysis
│       ├── New Media Present → Import, Import+Clean
│       └── No New Media → Skip
├── State 3: Archive-Only Capability
│   └── Content Analysis  
│       ├── New Media Present → Archive, Archive+Clean
│       └── No New Media → Skip
├── State 2: Limited Capability
│   └── Content Analysis
│       ├── New Media Present → Archive, Import, Archive+Import, Archive+Clean, Archive+Import+Clean
│       └── No New Media → Skip
└── State 1: Full Capability
    └── Content Analysis
        ├── New Media Present → All workflows available
        └── No New Media → Skip
```

### Content-Based Workflow Selection

#### When New Media is Present

```
New Media Detected
├── Archive + Clean (Recommended)
│   ├── Fastest option
│   ├── Preserves media safely
│   ├── Frees up SD card
│   └── Ready for reuse
├── Archive + Import + Clean
│   ├── Full workflow
│   ├── Media ready for processing
│   ├── Archive backup created
│   └── SD card ready for reuse
├── Archive Only
│   ├── Safe backup
│   ├── SD card unchanged
│   └── Manual cleanup later
├── Import + Clean
│   ├── Media in library
│   ├── No archive backup
│   └── SD card ready for reuse
└── Do Nothing
    ├── No changes made
    ├── Manual processing later
    └── SD card unchanged
```

#### When No New Media is Present

```
No New Media Detected
├── Skip Processing
│   ├── No action needed
│   ├── Cards already processed
│   └── Exit gracefully
├── Clean Only (if requested)
│   ├── Remove old media
│   ├── Prepare for reuse
│   └── Requires confirmation
└── Firmware Updates
    ├── Check for updates
    ├── Offer firmware upgrades
    └── Separate from media processing
```

## Implementation Strategy

### Phase 1: System Readiness Detection

```zsh
function _assess_system_readiness() {
  local capabilities=()
  
  # Check each storage component
  if _test_library_component "library" "${library/#\~/$HOME}"; then
    capabilities+=("library_root")
  fi
  
  if _test_library_component "archive" "${library/#\~/$HOME}/archive"; then
    capabilities+=("archive")
  fi
  
  if _test_library_component "imported" "${library/#\~/$HOME}/imported"; then
    capabilities+=("import")
  fi
  
  if _test_library_component "processed" "${library/#\~/$HOME}/processed"; then
    capabilities+=("process")
  fi
  
  if _test_library_component "deleted" "${library/#\~/$HOME}/deleted"; then
    capabilities+=("clean")
  fi
  
  echo "${capabilities[@]}"
}
```

### Phase 2: Content Analysis

```zsh
function _analyze_content_requirements() {
  local volume="$1"
  local last_archived="$2"
  
  local new_media_count=0
  local total_media_count=0
  
  if [[ -n "$last_archived" ]]; then
    new_media_count=$(find "$volume" -type f \( -name "*.MP4" -o -name "*.JPG" -o -name "*.LRV" -o -name "*.THM" \) -newermt "$last_archived" 2>/dev/null | wc -l | tr -d ' ')
  else
    total_media_count=$(find "$volume" -type f \( -name "*.MP4" -o -name "*.JPG" -o -name "*.LRV" -o -name "*.THM" \) 2>/dev/null | wc -l | tr -d ' ')
    new_media_count=$total_media_count
  fi
  
  echo "new_media:$new_media_count"
}
```

### Phase 3: Workflow Selection

```zsh
function _select_available_workflows() {
  local capabilities="$1"
  local content_state="$2"
  
  local available_workflows=()
  
  case "$content_state" in
    "new_media_present")
      if [[ "$capabilities" == *"archive"* ]]; then
        available_workflows+=("archive")
        available_workflows+=("archive_clean")
      fi
      
      if [[ "$capabilities" == *"import"* ]]; then
        available_workflows+=("import")
        available_workflows+=("import_clean")
      fi
      
      if [[ "$capabilities" == *"archive"* && "$capabilities" == *"import"* ]]; then
        available_workflows+=("archive_import_clean")
      fi
      
      available_workflows+=("skip")
      ;;
      
    "no_new_media")
      available_workflows+=("skip")
      
      if [[ "$capabilities" == *"clean"* ]]; then
        available_workflows+=("clean_only")
      fi
      ;;
  esac
  
  echo "${available_workflows[@]}"
}
```

## User Experience Flow

### Workflow Presentation

```
📸 New Media Detected - Workflow Options
========================================
Found 3 card(s) with 210 total media files:
  • HERO13-0277: 75 files
  • HERO13-3705: 63 files  
  • HERO13-3848: 72 files

Available workflows:
  1. Archive + Clean (recommended)
     - Archive all media to compressed backup
     - Clean SD cards for reuse
     - Fastest option, preserves media

  2. Archive + Import + Clean
     - Archive all media to compressed backup
     - Import media to library for processing
     - Clean SD cards for reuse
     - Full workflow, ready for editing

  3. Do nothing
     - Exit without making changes
     - Cards remain as-is

Select workflow [1/2/3] (default: 1):
```

### Error Handling

#### Storage Validation Failures
```
❌ Storage validation failed
Missing required directories:
  - Archive directory: ~/goprox/archive
  - Import directory: ~/goprox/imported

Run 'goprox --setup' to configure storage
```

#### Content Analysis Failures
```
⚠️  Content analysis warning
Unable to determine last archive time for HERO13-0277
Will process all media files as new content
```

## Success Metrics

- **System Readiness**: 100% accurate capability detection
- **Content Analysis**: 99% accurate media detection
- **Workflow Selection**: Appropriate options for all scenarios
- **User Experience**: Clear, actionable workflow choices
- **Error Recovery**: Graceful handling of all failure modes

## Next Steps

1. **Implement system readiness assessment**
2. **Build content analysis framework**
3. **Create workflow selection logic**
4. **Design user interaction flow**
5. **Add comprehensive error handling**
6. **Test with various storage configurations**
7. **Validate with real media content**

## Related Documentation

- [Enhanced Default Behavior](ISSUE-67-ENHANCED_DEFAULT_BEHAVIOR.md)
- [Design Principles](../../architecture/DESIGN_PRINCIPLES.md)
- [AI Instructions](../../../AI_INSTRUCTIONS.md) 