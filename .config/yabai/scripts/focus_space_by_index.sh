#!/usr/bin/env bash
set -e
set -o pipefail

givenSpaceIndex="$1"

if [ `~/.config/yabai/scripts/CheckModKeys capslock` -eq 1 ]; then
  # echo "capslock on"
  spaceToSwitch="$(($givenSpaceIndex + 10))"
else
  # echo "capslock off"
  spaceToSwitch=$givenSpaceIndex
fi

if [ `yabai -m query --spaces --space | jq '.index'` -eq $spaceToSwitch ]; then
  yabai -m space --focus recent;
else
  yabai -m space --focus $spaceToSwitch;
fi

