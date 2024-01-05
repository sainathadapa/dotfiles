#!/usr/bin/env sh

if [ "$SELECTED" = "true" ]; then
  sketchybar -m --set $NAME --bar background.color=0xff81a1c1
else
  sketchybar -m --set $NAME --bar background.color=0xff57627A
fi
