#!/bin/zsh

# Decision Matrix Module for GoProX Enhanced Default Behavior
# This module determines the appropriate workflow based on detected cards and their states

# Source the logger module
SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/logger.zsh"

# Function to analyze detected cards and determine optimal workflow
analyze_workflow_requirements() {
    local detected_cards="$1"
    
    log_info "Analyzing workflow requirements for detected cards"
    
    if [[ -z "$detected_cards" ]]; then
        log_info "No cards detected, no workflow required"
        echo "none"
        return 0
    fi
    
    # Parse detected cards (assuming JSON array format)
    local card_count=$(echo "$detected_cards" | jq length 2>/dev/null || echo "0")
    
    if [[ "$card_count" -eq 0 ]]; then
        log_info "No valid cards found"
        echo "none"
        return 0
    fi
    
    # Analyze each card to determine required actions
    local workflow_actions=()
    local has_new_cards=false
    local has_processed_cards=false
    local has_firmware_updates=false
    
    for i in $(seq 0 $((card_count - 1))); do
        local card_info=$(echo "$detected_cards" | jq ".[$i]")
        local card_actions=$(analyze_single_card "$card_info")
        
        # Add actions to workflow
        if [[ -n "$card_actions" ]]; then
            workflow_actions+=("$card_actions")
        fi
        
        # Check for specific conditions
        local state=$(echo "$card_info" | jq -r '.state')
        local has_fw_update=$(echo "$card_info" | jq -r '.content.has_firmware_update')
        
        if [[ "$state" == "new" ]]; then
            has_new_cards=true
        elif [[ "$state" == "archived" || "$state" == "imported" ]]; then
            has_processed_cards=true
        fi
        
        if [[ "$has_fw_update" == "true" ]]; then
            has_firmware_updates=true
        fi
    done
    
    # Determine overall workflow type
    local workflow_type=$(determine_workflow_type "$has_new_cards" "$has_processed_cards" "$has_firmware_updates")
    
    # Create workflow plan
    local workflow_plan=$(create_workflow_plan "$workflow_type" "$detected_cards" "$workflow_actions")
    
    echo "$workflow_plan"
}

