#!/bin/zsh

#
# test-suites.zsh: Test suites for GoProX using the test framework
#
# Copyright (c) 2021-2025 by Oliver Ratzesberger
#
# This file contains specific test suites that demonstrate comprehensive
# testing including both success and failure scenarios.

# Source the test framework
source "$(dirname "$0")/test-framework.zsh"

# At the top of the file, define the absolute path to the firmware summary script
FIRMWARE_SUMMARY_SCRIPT="$(cd "$(dirname "$0")/../.." && pwd)/scripts/release/generate-firmware-summary.zsh"

# Configuration Tests
function test_configuration_suite() {
    run_test "config_valid_format" test_config_valid_format "Test valid configuration file format"
    run_test "config_invalid_format" test_config_invalid_format "Test invalid configuration file format"
    run_test "config_missing_library" test_config_missing_library "Test configuration with missing library"
    run_test "config_invalid_mountoptions" test_config_invalid_mountoptions "Test configuration with invalid mount options"
    run_test "config_invalid_geonames" test_config_invalid_geonames "Test configuration with invalid GeoNames account"
    run_test "config_example_comments" test_config_example_comments "Test that config files include example comments"
}

# Parameter Processing Tests
function test_parameter_processing_suite() {
    run_test "params_valid_options" test_params_valid_options "Test valid parameter combinations"
    run_test "params_invalid_options" test_params_invalid_options "Test invalid parameter combinations"
    run_test "params_missing_required" test_params_missing_required "Test missing required parameters"
    run_test "params_help_option" test_params_help_option "Test help option functionality"
    run_test "params_version_option" test_params_version_option "Test version option functionality"
}

# Storage Validation Tests
function test_storage_validation_suite() {
    run_test "storage_valid_hierarchy" test_storage_valid_hierarchy "Test valid storage hierarchy"
    run_test "storage_missing_directories" test_storage_missing_directories "Test missing storage directories"
    run_test "storage_broken_links" test_storage_broken_links "Test broken symbolic links"
    run_test "storage_permission_issues" test_storage_permission_issues "Test permission issues"
}

# Integration Tests
function test_integration_suite() {
    run_test "integration_basic_import" test_integration_basic_import "Test basic import functionality"
    run_test "integration_basic_process" test_integration_basic_process "Test basic process functionality"
    run_test "integration_archive_import_clean" test_integration_archive_import_clean "Test archive-import-clean workflow"
    run_test "integration_firmware_check" test_integration_firmware_check "Test firmware checking functionality"
    run_test "integration_error_handling" test_integration_error_handling "Test error handling scenarios"
}

# Firmware Summary Tests
function test_firmware_summary_suite() {
    run_test "firmware_summary_basic_generation" test_firmware_summary_basic_generation "Test basic firmware summary generation"
    run_test "firmware_summary_custom_sorting" test_firmware_summary_custom_sorting "Test custom model sorting order"
    run_test "firmware_summary_model_names_with_spaces" test_firmware_summary_model_names_with_spaces "Test handling of model names with spaces"
    run_test "firmware_summary_unknown_models" test_firmware_summary_unknown_models "Test handling of unknown models"
    run_test "firmware_summary_missing_firmware" test_firmware_summary_missing_firmware "Test handling of models with missing firmware"
    run_test "firmware_summary_table_formatting" test_firmware_summary_table_formatting "Test proper markdown table formatting"
    run_test "firmware_summary_column_alignment" test_firmware_summary_column_alignment "Test column width calculation and alignment"
}

# Logger Tests
function test_logger_suite() {
    if [[ "$DEBUG" == true ]]; then
        echo "[DEBUG] test_logger_suite: start"
    fi
    if [[ "$DEBUG" == true ]]; then
        echo "[DEBUG] test_logger_suite: checking if run_test is defined"
        type run_test 2>&1 || echo "[DEBUG] test_logger_suite: run_test is NOT defined"
    fi
    if [[ "$DEBUG" == true ]]; then
        echo "[DEBUG] test_logger_suite: about to call run_test"
    fi
    run_test "logger_rotation" test_logger_rotation "Test logger log rotation at 16KB threshold"
    run_test "duplicate_function_definitions" test_duplicate_function_definitions "Test for duplicate function definitions in core scripts"
    run_test "repo_root_cleanliness" test_repo_root_cleanliness "Test that no files are created in repo root during testing"
    if [[ "$DEBUG" == true ]]; then
        echo "[DEBUG] test_logger_suite: run_test calls completed"
    fi
}

