param(
    [string]$SshAlias = "festal-ubuntu",
    [Parameter(Mandatory=$true)][string]$LinuxUser,
    [switch]$EnableStartup
)
$ErrorActionPreference = "Stop"
if ($SshAlias -notmatch '^[a-zA-Z0-9][a-zA-Z0-9._-]*$' -or $LinuxUser -notmatch '^[a-zA-Z0-9_-]+$') { throw "Invalid alias or user." }
$RemoteDir = "/home/$LinuxUser/.codex-images"
$Dir = Join-Path $HOME "FestalTools"
$Startup = [Environment]::GetFolderPath("Startup")
$Link = Join-Path $Startup "FestalClipboard.lnk"
Get-Command ssh,scp -ErrorAction Stop | Out-Null
if (-not (Test-Path "Registry::HKEY_CLASSES_ROOT\.ahk")) { throw "Install AutoHotkey v2 first." }
foreach ($Name in @("Paste-FestalImage.ps1","FestalClipboard.ahk","clipboard-config.json")) {
    if (Test-Path (Join-Path $Dir $Name)) { throw "Existing setup detected. Back up and review before updating." }
}
if ($EnableStartup -and (Test-Path $Link)) { throw "Existing startup shortcut detected." }
& ssh -o BatchMode=yes -o ConnectTimeout=10 $SshAlias "test `"$(whoami)`" = '$LinuxUser' && test `"`$HOME`" = '/home/$LinuxUser' && mkdir -p '$RemoteDir' && chmod 700 '$RemoteDir'"
if ($LASTEXITCODE -ne 0) { throw "Remote user or directory verification failed." }
New-Item -ItemType Directory -Force $Dir | Out-Null
Copy-Item (Join-Path $PSScriptRoot "Paste-FestalImage.ps1") $Dir
Copy-Item (Join-Path $PSScriptRoot "FestalClipboard.ahk") $Dir
@{SshAlias=$SshAlias;RemoteDir=$RemoteDir} | ConvertTo-Json | Set-Content (Join-Path $Dir "clipboard-config.json") -Encoding UTF8
$Script = Join-Path $Dir "FestalClipboard.ahk"
if ($EnableStartup) {
    $Shell = New-Object -ComObject WScript.Shell
    $Shortcut = $Shell.CreateShortcut($Link)
    $Shortcut.TargetPath = $Script
    $Shortcut.WorkingDirectory = $Dir
    $Shortcut.Description = "Festal Clipboard Integration"
    $Shortcut.Save()
}
Start-Process $Script
Write-Host "Installed. Test text and image paste before use."
