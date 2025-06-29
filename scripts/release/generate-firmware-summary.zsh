#!/bin/zsh

# Generate firmware summary for release notes
# This script creates a comprehensive list of supported GoPro models and their latest firmware versions

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/../core/logger.zsh"
init_logger "generate-firmware-summary"

log_info "Generating firmware summary for release notes"

# Function to get latest firmware version for a model
get_latest_firmware() {
    local model_dir="$1"
    local latest_version=""
    
    if [[ ! -d "$model_dir" ]]; then
        return 1
    fi
    
    for version_dir in "$model_dir"/*/; do
        if [[ -d "$version_dir" ]]; then
            local version=$(basename "$version_dir")
            if [[ "$version" == ".keep" ]] || [[ "$version" == "README.txt" ]]; then
                continue
            fi
            if [[ "$version" > "$latest_version" ]]; then
                latest_version="$version"
            fi
        fi
    done
    
    echo "$latest_version"
}

# Initialize associative arrays
typeset -A official_firmware
typeset -A labs_firmware
typeset -a all_models

# Process official firmware
for model_dir in firmware/official/*/; do
    if [[ -d "$model_dir" ]]; then
        model_name=$(basename "$model_dir")
        model_name=${model_name//\"/}  # Remove any embedded quotes
        if [[ "$model_name" != ".keep" ]] && [[ "$model_name" != "README.txt" ]]; then
            latest_version=$(get_latest_firmware "$model_dir")
            official_firmware[$model_name]="$latest_version"
            all_models+=("$model_name")
        fi
    fi
done

# Process labs firmware
for model_dir in firmware/labs/*/; do
    if [[ -d "$model_dir" ]]; then
        model_name=$(basename "$model_dir")
        model_name=${model_name//\"/}  # Remove any embedded quotes
        if [[ "$model_name" != ".keep" ]] && [[ "$model_name" != "README.txt" ]]; then
            latest_version=$(get_latest_firmware "$model_dir")
            labs_firmware[$model_name]="$latest_version"
            # Only add to all_models if not already present
            if [[ ! " ${all_models[@]} " =~ " ${model_name} " ]]; then
                all_models+=("$model_name")
            fi
        fi
    fi
done

# Sort models for output
sorted_models=()
while IFS= read -r model; do
    sorted_models+=("$model")
done < <(printf '%s\n' "${all_models[@]}" | sort)

# Generate the summary
log_info "Generating firmware summary markdown"

cat << 'EOF'
## Supported GoPro Models

The following GoPro camera models are currently supported by GoProX:

EOF

# Single table with latest official and labs firmware
echo "| Model | Latest Official | Latest Labs |"
echo "|-------|-----------------|-------------|"
for model in "${sorted_models[@]}"; do
    official_ver="${official_firmware[$model]:-N/A}"
    labs_ver="${labs_firmware[$model]:-N/A}"
    echo "| $model | $official_ver | $labs_ver |"
done

log_info "Firmware summary generation completed" 