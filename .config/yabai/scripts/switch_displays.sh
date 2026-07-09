#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
. "$SCRIPT_DIR/lib/yabai_helpers.sh"

if ! require_two_displays "switch_displays"; then
  exit 0
fi

current_display="$(current_display_index)"
if [[ "$current_display" -eq 2 ]]; then
  yabai -m display --focus 1
else
  yabai -m display --focus 2
fi
