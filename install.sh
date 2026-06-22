#!/usr/bin/env bash
set -euo pipefail

if [ ! -f /etc/apt/sources.list.d/wezterm.list ]; then
  curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
  echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list > /dev/null
  sudo chmod 644 /usr/share/keyrings/wezterm-fury.gpg
  sudo apt update
fi

PACKAGES=(git curl unzip fcitx5 fcitx5-mozc fcitx5-config-qt wezterm-nightly rofi)
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

LINK_FILES=(.gitconfig .config/fcitx5/config .config/fcitx5/resume-restart.sh .config/xremap/config.yml .config/systemd/user/xremap.service .config/systemd/user/fcitx5-resume-restart.service .config/wezterm/wezterm.lua .config/herdr/config.toml .config/oh-my-posh/dracula.omp.json .config/rofi/config.rasi .config/rofi/themes/alfred-dracula.rasi)
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

# xremap: system-wide key remapper (Emacs-style bindings)
if [ ! -x "$HOME/.local/bin/xremap" ]; then
  XREMAP_VERSION="v0.15.8"
  TMP_ZIP="$(mktemp --suffix=.zip)"
  curl -fL -o "$TMP_ZIP" "https://github.com/xremap/xremap/releases/download/${XREMAP_VERSION}/xremap-linux-x86_64-gnome.zip"
  mkdir -p "$HOME/.local/bin"
  unzip -o "$TMP_ZIP" -d "$HOME/.local/bin" >/dev/null
  chmod +x "$HOME/.local/bin/xremap"
  rm -f "$TMP_ZIP"
  echo "xremap を $HOME/.local/bin/xremap にインストールしました"
fi

if ! getent group input | grep -q "\b$USER\b"; then
  sudo usermod -aG input "$USER"
  echo "$USER を input グループに追加しました（反映にはログアウト/ログインが必要です）"
fi

if [ ! -f /etc/udev/rules.d/99-input.rules ]; then
  echo 'KERNEL=="uinput", GROUP="input", MODE="0660"' | sudo tee /etc/udev/rules.d/99-input.rules > /dev/null
  sudo udevadm control --reload-rules
  sudo udevadm trigger
fi

if [ ! -d "$HOME/.local/share/gnome-shell/extensions/xremap@k0kubun.com" ]; then
  mkdir -p "$HOME/.local/share/gnome-shell/extensions"
  git clone https://github.com/xremap/xremap-gnome "$HOME/.local/share/gnome-shell/extensions/xremap@k0kubun.com"
  echo "xremap の GNOME Shell拡張をインストールしました。ログアウト/ログイン後に 'gnome-extensions enable xremap@k0kubun.com' を実行してください"
fi

systemctl --user daemon-reload
systemctl --user enable --now xremap.service 2>&1 || echo "xremap.service の起動に失敗しました（input グループの反映にログアウト/ログインが必要な場合があります）"
systemctl --user enable --now fcitx5-resume-restart.service

if [ ! -x "$HOME/.local/bin/herdr" ]; then
  curl -fsSL https://herdr.dev/install.sh | sh
fi

# oh-my-posh: bash prompt (Dracula theme)
if [ ! -x "$HOME/.local/bin/oh-my-posh" ]; then
  OH_MY_POSH_VERSION="v29.17.0"
  mkdir -p "$HOME/.local/bin"
  curl -fL -o "$HOME/.local/bin/oh-my-posh" "https://github.com/JanDeDobbeleer/oh-my-posh/releases/download/${OH_MY_POSH_VERSION}/posh-linux-amd64"
  chmod +x "$HOME/.local/bin/oh-my-posh"
  echo "oh-my-posh を $HOME/.local/bin/oh-my-posh にインストールしました"
fi

# rofi: launcher on Super+R via GNOME custom keybinding
# -normal-window is required: plain override-redirect popups don't reliably
# receive keyboard focus from Mutter/XWayland, so ESC/typing silently fail.
ROFI_CUSTOM_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/rofi/"
ROFI_COMMAND="env -u WAYLAND_DISPLAY DISPLAY=:0 rofi -show drun -normal-window"
EXISTING_KEYBINDINGS="$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)"
if [[ "$EXISTING_KEYBINDINGS" != *"$ROFI_CUSTOM_PATH"* ]]; then
  if [ "$EXISTING_KEYBINDINGS" = "@as []" ]; then
    NEW_KEYBINDINGS="['$ROFI_CUSTOM_PATH']"
  else
    NEW_KEYBINDINGS="${EXISTING_KEYBINDINGS%]}, '$ROFI_CUSTOM_PATH']"
  fi
  gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$NEW_KEYBINDINGS"
  echo "rofi 用のキーバインドエントリを追加しました"
fi
gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$ROFI_CUSTOM_PATH" name "rofi launcher"
gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$ROFI_CUSTOM_PATH" command "$ROFI_COMMAND"
gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$ROFI_CUSTOM_PATH" binding "<Super>r"
echo "Super+R で rofi が起動するように設定しました"

# Toggler: GNOME extension to minimize/restore WezTerm on Ctrl+Alt+I
# (focus when minimized/unfocused, minimize when already focused)
if [ ! -d "$HOME/.local/share/gnome-shell/extensions/toggler@hedgie.tech" ]; then
  git clone https://github.com/hedgieinsocks/gnome-extension-toggler "$HOME/.local/share/gnome-shell/extensions/toggler@hedgie.tech"
  echo "Toggler の GNOME Shell拡張をインストールしました。ログアウト/ログイン後に 'gnome-extensions enable toggler@hedgie.tech' を実行してください"
fi
glib-compile-schemas "$HOME/.local/share/gnome-shell/extensions/toggler@hedgie.tech/schemas"
TOGGLER_SCHEMA_DIR="$HOME/.local/share/gnome-shell/extensions/toggler@hedgie.tech/schemas"
GSETTINGS_SCHEMA_DIR="$TOGGLER_SCHEMA_DIR" gsettings set org.gnome.shell.extensions.toggler terminal-id "org.wezfurlong.wezterm.desktop"
GSETTINGS_SCHEMA_DIR="$TOGGLER_SCHEMA_DIR" gsettings set org.gnome.shell.extensions.toggler terminal-shortcut "['<Ctrl><Alt>i']"
GSETTINGS_SCHEMA_DIR="$TOGGLER_SCHEMA_DIR" gsettings set org.gnome.shell.extensions.toggler terminal-shortcut-text "<Ctrl><Alt>i"
echo "Ctrl+Alt+I で WezTerm をトグル表示できるように設定しました"
