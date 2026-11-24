# 06 Remote SSH の画像・テキスト貼り付け（任意）

Windows 利用者PCの VS Code / Codex CLI 向け。Ctrl+Shift+V でテキストは通常貼り付け、画像は SCP で本人専用領域へ転送しパスを貼り付ける。画像そのもののクリップボード転送ではない。Claude Code でもパスを使えるが個別検証する。

## STEP 1 前提確認

LOCAL / Windows PowerShell 5.1。01 の SSH 接続を完了し、本人の SSH alias と Linux ユーザー名を確認。鍵認証と ssh-agent による非対話接続が必要。SSH ホスト鍵は事前に照合する。

~~~powershell
ssh -o BatchMode=yes festal-ubuntu whoami
winget install --id AutoHotkey.AutoHotkey -e
~~~

## STEP 2 インストール

LOCAL / リポジトリルート。スクリプトを読んでから実行。Linux ユーザー名は管理者割当値を入力。既存設定がある場合は上書きせず停止する。

~~~powershell
$LinuxUser = Read-Host "Assigned Linux username"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Install-FestalClipboard.ps1 -SshAlias festal-ubuntu -LinuxUser $LinuxUser -EnableStartup
~~~

EnableStartup は任意。実行ポリシー変更は当該プロセスのみ。本人の ~/FestalTools とサーバーの ~/.codex-images (700) を使用する。AutoHotkey v2 が起動し、タスクトレイに H が表示されることを確認。

## STEP 3 テスト

1. VS Code Remote SSH の本人の Codex 入力欄でテキストを Ctrl+Shift+V で貼り付ける。
2. Win+Shift+S で機密性のない画像を撮り、同じ入力欄で Ctrl+Shift+V。画像パスが貼り付くことを確認。
3. Codex に画像ファイルを開いて説明するよう指示し、認識を確認。
4. Windows 再ログイン後の起動を確認（EnableStartup 指定時）。

元の実装は既存利用者でテキスト・画像認識まで確認済み。ここに掲載する汎用インストーラーと他利用者での動作は未検証。

## 注意

ショートカットは Code.exe 全体に作用する。ローカル VS Code や別サーバーのウィンドウでも画像が設定先に転送されるため、指定 Festal 接続の入力欄でのみ使用する。不要時はタスクトレイから終了する。画像に機密情報がないことを確認。転送画像はサーバーに残るため、不要になった本人の画像は確認して個別削除する。Ctrl+V は変更しない。

## 障害対応

画像をコピーした状態で LOCAL PowerShell から次を実行し、パスと終了コードを確認。

~~~powershell
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "$HOME\FestalTools\Paste-FestalImage.ps1"
$LASTEXITCODE
~~~

0 は転送成功、1 はエラー、2 は画像なし。SSH 疎通、鍵認証、本人の保存先権限を確認。既存スクリプトを無断で上書きしない。停止する場合は H アイコンから Exit、ログイン時の起動を止める場合は本人の Startup 内 FestalClipboard.lnk のみ削除する。
