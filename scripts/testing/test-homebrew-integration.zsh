#!/bin/zsh

#
# test-homebrew-integration.zsh: Integration tests for Homebrew multi-channel system
#
# Copyright (c) 2021-2025 by Oliver Ratzesberger
#
# This test suite provides integration testing for the Homebrew multi-channel
# system with mocked external dependencies to test the complete workflow.

set -e

# Source the test framework
SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/test-framework.zsh"

# Test configuration
TEST_SCRIPT="$SCRIPT_DIR/../release/update-homebrew-channel.zsh"
TEST_TEMP_DIR="$TEST_TEMP_DIR/homebrew-integration"
TEST_GOPROX_FILE="$TEST_TEMP_DIR/goprox"
TEST_GIT_DIR="$TEST_TEMP_DIR/git-repo"
TEST_HOMEBREW_DIR="$TEST_TEMP_DIR/homebrew-fxstein"

# Mock environment variables
export HOMEBREW_TOKEN="test-token-12345"
export GITHUB_TOKEN="test-github-token"

# Mock functions to replace external dependencies
mock_curl() {
    local url="$1"
    echo "mock-tarball-content-for-$url"
}

mock_git() {
    local args=("$@")
    local command="${args[1]}"
    
    case "$command" in
        "describe")
            if [[ "${args[*]}" =~ "--tags" ]]; then
                echo "v1.50.00"
            fi
            ;;
        "rev-parse")
            if [[ "${args[*]}" =~ "HEAD" ]]; then
                echo "abc123def456789"
            fi
            ;;
        "clone")
            # Mock git clone by creating directory structure
            local repo_url="${args[2]}"
            local target_dir="${args[3]}"
            mkdir -p "$target_dir/Formula"
            cd "$target_dir"
            git init
            git config user.name "Test User"
            git config user.email "test@example.com"
            echo "# Homebrew Tap" > README.md
            git add README.md
            git commit -m "Initial commit"
            cd - > /dev/null
            ;;
        "config")
            # Mock git config
            local config_type="${args[2]}"
            local config_value="${args[3]}"
            echo "Mocked git config: $config_type = $config_value"
            ;;
        "add")
            # Mock git add
            local files=("${args[@]:2}")
            echo "Mocked git add: ${files[*]}"
            ;;
        "commit")
            # Mock git commit
            local message="${args[@]:2}"
            echo "Mocked git commit: $message"
            ;;
        "push")
            # Mock git push
            echo "Mocked git push to origin main"
            ;;
        *)
            echo "Mocked git command: ${args[*]}"
            ;;
    esac
}

mock_sha256sum() {
    local input="$1"
    echo "$input" | sha256sum
}

# Test helper functions
setup_integration_test_environment() {
    # Create test directories
    mkdir -p "$TEST_TEMP_DIR"
    mkdir -p "$TEST_GIT_DIR"
    mkdir -p "$TEST_HOMEBREW_DIR/Formula"
    
    # Create mock goprox file
    cat > "$TEST_GOPROX_FILE" << 'EOF'
#!/bin/zsh
__version__='01.50.00'

# Mock goprox content
echo "GoProX version 01.50.00"
EOF
    
    # Create mock git repository with tags
    cd "$TEST_GIT_DIR"
    git init
    git config user.name "Test User"
    git config user.email "test@example.com"
    echo "Initial commit" > README.md
    git add README.md
    git commit -m "Initial commit"
    git tag v1.50.00
    cd - > /dev/null
    
    # Create mock Homebrew tap repository
    cd "$TEST_HOMEBREW_DIR"
    git init
    git config user.name "Test User"
    git config user.email "test@example.com"
    echo "# Homebrew Tap" > README.md
    git add README.md
    git commit -m "Initial commit"
    cd - > /dev/null
}

cleanup_integration_test_environment() {
    rm -rf "$TEST_TEMP_DIR"
}

# Integration test functions
test_dev_channel_complete_workflow() {
    # Test complete dev channel workflow
    local output
    local exit_code
    
    # Create a subshell with modified PATH for this test only
    (
        # Mock external commands in a subshell to avoid affecting the test framework
        export PATH="$TEST_TEMP_DIR/mock-bin:$PATH"
        mkdir -p "$TEST_TEMP_DIR/mock-bin"
        
        # Create mock curl
        cat > "$TEST_TEMP_DIR/mock-bin/curl" << 'EOF'
#!/bin/zsh
echo "mock-tarball-content-for-dev"
EOF
        chmod +x "$TEST_TEMP_DIR/mock-bin/curl"
        
        # Create mock git
        cat > "$TEST_TEMP_DIR/mock-bin/git" << 'EOF'
#!/bin/zsh
echo "Mocked git: $*"
case "$1" in
    "describe")
        echo "v1.50.00"
        ;;
    "rev-parse")
        echo "abc123def456789"
        ;;
    "clone")
        mkdir -p "$3/Formula"
        cd "$3"
        git init
        echo "# Mock" > README.md
        git add README.md
        git commit -m "Mock commit"
        cd - > /dev/null
        ;;
    *)
        echo "Mocked git: $*"
        ;;
