#!/usr/bin/env bash
set -e
set -o pipefail

currentSpace="$(yabai -m query --spaces --space | jq '.index')"
# echo $currentSpace

lastSpaceFirstMonitor="$((8))"
lastSpaceSecondMonitor="$((16))"

if [ $currentSpace -le $lastSpaceFirstMonitor ]; then
    currentFirstMonitorSpace=$currentSpace
    currentSecondMonitorSpace="$(($currentSpace + $lastSpaceSecondMonitor - $lastSpaceFirstMonitor))"
else
    currentFirstMonitorSpace="$(($currentSpace - $lastSpaceSecondMonitor + $lastSpaceFirstMonitor))"
    currentSecondMonitorSpace=$currentSpace
fi
# echo $currentFirstMonitorSpace
# echo $currentSecondMonitorSpace

if [ $currentFirstMonitorSpace -le 1 ]; then
    newFirstMonitorSpace="$((lastSpaceFirstMonitor))"
else
    newFirstMonitorSpace="$(($currentFirstMonitorSpace - 1))"
fi
firstSpaceSecondMonitor="$(($lastSpaceFirstMonitor + 1))"
if [ $currentSecondMonitorSpace -le $firstSpaceSecondMonitor ]; then
    newSecondMonitorSpace="$(($lastSpaceSecondMonitor))"
else
    newSecondMonitorSpace="$(($currentSecondMonitorSpace - 1))"
fi
# echo $newFirstMonitorSpace
# echo $newSecondMonitorSpace

if [ $currentSpace -le $lastSpaceFirstMonitor ]; then
    yabai -m space --focus $newSecondMonitorSpace && yabai -m space --focus $newFirstMonitorSpace
else
    yabai -m space --focus $newFirstMonitorSpace && yabai -m space --focus $newSecondMonitorSpace
fi
