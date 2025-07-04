#!/bin/zsh

#
# install-fromsource.zsh: Install GoProX from source for developer use
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
# Usage: ./install-fromsource.zsh
#

# Setup logging
export LOGFILE="output/install-fromsource.log"
mkdir -p "$(dirname "$LOGFILE")"
source "$(dirname $0)/../core/logger.zsh"

log_time_start

log_info "Starting GoProX installation from source"

#
# Most simplistic setup for GoProX for developer use
# Adds goprox to /usr/local/bin for easy access from source
#

cwd=$(pwd)
log_info "Current working directory: $cwd"

# In order to bypass macOS sandbox limitations when the git repo is within the 
# users Documents folder we have to physically copy the developer copy of goprox 
# into the homebrew tree. Links will cause the launch agent execution to fail 

# sudo ln -s $cwd/goprox /usr/local/bin
log_info "Copying goprox to /opt/homebrew/bin"
sudo cp $cwd/goprox /opt/homebrew/bin
# ln -s $cwd/launchd/com.goprox.mount.plist ~/Library/LaunchAgents
log_info "Copying launch agent plist to ~/Library/LaunchAgents"
cp $cwd/launchd/com.goprox.mount.plist ~/Library/LaunchAgents
log_info "Loading launch agent"
launchctl load ~/Library/LaunchAgents/com.goprox.mount.plist

log_success "GoProX installation completed successfully"
log_time_end