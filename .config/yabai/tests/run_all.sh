#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/../../.." && pwd)"
PYTHON_CACHE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/yabai-python-cache.XXXXXX")"

cleanup() {
  rm -rf "$PYTHON_CACHE_DIR"
}
trap cleanup EXIT

cd "$REPO_ROOT"

check_shell_syntax() {
  for file in "$@"; do
    bash -n "$file"
  done
}

check_shell_syntax .config/yabai/scripts/*.sh
check_shell_syntax .config/yabai/scripts/lib/*.sh
check_shell_syntax .config/yabai/tests/*.sh
check_shell_syntax .config/yabai/tests/lib/*.sh
check_shell_syntax .config/yabai/tests/stubs/*

bash .config/yabai/tests/test_helpers.sh
bash .config/yabai/tests/test_focus_move.sh
bash .config/yabai/tests/test_cycle_display.sh
bash .config/yabai/tests/test_iterm_scratchpad.sh

PYTHONPYCACHEPREFIX="$PYTHON_CACHE_DIR" \
  python3 -m py_compile .config/yabai/scripts/swap_spaces.py .config/yabai/tests/test_swap_spaces.py
PYTHONPYCACHEPREFIX="$PYTHON_CACHE_DIR" \
  python3 -m unittest discover -s .config/yabai/tests -p 'test_swap_spaces.py'

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck -x .config/yabai/scripts/*.sh \
    .config/yabai/scripts/lib/*.sh \
    .config/yabai/tests/*.sh \
    .config/yabai/tests/lib/*.sh \
    .config/yabai/tests/stubs/*
else
  printf 'info: shellcheck not installed; skipped shellcheck\n' >&2
fi

printf 'ok - all yabai script tests passed\n'
