# Artwork and metadata

```mermaid
flowchart LR
    A[Game entry] --> B{Store art?}
    B -- yes --> C[Copy to cache]
    B -- no --> D{Metadata enabled?}
    D -- no --> E[Placeholder]
    D -- yes --> F[Try Steam store]
    F -- miss --> G[Try SteamGridDB]
    G -- miss --> H[Try IGDB]
    H -- miss --> I[Try VNDB]
    I -- miss --> J[Record negative cache]
    F -- hit --> K[Download + cache]
    G -- hit --> K
    H -- hit --> K
    I -- hit --> K
    C --> L[Viewer shows cover]
    K --> L
    J --> E
    E --> L
```

The viewer's cover art comes from store-provided images first (Steam headers,
itch covers). Missing art is fetched from metadata providers:

1. Steam store (keyless).
2. SteamGridDB (requires API key).
3. IGDB (requires client id + secret).
4. VNDB (keyless, for visual novels).

Artwork is cached under `_library\artwork\` with an `index.json`. Repeated runs
reuse the cache. Missing art is recorded as a miss. All requests are
rate-limited.

The viewer also supports a per-game settings cog that generates a patch file
applied with `-ApplyGameSettings`. See `docs/developer/providers.md`.