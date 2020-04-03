#!/usr/bin/env bash
var="$(yabai -m query --displays --display | jq '.index' | awk '{ print ($1 == 2 ? 1 : 2) }')"
yabai -m display --focus $var
