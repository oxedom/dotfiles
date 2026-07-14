---
name: tmux-merge-sessions
description: Use when the user wants to consolidate multiple tmux sessions into a single session's windows, or unify many tmux sessions into one tabbed view.
---

# Merge tmux Sessions into Windows

## Overview

Consolidate multiple tmux sessions into one session where each original session becomes a named window. Uses `move-window` to migrate windows and renames them by origin session for clarity.

## Steps

1. **Survey the landscape**
   ```bash
   tmux list-sessions
   tmux list-windows -a
   ```

2. **Pick a target session** — usually the currently attached one.

3. **Rename existing windows** in the target so their origin is clear:
   ```bash
   tmux rename-window -t TARGET:0 "descriptive-name"
   ```

4. **Move each window** from other sessions (omit target window number to auto-assign):
   ```bash
   tmux move-window -s SOURCE_SESSION:WINDOW_NUM -t TARGET_SESSION:
   ```

5. **Rename the moved window** immediately (tmux assigns the next available slot):
   ```bash
   tmux rename-window -t TARGET:NEW_NUM "source-session-name"
   ```

6. **Verify**:
   ```bash
   tmux list-windows -t TARGET_SESSION
   ```

## Example

Consolidate sessions `13`, `control-plane`, `waiting-plan-gen` into session `12`:

```bash
tmux rename-window -t 12:0 "12-a"

tmux move-window -s 13:0 -t 12:
tmux rename-window -t 12:2 "13"

tmux move-window -s control-plane:2 -t 12:
tmux rename-window -t 12:3 "ctrl-plane-a"
tmux move-window -s control-plane:4 -t 12:
tmux rename-window -t 12:4 "ctrl-plane-b"

tmux move-window -s waiting-plan-gen:0 -t 12:
tmux rename-window -t 12:5 "plan-gen"
```

## Navigation After Merging

| Key | Action |
|-----|--------|
| `Ctrl+b w` | Visual window picker |
| `Ctrl+b <number>` | Jump to window by index |
| `Ctrl+b n` / `p` | Next / previous window |

## Notes

- Moving the last window from a session destroys that session automatically.
- Always rename immediately after moving — auto-assigned numbers shift as windows are added.
- Multiple windows from the same session: move and rename each one individually.
