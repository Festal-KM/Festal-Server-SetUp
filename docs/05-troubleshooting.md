# 05 トラブルシューティング・運用

## 接続エラーの切り分け

LOCAL / PowerShell:
~~~powershell
tailscale status
$Server = Read-Host "割当接続先"
tailscale ping $Server
Test-NetConnection -ComputerName $Server -Port 22
ssh -v festal-ubuntu
~~~
- port 22 timeout: Tailscale / Windows 側を確認。再起動直後は数分待って再試行。
- Connection closed by UNKNOWN port 65535: ProxyJump の先を含む接続失敗。Windows SSH と WSL SSH を分けて確認。
- Permission denied (publickey): 割当ユーザー、IdentityFile、公開鍵登録、ACL を確認。秘密鍵を表示しない。
- Host key changed: 停止し管理者に指紋確認。known_hosts を無条件に削除しない。

LOCAL から ssh festal-windows。WINDOWS / CMD:
~~~cmd
whoami
wsl --list --verbose
netstat -ano
~~~
WSL の起動を伴う診断は無人起動試験とは区別する。PowerShell コマンドは powershell を起動してから実行。本人の WSL で systemctl is-active ssh、systemctl status ssh.socket --no-pager、ss -ltn を確認。管理者に割当ポートと照合を依頼する。

## 開発ツール

- pnpm not found: nvm current、nvm ls、npm list -g --depth=0 を確認。該当 Node バージョンに必要な pnpm を導入する。
- Docker 接続失敗: docker context show、systemctl --user status docker、loginctl show-user "$USER" -p Linger を確認。rootful daemon へ切り替えない。
- ポート競合: ss -ltn と本人の docker ps を確認し、管理者の割当台帳に従って変更。他人のプロセスを kill しない。
- VS Code 接続失敗: 先に CLI SSH を確認。Remote SSH の出力ログを確認し、他ユーザーの VS Code Server を削除しない。
- Codex 履歴が見えない: CODEX_HOME と codex resume --all を確認。Windows 旧パスは -C で指定し直す。

## 共有運用

本人の作業領域だけを変更する。重い並列ビルド、長時間ジョブ、ディスク消費は他利用者と調整。Docker の全体 prune、WSL shutdown、OS 更新・再起動、ファイアウォール変更は管理者の承認なしに行わない。開発サーバーは localhost bind を基本とし、外部公開は別途承認。バックアップと秘密情報を公開リポジトリに入れない。

障害報告には発生日時、STEP、実行場所、エラー、試した読み取り診断、影響範囲を記載。秘密情報は伏せる。
