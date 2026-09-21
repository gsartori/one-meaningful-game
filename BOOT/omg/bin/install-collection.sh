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
# OMG Collection Install
# ============================================================
set -u

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------
BOOT_DIR="/boot"

# OMG scripts
OMG_DIR="${BOOT_DIR}/omg"

# OMG data
OMG_ROMS_DIR="/roms/omg"

# Logs
LOG_DIR="${OMG_DIR}/logs"
LOG_FILE="${LOG_DIR}/omg.log"

# RetroArch configuration
CONFIG_DIR="${OMG_ROMS_DIR}/config"

# ROMs
ROM_DIR="${OMG_ROMS_DIR}/roms"

# Global random rotation
RANDOM_INDEX_FILE="${OMG_ROMS_DIR}/omg-random-index"

# Installation state
INSTALLED_FLAG="${OMG_ROMS_DIR}/omg-installed"

# ------------------------------------------------------------
# Collection source
# ------------------------------------------------------------
COLLECTION_DIR="/roms/omg-collection"

# ------------------------------------------------------------
# System files
# ------------------------------------------------------------
LOGO="/boot/logo.bmp"
LOGO_BACKUP="/boot/logo-backup.bmp"

LOW_BATTERY="/boot/low_battery.bmp"
LOW_BATTERY_BACKUP="/boot/low_battery-backup.bmp"

# ------------------------------------------------------------
# Read configuration
# ------------------------------------------------------------
source "${OMG_DIR}/bin/config.sh"
load_omg_config || exit 1

# ------------------------------------------------------------
# Init logging
# ------------------------------------------------------------
source "${OMG_DIR}/bin/logging.sh"
init_logging "INSTALL-COLLECTION"

# ------------------------------------------------------------
# Useful functions
# ------------------------------------------------------------
copy_folder()
{
    local SRC="$1"
    local DST="$2"

    rsync -r \
        --no-owner \
        --no-group \
        --no-perms \
        --exclude='.*' \
        "$SRC/" "$DST/"
}

# ------------------------------------------------------------
# Timing
# ------------------------------------------------------------
START_TIME=$(date +%s%3N)

# ------------------------------------------------------------
# Create OMG directories
# ------------------------------------------------------------
mkdir -p "$OMG_ROMS_DIR"
mkdir -p "$LOG_DIR"
mkdir -p "$CONFIG_DIR"
mkdir -p "$ROM_DIR"

# ------------------------------------------------------------
# Start
# ------------------------------------------------------------
log ""
log "============================================================"
log "OMG INSTALLATION STARTED"
log "============================================================"

log "OMG_DIR=$OMG_DIR"
log "OMG_ROMS_DIR=$OMG_ROMS_DIR"
log "COLLECTION_DIR=$COLLECTION_DIR"
log "ROM_DIR=$ROM_DIR"
log "LOG_DIR=$LOG_DIR"
log "CONFIG_DIR=$CONFIG_DIR"
log "RANDOM_INDEX_FILE=$RANDOM_INDEX_FILE"

# ------------------------------------------------------------
# Get collection to install
# ------------------------------------------------------------
COLLECTION_NAME="${OMG_CONFIG_VALUES[install_collection]:-}"

if [ -z "$COLLECTION_NAME" ]; then
    error "install_collection is not configured."

    show_message \
"No OMG collection has been configured.\n\n\
The 'install_collection' value is missing from omg.cfg.\n\n\
Please configure a collection and reboot the system."

    exit 1
fi

log "Installation requested for collection:"
log "$COLLECTION_NAME"

# ------------------------------------------------------------
# Source collection
# ------------------------------------------------------------
SOURCE_DIR="${COLLECTION_DIR}/${COLLECTION_NAME}"
SOURCE_ROM_DIR="${SOURCE_DIR}/roms"

SOURCE_LOGO="${SOURCE_DIR}/logo.bmp"
SOURCE_LOW_BATTERY="${SOURCE_DIR}/low_battery.bmp"

log "Source collection:"
log "$SOURCE_DIR"

log "Source ROM directory:"
log "$SOURCE_ROM_DIR"

log "Source logo:"
log "$SOURCE_LOGO"

log "Source low battery image:"
log "$SOURCE_LOW_BATTERY"

# ------------------------------------------------------------
# Check collection
# ------------------------------------------------------------
if [ ! -d "$SOURCE_DIR" ]; then
    error "Collection not found:"
    error "$SOURCE_DIR"

    show_message \
"OMG collection not found.\n\n\
Requested collection:\n\
${COLLECTION_NAME}\n\n\
Expected location:\n\
${SOURCE_DIR}\n\n\
Please copy the '${COLLECTION_NAME}' collection into:\n\
/EASYROMS/omg-collection\n\n\
Then reboot the system."

    exit 1
fi

if [ ! -d "$SOURCE_ROM_DIR" ]; then
    error "ROM directory not found:"
    error "$SOURCE_ROM_DIR"
    exit 1
fi

if [ ! -f "$SOURCE_LOGO" ]; then
    error "Collection logo not found:"
    error "$SOURCE_LOGO"
    exit 1
fi

# ------------------------------------------------------------
# Backup original logo
# ------------------------------------------------------------
if [ -f "$LOGO_BACKUP" ]; then
    log "Original logo backup already exists."
    log "Keeping:"
    log "$LOGO_BACKUP"
