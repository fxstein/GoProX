# SD Card Detection and GoPro Identification

This document describes how to detect mounted SD cards and identify if they are from GoPro cameras, including extracting firmware version and serial number information.

## SD Card Detection

### Method 1: Check for Removable Media
```zsh
# Find external disks with removable media
system_profiler SPUSBDataType | grep -A 5 -B 2 "Removable Media: Yes"
```

### Method 2: List Mounted Volumes
```zsh
# List all mounted volumes
ls -la /Volumes/ | grep -v "^d.*\.$" | grep -v "^d.*\.\.$" | grep -v "^total"
```

### Method 3: Check External Disks
```zsh
# List external physical disks
diskutil list | grep -A 10 "external"
```

## GoPro SD Card Identification

### Method 1: Check for GoPro URL File
```zsh
# Look for GoPro branding file
ls "/Volumes/$VOLUME_NAME/Get_started_with_GoPro.url"
```

### Method 2: Check for GoPro Directory Structure
```zsh
# Verify GoPro standard directories exist
[ -d "/Volumes/$VOLUME_NAME/MISC" ] && [ -d "/Volumes/$VOLUME_NAME/DCIM" ]
```

### Method 3: Check for Camera Type in Metadata (Recommended)
```zsh
# Look for camera type in version.txt
grep "camera type" "/Volumes/$VOLUME_NAME/MISC/version.txt"
```

## Extracting GoPro Information

### Firmware Version
```zsh
# Extract firmware version from version.txt
grep "firmware version" "/Volumes/$VOLUME_NAME/MISC/version.txt" | cut -d'"' -f4
```

### Camera Serial Number
```zsh
# Extract camera serial number from version.txt
grep "camera serial number" "/Volumes/$VOLUME_NAME/MISC/version.txt" | cut -d'"' -f4
```

### Camera Type
```zsh
# Extract camera type from version.txt
grep "camera type" "/Volumes/$VOLUME_NAME/MISC/version.txt" | cut -d'"' -f4
```

### WiFi MAC Address
```zsh
# Extract WiFi MAC address from version.txt
grep "wifi mac" "/Volumes/$VOLUME_NAME/MISC/version.txt" | cut -d'"' -f4
```

## Complete Detection Script Example

```zsh
#!/bin/zsh

# Function to detect GoPro SD cards
detect_gopro_sd() {
    local volume_name="$1"
    local version_file="/Volumes/$volume_name/MISC/version.txt"
    
    # Check if version.txt exists and contains camera type
    if [[ -f "$version_file" ]] && grep -q "camera type" "$version_file"; then
        echo "GoPro SD card detected: $volume_name"
        
        # Extract camera information
        local camera_type=$(grep "camera type" "$version_file" | cut -d'"' -f4)
        local firmware_version=$(grep "firmware version" "$version_file" | cut -d'"' -f4)
        local serial_number=$(grep "camera serial number" "$version_file" | cut -d'"' -f4)
        local wifi_mac=$(grep "wifi mac" "$version_file" | cut -d'"' -f4)
        
        echo "  Camera Type: $camera_type"
        echo "  Firmware Version: $firmware_version"
        echo "  Serial Number: $serial_number"
        echo "  WiFi MAC: $wifi_mac"
        
        return 0
    else
        return 1
    fi
}

# Find all mounted volumes and check for GoPro SD cards
for volume in /Volumes/*; do
    if [[ -d "$volume" ]] && [[ "$(basename "$volume")" != "." ]] && [[ "$(basename "$volume")" != ".." ]]; then
        volume_name=$(basename "$volume")
        detect_gopro_sd "$volume_name"
    fi
done
```

## GoPro Directory Structure

A typical GoPro SD card contains:

```
/Volumes/[VOLUME_NAME]/
├── DCIM/                    # Camera photos and videos
├── MISC/                    # GoPro metadata
│   ├── version.txt         # Camera info (firmware, serial, etc.)
│   ├── GoPro-owner.txt     # Owner information
│   ├── qr.bin             # QR code data
│   └── qrlog.txt          # QR code logging
├── UPDATE/                 # Firmware update files
└── Get_started_with_GoPro.url  # GoPro branding link
```

## version.txt Format

The `MISC/version.txt` file contains JSON-formatted camera information:

```json
{
"info version":"2.0"
,"firmware version":"H22.01.01.10.70"
,"wifi mac":"2474f7b84eb0"
,"camera type":"HERO11 Black"
,"camera serial number":"C3471325208909"
}
```

## Firmware Version Format

GoPro firmware versions follow the pattern: `H[YY].[MM].[DD].[HH].[MM]`

- `H[YY]` - Hardware version (e.g., H22 for HERO11)
- `[MM].[DD]` - Date (month.day)
- `[HH].[MM]` - Time (hour.minute)

Example: `H22.01.01.10.70` = HERO11 Black, January 1st, 10:70

## Notes

- The `MISC/version.txt` file is the most reliable indicator of a GoPro camera
- Firmware versions can be used to determine camera model and update status
- Serial numbers are unique identifiers for each camera
- WiFi MAC addresses can be used for network identification
- The detection methods work for all GoPro camera models (HERO8, HERO9, HERO10, HERO11, HERO12, etc.) 