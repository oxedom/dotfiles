#!/bin/bash
# Claude Code status line - converted from ~/.bashrc PS1
# Original PS1: \[\033[01;32m\]\u@\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$

input=$(cat)
cwd=$(echo "$input" | jq -r '.cwd')

printf "\033[01;32m%s@\033[00m:\033[01;34m%s\033[00m" "$(whoami)" "$cwd"
