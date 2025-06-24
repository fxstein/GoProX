# Test Media Files Requirements

## Overview
The GoProX processing tests require real media files from different GoPro camera models to be meaningful. Currently, the test suite lacks diverse media files, making it impossible to properly test the core functionality.

## Required Media Files

### GoPro Models to Cover
Based on the firmware directory structure, we need test files from:

1. **HERO8 Black** - Older model with different file naming
2. **HERO9 Black** - Transitional model
3. **HERO10 Black** - 5.3K video capability
4. **HERO11 Black** - 5.3K/60fps, 4K/120fps
5. **HERO11 Black Mini** - Compact version
6. **HERO12 Black** - Latest standard model
7. **HERO13 Black** - Latest model
8. **HERO (2024)** - New entry-level model
9. **GoPro Max** - 360-degree camera
10. **The Remote** - Accessory device

### File Types Needed

#### Video Files
- **MP4 files** with different resolutions:
  - 4K (3840x2160)
  - 5.3K (5312x2988)
  - 2.7K (2704x1520)
  - 1080p (1920x1080)
- **Different frame rates**: 24fps, 30fps, 60fps, 120fps
- **Different codecs**: H.264, H.265/HEVC
- **Different bitrates**: Standard, High, Max

#### Photo Files
- **JPEG files** with different resolutions
- **RAW files** (if supported by model)
- **Burst photos** (multiple files with sequence numbers)

#### Metadata Files
- **LRV files** (low resolution video)
- **THM files** (thumbnail files)
- **XMP sidecar files** (metadata)
- **GPS data files** (if applicable)

### File Naming Patterns
Each model uses different naming conventions:

- **HERO8**: `GX` prefix for video, `GP` for photos
- **HERO9**: `GX` prefix for video, `GP` for photos
- **HERO10**: `GX` prefix for video, `GP` for photos
- **HERO11**: `GX` prefix for video, `GP` for photos
- **HERO12**: `GX` prefix for video, `GP` for photos
- **HERO13**: `GX` prefix for video, `GP` for photos
- **GoPro Max**: `GS` prefix for 360 video, `GP` for photos

### Test Scenarios

#### Basic Processing
- Single video file processing
- Single photo file processing
- Batch processing of multiple files

#### Edge Cases
- Files with missing metadata
- Corrupted files (for error handling)
- Very large files (for performance testing)
- Files with unusual characters in names
- Files from different time zones

#### Integration Scenarios
- Mixed file types from same camera
- Files from multiple cameras in same directory
- Nested directory structures
- Files with existing processed versions

## Implementation Plan

### Phase 1: Source Files
1. **Identify sources** for test media files:
   - Public sample files from GoPro
   - Community-contributed samples
   - Generated test files with proper metadata
   - Sample files from camera reviews/demos

2. **File size considerations**:
   - Keep files small for CI/CD (under 10MB each)
   - Use compressed versions where possible
   - Consider using sample clips rather than full videos

### Phase 2: Organization
1. **Directory structure**:
   ```
   test/originals/
   ├── HERO8/
   │   ├── videos/
   │   ├── photos/
   │   └── metadata/
   ├── HERO9/
   ├── HERO10/
   ├── HERO11/
   ├── HERO11_Mini/
   ├── HERO12/
   ├── HERO13/
   ├── HERO_2024/
   ├── GoPro_Max/
   └── The_Remote/
   ```

2. **Naming convention**:
   - Use descriptive names: `HERO10_4K_30fps_sample.mp4`
   - Include metadata in filename where helpful

### Phase 3: Test Integration
1. **Update test scripts** to use new file structure
2. **Add metadata validation** tests
3. **Create performance benchmarks** with real files
4. **Add regression tests** for specific file types

## Current Status
- ❌ No real media files from GoPro cameras
- ❌ No diverse file types
- ❌ No metadata-rich files for testing
- ❌ No edge case files

## Next Steps
1. Research and collect sample files from each supported model
2. Organize files into structured test directories
3. Update test scripts to use real files
4. Add comprehensive test coverage for all file types

## Notes
- Ensure all test files are properly licensed for testing use
- Consider using anonymized metadata to protect privacy
- Document the source and characteristics of each test file
- Maintain a balance between comprehensive coverage and repository size 