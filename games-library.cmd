@echo off
setlocal
rem Games Library Manager - Windows batch wrapper around games-library.ps1.
rem Do not install anything; this uses the built-in Windows PowerShell 5.1.

if /i "%~1"=="-Help" goto usage
if /i "%~1"=="/?" goto usage

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0games-library.ps1" %*
set "EXITCODE=%ERRORLEVEL%"
endlocal & exit /b %EXITCODE%

:usage
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0games-library.ps1" -Help
endlocal & exit /b 0
