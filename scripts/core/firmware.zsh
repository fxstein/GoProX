# This script is a helper module and should be sourced, not executed directly.

# Firmware Module for GoProX
# This module provides firmware management functionality extracted from the main goprox script

# Source required modules
SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/logger.zsh"

# Global variables (these should match the main script)
if [[ -z "$FIRMWARE_CACHE_DIR" ]]; then
    FIRMWARE_CACHE_DIR="$HOME/.cache/goprox/firmware"
fi
if [[ -z "$DEFAULT_FWCHECKED_MARKER" ]]; then
    DEFAULT_FWCHECKED_MARKER=".goprox.fwchecked"
fi

# Function to clear firmware cache
clear_firmware_cache() {
    log_info "Clearing firmware cache at $FIRMWARE_CACHE_DIR..."
    if [[ -d "$FIRMWARE_CACHE_DIR" ]]; then
        rm -rf "$FIRMWARE_CACHE_DIR"/*
        log_info "Firmware cache cleared."
    else
        log_info "Firmware cache directory does not exist."
    fi
}

# Function to fetch and cache firmware zip
fetch_and_cache_firmware_zip() {
    # $1: firmware directory (e.g., .../firmware/HERO11 Black/H22.01.02.10.00)
    # $2: cache type (official or labs)
    local firmware_dir="$1"
    local cache_type="$2"
    
    local url_file="$firmware_dir/download.url"
    if [[ ! -f "$url_file" ]]; then
        log_error "No download.url found in $firmware_dir"
        return 1
    fi
    
    local firmware_url=$(cat "$url_file" | head -n 1)
    if [[ -z "$firmware_url" ]]; then
        log_error "Empty download URL in $url_file"
        return 1
    fi
    
    local firmware_name="${firmware_dir##*/}"
    local camera_name="$(basename $(dirname "$firmware_dir"))"
    local cache_subdir="$FIRMWARE_CACHE_DIR/$cache_type/$camera_name/$firmware_name"
    local cached_zip="$cache_subdir/firmware.zip"
    
    # Create cache directory if it doesn't exist
    mkdir -p "$cache_subdir"
    
    if [[ ! -f "$cached_zip" ]]; then
        log_info "Downloading firmware from $firmware_url to $cached_zip..." >&2
        curl -L -o "$cached_zip" "$firmware_url" || {
            log_error "Failed to download firmware from $firmware_url"
            return 1
        }
    else
        log_info "Using cached firmware: $cached_zip" >&2
    fi
    
    echo "$cached_zip"
}

# Function to check and update firmware for a specific source
check_and_update_firmware() {
    # $1: source directory (SD card mount point)
    # $2: firmware type preference (labs or official, defaults to labs)
    local source="$1"
    local firmware_preference="${2:-labs}"
    
    log_info "Checking firmware for source: $source"
    
    # Check if this is a GoPro storage card
    if [[ ! -f "$source/MISC/version.txt" ]]; then
        log_error "Cannot verify that $(realpath ${source}) is a GoPro storage device"
        log_error "Missing $(realpath ${source})/MISC/version.txt"
        echo "failed" >&2
        return 1
    fi
    
    # Extract camera and firmware information
    local camera=$(sed -e x -e '$ {s/,$//;p;x;}' -e 1d "$source/MISC/version.txt" | jq -r '."camera type"')
    local version=$(sed -e x -e '$ {s/,$//;p;x;}' -e 1d "$source/MISC/version.txt" | jq -r '."firmware version"')
    
    log_info "Camera: ${camera}"
    log_info "Current firmware version: ${version}"
    
    # Determine firmware base directory based on preference
    local firmwarebase=""
    local cache_type=""
    
    if [[ "$firmware_preference" == "labs" ]]; then
        firmwarebase="${GOPROX_HOME}/firmware/labs/${camera}"
        cache_type="labs"
    else
        firmwarebase="${GOPROX_HOME}/firmware/official/${camera}"
        cache_type="official"
    fi
    
    log_debug "Firmware base: $firmwarebase"
    
    # Find latest firmware
    local latestfirmware=""
    if [[ -d "$firmwarebase" ]]; then
        latestfirmware=$(ls -1d "$firmwarebase"/*/ 2>/dev/null | sort | tail -n 1)
        latestfirmware="${latestfirmware%/}"
    fi
    
    log_debug "Latest firmware: $latestfirmware"
    
    if [[ -z "$latestfirmware" ]]; then
        log_warning "No firmware files found at ${firmwarebase}"
        echo "failed" >&2
        return 1
    fi
    
    local latestversion="${latestfirmware##*/}"
    log_debug "Latest version: $latestversion"
    
    # Check if update is needed
    if [[ "$latestversion" == "$version" ]]; then
        log_info "Camera ${camera} has the latest firmware: ${latestversion}"
        echo "up_to_date" >&2
        return 0
    fi
    
    # Fetch and cache the firmware zip
    local firmwarezip=$(fetch_and_cache_firmware_zip "$latestfirmware" "$cache_type")
    if [[ -z "$firmwarezip" ]]; then
        log_error "No firmware zip found or downloaded for $latestfirmware"
        echo "failed" >&2
        return 1
    fi
    
    # Install the firmware update
    log_warning "New firmware available: ${version} >> ${latestversion}"
    log_warning "Transferring newer firmware to ${source}"
    
    # Remove existing UPDATE directory and create new one
    rm -rf "${source}/UPDATE"
    mkdir -p "${source}/UPDATE"
    
    # Extract firmware files
    unzip -o -uj "$firmwarezip" -d "${source}/UPDATE" || {
        log_error "Unzip copy of firmware $firmwarezip to ${source}/UPDATE failed!"
        echo "failed" >&2
        return 1
    }
    
    # Mark as checked
    touch "$source/$DEFAULT_FWCHECKED_MARKER"
    
    log_info "Finished firmware transfer. Camera ${camera} will install upgrade during next power on."
    echo "updated" >&2
    return 0
}

