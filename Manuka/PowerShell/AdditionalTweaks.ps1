# I'll add more if I find some... If you have any ideas create an issue and I'll look into whatever registry or service tweak you give me.


Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Type String -Value "0"
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ExtendedUIHoverTime" -Type DWord -Value 1


# Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\CrossDeviceResume\Configuration" -Name "IsResumeAllowed" -Type DWord -Value 0

# sc.exe config "WSearch" start= disabled