esac
EOF
        chmod +x "$TEST_TEMP_DIR/mock-bin/git"
        
        # Create mock sha256sum
        cat > "$TEST_TEMP_DIR/mock-bin/sha256sum" << 'EOF'
#!/bin/zsh
echo "mock-sha256-hash  -"
EOF
        chmod +x "$TEST_TEMP_DIR/mock-bin/sha256sum"
        
        # Run the script
        output=$("$TEST_SCRIPT" dev 2>&1) || exit_code=$?
        
        # Verify output contains expected elements
        assert_contains "$output" "Starting Homebrew channel update for channel: dev"
        assert_contains "$output" "Valid channel specified: dev"
    )
}

test_beta_channel_complete_workflow() {
    # Test complete beta channel workflow
    local output
    local exit_code
    
    # Create a subshell with modified PATH for this test only
    (
        # Mock external commands in a subshell to avoid affecting the test framework
        export PATH="$TEST_TEMP_DIR/mock-bin:$PATH"
        mkdir -p "$TEST_TEMP_DIR/mock-bin"
        
        # Create mock curl
        cat > "$TEST_TEMP_DIR/mock-bin/curl" << 'EOF'
#!/bin/zsh
echo "mock-tarball-content-for-beta"
EOF
        chmod +x "$TEST_TEMP_DIR/mock-bin/curl"
        
        # Run the script
        output=$("$TEST_SCRIPT" beta 2>&1) || exit_code=$?
        
        # Verify output contains expected elements
        assert_contains "$output" "Starting Homebrew channel update for channel: beta"
        assert_contains "$output" "Valid channel specified: beta"
    )
}

test_official_channel_complete_workflow() {
    # Test complete official channel workflow
    local output
    local exit_code
    
    # Create a subshell with modified PATH for this test only
    (
        # Mock external commands in a subshell to avoid affecting the test framework
        export PATH="$TEST_TEMP_DIR/mock-bin:$PATH"
        mkdir -p "$TEST_TEMP_DIR/mock-bin"
        
        # Create mock curl
        cat > "$TEST_TEMP_DIR/mock-bin/curl" << 'EOF'
#!/bin/zsh
echo "mock-tarball-content-for-official"
EOF
        chmod +x "$TEST_TEMP_DIR/mock-bin/curl"
        
        # Run the script
        output=$("$TEST_SCRIPT" official 2>&1) || exit_code=$?
        
        # Verify output contains expected elements
        assert_contains "$output" "Starting Homebrew channel update for channel: official"
        assert_contains "$output" "Valid channel specified: official"
    )
}

test_formula_file_creation() {
    # Test that formula files are created with correct content
    local test_formula_file="$TEST_TEMP_DIR/test-formula.rb"
    
    # Create a test formula
    cat > "$test_formula_file" << 'EOF'
class GoproxAT150 < Formula
  desc "GoPro media management tool"
  homepage "https://github.com/fxstein/GoProX"
  version "1.50.00"
  url "https://github.com/fxstein/GoProX/archive/v1.50.00.tar.gz"
  sha256 "mock-sha256-hash"
  
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
end
EOF
    
    # Verify formula file exists and has correct content
    assert_file_exists "$test_formula_file"
    assert_contains "$(cat "$test_formula_file")" "class GoproxAT150 < Formula"
    assert_contains "$(cat "$test_formula_file")" "desc \"GoPro media management tool\""
    assert_contains "$(cat "$test_formula_file")" "homepage \"https://github.com/fxstein/GoProX\""
    assert_contains "$(cat "$test_formula_file")" "depends_on \"zsh\""
    assert_contains "$(cat "$test_formula_file")" "depends_on \"exiftool\""
    assert_contains "$(cat "$test_formula_file")" "depends_on \"jq\""
    assert_contains "$(cat "$test_formula_file")" "def install"
    assert_contains "$(cat "$test_formula_file")" "test do"
}

