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
   - 未インストールのパッケージ（`git`, `curl`, `unzip`, `fcitx5`, `fcitx5-mozc`, `fcitx5-config-qt`）を`apt install`
   - 入力メソッドフレームワークを`im-config`で`fcitx5`に切り替え
   - `~/.bashrc`の末尾に`bashrc.local`を読み込む設定を追加
   - `~/.gitconfig`を`.gitconfig`へのシンボリックリンクに置き換え
   - `~/.config/fcitx5/config`を`.config/fcitx5/config`へのシンボリックリンクに置き換え、`fcitx5-remote -r`でリロード
   - `~/.config/autostart/org.fcitx.Fcitx5.desktop`を配置（GNOMEではfcitx5がデフォルトで自動起動エントリを持たないため、これが無いとログインしてもfcitx5が起動しない）
   - `xremap`バイナリを`~/.local/bin/xremap`にダウンロード
   - ユーザーを`input`グループに追加し、`/dev/uinput`用のudevルールを追加（`xremap`が`/dev/input`を読むのに必要）
   - `xremap`のGNOME Shell拡張(`xremap@k0kubun.com`)をclone（フォーカス中のアプリ名を取得するために必要。**有効化は手動**: ログイン後に`gnome-extensions enable xremap@k0kubun.com`を実行）
   - `~/.config/xremap/config.yml`をシンボリックリンクに置き換え、`xremap.service`をsystemdユーザーサービスとして有効化・起動

4. 入力メソッドの切り替え、`input`グループ、GNOME Shell拡張を反映するため、一度ログアウト→ログインする。その後、初回のみ次を実行して拡張を有効化する:

   ```
   gnome-extensions enable xremap@k0kubun.com
   ```

## Neovim（手動・ソースビルド）

`install.sh`には含めず、必要なときにその場で手動ビルドする方針（クリーンインストール毎の自動ビルドはコストが高いため）。stableブランチをビルドする手順:

```
sudo apt update && sudo apt install -y ninja-build gettext cmake unzip curl build-essential
git clone https://github.com/neovim/neovim.git ~/src/neovim
cd ~/src/neovim
git checkout stable
make CMAKE_BUILD_TYPE=RelWithDebInfo
sudo make install
```

更新したい場合は`~/src/neovim`で`git pull`してから`make`し直す。

## 管理しているファイル

- `bashrc.local` — `.bashrc`本体はデフォルトのまま維持し、これだけを追加でsourceする（diffだけをgit管理）。`LC_MESSAGES`/`LC_TIME`を`en_US.UTF-8`にし、タイムゾーン・`LANG`は`ja_JP.UTF-8`のまま、コマンド出力やdateの表示を英語化している
- `.gitconfig` — `user.name` / `user.email` などのGit設定
- `.config/fcitx5/config` — fcitx5の設定。右Alt(`Alt_R`)でIMEオン、左Alt(`Alt_L`)でIMEオフになるように`ActivateKeys`/`DeactivateKeys`を追加している
- `.config/xremap/config.yml` — xremap(Karabiner相当のシステム全体キーリマッパー)の設定。[公式のemacs.yml例](https://github.com/xremap/xremap/blob/master/example/emacs.yml)をベースに、**右Ctrl(`C_R`)・右Alt(`M_R`)のみ**でEmacsバインドを発動し、左Ctrl・左Altは標準動作のまま通過させる
  - カーソル移動・マーク(C_R-a/e/f/b/n/p/d/h/v/space, M_R-b/f/v, M_R-Shift-,/.): ターミナル(`org.gnome.Ptyxis`)とEmacs自体を除く全アプリで有効。`C_R-v`は標準の貼り付け、`C_R-space`はfcitx5の予備トリガー/エディタの自動補完と衝突するが右Ctrl限定なので影響は小さい
  - カット・コピー・ヤンク・単語削除(C_R-w/y/k, M_R-w/d, M_R-BackSpace)・C_R-xプレフィックス(h/C_R-f/C_R-s/k/C_R-c/u): 上記に加えVS Code(`code`)も除外（Ctrl+Kチェインコマンド等と衝突するため）。`C_R-y`は標準のRedo、`C_R-x`プレフィックスは右Ctrl+Xでのカットと衝突するが、いずれも右Ctrl限定。右AltはfcitxのIMEオン(`Alt_R`単体)と共存（単体押しと組み合わせ押しは別判定のため衝突しない）
  - `C-s`/`C-r`/`C-o`/`C-slash`/`C-g`単体は保存・検索・リロード等の標準動作を壊すため意図的に追加していない
- `.config/systemd/user/xremap.service` — xremapをsystemdユーザーサービスとして自動起動するunit
- `install.sh` — 上記のセットアップを行うスクリプト
