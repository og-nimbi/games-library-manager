# Project Structure

This document describes the key directories and files in the repository, with emphasis on the current C# application.

## Top-level overview

```text
app/                    Current C# WinForms + WebView2 application (primary)
assets/                 Icons and static assets
config/                 Bundled configuration defaults
docs/                   User and developer documentation
web/                    Web/UI helper assets (e.g. settings script) used by the app
.github/                Issue/PR templates and repository health files
.opencode/              Local agent/tooling configuration and project context (development support)
AGENTS.md               Agent/development instructions (project context)
```

> Legacy scripts or experiments may exist elsewhere in the repository. They are not part of the supported runtime unless explicitly documented as such.

## `app/` (primary application)

Core source files (representative):

- `Program.cs` — application entry point and orchestration (config load, scan, enrichment, generation, launch)
- `GamesLibraryViewer.cs` — WinForms host, WebView2 setup, host bridge/message handling
- `Config.cs` — configuration model, defaults, load/apply/save, user settings path
- `Secrets.cs` — secure credential storage and retrieval (DPAPI-backed)
- `Discovery.cs` — discovery/path/registry helpers used by providers and runtime
- `Titles.cs` — title normalization and display-safe naming helpers
- `Shortcuts.cs` — shortcut creation utilities (`.lnk`/`.url`)
- `Icons.cs` — UI icon helpers/assets references
- `Http.cs` — shared HTTP helpers (e.g. user agent)

### Providers
- `SteamProvider.cs` — Steam library detection and entry mapping
- `ItchProvider.cs` — itch.io installation/library detection and metadata extraction
- `EpicProvider.cs` — Epic Games manifest discovery and entry mapping

### Metadata and artwork
- `Metadata.cs` — metadata enrichment pipeline and external source integrations
- `Artwork.cs` — artwork resolution, download, and cache management

### UI generation
- `HtmlGenerator.cs` — generates `index.html` and `settings.html` (markup, styles, embedded scripts)

### Build and runtime assets
- `build.cmd` — local build script (`csc.exe` + WebView2 SDK references)
- `GamesLibraryViewer.exe` and WebView2 DLLs — build outputs/runtime dependencies (when built/copied)
- `settings.js` — settings-page script used by the generated settings view (source/copied variant)

## `config/`

- `settings.json` — bundled default configuration loaded at startup before user overrides

## `web/`

- `js/settings.js` — source for settings UI behavior (persisting API keys and config via host bridge)
- Other web-related assets may be added here as the UI evolves

## `docs/`

- `user/` — end-user guides (installation, usage, configuration, troubleshooting)
- `developer/` — architecture, build, implementation details, maintenance guidance
- `developer/research/` — exploratory notes and background research

## `.github/`

- `ISSUE_TEMPLATE/` — YAML issue forms and template configuration
- `PULL_REQUEST_TEMPLATE.md` — PR checklist and structure
- Additional repository health/community files (policies, support, contribution docs may live at repo root)

## Generated/runtime data (outside repo by default)

### Library root output (default `D:\Games`)
- `<LibraryRoot>\_library\index.html` — generated library UI
- `<LibraryRoot>\_library\settings.html` — generated settings UI
- `<LibraryRoot>\_library\artwork\` — cached artwork/assets
- Provider folders and shortcuts (when enabled)

### Per-user application data
- `%LOCALAPPDATA%\GamesLibraryManager\settings.json` — saved user settings overrides
- `%LOCALAPPDATA%\GamesLibraryManager\secrets.dat` — DPAPI-encrypted credentials

## Notes for contributors

- Treat `app/` as the source of truth for application behavior.
- When adding a provider or changing config/UI behavior, update both **user** and **developer** docs as appropriate.
- Avoid committing generated outputs, caches, secrets, or machine-specific build artifacts unless intentionally versioned for release.
