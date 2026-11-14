# Changelog

All notable changes to this project should be documented in this file.

The format is inspired by [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the project aims to follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html) where applicable.

## [Unreleased]

### Added
- Native C# WinForms + WebView2 desktop application (`app/`) for scanning, browsing, and launching games.
- Provider scanning for Steam, itch.io, and Epic Games.
- Unified library UI with cover grid, search, provider filters, sorting, and metadata sidebar.
- Launcher tiles to open installed storefront clients directly.
- Artwork resolution and caching under the library `_library/artwork` directory.
- Metadata enrichment pipeline combining provider data with IGDB, VNDB, and SteamGridDB (without overwriting provider-supplied fields).
- In-app Settings page for secure API key storage (DPAPI), library options, shortcut folders, and manual launcher path overrides.
- Dynamic settings rows for launcher executables and shortcut folders.
- Optional native library folder/shortcut generation in the configured library root.
- Bundled configuration defaults in `config/settings.json` and persisted user settings in `%LOCALAPPDATA%\GamesLibraryManager\settings.json`.

### Changed
- Project direction moved from legacy script-based flows to a compiled C# desktop app as the primary/supported implementation.
- Launcher section behavior clarified: storefront tiles launch clients; filter pills control library filtering.

### Fixed
- itch.io launcher detection for versioned `app-*` installations and common locations.
- Metadata parsing issues caused by JSON array handling, improving IGDB/VNDB enrichment reliability.
- HTTP requests now use a standard browser user agent to reduce CDN/anti-bot blocking.
- Library grid now renders automatically on initial load.

### Security
- API credentials stored encrypted for the current Windows user via DPAPI in `%LOCALAPPDATA%\GamesLibraryManager\secrets.dat`.

## [0.1.0] - Historical

Early repository iterations explored a PowerShell-based library builder and related experiments. Those implementations are considered legacy and are not the supported runtime for the current application.
