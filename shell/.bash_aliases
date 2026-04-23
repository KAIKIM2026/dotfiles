# Codex defaults: launch with approval/sandbox bypass unless explicitly using the safe wrapper.
codex() {
    command codex --dangerously-bypass-approvals-and-sandbox "$@"
}

codex_safe() {
    command codex "$@"
}
