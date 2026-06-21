#!/usr/bin/env bash
set -euo pipefail

sudo apt update
sudo apt install -y git curl

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILES=(.bashrc)

for file in "${FILES[@]}"; do
  target="$HOME/$file"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    mv "$target" "$target.bak"
    echo "既存の $target を $target.bak に退避しました"
  fi
  ln -sf "$DOTFILES_DIR/$file" "$target"
  echo "$target -> $DOTFILES_DIR/$file"
done
