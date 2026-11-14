# Architecture

## Purpose

Scan every local game source and rebuild one organized shortcut library. The
library is disposable; the sources are the source of truth.

## Runtime flow

```text
games-library.cmd
  -> games-library.ps1 (flags, config, module load)
     -> Get-GamesLibraryConfig
     -> Invoke-ProviderScans
        -> one Get-<Name>Provider per selected provider
        -> Merge-CustomEntries
        -> Remove-DuplicateStandaloneGames
     -> Build-GamesLibrary
        -> backup unmanaged root when -Force
        -> create provider folders and shortcuts
        -> write _library\manifest.json
        -> remove stale artifacts
        -> write _library\index.html
        -> open result when -Open
```

## Module responsibilities

| Module | Responsibility |
| --- | --- |
| `Common.ps1` | Config merge, logging, path/name helpers, `New-GameEntry`, `New-ProviderResult` |
| `Secrets.ps1` | DPAPI-backed secret storage and `{secret:NAME}` resolution |
| `Discovery.ps1` | Registry, drives, installed programs, executable resolution, PE bitness, version info |
| `Titles.ps1` | Curated overrides and regex normalization |
| `Shortcuts.ps1` | `.lnk` and `.url` creation, icon resolution, folder icons |
| `Index.ps1` | Static HTML index |
| `Library.ps1` | Root backup, folder build, manifest, stale cleanup |
| `Providers.ps1` | Catalog, selection, execution, merging |
| `src/Providers/*.ps1` | One source each |

## Provider contract

`Get-<Name>Provider -Config $Config` returns `New-ProviderResult`, an array of
them, or `$null`. The emulator provider is the only multi-result provider today.

## Configuration

`config/settings.json` merges over `Get-DefaultConfig`. Keys:

```text
libraryRoot
createHtmlIndex
createFolderIcons
removeStaleShortcuts
providers.{steam,epic,gog,itch,amazon,legacyGames,ea,ubisoft,battleNet,
           rockstar,riot,wargaming,hiRez,xbox,standalone,customLaunchers,emulators}
scan.extraGameRoots
scan.standaloneSearchRoots
scan.standaloneDepth
scan.deepDriveScan
scan.romRoots
scan.romDepth
scan.emulatorRoots
customEntries[]
customLaunchers[]
```

## Output layout

```text
D:\Games\
  Providers\
    Steam.lnk
    itch.io.lnk
    Dolphin.lnk
  Steam\
    Game.url
  itch.io\
    Game.lnk
  Dolphin\
    Game.lnk
  _library\
    manifest.json
    index.html
    last-run.log
```

One folder per provider or emulator. `Providers\` holds launcher shortcuts.

## Current source coverage

Stores: Steam, GOG, Epic Games, itch.io, Amazon Games, Legacy Games, EA,
Ubisoft Connect, Battle.net, Rockstar, Riot, Wargaming, Hi-Rez, Xbox.

Standalone: official launchers and community launchers under
`Custom Launchers\`.

Emulation: Dolphin, Cemu, PCSX2, RPCS3, DuckStation, PPSSPP, melonDS, DeSmuME,
Citra, yuzu, Ryujinx, mGBA, Snes9x, Project64, Mupen64Plus, Flycast, redream,
xemu, Xenia, Vita3K, Cxbx-Reloaded, FCEUX, Mesen, Nestopia, Kega Fusion,
Mednafen, BizHawk, ScummVM, MAME, RetroArch.

## Identity and dedupe

- A game entry carries `Provider`, `ProviderKey`, `Kind`, `Target`, `Arguments`,
  `WorkingDirectory`, `IconPath`, `InstallDir`, `Id`, and `Source`.
- Store protocol targets become `.url`; file targets become `.lnk`.
- Standalone entries already claimed by a store are removed by install directory
  or target path.
- Titles are normalized once, centrally.

## Artwork direction

Store art first, metadata providers as fallback. Raw images are cached. The viewer
is a native TypeScript (ESM) desktop app with system light/dark mode and accent
colors. No browser, PowerShell, Tauri, or web rendering engine. Games are
launched directly via native process invocation. Settings and secrets are managed
in-app. The viewer hydrates entries and metadata into memory once, backed by a
persistent disk cache, so navigation is instant and API/CDN requests stay rare
and conditional.
