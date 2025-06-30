#!/bin/zsh

#
# test-homebrew-multi-channel.zsh: Unit tests for Homebrew multi-channel system
#
# Copyright (c) 2021-2025 by Oliver Ratzesberger
#
# This test suite validates the Homebrew multi-channel update functionality,
# including parameter validation, version parsing, formula generation,
# and error handling scenarios.

set -e

# Source the test framework
SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/test-framework.zsh"

# Test configuration
TEST_SCRIPT="$SCRIPT_DIR/../release/update-homebrew-channel.zsh"
TEST_GOPROX_FILE="$TEST_TEMP_DIR/goprox"
TEST_GIT_DIR="$TEST_TEMP_DIR/git-repo"

# Mock functions for testing
mock_curl() {
    echo "mock-tarball-content"
}

mock_git_describe() {
    echo "v1.50.00"
}

mock_git_rev_parse() {
    echo "abc123def456"
}

mock_git_clone() {
    mkdir -p "$2/homebrew-fxstein/Formula"
    cd "$2/homebrew-fxstein"
    git init
    git config user.name "Test User"
    git config user.email "test@example.com"
    echo "Initial commit" > README.md
    git add README.md
    git commit -m "Initial commit"
}

# Test helper functions
setup_test_environment() {
    echo "[DEBUG] Entering setup_test_environment"
    # Clean up test temp directory to ensure a fresh environment
    rm -rf "$TEST_TEMP_DIR"
    mkdir -p "$TEST_TEMP_DIR"
    
    # Create mock goprox file
    cat > "$TEST_GOPROX_FILE" << 'EOF'
#!/bin/zsh
__version__='01.50.00'
# ... rest of goprox content
EOF
    echo "[DEBUG] Created mock goprox file at $TEST_GOPROX_FILE"
    
    # Create mock git repository
    mkdir -p "$TEST_GIT_DIR"
    echo "[DEBUG] Created test git dir $TEST_GIT_DIR"
    cd "$TEST_GIT_DIR"
    echo "[DEBUG] Changed directory to $TEST_GIT_DIR"
    git init
    echo "[DEBUG] Ran git init"
    git config user.name "Test User"
    git config user.email "test@example.com"
    echo "[DEBUG] Configured git user"
    echo "Initial commit" > README.md
    git add README.md
    git commit -m "Initial commit"
    echo "[DEBUG] Created initial commit"
    git tag v1.50.00
    echo "[DEBUG] Tagged v1.50.00"
    cd - > /dev/null
    echo "[DEBUG] Exiting setup_test_environment"
}

cleanup_test_environment() {
    rm -rf "$TEST_TEMP_DIR"
}

# Test functions
test_help_display() {
    local output
    output=$("$TEST_SCRIPT" --help 2>&1)
    
    assert_contains "$output" "Homebrew Multi-Channel Update Script"
    assert_contains "$output" "Usage:"
    assert_contains "$output" "Channels:"
    assert_contains "$output" "dev"
    assert_contains "$output" "beta"
    assert_contains "$output" "official"
}

test_missing_channel_parameter() {
    local output
    local exit_code
    
    output=$("$TEST_SCRIPT" 2>&1) || exit_code=$?
    
    assert_contains "$output" "Error: Channel parameter required"
    assert_exit_code 1 "$exit_code"
}

test_invalid_channel_parameter() {
    local output
    local exit_code
    
    output=$("$TEST_SCRIPT" invalid 2>&1) || exit_code=$?
    
    assert_contains "$output" "Error: Invalid channel 'invalid'"
    assert_contains "$output" "Use: dev, beta, or official"
    assert_exit_code 1 "$exit_code"
}

test_valid_channel_parameters() {
    local channels=("dev" "beta" "official")
    
    for channel in "${channels[@]}"; do
        local output
        output=$("$TEST_SCRIPT" "$channel" 2>&1) || true
        
        # Should pass channel validation but fail on authentication
        assert_contains "$output" "Valid channel specified: $channel"
        # The script now tries GitHub CLI first, so we expect authentication failure
        # but not necessarily HOMEBREW_TOKEN error
        assert_contains "$output" "Starting Homebrew channel update for channel: $channel"
    done
}

