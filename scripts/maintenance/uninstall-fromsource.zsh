#!/bin/zsh

#
# uninstall-fromsource.zsh: Uninstall GoProX from source for developer use
#
# Copyright (c) 2021-2025 by Oliver Ratzesberger
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# Usage: ./uninstall-fromsource.zsh
#

# Setup logging
export LOGFILE="output/uninstall-fromsource.log"
mkdir -p "$(dirname "$LOGFILE")"
source "$(dirname $0)/../core/logger.zsh"

log_time_start

log_info "Starting GoProX uninstallation from source"

cwd=$(pwd)
log_info "Current working directory: $cwd"

log_info "Unloading launch agent"
launchctl unload ~/Library/LaunchAgents/com.goprox.mount.plist
log_info "Removing launch agent plist"
rm ~/Library/LaunchAgents/com.goprox.mount.plist
log_info "Removing goprox from /opt/homebrew/bin"
sudo rm /opt/homebrew/bin/goprox

log_success "GoProX uninstallation completed successfully"
log_time_end
