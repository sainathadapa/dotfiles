#!/usr/bin/env bash
set -e
set -o pipefail

scratchpad_id=$(yabai -m query --windows | jq '.[] | select(.title=="Scratchpad").id')
is_minimized=$(yabai -m query --windows --window "$scratchpad_id" | jq '.minimized')
scratchpad_space=$(yabai -m query --windows --window "$scratchpad_id" | jq '.space')
current_space=$(yabai -m query --spaces --space | jq '.index')

# if the scratchpad is not minimized and it is on the current space, then minimize it
if [ $is_minimized -eq 0 ]; then
  if [ $current_space -eq $scratchpad_space ]; then
    yabai -m window "$scratchpad_id" --minimize
    exit 1
  fi
fi

# move the scratchpad to the current space
yabai -m window "$scratchpad_id" --space "$current_space"
# focus the scratchpad
yabai -m window --focus "$scratchpad_id"
# make it floating if it is not already
is_floating=$(yabai -m query --windows --window "$scratchpad_id" | jq '.floating')
echo $is_floating
if [[ "$is_floating" -eq 0 ]]; then
  yabai -m window --toggle float
fi
# yabai -m window --resize abs:1920:1080
# yabai -m window --move abs:480:540
