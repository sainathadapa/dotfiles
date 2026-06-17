# iTerm Directory Pastel Colors Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Assign each exact current working directory a reproducible balanced-pastel color in iTerm's tab and window-title chrome.

**Architecture:** Extend the existing zsh prompt hook with a canonical home-relative directory key, map that key through `cksum` into a fixed 16-color palette, and emit iTerm's tab and OSC 6 chrome-color controls. Preserve the existing Git-root title suffix, neutral home behavior, and no-badge behavior.

**Tech Stack:** zsh, POSIX `cksum`, iTerm2 shell integration and proprietary escape sequences, shell test harness.

---

### Task 1: Specify Directory-Level Color Behavior

**Files:**
- Modify: `tests/iterm-project-identity.zsh:17-124`
- Test: `tests/iterm-project-identity.zsh`

- [ ] **Step 1: Add assertions for directory keys and chrome output**

Add an inequality helper:

```zsh
assert_not_equal() {
  local unexpected=$1
  local actual=$2
  local message=$3

  [[ $actual != $unexpected ]] || fail "$message (unexpected '$unexpected')"
}
```

Create two monorepo directories under the temporary home and assert canonical,
home-relative keys:

```zsh
mkdir -p \
  "$tmpdir/home/src/monorepo/services/catalog" \
  "$tmpdir/home/src/monorepo/services/search"

assert_equal \
  "~" \
  "$(HOME="$tmpdir/home" iterm_project_identity_directory_key "$tmpdir/home")" \
  "normalizes the home directory"

assert_equal \
  "~/src/monorepo/services/catalog" \
  "$(HOME="$tmpdir/home" iterm_project_identity_directory_key "$tmpdir/home/src/monorepo/services/catalog")" \
  "normalizes a directory beneath home"
```

Replace the old eight-color/project-name assertions with:

```zsh
assert_equal "16" "${#ITERM_PROJECT_IDENTITY_COLORS}" "provides sixteen pastel colors"

catalog_color=$(iterm_project_identity_color "~/src/monorepo/services/catalog")
search_color=$(iterm_project_identity_color "~/src/monorepo/services/search")

assert_equal "afcff0" "$catalog_color" "maps a known directory reproducibly"
assert_equal "c8d6a5" "$search_color" "maps another known directory reproducibly"
assert_not_equal "$catalog_color" "$search_color" "distinguishes the representative monorepo directories"
[[ $catalog_color == [0-9a-f]## ]] || fail "returns a lowercase hexadecimal color"
assert_equal "6" "${#catalog_color}" "returns a six-digit color"

catalog_chrome=$(iterm_project_identity_set_chrome_color "$catalog_color")
assert_equal \
  $'\e]6;1;bg;red;brightness;175\a\e]6;1;bg;green;brightness;207\a\e]6;1;bg;blue;brightness;240\a' \
  "$catalog_chrome" \
  "emits the title chrome RGB controls"
```

Update the prompt-hook assertions so the expected color is calculated from the
exact directory key:

```zsh
directory_key=$(iterm_project_identity_directory_key "$PWD")
directory_color=$(iterm_project_identity_color "$directory_key")

assert_contains "$output" "COLOR:tab:$directory_color;" "sets the directory tab color"
assert_contains \
  "$output" \
  "$(iterm_project_identity_set_chrome_color "$directory_color")" \
  "sets the directory title chrome color"
```

Change the same-repository subdirectory test to require a redraw:

```zsh
mkdir -p "$tmpdir/alpha-repo/another-path"
cd "$tmpdir/alpha-repo/another-path"
iterm_project_identity_update > "$tmpdir/changed-directory-output"
changed_directory_output=$(<"$tmpdir/changed-directory-output")
assert_contains "$changed_directory_output" "COLOR:tab:" "redraws for another directory in the same Git repository"
```

Add the home chrome reset and non-iTerm assertions:

```zsh
assert_contains \
  "$neutral_output" \
  $'\e]6;1;bg;*;default\a' \
  "restores the default title chrome at home"

TERM_PROGRAM=Apple_Terminal
unset ITERM_PROJECT_IDENTITY_LAST_KEY
iterm_project_identity_update > "$tmpdir/non-iterm-output"
assert_equal "" "$(<"$tmpdir/non-iterm-output")" "does nothing outside iTerm"
```

- [ ] **Step 2: Run the tests and verify they fail**

Run:

```bash
zsh tests/iterm-project-identity.zsh
```

Expected: FAIL because `iterm_project_identity_directory_key` and
`iterm_project_identity_set_chrome_color` do not exist, and the palette still
contains eight colors.

### Task 2: Implement Pastel Directory Coloring

**Files:**
- Modify: `.iterm-project-identity.zsh:1-69`
- Test: `tests/iterm-project-identity.zsh`

- [ ] **Step 1: Replace the palette with the selected balanced pastels**

```zsh
typeset -ga ITERM_PROJECT_IDENTITY_COLORS=(
  a8dccb
  afcff0
  c5b7e8
  e7b4c4
  f0b5a8
  ebcb89
  bcd99a
  96d1d0
  b7c5e4
  d0b6dc
  e8c39e
  afcdb4
  9fc5e8
  d5b0c9
  c8d6a5
  a9c6c9
)
```

- [ ] **Step 2: Add canonical directory-key generation**

```zsh
iterm_project_identity_directory_key() {
  emulate -L zsh

  local directory=${1:-$PWD}
  local canonical=${directory:A}
  local home=${HOME:A}

  if [[ $canonical == $home ]]; then
    print -r -- "~"
  elif [[ $canonical == ${home}/* ]]; then
    print -r -- "~/${canonical#${home}/}"
  else
    print -r -- "$canonical"
  fi
}
```

