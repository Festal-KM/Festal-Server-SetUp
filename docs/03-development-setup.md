# 03 開発環境セットアップ

すべて WSL / 本人 Bash。VS Code Remote SSH 接続済みで whoami が本人であることを確認する。

## STEP 03-1 基本ツール・作業領域

~~~bash
umask 077
mkdir -p "$HOME/dev" "$HOME/migration"
chmod 700 "$HOME/dev" "$HOME/migration"
command -v git gh curl rsync 7z
~~~
不足する OS パッケージは管理者承認後に apt で導入（git gh curl rsync p7zip-full 等、利用可能なパッケージ名を確認）。他人のホームや /mnt/c に開発プロジェクトを置かない。

## STEP 03-2 Node.js / pnpm

NVM が存在するか command -v nvm で確認。なければ公式 https://github.com/nvm-sh/nvm のリリースとインストール手順を確認し、本人のホームに導入。取得スクリプトを確認してから実行し、シェルを再読込する。

~~~bash
nvm install 22
nvm use 22
npm install -g pnpm@9.15.0
nvm install 24
nvm use 24
npm install -g pnpm@10.12.1
nvm alias default 24
node -v
pnpm -v
~~~
新規利用者の推奨例。既存環境の default は変更しない。プロジェクトの .nvmrc、engines、packageManager を優先し、必要な Node バージョンに切り替える。グローバル npm パッケージは NVM バージョンごとに分離される。

## STEP 03-3 GitHub

~~~bash
gh auth login
gh auth setup-git
gh auth status
~~~
本人がブラウザ認証を行い、本人の GitHub アカウントを確認。トークンを表示しない。Git の user.name / user.email は本人の値を設定する。既存値は確認してから変更。

対象リポジトリのアクセス権を確認し、本人の ~/dev へ clone。既存ディレクトリは上書きしない。git ls-remote origin HEAD で読み取り疎通を確認。push は明示承認時のみ。

## STEP 03-4 Rootless Docker

既存 Docker を確認:
~~~bash
docker context show
docker info --format '{{json .SecurityOptions}}'
systemctl --user is-active docker
loginctl show-user "$USER" -p Linger
~~~
rootless が確認できなければ管理者と調整。公式 https://docs.docker.com/engine/security/rootless/ に従い、Ubuntu 24.04 用 Docker Engine パッケージ、uidmap、本人専用の重複しない subuid/subgid、rootless extras を準備する。既存 daemon を停止しない。本人 Bash で dockerd-rootless-setuptool.sh install を実行し、本人の rootless context を使用。管理者承認後に loginctl enable-linger を本人に対して設定する。

~~~bash
systemctl --user enable --now docker
docker info --format '{{json .SecurityOptions}}'
docker compose version
docker ps
~~~
成功条件: rootless 表示、本人の daemon active、Compose 利用可。docker グループや共有 rootful socket を代替に使わない。開発ポートは割当範囲内で 127.0.0.1 に bind。VS Code Ports で必要なものだけ転送する。Compose 起動前にポート・volume・外部接続・リソース消費を確認する。

## STEP 03-5 Codex / Claude Code

本人 Bash。既存 CLI の有無を command -v codex; command -v claude で確認。Codex は利用する NVM バージョンごとに必要なら npm install -g @openai/codex を実行。Claude Code は公式 https://code.claude.com/docs/ の Linux インストール手順を確認して本人のホームに導入。インストール済みなら不要な更新はしない。

~~~bash
codex --version
claude --version
~~~
本人が codex login / claude の対話ログインを行う。別人の auth.json や API キーをコピーしない。複数の本人所有 Codex アカウントを使う場合のみ CODEX_HOME を別ディレクトリに指定し、各ディレクトリを chmod 700 で保護する。各アカウントで codex login status を確認。

## STEP 03-6 完了確認

本人の SSH / VS Code 接続、Node/pnpm、GitHub 認証、rootless Docker、使用する AI CLI のバージョン・認証を確認。プロジェクト固有の依存導入・環境変数・DB 初期化は各リポジトリの指示に従う。外部連携や本番データ操作は自動実行しない。
