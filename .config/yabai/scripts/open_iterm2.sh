#!/usr/bin/env bash
set -euo pipefail

OSASCRIPT_BIN="${OSASCRIPT_BIN:-osascript}"
OPEN_BIN="${OPEN_BIN:-open}"
PGREP_BIN="${PGREP_BIN:-pgrep}"

if ! "$PGREP_BIN" -f "iTerm" >/dev/null 2>&1; then
  "$OPEN_BIN" -a "/Applications/iTerm.app"
  exit 0
fi

if ! "$OSASCRIPT_BIN" <<'APPLESCRIPT'
tell application id "com.googlecode.iterm2"
  create window with default profile
end tell
APPLESCRIPT
then
  printf 'warn: failed to create iTerm window through AppleScript; opening iTerm.app\n' >&2
  "$OPEN_BIN" -a "/Applications/iTerm.app"
fi
