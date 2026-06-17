#!/usr/bin/env zsh

setopt errexit nounset pipefail extendedglob

readonly TEST_DIR=${0:A:h}
readonly HELPER=${TEST_DIR:h}/.iterm-project-identity.zsh
readonly USER_HOME=$HOME
readonly SOURCE_LINE='[[ -r "$HOME/dotfiles/.iterm-project-identity.zsh" ]] && source "$HOME/dotfiles/.iterm-project-identity.zsh"'

typeset -i failures=0

fail() {
  print -u2 -- "FAIL: $1"
  failures+=1
}

assert_equal() {
  local expected=$1
  local actual=$2
  local message=$3

  [[ $actual == $expected ]] || fail "$message (expected '$expected', got '$actual')"
}

assert_contains() {
  local haystack=$1
  local needle=$2
  local message=$3

  [[ $haystack == *$needle* ]] || fail "$message (missing '$needle')"
}

if [[ ! -f $HELPER ]]; then
  fail "helper exists at $HELPER"
  exit $failures
fi

source "$HELPER"

tmpdir=$(mktemp -d)
trap 'find "$tmpdir" -depth -delete' EXIT

mkdir -p "$tmpdir/alpha-repo/nested/path" "$tmpdir/plain-dir"
git -C "$tmpdir/alpha-repo" init -q

assert_equal \
  "alpha-repo" \
  "$(iterm_project_identity_name "$tmpdir/alpha-repo/nested/path")" \
  "uses the Git root directory as project name"

assert_equal \
  "plain-dir" \
  "$(iterm_project_identity_name "$tmpdir/plain-dir")" \
  "falls back to the current directory outside Git"

assert_equal \
  "" \
  "$(HOME="$tmpdir/plain-dir" iterm_project_identity_name "$tmpdir/plain-dir")" \
  "keeps the home directory neutral"

first_color=$(iterm_project_identity_color "alpha-repo")
second_color=$(iterm_project_identity_color "alpha-repo")
assert_equal "$first_color" "$second_color" "assigns a stable project color"
[[ $first_color == [0-9a-f]## ]] || fail "returns a lowercase hexadecimal color"
assert_equal "6" "${#first_color}" "returns a six-digit color"

TERM_PROGRAM=iTerm.app
HOME="$tmpdir/home"
mkdir -p "$HOME"

iterm2_set_user_var() {
  print -rn -- "VAR:$1:$2;"
}

it2setcolor() {
  print -rn -- "COLOR:$1:$2;"
}

cd "$tmpdir/alpha-repo/nested/path"
unset ITERM_PROJECT_IDENTITY_LAST_KEY
iterm_project_identity_update > "$tmpdir/update-output"
output=$(<"$tmpdir/update-output")

assert_contains "$output" "VAR:project:alpha-repo;" "sets the project user variable"
assert_contains \
  "$output" "VAR:projectSuffix: · alpha-repo;" \
  "sets the project suffix used by the custom window title"
assert_contains "$output" "COLOR:tab:$first_color;" "sets the project tab color"
[[ $output != *SetBadgeFormat* ]] || fail "does not render an always-visible badge"
assert_equal "%n@%m" "${ZSH_THEME_TERM_TITLE_IDLE-}" "keeps the idle title distinct from the project"
assert_equal "%n@%m" "${ZSH_THEME_TERM_TAB_TITLE_IDLE-}" "keeps the idle tab name distinct from the project"

iterm_project_identity_update > "$tmpdir/second-output"
second_output=$(<"$tmpdir/second-output")
assert_equal "" "$second_output" "does not redraw an unchanged project identity"

mkdir -p "$tmpdir/alpha-repo/another-path"
cd "$tmpdir/alpha-repo/another-path"
iterm_project_identity_update > "$tmpdir/same-project-output"
same_project_output=$(<"$tmpdir/same-project-output")
assert_equal "" "$same_project_output" "does not redraw within the same Git project"

cd "$HOME"
iterm_project_identity_update > "$tmpdir/neutral-output"
neutral_output=$(<"$tmpdir/neutral-output")
assert_contains "$neutral_output" "VAR:project:;" "clears the project user variable at home"
assert_contains "$neutral_output" "VAR:projectSuffix:;" "clears the project title suffix at home"
assert_contains "$neutral_output" "COLOR:tab:default;" "restores the default tab color at home"
[[ $neutral_output != *SetBadgeFormat* ]] || fail "does not render a badge at home"

assert_contains \
  "$(<"$USER_HOME/.zshrc")" \
  "$SOURCE_LINE" \
  "loads the helper from the active zsh configuration"

assert_contains \
  "$(<"${TEST_DIR:h}/.zshrc")" \
  "$SOURCE_LINE" \
  "loads the helper from the managed zsh configuration"

if (( failures > 0 )); then
  exit $failures
fi

print -- "PASS: iTerm project identity"
