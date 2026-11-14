# Decisions

Durable choices, newest first. Add a new entry when a choice would be expensive
to reverse. Copy `../templates/decision.md.template` for the long form.

## ADR-021: Shortcut icons use store-provided icons; artwork cache is GUI-only

- Status: accepted
- Area: artwork

Windows shortcuts (`.lnk`/`.url`) use the icon the store already provides: the
game executable's embedded icon, or a store-supplied `.ico`. The artwork cache
(`_library/artwork/`) is for the GUI only and is never converted to `.ico` for
shortcuts. This keeps shortcut creation fast and reliable, and keeps the cache
focused on display. `.ico` conversion, if ever needed, is an optional,
config-gated output step for cases where no store icon exists.

## ADR-020: TypeScript ESM desktop app; cross-platform, no PowerShell

- Status: accepted
- Area: ui

The viewer is a cross-platform desktop application written in TypeScript (ESM).
No PowerShell, no browser-only, no Tauri. Native process invocation for launching
games. Node.js is the runtime. Cross-platform on Windows, Linux, and macOS.
All development tools are installed on the D: drive.

## ADR-019: SCSS must be compiled; browsers cannot parse it

- Status: accepted
- Area: ui

Browsers do not understand SCSS, so it must be compiled to CSS before shipping.
There is no native SCSS support. The shipped artifact is therefore compiled CSS,
kept small: one file or inlined, with unused selectors removed. SCSS remains an
optional authoring convenience; if the styling stays simple, native CSS with
custom properties is acceptable and avoids the build step entirely. For a native
.NET desktop app, XAML styling is preferred over CSS.

## ADR-018: Native .NET desktop app with WinForms + WebView2

- Status: accepted
- Area: ui

The viewer is a native .NET desktop application using WinForms + WebView2. The
WebView2 runtime ships with Windows 11. Theming follows the system (light/dark
mode and accent color). Games are launched directly via the host bridge
(Start-Process, no browser prompt). No Tauri or Electron. No custom protocol
handlers.

## ADR-017: Viewer settings page manages secrets in-process

- Status: accepted
- Area: ui

The settings page is part of the native .NET desktop app. It configures secrets
and settings directly through in-process calls to the DPAPI secret store and
config writer. Secrets are never displayed; only configured/not-configured status
is shown. Credential links open the relevant provider sites in the default browser.

## ADR-016: Native Windows theming (light/dark, system accent)

- Status: accepted
- Area: ui

The app follows the system color scheme: native Windows light and dark modes
and the system accent color. Glassmorphism and a fixed dark theme are not used.
Respect system animation settings (reduced motion).

## ADR-015: Secrets use Windows DPAPI

- Status: accepted
- Area: core

API keys and other secrets are encrypted with `ProtectedData` (CurrentUser
scope) and stored in `%LOCALAPPDATA%\GamesLibraryManager\secrets.dat`, outside
the repository and the library root. Config references them as `{secret:NAME}`;
`{env:VAR}` remains supported. This avoids plaintext secrets in config,
manifests, logs, and HTML while requiring no external tooling. Secrets do not
roam and must be re-entered after a profile change.

## ADR-014: ROM folder scaffolding is opt-in

- Status: accepted
- Area: emulators

`-InitRoms -RomRoot <path>` creates a per-console ROM folder tree and exits
without scanning or building. Folder names are short canonical system names that
match the emulator hints, so ROMs are assigned without extra configuration.
Existing folders are preserved and the command is idempotent. `-DryRun` previews
without writing. The default root is the first `scan.romRoots` entry, then
`D:\ROMs`.

## ADR-013: In-memory viewer data with a persistent cache in front of APIs

- Status: accepted
- Area: ui

The viewer hydrates the library entries and artwork metadata into memory once at
startup, so search, filter, sort, and detail views never touch disk or network.
A persistent disk cache is the durable layer and the primary source for repeat
lookups. Remote requests are conditional, concurrency-limited, backed off on
`429`/`403`/`5xx`, and negatively cached, so artwork APIs and CDNs are not
overused and the library still renders fully offline.

## ADR-012: Providers may return multiple results

- Status: accepted
- Area: providers

The emulator provider emits one result per installed emulator, so
`Invoke-ProviderScans` flattens results with `@(ConvertTo-Array $result)`.
Providers that return one result are unchanged.

## ADR-011: RetroArch is the ambiguous-ROM fallback

- Status: accepted
- Area: emulators

When several installed emulators accept an extension and no system-folder hint
matches, a definition marked `Fallback` (RetroArch) wins instead of dropping the
ROM. Truly unclaimed ROMs are skipped and logged at Debug.

## ADR-010: Multi-file disc images are one game

- Status: accepted
- Area: emulators

Track files are skipped when their entry point exists (`.bin` with `.cue`/`.gdi`,
`.mdf` with `.mds`, `.img` with `.ccd`/`.cue`). When the same title exists in
several formats, keep the best-ranked dump rather than emitting duplicates.

## ADR-009: Store art first, metadata providers as fallback

- Status: accepted
- Area: artwork

Steam, itch, and other store records already carry art offline. SteamGridDB,
Steam Web API, IGDB, and keyless scrapers are only consulted when the store has
none. Credentials are optional and a missing key disables that provider.

## ADR-008: Raw art is cached; `.ico` is an output step

- Status: accepted
- Area: artwork

The cache stores original image bytes and metadata. Shortcut icons are converted
only when `writeIcoIcons` is enabled. This keeps the HTML grid able to use
`.png`/`.jpg`/`.webp` directly and keeps conversion failures non-fatal.

## ADR-007: Native .NET desktop viewer with WinForms + WebView2

- Status: accepted
- Area: ui

The viewer is a native .NET desktop application using WinForms + WebView2. The
WebView2 runtime ships with Windows 11. Games are launched directly via the
host bridge (Start-Process). No file:// loading, no browser prompts, no Tauri.

## ADR-006: Epic requires a real uninstall record

- Status: accepted
- Area: providers

Leftover Epic folders must not create an Epic provider folder or game entries.
The provider checks for a real launcher/uninstall record before scanning.

## ADR-005: Title normalization is central

- Status: accepted
- Area: titles

`New-GameEntry` calls `Get-NormalizedGameTitle`. Providers never normalize.
Curated overrides run before regex and are keyed by stable provider id.

## ADR-004: Strip emoji, keep punctuation

- Status: accepted
- Area: titles

WScript shortcut COM cannot save non-BMP names, so `Get-SafeFileName` removes
emoji and control characters. Apostrophes, colons, hyphens, and capitalization
are preserved.

## ADR-003: `.url` for protocols, `.lnk` for files

- Status: accepted
- Area: core

Protocol targets such as `steam://rungameid/...` become `.url` shortcuts and
survive install path changes. Executables and documents become `.lnk`.

## ADR-002: Manifest plus stale cleanup

- Status: accepted
- Area: core

`_library\manifest.json` records every generated artifact. A run removes only
artifacts listed in the previous manifest, so unmanaged files are never deleted.

## ADR-001: Default library root and backup-first

- Status: accepted
- Area: core

The default root is `D:\Games`. A first run against an unmanaged non-empty root
requires `-Force` and moves it to `D:\Games_backup_YYYYMMDD_HHMMSS`.
