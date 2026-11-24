#Requires AutoHotkey v2.0
#SingleInstance Force
#HotIf WinActive("ahk_exe Code.exe")
$^+v:: {
    static Busy := false
    if Busy
        return
    Busy := true
    try {
        if DllCall("IsClipboardFormatAvailable", "UInt", 2)
            || DllCall("IsClipboardFormatAvailable", "UInt", 8)
            || DllCall("IsClipboardFormatAvailable", "UInt", 17)
            || DllCall("IsClipboardFormatAvailable", "UInt", 15) {
            Target := WinGetID("A")
            Script := A_ScriptDir "\Paste-FestalImage.ps1"
            Command := 'powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "' Script '"'
            ToolTip("Transferring image to Festal server...")
            Shell := ComObject("WScript.Shell")
            Proc := Shell.Exec(Command)
            while Proc.Status = 0
                Sleep(100)
            Output := Trim(Proc.StdOut.ReadAll())
            ErrorText := Trim(Proc.StdErr.ReadAll())
            if Proc.ExitCode != 0 {
                MsgBox("Image transfer failed.`n" ErrorText)
                return
            }
            if !WinActive("ahk_id " Target) {
                MsgBox("Image transferred. Paste this path manually:`n" Output)
                return
            }
            SavedClipboard := ClipboardAll()
            try {
                A_Clipboard := Output
                if ClipWait(2) {
                    Send("^+v")
                    Sleep(800)
                }
            } finally {
                A_Clipboard := SavedClipboard
            }
        } else {
            Send("^+v")
        }
    } catch as Err {
        MsgBox(Err.Message)
    } finally {
        ToolTip()
        Busy := false
    }
}
#HotIf
