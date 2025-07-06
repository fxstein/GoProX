#!/bin/zsh

# GoProX Configuration Management
# This module handles loading and parsing of GoProX configuration settings

# Function to get default configuration value for a key
get_default_config_value() {
    local key="$1"
    case "$key" in
        "sd_card_naming.auto_rename") echo "true" ;;
        "sd_card_naming.format") echo "{camera_type}-{serial_short}" ;;
        "sd_card_naming.clean_camera_type") echo "true" ;;
        "sd_card_naming.remove_words") echo "Black" ;;
        "sd_card_naming.space_replacement") echo "-" ;;
        "sd_card_naming.remove_special_chars") echo "true" ;;
        "sd_card_naming.allowed_chars") echo "-" ;;
        "enhanced_behavior.auto_execute") echo "false" ;;
        "enhanced_behavior.default_confirm") echo "false" ;;
        "enhanced_behavior.show_details") echo "true" ;;
        "logging.level") echo "info" ;;
        "logging.file_logging") echo "true" ;;
        "logging.log_file") echo "output/goprox.log" ;;
        "firmware.auto_check") echo "true" ;;
        "firmware.auto_update") echo "false" ;;
        "firmware.confirm_updates") echo "true" ;;
        *) echo "" ;;
    esac
}

# Load configuration from YAML file
load_goprox_config() {
    local config_file="${1:-config/goprox-settings.yaml}"
    local project_root="${2:-$(pwd)}"
    
    log_debug "Loading GoProX configuration from: $config_file"
    
    # Check if config file exists
    if [[ ! -f "$config_file" ]]; then
        log_warning "Configuration file not found: $config_file"
        log_info "Using default configuration values"
        return 0
    fi
    
    # Check if yq is available for YAML parsing
    if ! command -v yq &> /dev/null; then
        log_warning "yq not found, using default configuration values"
        log_info "Install yq with: brew install yq"
        return 0
    fi
    
    # Load configuration values
    local config_values=()
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            config_values+=("$line")
        fi
    done < <(yq eval 'to_entries | .[] | .key + "=" + (.value | tostring)' "$config_file" 2>/dev/null)
    
    # Export configuration as environment variables
    for value in "${config_values[@]}"; do
        local key="${value%%=*}"
        local val="${value#*=}"
        
        # Convert YAML path to environment variable name
        local env_var="GOPROX_${key//./_}"
        export "$env_var"="$val"
        log_debug "Loaded config: $env_var=$val"
    done
    
    log_info "Configuration loaded successfully"
}

# Get configuration value with fallback to defaults
get_config_value() {
    local key="$1"
    local env_var="GOPROX_${key//./_}"
    local default_value=$(get_default_config_value "$key")
    
    # Return environment variable if set, otherwise return default
    if [[ -n "${(P)env_var}" ]]; then
        echo "${(P)env_var}"
    else
        echo "$default_value"
    fi
}

# Check if a boolean configuration is enabled
is_config_enabled() {
    local key="$1"
    local value=$(get_config_value "$key")
    
    case "$value" in
        "true"|"yes"|"1"|"on")
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Get SD card naming configuration
get_sd_naming_config() {
    echo "auto_rename=$(is_config_enabled 'sd_card_naming.auto_rename' && echo true || echo false)"
    echo "format=$(get_config_value 'sd_card_naming.format')"
    echo "clean_camera_type=$(is_config_enabled 'sd_card_naming.clean_camera_type' && echo true || echo false)"
    echo "remove_words=$(get_config_value 'sd_card_naming.remove_words')"
    echo "space_replacement=$(get_config_value 'sd_card_naming.space_replacement')"
    echo "remove_special_chars=$(is_config_enabled 'sd_card_naming.remove_special_chars' && echo true || echo false)"
    echo "allowed_chars=$(get_config_value 'sd_card_naming.allowed_chars')"
}

