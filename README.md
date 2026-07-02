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
   - WezTermの公式APTリポジトリ(apt.fury.io)を追加
   - 未インストールのパッケージ（`git`, `curl`, `unzip`, `fcitx5`, `fcitx5-mozc`, `fcitx5-config-qt`, `wezterm-nightly`, `rofi`）を`apt install`（`wezterm`安定版は2024年2月のビルドで止まっており、GNOME WaylandでBroken pipeクラッシュするため`wezterm-nightly`を使用）
   - 入力メソッドフレームワークを`im-config`で`fcitx5`に切り替え
   - `~/.bashrc`の末尾に`bashrc.local`を読み込む設定を追加
   - `~/.gitconfig`を`.gitconfig`へのシンボリックリンクに置き換え
   - `~/.config/fcitx5/config`を`.config/fcitx5/config`へのシンボリックリンクに置き換え、`fcitx5-remote -r`でリロード
   - `~/.config/autostart/org.fcitx.Fcitx5.desktop`を配置（GNOMEではfcitx5がデフォルトで自動起動エントリを持たないため、これが無いとログインしてもfcitx5が起動しない）
   - `xremap`バイナリを`~/.local/bin/xremap`にダウンロード
   - ユーザーを`input`グループに追加し、`/dev/uinput`用のudevルールを追加（`xremap`が`/dev/input`を読むのに必要）
   - `xremap`のGNOME Shell拡張(`xremap@k0kubun.com`)をclone（フォーカス中のアプリ名を取得するために必要。**有効化は手動**: ログイン後に`gnome-extensions enable xremap@k0kubun.com`を実行）
   - `~/.config/xremap/config.yml`をシンボリックリンクに置き換え、`xremap.service`をsystemdユーザーサービスとして有効化・起動
   - [herdr](https://herdr.dev/)を公式インストールスクリプトで`~/.local/bin/herdr`にインストール
   - `~/.config/herdr/config.toml`を`.config/herdr/config.toml`へのシンボリックリンクに置き換え
   - [oh-my-posh](https://ohmyposh.dev/)バイナリを`~/.local/bin/oh-my-posh`にダウンロード（bashプロンプトに使用、`bashrc.local`で読み込み）
   - `~/.config/oh-my-posh/catppuccin-mocha.omp.json`を`.config/oh-my-posh/catppuccin-mocha.omp.json`へのシンボリックリンクに置き換え
   - `~/.config/rofi/config.rasi`・`~/.config/rofi/themes/alfred-catppuccin-mocha.rasi`をそれぞれシンボリックリンクに置き換え
   - GNOMEのカスタムショートカット(`Super+R`)で`rofi -show drun -normal-window`を起動するよう`gsettings`で設定（`-normal-window`が無いとMutter/XWayland環境でESC・文字入力が効かない）
   - `~/.config/fcitx5/resume-restart.sh`・`~/.config/systemd/user/fcitx5-resume-restart.service`をシンボリックリンクに置き換え、`fcitx5-resume-restart.service`をsystemdユーザーサービスとして有効化・起動
   - `Toggler`のGNOME Shell拡張(`toggler@hedgie.tech`)をclone・schemaをコンパイルし、`Ctrl+Alt+I`でWezTermをフォーカス/最小化トグルするよう`gsettings`で設定（**有効化は手動**: ログイン後に`gnome-extensions enable toggler@hedgie.tech`を実行）

4. 入力メソッドの切り替え、`input`グループ、GNOME Shell拡張を反映するため、一度ログアウト→ログインする。その後、初回のみ次を実行して拡張を有効化する:

   ```
   gnome-extensions enable xremap@k0kubun.com
   gnome-extensions enable toggler@hedgie.tech
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

- `bashrc.local` — `.bashrc`本体はデフォルトのまま維持し、これだけを追加でsourceする（diffだけをgit管理）。`LC_MESSAGES`/`LC_TIME`を`en_US.UTF-8`にし、タイムゾーン・`LANG`は`ja_JP.UTF-8`のまま、コマンド出力やdateの表示を英語化している。エイリアス`h=herdr`/`g=git`、`oh-my-posh`によるpowerline風プロンプトの設定も含む（Nerd Font前提）
- `.gitconfig` — `user.name` / `user.email` などのGit設定
- `.config/fcitx5/config` — fcitx5の設定。右Alt(`Alt_R`)でIMEオン、左Alt(`Alt_L`)でIMEオフになるように`ActivateKeys`/`DeactivateKeys`を追加している
- `.config/fcitx5/resume-restart.sh` / `.config/systemd/user/fcitx5-resume-restart.service` — スリープ復帰後にfcitx5を自動で`fcitx5 -r`再起動するsystemdユーザーサービス。fcitx5のAlt単体トリガーはXWayland経由のX11キーグラブに依存しており、スリープ復帰後にこのグラブだけが失効し、トリガーキーが反応しなくなる既知の不具合がある（これまでは手動でトレイメニューから再起動していた）。`systemd-logind`の`PrepareForSleep`信号(`gdbus monitor`で監視)を使って復帰を検出している
- `.config/xremap/config.yml` — xremap(Karabiner相当のシステム全体キーリマッパー)の設定。[公式のemacs.yml例](https://github.com/xremap/xremap/blob/master/example/emacs.yml)をベースに、**右Ctrl(`C_R`)・左Alt(`M_L`)のみ**でEmacsバインドを発動し、左Ctrl・右Altは標準動作のまま通過させる（右Altはfcitx5のIMEオン用キーとして使うため、あえて標準Altのまま）
  - `modmap`でCapsLockを右Ctrl(`Control_R`)に変換（CapsLockのオン/オフ機能は無効化され、右Ctrlとして動作。Emacsバインドも発動する）
  - カーソル移動・マーク(C_R-a/e/f/b/n/p/d/h/v/space, M_L-b/f/v, M_L-Shift-,/.): ターミナル(`org.gnome.Ptyxis`)・WezTerm(`org.wezfurlong.wezterm`)とEmacs自体を除く全アプリで有効。`C_R-v`は標準の貼り付け、`C_R-space`はfcitx5の予備トリガー/エディタの自動補完と衝突するが右Ctrl限定なので影響は小さい。WezTermを除外しているのはherdrのペイン移動(Alt+h/j/k/l)等、左Alt系のターミナル内ショートカットと衝突させないため
  - カット・コピー・ヤンク・単語削除(C_R-w/y/k, M_L-w/d, M_L-BackSpace)・C_R-xプレフィックス(h/C_R-f/C_R-s/k/C_R-c/u): 上記に加えVS Code(`code`)も除外（Ctrl+Kチェインコマンド等と衝突するため）。`C_R-y`は標準のRedo、`C_R-x`プレフィックスは右Ctrl+Xでのカットと衝突するが、いずれも右Ctrl限定。左AltはfcitxのIMEオフ(`Alt_L`単体)と共存（単体押しと組み合わせ押しは別判定のため衝突しない）
  - `C-s`/`C-r`/`C-o`/`C-slash`/`C-g`単体は保存・検索・リロード等の標準動作を壊すため意図的に追加していない
- `.config/systemd/user/xremap.service` — xremapをsystemdユーザーサービスとして自動起動するunit
- `.config/wezterm/wezterm.lua` — WezTermの設定。カラースキームを`Catppuccin Mocha`、フォントをJetBrainsMono Nerd Font Monoに指定
- `.config/herdr/config.toml` — herdrの設定。ペイン移動(`focus_pane_left/down/up/right`)をAlt+h/j/k/lに直接バインド（vimの方向キーと同じ並び）
- `.config/oh-my-posh/catppuccin-mocha.omp.json` — bashプロンプト(`oh-my-posh`)用のテーマ。[oh-my-posh公式のDraculaテーマ](https://github.com/JanDeDobbeleer/oh-my-posh/blob/main/themes/dracula.omp.json)をベースにsession/path/git/node/awsセグメントをカスタマイズした上で、配色をCatppuccin Mocha公式パレットに置き換えた自作版
- `.config/rofi/config.rasi` / `.config/rofi/themes/alfred-catppuccin-mocha.rasi` — ランチャー`rofi`の設定。中央配置・角丸・半透明のCatppuccin Mocha配色でmacOSのAlfredに寄せた自作テーマ。`Super+R`(`install.sh`がGNOMEカスタムショートカットとして設定)で`drun`モードを起動
- `Toggler`拡張 — WezTermはネイティブWaylandクライアントのため`wmctrl`等のX11ツールでは制御できない。GNOME Shell拡張[Toggler](https://github.com/hedgieinsocks/gnome-extension-toggler)を使い、`Ctrl+Alt+I`でWezTermウィンドウのフォーカス/最小化をトグル（`install.sh`が`terminal-id`をWezTerm(`org.wezfurlong.wezterm.desktop`)に設定）
- `install.sh` — 上記のセットアップを行うスクリプト