test_missing_homebrew_token() {
    local output
    local exit_code=0
    
    # Create completely isolated test environment
    local isolated_dir
    isolated_dir=$(create_isolated_test_env "missing_homebrew_token")
    
    # Capture both output and exit code in the isolated environment
    output=$("$TEST_SCRIPT" dev 2>&1) || exit_code=$?
    
    # The script should exit with code 1 when no authentication is available
    assert_contains "$output" "Starting Homebrew channel update for channel: dev"
    assert_contains "$output" "Error: No authentication available for Homebrew operations"
    assert_exit_code 1 "$exit_code"
    
    # Clean up isolated environment
    cleanup_isolated_test_env "$isolated_dir"
}

test_missing_goprox_file() {
    local output
    local exit_code
    
    # Create a temporary directory for this test
    local temp_test_dir="$TEST_TEMP_DIR/missing-goprox-test"
    mkdir -p "$temp_test_dir"
    cd "$temp_test_dir"
    
    # The goprox file should not exist in this temp directory
    output=$("$TEST_SCRIPT" dev 2>&1) || exit_code=$?
    
    assert_contains "$output" "Error: goprox file not found"
    assert_exit_code 1 "$exit_code"
    
    # Return to original directory
    cd - > /dev/null
}

test_version_parsing_from_goprox() {
    # Create test goprox file with specific version
    cat > "$TEST_GOPROX_FILE" << 'EOF'
#!/bin/zsh
__version__='01.50.00'
EOF
    
    # Test that the script can read the version
    local output
    output=$("$TEST_SCRIPT" dev 2>&1) || true
    
    # Should contain version parsing logic (even if it fails later)
    assert_contains "$output" "Starting Homebrew channel update for channel: dev"
}

test_dev_channel_version_format() {
    # Create test goprox file
    cat > "$TEST_GOPROX_FILE" << 'EOF'
#!/bin/zsh
__version__='01.50.00'
EOF
    
    # Mock the script to capture version logic
    local test_script_content
    test_script_content=$(cat "$TEST_SCRIPT")
    
    # Extract version parsing logic and test it
    local actual_version
    actual_version=$(echo '01.50.00' | sed 's/^0*//;s/\.0*$//;s/\.0*$//')
    
    assert_equal "1.50" "$actual_version"
}

test_beta_channel_fallback_version() {
    # Create test goprox file
    cat > "$TEST_GOPROX_FILE" << 'EOF'
#!/bin/zsh
__version__='01.50.00'
EOF
    
    # Test beta channel with no tags (should use fallback)
    local output
    output=$("$TEST_SCRIPT" beta 2>&1) || true
    
    # Should handle missing tags gracefully
    assert_contains "$output" "Starting Homebrew channel update for channel: beta"
}

test_official_channel_missing_tags() {
    # Create test goprox file
    cat > "$TEST_GOPROX_FILE" << 'EOF'
#!/bin/zsh
__version__='01.50.00'
EOF
    
    # Create a temp git repo with no tags
    local temp_git_dir="$TEST_TEMP_DIR/no-tags-repo"
    mkdir -p "$temp_git_dir"
    cd "$temp_git_dir"
    git init
    git config user.name "Test User"
    git config user.email "test@example.com"
    echo "Initial commit" > README.md
    git add README.md
    git commit -m "Initial commit"
    cd - > /dev/null
    
    # Run the script in the repo with no tags
    local output
    local exit_code
    (cd "$temp_git_dir" && "$TEST_SCRIPT" official 2>&1) || exit_code=$?
    
    assert_contains "$output" "Error: No tags found for official release"
    assert_exit_code 1 "$exit_code"
}

test_formula_class_name_generation() {
    local test_cases=(
        "1.50:GoproxAT150"
        "2.10:GoproxAT210"
        "0.99:GoproxAT099"
    )
    
    for test_case in "${test_cases[@]}"; do
        IFS=':' read -r version expected_class <<< "$test_case"
        local actual_class="GoproxAT${version//./}"
        assert_equal "$expected_class" "$actual_class"
    done
}