# Generate SD card name based on configuration
generate_sd_card_name() {
    local camera_type="$1"
    local serial_number="$2"
    local firmware_version="$3"
    local firmware_type="$4"

    # Load naming config as local variables
    local auto_rename format clean_camera_type remove_words space_replacement remove_special_chars allowed_chars
    eval "$(get_sd_naming_config)"

    # Extract last 4 digits of serial number
    local short_serial=${serial_number: -4}

    # Clean camera type if enabled
    local cleaned_camera_type="$camera_type"
    if [[ "$clean_camera_type" == "true" ]]; then
        # Remove specified words
        for word in ${=remove_words}; do
            cleaned_camera_type=$(echo "$cleaned_camera_type" | sed "s/ $word//g")
        done
        # Replace spaces
        cleaned_camera_type=$(echo "$cleaned_camera_type" | sed "s/ /${space_replacement}/g")
        # Remove special characters if enabled
        if [[ "$remove_special_chars" == "true" ]]; then
            local allowed_pattern="[A-Za-z0-9${allowed_chars}]"
            cleaned_camera_type=$(echo "$cleaned_camera_type" | sed "s/[^$allowed_pattern]//g")
        fi
    fi

    # Apply naming format
    local new_name="$format"
    new_name="${new_name//\{camera_type\}/$cleaned_camera_type}"
    new_name="${new_name//\{serial_full\}/$serial_number}"
    new_name="${new_name//\{serial_short\}/$short_serial}"
    new_name="${new_name//\{firmware_version\}/$firmware_version}"
    new_name="${new_name//\{firmware_type\}/$firmware_type}"

    echo "$new_name"
}

# Validate configuration
validate_config() {
    local config_file="${1:-config/goprox-settings.yaml}"
    
    if [[ ! -f "$config_file" ]]; then
        log_warning "Configuration file not found: $config_file"
        return 1
    fi
    
    if ! command -v yq &> /dev/null; then
        log_warning "yq not found, cannot validate YAML configuration"
        return 1
    fi
    
    if ! yq eval '.' "$config_file" >/dev/null 2>&1; then
        log_error "Invalid YAML syntax in configuration file: $config_file"
        return 1
    fi
    
    log_info "Configuration validation passed"
    return 0
}

# Show current configuration
show_config() {
    echo "GoProX Configuration:"
    echo "===================="
    
    # SD Card Naming
    echo "SD Card Naming:"
    echo "  Auto Rename: $(is_config_enabled "sd_card_naming.auto_rename" && echo "Enabled" || echo "Disabled")"
    echo "  Format: $(get_config_value "sd_card_naming.format")"
    echo "  Clean Camera Type: $(is_config_enabled "sd_card_naming.clean_camera_type" && echo "Enabled" || echo "Disabled")"
    echo "  Remove Words: $(get_config_value "sd_card_naming.remove_words")"
    echo "  Space Replacement: $(get_config_value "sd_card_naming.space_replacement")"
    echo "  Remove Special Chars: $(is_config_enabled "sd_card_naming.remove_special_chars" && echo "Enabled" || echo "Disabled")"
    echo "  Allowed Chars: $(get_config_value "sd_card_naming.allowed_chars")"
    echo
    
    # Enhanced Behavior
    echo "Enhanced Behavior:"
    echo "  Auto Execute: $(is_config_enabled "enhanced_behavior.auto_execute" && echo "Enabled" || echo "Disabled")"
    echo "  Default Confirm: $(is_config_enabled "enhanced_behavior.default_confirm" && echo "Enabled" || echo "Disabled")"
    echo "  Show Details: $(is_config_enabled "enhanced_behavior.show_details" && echo "Enabled" || echo "Disabled")"
    echo
    
    # Logging
    echo "Logging:"
    echo "  Level: $(get_config_value "logging.level")"
    echo "  File Logging: $(is_config_enabled "logging.file_logging" && echo "Enabled" || echo "Disabled")"
    echo "  Log File: $(get_config_value "logging.log_file")"
    echo
    
    # Firmware
    echo "Firmware:"
    echo "  Auto Check: $(is_config_enabled "firmware.auto_check" && echo "Enabled" || echo "Disabled")"
    echo "  Auto Update: $(is_config_enabled "firmware.auto_update" && echo "Enabled" || echo "Disabled")"
    echo "  Confirm Updates: $(is_config_enabled "firmware.confirm_updates" && echo "Enabled" || echo "Disabled")"
} 