#!/bin/bash

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