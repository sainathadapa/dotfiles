#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck source=.config/yabai/scripts/lib/yabai_helpers.sh
. "$SCRIPT_DIR/lib/yabai_helpers.sh"

find_scratchpad_id() {
  yabai -m query --windows | jq -r 'map(select(.title == "Scratchpad")) | .[0].id // empty'
}

scratchpad_id="$(find_scratchpad_id)"

if [[ -z "$scratchpad_id" ]]; then
  "$SCRIPT_DIR/open_iterm_scratchpad_profile.sh" || true
  scratchpad_id="$(find_scratchpad_id)"
fi

if [[ -z "$scratchpad_id" ]]; then
  log_warn "Scratchpad window not found"
  exit 0
fi

window_json="$(yabai -m query --windows --window "$scratchpad_id")"
is_minimized="$(printf '%s\n' "$window_json" | jq -r '."is-minimized"')"
scratchpad_space="$(printf '%s\n' "$window_json" | jq -r '.space')"
current_space="$(current_space_index)"

if [[ "$is_minimized" == "false" && "$scratchpad_space" -eq "$current_space" ]]; then
  yabai -m window "$scratchpad_id" --minimize
  exit 0
fi

yabai -m window "$scratchpad_id" --space "$current_space"
yabai -m window --focus "$scratchpad_id"

window_json="$(yabai -m query --windows --window "$scratchpad_id")"
is_floating="$(printf '%s\n' "$window_json" | jq -r '."is-floating"')"

if [[ "$is_floating" == "false" ]]; then
  yabai -m window "$scratchpad_id" --toggle float
fi
