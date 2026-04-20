#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
DOTS="$DOTFILES_DIR/claude"

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

echo ""
echo "==> Done! Remaining manual steps:"
echo "    1. claude        (Claude Code 로그인)"
echo "    2. gh auth login (GitHub CLI 로그인)"