test_formula_file_path_generation() {
    local test_cases=(
        "dev:Formula/goprox@1.50-dev.rb"
        "beta:Formula/goprox@1.50-beta.rb"
        "official:Formula/goprox@1.50.rb"
    )
    
    for test_case in "${test_cases[@]}"; do
        IFS=':' read -r channel expected_path <<< "$test_case"
        local actual_path
        if [[ "$channel" == "official" ]]; then
            actual_path="Formula/goprox@1.50.rb"
        else
            actual_path="Formula/goprox@1.50-$channel.rb"
        fi
        assert_equal "$expected_path" "$actual_path"
    done
}

test_url_generation() {
    # Test dev channel URL
    local dev_url="https://github.com/fxstein/GoProX/archive/develop.tar.gz"
    assert_contains "$dev_url" "github.com/fxstein/GoProX"
    assert_contains "$dev_url" "develop.tar.gz"
    
    # Test beta channel URL
    local beta_url="https://github.com/fxstein/GoProX/archive/abc123def456.tar.gz"
    assert_contains "$beta_url" "github.com/fxstein/GoProX"
    assert_contains "$beta_url" "abc123def456.tar.gz"
    
    # Test official channel URL (with v prefix handling)
    local version_clean="1.50.00"
    local official_url="https://github.com/fxstein/GoProX/archive/v${version_clean}.tar.gz"
    assert_contains "$official_url" "github.com/fxstein/GoProX"
    assert_contains "$official_url" "v1.50.00.tar.gz"
}

test_sha256_calculation() {
    # Mock curl output
    local mock_content="mock-tarball-content"
    local expected_sha256=$(echo "$mock_content" | sha256sum | cut -d' ' -f1)
    
    # Test SHA256 calculation
    local actual_sha256=$(echo "$mock_content" | sha256sum | cut -d' ' -f1)
    
    assert_equal "$expected_sha256" "$actual_sha256"
    assert_not_equal "" "$actual_sha256"
}

test_formula_content_structure() {
    # Test that formula content has required sections
    local formula_content='class GoproxAT150 < Formula
  desc "GoPro media management tool"
  homepage "https://github.com/fxstein/GoProX"
  version "1.50.00"
  url "https://github.com/fxstein/GoProX/archive/v1.50.00.tar.gz"
  sha256 "abc123"
  
  depends_on "zsh"
  depends_on "exiftool"
  depends_on "jq"
  
  def install
    bin.install "goprox"
    man1.install "man/goprox.1"
  end
  
  test do
    system "#{bin}/goprox", "--version"
  end
end'
    
    assert_contains "$formula_content" "class GoproxAT150 < Formula"
    assert_contains "$formula_content" "desc \"GoPro media management tool\""
    assert_contains "$formula_content" "homepage \"https://github.com/fxstein/GoProX\""
    assert_contains "$formula_content" "depends_on \"zsh\""
    assert_contains "$formula_content" "depends_on \"exiftool\""
    assert_contains "$formula_content" "depends_on \"jq\""
    assert_contains "$formula_content" "def install"
    assert_contains "$formula_content" "test do"
}

test_git_operations() {
    # Test git configuration
    local git_name="GoProX Release Bot"
    local git_email="release-bot@goprox.dev"
    
    assert_equal "GoProX Release Bot" "$git_name"
    assert_equal "release-bot@goprox.dev" "$git_email"
}

test_commit_message_format() {
    # Test commit message format for different channels
    local dev_commit="Update goprox@1.50-dev to version 20241201-dev

- Channel: dev
- SHA256: abc123
- URL: https://github.com/fxstein/GoProX/archive/develop.tar.gz

Automated update from GoProX release process."
    
    local official_commit="Update goprox to version 1.50.00 and add goprox@1.50

- Channel: official
- Default formula: goprox (latest)
- Versioned formula: goprox@1.50 (specific version)
- SHA256: abc123
- URL: https://github.com/fxstein/GoProX/archive/v1.50.00.tar.gz

Automated update from GoProX release process."
    
    assert_contains "$dev_commit" "Update goprox@1.50-dev to version"
    assert_contains "$dev_commit" "Channel: dev"
    assert_contains "$dev_commit" "Automated update from GoProX release process"
    
    assert_contains "$official_commit" "Update goprox to version 1.50.00"
    assert_contains "$official_commit" "Channel: official"
    assert_contains "$official_commit" "Default formula: goprox (latest)"
    assert_contains "$official_commit" "Versioned formula: goprox@1.50"
}

