#!/bin/zsh

# Force Mode Protection Module for GoProX
# Provides enhanced safety and validation for force mode operations

# Force mode operation types
readonly FORCE_OPERATION_CLEAN="clean"
readonly FORCE_OPERATION_ARCHIVE="archive"
readonly FORCE_OPERATION_IMPORT="import"
readonly FORCE_OPERATION_PROCESS="process"
readonly FORCE_OPERATION_EJECT="eject"

# Force mode confirmation requirements
readonly FORCE_CONFIRMATION_CLEAN="FORCE"
readonly FORCE_CONFIRMATION_ARCHIVE="FORCE"
readonly FORCE_CONFIRMATION_IMPORT="FORCE"
readonly FORCE_CONFIRMATION_EJECT="FORCE"

# Force mode scope validation
_validate_force_combination() {
  local archive="$1"
  local import="$2"
  local clean="$3"
  local process="$4"
  local eject="$5"
  local force="$6"
  
  # If force is not enabled, no validation needed
  if [[ "$force" != "true" ]]; then
    return 0
  fi
  
  # Count processing operations
  local operation_count=0
  [[ "$archive" == "true" ]] && ((operation_count++))
  [[ "$import" == "true" ]] && ((operation_count++))
  [[ "$clean" == "true" ]] && ((operation_count++))
  [[ "$process" == "true" ]] && ((operation_count++))
  [[ "$eject" == "true" ]] && ((operation_count++))
  
  # Check for invalid combinations
  if [[ "$clean" == "true" && "$process" == "true" ]]; then
    _error "❌ ERROR: Invalid force mode combination"
    _error "   --force --clean cannot be combined with --process"
    _error ""
    _error "   Allowed combinations:"
    _error "   • --force --clean (standalone only, requires 'FORCE' confirmation)"
    _error "   • --force --archive (standalone only)"
    _error "   • --force --import (standalone only)"
    _error "   • --force --eject (standalone only)"
    _error "   • --force --archive --clean (force archive, normal clean)"
    _error "   • --force --import --clean (force import, normal clean)"
    _error ""
    _error "   Modifiers allowed: --verbose, --debug, --quiet, --dry-run"
    return 1
  fi
  
  return 0
}

# Determine force mode scope for each operation
_determine_force_scope() {
  local archive="$1"
  local import="$2"
  local clean="$3"
  local process="$4"
  local eject="$5"
  local force="$6"
  
  local force_scope=()
  
  if [[ "$force" == "true" ]]; then
    # Standalone operations get full force mode
    if [[ "$clean" == "true" && "$archive" != "true" && "$import" != "true" && "$process" != "true" && "$eject" != "true" ]]; then
      force_scope+=("clean:force")
    elif [[ "$archive" == "true" && "$clean" != "true" && "$import" != "true" && "$process" != "true" && "$eject" != "true" ]]; then
      force_scope+=("archive:force")
    elif [[ "$import" == "true" && "$clean" != "true" && "$archive" != "true" && "$process" != "true" && "$eject" != "true" ]]; then
      force_scope+=("import:force")
    elif [[ "$eject" == "true" && "$clean" != "true" && "$archive" != "true" && "$import" != "true" && "$process" != "true" ]]; then
      force_scope+=("eject:force")
    else
      # Combined operations - force applies to archive/import but not clean
      if [[ "$archive" == "true" ]]; then
        force_scope+=("archive:force")
      fi
      if [[ "$import" == "true" ]]; then
        force_scope+=("import:force")
      fi
      if [[ "$clean" == "true" ]]; then
        force_scope+=("clean:normal")
      fi
      if [[ "$process" == "true" ]]; then
        force_scope+=("process:normal")
      fi
      if [[ "$eject" == "true" ]]; then
        force_scope+=("eject:normal")
      fi
    fi
  else
    # No force mode - all operations are normal
    [[ "$archive" == "true" ]] && force_scope+=("archive:normal")
    [[ "$import" == "true" ]] && force_scope+=("import:normal")
    [[ "$clean" == "true" ]] && force_scope+=("clean:normal")
    [[ "$process" == "true" ]] && force_scope+=("process:normal")
    [[ "$eject" == "true" ]] && force_scope+=("eject:normal")
  fi
  
  echo "${force_scope[@]}"
}

