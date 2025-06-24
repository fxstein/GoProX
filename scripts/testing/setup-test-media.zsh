#!/bin/zsh
# Setup Test Media Files for GoProX
# This script helps organize test media files for comprehensive testing

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h:h}"
TEST_DIR="${PROJECT_ROOT}/test"
ORIGINALS_DIR="${TEST_DIR}/originals"

# GoPro models we support
MODELS=(
    "HERO8"
    "HERO9" 
    "HERO10"
    "HERO11"
    "HERO11_Mini"
    "HERO12"
    "HERO13"
    "HERO_2024"
    "GoPro_Max"
    "The_Remote"
)

# File types and naming patterns
declare -A FILE_PATTERNS
FILE_PATTERNS[HERO8_VIDEO]="GX"
FILE_PATTERNS[HERO8_PHOTO]="GOPR"
FILE_PATTERNS[HERO9_VIDEO]="GX"
FILE_PATTERNS[HERO9_PHOTO]="GOPR"
FILE_PATTERNS[HERO10_VIDEO]="GX"
FILE_PATTERNS[HERO10_PHOTO]="GOPR"
FILE_PATTERNS[HERO11_VIDEO]="GX"
FILE_PATTERNS[HERO11_PHOTO]="GOPR"
FILE_PATTERNS[HERO12_VIDEO]="GX"
FILE_PATTERNS[HERO12_PHOTO]="GOPR"
FILE_PATTERNS[HERO13_VIDEO]="GX"
FILE_PATTERNS[HERO13_PHOTO]="GOPR"
FILE_PATTERNS[HERO_2024_VIDEO]="GX"
FILE_PATTERNS[HERO_2024_PHOTO]="GOPR"
FILE_PATTERNS[GoPro_Max_VIDEO]="GS"
FILE_PATTERNS[GoPro_Max_PHOTO]="GOPR"

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to create directory structure
create_directory_structure() {
    print_status $BLUE "Creating test media directory structure..."
    
    for model in $MODELS; do
        local model_dir="${ORIGINALS_DIR}/${model}"
        mkdir -p "${model_dir}/videos"
        mkdir -p "${model_dir}/photos"
        mkdir -p "${model_dir}/metadata"
        mkdir -p "${model_dir}/raw"
        
        # Create README for each model
        cat > "${model_dir}/README.md" << EOF
# ${model} Test Files

This directory contains test media files from the ${model} camera.

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
EOF
    done
    
    print_status $GREEN "✓ Directory structure created"
}

# Function to generate sample file lists
generate_file_lists() {
    print_status $BLUE "Generating sample file lists..."
    
    local sample_list="${ORIGINALS_DIR}/REQUIRED_SAMPLE_FILES.md"
    
    cat > "$sample_list" << 'EOF'
# Required Sample Files for GoProX Testing

## Overview
This document lists the sample files needed for comprehensive GoProX testing. Each file should be a real GoPro media file with proper metadata.

## File Sources
- GoPro official sample files
- Community-contributed samples
- Camera review/demo files
- Generated test files with proper metadata

## Required Files by Model

### HERO8 Black
- **Videos**: GX#######.MP4 (4K, 2.7K, 1080p)
- **Photos**: GOPR####.JPG (high-res, burst)
- **Metadata**: GL#######.LRV, GX#######.THM

### HERO9 Black  
- **Videos**: GX#######.MP4 (5.3K, 4K, 2.7K, 1080p)
- **Photos**: GOPR####.JPG (high-res, burst)
- **Metadata**: GL#######.LRV, GX#######.THM

### HERO10 Black
- **Videos**: GX#######.MP4 (5.3K, 4K, 2.7K, 1080p)
- **Photos**: GOPR####.JPG (high-res, burst)
- **Metadata**: GL#######.LRV, GX#######.THM

### HERO11 Black
- **Videos**: GX#######.MP4 (5.3K/60fps, 4K/120fps, 2.7K, 1080p)
- **Photos**: GOPR####.JPG (high-res, burst)
- **Metadata**: GL#######.LRV, GX#######.THM

### HERO11 Black Mini
- **Videos**: GX#######.MP4 (4K, 2.7K, 1080p)
- **Photos**: GOPR####.JPG (high-res, burst)
- **Metadata**: GL#######.LRV, GX#######.THM

### HERO12 Black
- **Videos**: GX#######.MP4 (5.3K, 4K, 2.7K, 1080p)
- **Photos**: GOPR####.JPG (high-res, burst)
- **Metadata**: GL#######.LRV, GX#######.THM

### HERO13 Black
- **Videos**: GX#######.MP4 (5.3K, 4K, 2.7K, 1080p)
- **Photos**: GOPR####.JPG (high-res, burst)
- **Metadata**: GL#######.LRV, GX#######.THM

### HERO (2024)
- **Videos**: GX#######.MP4 (4K, 2.7K, 1080p)
- **Photos**: GOPR####.JPG (high-res, burst)
- **Metadata**: GL#######.LRV, GX#######.THM

### GoPro Max
- **Videos**: GS#######.MP4 (360-degree video)
- **Photos**: GOPR####.JPG (360 photos)
- **Metadata**: GL#######.LRV, GS#######.THM

### The Remote
- **Metadata**: Configuration and log files

## File Characteristics to Test

### Video Files
- Different resolutions (1080p, 2.7K, 4K, 5.3K)
- Different frame rates (24fps, 30fps, 60fps, 120fps)
- Different codecs (H.264, H.265/HEVC)
- Different bitrates (Standard, High, Max)
- GPS-enabled videos
- Videos with different stabilization settings

### Photo Files
- Different resolutions (12MP, 20MP, 23MP)
- Burst photo sequences
- Time-lapse photos
- Night photos
- GPS-enabled photos
- Photos with different ProTune settings

### Metadata Files
- LRV files (low resolution video)
- THM files (thumbnail files)
- XMP sidecar files
- GPS data files

## Edge Cases to Test
- Files with missing metadata
- Corrupted files (for error handling)
- Very large files (for performance testing)
- Files with unusual characters in names
- Files from different time zones
- Files with existing processed versions

## Implementation Notes
- Keep individual files under 10MB for CI/CD
- Use sample clips rather than full videos
- Anonymize metadata to protect privacy
- Document source and characteristics
- Maintain proper licensing for test use
EOF
    
    print_status $GREEN "✓ Sample file lists generated"
}

