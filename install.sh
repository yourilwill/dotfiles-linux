#!/usr/bin/env bash
set -euo pipefail

sudo apt update
sudo apt install -y git curl

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SOURCE_LINE=". \"$DOTFILES_DIR/bashrc.local\""
if ! grep -qF "$SOURCE_LINE" "$HOME/.bashrc" 2>/dev/null; then
  printf '\n%s\n' "$SOURCE_LINE" >> "$HOME/.bashrc"
  echo "$HOME/.bashrc に $DOTFILES_DIR/bashrc.local の読み込みを追加しました"
else
  echo "$HOME/.bashrc は既に $DOTFILES_DIR/bashrc.local を読み込み済みです"
fi
