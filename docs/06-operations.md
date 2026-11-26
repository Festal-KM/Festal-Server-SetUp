# 06 管理者向け運用マニュアル

Windows ホスト上の共有 WSL2 / Ubuntu 24.04 開発環境を対象とする。新規利用者の追加は [管理者手順](02-server-setup.md)、接続できない利用者の初動は [トラブルシューティング](05-troubleshooting.md) を参照する。

`<WSL_OWNER>`、`<DISTRO>`、`<LINUX_UID>`、`<SSH_PORT>`、`<TENANT_ID>`、`<APP_ID>`、`<CERT_THUMBPRINT>`、`<SENDER_MAILBOX>`、`<RECIPIENT_MAILBOX>` は非公開の運用台帳で照合する。監視の閾値、通知間隔、タスクの実行条件は稼働中の設定を確認する。アカウント、接続先、証明書識別情報、鍵、トークン、実ログや状態ファイルは公開リポジトリに掲載しない。

## STEP 06-1 メモリ枯渇の予防

WSL のメモリ逼迫に伴う SSH 接続障害への対策として、WSL のメモリとスワップを拡張し、WSLg を無効化した。Docker コンテナと Linux ユーザー単位にも上限を設定した。負荷元を調べる際は、Windows の空きメモリ、Ubuntu の空きメモリとスワップ、OOM ログ、各コンテナの使用量を時刻で照合する。