# Function to create placeholder files for testing
create_placeholder_files() {
    print_status $BLUE "Creating placeholder files for testing..."
    
    # Create a simple script to generate test files
    local generator_script="${ORIGINALS_DIR}/generate_test_files.zsh"
    
    cat > "$generator_script" << 'EOF'
#!/bin/zsh
# Generate Test Files for GoProX
# This script creates placeholder files for testing when real files aren't available

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to create a minimal MP4 file
create_test_mp4() {
    local output_file=$1
    local duration=${2:-5}  # Default 5 seconds
    
    print_status $YELLOW "Creating test MP4: $output_file"
    
    # Use ffmpeg to create a minimal test video
    if command -v ffmpeg >/dev/null 2>&1; then
        ffmpeg -f lavfi -i testsrc=duration=${duration}:size=1920x1080:rate=30 \
               -f lavfi -i sine=frequency=1000:duration=${duration} \
               -c:v libx264 -preset ultrafast -crf 23 \
               -c:a aac -b:a 128k \
               -y "$output_file" >/dev/null 2>&1 || {
            print_status $RED "Failed to create MP4 with ffmpeg, creating empty file"
            touch "$output_file"
        }
    else
        print_status $YELLOW "ffmpeg not available, creating empty file"
        touch "$output_file"
    fi
}

# Function to create a minimal JPEG file
create_test_jpg() {
    local output_file=$1
    
    print_status $YELLOW "Creating test JPEG: $output_file"
    
    # Use ImageMagick to create a minimal test image
    if command -v convert >/dev/null 2>&1; then
        convert -size 1920x1080 xc:white -pointsize 72 -fill black \
                -gravity center -annotate +0+0 "Test Image" \
                "$output_file" 2>/dev/null || {
            print_status $RED "Failed to create JPEG with ImageMagick, creating empty file"
            touch "$output_file"
        }
    else
        print_status $YELLOW "ImageMagick not available, creating empty file"
        touch "$output_file"
    fi
}

# Function to create metadata files
create_metadata_files() {
    local base_name=$1
    local model=$2
    local firmware_version=$3
    
    # Create LRV file
    local lrv_file="${base_name}.LRV"
    print_status $YELLOW "Creating LRV file: $lrv_file"
    create_test_mp4 "$lrv_file" 2
    
    # Create THM file
    local thm_file="${base_name}.THM"
    print_status $YELLOW "Creating THM file: $thm_file"
    create_test_jpg "$thm_file"
    
    # Create XMP sidecar
    local xmp_file="${base_name}.xmp"
    print_status $YELLOW "Creating XMP file: $xmp_file"
    cat > "$xmp_file" << INNER_EOF
<?xml version="1.0" encoding="UTF-8"?>
<x:xmpmeta xmlns:x="adobe:ns:meta/">
  <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <rdf:Description rdf:about=""
      xmlns:exif="http://ns.adobe.com/exif/1.0/">
      <exif:Make>GoPro</exif:Make>
      <exif:Model>${model}</exif:Model>
      <exif:Software>${firmware_version}</exif:Software>
    </rdf:Description>
  </rdf:RDF>
</x:xmpmeta>
INNER_EOF
}

# Generate test files for each model
generate_model_files() {
    local model=$1
    local model_dir="$(dirname $0)/${model}"
    
    print_status $BLUE "Generating test files for $model..."
    
    # Create test videos
    create_test_mp4 "${model_dir}/videos/GX010000.MP4"
    create_test_mp4 "${model_dir}/videos/GX010001.MP4"
    create_test_mp4 "${model_dir}/videos/GX010002.MP4"
    
    # Create test photos
    create_test_jpg "${model_dir}/photos/GOPR0001.JPG"
    create_test_jpg "${model_dir}/photos/GOPR0002.JPG"
    create_test_jpg "${model_dir}/photos/GOPR0003.JPG"
    
    # Create metadata files
    create_metadata_files "GL010000" "$model" "H99.01.01.00.00"
    create_metadata_files "GX010000" "$model" "H99.01.01.00.00"
    
    print_status $GREEN "✓ Generated test files for $model"
}

# Main execution
main() {
    print_status $BLUE "Starting test file generation..."
    
    # Models to generate files for
    local models=("HERO8" "HERO9" "HERO10" "HERO11" "HERO11_Mini" "HERO12" "HERO13" "HERO_2024" "GoPro_Max")
    
    for model in $models; do
        if [[ -d "$(dirname $0)/${model}" ]]; then
            generate_model_files "$model"
        else
            print_status $RED "Model directory not found: $model"
        fi
    done
    
    print_status $GREEN "✓ Test file generation complete"
    print_status $YELLOW "Note: These are placeholder files. Replace with real GoPro files for comprehensive testing."
}

main "$@"
EOF
    
    chmod +x "$generator_script"
    print_status $GREEN "✓ Placeholder file generator created"
}

