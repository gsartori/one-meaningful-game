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
# OMG Stop Script
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

# RetroArch Network Command Interface
RETROARCH_HOST="127.0.0.1"
RETROARCH_PORT="55355"

# ------------------------------------------------------------
# Read configuration
# ------------------------------------------------------------
source "${OMG_DIR}/bin/config.sh"
load_omg_config || exit 1

# ------------------------------------------------------------
# Init logging
# ------------------------------------------------------------
source "${OMG_DIR}/bin/logging.sh"
init_logging "STOP"

# ------------------------------------------------------------
# Timing
# ------------------------------------------------------------
START_TIME=$(date +%s%3N)

# ------------------------------------------------------------
# Start
# ------------------------------------------------------------
log ""
log "============================================================"
log "OMG STOP STARTED"
log "============================================================"

log "PID: $$"
log "User: $(id -un)"
log "UID: $(id -u)"
log "Start timestamp: $(timestamp)"
log "============================================================"

# ------------------------------------------------------------
# Send command to retroarch
# ------------------------------------------------------------
send_retroarch_command()
{
    local COMMAND="$1"
    local OUTPUT
    local EXIT_CODE

    log "Sending ${COMMAND} command to RetroArch."
    log "Target: 127.0.0.1:55355"

    OUTPUT=$(
        echo -n "$COMMAND" |
        nc -u -w 1 127.0.0.1 55355 \
        2>&1
    )

    EXIT_CODE=$?

    if [ "$EXIT_CODE" -eq 0 ]; then
        log "${COMMAND} command sent successfully."

        if [ -n "$OUTPUT" ]; then
            log "nc output:"
            while IFS= read -r LINE; do
                log "nc: $LINE"
            done <<< "$OUTPUT"
        fi

        return 0
    fi

    error "Failed to send ${COMMAND} command."
    error "nc exit code: $EXIT_CODE"

    if [ -n "$OUTPUT" ]; then
        error "nc output:"
        while IFS= read -r LINE; do
            error "nc: $LINE"
        done <<< "$OUTPUT"
    else
        error "nc produced no diagnostic output."
    fi

    return "$EXIT_CODE"
}

# ------------------------------------------------------------
# Save and quit
# ------------------------------------------------------------
log "Stopping RetroArch."

send_retroarch_command "SAVE_FILES"
send_retroarch_command "CLOSE_CONTENT"
send_retroarch_command "QUIT"

# ------------------------------------------------------------
# Stop completed
# ------------------------------------------------------------
log "Stop command completed after $(elapsed)."

log "============================================================"
log "OMG STOP COMPLETED"
log "============================================================"

exit 0