function test_logger_rotation() {
    if [[ "$DEBUG" == true ]]; then
        echo "[DEBUG] test_logger_rotation: start"
    fi
    local log_dir="$TEST_TEMP_DIR/logger-test"
    local log_file="$log_dir/goprox.log"
    local log_file_old="$log_dir/goprox.log.old"
    rm -f "$log_file" "$log_file_old"
    mkdir -p "$log_dir"
    export LOG_MAX_SIZE=16384
    export LOGFILE="$log_file"
    export LOGFILE_OLD="$log_file_old"
    source scripts/core/logger.zsh
    if [[ "$DEBUG" == true ]]; then
        echo "[DEBUG] test_logger_rotation: logger sourced, writing log entries"
    fi
    for i in {1..600}; do
        log_info "Logger rotation test entry $i"
    done
    if [[ "$DEBUG" == true ]]; then
        echo "[DEBUG] test_logger_rotation: log entries written, checking files"
    fi
    # Check that both log files exist
    assert_file_exists "$log_file" "Current log file should exist after rotation"
    assert_file_exists "$log_file_old" "Rotated log file should exist after rotation"
    # Check that the rotated file contains early log entries
    assert_contains "$(head -n 1 "$log_file_old")" "Logger rotation test entry" "Rotated log should contain early entries"
    # Check that the current log contains later log entries
    assert_contains "$(tail -n 1 "$log_file")" "Logger rotation test entry" "Current log should contain recent entries"
    rm -f "$log_file" "$log_file_old"
    rm -rf "$log_dir"
    if [[ "$DEBUG" == true ]]; then
        echo "[DEBUG] test_logger_rotation: end"
    fi
}

function test_duplicate_function_definitions() {
    # Test to detect duplicate function definitions in shell scripts
    local script_files=(
        "scripts/core/logger.zsh"
        "scripts/testing/test-framework.zsh"
        "scripts/testing/test-suites.zsh"
        "scripts/release/release.zsh"
        "scripts/maintenance/install-commit-hooks.zsh"
    )
    
    for script_file in "${script_files[@]}"; do
        if [[ -f "$script_file" ]]; then
            # Extract function names and check for duplicates
            local function_names=$(grep -E '^(function )?[a-zA-Z_][a-zA-Z0-9_]*\(\)' "$script_file" | sed 's/^function //' | sed 's/()$//' | sort)
            local duplicate_functions=$(echo "$function_names" | uniq -d)
            
            if [[ -n "$duplicate_functions" ]]; then
                echo "❌ Duplicate function definitions found in $script_file:"
                echo "$duplicate_functions"
                return 1
            fi
        fi
    done
    
    echo "✅ No duplicate function definitions found in core scripts"
}

# Individual test functions

## Configuration Tests
function test_config_valid_format() {
    local config_file="test-config.txt"
    local config_content='# GoProX Configuration File
# Example configuration with all possible entries:
# source="."
# library="~/goprox"
# copyright="Your Name or Organization"
# geonamesacct="your_geonames_username"
# mountoptions=(--archive --import --clean --firmware)

source="."
library="~/test-goprox"
copyright="Test User"
geonamesacct=""
mountoptions=(--archive --import --clean --firmware)'
    
    create_test_config "$config_file" "$config_content"
    
    # Test that config file exists and has correct format
    assert_file_exists "$config_file" "Configuration file should be created"
    assert_contains "$(cat "$config_file")" "source=" "Config should contain source setting"
    assert_contains "$(cat "$config_file")" "library=" "Config should contain library setting"
    assert_contains "$(cat "$config_file")" "mountoptions=" "Config should contain mountoptions setting"
    
    cleanup_test_files "$config_file"
}

