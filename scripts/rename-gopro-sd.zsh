#!/bin/zsh
#
# rename-gopro-sd.zsh - Automatically rename GoPro SD card volumes
#
# MIT License
#
# Copyright (c) 2024 GoProX Contributors
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# Description: Automatically rename GoPro SD card volumes based on camera type and serial number
# Usage: ./rename-gopro-sd.zsh [volume_name]
#        If no volume name is provided, will scan all mounted volumes for GoPro SD cards

set -e

# Setup logging
export LOGFILE="output/rename-gopro-sd.log"
mkdir -p "$(dirname "$LOGFILE")"
source "$(dirname $0)/core/logger.zsh"

log_time_start

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output (for user interaction)
print_status() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

# Function to detect and rename GoPro SD cards
rename_gopro_sd() {
    local volume_name="$1"
    local volume_path="/Volumes/$volume_name"
    local version_file="$volume_path/MISC/version.txt"
    
    log_info "Processing volume: $volume_name"
    
    # Check if volume exists and is mounted
    if [[ ! -d "$volume_path" ]]; then
        print_status $RED "Error: Volume '$volume_name' is not mounted"
        log_error "Volume '$volume_name' is not mounted"
        return 1
    fi
    
    # Check if this is a GoPro SD card
    if [[ ! -f "$version_file" ]] || ! grep -q "camera type" "$version_file"; then
        print_status $YELLOW "Volume '$volume_name' is not a GoPro SD card (no version.txt or camera type found)"
        log_warning "Volume '$volume_name' is not a GoPro SD card"
        return 1
    fi
    
    # Extract camera information
    local camera_type=$(grep "camera type" "$version_file" | cut -d'"' -f4)
    local serial_number=$(grep "camera serial number" "$version_file" | cut -d'"' -f4)
    local firmware_version=$(grep "firmware version" "$version_file" | cut -d'"' -f4)
    
    log_info "GoPro SD card detected: $camera_type (serial: $serial_number, firmware: $firmware_version)"
    
    # Extract last 4 digits of serial number for shorter name
    local short_serial=${serial_number: -4}
    
    # Create new volume name: CAMERA_TYPE-SERIAL_LAST_4
    # Remove "Black" from camera type and clean up special characters
    local clean_camera_type=$(echo "$camera_type" | sed 's/ Black//g' | sed 's/ /-/g' | sed 's/[^A-Za-z0-9-]//g')
    local new_volume_name="${clean_camera_type}-${short_serial}"
    
    print_status $BLUE "GoPro SD card detected:"
    print_status $BLUE "  Current name: $volume_name"
    print_status $BLUE "  Camera type: $camera_type"
    print_status $BLUE "  Serial number: $serial_number"
    print_status $BLUE "  Firmware version: $firmware_version"
    print_status $BLUE "  Proposed new name: $new_volume_name"
    
    # Check if new name is different from current name
    if [[ "$volume_name" == "$new_volume_name" ]]; then
        print_status $GREEN "Volume '$volume_name' already has the correct name"
        log_info "Volume '$volume_name' already has the correct name"
        return 0
    fi
    
    # Check if new name already exists
    if [[ -d "/Volumes/$new_volume_name" ]]; then
        print_status $RED "Error: Volume name '$new_volume_name' already exists"
        log_error "Volume name '$new_volume_name' already exists"
        return 1
    fi
    
    # Confirm rename operation
    echo
    read -q "REPLY?Do you want to rename '$volume_name' to '$new_volume_name'? (y/N) "
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status $BLUE "Renaming volume..."
        log_info "User confirmed rename: '$volume_name' -> '$new_volume_name'"
        
        # Get the device identifier for the volume
        local device_id=$(diskutil info "$volume_path" | grep "Device Identifier" | awk '{print $3}')
        log_debug "Device identifier: $device_id"
        
        # Use diskutil to rename the volume using device identifier
        if diskutil rename "$device_id" "$new_volume_name"; then
            print_status $GREEN "Successfully renamed '$volume_name' to '$new_volume_name'"
            log_success "Successfully renamed '$volume_name' to '$new_volume_name'"
            return 0
        else
            print_status $RED "Failed to rename volume"
            log_error "Failed to rename volume '$volume_name' to '$new_volume_name'"
            return 1
        fi
    else
        print_status $YELLOW "Rename cancelled"
        log_info "User cancelled rename operation for '$volume_name'"
        return 0
    fi
}

# Function to scan all mounted volumes for GoPro SD cards
scan_all_volumes() {
    print_status $BLUE "Scanning all mounted volumes for GoPro SD cards..."
    log_info "Scanning all mounted volumes for GoPro SD cards"
    echo
    
    local found_gopro=false
    
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
                echo "Found GoPro SD card: $volume_name"
                log_info "Found GoPro SD card: $volume_name"
                rename_gopro_sd "$volume_name"
                echo
            fi
        fi
    done
    
    if [[ "$found_gopro" == false ]]; then
        print_status $YELLOW "No GoPro SD cards found"
        log_info "No GoPro SD cards found during scan"
    fi
}

# Main script logic
main() {
    print_status $BLUE "GoPro SD Card Volume Renamer"
    print_status $BLUE "============================="
    log_info "Starting GoPro SD Card Volume Renamer"
    echo
    
    if [[ $# -eq 0 ]]; then
        # No arguments provided, scan all volumes
        log_info "No volume specified, scanning all volumes"
        scan_all_volumes
    elif [[ $# -eq 1 ]]; then
        # Specific volume name provided
        log_info "Processing specified volume: $1"
        rename_gopro_sd "$1"
    else
        print_status $RED "Usage: $0 [volume_name]"
        print_status $RED "If no volume name is provided, will scan all mounted volumes"
        log_error "Invalid usage: too many arguments"
        exit 1
    fi
}

# Run main function with all arguments
main "$@"
log_time_end 