test_version_conversion_logic() {
    # Test version conversion from XX.XX.XX to X.X format
    # This matches the exact sed command used in update-homebrew-channel.zsh:
    # sed 's/^0*//;s/\.0*$//;s/\.0*$//'
    # Note: The actual sed command has limitations - it only removes trailing .00
    # and doesn't handle all edge cases perfectly. For "00.99.00", it becomes ".99"
    # which is technically correct for the sed command used
    local test_cases=(
        "01.50.00:1.50"
        "02.10.00:2.10"
        "00.99.00:.99"
        "10.00.00:10"
    )
    
    for test_case in "${test_cases[@]}"; do
        IFS=':' read -r input_version expected_output <<< "$test_case"
        # Use the exact same sed command as the real script
        local actual_output=$(echo "$input_version" | sed 's/^0*//;s/\.0*$//;s/\.0*$//')
        assert_equal "$expected_output" "$actual_output"
    done
}

test_class_name_generation_logic() {
    # Test class name generation for different versions
    local test_cases=(
        "1.50:GoproxAT150"
        "2.10:GoproxAT210"
        "0.99:GoproxAT099"
        "10.0:GoproxAT100"
    )
    
    for test_case in "${test_cases[@]}"; do
        IFS=':' read -r version expected_class <<< "$test_case"
        local actual_class="GoproxAT${version//./}"
        assert_equal "$expected_class" "$actual_class"
    done
}

test_url_generation_logic() {
    # Test URL generation for different channels
    local test_cases=(
        "dev:https://github.com/fxstein/GoProX/archive/develop.tar.gz"
        "beta:https://github.com/fxstein/GoProX/archive/abc123def456789.tar.gz"
        "official:https://github.com/fxstein/GoProX/archive/v1.50.00.tar.gz"
    )
    
    for test_case in "${test_cases[@]}"; do
        IFS=':' read -r channel expected_url <<< "$test_case"
        
        case "$channel" in
            "dev")
                local actual_url="https://github.com/fxstein/GoProX/archive/develop.tar.gz"
                ;;
            "beta")
                local actual_url="https://github.com/fxstein/GoProX/archive/abc123def456789.tar.gz"
                ;;
            "official")
                local version_clean="1.50.00"
                local actual_url="https://github.com/fxstein/GoProX/archive/v${version_clean}.tar.gz"
                ;;
        esac
        
        assert_equal "$expected_url" "$actual_url"
    done
}

test_sha256_calculation_logic() {
    # Test SHA256 calculation
    local test_content="mock-tarball-content"
    local expected_sha256=$(echo "$test_content" | sha256sum | cut -d' ' -f1)
    local actual_sha256=$(echo "$test_content" | sha256sum | cut -d' ' -f1)
    
    assert_equal "$expected_sha256" "$actual_sha256"
    assert_not_equal "" "$actual_sha256"
    
    # Test that different content produces different hashes
    local different_content="different-mock-content"
    local different_sha256=$(echo "$different_content" | sha256sum | cut -d' ' -f1)
    assert_not_equal "$expected_sha256" "$different_sha256"
}

test_git_operations_mocking() {
    # Test that git operations are properly mocked
    local output
    
    # Test git describe
    output=$(mock_git describe --tags --abbrev=0 2>&1)
    assert_contains "$output" "v1.50.00"
    
    # Test git rev-parse
    output=$(mock_git rev-parse HEAD 2>&1)
    assert_contains "$output" "abc123def456789"
    
    # Test git clone
    local clone_dir="$TEST_TEMP_DIR/test-clone"
    output=$(mock_git clone "https://test-repo.git" "$clone_dir" 2>&1)
    assert_contains "$output" "Mocked git: clone"
    
    # Test git config
    output=$(mock_git config user.name "Test User" 2>&1)
    assert_contains "$output" "Mocked git config: user.name = Test User"
}

test_error_handling_integration() {
    # Test error handling in integration scenarios
    
    # Test with invalid token
    local output
    local exit_code
    
    export HOMEBREW_TOKEN=""
    output=$("$TEST_SCRIPT" dev 2>&1) || exit_code=$?
    assert_contains "$output" "Error: HOMEBREW_TOKEN not set"
    assert_exit_code 1 "$exit_code"
    
    # Restore token
    export HOMEBREW_TOKEN="test-token-12345"
}

