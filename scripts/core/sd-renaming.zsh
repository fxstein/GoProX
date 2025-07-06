#!/bin/zsh

# GoProX SD Card Renaming Module
# This module handles automatic renaming of GoPro SD cards based on configuration

# Function to check if SD card renaming is enabled
is_sd_renaming_enabled() {
    is_config_enabled "sd_card_naming.auto_rename"
}

# Function to analyze SD card naming requirements
analyze_sd_naming_requirements() {
    local detected_cards="$1"
    local dry_run="${2:-false}"
    
    log_info "Analyzing SD card naming requirements"
    
    if [[ -z "$detected_cards" ]]; then
        log_info "No cards detected for naming analysis"
        echo "[]"
        return 0
    fi
    
    # Check if renaming is enabled
    if ! is_sd_renaming_enabled; then
        log_info "SD card renaming is disabled in configuration"
        echo "[]"
        return 0
    fi
    
    local card_count=$(echo "$detected_cards" | jq length 2>/dev/null || echo "0")
    local naming_actions=()
    
    for i in $(seq 0 $((card_count - 1))); do
        local card_info=$(echo "$detected_cards" | jq ".[$i]")
        local volume_name=$(echo "$card_info" | jq -r '.volume_name')
        local camera_type=$(echo "$card_info" | jq -r '.camera_type')
        local serial_number=$(echo "$card_info" | jq -r '.serial_number')
        local firmware_version=$(echo "$card_info" | jq -r '.firmware_version')
        local firmware_type=$(echo "$card_info" | jq -r '.firmware_type')
        
        # Generate expected name based on configuration
        local expected_name=$(generate_sd_card_name "$camera_type" "$serial_number" "$firmware_version" "$firmware_type")
        
        # Check if renaming is needed
        if [[ "$volume_name" != "$expected_name" ]]; then
            local naming_action=$(cat <<EOF
{
  "volume_name": "$volume_name",
  "expected_name": "$expected_name",
  "camera_type": "$camera_type",
  "serial_number": "$serial_number",
  "firmware_version": "$firmware_version",
  "firmware_type": "$firmware_type",
  "action": "rename",
  "reason": "Name does not match configured format"
}
EOF
)
            naming_actions+=("$naming_action")
            log_debug "Naming action required: $volume_name -> $expected_name"
        else
            log_debug "No renaming needed for: $volume_name"
        fi
    done
    
    # Return as JSON array
    local actions_json="[]"
    if (( ${#naming_actions[@]} > 0 )); then
        actions_json="["
        local first=true
        for action in "${naming_actions[@]}"; do
            if [[ "$first" == true ]]; then
                first=false
            else
                actions_json+=","
            fi
            actions_json+="$action"
        done
        actions_json+="]"
    fi
    
    echo "$actions_json"
}

# Function to execute SD card renaming
execute_sd_renaming() {
    local naming_actions="$1"
    local dry_run="${2:-false}"
    
    log_info "Executing SD card renaming operations"
    
    if [[ -z "$naming_actions" ]] || [[ "$naming_actions" == "[]" ]]; then
        log_info "No renaming actions required"
        return 0
    fi
    
    local action_count=$(echo "$naming_actions" | jq length)
    local success_count=0
    local error_count=0
    
    for i in $(seq 0 $((action_count - 1))); do
        local action=$(echo "$naming_actions" | jq ".[$i]")
        local volume_name=$(echo "$action" | jq -r '.volume_name')
        local expected_name=$(echo "$action" | jq -r '.expected_name')
        local camera_type=$(echo "$action" | jq -r '.camera_type')
        local serial_number=$(echo "$action" | jq -r '.serial_number')
        
        log_info "Processing rename: $volume_name -> $expected_name"
        
        if [[ "$dry_run" == "true" ]]; then
            echo "[DRY RUN] Would rename: $volume_name -> $expected_name"
            echo "  Camera: $camera_type (Serial: $serial_number)"
            success_count=$((success_count + 1))
        else
            if rename_sd_card_volume "$volume_name" "$expected_name"; then
                log_success "Successfully renamed: $volume_name -> $expected_name"
                success_count=$((success_count + 1))
            else
                log_error "Failed to rename: $volume_name -> $expected_name"
                error_count=$((error_count + 1))
            fi
        fi
    done
    
    log_info "SD card renaming completed: $success_count successful, $error_count failed"
    return $error_count
}

# Function to rename a single SD card volume
rename_sd_card_volume() {
    local volume_name="$1"
    local new_name="$2"
    local volume_path="/Volumes/$volume_name"
    
    log_debug "Renaming volume: $volume_name -> $new_name"
    
    # Check if volume exists and is mounted
    if [[ ! -d "$volume_path" ]]; then
        log_error "Volume '$volume_name' is not mounted"
        return 1
    fi
    
    # Check if new name already exists
    if [[ -d "/Volumes/$new_name" ]]; then
        log_error "Volume name '$new_name' already exists"
        return 1
    fi
    
    # Get the device identifier for the volume
    local device_id=$(diskutil info "$volume_path" | grep "Device Identifier" | awk '{print $3}')
    if [[ -z "$device_id" ]]; then
        log_error "Could not determine device identifier for volume: $volume_name"
        return 1
    fi
    
    log_debug "Device identifier: $device_id"
    
    # Use diskutil to rename the volume
    if diskutil rename "$device_id" "$new_name"; then
        log_success "Successfully renamed '$volume_name' to '$new_name'"
        return 0
    else
        log_error "Failed to rename volume '$volume_name' to '$new_name'"
        return 1
    fi
}

# Function to validate SD card naming configuration
validate_sd_naming_config() {
    log_debug "Validating SD card naming configuration"
    
    # Check if renaming is enabled
    if ! is_sd_renaming_enabled; then
        log_info "SD card renaming is disabled"
        return 0
    fi
    
    # Validate naming format
    local format=$(get_config_value "sd_card_naming.format")
    if [[ -z "$format" ]]; then
        log_error "SD card naming format is not configured"
        return 1
    fi
    
    # Check for required placeholders
    local required_placeholders=("{camera_type}" "{serial_short}")
    for placeholder in "${required_placeholders[@]}"; do
        if [[ "$format" != *"$placeholder"* ]]; then
            log_warning "Naming format does not include required placeholder: $placeholder"
        fi
    done
    
    log_debug "SD card naming configuration validation passed"
    return 0
}

# Function to show SD card naming information
show_sd_naming_info() {
    local detected_cards="$1"
    
    echo "SD Card Naming Analysis:"
    echo "======================="
    
    # Show configuration
    local auto_rename=$(is_config_enabled "sd_card_naming.auto_rename" && echo "Enabled" || echo "Disabled")
    local format=$(get_config_value "sd_card_naming.format")
    echo "Auto Rename: $auto_rename"
    echo "Naming Format: $format"
    echo
    
    if [[ -z "$detected_cards" ]] || [[ "$detected_cards" == "[]" ]]; then
        echo "No GoPro SD cards detected"
        return 0
    fi
    
    local card_count=$(echo "$detected_cards" | jq length)
    echo "Detected Cards ($card_count):"
    
    for i in $(seq 0 $((card_count - 1))); do
        local card_info=$(echo "$detected_cards" | jq ".[$i]")
        local volume_name=$(echo "$card_info" | jq -r '.volume_name')
        local camera_type=$(echo "$card_info" | jq -r '.camera_type')
        local serial_number=$(echo "$card_info" | jq -r '.serial_number')
        local firmware_version=$(echo "$card_info" | jq -r '.firmware_version')
        local firmware_type=$(echo "$card_info" | jq -r '.firmware_type')
        
        # Generate expected name
        local expected_name=$(generate_sd_card_name "$camera_type" "$serial_number" "$firmware_version" "$firmware_type")
        
        echo "  $volume_name:"
        echo "    Camera: $camera_type"
        echo "    Serial: $serial_number"
        echo "    Firmware: $firmware_version ($firmware_type)"
        echo "    Expected Name: $expected_name"
        
        if [[ "$volume_name" != "$expected_name" ]]; then
            echo "    Status: ⚠️  Renaming required"
        else
            echo "    Status: ✅ Correctly named"
        fi
        echo
    done
}

# Function to test naming format with sample data
test_naming_format() {
    local camera_type="${1:-HERO11 Black}"
    local serial_number="${2:-C1234567890123}"
    local firmware_version="${3:-v2.00}"
    local firmware_type="${4:-official}"
    
    echo "Testing SD Card Naming Format:"
    echo "=============================="
    echo "Sample Data:"
    echo "  Camera Type: $camera_type"
    echo "  Serial Number: $serial_number"
    echo "  Firmware Version: $firmware_version"
    echo "  Firmware Type: $firmware_type"
    echo
    
    local expected_name=$(generate_sd_card_name "$camera_type" "$serial_number" "$firmware_version" "$firmware_type")
    echo "Generated Name: $expected_name"
    echo
    
    # Show configuration details
    local naming_config=($(get_sd_naming_config))
    echo "Configuration:"
    echo "  Format: ${naming_config[format]}"
    echo "  Clean Camera Type: ${naming_config[clean_camera_type]}"
    echo "  Remove Words: ${naming_config[remove_words]}"
    echo "  Space Replacement: ${naming_config[space_replacement]}"
    echo "  Remove Special Chars: ${naming_config[remove_special_chars]}"
    echo "  Allowed Chars: ${naming_config[allowed_chars]}"
} 