- [ ] **Step 3: Make color selection operate on the directory key**

```zsh
iterm_project_identity_color() {
  emulate -L zsh

  local identity=$1
  local checksum byte_count
  read -r checksum byte_count <<< "$(print -rn -- "$identity" | cksum)"

  local index=$(( checksum % ${#ITERM_PROJECT_IDENTITY_COLORS} + 1 ))
  print -r -- "$ITERM_PROJECT_IDENTITY_COLORS[$index]"
}
```

- [ ] **Step 4: Add title-chrome RGB and reset controls**

```zsh
iterm_project_identity_set_chrome_color() {
  emulate -L zsh

  local color=$1
  if [[ $color == default ]]; then
    print -rn -- $'\e]6;1;bg;*;default\a'
    return 0
  fi

  local red=$(( 16#${color[1,2]} ))
  local green=$(( 16#${color[3,4]} ))
  local blue=$(( 16#${color[5,6]} ))

  print -rn -- \
    $'\e]6;1;bg;red;brightness;'"$red"$'\a' \
    $'\e]6;1;bg;green;brightness;'"$green"$'\a' \
    $'\e]6;1;bg;blue;brightness;'"$blue"$'\a'
}
```

- [ ] **Step 5: Update the prompt hook to color by exact directory**

Use the Git root only for title text and use the directory key for color:

```zsh
  local project directory_key color suffix
  project=$(iterm_project_identity_name "$PWD")
  directory_key=$(iterm_project_identity_directory_key "$PWD")

  if [[ $directory_key == "~" ]]; then
    color=default
  else
    color=$(iterm_project_identity_color "$directory_key")
  fi

  if [[ -n $project ]]; then
    suffix=" · $project"
  else
    suffix=""
  fi

  local key="$project|$directory_key|$color"
```

After the existing `it2setcolor` block, emit:

```zsh
  iterm_project_identity_set_chrome_color "$color"
```

- [ ] **Step 6: Run the focused tests**

Run:

```bash
zsh tests/iterm-project-identity.zsh
```

Expected:

```text
PASS: iTerm project identity
```

- [ ] **Step 7: Commit the tested shell implementation**

```bash
git add .zshrc .iterm-project-identity.zsh tests/iterm-project-identity.zsh
git commit -m "Color iTerm chrome by working directory"
```

### Task 3: Apply and Verify the Live iTerm State

**Files:**
- Read: `.iterm-project-identity.zsh`
- Read: `tests/iterm-project-identity.zsh`
- Temporary: `/tmp/apply-iterm-directory-colors.py`

- [ ] **Step 1: Run static and repository checks**

Run:

```bash
zsh -n ~/.zshrc .zshrc .iterm-project-identity.zsh tests/iterm-project-identity.zsh
git diff --check
```

Expected: both commands exit successfully with no output.

- [ ] **Step 2: Verify a fresh login shell loads the integration**

Run:

```bash
TERM_PROGRAM=iTerm.app zsh -lic \
  'print -r -- "helper=$(( $+functions[iterm_project_identity_update] )) key=$(iterm_project_identity_directory_key "$PWD") color=$(iterm_project_identity_color "$(iterm_project_identity_directory_key "$PWD")")"'
```

Expected: the output ends with `helper=1`, a home-relative directory key, and a
six-digit pastel color. Escape controls before that line are expected.

- [ ] **Step 3: Apply the palette to currently open iTerm sessions**

Create a temporary Python script that:

1. Connects to iTerm's Python API.
2. Reads each session's `path`.
3. Canonicalizes and home-normalizes it using the same rules as the shell.
4. Maps it through the same `cksum` and 16-color palette.
5. Uses `session.async_inject()` to emit the OSC 6 RGB controls as terminal
   output.
6. Sets the session's local profile tab color.
7. Injects the default reset and disables tab color for sessions at home.

Run it with the already downloaded official iTerm Python package:

```bash
PYTHONPATH=/tmp/iterm-api-libs python3 /tmp/apply-iterm-directory-colors.py
```

Expected: JSON listing each open session path and its applied color.

- [ ] **Step 4: Visually verify the title bar**

Set iTerm's appearance theme to Compact and keep the tab bar visible for a
single tab. Through the Python API, these preferences are:

```text
TabStyleWithAutomaticOption = 6
HideTab = false
Use Custom Tab Title = true
Custom Tab Title = \(currentSession.autoName)\(currentSession.user.projectSuffix)
```

Compact window styling is selected when a window is created, so use a
disposable fresh window for verification instead of restarting existing
sessions with running work. Apply the custom tab-title expression to existing
tabs through `tab.async_set_title()` so their labels update immediately.

Capture the desktop:

```bash
screencapture -x /tmp/iterm-directory-colors-check.png
```

Verify that the visible iTerm title bar has the balanced pastel associated with
its current directory, title text remains readable, and the terminal
background is unchanged. Change into a subdirectory and verify that the
integrated title/tab bar switches to that directory's expected color.

- [ ] **Step 5: Stop the visual-companion server**

Run:

```bash
/Users/sainatha/.codex/plugins/cache/openai-curated/superpowers/43313cc9/skills/brainstorming/scripts/stop-server.sh \
  /tmp/iterm-color-brainstorm/.superpowers/brainstorm/67535-1781720682
```

Expected: the local palette-comparison server exits successfully.
