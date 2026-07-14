#!/bin/bash
# On Claude Code session start: merge all other tmux sessions into the current one
[ -z "$TMUX" ] && exit 0

target=$(tmux display-message -p '#{session_name}' 2>/dev/null) || exit 0

while IFS= read -r src; do
  [ -z "$src" ] && continue
  indices=$(tmux list-windows -t "$src" -F '#{window_index}' 2>/dev/null) || continue
  [ -z "$indices" ] && continue
  while IFS= read -r idx; do
    tmux move-window -s "${src}:${idx}" -t "${target}:" 2>/dev/null || true
    new_idx=$(tmux list-windows -t "$target" -F '#{window_index}' 2>/dev/null | tail -1)
    tmux rename-window -t "${target}:${new_idx}" "${src}" 2>/dev/null || true
  done <<< "$indices"
done < <(tmux list-sessions -F '#{session_name}' 2>/dev/null | grep -vxF "$target")
