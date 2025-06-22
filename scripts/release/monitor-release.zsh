#!/bin/zsh

# --- DEBUG OUTPUT TEST ---
if [[ "$1" == "--test-output" ]]; then
    TEST_SUMMARY=$'╔══════════════════════╗\n'
    TEST_SUMMARY+=$'║  TEST SUMMARY BLOCK  ║\n'
    TEST_SUMMARY+=$'╚══════════════════════╝\n'
    echo "ECHO TEST BLOCK:"
    echo "$TEST_SUMMARY"
    printf "PRINTF TEST BLOCK:\n"
    printf "$TEST_SUMMARY"
    exit 0
fi

# GoProX Release Monitor
# Monitors the release workflow in real-time and generates a summary

set -e

# Initialize summary variables
SUMMARY_STATUS=""
SUMMARY_DURATION=""
SUMMARY_ISSUES=""
SUMMARY_NEXT_STEPS=""

show_usage() {
    echo "Usage: $0 [<version>]"
    echo "  <version>   Optional. Monitor the workflow for the specified release version (e.g., 01.00.07)."
    echo "              If omitted, monitors the latest workflow run."
    echo "  --test-output   Show test output formatting."
}

# Function to print plain output
print_status() {
    local _color=$1  # ignored
    local message=$2
    echo "[$(date '+%H:%M:%S')] ${message}" >&2
}

# Function to check if gh CLI is available
check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        echo "Error: GitHub CLI (gh) is not installed. Please install it first: https://cli.github.com/" >&2
        exit 1
    fi
    
    if ! gh auth status &> /dev/null; then
        echo "Error: Not authenticated with GitHub CLI. Please run: gh auth login" >&2
        exit 1
    fi
}

# Function to get workflow ID for a specific version (if provided)
get_workflow_id() {
    local workflow_name="Automated Release Process"
    local version="$1"
    local workflow_id=""
    if [[ -n "$version" ]]; then
        print_status "" "Searching for workflow run for version '$version'..."
        # Search for workflow runs and find one with the version in the title or release notes
        workflow_id=$(gh run list --workflow="$workflow_name" --json databaseId,displayTitle,headSha,headBranch,status,conclusion --limit 20 | \
            jq -r --arg v "$version" '.[] | select(.displayTitle | test($v)) | .databaseId' | head -n1)
        if [[ -z "$workflow_id" ]]; then
            echo "Error: No workflow run found for version '$version'." >&2
            exit 1
        fi
    else
        print_status "" "Searching for latest '$workflow_name' workflow..."
        workflow_id=$(gh run list --workflow="$workflow_name" --limit=1 --json databaseId --jq '.[0].databaseId' 2>/dev/null)
        if [[ -z "$workflow_id" || "$workflow_id" == "null" ]]; then
            echo "Error: No recent '$workflow_name' workflow found. Make sure the workflow has been triggered recently." >&2
            exit 1
        fi
    fi
    echo "$workflow_id"
}

# Function to get workflow status
get_workflow_status() {
    local workflow_id=$1
    gh run view "$workflow_id" --json status,conclusion,startedAt,updatedAt,headBranch,headSha,url
}

# Function to get workflow jobs
get_workflow_jobs() {
    local workflow_id=$1
    gh run view "$workflow_id" --json jobs
}

# Function to get job logs
get_job_logs() {
    local workflow_id=$1
    local job_name=$2
    gh run view "$workflow_id" --log --job="$job_name" 2>/dev/null || echo "Logs not available yet"
}

