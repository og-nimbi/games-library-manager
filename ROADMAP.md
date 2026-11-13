# Roadmap

Public roadmap for Games Library Manager. Items are grouped by status; completed
work moves to the changelog.

## Done

- Core scan, shortcut build, manifest, stale cleanup, HTML index.
- Windows PowerShell 5.1 compatibility and ASCII sources.
- Root backup with `-Force`.
- Provider catalog with `-Only` selection and isolated runs.
- Storefront, standalone, and custom-launcher providers.
- Executable detection that rejects runtime and engine helpers and prefers
  64-bit builds.
- itch.io Java, HTML, Flash, and batch launch resolution.
- Title normalization with curated overrides and apostrophe handling.
- Emulator provider with about 30 emulators, hint matching, ambiguity
  fallback, disc-pair skipping, and format dedupe.
- DPAPI-backed secret store (`{secret:NAME}`) with CLI management.
- Optional per-console ROM folder scaffolding via `-InitRoms`.
- Dry-run safety: stale cleanup previews instead of deleting.
- Multi-result provider support.
- Artwork cache (store-first): Steam headers and itch covers cached under
  `_library\artwork\` with an `index.json`.
- HTML viewer: cover grid, themed search box, provider chips, sort pills, detail
  sidebar, per-game settings cog, app icon, Edge app-mode launch.
- Metadata providers: Steam store (keyless), SteamGridDB, IGDB, VNDB, with
  caching, rate limiting, and negative caching.
- `.env` loading for development API keys.

## In progress

- Metadata provider rollout (SteamGridDB, Steam Web API, IGDB need credentials).
- README coverage for metadata config and secrets.

## Next

1. Verify IGDB and SteamGridDB cover lookup with real credentials.
2. Keyless fallback: gaming wikis.
3. Dependency-free multi-size `.ico` conversion with graceful fallback.
4. Metadata surface: developer, publisher, genre, release year in entries and
   viewer.
5. Polish: app icon, window size, single-instance, settings patch apply.