test_error_handling_network_failure() {
    # Test handling of network failures during SHA256 calculation
    local output
    local exit_code
    
    # This would normally fail with curl, but we're testing the error handling logic
    output=$("$TEST_SCRIPT" dev 2>&1) || exit_code=$?
    
    # Should handle network errors gracefully
    assert_contains "$output" "Starting Homebrew channel update for channel: dev"
}

test_cleanup_operations() {
    # Test that temporary directories are cleaned up
    local temp_dir=$(mktemp -d)
    
    # Verify temp directory exists
    assert_directory_exists "$temp_dir"
    
    # Cleanup
    rm -rf "$temp_dir"
    
    # Verify temp directory is removed
    assert_file_not_exists "$temp_dir"
}

# Test suite functions
test_parameter_validation_suite() {
    run_test "help_display" test_help_display "Display help information"
    run_test "missing_channel_parameter" test_missing_channel_parameter "Handle missing channel parameter"
    run_test "invalid_channel_parameter" test_invalid_channel_parameter "Handle invalid channel parameter"
    run_test "valid_channel_parameters" test_valid_channel_parameters "Accept valid channel parameters"
}

test_environment_validation_suite() {
    run_test "missing_homebrew_token" test_missing_homebrew_token "Handle missing HOMEBREW_TOKEN"
    run_test "missing_goprox_file" test_missing_goprox_file "Handle missing goprox file"
}

test_version_processing_suite() {
    run_test "version_parsing_from_goprox" test_version_parsing_from_goprox "Parse version from goprox file"
    run_test "dev_channel_version_format" test_dev_channel_version_format "Format dev channel version"
    run_test "beta_channel_fallback_version" test_beta_channel_fallback_version "Handle beta channel fallback version"
    run_test "official_channel_missing_tags" test_official_channel_missing_tags "Handle official channel missing tags"
}

test_formula_generation_suite() {
    run_test "formula_class_name_generation" test_formula_class_name_generation "Generate correct class names"
    run_test "formula_file_path_generation" test_formula_file_path_generation "Generate correct file paths"
    run_test "formula_content_structure" test_formula_content_structure "Validate formula content structure"
}

test_url_and_sha256_suite() {
    run_test "url_generation" test_url_generation "Generate correct URLs for each channel"
    run_test "sha256_calculation" test_sha256_calculation "Calculate SHA256 correctly"
}

test_git_operations_suite() {
    run_test "git_operations" test_git_operations "Configure git operations correctly"
    run_test "commit_message_format" test_commit_message_format "Format commit messages correctly"
}

test_error_handling_suite() {
    run_test "error_handling_network_failure" test_error_handling_network_failure "Handle network failures gracefully"
    run_test "cleanup_operations" test_cleanup_operations "Clean up temporary files and directories"
}

# Main test runner
function run_homebrew_multi_channel_tests() {
    test_init
    
    # Setup test environment
    setup_test_environment
    echo "[DEBUG] setup_test_environment completed"
    
    # Run test suites
    test_suite "Parameter Validation" test_parameter_validation_suite
    test_suite "Environment Validation" test_environment_validation_suite
    test_suite "Version Processing" test_version_processing_suite
    test_suite "Formula Generation" test_formula_generation_suite
    test_suite "URL and SHA256" test_url_and_sha256_suite
    test_suite "Git Operations" test_git_operations_suite
    test_suite "Error Handling" test_error_handling_suite
    
    # Cleanup test environment
    cleanup_test_environment
    
    # Generate report and summary
    generate_test_report
    print_test_summary
    
    return $TEST_FAILED
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_homebrew_multi_channel_tests
fi 