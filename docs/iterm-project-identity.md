# iTerm Project Identity

## End-user experience

- Each directory gets a stable, reproducible pastel color.
- Changing directories updates the color automatically.
- Home remains neutral instead of receiving a color.
- Titles show `task · project`; each tab has its own identity.
- New or reopened windows display color across the integrated top bar.

## Behavior

The exact canonical current directory is normalized relative to home, hashed
with `cksum`, and mapped into a fixed 16-color pastel palette. The Git root is
used only for the project suffix in the title, so directories inside a
monorepo can have different colors while retaining the same project name.

The prompt hook updates after each command, caches unchanged state, resets the
color at home, and does nothing outside iTerm. It does not change the terminal
background or display a badge.

## iTerm settings

The integrated top bar depends on these persisted iTerm settings:

- Theme: Compact (`TabStyleWithAutomaticOption = 6`)
- Show the tab bar for one tab (`HideTab = false`)
- Custom tab title:
  `\(currentSession.autoName)\(currentSession.user.projectSuffix)`
- Custom window title:
  `\(currentTab.currentSession.autoName)\(currentTab.currentSession.user.projectSuffix)`

Compact styling is selected when a window is created. Existing windows keep
their previous frame style until they are reopened, though their colored tab
strip and title still update immediately.

## Implementation

- `.iterm-project-identity.zsh`: directory identity, color selection, title
  variables, and prompt hook
- `.zshrc`: loads the helper
- `tests/iterm-project-identity.zsh`: focused behavior tests

Verify with:

```sh
zsh tests/iterm-project-identity.zsh
zsh -n ~/.zshrc .zshrc .iterm-project-identity.zsh \
  tests/iterm-project-identity.zsh
```
