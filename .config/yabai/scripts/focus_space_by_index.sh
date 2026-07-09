#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
. "$SCRIPT_DIR/lib/yabai_helpers.sh"

given_space_index="${1:?space index required}"
target_space="$(target_space_with_capslock_offset "$given_space_index")"

focus_space_if_exists "$target_space"
