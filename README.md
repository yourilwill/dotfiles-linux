# dotfiles-linux

このラップトップ（Ubuntu）のセットアップを再現するためのdotfiles。

## クリーンインストール後の手順

1. gitをインストール

   ```
   sudo apt update && sudo apt install -y git
   ```

2. このリポジトリをclone

   ```
   git clone https://github.com/yourilwill/dotfiles-linux.git ~/dotfiles-linux
   ```

3. インストールスクリプトを実行

   ```
   ~/dotfiles-linux/install.sh
   ```

   このスクリプトが以下を行う:
   - 未インストールのパッケージ（`git`, `curl`, `fcitx5`, `fcitx5-mozc`, `fcitx5-config-qt`）を`apt install`
   - 入力メソッドフレームワークを`im-config`で`fcitx5`に切り替え
   - `~/.bashrc`の末尾に`bashrc.local`を読み込む設定を追加
   - `~/.gitconfig`を`.gitconfig`へのシンボリックリンクに置き換え

4. 入力メソッドの切り替えを反映するため、一度ログアウト→ログインする

## 管理しているファイル

- `bashrc.local` — `.bashrc`本体はデフォルトのまま維持し、これだけを追加でsourceする（diffだけをgit管理）
- `.gitconfig` — `user.name` / `user.email` などのGit設定
- `install.sh` — 上記のセットアップを行うスクリプト
