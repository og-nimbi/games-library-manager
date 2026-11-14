# Games Library Manager

Games Library Manager is a Windows desktop app that scans installed storefront libraries, discovers games, enriches them with artwork and metadata, and presents a unified game library in a native WinForms + WebView2 interface.

It can also generate an organized folder of shortcuts in your library root so your collection is easy to browse outside the app.

## Highlights

- **Unified library view**: Browse games from supported storefronts in one grid.
- **Native desktop app**: WinForms host with an embedded WebView2 UI for fast, modern rendering.
- **Direct launching**: Launch games and storefront clients from inside the app (no browser/protocol prompt flow).
- **Metadata enrichment**: Combines provider/store data with remote metadata sources (IGDB, VNDB, SteamGridDB) to fill gaps while preserving provider-supplied values.
- **Artwork cache**: Downloads and caches cover/hero art under your library’s `_library` cache for quick reloads.
- **Settings in-app**: Configure library options, shortcut folders, and optional launcher path overrides; store API credentials securely for the current Windows user.
- **Optional native library folders**: Create provider folders and `.lnk`/`.url` shortcuts in your library root, or disable folder creation and still launch directly from the app.

## Supported sources (current)

- **Steam** (installed games, metadata, artwork)
- **itch.io** (installed games from the itch app library, page/receipt metadata, artwork)
- **Epic Games** (installed games from Epic manifests)

Additional storefronts, standalone launchers, and emulator/ROM sources are part of the project’s direction (see [ROADMAP.md](ROADMAP.md)), but the current C# app focuses on the sources above.

## Requirements

- **Windows 10/11** (WebView2 runtime required; ships with Windows 11 and is commonly present on Windows 10)
- **.NET Framework 4.x runtime** (for the built app)
- **Microsoft WebView2 Runtime** if not already installed
- Internet access for remote metadata/artwork lookups (optional but recommended)

## Quick start

### Run a built copy

1. Build the app (see [docs/developer/building.md](docs/developer/building.md)) or use an existing deployment.
2. Launch `GamesLibraryViewer.exe`.
3. On first run, the app scans supported sources, enriches entries, generates the library view, and opens the UI.
4. Use **Settings** (gear icon) to configure library root, shortcut folders, launcher overrides, and API keys.

### Default locations

- **Library root (default):** `D:\Games`
- **Generated app/view data:** `<LibraryRoot>\_library\`
  - `index.html` – library view
  - `settings.html` – settings view
  - `artwork\` – cached images
  - app host files copied for local launch
- **User settings:** `%LOCALAPPDATA%\GamesLibraryManager\settings.json`
- **Secure secrets (DPAPI, CurrentUser):** `%LOCALAPPDATA%\GamesLibraryManager\secrets.dat`

## How it works

1. **Scan**: Detect installed games from supported providers.
2. **Normalize & merge**: Build game entries with provider IDs, targets, install paths, and normalized titles.
3. **Enrich**: Apply provider metadata first, then fill missing fields via configured metadata sources (without overwriting provider data).
4. **Cache artwork**: Resolve and download cover/hero images into the library cache.
5. **Generate UI**: Produce `index.html`/`settings.html` and copy runtime assets into `_library`.
6. **Launch**: Open the desktop app; actions in the UI are bridged to the host to launch games/launchers and save settings/secrets.

## Configuration

Bundled defaults live in `config/settings.json`. User changes made in the Settings UI are saved to `%LOCALAPPDATA%\GamesLibraryManager\settings.json` and loaded after bundled config.

Key options include:

- `libraryRoot` – where provider folders and `_library` are created
- `createLibraryFolders` – create provider folders and shortcuts in the library root
- `scan.shortcutFolders` – existing shortcut folders to reference/include (as configured)
- `launchers` – optional manual launcher executable paths (`steam`, `itch`, `epic`, or custom keys) used before auto-detection when valid

See [docs/user/configuration.md](docs/user/configuration.md) for details.

## Metadata & API keys

Some metadata/artwork sources require credentials:

- **Steam Web API** (optional features) / Steam 64 ID
- **SteamGridDB** API key (art fallback/enrichment)
- **IGDB** Client ID + Client Secret (Twitch developer app)

Keys are stored encrypted with Windows DPAPI for the current user and are never written to generated HTML/manifest-style outputs. VNDB lookups are keyless.

See [docs/user/metadata-and-api-keys.md](docs/user/metadata-and-api-keys.md).

## Documentation

- **User docs:** [docs/user/README.md](docs/user/README.md)
- **Developer docs:** [docs/developer/README.md](docs/developer/README.md)

## Project policies

- [LICENSE](LICENSE)
- [CHANGELOG.md](CHANGELOG.md)
- [ROADMAP.md](ROADMAP.md)
- [SECURITY.md](SECURITY.md)
- [PRIVACY.md](PRIVACY.md)
- [Terms of Service](TOS.md)
- [Contributing](CONTRIBUTING.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Support](SUPPORT.md)

## Status

This repository contains the current C# desktop application under `app/` and supporting assets/configuration. Legacy scripts or prototypes may exist in the tree for historical reference, but they are not the supported runtime for the app described in this documentation.

## Build & run

**Prerequisites:** Windows 10/11, WebView2 Runtime, .NET Framework build tools (`csc.exe`), and the WebView2 SDK (path configured in `app/build.cmd`, default `D:\tools\WebView2SDK`).

```cmd
cd app
build.cmd
```

```cmd
.\GamesLibraryViewer.exe
```

The build creates/updates a desktop shortcut for easier access. For detailed build, configuration, and deployment notes, see [docs/developer/building.md](docs/developer/building.md).
