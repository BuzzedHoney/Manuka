# I'll add more if I find some...
Write-Host "Configuring Registry Tweaks"
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Type String -Value "0"
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ExtendedUIHoverTime" -Type DWord -Value 1
