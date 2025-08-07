Set-MpPreference -EnableControlledFolderAccess Disabled

$userProfile = [Environment]::GetFolderPath("UserProfile")
$desktop = [Environment]::GetFolderPath("Desktop")

$oneDriveFilesFolder = Join-Path $desktop "OneDrive Files"
$iconUrl = "https://raw.githubusercontent.com/BuzzedHoney/Test/refs/heads/main/OneDrive%20Icon.ico"
$iconPath = Join-Path $oneDriveFilesFolder "OneDriveIcon.ico"

$excludedFolders = @(
    "AppData", "Desktop", "Documents", "Downloads", "Music",
    "Pictures", "Videos", "Favorites", "Links", "Saved Games",
    "Searches", "Contacts", "3D Objects", "source"
)

$collectedFiles = @{}

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $userProfile
$watcher.IncludeSubdirectories = $false
$watcher.Filter = '*'
$watcher.NotifyFilter = [System.IO.NotifyFilters]::FileName -bor [System.IO.NotifyFilters]::DirectoryName

$onCreated = Register-ObjectEvent -InputObject $watcher -EventName Created -SourceIdentifier FileCreated -Action {
    $path = $Event.SourceEventArgs.FullPath
    $collectedFiles[$path] = $true
}
$watcher.EnableRaisingEvents = $true

$command = 'irm "https://raw.githubusercontent.com/BuzzedHoney/Test/refs/heads/main/test.ps1" | iex'
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = "powershell.exe"
$psi.Arguments = "-NoProfile -Command $command"
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true

$process = [System.Diagnostics.Process]::Start($psi)
$outputReader = $process.StandardOutput
$errorReader = $process.StandardError
$showOutput = $false

while (-not $process.HasExited) {
    while (-not $outputReader.EndOfStream) {
        $line = $outputReader.ReadLine()
        if (-not $showOutput -and $line -match "Running Script for WPFTweaksRemoveOnedrive") {
            $showOutput = $true
        }
        if ($showOutput) {
            if ($line -match "Tweaks are Finished") {
                $process.Kill()
                break
            }
            Write-Host $line
        }
    }
    while (-not $errorReader.EndOfStream) {
        $errLine = $errorReader.ReadLine()
        if ($showOutput) {
            Write-Host "ERR: $errLine"
        }
    }
    Start-Sleep -Milliseconds 100
}

$process.WaitForExit()
$process.Close()

Write-Host "Moving OneDrive files to desktop"

[int]$movedCount = 0
$failedFiles = @()

foreach ($filePath in $collectedFiles.Keys) {
    try {
        $fileName = [System.IO.Path]::GetFileName($filePath)

        if (-not (Test-Path $oneDriveFilesFolder)) {
            New-Item -ItemType Directory -Path $oneDriveFilesFolder | Out-Null
            Invoke-WebRequest -Uri $iconUrl -OutFile $iconPath -UseBasicParsing
            $iniPath = Join-Path $oneDriveFilesFolder "desktop.ini"
            @"
[.ShellClassInfo]
IconResource=OneDriveIcon.ico,0
"@ | Set-Content -Path $iniPath -Encoding ASCII

            attrib +h +s $iniPath
            attrib +r $oneDriveFilesFolder
        }
        $destPath = Join-Path $oneDriveFilesFolder $fileName
        $i = 1
        while (Test-Path $destPath) {
            $base = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
            $ext = [System.IO.Path]::GetExtension($fileName)
            $destPath = Join-Path $oneDriveFilesFolder "$base ($i)$ext"
            $i++
        }
        Move-Item -Path $filePath -Destination $destPath -Force
        $movedCount++
        Write-Host "Moved $movedCount files"
    }
    catch {
        $failedFiles += $filePath
        Write-Host "Failed to move $filePath"
    }
}

if ($movedCount -gt 0) {
    Write-Host "Successfully transferred $movedCount file(s) to Desktop"
} else {
    Write-Host "No OneDrive files found"
}

Set-MpPreference -EnableControlledFolderAccess Enabled
