#!/bin/zsh

# Smart Detection Module for GoProX Enhanced Default Behavior
# This module provides intelligent GoPro SD card detection and analysis

# Source the logger module
SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/logger.zsh"

# Function to detect all GoPro SD cards mounted on the system
detect_gopro_cards() {
    log_info "Starting GoPro SD card detection"
    
    local detected_cards=()
    local found_gopro=false
    
    # Scan all mounted volumes
    for volume in /Volumes/*; do
        if [[ -d "$volume" ]] && [[ "$(basename "$volume")" != "." ]] && [[ "$(basename "$volume")" != ".." ]]; then
            local volume_name=$(basename "$volume")
            
            # Skip system volumes
            if [[ "$volume_name" == "Macintosh HD" ]] || [[ "$volume_name" == ".timemachine" ]] || [[ "$volume_name" == "Time Machine" ]]; then
                continue
            fi
            
            # Check if this is a GoPro SD card
            local version_file="$volume/MISC/version.txt"
            if [[ -f "$version_file" ]] && grep -q "camera type" "$version_file"; then
                found_gopro=true
                log_info "Found GoPro SD card: $volume_name"
                
                # Extract card information
                local card_info=$(extract_card_info "$volume" "$volume_name")
                detected_cards+=("$card_info")
            fi
        fi
    done
    
    if [[ "$found_gopro" == false ]]; then
        log_info "No GoPro SD cards found during scan"
        return 1
    fi
    
    # Return detected cards as JSON array
    local json_array="["
    local first=true
    for card in "${detected_cards[@]}"; do
        if [[ "$first" == true ]]; then
            first=false
        else
            json_array+=","
        fi
        json_array+="$card"
    done
    json_array+="]"
    
    echo "$json_array"
    return 0
}

# Function to extract detailed information from a GoPro SD card
extract_card_info() {
    local volume_path="$1"
    local volume_name="$2"
    local version_file="$volume_path/MISC/version.txt"
    
    log_debug "Extracting card info from: $volume_path"
    
    # Extract basic camera information
    local camera_type=$(grep "camera type" "$version_file" | cut -d'"' -f4)
    local serial_number=$(grep "camera serial number" "$version_file" | cut -d'"' -f4)
    local firmware_version=$(grep "firmware version" "$version_file" | cut -d'"' -f4)
    
    # Determine firmware type (official vs labs)
    local firmware_type="official"
    if [[ "$firmware_version" =~ \.7[0-9]$ ]]; then
        firmware_type="labs"
    fi
    
    # Analyze media content
    local content_analysis=$(analyze_media_content "$volume_path")
    
    # Check for existing processed markers
    local state=$(determine_card_state "$volume_path")
    
    # Create structured card information
    local card_info=$(cat <<EOF
{
  "volume_name": "$volume_name",
  "volume_path": "$volume_path",
  "camera_type": "$camera_type",
  "serial_number": "$serial_number",
  "firmware_version": "$firmware_version",
  "firmware_type": "$firmware_type",
  "state": "$state",
  "content": $content_analysis
}
EOF
)
    
    echo "$card_info"
}

# Function to analyze media content on the SD card
analyze_media_content() {
    local volume_path="$1"
    
    log_debug "Analyzing media content in: $volume_path"
    
    # Count media files by type
            local jpg_count=$(find "$volume_path" -name "*.JPG" -o -name "*.jpg" 2>/dev/null | wc -l | tr -d ' ')
        local mp4_count=$(find "$volume_path" -name "*.MP4" -o -name "*.mp4" 2>/dev/null | wc -l | tr -d ' ')
        local lrv_count=$(find "$volume_path" -name "*.LRV" -o -name "*.lrv" 2>/dev/null | wc -l | tr -d ' ')
        local thm_count=$(find "$volume_path" -name "*.THM" -o -name "*.thm" 2>/dev/null | wc -l | tr -d ' ')
    
    # Calculate total file count
    local total_files=$((jpg_count + mp4_count + lrv_count + thm_count))
    
    # Determine card state based on content
    local content_state="empty"
    if [[ $total_files -gt 0 ]]; then
        if [[ $total_files -lt 10 ]]; then
            content_state="few_files"
        elif [[ $total_files -lt 100 ]]; then
            content_state="moderate"
        else
            content_state="full"
        fi
    fi
    
    # Check for firmware update files
    local has_firmware_update=false
    if [[ -d "$volume_path/UPDATE" ]] || [[ -f "$volume_path/UPDATE.zip" ]]; then
        has_firmware_update=true
    fi
    
    # Create content analysis JSON
    local content_analysis=$(cat <<EOF
{
  "total_files": $total_files,
  "jpg_count": $jpg_count,
  "mp4_count": $mp4_count,
  "lrv_count": $lrv_count,
  "thm_count": $thm_count,
  "content_state": "$content_state",
  "has_firmware_update": $has_firmware_update
}
EOF
)
    
    echo "$content_analysis"
}

# Function to determine the current state of the SD card
determine_card_state() {
    local volume_path="$1"
    
    log_debug "Determining card state for: $volume_path"
    
    # Check for processing markers
    local has_archived_marker=false
    local has_imported_marker=false
    local has_cleaned_marker=false
    local has_fwchecked_marker=false
    
    if [[ -f "$volume_path/.goprox.archived" ]]; then
        has_archived_marker=true
    fi
    
    if [[ -f "$volume_path/.goprox.imported" ]]; then
        has_imported_marker=true
    fi
    
    if [[ -f "$volume_path/.goprox.cleaned" ]]; then
        has_cleaned_marker=true
    fi
    
    if [[ -f "$volume_path/.goprox.fwchecked" ]]; then
        has_fwchecked_marker=true
    fi
    
    # Determine state based on markers
    if [[ "$has_cleaned_marker" == true ]]; then
        echo "cleaned"
    elif [[ "$has_imported_marker" == true ]]; then
        echo "imported"
    elif [[ "$has_archived_marker" == true ]]; then
        echo "archived"
    elif [[ "$has_fwchecked_marker" == true ]]; then
        echo "firmware_checked"
    else
        echo "new"
    fi
}

# Function to check if firmware update is available
check_firmware_update() {
    local camera_type="$1"
    local current_firmware="$2"
    local firmware_type="$3"
    
    log_debug "Checking firmware update for: $camera_type ($current_firmware, $firmware_type)"
    
    # This is a placeholder - actual firmware checking logic will be implemented
    # when the firmware management system is enhanced
    echo "false"
}

# Function to validate card information
validate_card_info() {
    local card_info="$1"
    
    # Basic validation - check if required fields are present
    if [[ -z "$card_info" ]]; then
        log_error "Card info is empty"
        return 1
    fi
    
    # Validate JSON structure (basic check)
    if ! echo "$card_info" | jq . >/dev/null 2>&1; then
        log_error "Invalid JSON structure in card info"
        return 1
    fi
    
    # Check required fields
    local required_fields=("volume_name" "camera_type" "serial_number" "firmware_version")
    for field in "${required_fields[@]}"; do
        if ! echo "$card_info" | jq -e ".$field" >/dev/null 2>&1; then
            log_error "Missing required field: $field"
            return 1
        fi
    done
    
    log_debug "Card info validation passed"
    return 0
}

# Function to format card information for display
format_card_display() {
    local card_info="$1"
    
    local volume_name=$(echo "$card_info" | jq -r '.volume_name')
    local camera_type=$(echo "$card_info" | jq -r '.camera_type')
    local serial_number=$(echo "$card_info" | jq -r '.serial_number')
    local firmware_version=$(echo "$card_info" | jq -r '.firmware_version')
    local firmware_type=$(echo "$card_info" | jq -r '.firmware_type')
    local state=$(echo "$card_info" | jq -r '.state')
    local total_files=$(echo "$card_info" | jq -r '.content.total_files')
    
    cat <<EOF
Found GoPro SD card: $volume_name
  Camera type: $camera_type
  Serial number: $serial_number
  Firmware version: $firmware_version
  Firmware type: $firmware_type
  Card state: $state
  Media files: $total_files
EOF
}

# Export functions for use in other modules
export -f detect_gopro_cards
export -f extract_card_info
export -f analyze_media_content
export -f determine_card_state
export -f check_firmware_update
export -f validate_card_info
export -f format_card_display 