# Function to check firmware status without updating
check_firmware_status() {
    # $1: source directory (SD card mount point)
    # $2: firmware type preference (labs or official, defaults to labs)
    local source="$1"
    local firmware_preference="${2:-labs}"
    
    log_info "Checking firmware status for source: $source"
    
    # Check if this is a GoPro storage card
    if [[ ! -f "$source/MISC/version.txt" ]]; then
        log_error "Cannot verify that $(realpath ${source}) is a GoPro storage device"
        log_error "Missing $(realpath ${source})/MISC/version.txt"
        return 1
    fi
    
    # Extract camera and firmware information
    local camera=$(sed -e x -e '$ {s/,$//;p;x;}' -e 1d "$source/MISC/version.txt" | jq -r '."camera type"')
    local version=$(sed -e x -e '$ {s/,$//;p;x;}' -e 1d "$source/MISC/version.txt" | jq -r '."firmware version"')
    
    log_info "Camera: ${camera}"
    log_info "Current firmware version: ${version}"
    
    # Determine firmware base directory based on preference
    local firmwarebase=""
    local cache_type=""
    
    if [[ "$firmware_preference" == "labs" ]]; then
        firmwarebase="${GOPROX_HOME}/firmware/labs/${camera}"
        cache_type="labs"
    else
        firmwarebase="${GOPROX_HOME}/firmware/official/${camera}"
        cache_type="official"
    fi
    
    # Find latest firmware
    local latestfirmware=""
    if [[ -d "$firmwarebase" ]]; then
        latestfirmware=$(ls -1d "$firmwarebase"/*/ 2>/dev/null | sort | tail -n 1)
        latestfirmware="${latestfirmware%/}"
    fi
    
    if [[ -z "$latestfirmware" ]]; then
        log_warning "No firmware files found at ${firmwarebase}"
        return 1
    fi
    
    local latestversion="${latestfirmware##*/}"
    
    # Return status information
    if [[ "$latestversion" == "$version" ]]; then
        echo "up_to_date:$camera:$version:$latestversion:$firmware_preference"
    else
        echo "update_available:$camera:$version:$latestversion:$firmware_preference"
    fi
}

# Function to get firmware information for a card
get_firmware_info() {
    # $1: source directory (SD card mount point)
    local source="$1"
    
    if [[ ! -f "$source/MISC/version.txt" ]]; then
        return 1
    fi
    
    # Extract camera and firmware information
    local camera=$(sed -e x -e '$ {s/,$//;p;x;}' -e 1d "$source/MISC/version.txt" | jq -r '."camera type"')
    local version=$(sed -e x -e '$ {s/,$//;p;x;}' -e 1d "$source/MISC/version.txt" | jq -r '."firmware version"')
    local serial=$(sed -e x -e '$ {s/,$//;p;x;}' -e 1d "$source/MISC/version.txt" | jq -r '."camera serial number"')
    
    # Determine firmware type
    local firmware_type="official"
    local firmware_suffix=${version: -2}
    if [[ "$firmware_suffix" =~ ^7[0-9]$ ]]; then
        firmware_type="labs"
    fi
    
    echo "$camera:$version:$serial:$firmware_type"
}

# Debug: Show that functions are loaded
log_debug "firmware.zsh loaded, functions available:"
log_debug "  - check_firmware_status"
log_debug "  - check_and_update_firmware"
log_debug "  - fetch_and_cache_firmware_zip"
log_debug "  - clear_firmware_cache"
log_debug "  - get_firmware_info" 