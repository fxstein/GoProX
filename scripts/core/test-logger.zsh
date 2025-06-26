#!/bin/zsh
# test-logger.zsh: Test script for GoProX logger module

export LOG_MAX_SIZE=16384  # 16KB for rapid rotation test
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

# Test log rotation by writing many lines (simulate large log)
for i in {1..2000}; do
  log_info "Filling log for rotation test: line $i"
done

echo "Logger test complete. Check output/goprox.log and output/goprox.log.old for results." 