#!/usr/bin/env bash
set -euo pipefail

PACKAGES=(git curl fcitx5 fcitx5-mozc fcitx5-config-qt)
MISSING=()
for pkg in "${PACKAGES[@]}"; do
  dpkg -s "$pkg" >/dev/null 2>&1 || MISSING+=("$pkg")
done
if [ "${#MISSING[@]}" -gt 0 ]; then
  sudo apt update
  sudo apt install -y "${MISSING[@]}"
fi

if ! grep -qF "run_im fcitx5" "$HOME/.xinputrc" 2>/dev/null; then
  im-config -n fcitx5
  echo "im-config を fcitx5 に切り替えました（反映にはログアウト/ログインが必要です）"
fi

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SOURCE_LINE=". \"$DOTFILES_DIR/bashrc.local\""
if ! grep -qF "$SOURCE_LINE" "$HOME/.bashrc" 2>/dev/null; then
  printf '\n%s\n' "$SOURCE_LINE" >> "$HOME/.bashrc"
  echo "$HOME/.bashrc に $DOTFILES_DIR/bashrc.local の読み込みを追加しました"
else
  echo "$HOME/.bashrc は既に $DOTFILES_DIR/bashrc.local を読み込み済みです"
fi

LINK_FILES=(.gitconfig .config/fcitx5/config)
for file in "${LINK_FILES[@]}"; do
  target="$HOME/$file"
  mkdir -p "$(dirname "$target")"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    mv "$target" "$target.bak"
    echo "既存の $target を $target.bak に退避しました"
  fi
  ln -sf "$DOTFILES_DIR/$file" "$target"
  echo "$target -> $DOTFILES_DIR/$file"
done

mkdir -p "$HOME/.config/autostart"
cp /usr/share/applications/org.fcitx.Fcitx5.desktop "$HOME/.config/autostart/org.fcitx.Fcitx5.desktop"

fcitx5-remote -r >/dev/null 2>&1 || true