# Function to display workflow progress
display_progress() {
    local workflow_id=$1
    local workflow_data=$2
    local jobs_data=$3
    
    local wf_status=$(echo "$workflow_data" | jq -r '.status')
    local wf_conclusion=$(echo "$workflow_data" | jq -r '.conclusion // "null"')
    local started_at=$(echo "$workflow_data" | jq -r '.startedAt')
    local updated_at=$(echo "$workflow_data" | jq -r '.updatedAt')
    local branch=$(echo "$workflow_data" | jq -r '.headBranch')
    local sha=$(echo "$workflow_data" | jq -r '.headSha')
    local url=$(echo "$workflow_data" | jq -r '.url')
    
    # Calculate duration
    local start_time=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$started_at" "+%s" 2>/dev/null || date -d "$started_at" "+%s")
    local end_time=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$updated_at" "+%s" 2>/dev/null || date -d "$updated_at" "+%s")
    local duration=$((end_time - start_time))
    local duration_str=$(printf "%02d:%02d" $((duration / 60)) $((duration % 60)))
    
    # Display workflow info with better formatting
    echo ""
    echo "┌─────────────────────────────────────────────────────────────────┐"
    echo "│                   WORKFLOW STATUS                               │"
    echo "├─────────────────────────────────────────────────────────────────┤"
    echo "│ Status:    $wf_status"
    if [[ "$wf_conclusion" != "null" ]]; then
        echo "│ Conclusion: $wf_conclusion"
    fi
    echo "│ Duration:  $duration_str"
    echo "│ Branch:    $branch"
    echo "│ Commit:    ${sha:0:8}"
    echo "│ URL:       $url"
    echo "└─────────────────────────────────────────────────────────────────┘"
    
    # Display jobs status with better formatting
    echo ""
    echo "┌─────────────────────────────────────────────────────────────────┐"
    echo "│                       JOBS STATUS                               │"
    echo "├─────────────────────────────────────────────────────────────────┤"
    while read -r job_info; do
        local job_name=$(echo "$job_info" | cut -d: -f1)
        local job_status=$(echo "$job_info" | cut -d: -f2 | xargs)
        local job_conclusion=$(echo "$job_info" | cut -d: -f3 | tr -d '()' | xargs)
        
        if [[ "$job_status" == "completed" ]]; then
            if [[ "$job_conclusion" == "success" ]]; then
                print_status "" "✅ $job_name: $job_status ($job_conclusion)"
            else
                print_status "" "❌ $job_name: $job_status ($job_conclusion)"
            fi
        elif [[ "$job_status" == "in_progress" ]]; then
            print_status "" "🔄 $job_name: $job_status"
        else
            print_status "" "⏳ $job_name: $job_status"
        fi
    done < <(echo "$jobs_data" | jq -r '.jobs[] | "\(.name): \(.status) (\(.conclusion // "running"))"')
    echo "└─────────────────────────────────────────────────────────────────┘"
    
    # Store summary data
    SUMMARY_STATUS="$wf_status"
    if [[ "$wf_conclusion" != "null" ]]; then
        SUMMARY_STATUS="$wf_status ($wf_conclusion)"
    fi
    SUMMARY_DURATION="$duration_str"
}

# Function to check for issues
check_for_issues() {
    local workflow_id=$1
    local jobs_data=$2
    
    local issues=""
    
    # Check for failed jobs
    local failed_jobs=$(echo "$jobs_data" | jq -r '.jobs[] | select(.conclusion == "failure") | .name')
    if [[ -n "$failed_jobs" ]]; then
        issues+=$'❌ Failed jobs: '
        issues+="$failed_jobs"
        issues+=$'\n'
    fi
    
    # Check for cancelled jobs
    local cancelled_jobs=$(echo "$jobs_data" | jq -r '.jobs[] | select(.conclusion == "cancelled") | .name')
    if [[ -n "$cancelled_jobs" ]]; then
        issues+=$'⚠️  Cancelled jobs: '
        issues+="$cancelled_jobs"
        issues+=$'\n'
    fi
    
    # Check for skipped jobs
    local skipped_jobs=$(echo "$jobs_data" | jq -r '.jobs[] | select(.conclusion == "skipped") | .name')
    if [[ -n "$skipped_jobs" ]]; then
        issues+=$'⏭️  Skipped jobs: '
        issues+="$skipped_jobs"
        issues+=$'\n'
    fi
    
    if [[ -z "$issues" ]]; then
        issues=$'✅ No issues detected'
    fi
    
    SUMMARY_ISSUES="$issues"
}

# Function to generate next steps
generate_next_steps() {
    local workflow_data=$1
    local jobs_data=$2
    
    local wf_status=$(echo "$workflow_data" | jq -r '.status')
    local wf_conclusion=$(echo "$workflow_data" | jq -r '.conclusion // "null"')
    
    local next_steps=""
    
    if [[ "$wf_status" == "completed" ]]; then
        if [[ "$wf_conclusion" == "success" ]]; then
            next_steps=$'🎉 Release completed successfully!\n'
            next_steps+=$'\nNext steps:\n'
            next_steps+=$'• Verify the GitHub release was created\n'
            next_steps+=$'• Check Homebrew formula was updated\n'
            next_steps+=$'• Test installation: brew install fxstein/tap/goprox\n'
            next_steps+=$'• Update documentation if needed'
        else
            next_steps=$'❌ Release failed!\n'
            next_steps+=$'\nNext steps:\n'
            next_steps+=$'• Check workflow logs for detailed error information\n'
            next_steps+=$'• Fix any issues identified\n'
            next_steps+=$'• Re-run the workflow\n'
            next_steps+=$'• Check GitHub Actions status page'
        fi
    elif [[ "$wf_status" == "in_progress" ]]; then
        next_steps=$'⏳ Release in progress...\n'
        next_steps+=$'\nContinue monitoring or check back later.'
    else
        next_steps=$'⏸️  Release paused or waiting...\n'
        next_steps+=$'\nCheck GitHub Actions for more details.'
    fi
    
    SUMMARY_NEXT_STEPS="$next_steps"
}

