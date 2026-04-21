#!/usr/bin/env bash

set -euo pipefail

session_name="${1:-}"

if [[ -z "$session_name" ]]; then
  session_name="$(tmux display-message -p '#S' 2>/dev/null || true)"
fi

if [[ -z "$session_name" ]]; then
  exit 0
fi

if ! tmux list-panes -t "$session_name" -F '#{pane_start_command}' 2>/dev/null | grep -qi 'codex'; then
  exit 0
fi

renderer_script="${CODEX_STATUS_RENDERER_SCRIPT:-$HOME/.tmux/codex-status-line.mjs}"
node "$renderer_script"
