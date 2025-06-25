#!/bin/zsh
# Test File Comparison Framework for GoProX
# Compensates for not committing test/imported and test/processed to git

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
OUTPUT_DIR="${PROJECT_ROOT}/output"

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to extract file metadata for comparison
extract_file_metadata() {
    local file_path="$1"
    local output_file="$2"
    
    if [[ ! -f "$file_path" ]]; then
        return 1
    fi
    
    # Extract basic file info
    local file_info=$(stat -f "%z %m %N" "$file_path" 2>/dev/null || stat -c "%s %Y %n" "$file_path" 2>/dev/null)
    
    # Extract EXIF metadata if available
    local exif_data=""
    if command -v exiftool >/dev/null 2>&1; then
        exif_data=$(exiftool -j "$file_path" 2>/dev/null | head -c 1000)
    fi
    
    # Extract file hash
    local file_hash=$(shasum -a 256 "$file_path" 2>/dev/null | cut -d' ' -f1)
    
    # Write metadata to output file
    cat > "$output_file" << EOF
# File Metadata: $(basename "$file_path")
# Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
# File Path: $file_path

## Basic Info
$file_info

## File Hash (SHA256)
$file_hash

## EXIF Data (if available)
$exif_data

## File Size (bytes)
$(stat -f "%z" "$file_path" 2>/dev/null || stat -c "%s" "$file_path" 2>/dev/null)

## File Permissions
$(ls -la "$file_path" 2>/dev/null | awk '{print $1, $3, $4}')

## Last Modified
$(stat -f "%Sm" "$file_path" 2>/dev/null || stat -c "%y" "$file_path" 2>/dev/null)
EOF
}

# Function to compare file metadata
compare_file_metadata() {
    local file1="$1"
    local file2="$2"
    local diff_output="$3"
    
    if [[ ! -f "$file1" ]] || [[ ! -f "$file2" ]]; then
        return 1
    fi
    
    # Compare file sizes
    local size1=$(stat -f "%z" "$file1" 2>/dev/null || stat -c "%s" "$file1" 2>/dev/null)
    local size2=$(stat -f "%z" "$file2" 2>/dev/null || stat -c "%s" "$file2" 2>/dev/null)
    
    # Compare file hashes
    local hash1=$(shasum -a 256 "$file1" 2>/dev/null | cut -d' ' -f1)
    local hash2=$(shasum -a 256 "$file2" 2>/dev/null | cut -d' ' -f1)
    
    # Write comparison results
    cat > "$diff_output" << EOF
# File Comparison Report
# Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

## File 1: $file1
Size: $size1 bytes
Hash: $hash1

## File 2: $file2
Size: $size2 bytes
Hash: $hash2

## Comparison Results
EOF
    
    if [[ "$size1" == "$size2" ]]; then
        echo "✅ File sizes match: $size1 bytes" >> "$diff_output"
    else
        echo "❌ File sizes differ: $size1 vs $size2 bytes" >> "$diff_output"
    fi
    
    if [[ "$hash1" == "$hash2" ]]; then
        echo "✅ File hashes match: $hash1" >> "$diff_output"
    else
        echo "❌ File hashes differ: $hash1 vs $hash2" >> "$diff_output"
    fi
    
    # Compare EXIF data if available
    if command -v exiftool >/dev/null 2>&1; then
        local exif1=$(exiftool -j "$file1" 2>/dev/null | head -c 500)
        local exif2=$(exiftool -j "$file2" 2>/dev/null | head -c 500)
        
        if [[ "$exif1" == "$exif2" ]]; then
            echo "✅ EXIF data matches" >> "$diff_output"
        else
            echo "❌ EXIF data differs" >> "$diff_output"
            echo "File 1 EXIF: $exif1" >> "$diff_output"
            echo "File 2 EXIF: $exif2" >> "$diff_output"
        fi
    fi
}

# Function to generate directory structure report
generate_structure_report() {
    local dir_path="$1"
    local output_file="$2"
    
    if [[ ! -d "$dir_path" ]]; then
        return 1
    fi
    
    # Generate directory tree with file sizes
    local tree_output=$(find "$dir_path" -type f -exec stat -f "%z %N" {} \; 2>/dev/null | sort)
    
    # Count files by extension
    local extension_counts=$(find "$dir_path" -type f -name "*.*" 2>/dev/null | sed 's/.*\.//' | sort | uniq -c | sort -nr)
    
    # Calculate total size
    local total_size=$(find "$dir_path" -type f -exec stat -f "%z" {} \; 2>/dev/null | awk '{sum += $1} END {print sum}')
    
    cat > "$output_file" << EOF
# Directory Structure Report: $(basename "$dir_path")
# Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
# Path: $dir_path

## File Listing (with sizes)
$tree_output

## File Count by Extension
$extension_counts

## Total Size
$total_size bytes ($(numfmt --to=iec $total_size 2>/dev/null || echo "unknown"))

## Directory Tree
$(find "$dir_path" -type f 2>/dev/null | sed 's|.*/||' | sort)
EOF
}

