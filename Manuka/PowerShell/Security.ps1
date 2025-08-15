Write-Host "Updating Windows Defender"
Set-MpPreference -PlatformUpdatesChannel Beta
Update-MpSignature
Write-Host "Configuring Windows Defender"
Set-MpPreference `
  -DisableRealtimeMonitoring $false `
  -DisableBehaviorMonitoring $false `
  -DisableIOAVProtection $false `
  -DisableScriptScanning $false `
  -MAPSReporting Advanced `
  -SubmitSamplesConsent AlwaysPrompt `
  -PUAProtection Enabled `
  -EnableControlledFolderAccess Enabled `
  -EnableNetworkProtection Enabled `
  -NetworkProtectionReputationMode 2 `
  -EnableDnsSinkhole $true `
  -DisableNetworkProtectionPerfTelemetry $true `
  -CloudBlockLevel ZeroTolerance `
  -CloudExtendedTimeout 60

Write-Host "Configuring Exploit Protection"
$current = (Get-ProcessMitigation -System).System.MitigationOptions
Set-ProcessMitigation -System -Enable ($current + @("CFG","DEP","ForceRelocateImages","BottomUp","HighEntropy","SEHOP","TerminateOnError"))
bcdedit /set "{current}" nx AlwaysOn

Write-Host "Configuring Firewall"
Set-NetFirewallProfile -Profile Domain,Private,Public -Enabled True
Get-NetConnectionProfile | Where-Object {$_.NetworkCategory -ne 'Public'} | ForEach-Object { Set-NetConnectionProfile -InterfaceIndex $_.InterfaceIndex -NetworkCategory Public }

Write-Host "Security Tweaks Completed"
