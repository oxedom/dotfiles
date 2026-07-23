---
name: restoring-crashed-agent-sessions
description: Use when a machine crashed, rebooted, or lost power and took running tmux panes with it, and Claude Code or Codex CLI sessions that were open in those panes need to be found and brought back.
---

# Restoring Crashed Agent Sessions

## Overview

Both Claude Code and Codex CLI journal every turn to disk as it happens. A crash
destroys the **panes**, not the **work** — the conversations survive, keyed by
session ID.

**Recovery is a read of what the agents already wrote down, not a reconstruction
from memory.** Reconstructing from memory is the failure mode this skill exists
to prevent: you will misremember which sessions mattered, and silently drop the
ones that were mid-task.

## When to Use

- The machine rebooted or lost power; the session list is empty or shows only a fresh session
- You know roughly what you were working on, but not the session IDs
- Several agent panes were open across different directories or worktrees

**Not for:** a session closed on purpose, or one whose ID you already have — both
CLIs have a continue/resume flag for that.

## The Judgement Call

The distinction worth making carefully is **mid-task versus idle**. A session cut
off partway through a tool call has work in flight and needs review before it is
trusted. A session that had finished its turn was just sitting at a prompt, and
can be resumed and continued.

| Agent | Where turns are journaled | Signal it was mid-task |
|-------|---------------------------|------------------------|
| Claude Code | Per-project directory, named after the working directory, one file per session | A tool call with no matching result |
| Codex CLI | Dated session rollouts | Last event is not a completion event |

## Traps

- **Timestamps mix zones.** Journals record in UTC; the system clock, file times,
  and rollout filenames are local. Compare them without converting and every
  session lands in the wrong bucket.
- **A currently-running session also looks mid-task** — it has an open tool call
  by definition. Exclude your own before drawing conclusions.
- **File modification time is a weak signal.** Idle sessions get touched without
  new turns having happened.
- **The directory may be gone.** Worktrees get removed once their branch ships;
  those sessions are not worth restoring, the work already landed.
- **Identify restored panes by their contents, not their position.** Window order
  and names drift — automatic renaming overwrites them, and merging sessions
  renumbers them.

## What Resume Does Not Restore

Resuming replays the conversation, not the machine. The history, working
directory, and pending-task awareness come back. Background servers, watchers,
daemons, and listening ports do not — both CLIs mark background tasks stopped
rather than re-running them.

The quiet one is environment: anything exported by hand in the old shell is gone,
so tooling that reads credentials from the environment fails at startup, with the
error scrolling past during restore. Check the top of each restored pane.

## Prevention

Export environment variables from your dotfiles rather than interactively, so
restored shells inherit them.
