Branches:
- `master` branch has the linux config
- `mac` has, well, the macOS config

Set up the configs manually:
- `git clone --recursive ...`
- `ln -s ... ...`

## macOS iTerm project identity

See [docs/iterm-project-identity.md](docs/iterm-project-identity.md) for the
directory-based colors and `task · project` title behavior.

## Keyboard Shortcuts (macOS / skhd)

Managed via `skhd` (`.config/skhd/skhdrc`) and `yabai` scripts:

### Window Management
| Shortcut | Action |
| :--- | :--- |
| `ctrl - h` / `j` / `k` / `l` | Focus window west / south / north / east |
| `ctrl + shift - h` / `j` / `k` / `l` | Swap window with adjacent window west / south / north / east |
| `ctrl - f` | Toggle window fullscreen zoom |
| `cmd - tab` | Rotate space layout 270° |

### Display Management
| Shortcut | Action |
| :--- | :--- |
| `ctrl - tab` | Switch display focus between dual monitors |
| `cmd + ctrl - tab` | Move focused window to recent display and focus it |
| `ctrl + shift - tab` | Swap visible spaces across two displays |

### Spaces & Project Navigation
| Shortcut | Action |
| :--- | :--- |
| `ctrl - 1` .. `0` | Focus space 1–10 (or 11–20 when CapsLock is ON) |
| `ctrl - q` / `w` / `e` / `r` / `t` / `y` | Focus space 11–16 |
| `ctrl + shift - 1` .. `0` | Move focused window to space 1–10 (or 11–20 when CapsLock is ON) |
| `ctrl + shift - q` .. `o` | Move focused window to space 11–19 |
| `ctrl - p` | Cycle paired project spaces forward across displays |
| `ctrl + shift - p` | Cycle paired project spaces backward across displays |

> **Note:** When focusing the currently active space, it toggles back to the most recent space.

### Applications & Scratchpad
| Shortcut | Action |
| :--- | :--- |
| `ctrl - return` | Open a new iTerm window |
| `ctrl - z` | Toggle floating iTerm scratchpad (shows/focuses or minimizes) |
