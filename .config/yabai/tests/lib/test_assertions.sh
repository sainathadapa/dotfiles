#!/usr/bin/env bash

set -u

fail() {
  printf 'not ok - %s\n' "$1" >&2
  exit 1
}

assert_eq() {
  local expected="$1"
  local actual="$2"
  local message="$3"

  if [[ "$expected" != "$actual" ]]; then
    fail "$message: expected [$expected], got [$actual]"
  fi
}

assert_success() {
  local status="$1"
  local message="$2"

  if [[ "$status" -ne 0 ]]; then
    fail "$message: expected exit 0, got $status"
  fi
}

assert_failure() {
  local status="$1"
  local message="$2"

  if [[ "$status" -eq 0 ]]; then
    fail "$message: expected nonzero exit"
  fi
}

assert_file_contains() {
  local file="$1"
  local needle="$2"
  local message="$3"

  if ! grep -Fq -- "$needle" "$file"; then
    printf '--- %s ---\n' "$file" >&2
    cat "$file" >&2
    fail "$message: missing [$needle]"
  fi
}

assert_file_not_contains() {
  local file="$1"
  local needle="$2"
  local message="$3"

  if grep -Fq -- "$needle" "$file"; then
    printf '--- %s ---\n' "$file" >&2
    cat "$file" >&2
    fail "$message: unexpected [$needle]"
  fi
}
