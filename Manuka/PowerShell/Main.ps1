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
$psi.RedirectStandardError = $true
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true

$process   = [System.Diagnostics.Process]::Start($psi)
$readerOut = $process.StandardOutput
$readerErr = $process.StandardError

while (-not $readerOut.EndOfStream -or -not $readerErr.EndOfStream) {
    while (-not $readerOut.EndOfStream) {
        $line = $readerOut.ReadLine()
        Write-Output $line

        if ($line -match "=====Windows Toolbox=====") {
            $hiderScript = @'
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
}
"@

while ($true) {
    $manukaProc = Get-Process -Name "Manuka" -ErrorAction SilentlyContinue
    if (-not $manukaProc) {
        Get-Process PowerShell | Stop-Process -Force
    }

    $winutilProcs = Get-Process | Where-Object { $_.MainWindowTitle -like "*WinUtil*" -or $_.MainWindowTitle -like "*powershell*" }
    foreach ($proc in $winutilProcs) {
        if ($proc.MainWindowHandle -ne 0) {
            [Win32]::ShowWindowAsync($proc.MainWindowHandle, 0) | Out-Null
        }
    }
}
'@
            $encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($hiderScript))
            Start-Process -FilePath "powershell.exe" -WindowStyle Hidden -ArgumentList "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $encodedCommand"
        }

        if ($line -match "Tweaks are Finished") {
            $apps = Get-Process | Where-Object { $_.MainWindowTitle }
            foreach ($app in $apps) {
                if ($app.MainWindowTitle -like "*WinUtil*") {
                    Stop-Process -Id $app.Id -Force
                }
            }

            irm "https://raw.githubusercontent.com/BuzzedHoney/Manuka/main/Manuka/PowerShell/Debloat.ps1" | iex
			
            Start-Sleep 3

            New-Item -ItemType Directory -Force -Path "$env:LOCALAPPDATA\Temp\Win11Debloat" | Out-Null
            Invoke-RestMethod 'https://raw.githubusercontent.com/BuzzedHoney/Manuka/main/Manuka/Configs/CustomAppsList' |
                Set-Content "$env:LOCALAPPDATA\Temp\Win11Debloat\CustomAppsList"

            & ([scriptblock]::Create((irm "https://debloat.raphi.re/"))) `
                -Silent `
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
                -DisableSuggestions `
                -DisableLockscreenTips `
                -DisableDesktopSpotlight `
                -DisableWidgets `
                -DisableFastStartup `
                -DisableStickyKeys `
                -DisableMouseAcceleration

            Start-Sleep 3
   
            irm "https://raw.githubusercontent.com/BuzzedHoney/Manuka/main/Manuka/PowerShell/Security.ps1" | iex
   
            Get-Process PowerShell | Stop-Process -Force
        }
    }
    while (-not $readerErr.EndOfStream) {
        $errLine = $readerErr.ReadLine()
        Write-Output $errLine
    }
}
