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

yabai -m window --space $spaceToSwitch

