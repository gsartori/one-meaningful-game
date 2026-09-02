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
# OMG - One Meaningful Game
# Installation script
# ============================================================
set -u

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------
BOOT_DIR="/boot"

# OMG scripts
OMG_BOOT_DIR="${BOOT_DIR}/omg"

# OMG data
OMG_DIR="/roms/omg"

# Logs
LOG_DIR="${OMG_DIR}/logs"
LOG_FILE="${LOG_DIR}/omg.log"

# RetroArch configuration
CONFIG_DIR="${OMG_DIR}/config"
RETROARCH_CONFIG_DEST="${CONFIG_DIR}/retroarch.cfg"

# ROMs
ROM_DIR="${OMG_DIR}/roms"

# Global random rotation
RANDOM_INDEX_FILE="${OMG_DIR}/omg-random-index"

# Logo
OMG_LOGO="${OMG_DIR}/logo.bmp"

# Installation state
INSTALLED_FLAG="${OMG_DIR}/omg-installed"

# ------------------------------------------------------------
# Collection source
# ------------------------------------------------------------
COLLECTION_DIR="/roms/omg-collection"

# ------------------------------------------------------------
# System files
# ------------------------------------------------------------
LOGO="/boot/logo.bmp"
LOGO_BACKUP="/boot/logo-backup.bmp"
RETROARCH_CONFIG_ORIGINAL="/home/ark/.config/retroarch/retroarch.cfg"

# ------------------------------------------------------------
# Read configuration
# ------------------------------------------------------------
source "${OMG_BOOT_DIR}/bin/config.sh"
load_omg_config || exit 1

# ------------------------------------------------------------
# Init logging
# ------------------------------------------------------------
source "${OMG_BOOT_DIR}/bin/logging.sh"
init_logging "INSTALL"

# ------------------------------------------------------------
# Useful functions
# ------------------------------------------------------------
copy_folder()
{
    local source="$1"
    local destination="$2"

    rsync -a \
        --exclude='.*' \
        "$source/" "$destination/"
}

# ------------------------------------------------------------
# Timing
# ------------------------------------------------------------
START_TIME=$(date +%s%3N)

# ------------------------------------------------------------
# Create OMG directories
# ------------------------------------------------------------
mkdir -p "$OMG_DIR"
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

log "OMG_BOOT_DIR=$OMG_BOOT_DIR"
log "OMG_DIR=$OMG_DIR"
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

log "Source collection:"
log "$SOURCE_DIR"

log "Source ROM directory:"
log "$SOURCE_ROM_DIR"

# ------------------------------------------------------------
# Check collection
# ------------------------------------------------------------
if [ ! -d "$SOURCE_DIR" ]; then
    error "Collection not found:"
    error "$SOURCE_DIR"
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
# Install OMG logo
# ------------------------------------------------------------
log "Installing OMG logo:"
log "$SOURCE_LOGO -> $OMG_LOGO"

if ! cp -f "$SOURCE_LOGO" "$OMG_LOGO"; then
    error "Unable to install OMG logo."
    exit 1
fi

# ------------------------------------------------------------
# Install boot logo
# ------------------------------------------------------------
log "Installing OMG boot logo:"
log "$OMG_LOGO -> $LOGO"

if ! cp -f "$OMG_LOGO" "$LOGO"; then
    error "Unable to install boot logo."
    exit 1
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
# RetroArch configuration
# ------------------------------------------------------------
log "Copying original RetroArch configuration."

if [ ! -f "$RETROARCH_CONFIG_ORIGINAL" ]; then
    error "Original RetroArch configuration not found:"
    error "$RETROARCH_CONFIG_ORIGINAL"
    exit 1
fi

if ! cp -f \
    "$RETROARCH_CONFIG_ORIGINAL" \
    "$RETROARCH_CONFIG_DEST"; then
    error "Unable to copy RetroArch configuration."
    exit 1
fi

# ------------------------------------------------------------
# RetroArch input configuration
# ------------------------------------------------------------
log "Configuring RetroArch input controls."

# Disable single-button / keyboard emulator exit.
sed -i \
    -e 's/^input_exit_emulator[[:space:]]*=.*/input_exit_emulator = "nul"/' \
    -e 's/^input_exit_emulator_axis[[:space:]]*=.*/input_exit_emulator_axis = "nul"/' \
    -e 's/^input_exit_emulator_btn[[:space:]]*=.*/input_exit_emulator_btn = "nul"/' \
    -e 's/^input_exit_emulator_mbtn[[:space:]]*=.*/input_exit_emulator_mbtn = "nul"/' \
    "$RETROARCH_CONFIG_DEST"