# Function to compare directory structures
compare_directory_structures() {
    local dir1="$1"
    local dir2="$2"
    local output_file="$3"
    
    local temp1="/tmp/structure1_$$"
    local temp2="/tmp/structure2_$$"
    
    generate_structure_report "$dir1" "$temp1"
    generate_structure_report "$dir2" "$temp2"
    
    cat > "$output_file" << EOF
# Directory Structure Comparison
# Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

## Directory 1: $dir1
$(cat "$temp1")

## Directory 2: $dir2
$(cat "$temp2")

## Differences
$(diff "$temp1" "$temp2" 2>/dev/null || echo "No differences found or comparison failed")
EOF
    
    rm -f "$temp1" "$temp2"
}

# Function to create regression test baseline
create_regression_baseline() {
    local baseline_dir="${OUTPUT_DIR}/regression-baseline"
    local test_run_id=$(date -u +"%Y%m%d_%H%M%S")
    local baseline_path="${baseline_dir}/${test_run_id}"
    
    mkdir -p "$baseline_path"
    
    print_status $BLUE "Creating regression test baseline: $test_run_id"
    
    # Generate metadata for all test files
    if [[ -d "${TEST_DIR}/imported" ]]; then
        mkdir -p "${baseline_path}/imported-metadata"
        find "${TEST_DIR}/imported" -type f -name "*.JPG" -o -name "*.MP4" -o -name "*.LRV" -o -name "*.THM" | while read file; do
            local filename=$(basename "$file")
            extract_file_metadata "$file" "${baseline_path}/imported-metadata/${filename}.meta"
        done
    fi
    
    if [[ -d "${TEST_DIR}/processed" ]]; then
        mkdir -p "${baseline_path}/processed-metadata"
        find "${TEST_DIR}/processed" -type f -name "*.jpg" -o -name "*.mp4" | while read file; do
            local filename=$(basename "$file")
            extract_file_metadata "$file" "${baseline_path}/processed-metadata/${filename}.meta"
        done
    fi
    
    # Generate structure reports
    if [[ -d "${TEST_DIR}/imported" ]]; then
        generate_structure_report "${TEST_DIR}/imported" "${baseline_path}/imported-structure.txt"
    fi
    
    if [[ -d "${TEST_DIR}/processed" ]]; then
        generate_structure_report "${TEST_DIR}/processed" "${baseline_path}/processed-structure.txt"
    fi
    
    # Create baseline info
    cat > "${baseline_path}/baseline-info.txt" << EOF
# Regression Test Baseline
# Created: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
# Test Run ID: $test_run_id
# GoProX Version: $(./goprox --version 2>/dev/null || echo "unknown")
# System: $(uname -a)

## Test Configuration
- Original files: ${TEST_DIR}/originals
- Imported files: ${TEST_DIR}/imported
- Processed files: ${TEST_DIR}/processed

## File Counts
- Original files: $(find "${TEST_DIR}/originals" -type f -name "*.JPG" -o -name "*.MP4" -o -name "*.LRV" -o -name "*.THM" 2>/dev/null | wc -l)
- Imported files: $(find "${TEST_DIR}/imported" -type f 2>/dev/null | wc -l)
- Processed files: $(find "${TEST_DIR}/processed" -type f 2>/dev/null | wc -l)
EOF
    
    print_status $GREEN "✓ Baseline created: $baseline_path"
    echo "$baseline_path"
}

