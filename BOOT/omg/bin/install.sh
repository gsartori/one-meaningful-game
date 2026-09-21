#!/bin/bash

# Copyright 2026 Gianluca Sartori
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# ============================================================
# OMG Service Install
# ============================================================
set -u

SERVICE_NAME="omg.service"
OMG_DIR="/boot/omg"
SERVICE_SOURCE="${OMG_DIR}/bin/${SERVICE_NAME}"
SERVICE_DEST="/etc/systemd/system/${SERVICE_NAME}"

# Logs
LOG_DIR="${OMG_DIR}/logs"
LOG_FILE="${LOG_DIR}/omg-install.log"

# ------------------------------------------------------------
# Read configuration
# ------------------------------------------------------------
source "${OMG_DIR}/bin/config.sh"
load_omg_config || exit 1

# ------------------------------------------------------------
# Init logging
# ------------------------------------------------------------
source "${OMG_DIR}/bin/logging.sh"
init_logging "INSTALL"

# ------------------------------------------------------------
# Disable services used by dArkOS
# ------------------------------------------------------------
disable_service()
{
    local service="$1"
    local output
    local rc

    log "Disabling $service."

    if ! systemctl list-unit-files "$service" --no-legend 2>/dev/null | grep -q "^$service"; then
        log "$service not found."
        return 0
    fi

    output=$(systemctl disable --now "$service" 2>&1)
    rc=$?

    if [ "$rc" -eq 0 ]; then
        log "$service disabled successfully."
    else
        error "$output"
    fi
}

disable_service "NetworkManager.service"
disable_service "NetworkManager-dispatcher.service"
disable_service "welcome-message.service"
disable_service "emulationstation.service"

# ------------------------------------------------------------
# Check service file
# ------------------------------------------------------------
if [ ! -f "$SERVICE_SOURCE" ]; then
    error "OMG service file not found: $SERVICE_SOURCE"
    exit 1
fi

# ------------------------------------------------------------
# Install OMG service
# ------------------------------------------------------------
log "Installing $SERVICE_NAME..."

output=$(cp -f "$SERVICE_SOURCE" "$SERVICE_DEST" 2>&1)
rc=$?

if [ "$rc" -ne 0 ]; then
    error "$output"
    exit 1
fi

chmod 644 "$SERVICE_DEST"

# ------------------------------------------------------------
# Validate systemd service file
# ------------------------------------------------------------
log "Validating $SERVICE_NAME..."

output=$(systemd-analyze verify "$SERVICE_DEST" 2>&1)
rc=$?

if [ "$rc" -ne 0 ]; then
    error "$output"
    exit 1
fi

# ------------------------------------------------------------
# Reload systemd
# ------------------------------------------------------------
log "Reloading systemd..."

output=$(systemctl daemon-reload 2>&1)
rc=$?

if [ "$rc" -ne 0 ]; then
    error "$output"
    exit 1
fi

# ------------------------------------------------------------
# Configure hardware button handlers (pause.sh)
# ------------------------------------------------------------
PAUSE_SCRIPT="/usr/local/bin/pause.sh"
PAUSE_BACKUP="/usr/local/bin/pause.sh.backup"

log "Configuring hardware button handlers (pause.sh)..."

if [ -f "$PAUSE_SCRIPT" ]; then

    if [ ! -f "$PAUSE_BACKUP" ]; then
        log "Backing up original pause.sh..."

        output=$(cp -f "$PAUSE_SCRIPT" "$PAUSE_BACKUP" 2>&1)
        rc=$?

        if [ "$rc" -ne 0 ]; then
            error "$output"
            exit 1
        fi
    fi

    log "Replacing pause.sh with power-off command..."

    if ! cat << 'EOF' > "$PAUSE_SCRIPT"
#!/bin/bash
systemctl stop omg
sync
systemctl poweroff
EOF
    then
        error "Unable to write $PAUSE_SCRIPT."
        exit 1
    fi

    output=$(chmod +x "$PAUSE_SCRIPT" 2>&1)
    rc=$?

    if [ "$rc" -ne 0 ]; then
        error "$output"
        exit 1
    fi

    log "pause.sh configured to power off system."

else
    log "Warning: $PAUSE_SCRIPT not found."
fi

# ------------------------------------------------------------
# Enable OMG service
# ------------------------------------------------------------
log "Enabling $SERVICE_NAME..."

output=$(systemctl enable "$SERVICE_NAME" 2>&1)
rc=$?

if [ "$rc" -ne 0 ]; then
    error "$output"
    exit 1
fi

# ------------------------------------------------------------
# Do NOT start OMG service here
#
# dArkOS first boot must continue normally.
# OMG will start on the next boot.
# ------------------------------------------------------------
log ""
log "============================================================"
log "OMG INSTALLED"
log "============================================================"
log ""
log "Service:"
log "  $SERVICE_DEST"
log ""
log "OMG service has been enabled."
log "OMG service will start on the next boot."
log ""

exit 0
