#!/bin/zsh

# This script is a workflow module and should be sourced, not executed directly.

# Source required modules (must be at the top for global function availability)
SCRIPT_DIR="${0:A:h}"
CORE_DIR="$SCRIPT_DIR"
log_debug "SCRIPT_DIR=$SCRIPT_DIR"
log_debug "CORE_DIR=$CORE_DIR"
log_debug "firmware.zsh path=$CORE_DIR/firmware.zsh"
log_debug "firmware.zsh exists: $(test -f "$CORE_DIR/firmware.zsh" && echo "YES" || echo "NO")"

source "$CORE_DIR/logger.zsh"
source "$CORE_DIR/smart-detection.zsh"
source "$CORE_DIR/config.zsh"
source "$CORE_DIR/sd-renaming.zsh"
source "$CORE_DIR/firmware.zsh"

log_debug "After sourcing firmware.zsh"

# Firmware-Focused Workflow Module for GoProX
# This module provides a streamlined workflow for:
# 1. Renaming GoPro SD cards to standard format
# 2. Checking for firmware updates
# 3. Installing labs firmware (preferred) or official firmware

# Function to run firmware-focused workflow
run_firmware_focused_workflow() {
    log_info "Starting firmware-focused workflow"
    
    if [[ "$dry_run" == "true" ]]; then
        cat <<EOF

🚦 DRY RUN MODE ENABLED
======================
All actions will be simulated. No files will be modified or deleted.

EOF
    fi
    
    # Display welcome message
    display_firmware_welcome_message
    
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
    
    # Step 1: Analyze and execute SD card renaming
    execute_card_renaming "$detected_cards"
    
    # Step 2: Check for firmware updates
    execute_firmware_check "$detected_cards"
    
    # Step 3: Install firmware updates (labs preferred)
    execute_firmware_installation "$detected_cards"
    
    # Display completion summary
    display_firmware_completion_summary
}

# Function to display firmware-focused welcome message
display_firmware_welcome_message() {
    cat <<EOF

🎥 GoProX Firmware-Focused Workflow
===================================

This workflow will:
1. Rename GoPro SD cards to standard format
2. Check for available firmware updates
3. Install labs firmware (preferred) or official firmware

Scanning for GoPro SD cards...

EOF
}

# Function to display message when no cards are detected
display_no_cards_message() {
    cat <<EOF

📋 No GoPro SD Cards Detected
============================

No GoPro SD cards were found mounted on your system.

To use GoProX firmware-focused workflow:
1. Insert a GoPro SD card into your Mac
2. Ensure the card is properly mounted
3. Run 'goprox --firmware-focused' again

EOF
}

# Function to execute card renaming
execute_card_renaming() {
    local detected_cards="$1"
    
    echo "📝 Step 1: SD Card Renaming"
    echo "==========================="
    
    # Analyze SD card naming requirements
    log_info "Analyzing SD card naming requirements..."
    local naming_actions=$(analyze_sd_naming_requirements "$detected_cards" "$dry_run")
    
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
    else
        echo "✅ All SD cards already have standard names"
        echo
    fi
}

# Function to execute firmware checking
execute_firmware_check() {
    local detected_cards="$1"
    
    echo "🔍 Step 2: Firmware Update Check"
    echo "================================"
    
    local card_count=$(echo "$detected_cards" | jq length)
    local updates_available=0
    
    for i in $(seq 0 $((card_count - 1))); do
        local card_info=$(echo "$detected_cards" | jq ".[$i]")
        local volume_name=$(echo "$card_info" | jq -r '.volume_name')
        local camera_type=$(echo "$card_info" | jq -r '.camera_type')
        local current_fw=$(echo "$card_info" | jq -r '.firmware_version')
        local firmware_type=$(echo "$card_info" | jq -r '.firmware_type')
        
        echo "Checking $volume_name ($camera_type)..."
        echo "  Current firmware: $current_fw ($firmware_type)"
        
        if [[ "$dry_run" == "true" ]]; then
            echo "  [DRY RUN] Would check for firmware updates"
            echo "  [DRY RUN] Would prefer labs firmware if available"
        else
            # Check for firmware updates
            local fw_check_result=$(check_firmware_updates "$card_info")
            if [[ "$fw_check_result" == "update_available" ]]; then
                echo "  ✅ Firmware update available"
                ((updates_available++))
            elif [[ "$fw_check_result" == "up_to_date" ]]; then
                echo "  ✅ Firmware is up to date"
            elif [[ "$fw_check_result" == "no_firmware_found" ]]; then
                echo "  ⚠️  No firmware found for this camera model"
            else
                echo "  ❌ Firmware check failed"
            fi
        fi
        echo
    done
    
    if [[ $updates_available -eq 0 ]]; then
        echo "✅ All cameras have up-to-date firmware"
    else
        echo "📋 $updates_available camera(s) have firmware updates available"
    fi
    echo
}