# Function to analyze a single card and determine required actions
analyze_single_card() {
    local card_info="$1"
    log_debug "Analyzing single card for required actions"
    local state=$(echo "$card_info" | jq -r '.state')
    local content_state=$(echo "$card_info" | jq -r '.content.content_state')
    local has_fw_update=$(echo "$card_info" | jq -r '.content.has_firmware_update')
    local total_files=$(echo "$card_info" | jq -r '.content.total_files')
    local actions=()
    case "$state" in
        "new")
            if [[ $total_files -gt 0 ]]; then
                actions+=("archive")
                actions+=("import")
                actions+=("process")
                actions+=("clean")
            fi
            actions+=("firmware_check")
            ;;
        "archived")
            actions+=("import")
            actions+=("process")
            actions+=("clean")
            actions+=("firmware_check")
            ;;
        "imported")
            actions+=("process")
            actions+=("clean")
            actions+=("firmware_check")
            ;;
        "firmware_checked")
            if [[ $total_files -gt 0 ]]; then
                actions+=("archive")
                actions+=("import")
                actions+=("process")
                actions+=("clean")
            fi
            ;;
        "cleaned")
            actions+=("firmware_check")
            ;;
        *)
            log_warning "Unknown card state: $state"
            actions+=("archive")
            actions+=("import")
            actions+=("process")
            actions+=("clean")
            actions+=("firmware_check")
            ;;
    esac
    if [[ "$has_fw_update" == "true" ]]; then
        actions+=("firmware_update")
    fi
    # Build valid JSON array for actions
    local actions_json="[]"
    if (( ${#actions[@]} > 0 )); then
        local joined=$(printf ',"%s"' "${actions[@]}")
        actions_json="[${joined:1}]"
    fi
    local card_actions=$(cat <<EOF
{
  "volume_name": "$(echo "$card_info" | jq -r '.volume_name')",
  "state": "$state",
  "content_state": "$content_state",
  "total_files": $total_files,
  "actions": $actions_json
}
EOF
)
    echo "$card_actions"
}

# Function to determine overall workflow type
determine_workflow_type() {
    local has_new_cards="$1"
    local has_processed_cards="$2"
    local has_firmware_updates="$3"
    
    log_debug "Determining workflow type: new=$has_new_cards, processed=$has_processed_cards, fw=$has_firmware_updates"
    
    if [[ "$has_new_cards" == "true" ]]; then
        if [[ "$has_firmware_updates" == "true" ]]; then
            echo "comprehensive"
        else
            echo "full_processing"
        fi
    elif [[ "$has_processed_cards" == "true" ]]; then
        if [[ "$has_firmware_updates" == "true" ]]; then
            echo "continue_processing"
        else
            echo "complete_processing"
        fi
    elif [[ "$has_firmware_updates" == "true" ]]; then
        echo "firmware_only"
    else
        echo "maintenance"
    fi
}

# Function to create a comprehensive workflow plan
create_workflow_plan() {
    local workflow_type="$1"
    local detected_cards="$2"
    local workflow_actions_str="$3"
    
    log_info "Creating workflow plan: $workflow_type"
    
    # Determine workflow description and priority
    local workflow_description=""
    local priority="medium"
    
    case "$workflow_type" in
        "comprehensive")
            workflow_description="Full processing with firmware updates for new cards"
            priority="high"
            ;;
        "full_processing")
            workflow_description="Complete media processing for new cards"
            priority="high"
            ;;
        "continue_processing")
            workflow_description="Continue processing for partially processed cards"
            priority="medium"
            ;;
        "complete_processing")
            workflow_description="Complete remaining processing steps"
            priority="medium"
            ;;
        "firmware_only")
            workflow_description="Firmware update and maintenance only"
            priority="low"
            ;;
        "maintenance")
            workflow_description="Routine maintenance and checks"
            priority="low"
            ;;
        *)
            workflow_description="Unknown workflow type"
            priority="low"
            ;;
    esac

    # Build a valid JSON array for actions
    local actions_json="[]"
    if [[ -n "$workflow_actions_str" ]]; then
        local actions_lines=()
        # Read each card JSON object as a single element, using NUL as delimiter
        while IFS= read -r -d '' obj; do
            [[ -n "$obj" ]] && actions_lines+=("$obj")
        done < <(printf '%s\0' "$workflow_actions_str")
        if (( ${#actions_lines[@]} > 0 )); then
            actions_json="["
            for ((i=0; i<${#actions_lines[@]}; i++)); do
                if (( i > 0 )); then
                    actions_json+="," 
                fi
                actions_json+="${actions_lines[$i]}"
            done
            actions_json+="]"
        fi
    fi

    local workflow_plan=$(cat <<EOF
{
  "workflow_type": "$workflow_type",
  "description": "$workflow_description",
  "priority": "$priority",
  "card_count": $(echo "$detected_cards" | jq length),
  "cards": $detected_cards,
  "actions": $actions_json,
  "estimated_duration": "$(estimate_workflow_duration "$workflow_type" "$detected_cards")",
  "recommended_approach": "$(get_recommended_approach "$workflow_type")"
}
EOF
)

    # DEBUG: Log the generated JSON for debugging
    log_debug "Generated workflow_plan JSON:"
    log_debug "$workflow_plan"
    
    echo "$workflow_plan"
}

# Function to estimate workflow duration
estimate_workflow_duration() {
    local workflow_type="$1"
    local detected_cards="$2"
    
    local card_count=$(echo "$detected_cards" | jq length)
    local total_files=0
    
    # Calculate total files across all cards
    for i in $(seq 0 $((card_count - 1))); do
        local files=$(echo "$detected_cards" | jq ".[$i].content.total_files")
        total_files=$((total_files + files))
    done
    
    # Estimate based on workflow type and file count
    case "$workflow_type" in
        "comprehensive")
            if [[ $total_files -gt 1000 ]]; then
                echo "30-60 minutes"
            elif [[ $total_files -gt 100 ]]; then
                echo "10-30 minutes"
            else
                echo "5-15 minutes"
            fi
            ;;
        "full_processing")
            if [[ $total_files -gt 1000 ]]; then
                echo "20-45 minutes"
            elif [[ $total_files -gt 100 ]]; then
                echo "8-20 minutes"
            else
                echo "3-10 minutes"
            fi
            ;;
        "continue_processing"|"complete_processing")
            if [[ $total_files -gt 1000 ]]; then
                echo "15-30 minutes"
            elif [[ $total_files -gt 100 ]]; then
                echo "5-15 minutes"
            else
                echo "2-8 minutes"
            fi
            ;;
        "firmware_only"|"maintenance")
            echo "1-3 minutes"
            ;;
        *)
            echo "5-15 minutes"
            ;;
    esac
}

