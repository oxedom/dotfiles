# claude-global

Everything that becomes `~/.claude`. `../init claude` symlinks each entry below into
place, so editing a file here edits the live config.

| Path | Symlinked to | What |
|---|---|---|
| `settings.json` | `~/.claude/settings.json` | Model, hooks, statusline, marketplaces |
| `settings.local.json` | `~/.claude/settings.local.json` | Permission allowlist |
| `CLAUDE.md` | `~/.claude/CLAUDE.md` | Global persona and tone |
| `rules/` | `~/.claude/rules/` | Always-on rules (context7) |
| `agents/` | `~/.claude/agents/` | Subagents |
| `commands/` | `~/.claude/commands/` | Slash commands |
| `hooks/` | `~/.claude/hooks/` | SessionStart tmux-merge |
| `sounds/` | `~/.claude/sounds/` | Stop-hook chime |
| `statusline-command.sh` | `~/.claude/statusline-command.sh` | Statusline |

`agent-template.md` is a scaffold for writing new subagents, not a live config file.

## MCP servers

`install-mcp.sh` registers user-scope MCP servers and is idempotent. It reads keys from
`~/dotfiles/secrets.sh` (gitignored); `mcp-servers.example.json` lists which keys it wants.

```bash
../init claude          # symlinks, then runs install-mcp.sh if secrets.sh exists
```

## Skills

Skills are **not** vendored here.

- **Mine** live in `../skills/` and install with
  `npx skills@latest add oxedom/dotfiles -g -s '*'`.
- **Third-party** ones are recorded in `skills-lock.json` (source repo + skill name per
  entry) and reinstalled from their upstreams by `../init skills`.

Both land in `~/.agents/skills/`, which `~/.claude/skills/` symlinks into. To capture a
newly installed skill for future machines, refresh the lockfile:

```bash
cp ~/.agents/.skill-lock.json ~/dotfiles/claude-global/skills-lock.json
```

## Never tracked

`~/.claude.json`, `.credentials.json`, `projects/`, `history.jsonl`, `todos/`, `plans/`,
`statsig/`, `telemetry/`, `debug/`, `file-history/`, `shell-snapshots/`, `paste-cache/`,
`ide/`, `backups/`, `cache/`, `plugins/` — all ephemeral or sensitive.
