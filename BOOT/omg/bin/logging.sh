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

# ------------------------------------------------------------
# OMG Logging
# ------------------------------------------------------------

LOG_ENABLED=false
LOG_CONTEXT="OMG"

timestamp()
{
    date '+%Y-%m-%d %H:%M:%S'
}

elapsed()
{
    local NOW
    NOW=$(date +%s%3N)
    echo "$((NOW - START_TIME)) ms"
}

init_logging()
{
    LOG_CONTEXT="$1"

    mkdir -p "$LOG_DIR"
    touch "$LOG_FILE" 2>/dev/null || true

    if [ "${OMG_CONFIG_VALUES[enable_logging]:-false}" = "true" ]; then
        LOG_ENABLED=true
    else
        LOG_ENABLED=false
    fi
}

log()
{
    if [ "$LOG_ENABLED" = "true" ]; then
        echo "$(timestamp) [OMG][$LOG_CONTEXT] $*" >> "$LOG_FILE"
    fi
}

error()
{
    if [ "$LOG_ENABLED" = "true" ]; then
        echo "$(timestamp) [OMG][$LOG_CONTEXT][ERROR] $*" >> "$LOG_FILE"
    fi
}
