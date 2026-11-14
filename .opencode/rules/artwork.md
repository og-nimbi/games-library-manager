# Artwork and Metadata Rules

Artwork feeds two consumers: Windows shortcut icons and the HTML library page.
They have different constraints, so keep the raw art and the rendered icon
separate.

## Source priority

1. **Store provider data first.** Steam app ids, itch `coverUrl` and
   `stillCoverUrl`, GOG/Epic image fields, and Xbox package art are already
   installed and require no network lookup.
2. **Metadata providers as fallback.** Only look up art when the primary source
   has none.
3. **Cached result last.** Never block a library build on the network.

The HTML grid is free to use raw provider art directly and does not need `.ico`.

## Supported providers

| Provider | Credentials | Notes |
| --- | --- | --- |
| Store provider data | none | Highest priority, offline |
| Steam Web API | optional key | App details, header image, capsule art |
| SteamGridDB | API key | Grids, heroes, logos, icons |
| IGDB | client id + secret | Cover art and metadata |
| Steam store page | none | Keyless scraper fallback |
| VNDB | none | Visual novel covers |
| Gaming wikis | none | Keyless fallback, last resort |

- Credentials come from config, the Windows DPAPI secret store (`{secret:NAME}`),
  or environment variables (`{env:VAR}`). They are never hardcoded.
- Use environment substitution such as `{env:STEAMGRIDDB_API_KEY}` where
  possible.
- A missing key disables that provider; it is not an error.
- Respect rate limits. Cache aggressively and never refetch unchanged entries.

## Artwork cache

```text
D:\Games\_library\artwork\
  <provider>\
    <stable-id>.<ext>
  index.json
```

- Key by provider plus stable id (Steam app id, itch game id, ROM hash/name).
- Store the original extension; do not transcode during download.
- Record source, URL, fetch time, and dimensions in `index.json`.
- Reuse cached files across runs. Delete only entries for removed games during
  stale cleanup.
- `.ico` conversion is not needed. Shortcut icons use store-provided executables.
  The GUI displays images in their native format (jpg, png, gif, webp, bmp).

## Shortcut icons

Windows `.lnk` icons use the executable's embedded icon (store-provided). No
`.ico` conversion is performed. The GUI displays images in their native format
(jpg, png, gif, webp, bmp) without conversion.

## Shortcut icons versus GUI art

Windows shortcuts (`.lnk`/`.url`) use the icon the store already provides: the
game executable's embedded icon or a store-supplied `.ico`. Do not override
them with artwork-cache images. The artwork cache (`_library/artwork/`) is for
the GUI only. `.ico` conversion, if ever needed, is an optional, config-gated
output step for cases where no store icon exists.

The viewer is a cross-platform TypeScript (ESM) desktop application. No
PowerShell, no browser-only, no Tauri. Native process invocation for launching
games. Theming follows the system (light/dark, accent color). No glassmorphism.

- The app renders a cover-art grid with search, provider filters, and sort.
- Covers come from the local artwork cache with placeholders for missing art.
- Search, filter, sort, and detail views operate on in-memory data.
- Launch games directly via native process invocation (no browser, no prompt).
- Respect system animation settings (reduced motion).
- Keep thumbnails decoded lazily and bounded, but keep the entry array, index,
  and already-viewed images resident for instant navigation.
- Persist a cache so a cold start is fast and repeat lookups never re-request
  an unchanged asset:
- Use a native desktop UI: standard window chrome, system light/dark mode,
  and system accent color. No glassmorphism, no fixed dark theme. For the GUI
  framework, research Node.js native GUI options (equivalent to Python's tkinter)
  before defaulting to a web-based renderer. Respect system animation settings
  (reduced motion).
- Performance budget: lazy-load images, cap concurrent image requests, and honor
  system animation settings (reduced motion).
- Provide a reduced-effects mode for small systems, enabled automatically when
  the browser reports limited memory or reduced motion.
- Render covers from the cache directory with a stable relative path.
- Search and filter should operate on embedded JSON, not network calls.

## Configuration shape

```jsonc
{
  "artwork": {
    "enabled": true,
    "preferStoreArt": true,
    "writeIcoIcons": true,
    "cacheDir": "_library/artwork",
    "requestTimeoutSeconds": 15,
    "providers": {
      "steamWebApi": { "enabled": true, "apiKey": "{env:STEAM_API_KEY}" },
      "steamGridDb": { "enabled": true, "apiKey": "{env:STEAMGRIDDB_API_KEY}" },
      "igdb": { "enabled": false, "clientId": "", "clientSecret": "" },
      "keyless": { "enabled": true }
    }
  }
}
```

Add defaults to `Get-DefaultConfig` and a matching example to
`config/settings.json` when this is implemented.

## Failure behavior

- Network failure means "no art this run", logged at Debug or Warn once.
- Never write a partial or corrupt image into the cache.
- Never replace working art with a failed download.
- Never ship a secret in logs, the manifest, or `index.html`.

## API and CDN protection

Store and metadata APIs are rate limited, and image CDNs block clients that
hammer them. The viewer and the artwork resolver must both treat the cache as the
primary source.

- **Disk cache is authoritative.** Downloaded art and metadata responses are
  written once with source, URL, fetch time, and an ETag or last-modified value
  when available.
- **Memory cache in front.** The viewer hydrates from the disk cache into memory
  at startup. Navigating, searching, and filtering are pure in-memory work.
- **Conditional requests only.** When a refresh is needed, send `If-None-Match`
  or `If-Modified-Since`. A `304` keeps the existing bytes.
- **Bounded concurrency.** Cap simultaneous downloads (for example 2 to 4) and
  add a small delay between requests to one host.
- **Backoff on 429/403/5xx.** Honor `Retry-After`, then exponential backoff with
  jitter. After repeated failures, disable that host for the rest of the run and
  log once.
- **Negative cache.** Remember "not found" for a game and source so the same
  miss is not retried every run.
- **Single-flight.** Coalesce duplicate requests for the same key so two cards
  never fetch the same image at once.
- **Stale-while-revalidate.** Serve cached data immediately; refresh in the
  background only when the entry is older than its TTL.
- **Offline first.** With no network, the viewer must still render the full
  library from cache and placeholders.
