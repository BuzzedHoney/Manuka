# --- Define Win32 API calls once ---
Add-Type @"
using System;
using System.Runtime.InteropServices;

public class Win32 {
    [DllImport("user32.dll")]
    public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern int GetWindowText(IntPtr hWnd, System.Text.StringBuilder text, int maxLength);
}
"@

# Constants
$SW_HIDE = 0

# --- Start background job to hide PS windows ---
$null = Start-Job -ScriptBlock {
    param($SW_HIDE)
    $hidden = 0
    while ($hidden -lt 3) {
        $psProcesses = Get-Process | Where-Object {
            $_.ProcessName -match '^powershell(|_ise|\.exe)?$' -or $_.ProcessName -match '^pwsh$'
        }
        foreach ($proc in $psProcesses) {
            if ($proc.MainWindowHandle -ne 0) {
                if ([Win32]::ShowWindowAsync($proc.MainWindowHandle, $SW_HIDE)) {
                    $hidden++
                }
            }
        }
        Start-Sleep -Milliseconds 200
    }
} -ArgumentList $SW_HIDE

# --- Launch WinUtil tweaks process ---
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = "powershell.exe"
$psi.Arguments = '-NoProfile -Command "iex \"& { $(irm christitus.com/win) } -Config https://raw.githubusercontent.com/BuzzedHoney/Manuka/main/Manuka/Configs/Tweaks.json -Run\""'
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError  = $true
$psi.UseShellExecute        = $false
$psi.CreateNoWindow         = $true

$process   = [System.Diagnostics.Process]::Start($psi)
$readerOut = $process.StandardOutput
$readerErr = $process.StandardError

while (-not $readerOut.EndOfStream -or -not $readerErr.EndOfStream) {
    while (-not $readerOut.EndOfStream) {
        $line = $readerOut.ReadLine()
        Write-Output $line

        if ($line -match "Tweaks are Finished") {
            $apps = Get-Process | Where-Object { $_.MainWindowTitle }
            foreach ($app in $apps) {
                if ($app.MainWindowTitle -like "*WinUtil*") {
                    Stop-Process -Id $app.Id -Force
                }
            }

            irm "https://raw.githubusercontent.com/BuzzedHoney/Manuka/main/Manuka/PowerShell/Debloat.ps1" | iex
            Start-Sleep -Seconds 3

            New-Item -ItemType Directory -Force -Path "$env:LOCALAPPDATA\Temp\Win11Debloat" | Out-Null
            Invoke-RestMethod 'https://raw.githubusercontent.com/BuzzedHoney/Manuka/main/Manuka/Configs/CustomAppsList' |
                Set-Content "$env:LOCALAPPDATA\Temp\Win11Debloat\CustomAppsList"

            & ([scriptblock]::Create((irm "https://debloat.raphi.re/"))) `
                -Silent `
                -RemoveAppsCustom `
                -DisableTelemetry `
                -DisableSettings365Ads `
                -DisableBing `
                -DisableCopilot `
                -DisableNotepadAI `
                -DisablePaintAI `
                -DisableRecall `
                -DisableDVR `
                -DisableSuggestions `
                -DisableLockscreenTips `
                -DisableDesktopSpotlight `
                -DisableWidgets `
                -DisableFastStartup `
                -DisableStickyKeys `
                -DisableMouseAcceleration

            Start-Sleep -Seconds 3
            irm "https://raw.githubusercontent.com/BuzzedHoney/Manuka/main/Manuka/PowerShell/Security.ps1" | iex
            Start-Sleep -Seconds 3
            irm "https://raw.githubusercontent.com/BuzzedHoney/Manuka/main/Manuka/PowerShell/Privacy.ps1" | iex
            Start-Sleep -Seconds 3

            Write-Host "All Optimizations Complete"
            Start-Sleep -Seconds 3
            Write-Host "Closing Message"
            Start-Sleep -Seconds 3

            $process.Close()
            exit
        }
    }

    while (-not $readerErr.EndOfStream) {
        $errLine = $readerErr.ReadLine()
        Write-Output $errLine
    }
}

$process.WaitForExit()
$process.Close()
