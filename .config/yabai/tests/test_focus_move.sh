#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/../../.." && pwd)"
TEST_DIR="$REPO_ROOT/.config/yabai/tests"
SCRIPT_DIR="$REPO_ROOT/.config/yabai/scripts"

. "$TEST_DIR/lib/test_assertions.sh"

export PATH="$TEST_DIR/stubs:$PATH"
export YABAI_COMMAND_LOG
YABAI_COMMAND_LOG="$(mktemp "${TMPDIR:-/tmp}/yabai-focus-move-commands.XXXXXX")"
STDERR_LOG="$(mktemp "${TMPDIR:-/tmp}/yabai-focus-move-stderr.XXXXXX")"

cleanup() {
  rm -f "$YABAI_COMMAND_LOG" "$STDERR_LOG"
}
trap cleanup EXIT

reset_state() {
  : > "$YABAI_COMMAND_LOG"
  : > "$STDERR_LOG"
  export CHECK_MOD_KEYS_RESULT=0
  export YABAI_STUB_SPACES='[{"index":1},{"index":2},{"index":12}]'
  export YABAI_STUB_CURRENT_SPACE='{"index":1}'
  export YABAI_STUB_WINDOW='{"id":42}'
  unset YABAI_STUB_WINDOW_FAIL
}

test_focus_plain_target() {
  reset_state
  "$SCRIPT_DIR/focus_space_by_index.sh" 2
  assert_file_contains "$YABAI_COMMAND_LOG" "-m space --focus 2" "focus script focuses requested space"
}

test_focus_capslock_target() {
  reset_state
  export CHECK_MOD_KEYS_RESULT=1
  "$SCRIPT_DIR/focus_space_by_index.sh" 2
  assert_file_contains "$YABAI_COMMAND_LOG" "-m space --focus 12" "focus script applies capslock offset"
}

test_focus_missing_target() {
  reset_state
  "$SCRIPT_DIR/focus_space_by_index.sh" 9 2> "$STDERR_LOG"
  assert_file_not_contains "$YABAI_COMMAND_LOG" "--focus 9" "focus script skips missing space"
  assert_file_contains "$STDERR_LOG" "space 9 does not exist" "focus script logs missing space"
}

test_focus_current_target_uses_recent() {
  reset_state
  "$SCRIPT_DIR/focus_space_by_index.sh" 1
  assert_file_contains "$YABAI_COMMAND_LOG" "-m space --focus recent" "focus script toggles recent"
}

test_move_plain_target() {
  reset_state
  "$SCRIPT_DIR/move_window_to_space_by_index.sh" 2
  assert_file_contains "$YABAI_COMMAND_LOG" "-m window --space 2" "move script moves to requested space"
}

test_move_capslock_target() {
  reset_state
  export CHECK_MOD_KEYS_RESULT=1
  "$SCRIPT_DIR/move_window_to_space_by_index.sh" 2
  assert_file_contains "$YABAI_COMMAND_LOG" "-m window --space 12" "move script applies capslock offset"
}

test_move_missing_target() {
  reset_state
  "$SCRIPT_DIR/move_window_to_space_by_index.sh" 9 2> "$STDERR_LOG"
  assert_file_not_contains "$YABAI_COMMAND_LOG" "--space 9" "move script skips missing space"
  assert_file_contains "$STDERR_LOG" "space 9 does not exist" "move script logs missing space"
}

test_move_no_focused_window() {
  reset_state
  export YABAI_STUB_WINDOW_FAIL=1
  "$SCRIPT_DIR/move_window_to_space_by_index.sh" 2 2> "$STDERR_LOG"
  assert_file_not_contains "$YABAI_COMMAND_LOG" "--space 2" "move script skips when no focused window"
  assert_file_contains "$STDERR_LOG" "no focused window to move" "move script logs missing focused window"
}

test_focus_plain_target
test_focus_capslock_target
test_focus_missing_target
test_focus_current_target_uses_recent
test_move_plain_target
test_move_capslock_target
test_move_missing_target
test_move_no_focused_window

printf 'ok - focus/move tests passed\n'
