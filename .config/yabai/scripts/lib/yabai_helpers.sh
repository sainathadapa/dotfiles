#!/usr/bin/env bash

set -u

YABAI_HELPERS_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
YABAI_SCRIPTS_DIR="${YABAI_SCRIPTS_DIR:-$(CDPATH= cd -- "$YABAI_HELPERS_DIR/.." && pwd)}"
CHECK_MOD_KEYS_BIN="${CHECK_MOD_KEYS_BIN:-$(command -v CheckModKeys || printf '%s/CheckModKeys' "$YABAI_SCRIPTS_DIR")}"

log_info() {
  printf 'info: %s\n' "$*" >&2
}

log_warn() {
  printf 'warn: %s\n' "$*" >&2
}

log_error() {
  printf 'error: %s\n' "$*" >&2
}

display_count() {
  yabai -m query --displays | jq 'length'
}

current_display_index() {
  yabai -m query --displays --display | jq -r '.index'
}

current_space_index() {
  yabai -m query --spaces --space | jq -r '.index'
}

focused_window_id() {
  local window_json

  if ! window_json="$(yabai -m query --windows --window 2>/dev/null)"; then
    return 0
  fi

  printf '%s\n' "$window_json" | jq -r '.id // empty'
}

space_exists() {
  local target="$1"

  yabai -m query --spaces | jq -e --argjson target "$target" \
    'any(.[]; .index == $target)' >/dev/null
}

capslock_is_on() {
  [[ "$("$CHECK_MOD_KEYS_BIN" capslock)" -eq 1 ]]
}

target_space_with_capslock_offset() {
  local base_index="$1"

  if capslock_is_on; then
    printf '%s\n' "$((base_index + 10))"
  else
    printf '%s\n' "$base_index"
  fi
}

focus_space_if_exists() {
  local target="$1"
  local current

  if ! space_exists "$target"; then
    log_warn "space $target does not exist"
    return 0
  fi

  current="$(current_space_index)"
  if [[ "$current" -eq "$target" ]]; then
    yabai -m space --focus recent
  else
    yabai -m space --focus "$target"
  fi
}

move_window_to_space_if_exists() {
  local target="$1"
  local window_id

  if ! space_exists "$target"; then
    log_warn "space $target does not exist"
    return 0
  fi

  window_id="$(focused_window_id)"
  if [[ -z "$window_id" ]]; then
    log_warn "no focused window to move"
    return 0
  fi

  yabai -m window --space "$target"
}

require_two_displays() {
  local command_name="$1"
  local count

  count="$(display_count)"
  if [[ "$count" -eq 1 ]]; then
    log_warn "$command_name: expected 2 displays, found $count"
    return 1
  fi
  if [[ "$count" -ne 2 ]]; then
    log_warn "$command_name: unsupported display count $count"
    return 1
  fi
}
