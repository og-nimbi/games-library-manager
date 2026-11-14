# Architecture Overview

## High-level design

Games Library Manager is a **Windows desktop app** composed of:

- **Native host (WinForms):** application lifecycle, window management, and privileged/local operations
- **Embedded UI (WebView2):** renders the library and settings interfaces (generated HTML/CSS/JS)
- **Host bridge:** message passing between UI JavaScript and the C# host for actions like launching targets and saving settings/secrets
- **Scan/build pipeline:** provider discovery, normalization, enrichment, artwork caching, and UI generation

The app is designed to run locally, scan installed games, generate a browsable library view, and launch games/launchers directly.

## Runtime flow

1. **Startup**
   - Load bundled config (`config/settings.json`) and user overrides (`%LOCALAPPDATA%\GamesLibraryManager\settings.json`)
   - Determine library root and ensure `_library` output directory exists

2. **Provider scans**
   - Query supported storefront providers (Steam, itch.io, Epic Games)
   - Produce normalized game entries (title, provider, IDs, target/launch info, install hints, etc.)

3. **Shortcut/library output (optional)**
   - If enabled, create provider folders and shortcuts in the library root
   - Preserve safe naming and provider grouping

4. **Artwork and metadata enrichment**
   - Resolve provider/store artwork and metadata first
   - Fill missing fields via external sources (IGDB, VNDB, SteamGridDB) without overwriting provider values
   - Cache assets under `<LibraryRoot>\_library\artwork`

5. **UI generation**
   - Generate `index.html` (library) and `settings.html` (settings)
   - Copy required runtime assets (exe/DLLs/icon/settings JS as applicable) into `_library` for the deployed view

6. **Host/UI interaction**
   - Open WebView2 window pointing to generated library page
   - UI sends actions (launch, save config, save secrets) to host via bridge
   - Host performs local operations and persists settings/secrets

## Key components

### Host and entry points
- `Program.cs` / app startup: orchestrates config load, scanning, enrichment, output generation, and app launch
- `GamesLibraryViewer.cs` (and related host classes): WinForms window, WebView2 initialization, and host-side handlers/objects

### Configuration and persistence
- `Config.cs`: config model/defaults, load/merge, user settings path, apply/save behavior
- `Secrets.cs`: secure credential storage/retrieval (DPAPI-backed)

### Providers and discovery
- `SteamProvider.cs`, `ItchProvider.cs`, `EpicProvider.cs`: source-specific detection and entry creation
- `Discovery.cs`: filesystem/registry/path helpers (as implemented)

### Metadata and artwork
- `Metadata.cs`: enrichment pipeline and external provider integrations
- `Artwork.cs`: cover/hero resolution and caching
- `Http.cs`: shared HTTP helpers (including user agent)

### UI generation
- `HtmlGenerator.cs`: builds library and settings HTML/embedded UI assets
- `web/js/settings.js` (and copied runtime variant): settings page interactions and host messaging

### Utilities
- `Titles.cs`: normalization and display-safe title handling
- `Shortcuts.cs`: shortcut creation helpers
- `Icons.cs`: icon assets/helpers for UI

## Data and trust boundaries

- **Local filesystem/registry:** read for discovery; write for generated library artifacts, cache, and settings (within configured/user-app-data locations)
- **Network:** outbound requests to metadata/artwork services as needed; responses treated as untrusted external data
- **Secrets:** user-provided API keys stored encrypted locally (DPAPI, CurrentUser) and accessed only for configured integrations
- **UI-to-host bridge:** accepts specific action messages; host must validate inputs before performing local actions

## Design principles

- **Provider data wins:** never overwrite provider-supplied metadata with remote guesses
- **Graceful degradation:** missing credentials/services should not break core browsing/launching
- **Local-first:** cache assets and persist settings locally for repeat use
- **Minimal surprises:** avoid destructive operations and make output locations explicit/configurable
- **Compatibility:** keep build/runtime assumptions aligned with the project’s supported Windows toolchain

## Known architectural constraints

- Windows-only (WinForms + WebView2)
- UI is generated/static HTML hosted in WebView2 (not a bundled SPA framework build pipeline in the current app)
- Network-dependent enrichment quality varies by third-party service availability and matching accuracy
- Some behaviors depend on locally installed storefront clients and their data formats
