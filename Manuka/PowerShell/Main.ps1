$winutil_content = irm "https://christitus.com/win"

$feature_pattern = '(?ms)^\s*Write-Host "Installing features\.\.\."\s*.*?Write-Host "Done\."'
$modded_content = [regex]::Replace($winutil_content, $feature_pattern, '')

$winutil_path = "$env:TEMP\Manuka\Modded_WinUtil.ps1"
New-Item -ItemType Directory -Force -Path (Split-Path $winutil_path) | Out-Null
Set-Content -Path $winutil_path -Value $modded_content -Encoding UTF8

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = "powershell.exe"
$psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$winutil_path`" -Config https://raw.githubusercontent.com/BuzzedHoney/Manuka/main/Manuka/Configs/Tweaks.json -Run -NoUI"
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError  = $true
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true

$process   = [System.Diagnostics.Process]::Start($psi)
$readerOut = $process.StandardOutput
$readerErr = $process.StandardError

$winutilHidden = $false

while (-not $process.HasExited) {

    while (-not $readerOut.EndOfStream) {
        $line = $readerOut.ReadLine()
        Write-Output $line

        if (-not $winutilHidden -and $line -match "=====Windows Toolbox=====") {
            $winutilHidden = $true

            Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
}
"@

            Get-Process | Where-Object {
                $_.MainWindowTitle -like "*WinUtil*" -or $_.MainWindowTitle -like "*Windows Toolbox*"
            } | ForEach-Object {
                if ($_.MainWindowHandle -ne 0) {
                    [Win32]::ShowWindowAsync($_.MainWindowHandle, 0) | Out-Null
                }
            }
        }

        if ($line -match "Tweaks are Finished") {

            Get-Process | Where-Object {
                $_.MainWindowTitle -like "*WinUtil*"
            } | Stop-Process -Force

            irm "https://raw.githubusercontent.com/BuzzedHoney/Manuka/main/Manuka/PowerShell/Debloat.ps1" | iex
            Start-Sleep 3

            $debloatPath = "$env:LOCALAPPDATA\Temp\Win11Debloat"
            New-Item -ItemType Directory -Force -Path $debloatPath | Out-Null

            irm "https://raw.githubusercontent.com/BuzzedHoney/Manuka/main/Manuka/Configs/CustomAppsList" |
                Set-Content "$debloatPath\CustomAppsList"

            & ([scriptblock]::Create((irm "https://debloat.raphi.re/"))) `
                -Silent `
                -NoRestartExplorer `
                -RemoveAppsCustom `
                -DisableTelemetry `
                -DisableSettings365Ads `
                -DisableEdgeAds `
                -DisableBing `
                -DisableCopilot `
                -DisableNotepadAI `
                -DisablePaintAI `
                -DisableEdgeAI `
                -DisableClickToDo `
                -DisableRecall `
                -DisableDVR `
                -DisableGameBarIntegration `
                -DisableSuggestions `
                -DisableLockscreenTips `
                -DisableDesktopSpotlight `
                -DisableWidgets `
                -DisableFastStartup `
                -DisableStickyKeys `
                -DisableMouseAcceleration

            Start-Sleep 3

            irm "https://raw.githubusercontent.com/BuzzedHoney/Manuka/main/Manuka/PowerShell/Security.ps1" | iex
        }
    }

    while (-not $readerErr.EndOfStream) {
        Write-Output $readerErr.ReadLine()
    }

    Start-Sleep -Milliseconds 50
}
