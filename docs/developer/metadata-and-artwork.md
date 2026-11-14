# Metadata, Artwork, and Enrichment

This document describes how the app resolves metadata and artwork for discovered games.

## Goals

- Present useful, accurate game information in the library UI
- Prefer authoritative provider/store data
- Fill missing fields with external sources when available
- Cache assets locally to improve performance and reduce repeated network calls
- Degrade gracefully when credentials or network access are unavailable

## Data precedence

The enrichment pipeline follows a **provider-first** strategy:

1. **Provider/store-populated fields** (authoritative)
2. **External metadata sources** fill only missing/empty fields
3. **Artwork resolution** uses available provider/store assets first, then fallback sources/cache logic as implemented

Provider values must not be overwritten by enrichment sources.

## Components

- `Metadata.cs`
  - External metadata lookups and normalization/mapping into game entries
  - Source-specific request/parsing logic and matching safeguards
- `Artwork.cs`
  - Artwork lookup/download/cache resolution
  - Local cache path management under the library output directory
- `Http.cs`
  - Shared HTTP behavior (including a standard browser user agent for compatibility)
- `Program.cs` / orchestration
  - Invokes provider-specific and generic enrichment during the scan/build flow

## Supported enrichment sources

### Steam (store/provider data)
- Used for Steam entries to populate metadata fields and artwork references where available.
- May include title-related metadata, release/year, genres, developer/publisher, and images.

### itch.io (provider/page-derived data)
- Uses locally available itch.io data and accessible page/receipt information for installed titles.
- Can populate fields such as author/developer, publisher attribution (as applicable), year, genres, and cover imagery.

### IGDB (credentialed)
- Used for broader metadata enrichment when configured.
- Requires IGDB client credentials (Twitch application credentials).
- Matching should be conservative (e.g. exact/normalized title matching where implemented) to avoid incorrect associations.

### VNDB (keyless)
- Used primarily for visual novel titles where names match.
- Can provide metadata such as developer, release information, ratings, and cover/screenshot URLs.
- Rating scales and field formats must be mapped consistently into the app’s display model.

### SteamGridDB (credentialed, artwork/metadata fallback)
- Used to fill missing artwork (and/or related metadata where supported) when other sources do not provide suitable results.
- Requires a SteamGridDB API key.

## Credentials and configuration

- API credentials are entered in the Settings UI and stored securely via DPAPI (`Secrets.cs` / host bridge integration).
- Metadata providers that require credentials should be skipped automatically when keys are absent.
- Configuration may include metadata provider toggles/settings in bundled config; effective behavior depends on current implementation and available secrets.

See [../user/metadata-and-api-keys.md](../user/metadata-and-api-keys.md) for user-facing setup.

## Artwork caching

- Cached artwork is stored under `<LibraryRoot>\_library\artwork\` (or the configured cache path under `_library`).
- Cache keys/filenames are derived to avoid collisions and support reuse across runs.
- The UI references cached/localized paths where possible for fast rendering.

### Cache behavior considerations
- Reuse existing cached files when valid to reduce network traffic
- Handle download failures without breaking the entire scan/build
- Prefer deterministic resolution so reruns produce stable results

## Matching and correctness

Metadata enrichment is inherently fuzzy; implementations should prioritize correctness:

- Use provider IDs when available (strongest match)
- Apply strict title normalization/comparison for name-based lookups
- Avoid overwriting known-good provider data
- Skip or leave fields empty when confidence is low

Incorrect matches are worse than missing metadata.

## Network behavior and resilience

- Outbound requests should use a consistent user agent (`Http.cs`) for compatibility.
- Handle timeouts, HTTP errors, malformed responses, and partial data safely.
- Third-party APIs/pages may change; parsers should fail gracefully.
- Consider rate limits and avoid unnecessary duplicate requests (cache-first where possible).

## Extending metadata/artwork support

When adding a new metadata or artwork source:

1. **Define integration boundaries** (lookup inputs, required credentials, returned fields)
2. **Implement client/parsing logic** in the appropriate module (`Metadata.cs`, `Artwork.cs`, or a new helper)
3. **Map fields carefully** into the shared entry model with clear precedence rules
4. **Add secure credential handling** if needed (secret names, settings UI fields, host bridge wiring)
5. **Add caching and failure handling** to prevent regressions in scan/build reliability
6. **Update documentation** (user setup, developer notes, supported fields/limitations)

## Known limitations

- Not all games have complete metadata/artwork across sources
- Name-based matching can fail for ambiguous or localized titles
- External services may impose rate limits or change APIs/page structures
- Some fields (ratings, release dates, publisher attribution) vary by source semantics and may require normalization decisions
