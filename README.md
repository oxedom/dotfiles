# dotfiles

Personal dev environment + Claude Code toolkit.

## Setup (new machine)

```bash
git clone git@github.com:oxedom/dotfiles.git ~/dotfiles
~/dotfiles/init
source ~/.bashrc
```

`init` will:
- Add `source ~/dotfiles/aliases.sh` to your `~/.bashrc`
- Symlink configs (tmux, pnpm, Xmodmap, nvim, kitty)

## What's in here

### Shell
- `.bashrc` — prompt, PATH (nvm, bun, cargo, go, pnpm), `mtmux` function
- `aliases.sh` — clipboard (`klip`), `dclaude`, `claude-toolkit`
- `.tmux.conf` — prefix `C-a`, mouse, pane/window nav, scrollback

### Claude Toolkit

Interactive installer that copies Claude Code agents, commands, and skills into any project's `.claude/` directory.

```bash
cd ~/repos/some-project
claude-toolkit          # interactive picker
claude-toolkit --all    # install everything
claude-toolkit --list   # see what's available
```

Contents (in `.claude/`):

| Category | Count |
|----------|-------|
| Agents | 8 |
| Commands | 29 |
| Skills | 10 |

### Other configs
- `keybindings.json` — VS Code keyboard shortcuts
- `.config/pnpm/rc` — pnpm workspace config
- `.Xmodmap` — key remapping

## Snippets

```bash
# Touchpad scroll speed
xinput set-prop 11 "libinput Scrolling Pixel Distance" 30

# Quick speedtest
curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -
```
