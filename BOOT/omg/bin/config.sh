#!/bin/bash

# ------------------------------------------------------------
# OMG configuration
# ------------------------------------------------------------

OMG_CONFIG="/boot/omg/config.txt"

declare -A OMG_CONFIG_VALUES

load_omg_config()
{
    local KEY
    local VALUE

    if [ ! -f "$OMG_CONFIG" ]; then
        return 1
    fi

    while IFS='=' read -r KEY VALUE; do

        # Ignore empty lines.
        [ -z "$KEY" ] && continue

        # Ignore comments.
        case "$KEY" in
            \#*)
                continue
                ;;
        esac

        # Remove leading/trailing whitespace.
        KEY=$(echo "$KEY" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        VALUE=$(echo "$VALUE" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

        OMG_CONFIG_VALUES["$KEY"]="$VALUE"

    done < "$OMG_CONFIG"
}