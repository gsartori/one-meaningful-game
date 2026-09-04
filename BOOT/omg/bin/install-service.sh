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
# OMG - Install Service
# ============================================================
set -u

SERVICE_NAME="omg.service"
OMG_DIR="/boot/omg"
SERVICE_SOURCE="${OMG_DIR}/bin/${SERVICE_NAME}"
SERVICE_DEST="/etc/systemd/system/${SERVICE_NAME}"

# ------------------------------------------------------------
# Logging
# ------------------------------------------------------------
log()
{
    echo "[OMG] $*"
}

error()
{
    echo "[OMG][ERROR] $*" >&2
}

# ------------------------------------------------------------
# Check root
# ------------------------------------------------------------
if [ "$(id -u)" -ne 0 ]; then
    error "This script must be run as root."
    exit 1
fi

# ------------------------------------------------------------
# Check service file
# ------------------------------------------------------------
if [ ! -f "$SERVICE_SOURCE" ]; then
    error "OMG service file not found:"
    error "$SERVICE_SOURCE"
    exit 1
fi

# ------------------------------------------------------------
# Install OMG service
# ------------------------------------------------------------
log "Installing $SERVICE_NAME..."

if ! cp -f "$SERVICE_SOURCE" "$SERVICE_DEST"; then
    error "Unable to install service:"
    error "$SERVICE_DEST"
    exit 1
fi

chmod 644 "$SERVICE_DEST"

# ------------------------------------------------------------
# Reload systemd
# ------------------------------------------------------------
log "Reloading systemd..."

if ! systemctl daemon-reload; then
    error "systemctl daemon-reload failed."
    exit 1
fi

# ------------------------------------------------------------
# Disable services used by dArkOS
# ------------------------------------------------------------
disable_service()
{
    local service="$1"
    log "Disabling $service."

    if ! systemctl list-unit-files "$service" --no-legend 2>/dev/null | grep -q "^$service"; then
        log "$service not found."
        return 0
    fi

    if systemctl disable --now "$service" 2>/dev/null; then
        log "$service disabled successfully."
    else
        log "Unable to disable $service."
    fi
}

disable_service "welcome-message.service"
disable_service "NetworkManager.service"
disable_service "NetworkManager-dispatcher.service"
disable_service "emulationstation.service"

# ------------------------------------------------------------
# Configure hardware button handlers (pause.sh)
# ------------------------------------------------------------
PAUSE_SCRIPT="/usr/local/bin/pause.sh"
PAUSE_BACKUP="/usr/local/bin/pause.sh.backup"

log "Configuring hardware button handlers (pause.sh)..."

if [ -f "$PAUSE_SCRIPT" ]; then
    if [ ! -f "$PAUSE_BACKUP" ]; then
        log "Backing up original pause.sh..."
        cp -f "$PAUSE_SCRIPT" "$PAUSE_BACKUP"
    fi

    log "Replacing pause.sh with power-off command..."
    cat << 'EOF' > "$PAUSE_SCRIPT"
#!/bin/bash
sync
systemctl poweroff
EOF
    chmod +x "$PAUSE_SCRIPT"
    log "pause.sh configured to power off system."
else
    log "Warning: $PAUSE_SCRIPT not found."
fi

# ------------------------------------------------------------
# Enable OMG service
# ------------------------------------------------------------
log "Enabling $SERVICE_NAME..."

if ! systemctl enable "$SERVICE_NAME"; then
    error "Unable to enable $SERVICE_NAME."
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
log "OMG SERVICE INSTALLED"
log "============================================================"
log ""
log "Service:"
log "  $SERVICE_DEST"
log ""
log "OMG service has been enabled."
log "OMG service will start on the next boot."
log ""

exit 0