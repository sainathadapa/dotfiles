# iTerm Directory Background Badge Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show the canonical home-relative current directory as an iTerm background badge while preserving the existing pastel chrome, `task · project` titles, and neutral home behavior.

**Architecture:** Extend the existing zsh prompt hook with a fixed iTerm badge format that references a `directoryBadge` user variable. Reuse the exact directory key already used for color hashing, clear both the variable and badge format at home, and apply the same state to currently open iTerm sessions through the Python API.

**Tech Stack:** zsh, POSIX `base64`, iTerm2 shell integration and proprietary escape sequences, iTerm2 Python API, shell test harness.

---

### Task 1: Add Failing Badge Behavior Tests

**Files:**
- Modify: `tests/iterm-project-identity.zsh:100-165`
- Test: `tests/iterm-project-identity.zsh`

- [ ] **Step 1: Add a unit assertion for the badge control**

After the existing chrome-control assertion, add:

```zsh
directory_badge_control=$(iterm_project_identity_set_badge_format '\(user.directoryBadge)')
assert_equal \
  $'\e]1337;SetBadgeFormat=XCh1c2VyLmRpcmVjdG9yeUJhZGdlKQ==\a' \
  "$directory_badge_control" \
  "emits the fixed directory badge format"
```

- [ ] **Step 2: Require the normalized path user variable and badge format**

Replace the assertion that rejects `SetBadgeFormat` in the first update with:

```zsh
assert_contains \
  "$output" \
  "VAR:directoryBadge:$directory_key;" \
  "sets the normalized directory badge variable"
assert_contains \
  "$output" \
  "$(iterm_project_identity_set_badge_format '\(user.directoryBadge)')" \
  "renders the directory badge"
```

- [ ] **Step 3: Require a badge update in a same-repository subdirectory**

After calculating `changed_directory_output`, add:

```zsh
changed_directory_key=$(iterm_project_identity_directory_key "$PWD")
assert_contains \
  "$changed_directory_output" \
  "VAR:directoryBadge:$changed_directory_key;" \
  "updates the badge for another directory in the same Git repository"
```

- [ ] **Step 4: Require explicit home clearing**

Replace the assertion that rejects a home badge with:

```zsh
assert_contains \
  "$neutral_output" \
  "VAR:directoryBadge:;" \
  "clears the directory badge variable at home"
assert_contains \
  "$neutral_output" \
  "$(iterm_project_identity_set_badge_format "")" \
  "clears the badge format at home"
```

- [ ] **Step 5: Cover missing iTerm user-variable helpers**

Before the non-iTerm test, add:

```zsh
cd "$tmpdir/alpha-repo/nested/path"
unfunction iterm2_set_user_var
unset ITERM_PROJECT_IDENTITY_LAST_KEY
iterm_project_identity_update > "$tmpdir/no-user-var-helper-output"
no_user_var_helper_output=$(<"$tmpdir/no-user-var-helper-output")
assert_contains \
  "$no_user_var_helper_output" \
  "$(iterm_project_identity_set_badge_format "")" \
  "clears the badge when the user-variable helper is unavailable"
```

- [ ] **Step 6: Run the test and verify the red state**

Run:

```sh
zsh tests/iterm-project-identity.zsh
```

Expected: failure because `iterm_project_identity_set_badge_format` does not
exist and the prompt hook does not set `directoryBadge`.

- [ ] **Step 7: Commit the failing test**

```sh
git add tests/iterm-project-identity.zsh
git commit -m "Test iTerm directory background badge"
```

### Task 2: Implement Badge Rendering in the Prompt Hook

**Files:**
- Modify: `.iterm-project-identity.zsh:58-111`
- Test: `tests/iterm-project-identity.zsh`

- [ ] **Step 1: Add the badge-format control helper**

Insert after `iterm_project_identity_set_chrome_color`:

```zsh
iterm_project_identity_set_badge_format() {
  emulate -L zsh

  local format=$1
  local encoded
  encoded=$(print -rn -- "$format" | base64)
  print -rn -- $'\e]1337;SetBadgeFormat='"$encoded"$'\a'
}
```

- [ ] **Step 2: Derive badge state from the existing directory key**

Change the local declarations and directory-state block in
`iterm_project_identity_update` to:

```zsh
  local project directory_key color suffix badge_value badge_format
  project=$(iterm_project_identity_name "$PWD")
  directory_key=$(iterm_project_identity_directory_key "$PWD")

  badge_value=""
  badge_format=""
  if [[ $directory_key == "~" ]]; then
    color=default
  else
    color=$(iterm_project_identity_color "$directory_key")
    badge_value=$directory_key
    badge_format='\(user.directoryBadge)'
  fi
```

- [ ] **Step 3: Set the user variable only when the helper exists**

Replace the two independent user-variable calls with:

```zsh
  if (( $+functions[iterm2_set_user_var] )); then
    iterm2_set_user_var project "$project"
    iterm2_set_user_var projectSuffix "$suffix"
    iterm2_set_user_var directoryBadge "$badge_value"
  else
    badge_format=""
  fi
```

This clears the badge format rather than displaying a stale variable when
iTerm shell-integration helpers are unavailable.

- [ ] **Step 4: Emit the badge control with the existing chrome update**

After the chrome-color call, add:

```zsh
  iterm_project_identity_set_badge_format "$badge_format"
```

- [ ] **Step 5: Run the focused test**

Run:

```sh
zsh tests/iterm-project-identity.zsh
```

Expected:

```text
PASS: iTerm project identity
```

- [ ] **Step 6: Run syntax and whitespace checks**