# Show force mode warning based on operation type
_show_force_warning() {
  local force_scope="$1"
  local dry_run="$2"
  
  # Parse force scope
  local operation=$(echo "$force_scope" | cut -d: -f1)
  local mode=$(echo "$force_scope" | cut -d: -f2)
  
  case "$operation" in
    "clean")
      if [[ "$mode" == "force" ]]; then
        _warning "⚠️  WARNING: --force --clean is destructive and will:"
        _warning "   • Remove media files from ALL detected SD cards"
        _warning "   • Skip archive/import safety requirements"
        _warning "   • Bypass all user confirmations"
        _warning "   • Potentially cause permanent data loss"
        _warning ""
        if [[ "$dry_run" == "true" ]]; then
          _warning "   🚦 DRY RUN MODE - No actual changes will be made"
          _warning ""
        fi
        _warning "   Type 'FORCE' to proceed with this destructive operation:"
      fi
      ;;
    "archive")
      if [[ "$mode" == "force" ]]; then
        _warning "⚠️  WARNING: --force with --archive will:"
        _warning "   • Skip individual confirmations"
        _warning "   • Re-process already completed operations"
        _warning "   • Still require successful completion and marker file creation"
        _warning ""
        if [[ "$dry_run" == "true" ]]; then
          _warning "   🚦 DRY RUN MODE - No actual changes will be made"
          _warning ""
        fi
        _warning "   Type 'FORCE' to proceed:"
      fi
      ;;
    "import")
      if [[ "$mode" == "force" ]]; then
        _warning "⚠️  WARNING: --force with --import will:"
        _warning "   • Skip individual confirmations"
        _warning "   • Re-process already completed operations"
        _warning "   • Still require successful completion and marker file creation"
        _warning ""
        if [[ "$dry_run" == "true" ]]; then
          _warning "   🚦 DRY RUN MODE - No actual changes will be made"
          _warning ""
        fi
        _warning "   Type 'FORCE' to proceed:"
      fi
      ;;
    "eject")
      if [[ "$mode" == "force" ]]; then
        _warning "⚠️  WARNING: --force with --eject will:"
        _warning "   • Skip individual confirmations"
        _warning "   • Eject ALL detected GoPro SD cards"
        _warning "   • Bypass user confirmations for each card"
        _warning ""
        if [[ "$dry_run" == "true" ]]; then
          _warning "   🚦 DRY RUN MODE - No actual changes will be made"
          _warning ""
        fi
        _warning "   Type 'FORCE' to proceed:"
      fi
      ;;
  esac
}

# Enhanced force confirmation (requires specific text)
_confirm_force_operation() {
  local force_scope="$1"
  local dry_run="$2"
  
  # Parse force scope
  local operation=$(echo "$force_scope" | cut -d: -f1)
  local mode=$(echo "$force_scope" | cut -d: -f2)
  
  # Only require confirmation for force mode operations
  if [[ "$mode" != "force" ]]; then
    return 0
  fi
  
  # Show appropriate warning
  _show_force_warning "$force_scope" "$dry_run"
  
  # Get required confirmation text
  local required_confirmation=""
  case "$operation" in
    "clean")
      required_confirmation="$FORCE_CONFIRMATION_CLEAN"
      ;;
    "archive")
      required_confirmation="$FORCE_CONFIRMATION_ARCHIVE"
      ;;
    "import")
      required_confirmation="$FORCE_CONFIRMATION_IMPORT"
      ;;
    "eject")
      required_confirmation="$FORCE_CONFIRMATION_EJECT"
      ;;
    *)
      return 0
      ;;
  esac
  
  # Read user input
  local user_input=""
  read -r user_input
  
  # Check if input matches required confirmation
  if [[ "$user_input" == "$required_confirmation" ]]; then
    _log_force_action "FORCE_CONFIRMED" "$operation" "$mode"
    return 0
  else
    _warning "❌ Invalid confirmation. Operation cancelled."
    _log_force_action "FORCE_CANCELLED" "$operation" "$mode"
    return 1
  fi
}

