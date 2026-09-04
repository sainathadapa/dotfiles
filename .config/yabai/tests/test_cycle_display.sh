#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/../../.." && pwd)"
TEST_DIR="$REPO_ROOT/.config/yabai/tests"
SCRIPT_DIR="$REPO_ROOT/.config/yabai/scripts"

# shellcheck source=.config/yabai/tests/lib/test_assertions.sh
. "$TEST_DIR/lib/test_assertions.sh"

export PATH="$TEST_DIR/stubs:$PATH"
export YABAI_COMMAND_LOG
YABAI_COMMAND_LOG="$(mktemp "${TMPDIR:-/tmp}/yabai-cycle-display-commands.XXXXXX")"
STDERR_LOG="$(mktemp "${TMPDIR:-/tmp}/yabai-cycle-display-stderr.XXXXXX")"

cleanup() {
  rm -f "$YABAI_COMMAND_LOG" "$STDERR_LOG"
}
trap cleanup EXIT

spaces_1_to_16() {
  printf '['
  local first=1
  local i
  for i in $(seq 1 16); do
    if [[ "$first" -eq 0 ]]; then
      printf ','
    fi
    first=0
    printf '{"index":%s}' "$i"
  done
  printf ']\n'
}

reset_state() {
  : > "$YABAI_COMMAND_LOG"
  : > "$STDERR_LOG"
  export YABAI_STUB_SPACES
  YABAI_STUB_SPACES="$(spaces_1_to_16)"
  export YABAI_STUB_DISPLAYS='[{"index":1}]'
  export YABAI_STUB_CURRENT_DISPLAY='{"index":1}'
  export YABAI_STUB_CURRENT_SPACE='{"index":1}'
}

test_forward_one_display_next() {
  reset_state
  export YABAI_STUB_CURRENT_SPACE='{"index":3}'
  "$SCRIPT_DIR/cycle_projects.sh"
  assert_file_contains "$YABAI_COMMAND_LOG" "-m space --focus 4" "forward one-display cycle focuses next space"
}

test_forward_one_display_wrap() {
  reset_state
  export YABAI_STUB_CURRENT_SPACE='{"index":16}'
  "$SCRIPT_DIR/cycle_projects.sh"
  assert_file_contains "$YABAI_COMMAND_LOG" "-m space --focus 1" "forward one-display cycle wraps to first space"
}

test_reverse_one_display_previous() {
  reset_state
  export YABAI_STUB_CURRENT_SPACE='{"index":3}'
  "$SCRIPT_DIR/cycle_projects_reverse.sh"
  assert_file_contains "$YABAI_COMMAND_LOG" "-m space --focus 2" "reverse one-display cycle focuses previous space"
}

test_reverse_one_display_wrap() {
  reset_state
  export YABAI_STUB_CURRENT_SPACE='{"index":1}'
  "$SCRIPT_DIR/cycle_projects_reverse.sh"
  assert_file_contains "$YABAI_COMMAND_LOG" "-m space --focus 16" "reverse one-display cycle wraps to last space"
}

test_forward_two_display_pair() {
  reset_state
  export YABAI_STUB_DISPLAYS='[{"index":1},{"index":2}]'
  export YABAI_STUB_CURRENT_SPACE='{"index":2}'
  "$SCRIPT_DIR/cycle_projects.sh"
  assert_file_contains "$YABAI_COMMAND_LOG" "-m space --focus 11" "forward two-display cycle focuses paired second-display target"
  assert_file_contains "$YABAI_COMMAND_LOG" "-m space --focus 3" "forward two-display cycle focuses paired first-display target"
}

test_forward_two_display_missing_pair_noops() {
  reset_state
  export YABAI_STUB_DISPLAYS='[{"index":1},{"index":2}]'
  export YABAI_STUB_CURRENT_SPACE='{"index":2}'
  export YABAI_STUB_SPACES='[{"index":1},{"index":2},{"index":3},{"index":9},{"index":10}]'

  set +e
  "$SCRIPT_DIR/cycle_projects.sh" 2> "$STDERR_LOG"
  local status="$?"
  set -e

  assert_success "$status" "forward two-display missing paired target exits cleanly"
  assert_file_contains "$STDERR_LOG" "space 11 does not exist" "forward two-display missing pair logs warning"
  assert_file_not_contains "$YABAI_COMMAND_LOG" "--focus" "forward two-display missing pair does not focus spaces"
}

test_reverse_two_display_pair() {
  reset_state
  export YABAI_STUB_DISPLAYS='[{"index":1},{"index":2}]'
  export YABAI_STUB_CURRENT_SPACE='{"index":10}'
  "$SCRIPT_DIR/cycle_projects_reverse.sh"
  assert_file_contains "$YABAI_COMMAND_LOG" "-m space --focus 1" "reverse two-display cycle focuses paired first-display target"
  assert_file_contains "$YABAI_COMMAND_LOG" "-m space --focus 9" "reverse two-display cycle focuses paired second-display target"
}

test_three_display_cycle_logs_unsupported() {
  reset_state
  export YABAI_STUB_DISPLAYS='[{"index":1},{"index":2},{"index":3}]'
  "$SCRIPT_DIR/cycle_projects.sh" 2> "$STDERR_LOG"
  assert_file_contains "$STDERR_LOG" "unsupported display count" "three-display cycle logs unsupported"
}

test_switch_one_display_noop() {
  reset_state
  "$SCRIPT_DIR/switch_displays.sh" 2> "$STDERR_LOG"
  assert_file_not_contains "$YABAI_COMMAND_LOG" "-m display --focus" "one-display switch does not focus display"
  assert_file_contains "$STDERR_LOG" "switch_displays: expected 2 displays, found 1" "one-display switch logs count"
}

test_switch_two_displays() {
  reset_state
  export YABAI_STUB_DISPLAYS='[{"index":1},{"index":2}]'
  export YABAI_STUB_CURRENT_DISPLAY='{"index":1}'
  "$SCRIPT_DIR/switch_displays.sh"
  assert_file_contains "$YABAI_COMMAND_LOG" "-m display --focus 2" "two-display switch focuses other display"
}

test_forward_one_display_next
test_forward_one_display_wrap
test_reverse_one_display_previous
test_reverse_one_display_wrap
test_forward_two_display_pair
test_forward_two_display_missing_pair_noops
test_reverse_two_display_pair
test_three_display_cycle_logs_unsupported
test_switch_one_display_noop
test_switch_two_displays

printf 'ok - cycle/display tests passed\n'
