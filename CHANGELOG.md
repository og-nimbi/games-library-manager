# Changelog

All notable changes to Games Library Manager are documented in this file. The
format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- Edge application-mode viewer launch (`-Open`) with app icon.
- Cover-art grid viewer with search, provider chips, sort pills, detail sidebar,
  per-game settings cog, and app settings modal.
- Store-first artwork cache (Steam headers, itch covers) with `index.json`.
- Metadata providers: Steam store (keyless), SteamGridDB, IGDB, VNDB.
- DPAPI-backed secret store with `-SetSecret`, `-RemoveSecret`, `-ListSecrets`.
- `-ApplySettings` and `-ApplyGameSettings` for merging config patches.
- `-InitRoms` per-console ROM folder scaffolding.
- `-RegisterProtocol` / `-UnregisterProtocol` / `-Launch` for `gameslibrary://`.
- `.env` loading for development API keys.
- Agent ecosystem under `agents/` and OpenCode wiring under `.opencode/`.

### Changed
- itch.io icons now use the executable icon (extracted `.ico` colors were wrong).
- Stale cleanup previews instead of deleting during dry runs.
- Executable detection rejects runtime/engine helpers and prefers 64-bit builds.

### Fixed
- Apostrophe normalization (`Sarada's Rise`).
- Version regex no longer strips bare `V3`.
- Trailing hyphens preserved (`LoveKami -Divinity Stage-`).
- `-Only` accepts comma/semicolon-separated values and reports unknown providers.
- Epic requires a real uninstall record.
- Multi-file disc images counted once.
- Ambiguous ROM extensions fall back to RetroArch.