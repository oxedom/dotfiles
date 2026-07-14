#!/bin/bash
# Registers global (user-scope) MCP servers with Claude Code.
# Reads credentials from ~/dotfiles/secrets.sh (gitignored). Idempotent.
#
# Usage: ~/dotfiles/claude-global/install-mcp.sh

set -e

SECRETS="$HOME/dotfiles/secrets.sh"
[ -f "$SECRETS" ] && source "$SECRETS"

if ! command -v claude >/dev/null 2>&1; then
    echo "[error] 'claude' CLI not found in PATH"
    exit 1
fi

add_mcp() {
    local name="$1"
    local json="$2"
    if claude mcp list --scope user 2>/dev/null | grep -q "^${name}\b"; then
        echo "[ok] ${name} already registered"
        return
    fi
    claude mcp add-json --scope user "$name" "$json" && echo "[add] ${name}"
}

if [ -n "$CONTEXT7_API_KEY" ]; then
    add_mcp "context7" "$(cat <<EOF
{
  "type": "http",
  "url": "https://mcp.context7.com/mcp",
  "headers": { "CONTEXT7_API_KEY": "${CONTEXT7_API_KEY}" }
}
EOF
)"
else
    echo "[skip] CONTEXT7_API_KEY not set"
fi

if [ -n "$BRIGHTDATA_MCP_URL" ]; then
    add_mcp "brightdata" "$(cat <<EOF
{
  "type": "http",
  "url": "${BRIGHTDATA_MCP_URL}"
}
EOF
)"
else
    echo "[skip] BRIGHTDATA_MCP_URL not set"
fi

echo "Done."
