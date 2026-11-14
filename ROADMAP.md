# Roadmap

This roadmap reflects the current direction of Games Library Manager as a Windows desktop application (C# WinForms + WebView2).

Status labels used below: **Done**, **In progress**, **Planned**, **Exploring**, **Not planned**.

## Done

- [x] C# WinForms + WebView2 desktop host with in-app library UI
- [x] Steam provider scanning and library entries
- [x] itch.io provider scanning and library entries
- [x] Epic Games provider scanning and library entries
- [x] Unified game grid with search, provider filter pills, sorting, and detail sidebar
- [x] Direct in-app launching of games and storefront launchers (host bridge)
- [x] Artwork resolution and local caching
- [x] Metadata enrichment pipeline (provider data first; IGDB/VNDB/SteamGridDB fill gaps)
- [x] Secure credential storage via Windows DPAPI (current user)
- [x] In-app settings for library options, shortcut folders, and manual launcher path overrides
- [x] Dynamic settings rows for launcher paths and shortcut folders
- [x] Optional native library folder and shortcut generation
- [x] Standard browser user agent for outbound HTTP requests to improve compatibility

## In progress

- [ ] Broaden metadata coverage and quality across all supported storefronts
- [ ] Improve resilience and diagnostics for provider scans and network-dependent enrichment
- [ ] UI polish and accessibility refinements (keyboard flow, contrast, responsiveness)
- [ ] Documentation expansion (user and developer guides)

## Planned

### Provider coverage
- [ ] GOG Galaxy / GOG installed games
- [ ] Ubisoft Connect
- [ ] EA app
- [ ] Battle.net
- [ ] Amazon Games
- [ ] Xbox / Microsoft Store (where discoverable and launchable)
- [ ] Additional storefronts and launchers with reliable local detection

### Library & organization
- [ ] Custom/manual game entries and overrides (titles, launch targets, artwork)
- [ ] Better duplicate detection and merge rules across providers
- [ ] Incremental scan/rescan and background refresh options
- [ ] Stale artifact cleanup and library health checks

### Metadata & artwork
- [ ] More metadata sources and configurable source priority/fallback behavior
- [ ] Artwork selection controls (prefer store art, prefer remote art, manual override)
- [ ] Improved caching strategy (validation, expiry/refresh, offline behavior)

### User experience
- [ ] Enhanced filtering/sorting (tags, year, rating, recently added/played where available)
- [ ] Grid/list density options and richer detail views
- [ ] Import/export of user settings (excluding secrets)

### Packaging & distribution
- [ ] Versioned releases and installer/portable distribution options
- [ ] Automatic update checks (opt-in) with clear privacy guarantees

## Exploring

- [ ] Emulator/ROM library support in the C# app (separate provider model)
- [ ] Standalone/non-store game discovery with safe heuristics
- [ ] Plugin/provider extension model for community-maintained sources
- [ ] Cross-platform architecture research (long-term; current app is Windows-focused)

## Not planned (current scope)

- Bundling or installing third-party runtimes, storefront clients, emulators, or games
- Bypassing DRM, license checks, or platform protections
- Cloud sync/accounts as a requirement for core functionality
- Collecting telemetry by default

## Notes

Priorities may change based on stability, maintainability, and user feedback. Historical experiments and legacy implementations in this repository do not define the current roadmap unless explicitly adopted into the C# app.
