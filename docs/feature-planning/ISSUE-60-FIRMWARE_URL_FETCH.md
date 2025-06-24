# Issue #60: Firmware URL-Based Fetch

**Issue Title**: Feature: Redesign firmware processing to use URL-based fetch and local cache  
**Status**: Open  
**Assignee**: fxstein  
**Labels**: enhancement

## Overview

Redesign the firmware processing logic in GoProX to remove all firmware zip files from the repository. Instead, use the URLs provided in the existing shortcut files to fetch the required firmware file directly from the internet when needed, storing it in a local cache directory.

## Current State Analysis

### Existing Capabilities
- Firmware files stored in repository
- Firmware tree structure
- Basic firmware management
- Download URL files

### Current Limitations
- Large repository size due to firmware files
- Manual firmware management
- No caching mechanism
- Inefficient storage usage

## Implementation Strategy

### Phase 1: Cache System Implementation (High Priority)
**Estimated Effort**: 3-4 days

#### 1.1 Cache Directory Structure
```zsh
# Cache structure
~/.goprox/cache/
├── firmware/
│   ├── official/
│   │   ├── H22.01.02.32.00.zip
│   │   └── H21.01.01.62.00.zip
│   └── labs/
│       ├── H22.01.02.32.70.zip
│       └── H21.01.01.62.70.zip
├── metadata/
│   ├── cache-index.json
│   └── download-logs/
└── temp/
    └── downloads/
```

#### 1.2 Cache Management Script
```zsh
# Cache management functionality
scripts/firmware/cache-manager.zsh
```
- Download firmware from URLs
- Store in local cache
- Validate downloaded files
- Manage cache lifecycle

### Phase 2: URL-Based Fetch Integration (High Priority)
**Estimated Effort**: 2-3 days

#### 2.1 Fetch Logic Implementation
```zsh
# Enhanced firmware processing
scripts/firmware/fetch-firmware.zsh
```
- Read URL from download.url files
- Check cache for existing firmware
- Download if not cached
- Validate download integrity

#### 2.2 Integration with Existing Workflow
```zsh
# Updated firmware commands
goprox --firmware --cache-status
goprox --firmware --clear-cache
goprox --firmware --download-all
```

### Phase 3: Cache Management Features (Medium Priority)
**Estimated Effort**: 2-3 days

#### 3.1 Cache Operations
```zsh
# Cache management commands
goprox --cache --status
goprox --cache --clear
goprox --cache --cleanup
goprox --cache --download-missing
```

#### 3.2 Cache Optimization
- Automatic cleanup of old firmware
- Size-based cache limits
- Usage-based retention policies

## Technical Design

### Cache Index Structure
```json
{
  "cache_version": "1.0",
  "last_updated": "2024-01-15T10:30:00Z",
  "firmware": {
    "H22.01.02.32.00": {
      "type": "official",
      "model": "HERO11 Black",
      "url": "https://device-firmware.gopro.com/v/H22.01.02.32.00/UPDATE.zip",
      "local_path": "~/.goprox/cache/firmware/official/H22.01.02.32.00.zip",
      "size": 52428800,
      "checksum": "sha256:abc123...",
      "download_date": "2024-01-15T10:30:00Z",
      "last_used": "2024-01-15T14:22:00Z"
    }
  }
}
```

### Download Process
```zsh
# Download workflow
1. Check if firmware exists in cache
2. If not cached, read URL from download.url
3. Download firmware to temp directory
4. Validate download integrity
5. Move to cache directory
6. Update cache index
7. Clean up temp files
```

### Error Handling
```zsh
# Error scenarios
- Network connectivity issues
- Invalid or expired URLs
- Download corruption
- Cache directory issues
- Permission problems
```

## Integration Points

### Existing Firmware System
- Integrate with current firmware scripts
- Maintain backward compatibility
- Update firmware tree structure

### Main goprox Script
- Add cache management commands
- Integrate with firmware operations
- Provide user feedback

### Repository Structure
- Remove firmware zip files
- Keep download.url files
- Update documentation

## Success Metrics

- **Repository Size**: 90% reduction in size
- **Performance**: <30 second firmware download
- **Reliability**: 99% successful downloads
- **User Experience**: Seamless integration

## Dependencies

- Existing firmware tree structure
- Download URL files
- Network connectivity
- Local storage space

## Risk Assessment

### Low Risk
- Non-breaking changes
- Reversible implementation
- Based on existing URL files

### Medium Risk
- Network dependency
- Cache management complexity
- User experience changes

### High Risk
- URL expiration or changes
- Network connectivity issues
- Cache corruption

### Mitigation Strategies
- Robust error handling
- Fallback mechanisms
- Cache validation
- User notifications

## Testing Strategy

### Unit Testing
```zsh
# Test individual components
scripts/test/test-cache-system.zsh
```
- Test cache operations
- Validate download logic
- Check error handling

### Integration Testing
```zsh
# Test full workflow
scripts/test/test-firmware-workflow.zsh
```
- Test complete firmware process
- Validate cache integration
- Check performance

### Network Testing
- Test with various network conditions
- Validate timeout handling
- Check retry mechanisms

## Example Usage

```zsh
# Basic firmware update with caching
goprox --firmware

# Check cache status
goprox --cache --status

# Clear cache
goprox --cache --clear

# Download all firmware
goprox --cache --download-all

# Firmware update with cache check
goprox --firmware --check-cache
```

## Next Steps

1. **Immediate**: Implement cache system
2. **Week 1**: Add URL-based fetch logic
3. **Week 2**: Integrate with existing workflow
4. **Week 3**: Add cache management features
5. **Week 4**: Testing and optimization

## Related Issues

- #64: Exclude firmware zip files (enables this)
- #65: Firmware automation (complements this)
- #66: Repository cleanup (organization)
- #67: Enhanced default behavior (integration) 