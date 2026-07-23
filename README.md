# dotfiles

Personal dev environment + shared Claude Code/Codex setup. Works on WSL, Linux,
and macOS.

## New machine

```bash
git clone https://github.com/oxedom/dotfiles.git ~/dotfiles
~/dotfiles/init
exec $SHELL -l
```

`init` is idempotent and backs up anything real it would overwrite. Run a single
section with `init shell`, `init claude`, or `init skills`.

It will:

1. **shell** — symlink `.bashrc` (which sources `aliases.sh`), tmux, nvim and pnpm,
   plus kitty and Xmodmap on Linux. On macOS it appends the alias source line to
   `.zshrc` instead.
2. **claude** — symlink `claude-global/` into `~/.claude`, then register MCP servers
   if `secrets.sh` exists.
3. **skills** — install this repo's skills globally and replay every third-party skill
   from `claude-global/skills-lock.json`.
4. **bridge** — expose Claude skills, commands, subagents, and compatible global
   imports through Codex's native discovery paths.

MCP servers need credentials. Create `~/dotfiles/secrets.sh` (gitignored) using
`claude-global/mcp-servers.example.json` as the key list, then re-run `init claude`.

## Layout

```
skills/           Agent skills. Installable by anyone (see below).
claude-global/    Everything that becomes ~/.claude — symlinked by init.
  settings.json     Model, hooks, statusline, marketplaces
  CLAUDE.md         Global persona / tone
  rules/            Always-on rules (context7)
  agents/           6 subagents
  commands/         20 slash commands
  hooks/            SessionStart tmux-merge
  sounds/           Stop-hook chime
  skills-lock.json  Third-party skills, for reinstall on a new machine
.config/          nvim, kitty, pnpm
.bashrc .tmux.conf .Xmodmap aliases.sh
keybindings.json  VS Code
```

## Skills

Skills live in `skills/` and follow the [Agent Skills](https://skills.sh) convention,
so they install with the standard CLI on any supported agent:

```bash
npx skills@latest add oxedom/dotfiles           # pick interactively
npx skills@latest add oxedom/dotfiles -g -s '*' # all of them, globally
npx skills@latest add oxedom/dotfiles -l        # just list them
```

| Skill | What it's for |
|---|---|
| `bootstrapping-projects` | Nothing to a named, private GitHub repo |
| `context7-mcp` | Pull real library docs instead of guessing from training data |
| `playwright-cli` | Drive a browser: forms, screenshots, scraping |
| `react-best-practices` | React performance rules (rendering, bundles, async) |
| `skill-creator` | Write new skills |
| `small-to-before-research` | Sharpen a vague prompt before codebase research |
| `sql-pro` | Query optimization, indexing, schema design |
| `sticky-action-bar` | Pinned bottom action bars that survive scroll |
| `testing` | Test strategy, stateful tests, LLM evals |
| `tmux-merge-sessions` | Collapse duplicate tmux sessions |
| `using-git-worktrees` | Isolated worktrees with branch conventions |

## Claude/Codex bridge

The reusable sources live in `skills/` and `claude-global/`.
`sync-agent-resources` uses symlinks for portable Agent Skills and thin generated
adapters where the Claude and Codex formats differ.

```bash
agent-sync             # sync global Claude resources into Codex
agent-sync --check     # audit without changing anything

agent-sync --project /path/to/repo
```

- `.agents/skills/<name>` symlinks for Codex skill discovery
- `.agents/skills/<command>/SKILL.md` adapters for Claude legacy commands
- `.codex/agents/<name>.toml` adapters for Claude subagents
- `AGENTS.md -> CLAUDE.md` when the project does not already have `AGENTS.md`

Existing hand-written Codex files are never overwritten.

Third-party skills are not vendored here. They're recorded in
`claude-global/skills-lock.json` and reinstalled from source by `init skills`
(or `skills-sync`).

## Secrets

`secrets.sh` is gitignored and must never be committed. `.gitignore` also blocks
`*.jks`, `*.keystore`, and `.env`. Keystores and signing keys belong in a password
manager, not here.

See [AGENT-COMPATIBILITY.md](AGENT-COMPATIBILITY.md) for the exact compatibility
boundaries and maintenance model.

## Snippets

```bash
# Touchpad scroll speed
xinput set-prop 11 "libinput Scrolling Pixel Distance" 30

# Quick speedtest
curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -
```
