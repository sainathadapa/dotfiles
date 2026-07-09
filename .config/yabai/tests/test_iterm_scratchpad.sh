#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/../../.." && pwd)"
TEST_DIR="$REPO_ROOT/.config/yabai/tests"
SCRIPT_DIR="$REPO_ROOT/.config/yabai/scripts"

. "$TEST_DIR/lib/test_assertions.sh"

export PATH="$TEST_DIR/stubs:$PATH"
export YABAI_COMMAND_LOG
export OSASCRIPT_COMMAND_LOG
export OPEN_COMMAND_LOG
YABAI_COMMAND_LOG="$(mktemp "${TMPDIR:-/tmp}/yabai-scratchpad-commands.XXXXXX")"
OSASCRIPT_COMMAND_LOG="$(mktemp "${TMPDIR:-/tmp}/osascript-commands.XXXXXX")"
OPEN_COMMAND_LOG="$(mktemp "${TMPDIR:-/tmp}/open-commands.XXXXXX")"
STDERR_LOG="$(mktemp "${TMPDIR:-/tmp}/scratchpad-stderr.XXXXXX")"

cleanup() {
  rm -f "$YABAI_COMMAND_LOG" "$OSASCRIPT_COMMAND_LOG" "$OPEN_COMMAND_LOG" "$STDERR_LOG"
}
trap cleanup EXIT

reset_state() {
  : > "$YABAI_COMMAND_LOG"
  : > "$OSASCRIPT_COMMAND_LOG"
  : > "$OPEN_COMMAND_LOG"
  : > "$STDERR_LOG"
  export PGREP_STUB_FOUND=1
  export OSASCRIPT_STUB_STATUS=0
  export OPEN_STUB_STATUS=0
  export YABAI_STUB_CURRENT_SPACE='{"index":3}'
  export YABAI_STUB_WINDOWS='[{"id":88,"title":"Scratchpad","space":3,"is-minimized":false,"is-floating":true}]'
  export YABAI_STUB_WINDOW='{"id":88,"title":"Scratchpad","space":3,"is-minimized":false,"is-floating":true}'
}

assert_log_contains() {
  local file="$1"
  local needle="$2"
  local message="$3"

  if grep -Fq -- "$needle" "$file"; then
    assert_success 0 "$message"
  else
    assert_success 1 "$message"
  fi
}

test_open_iterm_uses_bundle_id() {
  reset_state
  "$SCRIPT_DIR/open_iterm2.sh"
  assert_log_contains "$OSASCRIPT_COMMAND_LOG" 'tell application id "com.googlecode.iterm2"' "open_iterm2 targets bundle id"
  assert_log_contains "$OSASCRIPT_COMMAND_LOG" 'create window with default profile' "open_iterm2 creates default window"
}

test_open_iterm_falls_back_to_open() {
  reset_state
  export OSASCRIPT_STUB_STATUS=1
  "$SCRIPT_DIR/open_iterm2.sh" 2> "$STDERR_LOG"
  assert_log_contains "$OPEN_COMMAND_LOG" '-a /Applications/iTerm.app' "open_iterm2 falls back to open"
  assert_log_contains "$STDERR_LOG" "failed to create iTerm window" "open_iterm2 logs fallback"
}

test_scratchpad_profile_uses_bundle_id() {
  reset_state
  "$SCRIPT_DIR/open_iterm_scratchpad_profile.sh"
  assert_log_contains "$OSASCRIPT_COMMAND_LOG" 'tell application id "com.googlecode.iterm2"' "scratchpad profile targets bundle id"
  assert_log_contains "$OSASCRIPT_COMMAND_LOG" 'create window with profile "Scratchpad"' "scratchpad profile creates Scratchpad window"
}

test_scratchpad_present_current_space_minimizes() {
  reset_state
  "$SCRIPT_DIR/scratchpad.sh"
  assert_log_contains "$YABAI_COMMAND_LOG" "-m window 88 --minimize" "scratchpad minimizes visible current-space window"
}

test_scratchpad_elsewhere_moves_focuses_and_floats() {
  reset_state
  export YABAI_STUB_WINDOWS='[{"id":88,"title":"Scratchpad","space":2,"is-minimized":false,"is-floating":false}]'
  export YABAI_STUB_WINDOW='{"id":88,"title":"Scratchpad","space":2,"is-minimized":false,"is-floating":false}'
  "$SCRIPT_DIR/scratchpad.sh"
  assert_log_contains "$YABAI_COMMAND_LOG" "-m window 88 --space 3" "scratchpad moves to current space"
  assert_log_contains "$YABAI_COMMAND_LOG" "-m window --focus 88" "scratchpad focuses moved window"
  assert_log_contains "$YABAI_COMMAND_LOG" "-m window 88 --toggle float" "scratchpad floats non-floating window"
}

test_scratchpad_missing_attempts_creation() {
  reset_state
  export YABAI_STUB_WINDOWS='[]'
  "$SCRIPT_DIR/scratchpad.sh" 2> "$STDERR_LOG"
  assert_log_contains "$OSASCRIPT_COMMAND_LOG" 'create window with profile "Scratchpad"' "missing scratchpad triggers profile creation"
  assert_log_contains "$STDERR_LOG" "Scratchpad window not found" "missing scratchpad logs after failed creation"
}

test_open_iterm_uses_bundle_id
test_open_iterm_falls_back_to_open
test_scratchpad_profile_uses_bundle_id
test_scratchpad_present_current_space_minimizes
test_scratchpad_elsewhere_moves_focuses_and_floats
test_scratchpad_missing_attempts_creation

printf 'ok - iTerm/scratchpad tests passed\n'
