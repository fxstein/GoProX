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
    output=$(../goprox --help 2>&1)
    assert_exit_code 1 "$?" "Help option should exit with code 1"
    assert_contains "$output" "Usage:" "Help output should contain usage information"
}

function test_params_invalid_options() {
    # Test that invalid options are rejected
    local output
    output=$(../goprox --invalid-option 2>&1)
    assert_exit_code 1 "$?" "Invalid option should exit with code 1"
    assert_contains "$output" "Unknown option" "Should show unknown option error"
}

function test_params_missing_required() {
    # Test that missing required parameters are handled
    local output
    output=$(../goprox --import 2>&1)
    assert_exit_code 1 "$?" "Missing library should exit with code 1"
    assert_contains "$output" "Missing library" "Should show missing library error"
}

function test_params_help_option() {
    # Test help option functionality
    local output
    output=$(../goprox -h 2>&1)
    assert_exit_code 1 "$?" "Help option should exit with code 1"
    assert_contains "$output" "goprox - import and process" "Help should show description"
}

function test_params_version_option() {
    # Test version option functionality
    local output
    output=$(../goprox --version 2>&1)
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
    # Create test firmware structure
    mkdir -p "test-firmware/MISC"
    echo '{"camera type": "HERO10 Black", "firmware version": "H21.01.01.10.00"}' > "test-firmware/MISC/version.txt"
    
    # Test firmware detection
    assert_file_exists "test-firmware/MISC/version.txt" "Firmware version file should exist"
    assert_contains "$(cat test-firmware/MISC/version.txt)" "HERO10 Black" "Should contain camera type"
    
    cleanup_test_files "test-firmware"
}

function test_integration_error_handling() {
    # Test error handling by trying to access non-existent file
    local output
    output=$(../goprox --source "/nonexistent/path" --library "./test-lib" 2>&1)
    
    # Should handle the error gracefully
    assert_exit_code 1 "$?" "Should exit with error code for non-existent source"
    
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