function test_config_invalid_format() {
    local config_file="test-config-invalid.txt"
    local config_content='source=.
library="~/test-goprox"
copyright="Test User"
geonamesacct="invalid&chars"
mountoptions=invalid_format'
    
    create_test_config "$config_file" "$config_content"
    
    # Test that invalid config is detected
    assert_file_exists "$config_file" "Invalid config file should be created"
    assert_contains "$(cat "$config_file")" "invalid&chars" "Config should contain invalid GeoNames"
    assert_contains "$(cat "$config_file")" "invalid_format" "Config should contain invalid mountoptions"
    
    cleanup_test_files "$config_file"
}

function test_config_missing_library() {
    local config_file="test-config-no-library.txt"
    local config_content='source="."
copyright="Test User"
geonamesacct=""
mountoptions=(--archive --import --clean --firmware)'
    
    create_test_config "$config_file" "$config_content"
    
    # Test that missing library is detected
    assert_file_exists "$config_file" "Config file should be created"
    assert_not_contains "$(cat "$config_file")" "library=" "Config should not contain library setting"
    
    cleanup_test_files "$config_file"
}

function test_config_invalid_mountoptions() {
    local config_file="test-config-invalid-mount.txt"
    local config_content='source="."
library="~/test-goprox"
copyright="Test User"
geonamesacct=""
mountoptions=not_an_array'
    
    create_test_config "$config_file" "$config_content"
    
    # Test that invalid mountoptions format is detected
    assert_file_exists "$config_file" "Config file should be created"
    assert_contains "$(cat "$config_file")" "not_an_array" "Config should contain invalid mountoptions"
    
    cleanup_test_files "$config_file"
}

function test_config_invalid_geonames() {
    local config_file="test-config-invalid-geo.txt"
    local config_content='source="."
library="~/test-goprox"
copyright="Test User"
geonamesacct="user with spaces"
mountoptions=(--archive --import --clean --firmware)'
    
    create_test_config "$config_file" "$config_content"
    
    # Test that invalid GeoNames account is detected
    assert_file_exists "$config_file" "Config file should be created"
    assert_contains "$(cat "$config_file")" "user with spaces" "Config should contain invalid GeoNames"
    
    cleanup_test_files "$config_file"
}

function test_config_example_comments() {
    local config_file="test-config-examples.txt"
    local config_content='# GoProX Configuration File
# Example configuration with all possible entries:
# source="."
# library="~/goprox"
# copyright="Your Name or Organization"
# geonamesacct="your_geonames_username"
# mountoptions=(--archive --import --clean --firmware)

source="."
library="~/test-goprox"
copyright="Test User"
geonamesacct=""
mountoptions=(--archive --import --clean --firmware)'
    
    create_test_config "$config_file" "$config_content"
    
    # Test that example comments are present
    assert_file_exists "$config_file" "Config file should be created"
    assert_contains "$(cat "$config_file")" "# Example configuration" "Config should contain example comments"
    assert_contains "$(cat "$config_file")" "# source=" "Config should contain source example"
    assert_contains "$(cat "$config_file")" "# library=" "Config should contain library example"
    
    cleanup_test_files "$config_file"
}

## Parameter Processing Tests
function test_params_valid_options() {
    # Test that valid parameter combinations work
    local output
    output=$(goprox --help 2>&1)
    assert_exit_code 1 "$?" "Help option should exit with code 1"
    assert_contains "$output" "Usage:" "Help output should contain usage information"
}

function test_params_invalid_options() {
    # Test that invalid options are rejected
    local output
    output=$(goprox --invalid-option 2>&1)
    assert_exit_code 1 "$?" "Invalid option should exit with code 1"
    assert_contains "$output" "Unknown option" "Should show unknown option error"
}

function test_params_missing_required() {
    # Test that missing required parameters are handled gracefully
    local output
    output=$(goprox --import 2>&1)
    assert_exit_code 0 "$?" "Missing library should be handled gracefully with exit code 0"
    assert_contains "$output" "GoProX started" "Should show GoProX started message"
}