# Function to run regression test against baseline
run_regression_test() {
    local baseline_path="$1"
    local test_run_id=$(date -u +"%Y%m%d_%H%M%S")
    local results_path="${OUTPUT_DIR}/regression-results/${test_run_id}"
    
    mkdir -p "$results_path"
    
    print_status $BLUE "Running regression test against baseline: $(basename "$baseline_path")"
    
    # Run GoProX test
    ./goprox --test > "${results_path}/test-output.log" 2>&1
    
    # Generate current metadata
    local current_metadata="${results_path}/current-metadata"
    mkdir -p "$current_metadata"
    
    if [[ -d "${TEST_DIR}/imported" ]]; then
        mkdir -p "${current_metadata}/imported"
        find "${TEST_DIR}/imported" -type f -name "*.JPG" -o -name "*.MP4" -o -name "*.LRV" -o -name "*.THM" | while read file; do
            local filename=$(basename "$file")
            extract_file_metadata "$file" "${current_metadata}/imported/${filename}.meta"
        done
    fi
    
    if [[ -d "${TEST_DIR}/processed" ]]; then
        mkdir -p "${current_metadata}/processed"
        find "${TEST_DIR}/processed" -type f -name "*.jpg" -o -name "*.mp4" | while read file; do
            local filename=$(basename "$file")
            extract_file_metadata "$file" "${current_metadata}/processed/${filename}.meta"
        done
    fi
    
    # Compare with baseline
    local comparison_report="${results_path}/comparison-report.txt"
    cat > "$comparison_report" << EOF
# Regression Test Comparison Report
# Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
# Test Run ID: $test_run_id
# Baseline: $(basename "$baseline_path")

## Test Results Summary
$(grep -E "(PASS|FAIL|ERROR)" "${results_path}/test-output.log" || echo "No test results found")

## File Count Comparison
EOF
    
    # Compare file counts
    local baseline_imported_count=$(find "${baseline_path}/imported-metadata" -name "*.meta" 2>/dev/null | wc -l)
    local current_imported_count=$(find "${current_metadata}/imported" -name "*.meta" 2>/dev/null | wc -l)
    local baseline_processed_count=$(find "${baseline_path}/processed-metadata" -name "*.meta" 2>/dev/null | wc -l)
    local current_processed_count=$(find "${current_metadata}/processed" -name "*.meta" 2>/dev/null | wc -l)
    
    echo "Imported files: Baseline=$baseline_imported_count, Current=$current_imported_count" >> "$comparison_report"
    echo "Processed files: Baseline=$baseline_processed_count, Current=$current_processed_count" >> "$comparison_report"
    
    # Detailed file comparisons
    echo "" >> "$comparison_report"
    echo "## Detailed File Comparisons" >> "$comparison_report"
    
    # Compare imported files
    if [[ -d "${baseline_path}/imported-metadata" ]] && [[ -d "${current_metadata}/imported" ]]; then
        for baseline_file in "${baseline_path}/imported-metadata"/*.meta; do
            if [[ -f "$baseline_file" ]]; then
                local filename=$(basename "$baseline_file" .meta)
                local current_file="${current_metadata}/imported/${filename}.meta"
                
                if [[ -f "$current_file" ]]; then
                    local diff_output="${results_path}/diff_${filename}.txt"
                    compare_file_metadata "$baseline_file" "$current_file" "$diff_output"
                    echo "✅ $filename: Metadata compared" >> "$comparison_report"
                else
                    echo "❌ $filename: Missing in current run" >> "$comparison_report"
                fi
            fi
        done
    fi
    
    print_status $GREEN "✓ Regression test completed: $results_path"
    echo "$results_path"
}

# Function to display usage
show_usage() {
    cat << EOF
Usage: $0 [COMMAND] [OPTIONS]

Commands:
    baseline              Create a new regression test baseline
    test <baseline>       Run regression test against specified baseline
    compare <file1> <file2>  Compare two files
    structure <dir1> <dir2>   Compare directory structures
    metadata <file>       Extract metadata from a file

Options:
    --help               Show this help

Examples:
    $0 baseline                    # Create new baseline
    $0 test /path/to/baseline     # Run regression test
    $0 compare file1.jpg file2.jpg # Compare two files
    $0 structure dir1 dir2         # Compare directories
    $0 metadata test.jpg           # Extract metadata
EOF
}

# Main function
main() {
    case "${1:-help}" in
        baseline)
            create_regression_baseline
            ;;
        test)
            if [[ -z "$2" ]]; then
                print_status $RED "Error: Baseline path required"
                show_usage
                exit 1
            fi
            run_regression_test "$2"
            ;;
        compare)
            if [[ -z "$2" ]] || [[ -z "$3" ]]; then
                print_status $RED "Error: Two file paths required"
                show_usage
                exit 1
            fi
            local diff_output="/tmp/file_comparison_$$.txt"
            compare_file_metadata "$2" "$3" "$diff_output"
            cat "$diff_output"
            rm -f "$diff_output"
            ;;
        structure)
            if [[ -z "$2" ]] || [[ -z "$3" ]]; then
                print_status $RED "Error: Two directory paths required"
                show_usage
                exit 1
            fi
            local diff_output="/tmp/structure_comparison_$$.txt"
            compare_directory_structures "$2" "$3" "$diff_output"
            cat "$diff_output"
            rm -f "$diff_output"
            ;;
        metadata)
            if [[ -z "$2" ]]; then
                print_status $RED "Error: File path required"
                show_usage
                exit 1
            fi
            extract_file_metadata "$2" "/tmp/metadata_$$.txt"
            cat "/tmp/metadata_$$.txt"
            rm -f "/tmp/metadata_$$.txt"
            ;;
        help|--help)
            show_usage
            ;;
        *)
            print_status $RED "Unknown command: $1"
            show_usage
            exit 1
            ;;
    esac
}

main "$@" 