```sh
zsh -n ~/.zshrc .zshrc .iterm-project-identity.zsh \
  tests/iterm-project-identity.zsh
git diff --check
```

Expected: both commands exit successfully.

- [ ] **Step 7: Commit the implementation**

```sh
git add .iterm-project-identity.zsh tests/iterm-project-identity.zsh
git commit -m "Show current directory in iTerm badge"
```

### Task 3: Update User and Agent Documentation

**Files:**
- Modify: `docs/iterm-project-identity.md:3-20`
- Modify: `AGENTS.md:10-31`

- [ ] **Step 1: Update the end-user description**

In `docs/iterm-project-identity.md`, add this end-user bullet:

```markdown
- A translucent background badge shows the home-relative current path.
```

Replace the behavior sentence that says no badge is displayed with:

```markdown
The prompt hook updates after each command, caches unchanged state, resets the
color and hides the badge at home, and does nothing outside iTerm. It does not
change the terminal background.
```

- [ ] **Step 2: Update future-agent invariants**

In `AGENTS.md`, replace the no-badge bullet with:

```markdown
- A large translucent badge shows the canonical home-relative current path.
- Home clears the badge; non-iTerm shells remain unaffected.
- The terminal background itself is unchanged.
```

Add this invariant after the existing prompt-hook warning:

```markdown
The badge format must remain the fixed expression
`\(user.directoryBadge)`. Store paths in the user variable rather than
embedding them in the badge format, so unusual path characters remain data.
```

- [ ] **Step 3: Run documentation and focused checks**

```sh
grep -RInE 'no badge|does not.*badge' \
  docs/iterm-project-identity.md AGENTS.md
zsh tests/iterm-project-identity.zsh
git diff --check
```

Expected: `grep` returns no matches, the focused test passes, and the diff
check is clean.

- [ ] **Step 4: Commit the documentation**

```sh
git add docs/iterm-project-identity.md AGENTS.md
git commit -m "Document iTerm directory badge"
```

### Task 4: Apply and Verify Live iTerm Sessions

**Files:**
- Read: `.iterm-project-identity.zsh`
- Temporary: `/tmp/iterm-api-venv`
- Temporary: `/tmp/apply-iterm-directory-badges.py`

- [ ] **Step 1: Verify a fresh login shell emits the badge**

Run:

```sh
TERM_PROGRAM=iTerm.app zsh -lic \
  'unset ITERM_PROJECT_IDENTITY_LAST_KEY; iterm_project_identity_update' \
  > /tmp/iterm-badge-login-output
grep -a 'SetBadgeFormat=XCh1c2VyLmRpcmVjdG9yeUJhZGdlKQ==' \
  /tmp/iterm-badge-login-output
```

Expected: `grep` finds the fixed badge control.

- [ ] **Step 2: Create a temporary Python environment**

```sh
uv venv /tmp/iterm-api-venv
uv pip install --python /tmp/iterm-api-venv/bin/python iterm2
```

Expected: commands exit successfully without modifying the repository.

- [ ] **Step 3: Create the live-session application script**

Create `/tmp/apply-iterm-directory-badges.py`:

```python
#!/usr/bin/env python3

import base64
import json
from pathlib import Path

import iterm2


BADGE_FORMAT = r"\(user.directoryBadge)"


def directory_key(path):
    directory = Path(path).expanduser().resolve()
    home = Path.home().resolve()
    if directory == home:
        return "~"
    try:
        relative = directory.relative_to(home)
    except ValueError:
        return str(directory)
    return f"~/{relative}"


def badge_control(format_string):
    encoded = base64.b64encode(format_string.encode()).decode()
    return f"\x1b]1337;SetBadgeFormat={encoded}\x07".encode()


async def main(connection):
    app = await iterm2.async_get_app(connection)
    applied = []
    for window in app.terminal_windows:
        for tab in window.tabs:
            for session in tab.sessions:
                path = await session.async_get_variable("path")
                key = directory_key(path)
                value = "" if key == "~" else key
                format_string = "" if key == "~" else BADGE_FORMAT
                await session.async_set_variable(
                    "user.directoryBadge", value
                )
                await session.async_inject(
                    badge_control(format_string)
                )
                applied.append(
                    {
                        "session": session.session_id,
                        "path": path,
                        "badge": value or "hidden",
                    }
                )
    print(json.dumps(applied, indent=2))


iterm2.run_until_complete(main)
```

- [ ] **Step 4: Apply badges to open sessions**

```sh
/tmp/iterm-api-venv/bin/python \
  /tmp/apply-iterm-directory-badges.py
```

Expected: JSON lists each open session and its home-relative badge path.

- [ ] **Step 5: Visually verify the badge**

```sh
osascript -e 'tell application "iTerm2" to activate'
sleep 1
screencapture -x /tmp/iterm-directory-badge-check.png
```

Verify that the active terminal shows its home-relative path as a large
top-right background badge, while terminal text, pastel chrome, and
`task · project` title remain readable.

- [ ] **Step 6: Run final repository checks**

```sh
zsh tests/iterm-project-identity.zsh
zsh -n ~/.zshrc .zshrc .iterm-project-identity.zsh \
  tests/iterm-project-identity.zsh
git diff --check
git status --short
```

Expected: tests and syntax checks pass. Repository status contains only the
pre-existing `.config/nvim` submodule modification.

- [ ] **Step 7: Remove temporary files**

```sh
rm -f /tmp/apply-iterm-directory-badges.py \
  /tmp/iterm-badge-login-output \
  /tmp/iterm-directory-badge-check.png
find /tmp/iterm-api-venv -depth -delete
```

Expected: temporary files are removed without changing persisted iTerm state.
