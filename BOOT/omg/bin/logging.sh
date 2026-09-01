#!/bin/bash

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

    if [ "${OMG_CONFIG_VALUES[enable_logging]:-false}" = "true" ]; then
        mkdir -p "$LOG_DIR"
        touch "$LOG_FILE" 2>/dev/null || true
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
