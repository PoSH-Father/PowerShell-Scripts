@ECHO OFF
REM This batch file adds a user to Administrator and enables RDP

SET USERNAME=moetest1
SET PASSWORD=password

ECHO Adding user "%USERNAME%"...
net user "%USERNAME%" "%PASSWORD%" /add
IF NOT %ERRORLEVEL% == 0 (
ECHO Failed to add user "%USERNAME%".
GOTO :END
)

ECHO Adding user "%USERNAME%" to Administrators group...
net localgroup Administrators "%USERNAME%" /add
IF NOT %ERRORLEVEL% == 0 (
ECHO Failed to add user "%USERNAME%" to Administrators group.
GOTO :END
)

ECHO Adding user "%USERNAME%" to Remote Desktop Users group...
net localgroup "Remote Desktop Users" "%USERNAME%" /add
IF NOT %ERRORLEVEL% == 0 (
ECHO Failed to add user "%USERNAME%" to Remote Desktop Users group.
GOTO :END
)

ECHO Enabling RDP...
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f
IF NOT %ERRORLEVEL% == 0 (
ECHO Failed to enable RDP.
GOTO :END
)

ECHO ==========================
ECHO User Added
ECHO ==========================
net users

:END
PAUSE