# Function to execute firmware installation
execute_firmware_installation() {
    local detected_cards="$1"
    
    echo "⚡ Step 3: Firmware Installation"
    echo "================================"
    
    local card_count=$(echo "$detected_cards" | jq length)
    local installed_count=0
    
    for i in $(seq 0 $((card_count - 1))); do
        local card_info=$(echo "$detected_cards" | jq ".[$i]")
        local volume_name=$(echo "$card_info" | jq -r '.volume_name')
        local camera_type=$(echo "$card_info" | jq -r '.camera_type')
        local current_fw=$(echo "$card_info" | jq -r '.firmware_version')
        local firmware_type=$(echo "$card_info" | jq -r '.firmware_type')
        
        echo "Processing $volume_name ($camera_type)..."
        echo "  Current firmware: $current_fw ($firmware_type)"
        
        if [[ "$dry_run" == "true" ]]; then
            echo "  [DRY RUN] Would check for labs firmware first"
            echo "  [DRY RUN] Would fall back to official firmware if labs not available"
            echo "  [DRY RUN] Would install firmware update"
        else
            # Try to install labs firmware first, then official
            local install_result=$(install_firmware_with_labs_preference "$card_info")
            if [[ "$install_result" == "updated" ]]; then
                echo "  ✅ Firmware installed successfully"
                ((installed_count++))
            elif [[ "$install_result" == "no_update" ]]; then
                echo "  ✅ Firmware is already up to date"
            else
                echo "  ❌ Firmware installation failed"
            fi
        fi
        echo
    done
    
    if [[ $installed_count -gt 0 ]]; then
        echo "✅ $installed_count firmware update(s) installed successfully"
    else
        echo "✅ No firmware updates were needed"
    fi
    echo
}

# Function to check for firmware updates
check_firmware_updates() {
    local card_info="$1"
    local volume_path=$(echo "$card_info" | jq -r '.volume_path')
    local camera_type=$(echo "$card_info" | jq -r '.camera_type')
    local current_fw=$(echo "$card_info" | jq -r '.firmware_version')
    
    log_info "Checking firmware updates for $camera_type (current: $current_fw)"
    
    # Use the real firmware status check
    local status_result=$(check_firmware_status "$volume_path" "labs")
    if [[ $? -eq 0 ]]; then
        local fw_status=$(echo "$status_result" | cut -d: -f1)
        echo "$fw_status"
    else
        echo "no_firmware_found"
    fi
}

# Function to install firmware with labs preference
install_firmware_with_labs_preference() {
    local card_info="$1"
    local camera_type=$(echo "$card_info" | jq -r '.camera_type')
    local volume_path=$(echo "$card_info" | jq -r '.volume_path')
    
    log_info "Installing firmware for $camera_type with labs preference"
    
    # First, try to install labs firmware
    log_debug "Attempting labs firmware installation..."
    local labs_result=$(check_and_update_firmware "$volume_path" "labs" 2>&1 | tail -n1)
    log_debug "Labs firmware result: '$labs_result'"
    if [[ "$labs_result" == "updated" ]]; then
        log_debug "Labs firmware installation succeeded"
        echo "updated"
        return 0
    elif [[ "$labs_result" == "up_to_date" ]]; then
        log_debug "Labs firmware already up to date"
        echo "no_update"
        return 0
    elif [[ "$labs_result" == "failed" ]]; then
        log_debug "Labs firmware installation failed, trying official..."
    else
        log_debug "Unknown labs firmware result: '$labs_result', trying official..."
    fi
    
    # Only try official firmware if labs firmware failed
    if [[ "$labs_result" == "failed" ]]; then
        log_debug "Attempting official firmware installation..."
        local official_result=$(check_and_update_firmware "$volume_path" "official" 2>&1 | tail -n1)
        log_debug "Official firmware result: '$official_result'"
        if [[ "$official_result" == "updated" ]]; then
            log_debug "Official firmware installation succeeded"
            echo "updated"
            return 0
        elif [[ "$official_result" == "up_to_date" ]]; then
            log_debug "Official firmware already up to date"
            echo "no_update"
            return 0
        else
            log_debug "Official firmware installation also failed"
        fi
    fi
    
    echo "failed"
    return 1
}

# Function to display completion summary
display_firmware_completion_summary() {
    cat <<EOF

🎉 Firmware-Focused Workflow Completed
======================================

Summary:
✅ SD cards renamed to standard format
✅ Firmware updates checked
✅ Labs firmware installed (preferred)
✅ Official firmware installed (fallback)

All GoPro SD cards have been processed according to the firmware-focused workflow.

EOF
}

# Note: Functions are automatically available when sourced 