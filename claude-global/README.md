# claude-global

Tracked pieces of the global `~/.claude/` configuration. Sensitive/session state
lives outside this directory and is never committed.

## Layout

| Path | Symlinked from |
|------|----------------|
| `settings.json` | `~/.claude/settings.json` |
| `settings.local.json` | `~/.claude/settings.local.json` |
| `rules/` | `~/.claude/rules/` |
| `mcp-servers.example.json` | (reference only — real config lives in `~/.claude.json`) |
| `install-mcp.sh` | one-shot MCP registration script |

## Fresh-machine setup

```bash
# 1) Symlink tracked configs into ~/.claude
mkdir -p ~/.claude
ln -sfn ~/dotfiles/claude-global/settings.json       ~/.claude/settings.json
ln -sfn ~/dotfiles/claude-global/settings.local.json ~/.claude/settings.local.json
ln -sfn ~/dotfiles/claude-global/rules               ~/.claude/rules

# 2) Populate ~/dotfiles/secrets.sh with API keys (see mcp-servers.example.json),
#    then register global MCP servers:
~/dotfiles/claude-global/install-mcp.sh
```

## Skills

Global skills (`~/.claude/skills/*`) are **not** tracked here. On this machine
they are symlinks into `~/.agents/skills/`, which is populated by an external
skill-installer keyed off `~/.agents/.skill-lock.json`. Reinstall skills there
on a fresh machine rather than syncing them via dotfiles.

The one exception, `context7-mcp`, is duplicated inside the project-level
template at `~/dotfiles/.claude/skills/context7-mcp/` (installed into projects
via `claude-toolkit`).

## What is deliberately NOT tracked

`~/.claude.json`, `.credentials.json`, `sessions/`, `projects/`, `history.jsonl`,
`todos/`, `tasks/`, `plans/`, `statsig/`, `telemetry/`, `debug/`, `file-history/`,
`shell-snapshots/`, `session-env/`, `paste-cache/`, `ide/`, `stats-cache.json`,
`backups/`, `cache/`, `plugins/{cache,data,repos}` — all ephemeral or sensitive.
