#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
DOTS="$DOTFILES_DIR/claude"
TMUX_DIR="$HOME/.tmux"
BASHRC_PATH="$HOME/.bashrc"
TMUX_CONF_PATH="$HOME/.tmux.conf"

ensure_line() {
  local file="$1"
  local line="$2"

  touch "$file"
  if ! grep -Fqx "$line" "$file"; then
    printf '\n%s\n' "$line" >> "$file"
  fi
}

echo "==> Claude Code / OMC / Codex dotfiles installer"

# 1. Node / nvm check
if ! command -v node &>/dev/null; then
  echo "[!] Node not found. Install nvm first:"
  echo "    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash"
  echo "    nvm install 20 && nvm use 20"
  exit 1
fi
echo "[✓] Node: $(node -v)"

# 2. Global npm packages
echo "==> Installing global npm packages..."
npm install -g @anthropic-ai/claude-code
npm install -g @openai/codex
npm install -g oh-my-claude-sisyphus
npm install -g oh-my-codex
echo "[✓] npm packages installed"

# 3. Symlink Claude config files
echo "==> Symlinking Claude config files..."
mkdir -p "$CLAUDE_DIR"

for f in settings.json settings.local.json CLAUDE.md .omc-config.json .omc-version.json; do
  rm -f "$CLAUDE_DIR/$f"
  ln -sf "$DOTS/$f" "$CLAUDE_DIR/$f"
done

for d in hooks skills hud plugins; do
  rm -rf "$CLAUDE_DIR/$d"
  ln -sf "$DOTS/$d" "$CLAUDE_DIR/$d"
done

echo "[✓] Symlinks created → $CLAUDE_DIR"

# 4. omc setup
echo "==> Running omc setup..."
omc setup || echo "[!] omc setup failed — run manually: omc setup"

# 5. omx setup
echo "==> Running omx setup..."
omx setup || echo "[!] omx setup failed — run manually: omx setup"

# 6. Codex/tmux assets
echo "==> Installing Codex tmux helpers..."
mkdir -p "$TMUX_DIR"
ln -sf "$DOTFILES_DIR/tmux/codex-usage-status.sh" "$TMUX_DIR/codex-usage-status.sh"
ln -sf "$DOTFILES_DIR/tmux/codex-status-line.mjs" "$TMUX_DIR/codex-status-line.mjs"
chmod +x "$DOTFILES_DIR/tmux/codex-usage-status.sh" "$DOTFILES_DIR/tmux/codex-status-line.mjs" "$DOTFILES_DIR/shell/codex-tmux.sh" "$DOTFILES_DIR/codex/apply-local-preferences.mjs"

ensure_line "$BASHRC_PATH" "[ -f \"$DOTFILES_DIR/shell/codex-tmux.sh\" ] && . \"$DOTFILES_DIR/shell/codex-tmux.sh\""
ensure_line "$TMUX_CONF_PATH" "source-file \"$DOTFILES_DIR/tmux/codex.tmux.conf\""

node "$DOTFILES_DIR/codex/apply-local-preferences.mjs"
tmux source-file "$TMUX_CONF_PATH" >/dev/null 2>&1 || true
echo "[✓] Codex/tmux preferences installed"

echo ""
echo "==> Done! Remaining manual steps:"
echo "    1. claude        (Claude Code 로그인)"
echo "    2. gh auth login (GitHub CLI 로그인)"