# Function to get recommended approach for workflow
get_recommended_approach() {
    local workflow_type="$1"
    
    case "$workflow_type" in
        "comprehensive")
            echo "Recommended: Full automated processing with user confirmation for firmware updates"
            ;;
        "full_processing")
            echo "Recommended: Automated processing with progress monitoring"
            ;;
        "continue_processing"|"complete_processing")
            echo "Recommended: Continue automated processing from current state"
            ;;
        "firmware_only")
            echo "Recommended: Quick firmware update and maintenance check"
            ;;
        "maintenance")
            echo "Recommended: Light maintenance and status check"
            ;;
        *)
            echo "Recommended: Standard processing approach"
            ;;
    esac
}

# Function to validate workflow plan
validate_workflow_plan() {
    local workflow_plan="$1"
    
    log_debug "Validating workflow plan"
    
    # Basic validation - check if required fields are present
    if [[ -z "$workflow_plan" ]]; then
        log_error "Workflow plan is empty"
        return 1
    fi
    
    # Validate JSON structure
    if ! echo "$workflow_plan" | jq . >/dev/null 2>&1; then
        log_error "Invalid JSON structure in workflow plan"
        return 1
    fi
    
    # Check required fields
    local required_fields=("workflow_type" "description" "priority" "card_count")
    for field in "${required_fields[@]}"; do
        if ! echo "$workflow_plan" | jq -e ".$field" >/dev/null 2>&1; then
            log_error "Missing required field: $field"
            return 1
        fi
    done
    
    log_debug "Workflow plan validation passed"
    return 0
}

# Function to format workflow plan for display
format_workflow_display() {
    local workflow_plan="$1"
    
    local workflow_type=$(echo "$workflow_plan" | jq -r '.workflow_type')
    local description=$(echo "$workflow_plan" | jq -r '.description')
    local priority=$(echo "$workflow_plan" | jq -r '.priority')
    local card_count=$(echo "$workflow_plan" | jq -r '.card_count')
    local estimated_duration=$(echo "$workflow_plan" | jq -r '.estimated_duration')
    local recommended_approach=$(echo "$workflow_plan" | jq -r '.recommended_approach')
    
    cat <<EOF
Workflow Analysis:
  Type: $workflow_type
  Description: $description
  Priority: $priority
  Cards detected: $card_count
  Estimated duration: $estimated_duration
  $recommended_approach

Card Details:
EOF
    
    # Display each card's information
    local card_count=$(echo "$workflow_plan" | jq '.cards | length')
    for i in $(seq 0 $((card_count - 1))); do
        local card_info=$(echo "$workflow_plan" | jq ".cards[$i]")
        local volume_name=$(echo "$card_info" | jq -r '.volume_name')
        local state=$(echo "$card_info" | jq -r '.state')
        local total_files=$(echo "$card_info" | jq -r '.content.total_files')
        local actions=$(echo "$workflow_plan" | jq -r ".actions[$i].actions[]" 2>/dev/null | tr '\n' ', ' | sed 's/, $//')
        
        echo "  $volume_name: $state ($total_files files) - Actions: $actions"
    done
}

# Export functions for use in other modules
export -f analyze_workflow_requirements
export -f analyze_single_card
export -f determine_workflow_type
export -f create_workflow_plan
export -f estimate_workflow_duration
export -f get_recommended_approach
export -f validate_workflow_plan
export -f format_workflow_display 