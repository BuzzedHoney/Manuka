Write-Host "Updating Windows Defender"
Set-MpPreference -PlatformUpdatesChannel Beta
Update-MpSignature
Write-Host "I removed the antivirus settings, I'll fix it later."
Start-Sleep 5


Write-Host "Configuring Exploit Protection"
$current = (Get-ProcessMitigation -System).System.MitigationOptions
Set-ProcessMitigation -System -Enable ($current + @("CFG","DEP","ForceRelocateImages","BottomUp","HighEntropy","SEHOP","TerminateOnError"))
bcdedit /set "{current}" nx AlwaysOn

Write-Host "Configuring Firewall"
Set-NetFirewallProfile -Profile Domain,Private,Public -Enabled True
Get-NetConnectionProfile | Where-Object {$_.NetworkCategory -ne 'Public'} | ForEach-Object { Set-NetConnectionProfile -InterfaceIndex $_.InterfaceIndex -NetworkCategory Public }

Write-Host "Security Tweaks Completed"

# DEPRICATED