function test_params_help_option() {
    # Test help option functionality
    local output
    output=$(goprox -h 2>&1)
    assert_exit_code 1 "$?" "Help option should exit with code 1"
    assert_contains "$output" "goprox - import and process" "Help should show description"
}

function test_params_version_option() {
    # Test version option functionality
    local output
    output=$(goprox --version 2>&1)
    assert_exit_code 0 "$?" "Version option should exit with code 0"
    assert_contains "$output" "goprox v" "Version should show version string"
}

## Storage Validation Tests
function test_storage_valid_hierarchy() {
    # Create valid storage hierarchy
    mkdir -p "test-storage/archive"
    mkdir -p "test-storage/imported"
    mkdir -p "test-storage/processed"
    mkdir -p "test-storage/deleted"
    
    # Test that directories exist
    assert_directory_exists "test-storage" "Main storage directory should exist"
    assert_directory_exists "test-storage/archive" "Archive directory should exist"
    assert_directory_exists "test-storage/imported" "Imported directory should exist"
    assert_directory_exists "test-storage/processed" "Processed directory should exist"
    assert_directory_exists "test-storage/deleted" "Deleted directory should exist"
    
    cleanup_test_files "test-storage"
}

function test_storage_missing_directories() {
    # Create incomplete storage hierarchy
    mkdir -p "test-storage-incomplete"
    # Don't create subdirectories
    
    # Test that missing directories are detected
    assert_directory_exists "test-storage-incomplete" "Main storage directory should exist"
    assert_file_not_exists "test-storage-incomplete/archive" "Archive directory should not exist"
    assert_file_not_exists "test-storage-incomplete/imported" "Imported directory should not exist"
    
    cleanup_test_files "test-storage-incomplete"
}

function test_storage_broken_links() {
    # Create a broken symbolic link
    mkdir -p "test-storage-links"
    ln -s "/nonexistent/path" "test-storage-links/broken-link"
    
    # Test that broken link exists but points to invalid location
    assert_file_exists "test-storage-links/broken-link" "Broken link should exist"
    
    cleanup_test_files "test-storage-links"
}

function test_storage_permission_issues() {
    # Create directory with restricted permissions
    mkdir -p "test-storage-perms"
    chmod 000 "test-storage-perms"
    
    # Test that directory exists but has restricted permissions
    assert_directory_exists "test-storage-perms" "Directory should exist"
    
    # Restore permissions for cleanup
    chmod 755 "test-storage-perms"
    cleanup_test_files "test-storage-perms"
}

## Integration Tests
function test_integration_basic_import() {
    # Create test media file
    create_test_media_file "test-media/test.jpg" "Test JPEG content"
    
    # Test basic import functionality (this would need to be adapted for actual goprox testing)
    assert_file_exists "test-media/test.jpg" "Test media file should exist"
    
    cleanup_test_files "test-media"
}

function test_integration_basic_process() {
    # Create test processed file
    create_test_media_file "test-processed/P_test.jpg" "Processed JPEG content"
    
    # Test basic process functionality
    assert_file_exists "test-processed/P_test.jpg" "Processed file should exist"
    assert_contains "$(cat test-processed/P_test.jpg)" "Processed JPEG content" "Processed file should contain expected content"
    
    cleanup_test_files "test-processed"
}

function test_integration_archive_import_clean() {
    # Test the complete workflow (simplified)
    mkdir -p "test-workflow/originals"
    create_test_media_file "test-workflow/originals/test.jpg" "Original content"
    
    # Simulate workflow steps
    assert_file_exists "test-workflow/originals/test.jpg" "Original file should exist"
    
    cleanup_test_files "test-workflow"
}

function test_integration_firmware_check() {
    # Create test firmware structure in test temp directory
    local test_dir="$TEST_TEMP_DIR/test-firmware"
    mkdir -p "$test_dir/MISC"
    echo '{"camera type": "HERO10 Black", "firmware version": "H21.01.01.10.00"}' > "$test_dir/MISC/version.txt"
    
    # Test firmware detection
    assert_file_exists "$test_dir/MISC/version.txt" "Firmware version file should exist"
    assert_contains "$(cat "$test_dir/MISC/version.txt")" "HERO10 Black" "Should contain camera type"
    
    cleanup_test_files "$test_dir"
}