# Disable gamepad quit combination.
sed -i \
    -e 's/^input_quit_gamepad_combo[[:space:]]*=.*/input_quit_gamepad_combo = "0"/' \
    "$RETROARCH_CONFIG_DEST"

# Disable single-button menu toggle.
sed -i \
    -e 's/^input_menu_toggle[[:space:]]*=.*/input_menu_toggle = "nul"/' \
    -e 's/^input_menu_toggle_axis[[:space:]]*=.*/input_menu_toggle_axis = "nul"/' \
    -e 's/^input_menu_toggle_btn[[:space:]]*=.*/input_menu_toggle_btn = "nul"/' \
    -e 's/^input_menu_toggle_mbtn[[:space:]]*=.*/input_menu_toggle_mbtn = "nul"/' \
    "$RETROARCH_CONFIG_DEST"

# Enable SELECT + START for RetroArch menu.
sed -i \
    -e 's/^input_menu_toggle_gamepad_combo[[:space:]]*=.*/input_menu_toggle_gamepad_combo = "4"/' \
    "$RETROARCH_CONFIG_DEST"

# Disable emulator exit completely.
sed -i \
    -e 's/^input_exit_emulator[[:space:]]*=.*/input_exit_emulator = "nul"/' \
    -e 's/^input_exit_emulator_axis[[:space:]]*=.*/input_exit_emulator_axis = "nul"/' \
    -e 's/^input_exit_emulator_btn[[:space:]]*=.*/input_exit_emulator_btn = "nul"/' \
    -e 's/^input_exit_emulator_mbtn[[:space:]]*=.*/input_exit_emulator_mbtn = "nul"/' \
    "$RETROARCH_CONFIG_DEST"

log "RetroArch input configuration completed."

# ------------------------------------------------------------
# RetroArch OMG directories and UI
# ------------------------------------------------------------
log "Configuring RetroArch OMG directories and UI."

# Create OMG RetroArch directories.
mkdir -p \
    "${CONFIG_DIR}/saves" \
    "${CONFIG_DIR}/states" \
    "${CONFIG_DIR}/system" \
    "${CONFIG_DIR}/remaps" \
    "${CONFIG_DIR}/cache"

# Remove existing OMG directory definitions and UI settings.
sed -i \
    -e '/^[[:space:]]*savefile_directory[[:space:]]*=/d' \
    -e '/^[[:space:]]*savestate_directory[[:space:]]*=/d' \
    -e '/^[[:space:]]*system_directory[[:space:]]*=/d' \
    -e '/^[[:space:]]*input_remapping_directory[[:space:]]*=/d' \
    -e '/^[[:space:]]*cache_directory[[:space:]]*=/d' \
    -e '/^[[:space:]]*menu_timedate_enable[[:space:]]*=/d' \
    -e '/^[[:space:]]*menu_battery_level_enable[[:space:]]*=/d' \
    -e '/^[[:space:]]*notification_show_remap_load[[:space:]]*=/d' \
    "$RETROARCH_CONFIG_DEST"

# Add OMG directory definitions and UI settings.
cat >> "$RETROARCH_CONFIG_DEST" <<EOF

# ------------------------------------------------------------
# OMG directories
# ------------------------------------------------------------

savefile_directory = "${CONFIG_DIR}/saves"
savestate_directory = "${CONFIG_DIR}/states"
system_directory = "${CONFIG_DIR}/system"
input_remapping_directory = "${CONFIG_DIR}/remaps"
cache_directory = "${CONFIG_DIR}/cache"

# ------------------------------------------------------------
# OMG UI
# ------------------------------------------------------------
menu_timedate_enable = "false"
menu_battery_level_enable = "true"
notification_show_remap_load = "false"
EOF

log "RetroArch OMG directories configured:"
log "Save files: ${CONFIG_DIR}/saves"
log "Save states: ${CONFIG_DIR}/states"
log "System: ${CONFIG_DIR}/system"
log "Remaps: ${CONFIG_DIR}/remaps"
log "Cache: ${CONFIG_DIR}/cache"

# ------------------------------------------------------------
# RetroArch core options
# ------------------------------------------------------------
RETROARCH_CORE_OPTIONS="${CONFIG_DIR}/retroarch-core-options.cfg"

log "Creating RetroArch core options configuration."

cat > "$RETROARCH_CORE_OPTIONS" <<'EOF'
# ============================================================
# OMG - RetroArch core options
# ============================================================

