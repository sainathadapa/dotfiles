#!/usr/bin/env bash
set -e
set -o pipefail

if [ `yabai -m query --spaces --space | jq '.index'` -eq $1 ]; then yabai -m space --focus recent; else yabai -m space --focus $1; fi

