#!/usr/bin/env bash
currentSpace="$(yabai -m query --spaces --space | jq '.index')"

if [ $currentSpace -gt 6 ] && [ $currentSpace -le 10 ]
then
  leftSpace="$(($currentSpace - 1))"
  rightSpace="$(($currentSpace - 6))"
  yabai -m space --focus $rightSpace && yabai -m space --focus $leftSpace
fi

if [ $currentSpace -eq 6 ]
then
  leftSpace="$((10))"
  rightSpace="$((5))"
  yabai -m space --focus $rightSpace && yabai -m space --focus $leftSpace
fi

if [ $currentSpace -gt 1 ] && [ $currentSpace -le 5 ]
then
  leftSpace="$(($currentSpace + 4))"
  rightSpace="$(($currentSpace - 1))"
  yabai -m space --focus $leftSpace && yabai -m space --focus $rightSpace
fi

if [ $currentSpace -eq 1 ]
then
  leftSpace="$((10))"
  rightSpace="$((5))"
  yabai -m space --focus $leftSpace && yabai -m space --focus $rightSpace
fi
