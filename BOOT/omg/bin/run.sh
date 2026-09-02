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
# Runtime script
# ============================================================
set -u

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------
BOOT_DIR="/boot"

# OMG scripts
OMG_BOOT_DIR="${BOOT_DIR}/omg"
INSTALL_SCRIPT="${OMG_BOOT_DIR}/bin/install.sh"

# OMG data
OMG_DIR="/roms/omg"

# Installation state
INSTALLED_FLAG="${OMG_DIR}/omg-installed"
BOOT_COUNT_FILE="${OMG_DIR}/omg-boot-count"

# Random rotation state
RANDOM_INDEX_FILE="${OMG_DIR}/omg-random-index"

# Logs
LOG_DIR="${OMG_DIR}/logs"
LOG_FILE="${LOG_DIR}/omg.log"

# RetroArch configuration
CONFIG_DIR="${OMG_DIR}/config"
RETROARCH_CONFIG="${CONFIG_DIR}/retroarch.cfg"

# ROM root
ROM_ROOT="${OMG_DIR}/roms"

# ROM directories
ROM_DIR_MAME2003="${ROM_ROOT}/mame2003"
ROM_DIR_MAME2010="${ROM_ROOT}/mame2010"
ROM_DIR_MAME="${ROM_ROOT}/mame"

# Random directories
RANDOM_DIR_MAME2003="${ROM_DIR_MAME2003}/random"
RANDOM_DIR_MAME2010="${ROM_DIR_MAME2010}/random"
RANDOM_DIR_MAME="${ROM_DIR_MAME}/random"

# ------------------------------------------------------------
# RetroArch
# ------------------------------------------------------------
RETROARCH="/usr/local/bin/retroarch"

# ------------------------------------------------------------
# RetroArch cores
# ------------------------------------------------------------
CORE_MAME2003="/home/ark/.config/retroarch/cores/mame2003_plus_libretro.so"
CORE_MAME2010="/home/ark/.config/retroarch/cores/mame2010_libretro.so"
CORE_MAME="/home/ark/.config/retroarch/cores/mame_libretro.so"
CORE=""

# ------------------------------------------------------------
# Read configuration
# ------------------------------------------------------------
source "${OMG_BOOT_DIR}/bin/config.sh"
load_omg_config || exit 1

# ------------------------------------------------------------
# Init logging
# ------------------------------------------------------------
source "${OMG_BOOT_DIR}/bin/logging.sh"
init_logging "RUN"

# ------------------------------------------------------------
# Timing
# ------------------------------------------------------------
START_TIME=$(date +%s%3N)

