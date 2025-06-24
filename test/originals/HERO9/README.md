# HERO9 Test Files

This directory contains test media files from the HERO9 camera.

## File Types
- **videos/**: MP4 video files (GX prefix for standard models, GS for Max)
- **photos/**: JPEG photo files (GOPR prefix)
- **metadata/**: LRV, THM, and XMP sidecar files
- **raw/**: RAW photo files (if supported)

## Naming Conventions
- Video files: GX#######.MP4 (or GS for Max)
- Photo files: GOPR####.JPG
- LRV files: GL#######.LRV
- THM files: GX#######.THM

## Required Test Files
- [ ] 4K video sample
- [ ] 5.3K video sample (if supported)
- [ ] 2.7K video sample
- [ ] 1080p video sample
- [ ] High-resolution photo
- [ ] Burst photo sequence
- [ ] LRV file
- [ ] THM file
- [ ] XMP sidecar file
- [ ] GPS-enabled file

## Notes
- Keep files under 10MB for CI/CD compatibility
- Use sample clips rather than full videos
- Ensure metadata is anonymized for privacy
- Document source and characteristics
