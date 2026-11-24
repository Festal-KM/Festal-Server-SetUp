$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$TempFile = $null
try {
    $Config = Get-Content -Raw (Join-Path $PSScriptRoot "clipboard-config.json") | ConvertFrom-Json
    $HostAlias = $Config.SshAlias
    $RemoteDir = $Config.RemoteDir
    if ($HostAlias -notmatch '^[a-zA-Z0-9][a-zA-Z0-9._-]*$' -or $RemoteDir -notmatch '^/home/[a-zA-Z0-9_-]+/\.codex-images$') { throw "Invalid configuration." }
    if ([System.Windows.Forms.Clipboard]::ContainsImage()) {
        $Image = [System.Windows.Forms.Clipboard]::GetImage()
        $Name = "clipboard-" + [guid]::NewGuid().ToString("N") + ".png"
        $TempFile = Join-Path $env:TEMP $Name
        try { $Image.Save($TempFile, [System.Drawing.Imaging.ImageFormat]::Png) }
        finally { $Image.Dispose() }
        $Source = $TempFile
    } elseif ([System.Windows.Forms.Clipboard]::ContainsFileDropList()) {
        $Files = [System.Windows.Forms.Clipboard]::GetFileDropList()
        if ($Files.Count -ne 1) { throw "Select one image file." }
        $Source = $Files[0]
        $Ext = [IO.Path]::GetExtension($Source).ToLowerInvariant()
        if ($Ext -notin @(".png",".jpg",".jpeg",".webp",".gif")) { throw "Unsupported image format." }
        $Name = "clipboard-" + [guid]::NewGuid().ToString("N") + $Ext
    } else { exit 2 }
    $RemotePath = "$RemoteDir/$Name"
    & scp -q -o BatchMode=yes -o ConnectTimeout=10 -- $Source "$($HostAlias):$RemotePath"
    if ($LASTEXITCODE -ne 0) { throw "Image transfer failed." }
    & ssh -o BatchMode=yes -o ConnectTimeout=10 $HostAlias "chmod 600 '$RemotePath'"
    if ($LASTEXITCODE -ne 0) { throw "Remote permission setup failed." }
    [Console]::WriteLine($RemotePath)
    exit 0
} catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
} finally {
    if ($TempFile -and (Test-Path -LiteralPath $TempFile)) { Remove-Item -LiteralPath $TempFile -Force }
}