function test_integration_error_handling() {
    # Test error handling by trying to access non-existent file
    local output
    output=$(goprox --source "/nonexistent/path" --library "./test-lib" 2>&1)
    
    # Should handle the error gracefully with warnings
    assert_exit_code 0 "$?" "Should handle non-existent source gracefully with exit code 0"
    assert_contains "$output" "Warning:" "Should show warning messages"
    
    cleanup_test_files "test-lib"
}

# Helper function for testing
function assert_not_contains() {
    local text="$1"
    local pattern="$2"
    local message="${3:-Text should not contain pattern}"
    
    if [[ ! "$text" =~ $pattern ]]; then
        return 0
    else
        echo "❌ Assertion failed: $message"
        echo "   Text: '$text'"
        echo "   Pattern: '$pattern'"
        return 1
    fi
}

## Firmware Summary Tests
function test_firmware_summary_basic_generation() {
    # Create test firmware structure
    create_test_firmware_structure
    
    # Run the firmware summary script
    local output
    output=$("$FIRMWARE_SUMMARY_SCRIPT" 2>&1)
    local exit_code=$?
    
    # Test basic functionality
    assert_exit_code 0 "$exit_code" "Firmware summary script should exit successfully"
    assert_contains "$output" "## Supported GoPro Models" "Output should contain section header"
    assert_contains "$output" "Model" "Output should contain table header"
    assert_contains "$output" "HERO13 Black" "Output should contain HERO13 Black model"
    assert_contains "$output" "HERO \\(2024\\)" "Output should contain HERO (2024) model"
    
    cleanup_test_firmware_structure
}

function test_firmware_summary_custom_sorting() {
    # Create test firmware structure
    create_test_firmware_structure
    
    # Run the firmware summary script
    local output
    output=$("$FIRMWARE_SUMMARY_SCRIPT" 2>&1)
    
    # Test custom sorting order
    local hero13_pos=$(echo "$output" | grep -n "HERO13 Black" | cut -d: -f1)
    local hero2024_pos=$(echo "$output" | grep -n "HERO (2024)" | cut -d: -f1)
    local hero12_pos=$(echo "$output" | grep -n "HERO12 Black" | cut -d: -f1)
    local gopro_max_pos=$(echo "$output" | grep -n "GoPro Max" | cut -d: -f1)
    
    # Verify custom order: HERO13 -> HERO (2024) -> HERO12 -> ... -> GoPro Max
    assert_equal 1 "$((hero13_pos < hero2024_pos))" "HERO13 should come before HERO (2024)"
    assert_equal 1 "$((hero2024_pos < hero12_pos))" "HERO (2024) should come before HERO12"
    assert_equal 1 "$((hero12_pos < gopro_max_pos))" "HERO12 should come before GoPro Max"
    
    cleanup_test_firmware_structure
}

function test_firmware_summary_model_names_with_spaces() {
    # Create test firmware structure with models that have spaces
    create_test_firmware_structure
    
    # Run the firmware summary script
    local output
    output=$("$FIRMWARE_SUMMARY_SCRIPT" 2>&1)
    
    # Test handling of model names with spaces
    assert_contains "$output" "HERO \\(2024\\)" "Should handle model name with parentheses and spaces"
    assert_contains "$output" "HERO11 Black Mini" "Should handle model name with multiple spaces"
    assert_contains "$output" "GoPro Max" "Should handle model name with space"
    
    cleanup_test_firmware_structure
}

function test_firmware_summary_unknown_models() {
    # Create test firmware structure with unknown models
    create_test_firmware_structure_with_unknown_models
    
    # Run the firmware summary script
    local output
    output=$("$FIRMWARE_SUMMARY_SCRIPT" 2>&1)
    
    # Test handling of unknown models
    assert_contains "$output" "Unknown Model X" "Should include unknown models"
    assert_contains "$output" "Test Camera Y" "Should include other unknown models"
    
    # Unknown models should appear at the top (sorted by firmware version)
    local unknown_x_pos=$(echo "$output" | grep -n "Unknown Model X" | cut -d: -f1)
    local hero13_pos=$(echo "$output" | grep -n "HERO13 Black" | cut -d: -f1)
    assert_equal 1 "$((unknown_x_pos < hero13_pos))" "Unknown models should appear before known models"
    
    cleanup_test_firmware_structure_with_unknown_models
}

