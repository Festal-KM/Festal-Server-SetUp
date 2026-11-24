# 02 管理者向け: 新規利用者のプロビジョニング

既設 Windows 11 Pro / Tailscale / OpenSSH / WSL2 を前提とする。既存利用者への影響を避ける。新規利用者向け手順は個別検証が必要。

## STEP 02-1 割当

管理者は非公開台帳に Windows 標準ユーザー、Linux ユーザー、WSL 名、SSH ポート、開発用ポート範囲、Tailscale アクセス権を記録。Windows 管理者アカウントを共有しない。利用者の公開鍵を受領する。既存ポートと競合しないことを Windows の Get-NetTCPConnection および既存割当台帳で確認。

## STEP 02-2 Windows 側

WINDOWS / 管理者 PowerShell: Get-Service sshd と Get-NetTCPConnection -LocalPort 22 -State Listen を確認。既存の Tailscale / SSH / firewall 設定を維持する。Tailscale のアクセス制御は必要な利用者に限定する。

新規標準ユーザーを Windows のアカウント管理で作成し、初回ログイン方法を安全に渡す。本人の Windows プロファイル内の .ssh/authorized_keys に公開鍵を追記し、OpenSSH の要件に沿った所有者・ACL（本人、SYSTEM、必要な管理者のみ）を確認。既存鍵を消さない。管理者用 administrators_authorized_keys を流用しない。

## STEP 02-3 WSL

WINDOWS / 新規利用者本人の PowerShell:
~~~powershell
wsl --list --verbose
~~~
本人のアカウントで Ubuntu-24.04 が未登録の場合のみ、管理者と調整して wsl --install -d Ubuntu-24.04 を実行。必要な再起動は全利用者と調整。既存ディストリビューションを unregister しない。初回起動時に本人の Linux ユーザーを作成する。

WSL / 本人 Bash: systemd が有効か ps -p 1 -o comm= で確認。必要なら本人の /etc/wsl.conf の既存設定を保ち [boot] systemd=true を設定し、本人のディストリビューションだけを停止・再起動する（承認必須）。wsl --shutdown は共有ホストで安易に実行しない。

## STEP 02-4 Linux SSH

WSL / 本人 Bash（管理者承認の sudo）:
~~~bash
sudo apt update
sudo apt install openssh-server
umask 077
mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
~~~
本人の公開鍵を authorized_keys に重複なく追記する。割当ポートを /etc/ssh/sshd_config.d/ の専用設定に記載する（Port ASSIGNED_SSH_PORT、PubkeyAuthentication yes、PermitRootLogin no）。既存設定、ssh.socket の有無、実効ポートを確認する。Ubuntu 24.04 の socket activation によりポート変更時は daemon-reload と socket の再起動が必要な場合がある。設定検証 sudo sshd -t が成功してから適切な unit を起動する。鍵接続成功後にパスワード認証を無効化し、実効設定を sudo sshd -T で確認。Windows のループバックから割当ポートに到達できることを確認し、外部 LAN へポートを公開しない。

~~~bash
systemctl status ssh.service ssh.socket --no-pager
ss -ltn
ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
~~~
Windows 側のホスト鍵指紋も管理者が取得し、本人に安全な経路で渡す。ProxyJump に必要な TCP forwarding は既存ポリシーを確認し、必要最小限の接続先に限定する。

## STEP 02-5 無人起動

管理者が Tailscale の無人実行設定、Windows sshd の自動起動、本人の Windows アカウントで WSL を起動・維持する起動時タスクを確認・構成する。タスクは本人のディストリビューションを対象にし、対話ログオンなしで実行できる方式を管理者が検証する。資格情報をスクリプトに埋め込まない。例として本人のタスクで wsl.exe -d Ubuntu-24.04 --exec /bin/sleep infinity を起動し、停止時の再実行・時間制限・重複実行設定を調整する。既存タスクを上書きしない。

承認済みメンテナンス時間に再起動し、数分待って利用者PCから Windows に事前ログインせず ssh festal-ubuntu を検証する。失敗時は 05 を参照。利用者の追加だけでホスト再起動を強制しない。

## STEP 02-6 引渡し

本人に README の割当情報を渡す。別ユーザーのホームや Docker へアクセスできないこと、ポート競合がないことを確認。WSL は強固なマルチテナント隔離ではないため、信頼できる社内利用者のみを対象とし、厳格な隔離が必要な場合は別 VM 等を検討する。