# ------------------------------------------------------------
# MAME 2003-Plus
# ------------------------------------------------------------

mame2003-plus_skip_disclaimer = "enabled"
mame2003-plus_skip_warnings = "enabled"
EOF

if [ ! -f "$RETROARCH_CORE_OPTIONS" ]; then
    error "Unable to create RetroArch core options:"
    error "$RETROARCH_CORE_OPTIONS"
    exit 1
fi

log "RetroArch core options installed:"
log "$RETROARCH_CORE_OPTIONS"

# ------------------------------------------------------------
# Make RetroArch use OMG core options
# ------------------------------------------------------------
log "Configuring RetroArch core options path."

if grep -q '^core_options_path' "$RETROARCH_CONFIG_DEST"; then
    sed -i \
        "s|^core_options_path[[:space:]]*=.*|core_options_path = \"$RETROARCH_CORE_OPTIONS\"|" \
        "$RETROARCH_CONFIG_DEST"
else
    echo "core_options_path = \"$RETROARCH_CORE_OPTIONS\"" \
        >> "$RETROARCH_CONFIG_DEST"
fi

# ------------------------------------------------------------
# Copy custom OMG configuration
# ------------------------------------------------------------
OMG_BOOT_CONFIG_DIR="${OMG_BOOT_DIR}/config"

log "Installing custom OMG configuration files."

if [ -d "$OMG_BOOT_CONFIG_DIR" ]; then
    log "Copying custom configuration:"
    log "$OMG_BOOT_CONFIG_DIR -> $CONFIG_DIR"

    copy_folder "$OMG_BOOT_CONFIG_DIR" "$CONFIG_DIR"

else
    log "No custom OMG configuration directory found:"
    log "$OMG_BOOT_CONFIG_DIR"
fi

# ------------------------------------------------------------
# Sync RetroArch configuration
# ------------------------------------------------------------
sync

log "RetroArch core options path configured:"
log "$RETROARCH_CORE_OPTIONS"

# ------------------------------------------------------------
# Backup pause.sh and replace it with finish.sh
# ------------------------------------------------------------
PAUSE_SCRIPT="/usr/local/bin/pause.sh"
PAUSE_BACKUP="/usr/local/bin/pause.sh.backup"
FINISH_SCRIPT="/usr/local/bin/finish.sh"

log "Backing up pause.sh and replacing it with finish.sh."

# ------------------------------------------------------------
# Check required files
# ------------------------------------------------------------
if [ ! -f "$PAUSE_SCRIPT" ]; then
    error "pause.sh not found:"
    error "$PAUSE_SCRIPT"
    exit 1
fi

if [ ! -f "$FINISH_SCRIPT" ]; then
    error "finish.sh not found:"
    error "$FINISH_SCRIPT"
    exit 1
fi

# ------------------------------------------------------------
# Backup original pause.sh
# ------------------------------------------------------------
if [ -f "$PAUSE_BACKUP" ]; then
    log "pause.sh backup already exists."
    log "Keeping:"
    log "$PAUSE_BACKUP"
else
    log "Creating pause.sh backup:"
    log "$PAUSE_SCRIPT -> $PAUSE_BACKUP"

    if ! cp -f "$PAUSE_SCRIPT" "$PAUSE_BACKUP"; then
        error "Unable to backup pause.sh."
        exit 1
    fi
fi

# ------------------------------------------------------------
# Replace pause.sh with finish.sh
# ------------------------------------------------------------
log "Replacing pause.sh with finish.sh content."

if ! cp -f "$FINISH_SCRIPT" "$PAUSE_SCRIPT"; then
    error "Unable to replace pause.sh."
    exit 1
fi

# ------------------------------------------------------------
# Permissions
# ------------------------------------------------------------
chmod +x "$PAUSE_SCRIPT"

log "pause.sh successfully replaced."

# ------------------------------------------------------------
# Installation flag
# ------------------------------------------------------------

# IMPORTANT:
# This must be the last operation before reboot.
#
# run.sh uses this file to know whether OMG has been installed.
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
log "OMG INSTALLATION COMPLETE"
log "============================================================"

log "Collection: $SOURCE_DIR"

log "ROM structure:"
log "$ROM_DIR/mame2003"
log "$ROM_DIR/mame2010"
log "$ROM_DIR/mame"

log "Global random index:"
log "$RANDOM_INDEX_FILE"

log "Logo:"
log "$OMG_LOGO"

log "RetroArch config:"
log "$RETROARCH_CONFIG_DEST"

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