else
    if [ ! -f "$LOGO" ]; then
        error "Original logo not found:"
        error "$LOGO"
        exit 1
    fi

    log "Backing up original logo:"
    log "$LOGO -> $LOGO_BACKUP"

    if ! cp -f "$LOGO" "$LOGO_BACKUP"; then
        error "Unable to backup original logo."
        exit 1
    fi
fi

# ------------------------------------------------------------
# Install boot logo
# ------------------------------------------------------------
log "Installing OMG boot logo:"
log "$SOURCE_LOGO -> $LOGO"

if ! cp -f "$SOURCE_LOGO" "$LOGO"; then
    error "Unable to install boot logo."
    exit 1
fi

# ------------------------------------------------------------
# Backup original low battery image
# ------------------------------------------------------------
if [ -f "$SOURCE_LOW_BATTERY" ]; then

    if [ -f "$LOW_BATTERY_BACKUP" ]; then
        log "Original low battery image backup already exists."
        log "Keeping:"
        log "$LOW_BATTERY_BACKUP"
    else
        if [ -f "$LOW_BATTERY" ]; then
            log "Backing up original low battery image:"
            log "$LOW_BATTERY -> $LOW_BATTERY_BACKUP"

            if ! cp -f "$LOW_BATTERY" "$LOW_BATTERY_BACKUP"; then
                error "Unable to backup original low battery image."
                exit 1
            fi
        else
            log "No existing low battery image found."
            log "No backup required."
        fi
    fi

    # --------------------------------------------------------
    # Install custom low battery image
    # --------------------------------------------------------
    log "Installing OMG low battery image:"
    log "$SOURCE_LOW_BATTERY -> $LOW_BATTERY"

    if ! cp -f "$SOURCE_LOW_BATTERY" "$LOW_BATTERY"; then
        error "Unable to install low battery image."
        exit 1
    fi

else
    log "No custom low battery image found in collection."
    log "Expected:"
    log "$SOURCE_LOW_BATTERY"
    log "Keeping existing:"
    log "$LOW_BATTERY"
fi

# ------------------------------------------------------------
# Install ROM collection
# ------------------------------------------------------------
log "Removing previous OMG ROM collection."
rm -rf "$ROM_DIR"

log "Creating OMG ROM directory."
mkdir -p "$ROM_DIR"

log "Copying ROM collection:"
log "$SOURCE_ROM_DIR -> $ROM_DIR"

if ! cp -a "$SOURCE_ROM_DIR/." "$ROM_DIR/"; then
    error "Unable to copy ROM collection."
    exit 1
fi

# ------------------------------------------------------------
# Log installed ROM structure
# ------------------------------------------------------------
log "Installed ROM directories:"

find "$ROM_DIR" \
    -mindepth 1 \
    -maxdepth 2 \
    -type d \
    -print >> "$LOG_FILE" 2>/dev/null || true

# ------------------------------------------------------------
# Reset global random rotation
# ------------------------------------------------------------
log "Resetting global random rotation."

if ! echo "0" > "$RANDOM_INDEX_FILE"; then
    error "Unable to reset random rotation index:"
    error "$RANDOM_INDEX_FILE"
    exit 1
fi

# ------------------------------------------------------------
# Custom OMG configuration
# ------------------------------------------------------------
OMG_BOOT_CONFIG_DIR="${OMG_DIR}/config"

log "Installing custom OMG configuration files."

if [ -d "$OMG_BOOT_CONFIG_DIR" ]; then

    log "Copying custom configuration:"
    log "$OMG_BOOT_CONFIG_DIR -> $CONFIG_DIR"

    copy_folder "$OMG_BOOT_CONFIG_DIR" "$CONFIG_DIR"
else
    error "OMG configuration directory not found:"
    error "$OMG_BOOT_CONFIG_DIR"
    exit 1
fi

# ------------------------------------------------------------
# Sync configuration
# ------------------------------------------------------------
sync

log "OMG configuration installed:"
log "$CONFIG_DIR"

# ------------------------------------------------------------
# Installation flag
# ------------------------------------------------------------

# IMPORTANT:
# This must be the last operation before reboot.
#
# start.sh uses this file to know whether OMG has been installed.
#
# If installation fails before this point, the flag does not
# exist and installation will be attempted again on next boot.
log "Creating installation flag:"
log "$INSTALLED_FLAG"

if ! touch "$INSTALLED_FLAG"; then
    error "Unable to create installation flag."
    exit 1
fi

# ------------------------------------------------------------
# Complete
# ------------------------------------------------------------
log ""
log "============================================================"
log "OMG COLLECTION INSTALLATION COMPLETE"
log "============================================================"

log "Collection: $SOURCE_DIR"

log "ROM structure:"
log "$ROM_DIR/<core>"

log "Global random index:"
log "$RANDOM_INDEX_FILE"

log "Boot logo:"
log "$LOGO"

log "Low battery image:"
if [ -f "$LOW_BATTERY" ]; then
    log "$LOW_BATTERY"
else
    log "Not installed / existing image preserved"
fi

log "OMG configuration:"
log "$CONFIG_DIR"

log "Installation flag:"
log "$INSTALLED_FLAG"

log "Elapsed:"
log "$(elapsed)"

log "============================================================"
log ""

# ------------------------------------------------------------
# Reboot
# ------------------------------------------------------------
log "Rebooting system..."
reboot

exit 0