**WINDOWS / WSL 所有者の PowerShell**。既存の `%USERPROFILE%\.wslconfig` をバックアップし、既存設定を維持して `[wsl2]` の `memory`、`swap`、`guiApplications=false` を管理者と確認する。Windows と他の利用者に必要な余裕を確保し、スワップ用ディスクの空きも確認する。適用に WSL VM の停止が必要な場合は共有作業を調整してから実施する。適用後は対象 Ubuntu の `free -h` と `swapon --show` で確認する。[Microsoft の WSL 設定](https://learn.microsoft.com/en-us/windows/wsl/wsl-config)

**WSL / 本人の Bash**。対象プロジェクトの Compose でサービスごとのメモリ上限を設定し、変更対象だけを調整済みの時間に反映する。`docker inspect --format '{{.HostConfig.Memory}}' <CONTAINER>` の値が割当どおりか、`docker stats --no-stream` で使用量と上限を確認する。Rootless Docker の実効制限は cgroup の設定にも依存する。

**WSL / 管理者承認済みの Bash**。systemd 管理下の対象ユーザーについて、`systemctl show user-<LINUX_UID>.slice -p MemoryHigh -p MemoryMax -p MemorySwapMax` で実効値を確認する。変更時は対象ユーザーの slice の永続設定をバックアップし、承認済みの上限を適用する。低すぎる上限は SSH やビルドにも影響するため、適用後は本人の接続と作業を確認する。

## STEP 06-2 監視の構成と点検

| 場所 | 役割 | 正常時の確認 |
| --- | --- | --- |
| Windows の WSL 自動起動タスク | WSL 所有者で対象ディストリビューションを起動・維持。タスク失敗時の再試行を設定 | 維持プロセスが稼働し、割当 SSH ポートが応答する |
| `Festal-WSL-HealthMonitor` / `Watch-FestalWSL.ps1` | Windows の空きメモリ・使用率、WSL メモリ、起動タスクと SSH バナーを確認 | `Logs\health-YYYY-MM-DD.log` が更新され、`SSH_STATUS=OK` |
| Ubuntu 定期監視 | Ubuntu 側の状態を Windows が読める `FestalHealthBridge/ubuntu-health.txt` に出力 | 更新が継続し、監視対象の状態が記録される |
| `Festal-Health-Notification` / `Notify-FestalHealth.ps1` | Windows と Ubuntu の結果を集約し、SYSTEM で 5 分ごとに通知判定 | 実行結果 `0`、`CHECK_COMPLETED`、状態ファイルの更新 |

**WINDOWS / 管理者 PowerShell**。監視ファイルの配置先は `C:\ProgramData\FestalMonitor`。再構築時は管理者が保管する承認済みスクリプトとタスク定義を使う。自動起動タスクの実行ユーザー、起動対象、失敗時の再試行設定を照合する。Windows 監視は当該自動起動タスクと割当 SSH ポートを参照し、通知タスクは Windows ログと WSL 所有者のプロファイル内にある Ubuntu の出力を参照する。SYSTEM の読み取り権限と、監視スクリプト・ログ・状態ファイルへの書き込み権限を確認する。

~~~powershell
$base = Join-Path $env:ProgramData 'FestalMonitor'
$day = Get-Date -Format 'yyyy-MM-dd'
Get-ScheduledTask -TaskName 'Festal-*' | Select-Object TaskName, State
Get-ScheduledTaskInfo -TaskName 'Festal-Health-Notification' |
    Select-Object LastRunTime, LastTaskResult, NextRunTime
Get-Content (Join-Path $base "Logs\health-$day.log") -Tail 20
Get-Content (Join-Path $base "Logs\notification-$day.log") -Tail 20
Get-Content (Join-Path $base 'notification-state.json')
~~~

**WSL / 対象環境の所有者または管理者の Bash**。既存の Ubuntu 監視ジョブの実行ユーザー、周期と出力先を非公開台帳に沿って復元する。Windows 側で出力ファイルの更新時刻と報告内容を照合し、ファイルの欠落や更新停止があればジョブ、マウント、権限を調べる。通知タスクの正常終了は、通知不要の回にも記録される。

## STEP 06-3 Microsoft 365 メール通知

**Microsoft Entra / Exchange Online 管理者と WINDOWS 管理者**。Microsoft Graph のアプリ専用認証には、Entra アプリに登録した公開証明書と、Windows 側の対応する秘密鍵を使う。アプリ登録、テナント、送信権限と送信元メールボックスの許可範囲を確認する。Entra の Microsoft Graph アプリケーション権限で送信を許可する構成では、`Mail.Send` と管理者同意を確認し、送信可能なメールボックスの範囲も確認する。タスクの SYSTEM が証明書ストアから証明書を参照でき、秘密鍵を使用できることを確認する。`Send-FestalAlert.ps1` の接続設定、送信元と宛先は運用台帳と照合する。[Graph PowerShell の証明書認証](https://learn.microsoft.com/powershell/microsoftgraph/authentication-commands)・[Graph の sendMail](https://learn.microsoft.com/graph/api/user-sendmail)

通知タスクは判定を `notification-state.json` に保持する。新規障害や状態の変化、障害継続時の再通知、正常化時の復旧通知を扱う。同じ状態で再通知間隔に達していない場合は送信を抑制する。閾値と再通知間隔は稼働中のスクリプトを確認する。調査時は `Level`、`Key`、`LastChecked`、`LastSent` を通知ログおよび受信時刻と照合する。状態ファイルを初期化すると通知判定に影響するため、調査中は保全する。ホストの電源断や通信断の間は、このホスト上の仕組みだけでは送信できない。

### 証明書の更新

1. 有効期限前に新しい証明書を用意し、Entra アプリに公開証明書を追加する。旧証明書は切り戻し用に残す。
2. WINDOWS / 管理者が新しい証明書と秘密鍵を実行環境の証明書ストアに配置し、SYSTEM の秘密鍵アクセスを確認する。送信スクリプトをバックアップして参照先を更新する。
3. 承認済みのテスト宛先で SYSTEM による送信と受信を確認し、本番タスクの次回実行ログを確認する。失敗時は旧参照に戻し、期限、アプリ登録、鍵権限、メールボックスの許可範囲を調べる。
4. 切替確認後に旧証明書を運用手順に従って撤去し、期限と更新履歴を非公開台帳に記録する。

## STEP 06-4 障害時の切り分けと復旧

1. **LOCAL / 利用者**。発生時刻と影響範囲を管理者に連絡し、[接続エラーの切り分け](05-troubleshooting.md#接続エラーの切り分け)に従って Windows SSH と Ubuntu SSH を順に確認する。
2. **WINDOWS / 管理者**。ホストの空きメモリ、`Get-Service sshd`、WSL 自動起動タスク、Windows 監視ログを確認する。`Test-NetConnection -ComputerName localhost -Port <SSH_PORT>` は割当ポートに置き換える。TCP 到達性と Windows 監視の SSH バナーを照合する。WSL の登録・状態は所有者の PowerShell で `wsl --list --verbose` を確認する。
3. **WSL / 対象環境の所有者または管理者**。アクセスできる場合は下記の診断で、メモリ逼迫、OOM、SSH、Docker の状態を確認する。カーネルログの取得に権限が必要なら管理者が実施する。負荷元の所有者と調整して対象ジョブやコンテナだけを停止・縮小する。
4. **WINDOWS / 管理者と WSL 所有者**。対象 WSL が停止していれば起動タスクの結果と再試行設定を確認し、必要に応じてタスクを起動する。既に稼働中で応答しない場合は、作業とデータへの影響を確認し、承認済みの時間に対象ディストリビューションの停止・起動を検討する。共有ホスト全体の `wsl --shutdown`、OS 再起動、Docker の全体 prune は影響調整と管理者承認が必要。ハングを検出して WSL を強制再起動する構成は導入していない。
5. **LOCAL / 利用者、WINDOWS / 管理者**。利用者 PC からの SSH 接続、対象の開発サービス、Windows と Ubuntu の監視更新、通知タスクの次回実行を確認する。障害通知が出ていた場合は復旧通知の受信も照合する。発生・復旧時刻、影響、診断結果、実施した変更を非公開で記録する。

~~~bash
free -h
swapon --show
ps -eo pid,user,comm,rss --sort=-rss | head -20
journalctl -k --since '-1 hour' --no-pager | grep -Ei 'out of memory|oom-kill|killed process'
systemctl status ssh.service ssh.socket --no-pager
ss -ltn
docker stats --no-stream
~~~

## 検証状況（2026-11-26）

| 状況 | 確認項目 |
| --- | --- |
| 確認済み | SSH 接続の復旧。Windows 側で WSL 起動タスクの稼働と SSH バナーの応答を確認 |
| 確認済み | SYSTEM でのメール送信テストと、模擬入力による通知判定 15 パターン |
| 確認済み | 正常時の本番通知タスクの手動起動と 5 分間隔の定期実行。終了コード `0`、`CHECK_COMPLETED` と通知状態の更新を確認 |
| 確認済み | 一時テストタスク・スクリプト・模擬データの削除。本番タスクは残存 |
| 未実施 | 実障害の検知から初回通知・継続通知・復旧通知の受信までの一貫検証 |
| 未実施 | ホスト再起動後の設定維持と監視・通知の無人復帰の一貫検証 |
| 未実施 | 実障害で WSL 自動起動タスクの再試行が発動し復旧することの検証 |

未実施項目を検証するときは、合意済みの保守時間を確保し、監視ログ・タスク履歴・受信結果を突き合わせる。
