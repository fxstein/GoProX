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

# Sort models in custom order
sorted_models=()
custom_order=(
    "HERO13 Black"
    "HERO (2024)"
    "HERO12 Black"
    "HERO11 Black"
    "HERO11 Black Mini"
    "HERO10 Black"
    "HERO9 Black"
    "HERO8 Black"
    "GoPro Max"
    "The Remote"
)

# Add models in custom order if they exist
for model in "${custom_order[@]}"; do
    if [[ " ${all_models[@]} " =~ " ${model} " ]]; then
        sorted_models+=("$model")
    fi
done

# Add any remaining models that weren't in the custom order (alphabetically)
for model in "${all_models[@]}"; do
    if [[ ! " ${sorted_models[@]} " =~ " ${model} " ]]; then
        sorted_models+=("$model")
    fi
done

# Calculate column widths
model_width=5  # "Model" header length
official_width=15  # "Latest Official" header length
labs_width=11  # "Latest Labs" header length

for model in "${sorted_models[@]}"; do
    model_len=${#model}
    if [[ $model_len -gt $model_width ]]; then
        model_width=$model_len
    fi
    
    official_ver="${official_firmware[$model]:-N/A}"
    official_len=${#official_ver}
    if [[ $official_len -gt $official_width ]]; then
        official_width=$official_len
    fi
    
    labs_ver="${labs_firmware[$model]:-N/A}"
    labs_len=${#labs_ver}
    if [[ $labs_len -gt $labs_width ]]; then
        labs_width=$labs_len
    fi
done

# Generate the summary
log_info "Generating firmware summary markdown"

cat << 'EOF'
## Supported GoPro Models

The following GoPro camera models are currently supported by GoProX:

EOF

# Generate properly formatted table
printf "| %-${model_width}s | %-${official_width}s | %-${labs_width}s |\n" "Model" "Latest Official" "Latest Labs"
printf "|%s|%s|%s|\n" "$(printf '%*s' $((model_width + 2)) '' | tr ' ' '-')" "$(printf '%*s' $((official_width + 2)) '' | tr ' ' '-')" "$(printf '%*s' $((labs_width + 2)) '' | tr ' ' '-')"

for model in "${sorted_models[@]}"; do
    official_ver="${official_firmware[$model]:-N/A}"
    labs_ver="${labs_firmware[$model]:-N/A}"
    printf "| %-${model_width}s | %-${official_width}s | %-${labs_width}s |\n" "$model" "$official_ver" "$labs_ver"
done

log_info "Firmware summary generation completed" 