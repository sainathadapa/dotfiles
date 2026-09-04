#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/../../.." && pwd)"
TEST_DIR="$REPO_ROOT/.config/yabai/tests"
SCRIPT_DIR="$REPO_ROOT/.config/yabai/scripts"

# shellcheck source=.config/yabai/tests/lib/test_assertions.sh
. "$TEST_DIR/lib/test_assertions.sh"

export PATH="$TEST_DIR/stubs:$PATH"
export YABAI_COMMAND_LOG
YABAI_COMMAND_LOG="$(mktemp "${TMPDIR:-/tmp}/yabai-helper-commands.XXXXXX")"
STDERR_LOG="$(mktemp "${TMPDIR:-/tmp}/yabai-helper-stderr.XXXXXX")"

cleanup() {
  rm -f "$YABAI_COMMAND_LOG" "$STDERR_LOG"
}
trap cleanup EXIT

# shellcheck source=.config/yabai/scripts/lib/yabai_helpers.sh
. "$SCRIPT_DIR/lib/yabai_helpers.sh"

test_display_count() {
  export YABAI_STUB_DISPLAYS='[{"index":1},{"index":2}]'
  local actual
  actual="$(display_count)"
  assert_eq "2" "$actual" "display_count reads display array length"
}

test_space_exists() {
  export YABAI_STUB_SPACES='[{"index":1},{"index":11}]'
  space_exists 11
  assert_success "$?" "space_exists succeeds for present space"

  set +e
  space_exists 12
  local status="$?"
  set -e
  assert_failure "$status" "space_exists fails for absent space"
}

test_capslock_offset() {
  export CHECK_MOD_KEYS_RESULT=1
  local actual
  actual="$(target_space_with_capslock_offset 3)"
  assert_eq "13" "$actual" "capslock offset adds 10"

  export CHECK_MOD_KEYS_RESULT=0
  actual="$(target_space_with_capslock_offset 3)"
  assert_eq "3" "$actual" "capslock off preserves base index"
}

test_focus_space_if_exists() {
  export YABAI_STUB_SPACES='[{"index":1},{"index":2}]'
  export YABAI_STUB_CURRENT_SPACE='{"index":1}'
  : > "$YABAI_COMMAND_LOG"

  focus_space_if_exists 2
  assert_file_contains "$YABAI_COMMAND_LOG" "-m space --focus 2" "focus_space_if_exists focuses target"

  : > "$YABAI_COMMAND_LOG"
  focus_space_if_exists 1
  assert_file_contains "$YABAI_COMMAND_LOG" "-m space --focus recent" "focus_space_if_exists toggles recent for current target"
}

test_move_window_to_space_if_exists() {
  export YABAI_STUB_SPACES='[{"index":4}]'
  export YABAI_STUB_WINDOW='{"id":77}'
  : > "$YABAI_COMMAND_LOG"

  move_window_to_space_if_exists 4
  assert_file_contains "$YABAI_COMMAND_LOG" "-m window --space 4" "move_window_to_space_if_exists moves focused window"
}

test_missing_target_logs_warning() {
  export YABAI_STUB_SPACES='[{"index":1}]'
  : > "$YABAI_COMMAND_LOG"

  focus_space_if_exists 9 2> "$STDERR_LOG"
  assert_file_not_contains "$YABAI_COMMAND_LOG" "--focus 9" "missing target does not call yabai focus"
  assert_file_contains "$STDERR_LOG" "space 9 does not exist" "missing target logs warning"
}

test_display_requirement() {
  export YABAI_STUB_DISPLAYS='[{"index":1}]'
  : > "$STDERR_LOG"
  set +e
  require_two_displays "swap_spaces" 2> "$STDERR_LOG"
  local status="$?"
  set -e

  assert_failure "$status" "require_two_displays fails for one display"
  assert_file_contains "$STDERR_LOG" "swap_spaces: expected 2 displays, found 1" "display requirement logs count"

  export YABAI_STUB_DISPLAYS='[{"index":1},{"index":2},{"index":3}]'
  : > "$STDERR_LOG"
  set +e
  require_two_displays "switch_displays" 2> "$STDERR_LOG"
  status="$?"
  set -e

  assert_failure "$status" "require_two_displays fails for three displays"
  assert_file_contains "$STDERR_LOG" "switch_displays: unsupported display count 3" "display requirement logs unsupported count"
}

test_stub_window_payloads_include_is_visible() {
  local single_window has_visible windows_array all_have_visible

  export YABAI_STUB_WINDOW='{"id":42,"space":1,"is-minimized":false,"is-visible":true,"is-floating":false}'
  export YABAI_STUB_WINDOWS='[{"id":42,"title":"Main","space":1,"is-minimized":false,"is-visible":true,"is-floating":false}]'

  single_window="$(yabai -m query --windows --window)"
  has_visible="$(printf '%s\n' "$single_window" | jq -r 'has("is-visible")')"
  assert_eq "true" "$has_visible" "single window payload includes is-visible"

  windows_array="$(yabai -m query --windows)"
  all_have_visible="$(printf '%s\n' "$windows_array" | jq -r 'all(.[]; has("is-visible"))')"
  assert_eq "true" "$all_have_visible" "windows array payload includes is-visible"
}

test_display_count
test_space_exists
test_capslock_offset
test_focus_space_if_exists
test_move_window_to_space_if_exists
test_missing_target_logs_warning
test_display_requirement
test_stub_window_payloads_include_is_visible

printf 'ok - helper tests passed\n'
