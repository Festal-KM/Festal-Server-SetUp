# 01 利用者PCのセットアップ

対象: Windows 11 / ローカル PowerShell。Mac/Linux は管理者と接続方法を確認する。

## STEP 01-1 割当情報の確認

管理者から README 記載の情報を受け取る。自分の Windows / Linux アカウントが作成済みであること。未作成なら 02 を管理者に依頼する。

## STEP 01-2 ツール

LOCAL / PowerShell:
~~~powershell
Get-Command ssh, ssh-keygen, tailscale, code, git -ErrorAction SilentlyContinue
~~~
不足分のみ公式配布元または winget で導入する。例:
~~~powershell
winget install --id Tailscale.Tailscale -e
winget install --id Microsoft.VisualStudioCode -e
winget install --id Git.Git -e
~~~
OpenSSH Client がなければ管理者に Windows オプション機能の追加を依頼。新しい PowerShell で再確認する。

## STEP 01-3 Tailscale

本人が管理者の招待を承認し、Tailscale にログインする。
~~~powershell
tailscale status
$Server = Read-Host "管理者指定の接続先"
tailscale ping $Server
Test-NetConnection -ComputerName $Server -Port 22
~~~
成功条件: 指定ホストが表示され TCP 22 が True。ping のみでは SSH 成功としない。

## STEP 01-4 SSH 鍵

LOCAL / PowerShell:
~~~powershell
$Key = Join-Path $HOME ".ssh\id_ed25519_festal"
New-Item -ItemType Directory -Force (Split-Path $Key) | Out-Null
if (-not (Test-Path $Key) -and -not (Test-Path "$Key.pub")) {
    ssh-keygen -t ed25519 -f $Key -C "festal-development"
}
Get-Content "$Key.pub"
~~~
本人がパスフレーズを設定。公開鍵だけを管理者に渡す。既存鍵が片方だけなら停止。秘密鍵は端末外へ送らない。

任意: パスフレーズ入力を減らす場合、管理者承認のもと Windows ssh-agent サービスを有効化し、本人の PowerShell で ssh-add $Key を実行する。鍵を無パスフレーズに変更しない。

## STEP 01-5 SSH config

LOCAL / PowerShell: ~/.ssh/config を確認し、存在する場合はバックアップ。次のテンプレートの大文字プレースホルダーを割当値で置換して追記する。既存 Host と衝突する場合は別名を選ぶ。

~~~sshconfig
Host festal-windows
    HostName SERVER_ADDRESS
    User WINDOWS_USER
    Port 22
    IdentityFile ~/.ssh/id_ed25519_festal
    IdentitiesOnly yes

Host festal-ubuntu
    HostName 127.0.0.1
    User LINUX_USER
    Port ASSIGNED_SSH_PORT
    ProxyJump festal-windows
    IdentityFile ~/.ssh/id_ed25519_festal
    IdentitiesOnly yes
    ServerAliveInterval 30
    ServerAliveCountMax 3
~~~

## STEP 01-6 接続検証

~~~powershell
ssh -G festal-ubuntu
ssh festal-windows
~~~
初回は管理者から受け取った Windows ホスト鍵指紋を照合する。接続先が CMD なら whoami を実行し、自分の Windows ユーザーであることを確認して exit。

LOCAL:
~~~powershell
ssh festal-ubuntu
~~~
Linux ホスト鍵指紋も照合する。WSL / Bash:
~~~bash
whoami
hostname
pwd
cat /etc/os-release
~~~
成功条件: 割当 Linux ユーザー、Ubuntu 24.04、自分のホーム。違うユーザーなら直ちに exit。

## STEP 01-7 VS Code

LOCAL:
~~~powershell
code --install-extension ms-vscode-remote.remote-ssh
~~~
VS Code のコマンドパレットから Remote-SSH: Connect to Host... → festal-ubuntu → Linux（聞かれた場合）。接続後、自分のホーム内の dev フォルダを開く（03 で作成）。統合ターミナルで whoami と pwd を再確認する。
