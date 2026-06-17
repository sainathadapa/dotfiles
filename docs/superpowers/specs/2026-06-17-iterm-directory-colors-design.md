# iTerm Directory Pastel Chrome Design

## Goal

Make iTerm windows easier to distinguish by assigning the exact current
working directory a reproducible pastel color. The color should be visible in
the tab and window-title chrome without changing the terminal background.

## Behavior

- Resolve the current working directory to a canonical absolute path.
- Normalize paths under the user's home directory to start with `~` before
  hashing, so equivalent home-relative paths remain stable across machines.
- Hash the normalized path with `cksum` and map it into a curated 16-color
  balanced pastel palette.
- Recalculate after each command prompt, so changing directories updates the
  color.
- Keep the home directory neutral and restore iTerm's default chrome and tab
  colors there.
- Keep the existing `task · project` title text unchanged. The project suffix
  continues to come from the Git root name, while color provides exact
  subdirectory-level identity.
- Keep the terminal background unchanged and do not restore the removed badge.

## Implementation

The existing `.iterm-project-identity.zsh` prompt hook remains the integration
point.

1. A directory-key function canonicalizes `PWD` and replaces the home prefix
   with `~`.
2. The color function hashes that key and selects a six-digit RGB value from
   the fixed palette.
3. The prompt hook applies the RGB value through both:
   - iTerm's `SetColors=tab=...` helper for per-tab color.
   - iTerm's OSC 6 title/tab-chrome controls for the window top bar.
4. The hook caches the directory key and color to avoid redundant escape
   sequences when the prompt redraws without a directory change.
5. Outside iTerm, the hook remains a no-op.

For the color to occupy the integrated macOS top bar, iTerm uses the Compact
appearance theme and keeps the tab bar visible when a window has one tab.
The default profile's custom tab title mirrors the custom window title with
`\(currentSession.autoName)\(currentSession.user.projectSuffix)`, so Compact
windows retain the same `task · project` label.
Existing windows retain their original window style until they are reopened;
their colored tab strip remains visible in the meantime.

For windows containing multiple tabs, each tab retains its directory color and
the visible window chrome follows the active tab.

## Failure Handling

- If canonical path resolution fails, use the shell's current `PWD`.
- `cksum` is a required POSIX utility already available in the target
  environment.
- If iTerm's tab-color helper is unavailable, title-chrome coloring still
  works through direct escape sequences.
- Reset sequences are emitted when returning home so stale project colors do
  not remain visible.

## Verification

Shell tests will cover:

- Canonical and home-relative directory keys.
- Stable color selection for a known directory.
- Subdirectories being hashed independently.
- Six-digit colors drawn only from the curated palette.
- Tab and title-chrome color sequences.
- Neutral home-directory reset behavior.
- Cached redraws producing no output.
- Existing title variables and badge removal remaining intact.
- Non-iTerm shells remaining unaffected.
- A fresh Compact window showing the color across the integrated title/tab bar.
- Changing to a subdirectory changing that integrated bar to the expected
  deterministic color.
