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