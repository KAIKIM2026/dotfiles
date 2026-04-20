#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Claude Code / OMC / Codex dotfiles installer"

# 1. Node / nvm check
if ! command -v node &>/dev/null; then
  echo "[!] Node not found. Install nvm first:"
  echo "    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash"
  echo "    nvm install 20 && nvm use 20"
  exit 1
fi

NODE_VER=$(node -v)
echo "[✓] Node: $NODE_VER"

# 2. Global npm packages
echo "==> Installing global npm packages..."
npm install -g @anthropic-ai/claude-code
npm install -g @openai/codex
npm install -g oh-my-claude-sisyphus
npm install -g oh-my-codex
echo "[✓] npm packages installed"

# 3. Copy Claude config files
echo "==> Copying Claude config files..."
CLAUDE_DIR="$HOME/.claude"
mkdir -p "$CLAUDE_DIR"

cp "$DOTFILES_DIR/claude/settings.json"      "$CLAUDE_DIR/settings.json"
cp "$DOTFILES_DIR/claude/settings.local.json" "$CLAUDE_DIR/settings.local.json"
cp "$DOTFILES_DIR/claude/CLAUDE.md"          "$CLAUDE_DIR/CLAUDE.md"
cp "$DOTFILES_DIR/claude/.omc-config.json"   "$CLAUDE_DIR/.omc-config.json"
cp "$DOTFILES_DIR/claude/.omc-version.json"  "$CLAUDE_DIR/.omc-version.json"

cp -r "$DOTFILES_DIR/claude/hooks"   "$CLAUDE_DIR/"
cp -r "$DOTFILES_DIR/claude/skills"  "$CLAUDE_DIR/"
cp -r "$DOTFILES_DIR/claude/hud"     "$CLAUDE_DIR/"
cp -r "$DOTFILES_DIR/claude/plugins" "$CLAUDE_DIR/"

echo "[✓] Config files copied to $CLAUDE_DIR"

# 4. omc setup
echo "==> Running omc setup..."
omc setup || echo "[!] omc setup failed — run manually: omc setup"

echo ""
echo "==> Done! Remaining manual steps:"
echo "    1. claude  (Claude Code 로그인)"
echo "    2. gh auth login  (GitHub CLI 로그인)"
echo "    3. omc setup  (필요시 재실행)"
