# AGENTS.md

## Repository

- `mac` is the macOS configuration branch.
- `master` is the Linux configuration branch.
- Preserve unrelated worktree and submodule changes. In particular, do not
  reset `.config/nvim` merely because it is reported as modified.

## iTerm project identity

The macOS setup gives every exact current directory a stable pastel identity:

- Each canonical directory hashes through POSIX `cksum` into a fixed 16-color
  palette.
- A `cd` into a subdirectory may change the color, including inside monorepos.
- Home is neutral and resets iTerm's tab and title chrome.
- Titles use `task · project`; the project suffix comes from the Git root.
- Each tab keeps its own identity, and the active tab controls window chrome.
- The terminal background is unchanged, no badge is shown, and non-iTerm
  shells are unaffected.

Implementation and tests:

- `.iterm-project-identity.zsh`
- `.zshrc`
- `tests/iterm-project-identity.zsh`
- `docs/iterm-project-identity.md`

Do not change the hashing input, palette order, home reset, title variables, or
prompt-hook caching without updating the focused tests.

## Required iTerm state

The full-width colored top bar requires:

```text
TabStyleWithAutomaticOption = 6
HideTab = false
Use Custom Tab Title = true
Custom Tab Title = \(currentSession.autoName)\(currentSession.user.projectSuffix)
Use Custom Window Title = true
Custom Window Title = \(currentTab.currentSession.autoName)\(currentTab.currentSession.user.projectSuffix)
```

Theme value `6` is Compact. Compact window styling takes effect when a window
is created, so do not restart or close terminals with running work just to
refresh their frame style. Newly opened or deliberately reopened windows use
the integrated colored title/tab bar.

## Verification

Run:

```sh
zsh tests/iterm-project-identity.zsh
zsh -n ~/.zshrc .zshrc .iterm-project-identity.zsh \
  tests/iterm-project-identity.zsh
git diff --check
```

Expected focused-test output:

```text
PASS: iTerm project identity
```