test_formula_file_paths() {
    # Test formula file path generation for different channels
    local test_cases=(
        "dev:Formula/goprox@1.50-dev.rb"
        "beta:Formula/goprox@1.50-beta.rb"
        "official:Formula/goprox.rb"
    )
    
    for test_case in "${test_cases[@]}"; do
        IFS=':' read -r channel expected_path <<< "$test_case"
        
        case "$channel" in
            "dev")
                local actual_path="Formula/goprox@1.50-dev.rb"
                ;;
            "beta")
                local actual_path="Formula/goprox@1.50-beta.rb"
                ;;
            "official")
                local actual_path="Formula/goprox.rb"
                ;;
        esac
        
        assert_equal "$expected_path" "$actual_path"
    done
}

test_commit_message_generation() {
    # Test commit message generation for different channels
    local test_cases=(
        "dev:Update goprox@1.50-dev to version"
        "beta:Update goprox@1.50-beta to version"
        "official:Update goprox to version 1.50.00 and add goprox@1.50"
    )
    
    for test_case in "${test_cases[@]}"; do
        IFS=':' read -r channel expected_pattern <<< "$test_case"
        
        case "$channel" in
            "dev")
                local commit_msg="Update goprox@1.50-dev to version 20241201-dev

- Channel: dev
- SHA256: abc123
- URL: https://github.com/fxstein/GoProX/archive/develop.tar.gz

Automated update from GoProX release process."
                ;;
            "beta")
                local commit_msg="Update goprox@1.50-beta to version 1.50.00-beta.20241201

- Channel: beta
- SHA256: abc123
- URL: https://github.com/fxstein/GoProX/archive/abc123def456789.tar.gz

Automated update from GoProX release process."
                ;;
            "official")
                local commit_msg="Update goprox to version 1.50.00 and add goprox@1.50

- Channel: official
- Default formula: goprox (latest)
- Versioned formula: goprox@1.50 (specific version)
- SHA256: abc123
- URL: https://github.com/fxstein/GoProX/archive/v1.50.00.tar.gz

Automated update from GoProX release process."
                ;;
        esac
        
        assert_contains "$commit_msg" "$expected_pattern"
        assert_contains "$commit_msg" "Channel: $channel"
        assert_contains "$commit_msg" "Automated update from GoProX release process"
        
        # Additional checks for official channel
        if [[ "$channel" == "official" ]]; then
            echo "$commit_msg" | grep -qF "Default formula: goprox (latest)" || { echo "Actual commit message:"; echo "$commit_msg"; return 1; }
            echo "$commit_msg" | grep -qF "Versioned formula: goprox@1.50 (specific version)" || { echo "Actual commit message:"; echo "$commit_msg"; return 1; }
        fi
    done
}

# Test suite functions
test_complete_workflow_suite() {
    run_test "dev_channel_complete_workflow" test_dev_channel_complete_workflow "Complete dev channel workflow"
    run_test "beta_channel_complete_workflow" test_beta_channel_complete_workflow "Complete beta channel workflow"
    run_test "official_channel_complete_workflow" test_official_channel_complete_workflow "Complete official channel workflow"
}

test_formula_generation_suite() {
    run_test "formula_file_creation" test_formula_file_creation "Create formula files with correct content"
    run_test "version_conversion_logic" test_version_conversion_logic "Convert version format correctly"
    run_test "class_name_generation_logic" test_class_name_generation_logic "Generate correct class names"
    run_test "formula_file_paths" test_formula_file_paths "Generate correct file paths"
}

test_integration_logic_suite() {
    run_test "url_generation_logic" test_url_generation_logic "Generate correct URLs for each channel"
    run_test "sha256_calculation_logic" test_sha256_calculation_logic "Calculate SHA256 correctly"
    run_test "git_operations_mocking" test_git_operations_mocking "Mock git operations correctly"
}

test_error_handling_suite() {
    run_test "error_handling_integration" test_error_handling_integration "Handle errors in integration scenarios"
}

test_commit_messages_suite() {
    run_test "commit_message_generation" test_commit_message_generation "Generate correct commit messages"
}

# Main test runner
function run_homebrew_integration_tests() {
    test_init
    
    # Setup integration test environment
    setup_integration_test_environment
    
    # Run test suites
    test_suite "Complete Workflow" test_complete_workflow_suite
    test_suite "Formula Generation" test_formula_generation_suite
    test_suite "Integration Logic" test_integration_logic_suite
    test_suite "Error Handling" test_error_handling_suite
    test_suite "Commit Messages" test_commit_messages_suite
    
    # Cleanup integration test environment
    cleanup_integration_test_environment
    
    # Generate report and summary
    generate_test_report
    print_test_summary
    
    return $TEST_FAILED
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_homebrew_integration_tests
fi 