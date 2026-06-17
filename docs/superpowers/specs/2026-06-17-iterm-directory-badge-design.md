# iTerm Directory Background Badge Design

## Goal

Add a large background badge to each iTerm session so the exact current
directory remains readable at a glance alongside the existing pastel chrome
and `task · project` title.

## User Experience

- The badge appears in iTerm's existing large, translucent top-right style.
- It shows the canonical home-relative current directory, such as
  `~/src/work-obsidian-vault/Projects`.
- Changing directories updates the badge at the next prompt.
- The home directory keeps its neutral behavior and shows no badge.
- Existing exact-directory pastel colors and Git-root project titles remain
  unchanged.
- Outside iTerm, the integration remains a no-op.

Long paths may wrap naturally in narrow terminal windows. The badge is a
background label and does not reserve terminal layout space.

## Implementation

Extend the existing `.iterm-project-identity.zsh` prompt hook.

1. Reuse `iterm_project_identity_directory_key` as the badge value so path
   canonicalization, symlink resolution, and home-relative normalization stay
   consistent with color selection.
2. Add an iTerm user variable named `directoryBadge`.
3. For non-home directories, set `directoryBadge` to the normalized path and
   set the badge format to the fixed interpolated expression
   `\(user.directoryBadge)`.
4. At home, clear `directoryBadge` and clear the badge format so no stale path
   remains visible.
5. Keep badge updates inside the existing cached prompt update. An unchanged
   directory emits no additional controls.

The badge format is sent through iTerm's documented
`OSC 1337;SetBadgeFormat=<base64>` control sequence. Using a fixed format that
references a user variable prevents directory names from being parsed as
iTerm interpolation expressions.

## Failure Handling

- If canonical path resolution cannot improve the path, the existing
  directory-key function falls back to the shell path behavior already used
  by color selection.
- If iTerm shell-integration helpers are unavailable, chrome coloring
  continues to work and the badge is explicitly cleared rather than showing a
  potentially stale value.
- Paths containing spaces or punctuation are carried as user-variable values,
  not embedded in the badge expression.

## Verification

Focused shell tests will cover:

- Non-home updates setting `directoryBadge` to the normalized current path.
- Emitting the fixed base64-encoded badge format.
- Different subdirectories producing updated badge values.
- Home clearing both the user variable and badge format.
- Cached redraws producing no output.
- Existing color and title behavior remaining intact.
- Non-iTerm shells remaining unaffected.

Documentation in `docs/iterm-project-identity.md` and `AGENTS.md` will be
updated to describe the badge and remove the previous no-badge invariant.
