#!/usr/bin/env bash

codex() {
    local codex_bin shell_cmd session_name
    codex_bin="$(type -P codex)"
    if [ -z "$codex_bin" ]; then
        echo "codex binary not found in PATH" >&2
        return 127
    fi

    if [ -n "${TMUX-}" ] || ! command -v tmux >/dev/null 2>&1 || [ "${CODEX_FORCE_NO_TMUX:-0}" = "1" ]; then
        command "$codex_bin" "$@"
        return $?
    fi

    session_name="${CODEX_TMUX_SESSION_NAME:-codex-hud}"
    printf -v shell_cmd 'exec %q' "$codex_bin"
    if [ "$#" -gt 0 ]; then
        local arg
        for arg in "$@"; do
            printf -v shell_cmd '%s %q' "$shell_cmd" "$arg"
        done
    fi

    tmux source-file "$HOME/.tmux.conf" >/dev/null 2>&1 || true

    if tmux has-session -t "$session_name" 2>/dev/null; then
        tmux new-window -t "${session_name}:" -c "$PWD" "$shell_cmd"
        tmux attach-session -t "$session_name"
    else
        tmux new-session -s "$session_name" -c "$PWD" "$shell_cmd"
    fi
}
