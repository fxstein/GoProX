#!/bin/zsh

# Test script for Enhanced Default Behavior
# This script tests the intelligent media management functionality

# Source the logger module
SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/../core/logger.zsh"

# Test configuration
TEST_NAME="Enhanced Default Behavior Test Suite"
TEST_VERSION="1.0.0"

# Test results tracking
declare -A test_results
total_tests=0
passed_tests=0
failed_tests=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_function="$2"
    
    total_tests=$((total_tests + 1))
    log_info "Running test: $test_name"
    
    if $test_function; then
        test_results["$test_name"]="PASS"
        passed_tests=$((passed_tests + 1))
        echo "✅ PASS: $test_name"
    else
        test_results["$test_name"]="FAIL"
        failed_tests=$((failed_tests + 1))
        echo "❌ FAIL: $test_name"
    fi
}

# Test 1: Smart Detection Module Loading
test_smart_detection_loading() {
    log_debug "Testing smart detection module loading"
    
    # Source the smart detection module
    if source "$SCRIPT_DIR/../core/smart-detection.zsh"; then
        # Check if key functions are available
        if command -v detect_gopro_cards >/dev/null 2>&1; then
            return 0
        else
            log_error "detect_gopro_cards function not found"
            return 1
        fi
    else
        log_error "Failed to source smart-detection.zsh"
        return 1
    fi
}

# Test 2: Decision Matrix Module Loading
test_decision_matrix_loading() {
    log_debug "Testing decision matrix module loading"
    
    # Source the decision matrix module
    if source "$SCRIPT_DIR/../core/decision-matrix.zsh"; then
        # Check if key functions are available
        if command -v analyze_workflow_requirements >/dev/null 2>&1; then
            return 0
        else
            log_error "analyze_workflow_requirements function not found"
            return 1
        fi
    else
        log_error "Failed to source decision-matrix.zsh"
        return 1
    fi
}

# Test 3: Enhanced Default Behavior Module Loading
test_enhanced_default_loading() {
    log_debug "Testing enhanced default behavior module loading"
    
    # Source the enhanced default behavior module
    if source "$SCRIPT_DIR/../core/enhanced-default-behavior.zsh"; then
        # Check if key functions are available
        if command -v run_enhanced_default_behavior >/dev/null 2>&1; then
            return 0
        else
            log_error "run_enhanced_default_behavior function not found"
            return 1
        fi
    else
        log_error "Failed to source enhanced-default-behavior.zsh"
        return 1
    fi
}

# Test 4: Card State Detection
test_card_state_detection() {
    log_debug "Testing card state detection"
    
    # Create a temporary test directory structure
    local test_dir=$(mktemp -d)
    local version_file="$test_dir/MISC/version.txt"
    
    # Create test directory structure
    mkdir -p "$test_dir/MISC"
    
    # Create a mock version.txt file
    cat > "$version_file" <<EOF
{
  "camera type": "HERO11 Black",
  "camera serial number": "C3471325208909",
  "firmware version": "H22.01.01.10.70"
}
EOF
    
    # Test state detection for new card
    local state=$(determine_card_state "$test_dir")
    if [[ "$state" == "new" ]]; then
        # Create a marker file and test again
        touch "$test_dir/.goprox.archived"
        local state2=$(determine_card_state "$test_dir")
        if [[ "$state2" == "archived" ]]; then
            # Cleanup
            rm -rf "$test_dir"
            return 0
        else
            log_error "State detection failed for archived card: $state2"
            rm -rf "$test_dir"
            return 1
        fi
    else
        log_error "State detection failed for new card: $state"
        rm -rf "$test_dir"
        return 1
    fi
}

