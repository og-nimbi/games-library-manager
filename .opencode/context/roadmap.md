# Roadmap

## Done

- Core scan, shortcut build, manifest, stale cleanup, HTML index.
- Windows PowerShell 5.1 compatibility and ASCII sources.
- Root backup with `-Force`.
- Provider catalog with `-Only` selection and isolated runs.
- 16 store, standalone, and custom-launcher providers.
- Executable detection that rejects runtime and engine helpers, prefers 64-bit
  builds, and scores real game binaries.
- itch.io Java, HTML, Flash, and batch launch resolution.
- Title normalization with curated overrides and apostrophe handling.
- Emulator provider with about 30 emulators, hint matching, ambiguity fallback,
  disc-pair skipping, and format dedupe.
- DPAPI-backed secret store (`{secret:NAME}`) with CLI management.
- Optional per-console ROM folder scaffolding via `-InitRoms`.
- Windows Libraries integration: per-provider/per-console folders registered in
  the Windows "Games" library.
- Dry-run safety: stale cleanup previews instead of deleting.
- Multi-result provider support.
- Artwork cache (store-first): Steam local headers and itch covers cached under
  `_library\artwork\` with an `index.json`; viewer shows covers with placeholders.
- HTML viewer: cover grid, themed search box, provider chips (filter by store), sort
  pills (name/store), app icon (favicon + header logo from assets/games.ico), detail
  sidebar (hero, metadata, play button + launch-method dropdown), per-game settings
  cog with patch generator, settings panel, in-memory hydration, lazy images, Edge
  app-mode launch.
- Native .NET desktop app with system light/dark mode and accent colors (replaces
  browser/WebView2 viewer).

## In progress

- .NET desktop viewer: functional, needs polish (theming, metadata surface).
- Metadata provider rollout (SteamGridDB, Steam Web API, IGDB need credentials).
- README coverage for metadata config and secrets.

## Next

1. Artwork cache module with store-first lookup and an `index.json`.
2. SteamGridDB, Steam Web API, and IGDB providers behind optional credentials.
3. Keyless fallbacks: Steam store, VNDB, gaming wikis.
4. Native TypeScript (ESM) desktop viewer (in development): cover grid, search,
   provider filters, sort, detail sidebar, settings. No PowerShell/browser. Uses
   system light/dark mode and accent color. For the GUI framework, research
   Node.js native GUI options (equivalent to Python's tkinter) before defaulting
   to a web-based renderer.
5. In-memory viewer data with a persistent cache, conditional requests, backoff,
   and negative caching so APIs and CDNs are never overused.
6. Metadata surface: developer, publisher, tags, year, rating for Steam games via
   Steam store (storefront is primary; metadata fills gaps). IGDB/VNDB available
   for enrichment. Sidebar displays clean labeled metadata rows.

## Later

- Per-provider include/exclude lists.
- Manual artwork overrides in config.
- ROM hash-based identification.
- Controller-friendly viewer navigation.
- Portable library mode with relative shortcut targets.

## Not planned

- Installing runtimes, emulators, or stores.
- Bundling a browser, WebView2 runtime, or any other runtime.
- Cloud sync or accounts.
- A database; JSON manifest and cache are sufficient.