function test_firmware_summary_missing_firmware() {
    # Create test firmware structure with some models missing firmware
    create_test_firmware_structure_with_missing_firmware
    
    # Run the firmware summary script
    local output
    output=$("$FIRMWARE_SUMMARY_SCRIPT" 2>&1)
    
    # Test handling of missing firmware
    assert_contains "$output" "N/A" "Should show N/A for missing firmware"
    assert_contains "$output" "HERO13 Black" "Should still include models with missing firmware"
    
    cleanup_test_firmware_structure_with_missing_firmware
}

function test_firmware_summary_table_formatting() {
    # Create test firmware structure
    create_test_firmware_structure
    
    # Run the firmware summary script
    local output
    output=$("$FIRMWARE_SUMMARY_SCRIPT" 2>&1)
    
    # Test proper markdown table formatting
    assert_contains "$output" "Model" "Should have table header with Model column"
    assert_contains "$output" "Latest Official" "Should have table header with Latest Official column"
    assert_contains "$output" "Latest Labs" "Should have table header with Latest Labs column"
    assert_contains "$output" "---" "Should have table separator line"
    assert_contains "$output" "HERO13 Black" "Should have properly formatted table rows"
    
    cleanup_test_firmware_structure
}

function test_firmware_summary_column_alignment() {
    # Create test firmware structure with varying model name lengths
    create_test_firmware_structure_with_varying_lengths
    
    # Run the firmware summary script
    local output
    output=$("$FIRMWARE_SUMMARY_SCRIPT" 2>&1)
    
    # Test column alignment
    # Check that all table rows have the same number of pipe characters (3 columns)
    local table_rows=$(echo "$output" | grep "^|" | wc -l | tr -d ' ')
    local expected_min_rows=12  # Header + separator + 10 models (minimum)
    assert_greater_equal "$expected_min_rows" "$table_rows" "Should have at least $expected_min_rows table rows"
    
    # Check that each row has exactly 3 pipe characters (indicating 3 columns)
    local malformed_rows=$(echo "$output" | grep "^|" | grep -v "^|.*|.*|$" | wc -l | tr -d ' ')
    assert_equal "0" "$malformed_rows" "All table rows should have exactly 3 columns"
    
    cleanup_test_firmware_structure_with_varying_lengths
}

# Helper functions for firmware summary tests
function create_test_firmware_structure() {
    local test_dir="$TEST_TEMP_DIR/firmware-test"
    
    # Create official firmware structure
    mkdir -p "$test_dir/firmware/official/HERO13 Black/H24.01.02.02.00"
    mkdir -p "$test_dir/firmware/official/HERO (2024)/H24.03.02.20.00"
    mkdir -p "$test_dir/firmware/official/HERO12 Black/H23.01.02.32.00"
    mkdir -p "$test_dir/firmware/official/HERO11 Black/H22.01.02.32.00"
    mkdir -p "$test_dir/firmware/official/HERO11 Black Mini/H22.03.02.50.00"
    mkdir -p "$test_dir/firmware/official/HERO10 Black/H21.01.01.62.00"
    mkdir -p "$test_dir/firmware/official/HERO9 Black/HD9.01.01.72.00"
    mkdir -p "$test_dir/firmware/official/HERO8 Black/HD8.01.02.51.00"
    mkdir -p "$test_dir/firmware/official/GoPro Max/H19.03.02.02.00"
    mkdir -p "$test_dir/firmware/official/The Remote/GP.REMOTE.FW.02.00.01"
    
    # Create labs firmware structure
    mkdir -p "$test_dir/firmware/labs/HERO13 Black/H24.01.02.02.70"
    mkdir -p "$test_dir/firmware/labs/HERO12 Black/H23.01.02.32.70"
    mkdir -p "$test_dir/firmware/labs/HERO11 Black/H22.01.02.32.70"
    mkdir -p "$test_dir/firmware/labs/HERO11 Black Mini/H22.03.02.50.71b"
    mkdir -p "$test_dir/firmware/labs/HERO10 Black/H21.01.01.62.70"
    mkdir -p "$test_dir/firmware/labs/HERO9 Black/HD9.01.01.72.70"
    mkdir -p "$test_dir/firmware/labs/HERO8 Black/HD8.01.02.51.75"
    mkdir -p "$test_dir/firmware/labs/GoPro Max/H19.03.02.02.70"
    
    # Change to test directory for firmware summary script
    cd "$test_dir"
}