# Test 5: Content Analysis
test_content_analysis() {
    log_debug "Testing content analysis"
    
    # Create a temporary test directory
    local test_dir=$(mktemp -d)
    
    # Create some test files
    touch "$test_dir/test1.JPG"
    touch "$test_dir/test2.MP4"
    touch "$test_dir/test3.LRV"
    touch "$test_dir/test4.THM"
    
    # Test content analysis
    local analysis=$(analyze_media_content "$test_dir")
    
    # Validate JSON structure
    if echo "$analysis" | jq . >/dev/null 2>&1; then
        # Check if expected fields are present
        local total_files=$(echo "$analysis" | jq -r '.total_files')
        local jpg_count=$(echo "$analysis" | jq -r '.jpg_count')
        local mp4_count=$(echo "$analysis" | jq -r '.mp4_count')
        
        if [[ "$total_files" == "4" && "$jpg_count" == "1" && "$mp4_count" == "1" ]]; then
            # Cleanup
            rm -rf "$test_dir"
            return 0
        else
            log_error "Content analysis returned unexpected values: total=$total_files, jpg=$jpg_count, mp4=$mp4_count"
            rm -rf "$test_dir"
            return 1
        fi
    else
        log_error "Content analysis returned invalid JSON"
        rm -rf "$test_dir"
        return 1
    fi
}

# Test 6: Workflow Analysis
test_workflow_analysis() {
    log_debug "Testing workflow analysis"
    
    # Create mock detected cards JSON
    local mock_cards='[
      {
        "volume_name": "HERO11-8909",
        "volume_path": "/Volumes/HERO11-8909",
        "camera_type": "HERO11 Black",
        "serial_number": "C3471325208909",
        "firmware_version": "H22.01.01.10.70",
        "firmware_type": "labs",
        "state": "new",
        "content": {
          "total_files": 10,
          "jpg_count": 5,
          "mp4_count": 5,
          "lrv_count": 0,
          "thm_count": 0,
          "content_state": "few_files",
          "has_firmware_update": false
        }
      }
    ]'
    
    # Test workflow analysis
    local workflow_plan=$(analyze_workflow_requirements "$mock_cards")
    
    # Validate JSON structure
    if echo "$workflow_plan" | jq . >/dev/null 2>&1; then
        # Check if expected fields are present
        local workflow_type=$(echo "$workflow_plan" | jq -r '.workflow_type')
        local card_count=$(echo "$workflow_plan" | jq -r '.card_count')
        
        if [[ "$workflow_type" == "full_processing" && "$card_count" == "1" ]]; then
            return 0
        else
            log_error "Workflow analysis returned unexpected values: type=$workflow_type, count=$card_count"
            return 1
        fi
    else
        log_error "Workflow analysis returned invalid JSON"
        return 1
    fi
}

# Test 7: No Cards Scenario
test_no_cards_scenario() {
    log_debug "Testing no cards scenario"
    
    # Test with empty cards array
    local empty_cards="[]"
    local workflow_plan=$(analyze_workflow_requirements "$empty_cards")
    
    if [[ "$workflow_plan" == "none" ]]; then
        return 0
    else
        log_error "No cards scenario should return 'none', got: $workflow_plan"
        return 1
    fi
}

# Main test execution
main() {
    log_info "Starting $TEST_NAME v$TEST_VERSION"
    echo "🧪 $TEST_NAME v$TEST_VERSION"
    echo "=================================="
    echo
    
    # Run all tests
    run_test "Smart Detection Module Loading" test_smart_detection_loading
    run_test "Decision Matrix Module Loading" test_decision_matrix_loading
    run_test "Enhanced Default Behavior Module Loading" test_enhanced_default_loading
    run_test "Card State Detection" test_card_state_detection
    run_test "Content Analysis" test_content_analysis
    run_test "Workflow Analysis" test_workflow_analysis
    run_test "No Cards Scenario" test_no_cards_scenario
    
    # Display results
    echo
    echo "📊 Test Results Summary"
    echo "======================="
    echo "Total tests: $total_tests"
    echo "Passed: $passed_tests"
    echo "Failed: $failed_tests"
    echo
    
    # Display detailed results
    for test_name in "${!test_results[@]}"; do
        local result="${test_results[$test_name]}"
        if [[ "$result" == "PASS" ]]; then
            echo "✅ $test_name: PASS"
        else
            echo "❌ $test_name: FAIL"
        fi
    done
    
    echo
    
    # Exit with appropriate code
    if [[ $failed_tests -eq 0 ]]; then
        log_success "All tests passed!"
        echo "🎉 All tests passed!"
        exit 0
    else
        log_error "$failed_tests test(s) failed"
        echo "💥 $failed_tests test(s) failed"
        exit 1
    fi
}

# Run main function
main "$@" 