# Function to check for existing test files
check_existing_files() {
    print_status $BLUE "Checking for existing test files..."
    
    local found_files=0
    
    for model in $MODELS; do
        local model_dir="${ORIGINALS_DIR}/${model}"
        if [[ -d "$model_dir" ]]; then
            local video_count=$(find "$model_dir/videos" -name "*.MP4" 2>/dev/null | wc -l)
            local photo_count=$(find "$model_dir/photos" -name "*.JPG" 2>/dev/null | wc -l)
            
            if [[ $video_count -gt 0 || $photo_count -gt 0 ]]; then
                print_status $GREEN "✓ $model: $video_count videos, $photo_count photos"
                ((found_files++))
            else
                print_status $YELLOW "⚠ $model: No media files found"
            fi
        fi
    done
    
    if [[ $found_files -eq 0 ]]; then
        print_status $RED "No test media files found. Run the generator script to create placeholders."
    fi
}

# Function to display usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    --create-dirs     Create directory structure
    --generate-lists  Generate sample file lists
    --create-placeholders  Create placeholder file generator
    --check-files     Check for existing test files
    --all            Run all setup steps
    --help           Show this help

Examples:
    $0 --all                    # Run complete setup
    $0 --create-dirs           # Only create directories
    $0 --check-files           # Check existing files
EOF
}

# Main function
main() {
    case "${1:---all}" in
        --create-dirs)
            create_directory_structure
            ;;
        --generate-lists)
            generate_file_lists
            ;;
        --create-placeholders)
            create_placeholder_files
            ;;
        --check-files)
            check_existing_files
            ;;
        --all)
            create_directory_structure
            generate_file_lists
            create_placeholder_files
            check_existing_files
            ;;
        --help)
            show_usage
            ;;
        *)
            print_status $RED "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
    
    print_status $GREEN "✓ Setup complete!"
    print_status $YELLOW "Next steps:"
    print_status $YELLOW "1. Add real GoPro media files to the model directories"
    print_status $YELLOW "2. Run the placeholder generator if needed: ./generate_test_files.zsh"
    print_status $YELLOW "3. Update test scripts to use the new file structure"
}

main "$@" 