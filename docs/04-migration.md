# 04 任意: 既存開発環境の移行

新規 clone で足りる場合はスキップ。移行元は削除しない。移行中の変更を避けるため本人の作業を停止・調整する。

## STEP 04-1 棚卸し

移行元で git status --short、git branch --show-current、git rev-parse HEAD、git worktree list、git remote -v を確認（URL に認証情報があれば伏せる）。各 worktree の staged / unstaged / untracked を別々に記録。ignored ファイルは必要性を個別判断。DB・volume・認証情報は自動移行しない。

## STEP 04-2 バックアップ

git bundle create PROJECT.bundle --all と git bundle verify PROJECT.bundle を使用。detached HEAD が bundle に含まれるか別途確認し、必要なら本人承認のもと一時 ref を作成。bundle は未コミット変更を含まない。各 worktree の git diff --binary と git diff --cached --binary を別ファイルに保存する（Windows PowerShell 5.1 のリダイレクトは文字コード変換に注意し、Git の --output オプションを使う）。untracked は git ls-files --others --exclude-standard で棚卸しし、必要ファイルをアーカイブ。node_modules 等の再生成可能な依存は除外。秘密情報は別途承認し安全な経路で扱う。

## STEP 04-3 転送・復元

LOCAL から scp を利用して本人の ~/migration に転送。Windows Get-FileHash -Algorithm SHA256 と WSL sha256sum を比較。7z 等は展開前にテストする。本人の ~/dev の新規パスへ clone / 展開し、既存ファイルを上書きしない。worktree を元の branch / commit で再作成し、staged patch を git apply --cached、該当ファイルを index から worktree に復元してから unstaged patch を git apply。untracked を復元。CRLF 差異は Git 設定と patch 内容で確認し、一括変換しない。

## STEP 04-4 Codex 履歴（任意）

本人の各 CODEX_HOME/sessions を別々にバックアップ。圧縮形式を含む全ファイルを数え、ハッシュを確認。既存リモートセッションと衝突しないもののみ rsync --ignore-existing 等でコピー。本人以外の履歴、auth.json、トークン、他の認証 DB は移行しない。履歴自体に秘密情報が含まれる可能性があるため本人専用の権限で保護する。ディレクトリ 700、ファイル 600 を維持。codex resume --all で表示を確認し、必要に応じて -C で新しい作業パスを指定する。CLI の対応形式は codex resume --help で確認。Claude Code の履歴移行は別途公式仕様を確認する。

## STEP 04-5 検証

branch / HEAD、staged・unstaged の差分、untracked の件数・SHA256、全 worktree、履歴件数を移行元と比較。GitHub origin を確認し読み取り疎通を検証。差異は理由を記録し、未確認項目を残す。移行元・バックアップの削除は別途承認が必要。
