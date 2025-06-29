#!/bin/zsh
# logger.zsh: Centralized logging module for GoProX scripts
#
# Usage:
#   export LOGFILE=relative/or/absolute/path/to/logfile.log  # Optional
#   export LOGFILE_OLD=relative/or/absolute/path/to/logfile.log.old  # Optional
#   export LOG_MAX_SIZE=16384  # Optional, bytes
#   source "$(dirname $0)/logger.zsh"
#   log_info "Message"
#   log_error "Error message"
#   log_debug "Debug message"
#   log_json "INFO" "Message"  # JSON log format
#
# If LOGFILE and LOGFILE_OLD are not set, defaults are output/goprox.log and output/goprox.log.old

# --- Configurable Variables ---
: "${LOGFILE:=output/goprox.log}"
: "${LOGFILE_OLD:=output/goprox.log.old}"
: "${LOG_MAX_SIZE:=1048576}"
mkdir -p "$(dirname "$LOGFILE")"
: > "$LOGFILE"

# --- Internal Helpers ---
function _log_rotate_if_needed() {
  if [[ -f "$LOGFILE" && $(stat -f%z "$LOGFILE") -ge $LOG_MAX_SIZE ]]; then
    mv "$LOGFILE" "$LOGFILE_OLD"
    : > "$LOGFILE"
  fi
}

function _log_write() {
  local level="$1"
  local msg="$2"
  local ts
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  _log_rotate_if_needed
  echo "[$ts] [$level] $msg" | tee -a "$LOGFILE"
}

function log_info()    { _log_write "INFO"    "$*"; }
function log_success() { _log_write "SUCCESS" "$*"; }
function log_warning() { _log_write "WARNING" "$*"; }
function log_error()   { _log_write "ERROR"   "$*"; }
function log_debug()   { [[ "$LOG_VERBOSE" == 1 ]] && _log_write "DEBUG" "$*"; }
function log_json()    {
  local level="$1"; shift
  local msg="$*"
  local ts
  ts="$(date '+%Y-%m-%dT%H:%M:%S')"
  _log_rotate_if_needed
  echo "{\"timestamp\":\"$ts\",\"level\":\"$level\",\"message\":\"$msg\"}" | tee -a "$LOGFILE"
}

function log_time_start() {
  export LOG_TIME_START=$(date +%s)
}
function log_time_end() {
  local end=$(date +%s)
  local duration=$((end - LOG_TIME_START))
  log_info "Elapsed time: ${duration}s"
}

trap 'log_error "Error on line $LINENO"' ERR

# --- Usage Example ---
# source scripts/core/logger.zsh
# log_info "Starting script"
# log_debug "Debug info"
# log_json "INFO" "Structured log message"
# log_time_start
# ... your code ...
# log_time_end
# log_trap_errors 