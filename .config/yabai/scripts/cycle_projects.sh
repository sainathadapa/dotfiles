#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck source=.config/yabai/scripts/lib/yabai_helpers.sh
. "$SCRIPT_DIR/lib/yabai_helpers.sh"

last_space_index() {
  yabai -m query --spaces | jq 'map(.index) | max'
}

focus_pair_preserving_origin() {
  local current="$1"
  local first_target="$2"
  local second_target="$3"

  if ! space_exists "$first_target"; then
    log_warn "space $first_target does not exist"
    return 0
  fi

  if ! space_exists "$second_target"; then
    log_warn "space $second_target does not exist"
    return 0
  fi

  if [[ "$current" -le 8 ]]; then
    yabai -m space --focus "$second_target"
    yabai -m space --focus "$first_target"
  else
    yabai -m space --focus "$first_target"
    yabai -m space --focus "$second_target"
  fi
}

num_displays="$(display_count)"
current_space="$(current_space_index)"

case "$num_displays" in
  1)
    last_space="$(last_space_index)"
    if [[ "$current_space" -eq "$last_space" ]]; then
      focus_space_if_exists 1
    else
      focus_space_if_exists "$((current_space + 1))"
    fi
    ;;
  2)
    if [[ "$current_space" -le 8 ]]; then
      current_first="$current_space"
      current_second="$((current_space + 8))"
    else
      current_first="$((current_space - 8))"
      current_second="$current_space"
    fi

    if [[ "$current_first" -ge 8 ]]; then
      new_first=1
    else
      new_first="$((current_first + 1))"
    fi

    if [[ "$current_second" -ge 16 ]]; then
      new_second=9
    else
      new_second="$((current_second + 1))"
    fi

    focus_pair_preserving_origin "$current_space" "$new_first" "$new_second"
    ;;
  *)
    log_warn "cycle_projects: unsupported display count $num_displays"
    ;;
esac
