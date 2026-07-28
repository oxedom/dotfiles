alias explorerpath='wslpath -w $(pwd) | clip.exe'
git config --global alias.add-commit '!git add -A && git commit'

# Clipboard: WSL -> macOS -> X11
if command -v clip.exe >/dev/null 2>&1; then
    alias klip='clip.exe'
elif command -v pbcopy >/dev/null 2>&1; then
    alias klip='pbcopy'
elif command -v xclip >/dev/null 2>&1; then
    alias klip='xclip -selection clipboard'
fi
alias clip='klip'
alias dclaude="claude --dangerously-skip-permissions"

# Reinstall/refresh agent skills from the tracked lockfile.
alias skills-sync="$HOME/dotfiles/init skills"
alias agent-sync="$HOME/dotfiles/sync-agent-resources"
