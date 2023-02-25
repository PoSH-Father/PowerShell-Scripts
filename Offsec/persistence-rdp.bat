@ECHO OFF
:: This batch file adds a user to Administrator and enables RDP
TITLE Add user
ECHO Adding user...
net user moetest1 password /add
net localgroup Administrators moetest /add
net localgroup "Remote Desktop Users" moetest /add
Echo Enabling RDP...
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f
ECHO ==========================
ECHO User Added
ECHO ==========================
net users 
