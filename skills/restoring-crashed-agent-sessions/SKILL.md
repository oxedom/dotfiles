---
name: restoring-crashed-agent-sessions
description: Use when a machine crashed, rebooted, or lost power and took running tmux panes with it, and Claude Code or Codex CLI sessions that were open in those panes need to be found and brought back.
---

# Restoring Crashed Agent Sessions

## Overview

Both Claude Code and Codex CLI journal every turn to disk as it happens. A crash
destroys the **panes**, not the **work** — the conversations are all still on
disk, keyed by session ID. Recovery is a read of those journals, not a
reconstruction from memory.

The one judgement call worth making carefully: which sessions were *mid-task*
when the machine died, versus which had finished their turn and were idling at a
prompt. Those need different follow-up.

## When to Use

- Machine rebooted / panicked / lost power; `tmux ls` is empty or shows only a fresh session
- You know roughly what you were working on but not the session IDs
- Multiple agent panes were open across several directories or worktrees

**Not for:** a session you closed on purpose (use `claude --continue` /
`codex resume --last`), or one whose ID you already have.

## 1. Establish the crash time

```bash
uptime -s              # boot time, local
last -x -n 5 reboot    # confirm it was unclean
```

**Gotcha that will bite you:** the journals timestamp entries in **UTC**, while
`uptime`, file mtimes, and Codex rollout *filenames* are **local**. Work out the
offset before comparing anything, or you will classify the wrong sessions as
live. `classify-sessions.py` converts to local for you.

## 2. Find and classify what was running

```bash
./classify-sessions.py                          # since last boot
./classify-sessions.py --since "2024-01-30 08:00"
```

It scans both journal trees and prints, per session: state, working directory,
git branch, unfinished tool calls, and the exact resume command.

| Agent | Journal location | "Was mid-task" signal |
|-------|------------------|-----------------------|
| Claude Code | `~/.claude/projects/<cwd-slug>/<uuid>.jsonl` | a `tool_use` block with no matching `tool_result` |
| Codex CLI | `~/.codex/sessions/<Y>/<M>/<D>/rollout-*.jsonl` | last event is **not** `task_complete` |

The Claude project directory name is the working directory with `/` replaced by
`-`, so you can find a specific project's sessions directly.

Two caveats on the output: a session that is *currently running* also shows as
MID-TASK (it has an open tool call), so exclude your own; and file mtime alone
is a poor signal, since idle sessions can be touched without new turns.

## 3. Check the targets still exist

A pane cannot be rebuilt if its directory is gone — worktrees in particular get
removed once their branch ships.

```bash
git worktree list      # look for "prunable" entries
git worktree prune
```

The script marks any session whose `cwd` no longer exists with `<-- MISSING`.
Skip those; their work already landed.

## 4. Rebuild the panes

```bash
tmux new-session -d -s work -n api -c ~/proj/api
tmux new-window  -t work    -n web -c ~/proj/web

sleep 2   # let each shell finish initialising before typing into it

tmux send-keys -t work:api 'claude --resume 00000000-1111-2222-3333-444444444444' Enter
tmux send-keys -t work:web 'codex resume  55555555-6666-7777-8888-999999999999' Enter
```

| Agent | Resume command |
|-------|----------------|
| Claude Code | `claude --resume <uuid>` |
| Codex CLI | `codex resume <uuid>` |

Three tmux details that matter:

- **Set the directory with `-c` at creation**, not with a `cd` sent afterwards.
- **`send-keys` into a live shell, don't pass the command to `new-window`.**
  Shell aliases only exist in interactive shells; `tmux new-window 'my-alias'`
  will not find one.
- **`automatic-rename` is on by default**, so your window names drift back to
  the running command. Pin them:
  ```bash
  tmux rename-window -t work:api api
  tmux set-window-option -t work:api automatic-rename off
  ```

## 5. Restore what resume does not

Resuming replays the conversation. It does not replay the machine.

| Comes back | Does not |
|------------|----------|
| Full conversation history | Background dev servers, daemons, watchers |
| Working directory and branch | Env vars exported by hand in the old shell |
| Pending-task awareness | Listening ports |

Both CLIs detect background tasks with no completion record on resume and mark
them stopped — they do **not** re-run them. Restart those yourself.

The quiet failure is environment: any variable you exported interactively rather
than in your dotfiles is gone, and MCP servers that read credentials from the
environment will fail at startup with a message that scrolls past during boot.
Check the top of each restored pane. Then check ports:

```bash
ss -tlnp | grep -E '3000|4000|8080'
```

## Common Mistakes

- Comparing UTC journal timestamps against a local clock — misclassifies everything.
- Trusting window *order* after a session merge. Merges renumber and often rename
  windows to the source session name. Identify panes by content
  (`tmux capture-pane -t <win> -p -S -200`), never by index.
- Resuming a session whose worktree was deleted.
- Assuming a resumed agent restarted your dev server.

## Prevention

- Install `tmux-resurrect` + `tmux-continuum` so layout survives the next one.
- Export env vars from your dotfiles, not interactively, so restored shells inherit them.
