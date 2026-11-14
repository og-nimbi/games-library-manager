@echo off
setlocal
set "SDK=D:\tools\WebView2SDK"
set "CSC=C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if not exist "%CSC%" set "CSC=C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe"

if not exist "%SDK%\lib\net462\Microsoft.Web.WebView2.Core.dll" (
    echo WebView2 SDK not found
    exit /b 1
)

pushd "%~dp0"
"%CSC%" /target:winexe /out:GamesLibraryViewer.exe /main:GamesLibraryManager.Program ^
  Config.cs Discovery.cs Titles.cs Secrets.cs Shortcuts.cs SteamProvider.cs ItchProvider.cs EpicProvider.cs Artwork.cs Metadata.cs Http.cs Icons.cs HtmlGenerator.cs Program.cs GamesLibraryViewer.cs ^
  /reference:"%SDK%\lib\net462\Microsoft.Web.WebView2.Core.dll" ^
  /reference:"%SDK%\lib\net462\Microsoft.Web.WebView2.WinForms.dll" ^
  /reference:System.dll /reference:System.Core.dll /reference:System.Web.dll ^
  /reference:System.Web.Extensions.dll

if errorlevel 1 (
    echo BUILD FAILED
    popd
    exit /b 1
)

copy /y "%SDK%\build\native\x64\WebView2Loader.dll" . >nul
copy /y "%SDK%\lib\net462\Microsoft.Web.WebView2.Core.dll" . >nul
copy /y "%SDK%\lib\net462\Microsoft.Web.WebView2.WinForms.dll" . >nul
copy /y "..\assets\games.ico" . >nul 2>&1
copy /y "..\web\js\settings.js" . >nul 2>&1
rem Create/update a desktop shortcut for easy access.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$exe = Join-Path '%CD%' 'GamesLibraryViewer.exe'; $desktop = [Environment]::GetFolderPath('Desktop'); $lnk = Join-Path $desktop 'Games Library Manager.lnk'; $w = New-Object -ComObject WScript.Shell; $s = $w.CreateShortcut($lnk); $s.TargetPath = $exe; $s.WorkingDirectory = '%CD%'; $s.Description = 'Games Library Manager'; $ico = Join-Path '%CD%' 'games.ico'; if (Test-Path $ico) { $s.IconLocation = $ico }; $s.Save()" >nul 2>&1
if errorlevel 1 (
    echo BUILD OK ^(desktop shortcut not created^)
) else (
    echo BUILD OK ^(desktop shortcut created/updated^)
)
popd
endlocal