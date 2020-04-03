#!/usr/bin/env bash
currentSpace="$(yabai -m query --spaces --space | jq '.index')"

if [ $currentSpace -ge 6 ] && [ $currentSpace -lt 10 ]
then
  leftSpace="$(($currentSpace + 1))"
  rightSpace="$(($currentSpace - 4))"
  yabai -m space --focus $rightSpace && yabai -m space --focus $leftSpace
fi

if [ $currentSpace -eq 10 ]
then
  leftSpace="$((6))"
  rightSpace="$((1))"
  yabai -m space --focus $rightSpace && yabai -m space --focus $leftSpace
fi

if [ $currentSpace -ge 1 ] && [ $currentSpace -lt 5 ]
then
  leftSpace="$(($currentSpace + 6))"
  rightSpace="$(($currentSpace + 1))"
  yabai -m space --focus $leftSpace && yabai -m space --focus $rightSpace
fi

if [ $currentSpace -eq 5 ]
then
  leftSpace="$((6))"
  rightSpace="$((1))"
  yabai -m space --focus $leftSpace && yabai -m space --focus $rightSpace
fi