# Show force mode summary
_show_force_summary() {
  local force_scopes=("$@")
  local dry_run="$1"
  shift
  force_scopes=("$@")
  
  if [[ ${#force_scopes[@]} -eq 0 ]]; then
    return
  fi
  
  _info "📋 FORCE MODE SUMMARY:"
  
  # Count operations by mode
  local force_operations=()
  local normal_operations=()
  
  for scope in "${force_scopes[@]}"; do
    local operation=$(echo "$scope" | cut -d: -f1)
    local mode=$(echo "$scope" | cut -d: -f2)
    
    if [[ "$mode" == "force" ]]; then
      force_operations+=("$operation")
    else
      normal_operations+=("$operation")
    fi
  done
  
  # Show operation counts
  if [[ ${#force_operations[@]} -gt 0 ]]; then
    _info "   Force operations: ${force_operations[*]}"
  fi
  if [[ ${#normal_operations[@]} -gt 0 ]]; then
    _info "   Normal operations: ${normal_operations[*]}"
  fi
  
  # Show mode details
  for scope in "${force_scopes[@]}"; do
    local operation=$(echo "$scope" | cut -d: -f1)
    local mode=$(echo "$scope" | cut -d: -f2)
    
    case "$operation" in
      "clean")
        if [[ "$mode" == "force" ]]; then
          _info "   Clean mode: FORCE (safety checks disabled)"
        else
          _info "   Clean mode: NORMAL (safety checks required)"
        fi
        ;;
      "archive")
        if [[ "$mode" == "force" ]]; then
          _info "   Archive mode: FORCE (skip confirmations, re-process)"
        else
          _info "   Archive mode: NORMAL (confirmations required)"
        fi
        ;;
      "import")
        if [[ "$mode" == "force" ]]; then
          _info "   Import mode: FORCE (skip confirmations, re-process)"
        else
          _info "   Import mode: NORMAL (confirmations required)"
        fi
        ;;
      "eject")
        if [[ "$mode" == "force" ]]; then
          _info "   Eject mode: FORCE (skip confirmations)"
        else
          _info "   Eject mode: NORMAL (confirmations required)"
        fi
        ;;
    esac
  done
  
  if [[ "$dry_run" == "true" ]]; then
    _info "   🚦 DRY RUN MODE - No actual changes will be made"
  fi
  
  _info ""
}

# Enhanced force mode logging
_log_force_action() {
  local action="$1"
  local operation="$2"
  local mode="$3"
  local details="$4"
  
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  local log_entry="[FORCE] $timestamp $action: $operation ($mode)"
  
  if [[ -n "$details" ]]; then
    log_entry="$log_entry - $details"
  fi
  
  _debug "$log_entry"
}

# Check force restrictions for archive/import operations
_check_force_restrictions() {
  local operation="$1"
  local source="$2"
  local force_mode="$3"
  
  # If not in force mode, normal checks apply
  if [[ "$force_mode" != "force" ]]; then
    return 0
  fi
  
  # Force mode still requires successful completion for archive/import
  case "$operation" in
    "archive")
      # Archive operations must still create marker files successfully
      _log_force_action "FORCE_ARCHIVE_CHECK" "$operation" "$force_mode" "marker file creation still required"
      ;;
    "import")
      # Import operations must still create marker files successfully
      _log_force_action "FORCE_IMPORT_CHECK" "$operation" "$force_mode" "marker file creation still required"
      ;;
  esac
  
  return 0
}

# Apply force mode to specific operations
_apply_force_mode() {
  local operation="$1"
  local force_mode="$2"
  local source="$3"
  
  case "$operation" in
    "clean")
      if [[ "$force_mode" == "force" ]]; then
        _log_force_action "FORCE_CLEAN_APPLIED" "$operation" "$force_mode" "bypassing all safety checks"
        return 0
      else
        _log_force_action "NORMAL_CLEAN_APPLIED" "$operation" "$force_mode" "using normal safety checks"
        return 1  # Indicate normal mode (safety checks required)
      fi
      ;;
    "archive")
      if [[ "$force_mode" == "force" ]]; then
        _log_force_action "FORCE_ARCHIVE_APPLIED" "$operation" "$force_mode" "skipping confirmations"
        return 0
      else
        _log_force_action "NORMAL_ARCHIVE_APPLIED" "$operation" "$force_mode" "using normal confirmations"
        return 1  # Indicate normal mode (confirmations required)
      fi
      ;;
          "import")
        if [[ "$force_mode" == "force" ]]; then
          _log_force_action "FORCE_IMPORT_APPLIED" "$operation" "$force_mode" "skipping confirmations"
          return 0
        else
          _log_force_action "NORMAL_IMPORT_APPLIED" "$operation" "$force_mode" "using normal confirmations"
          return 1  # Indicate normal mode (confirmations required)
        fi
        ;;
      "eject")
        if [[ "$force_mode" == "force" ]]; then
          _log_force_action "FORCE_EJECT_APPLIED" "$operation" "$force_mode" "skipping confirmations"
          return 0
        else
          _log_force_action "NORMAL_EJECT_APPLIED" "$operation" "$force_mode" "using normal confirmations"
          return 1  # Indicate normal mode (confirmations required)
        fi
        ;;
  esac
  
  return 1  # Default to normal mode
} 