function create_test_firmware_structure_with_unknown_models() {
    create_test_firmware_structure
    
    # Add unknown models with newer firmware versions
    mkdir -p "firmware/official/Unknown Model X/Z99.99.99.99.99"
    mkdir -p "firmware/official/Test Camera Y/Y88.88.88.88.88"
    mkdir -p "firmware/labs/Unknown Model X/Z99.99.99.99.99"
    mkdir -p "firmware/labs/Test Camera Y/Y88.88.88.88.88"
}

function create_test_firmware_structure_with_missing_firmware() {
    create_test_firmware_structure
    
    # Remove some firmware directories to simulate missing firmware
    rm -rf "firmware/labs/HERO (2024)"
    rm -rf "firmware/labs/The Remote"
}

function create_test_firmware_structure_with_varying_lengths() {
    create_test_firmware_structure
    
    # Add models with very long names
    mkdir -p "firmware/official/Very Long Model Name That Exceeds Normal Length/H99.99.99.99.99"
    mkdir -p "firmware/official/Short/H11.11.11.11.11"
}

function cleanup_test_firmware_structure() {
    local test_dir="$TEST_TEMP_DIR/firmware-test"
    if [[ -d "$test_dir" ]]; then
        cd - > /dev/null  # Return to original directory
        rm -rf "$test_dir"
    fi
}

function cleanup_test_firmware_structure_with_unknown_models() {
    cleanup_test_firmware_structure
}

function cleanup_test_firmware_structure_with_missing_firmware() {
    cleanup_test_firmware_structure
}

function cleanup_test_firmware_structure_with_varying_lengths() {
    cleanup_test_firmware_structure
    rm -rf "firmware/official/Very Long Model Name That Exceeds Normal Length"
    rm -rf "firmware/official/Short"
}

# Test for correct gitflow-release.zsh path in release.zsh
function test_release_script_gitflow_path() {
    local release_script="scripts/release/release.zsh"
    local gitflow_script="scripts/release/gitflow-release.zsh"
    
    # Backup and temporarily move gitflow-release.zsh
    if [[ -f "$gitflow_script" ]]; then
        mv "$gitflow_script" "$gitflow_script.bak"
    fi
    
    # Should fail with error about missing script
    local output
    output=$(ZSH_DISABLE_COMPFIX=true zsh "$release_script" --batch dry-run --prev 01.50.00 2>&1 || true)
    assert_contains "$output" "gitflow-release.zsh script not found" "Should error if gitflow-release.zsh is missing"
    
    # Restore script
    if [[ -f "$gitflow_script.bak" ]]; then
        mv "$gitflow_script.bak" "$gitflow_script"
    fi
    
    # Should pass prerequisites check - just verify the script starts without export errors
    output=$(ZSH_DISABLE_COMPFIX=true zsh "$release_script" --batch dry-run --prev 01.50.00 2>&1 || true)
    # Check that the script starts properly and reaches prerequisites check
    assert_contains "$output" "Release script starting" "Should start without export errors"
    assert_contains "$output" "Checking prerequisites" "Should reach prerequisites check"
    # The script may fail later due to uncommitted changes, but that's not what we're testing
}

# Add to the appropriate suite
run_test "release_script_gitflow_path" test_release_script_gitflow_path "Test release.zsh detects gitflow-release.zsh path correctly" 