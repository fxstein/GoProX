#!/bin/zsh
# test-logger.zsh: Test script for GoProX logger module

export LOG_MAX_SIZE=8192  # 8KB for rotation test
source "$(dirname $0)/logger.zsh"

log_info "This is an info message."
log_success "This is a success message."
log_warning "This is a warning message."
log_error "This is an error message."
LOG_VERBOSE=1
log_debug "This is a debug message."
log_json "INFO" "This is a JSON log message."

log_time_start
sleep 1
log_time_end

# Test log rotation by writing enough lines to exceed 8KB
# Each log line is approximately 60-70 bytes, so ~120 lines should trigger rotation
for i in {1..150}; do
  log_info "Filling log for rotation test: line $i"
done

echo "Logger test complete. Check output/goprox.log and output/goprox.log.old for results." 