# C# Conversion Plan

## Goal
Replace all PowerShell scripts with built-in C# functions. No .ps1 files at runtime.

## Steps (execute one at a time, verify each)

### Step 1: Secrets (DPAPI) — EASY
- DONE. Converted to app/Secrets.cs. Uses System.Security.Cryptography.ProtectedData.

### Step 2: Shortcuts (.lnk/.url) — MEDIUM
- DONE. Converted to app/Shortcuts.cs. Uses WScript.Shell COM for .lnk, text file for .url.

### Step 3: Steam Provider — MEDIUM
- IN PROGRESS. Skeleton created (GetSteamInstallPath, GetLibraryFolders, VDF parsing). Full game scanning not yet implemented.

### Step 4: Library Build — LARGE
- Convert src/Core/Library.ps1 to app/Library.cs
- Folder creation, manifest, stale cleanup

### Step 5: itch.io Provider — MEDIUM
- Convert src/Providers/Itch.ps1 to app/Providers/Itch.cs

### Step 6: Remaining Providers — LARGE
- Convert all other providers

### Step 7: Remove PS1 dependency
- Remove .ps1 files, update build, update docs

## Current Progress
- Step 1: NOT STARTED
- Step 2: NOT STARTED
- Step 3: NOT STARTED
- Step 4: NOT STARTED
- Step 5: NOT STARTED
- Step 6: NOT STARTED
- Step 7: NOT STARTED

## Completed
- Config.cs (JSON config loading)
- Discovery.cs (registry, Steam path)
- Titles.cs (title normalization)
- Program.cs (entry point, WebView2 host)
- app/build.cmd (compiles all C# files)