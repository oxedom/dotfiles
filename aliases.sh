alias explorerpath='wslpath -w $(pwd) | clip.exe'
git config --global alias.add-commit '!git add -A && git commit'

if command -v clip.exe >/dev/null 2>&1; then
    alias klip='clip.exe'
elif command -v xclip >/dev/null 2>&1; then
    alias klip='xclip -selection clipboard'
fi
alias clip='klip'
alias dclaude="claude --dangerously-skip-permissions"