# ------------------------------------------------------------
# Select core from ROM directory
# ------------------------------------------------------------
select_core()
{
    case "$ROM" in

        "$ROM_DIR_MAME2003"/*)
            CORE="$CORE_MAME2003"

            log "ROM belongs to mame2003."
            log "Using MAME2003-Plus core:"
            log "$CORE"
            ;;

        "$ROM_DIR_MAME2010"/*)
            CORE="$CORE_MAME2010"

            log "ROM belongs to mame2010."
            log "Using MAME2010 core:"
            log "$CORE"
            ;;

        "$ROM_DIR_MAME"/*)
            CORE="$CORE_MAME"

            log "ROM belongs to mame."
            log "Using newer MAME core:"
            log "$CORE"
            ;;

        *)
            error "Unable to determine core."
            error "ROM=$ROM"
            return 1
            ;;
    esac

    return 0
}

# ------------------------------------------------------------
# Check if file is a valid ROM
# ------------------------------------------------------------
is_valid_rom()
{
    local FILE="$1"
    local BASENAME

    BASENAME=$(basename "$FILE")

    # Only ZIP files are valid ROMs.
    case "$BASENAME" in
        *.zip|*.ZIP)
            ;;
        *)
            return 1
            ;;
    esac

    # Reject hidden files and macOS AppleDouble files.
    case "$BASENAME" in
        .*|._*)
            return 1
            ;;
    esac

    return 0
}

# ------------------------------------------------------------
# Find first alphabetical ROM
# ------------------------------------------------------------
find_first_rom()
{
    local FILE

    while IFS= read -r FILE; do

        if is_valid_rom "$FILE"; then
            echo "$FILE"
            return 0
        fi

    done < <(
        find \
            "$ROM_DIR_MAME2003" \
            "$ROM_DIR_MAME2010" \
            "$ROM_DIR_MAME" \
            -maxdepth 1 \
            -type f \
            -printf '%p\n' 2>/dev/null |
        sort -f
    )

    return 1
}

# ------------------------------------------------------------
# Build global random ROM list
# ------------------------------------------------------------
build_random_list()
{
    local FILE

    while IFS= read -r FILE; do

        if is_valid_rom "$FILE"; then
            echo "$FILE"
        fi

    done < <(
        find \
            "$RANDOM_DIR_MAME2003" \
            "$RANDOM_DIR_MAME2010" \
            "$RANDOM_DIR_MAME" \
            -maxdepth 1 \
            -type f \
            -printf '%p\n' 2>/dev/null |
        sort -f
    )
}

# ------------------------------------------------------------
# Select next random-rotation ROM
# ------------------------------------------------------------
select_random_rotation_rom()
{
    local RANDOM_LIST
    local RANDOM_COUNT
    local RANDOM_INDEX
    local SELECTED_ROM

    RANDOM_LIST=$(build_random_list)

    if [ -z "$RANDOM_LIST" ]; then
        log "No ROMs found in random directories."
        return 1
    fi

    RANDOM_COUNT=$(printf '%s\n' "$RANDOM_LIST" | wc -l)

    if [ -f "$RANDOM_INDEX_FILE" ]; then
        RANDOM_INDEX=$(cat "$RANDOM_INDEX_FILE" 2>/dev/null)
    else
        RANDOM_INDEX=0
    fi

    if ! [[ "$RANDOM_INDEX" =~ ^[0-9]+$ ]]; then
        RANDOM_INDEX=0
    fi

    RANDOM_INDEX=$((RANDOM_INDEX % RANDOM_COUNT))

    SELECTED_ROM=$(
        printf '%s\n' "$RANDOM_LIST" |
        sed -n "$((RANDOM_INDEX + 1))p"
    )

    if [ -z "$SELECTED_ROM" ]; then
        error "Unable to select ROM from random rotation."
        return 1
    fi

    # Save next index.
    NEXT_INDEX=$((RANDOM_INDEX + 1))

    if [ "$NEXT_INDEX" -ge "$RANDOM_COUNT" ]; then
        NEXT_INDEX=0
    fi

    if ! echo "$NEXT_INDEX" > "$RANDOM_INDEX_FILE"; then
        error "Unable to update random rotation index:"
        error "$RANDOM_INDEX_FILE"
        return 1
    fi

    # Force filesystem buffers to disk.
    sync

    ROM="$SELECTED_ROM"

    log "Global random rotation:"
    log "Random ROM count: $RANDOM_COUNT"
    log "Current random index: $RANDOM_INDEX"
    log "Next random index: $NEXT_INDEX"
    log "Selected random ROM:"
    log "$ROM"

    return 0
}

# ------------------------------------------------------------
# Start
# ------------------------------------------------------------
log ""
log "============================================================"
log "OMG RUN STARTED"
log "============================================================"

log "PID: $$"
log "User: $(id -un)"
log "UID: $(id -u)"
log "Start timestamp: $(timestamp)"

log "OMG_BOOT_DIR=$OMG_BOOT_DIR"
log "OMG_DIR=$OMG_DIR"
log "INSTALL_SCRIPT=$INSTALL_SCRIPT"
log "INSTALLED_FLAG=$INSTALLED_FLAG"
log "BOOT_COUNT_FILE=$BOOT_COUNT_FILE"
log "RANDOM_INDEX_FILE=$RANDOM_INDEX_FILE"

log "LOG_DIR=$LOG_DIR"
log "CONFIG_DIR=$CONFIG_DIR"

log "ROM_ROOT=$ROM_ROOT"

log "ROM_DIR_MAME2003=$ROM_DIR_MAME2003"
log "ROM_DIR_MAME2010=$ROM_DIR_MAME2010"
log "ROM_DIR_MAME=$ROM_DIR_MAME"

log "RANDOM_DIR_MAME2003=$RANDOM_DIR_MAME2003"
log "RANDOM_DIR_MAME2010=$RANDOM_DIR_MAME2010"
log "RANDOM_DIR_MAME=$RANDOM_DIR_MAME"

log "RETROARCH=$RETROARCH"

log "CORE_MAME2003=$CORE_MAME2003"
log "CORE_MAME2010=$CORE_MAME2010"
log "CORE_MAME=$CORE_MAME"

log "============================================================"

# ------------------------------------------------------------
# Check OMG collection
# ------------------------------------------------------------
if [ ! -d "/roms/omg-collection" ]; then
    log "============================================================"
    log "OMG COLLECTION NOT FOUND"
    log "Expected directory:"
    log "/roms/omg-collection"
    log "Waiting for user to install the OMG collection."
    log "============================================================"

    echo ""
    echo "============================================================"
    echo ""
    echo "                   ONE MEANINGFUL GAME"
    echo ""
    echo " Copy the '/EASYROM/omg-collection' in the EASYROM partition"
    echo "                             &"
    echo "                     Reboot the system"
    echo ""
    echo "============================================================"
    echo ""

    exit 0
fi

# ------------------------------------------------------------
# First boot installation
# ------------------------------------------------------------
if [ ! -f "$INSTALLED_FLAG" ]; then

    log "============================================================"
    log "OMG IS NOT INSTALLED"
    log "Starting installation."
    log "============================================================"

    if [ ! -f "$INSTALL_SCRIPT" ]; then
        error "Installation script not found:"
        error "$INSTALL_SCRIPT"
        exit 1
    fi

    log "Running installation script:"
    log "$INSTALL_SCRIPT"

    if ! /bin/bash "$INSTALL_SCRIPT"; then
        error "OMG installation failed."
        exit 1
    fi

    if [ ! -f "$INSTALLED_FLAG" ]; then
        error "Installation script completed but installation flag"
        error "was not created:"
        error "$INSTALLED_FLAG"
        exit 1
    fi

    log "OMG installation completed successfully."
else
    log "OMG is already installed."
fi

# ------------------------------------------------------------
# Setting max performance
# ------------------------------------------------------------
log "Setting CPU governor to max performance."

for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    if [ -w "$f" ]; then
        if echo performance > "$f" 2>/dev/null; then
            log "Governor set to performance:"
            log "$f"
        else
            log "Unable to set governor:"
            log "$f"
        fi
    fi
done

# ------------------------------------------------------------
# Boot counter
# ------------------------------------------------------------
if [ -f "$BOOT_COUNT_FILE" ]; then
    BOOT_COUNT=$(cat "$BOOT_COUNT_FILE" 2>/dev/null)
else
    BOOT_COUNT=0
fi

if ! [[ "$BOOT_COUNT" =~ ^[0-9]+$ ]]; then
    BOOT_COUNT=0
fi

BOOT_COUNT=$((BOOT_COUNT + 1))

if ! echo "$BOOT_COUNT" > "$BOOT_COUNT_FILE"; then
    error "Unable to update boot counter:"
    error "$BOOT_COUNT_FILE"
    exit 1
fi

# Force filesystem buffers to disk.
sync

log "Boot count: $BOOT_COUNT"
log "Boot counter phase completed after $(elapsed)."

# ------------------------------------------------------------
# ROM selection
# ------------------------------------------------------------
ROM=""

# ------------------------------------------------------------
# Every second boot:
# global random rotation
# ------------------------------------------------------------
if [ $((BOOT_COUNT % 2)) -eq 0 ]; then
    log "Alternative boot - Selecting next ROM from global random rotation."

    if ! select_random_rotation_rom; then
        log "Random rotation unavailable."
        log "Falling back to first alphabetical ROM."
        ROM=$(find_first_rom)
    fi
else
    log "Normal boot - selecting first ROM alphabetically."
    ROM=$(find_first_rom)
fi

log "ROM selection completed after $(elapsed)."

# ------------------------------------------------------------
# Check ROM
# ------------------------------------------------------------
if [ -z "$ROM" ]; then
    error "No ROM found."
    error "Searched:"
    error "$ROM_DIR_MAME2003"
    error "$ROM_DIR_MAME2010"
    error "$ROM_DIR_MAME"
    exit 1
fi

log "Selected ROM:"
log "$ROM"

# ------------------------------------------------------------
# Select core
# ------------------------------------------------------------
if ! select_core; then
    exit 1
fi

log "Final core selection:"
log "ROM=$ROM"
log "CORE=$CORE"

# ------------------------------------------------------------
# Check RetroArch
# ------------------------------------------------------------
if [ ! -x "$RETROARCH" ]; then
    error "RetroArch not found or not executable:"
    error "$RETROARCH"
    exit 1
fi

log "RetroArch executable exists and is executable."

# ------------------------------------------------------------
# Check selected core
# ------------------------------------------------------------
if [ ! -f "$CORE" ]; then
    error "Selected core not found:"
    error "$CORE"
    exit 1
fi

log "Selected core exists:"
log "$CORE"

# ------------------------------------------------------------
# Check RetroArch configuration
# ------------------------------------------------------------
if [ ! -f "$RETROARCH_CONFIG" ]; then
    error "RetroArch configuration not found:"
    error "$RETROARCH_CONFIG"
    exit 1
fi

log "RetroArch configuration exists:"
log "$RETROARCH_CONFIG"

# ------------------------------------------------------------
# Start RetroArch
# ------------------------------------------------------------
log "============================================================"
log "STARTING RETROARCH"
log "============================================================"

log "Timestamp: $(timestamp)"
log "Elapsed since script start: $(elapsed)"

log "RETROARCH=$RETROARCH"
log "Config=$RETROARCH_CONFIG"
log "CORE=$CORE"
log "ROM=$ROM"

log "============================================================"

# ------------------------------------------------------------
# RetroArch environment
# ------------------------------------------------------------
log "Saving RetroArch environment."

HOME=/home/ark \
USER=root \
LOGNAME=root \
TERM=linux

log "Launching RetroArch."

HOME=/home/ark \
USER=root \
LOGNAME=root \
TERM=linux \
"$RETROARCH" \
    --verbose \
    -c "$RETROARCH_CONFIG" \
    -L "$CORE" \
    "$ROM" \
    >> "$LOG_FILE" 2>&1

RETROARCH_EXIT=$?

# ------------------------------------------------------------
# RetroArch exit
# ------------------------------------------------------------
log "============================================================"
log "RetroArch exited."
log "============================================================"

log "Timestamp: $(timestamp)"
log "Elapsed since script start: $(elapsed)"
log "RetroArch exit code: $RETROARCH_EXIT"

log "============================================================"

exit "$RETROARCH_EXIT"
