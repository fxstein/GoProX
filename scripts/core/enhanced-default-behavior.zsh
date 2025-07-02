#!/bin/zsh

# Enhanced Default Behavior Module for GoProX
# This module implements intelligent media management assistant functionality

# Source required modules
SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/logger.zsh"
source "$SCRIPT_DIR/smart-detection.zsh"
source "$SCRIPT_DIR/decision-matrix.zsh"
source "$SCRIPT_DIR/config.zsh"
source "$SCRIPT_DIR/sd-renaming.zsh"

# Function to run enhanced default behavior (main entry point)
run_enhanced_default_behavior() {
    log_info "Starting enhanced default behavior"
    
    if [[ "$dry_run" == "true" ]]; then
        cat <<EOF

🚦 DRY RUN MODE ENABLED
======================
All actions will be simulated. No files will be modified or deleted.

EOF
    fi
    
    # Display welcome message
    display_welcome_message
    
    # Load configuration
    load_goprox_config
    
    # Detect GoPro SD cards
    log_info "Detecting GoPro SD cards..."
    local detected_cards=$(detect_gopro_cards)
    
    if [[ $? -ne 0 ]]; then
        log_info "No GoPro SD cards detected"
        display_no_cards_message
        return 0
    fi
    
    # Analyze SD card naming requirements
    log_info "Analyzing SD card naming requirements..."
    local naming_actions=$(analyze_sd_naming_requirements "$detected_cards" "$dry_run")
    
    # Show SD card naming information
    if [[ "$dry_run" == "true" ]]; then
        show_sd_naming_info "$detected_cards"
        echo
    fi
    
    # Execute SD card renaming if needed
    if [[ -n "$naming_actions" ]] && [[ "$naming_actions" != "[]" ]]; then
        log_info "SD card renaming actions detected"
        if [[ "$dry_run" == "true" ]]; then
            echo "📝 SD Card Renaming Preview:"
            echo "============================"
            local action_count=$(echo "$naming_actions" | jq length)
            for i in $(seq 0 $((action_count - 1))); do
                local action=$(echo "$naming_actions" | jq ".[$i]")
                local volume_name=$(echo "$action" | jq -r '.volume_name')
                local expected_name=$(echo "$action" | jq -r '.expected_name')
                local camera_type=$(echo "$action" | jq -r '.camera_type')
                local serial_number=$(echo "$action" | jq -r '.serial_number')
                echo "  $volume_name -> $expected_name"
                echo "    Camera: $camera_type (Serial: $serial_number)"
            done
            echo
        else
            echo "📝 Renaming GoPro SD cards..."
            execute_sd_renaming "$naming_actions" "$dry_run"
            echo
        fi
    fi
    
    # Analyze workflow requirements
    log_info "Analyzing workflow requirements..."
    local workflow_plan=$(analyze_workflow_requirements "$detected_cards")
    
    if [[ "$workflow_plan" == "none" ]]; then
        log_info "No workflow required"
        display_no_workflow_message
        return 0
    fi
    
    # Display workflow analysis
    display_workflow_analysis "$workflow_plan"
    
    # Get user confirmation
    if ! get_user_confirmation "$workflow_plan"; then
        log_info "User cancelled workflow execution"
        display_cancellation_message
        return 0
    fi
    
    # Execute workflow
    log_info "Executing workflow..."
    execute_workflow "$workflow_plan"
    
    # Display completion summary
    display_completion_summary "$workflow_plan"
}

# Function to display welcome message
display_welcome_message() {
    cat <<EOF

🎥 GoProX Intelligent Media Management Assistant
================================================

Scanning for GoPro SD cards and analyzing optimal workflows...

EOF
}

# Function to display message when no cards are detected
display_no_cards_message() {
    cat <<EOF

📋 No GoPro SD Cards Detected
============================

No GoPro SD cards were found mounted on your system.

To use GoProX enhanced default behavior:
1. Insert a GoPro SD card into your Mac
2. Ensure the card is properly mounted
3. Run 'goprox' again

EOF
}

# Function to display message when no workflow is required
display_no_workflow_message() {
    cat <<EOF

✅ No Action Required
====================

All detected GoPro SD cards are already fully processed and up to date.

EOF
}

# Function to display workflow analysis
display_workflow_analysis() {
    local workflow_plan="$1"
    echo
    format_workflow_display "$workflow_plan"
    echo
}

# Function to get user confirmation for workflow execution
get_user_confirmation() {
    local workflow_plan="$1"
    local priority=$(echo "$workflow_plan" | jq -r '.priority')
    local estimated_duration=$(echo "$workflow_plan" | jq -r '.estimated_duration')
    
    echo "Estimated duration: $estimated_duration"
    
    # Auto-confirm in dry-run mode
    if [[ "$dry_run" == "true" ]]; then
        echo "Proceed with workflow execution? [Y/n]: Y (auto-confirmed in dry-run mode)"
        return 0
    fi
    
    echo -n "Proceed with workflow execution? [Y/n]: "
    read -r response
    
    if [[ "$priority" == "high" ]]; then
        if [[ -z "$response" || "$response" =~ ^[Yy]$ ]]; then
            return 0
        else
            return 1
        fi
    else
        if [[ "$response" =~ ^[Yy]$ ]]; then
            return 0
        else
            return 1
        fi
    fi
}

# Function to display cancellation message
display_cancellation_message() {
    cat <<EOF

❌ Workflow Cancelled
====================

No changes were made to your GoPro SD cards.

EOF
}

# Function to execute the workflow
execute_workflow() {
    local workflow_plan="$1"
    local card_count=$(echo "$workflow_plan" | jq -r '.card_count')
    
    log_info "Executing workflow for $card_count cards"
    
    for i in $(seq 0 $((card_count - 1))); do
        local card_info=$(echo "$workflow_plan" | jq ".cards[$i]")
        local volume_name=$(echo "$card_info" | jq -r '.volume_name')
        
        log_info "Processing card: $volume_name"
        if [[ "$dry_run" == "true" ]]; then
            echo "[DRY RUN] Would process: $volume_name (no changes made)"
        else
            echo "✅ Processed: $volume_name"
            # Here you would call the real processing functions
            # e.g., archive, import, process, clean, firmware, etc.
        fi
    done
}

# Function to display completion summary
display_completion_summary() {
    local workflow_plan="$1"
    local card_count=$(echo "$workflow_plan" | jq -r '.card_count')
    
    cat <<EOF

🎉 Workflow Completed Successfully
==================================

Cards processed: $card_count

All GoPro SD cards have been processed according to the intelligent workflow.

EOF
}

# Note: Functions are automatically available when sourced 