# Function to display final summary
display_summary() {
    echo ""
    echo "┌─────────────────────────────────────────────────────────────────┐"
    echo "│                    RELEASE SUMMARY                             │"
    echo "├─────────────────────────────────────────────────────────────────┤"
    echo "│ Status:    $SUMMARY_STATUS"
    echo "│ Duration:  $SUMMARY_DURATION"
    echo "│ Issues:    $(echo "$SUMMARY_ISSUES" | tr -d '\n')"
    echo "│"
    
    # Print next steps with proper border formatting
    echo "$SUMMARY_NEXT_STEPS" | while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            echo "│ $line"
        else
            echo "│"
        fi
    done
    
    echo "└─────────────────────────────────────────────────────────────────┘"
    
    # Save summary to file in output directory
    mkdir -p output
    cat > output/release-summary.txt << EOF
RELEASE SUMMARY
===============

Status: $SUMMARY_STATUS
Duration: $SUMMARY_DURATION
Issues:
$SUMMARY_ISSUES

$SUMMARY_NEXT_STEPS

Generated: $(date)
EOF
    
    echo ""
    echo "📄 Summary saved to: output/release-summary.txt"
}

# Main monitoring function
monitor_workflow() {
    local workflow_id=$1
    local last_status=""
    local last_conclusion=""
    
    print_status $GREEN "Starting monitoring for workflow $workflow_id"
    print_status $GREEN "Press Ctrl+C to stop monitoring and show summary"
    
    while true; do
        # Get current workflow data
        local workflow_data=$(get_workflow_status "$workflow_id")
        local jobs_data=$(get_workflow_jobs "$workflow_id")
        
        local current_status=$(echo "$workflow_data" | jq -r '.status')
        local current_conclusion=$(echo "$workflow_data" | jq -r '.conclusion // "null"')
        
        # Check if status changed
        if [[ "$current_status" != "$last_status" || "$current_conclusion" != "$last_conclusion" ]]; then
            display_progress "$workflow_id" "$workflow_data" "$jobs_data"
            check_for_issues "$workflow_id" "$jobs_data"
            generate_next_steps "$workflow_data" "$jobs_data"
            
            last_status="$current_status"
            last_conclusion="$current_conclusion"
            
            # If workflow is completed, show final summary and exit
            if [[ "$current_status" == "completed" ]]; then
                display_summary
                break
            fi
        fi
        
        # Wait before next check
        sleep 10
    done
}

# Main script
main() {
    echo ""
    echo "┌─────────────────────────────────────────────────────────────────┐"
    echo "│                   GoProX Release Monitor                       │"
    echo "└─────────────────────────────────────────────────────────────────┘"
    echo ""
    
    # Wait to ensure new workflow run has started
    echo "[INFO] Waiting 15 seconds for workflow run to start..."
    sleep 15
    
    # Check prerequisites
    check_gh_cli
    
    # Always get the latest workflow ID
    local workflow_id
    workflow_id=$(get_workflow_id)
    print_status "" "Found workflow ID: $workflow_id"
    
    # Check if workflow is already completed
    local workflow_data
    local wf_status
    local conclusion
    local jobs_data
    workflow_data=$(get_workflow_status "$workflow_id")
    wf_status=$(echo "$workflow_data" | jq -r '.status')
    conclusion=$(echo "$workflow_data" | jq -r '.conclusion // "null"')
    if [[ "$wf_status" == "completed" ]]; then
        print_status "" "Workflow is already completed. Showing final summary..."
        jobs_data=$(get_workflow_jobs "$workflow_id")
        display_progress "$workflow_id" "$workflow_data" "$jobs_data"
        check_for_issues "$workflow_id" "$jobs_data"
        generate_next_steps "$workflow_data" "$jobs_data"
        display_summary
        exit 0
    fi
    # Start monitoring
    monitor_workflow "$workflow_id"
}

# Run main function
main "$@" 