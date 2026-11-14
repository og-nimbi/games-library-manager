# Known Issues

Living list of quirks and open problems. Remove an entry only when the cause is
fixed, not when it is merely hidden.

## PowerShell 5.1

- `@($genericList)` does not enumerate `List[object]`. Use `ConvertTo-Array`.
- `@($null).Count` is `1`; provider `Games` must be real empty arrays.
- WScript shortcut COM cannot save non-BMP filenames. Emoji are stripped.
- `ConvertFrom-Json` returns objects, not hashtables. Use `Get-PropertyValue`.

## Discovery

- Steam includes redistributable app `228980`; it is not a game and must be
  filtered from counts.
- Xbox `Microsoft.GamingApp` can be installed with zero games. The provider
  shortcut is still created intentionally.
- Epic leftover folders without a real uninstall record must be ignored.
- itch builds sometimes ship `python*.exe`, `nwjc.exe`, `steamcmd.exe`,
  `zsync*.exe`, and `chardetect.exe` next to the real game. The reject list must
  keep pace with new runtimes.
- All itch.io shortcuts use local paths (`.lnk`), never URL protocols, because
  many indie games (e.g. RPG Maker) do not support protocol launches.
- Some itch games are Java-only or Flash-only; resolution depends on a bundled
  or system runtime. Missing runtime means the game is skipped with a warning.

## Emulators

- Ambiguous extensions (`.iso`, `.cue`, `.chd`, `.bin`, `.zip`) require a system
  folder hint when several emulators are installed. RetroArch is the fallback.
- MAME `.zip` sets require a hint and use the ROM base name, not a path.
- PS3 and Xbox 360 folder games are only detected when RPCS3 or Xenia is
  installed.
- RetroArch shortcuts assume cores are configured; the tool does not manage
  cores.
- `scan.romRoots` defaults are best-effort. If no ROM root exists, the provider
  is silent by design.

## Titles

- Regex normalization is a balance. Prefer a curated override when a general
  rule would harm other titles.
- `Danganronpa V3` must not lose `V3`; `LoveKami -Divinity Stage-` must keep its
  trailing hyphen.

## Secrets

- DPAPI uses `CurrentUser` scope. Secrets do not roam and must be re-entered
  after a profile change or on another machine.
- A missing secret disables the related provider; it is not an error.
- `{secret:NAME}` values are resolved at runtime and must never be logged or
  written to the manifest or HTML.

## Artwork and UI

- `.ico` conversion is not implemented yet. Shortcut icons currently use an
  executable or an existing `.ico`.
- The viewer is a native TypeScript (ESM) desktop app (no browser/PowerShell).
- Theming follows system light/dark mode and accent color.
- Metadata providers are partially wired: Steam store (keyless) and VNDB (keyless)
  are implemented; SteamGridDB, Steam Web API, and IGDB (all require API
  credentials) are implemented behind config toggles and DPAPI secrets. Store art
  still takes priority. Rate limiting, caching, and negative caching are in
  place.
- For the GUI framework, research Node.js native GUI options (equivalent to
  Python's tkinter) before defaulting to a web-based renderer.
