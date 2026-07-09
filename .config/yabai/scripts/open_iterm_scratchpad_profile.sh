#!/usr/bin/env bash
set -euo pipefail

OSASCRIPT_BIN="${OSASCRIPT_BIN:-osascript}"
OPEN_BIN="${OPEN_BIN:-open}"
PGREP_BIN="${PGREP_BIN:-pgrep}"
SLEEP_BIN="${SLEEP_BIN:-sleep}"

if ! "$PGREP_BIN" -f "iTerm" >/dev/null 2>&1; then
  "$OPEN_BIN" -a "/Applications/iTerm.app"
  for _ in 1 2 3 4 5; do
    if "$PGREP_BIN" -f "iTerm" >/dev/null 2>&1; then
      break
    fi
    "$SLEEP_BIN" 1
  done
fi

if ! "$OSASCRIPT_BIN" <<'APPLESCRIPT'
tell application id "com.googlecode.iterm2"
  create window with profile "Scratchpad"
end tell
APPLESCRIPT
then
  printf 'error: failed to create iTerm Scratchpad profile window\n' >&2
  exit 1
fi
