---
name: add-artwork-source
description: Add a metadata or artwork source with credentials, caching, fallback order, and no build fragility.
---

# Add an Artwork Source

Use when adding SteamGridDB, Steam Web API, IGDB, or a keyless scraper to the
artwork pipeline.

## Preconditions

- Store provider art is already used first.
- `agents/rules/artwork.md` has been read.
- The cache layout and config keys are agreed.

## Steps

1. Add a config block under `artwork.providers.<name>` with `enabled` and the
   credential fields. Default to disabled until credentials exist.
2. Read credentials from config or `{env:...}`. Never hardcode a key.
3. Implement a resolver that accepts a game entry and returns a URL plus source
   metadata, or `$null`.
4. Add caching keyed by provider plus stable id. Skip the network when a fresh
   cache hit exists.
5. Download to a temporary file, validate it is a real image, then move it into
   place. Never leave partial files.
6. Record source, URL, timestamp, and dimensions in `index.json`.
7. Wire the resolver after store art and before any keyless fallback.
8. Log a single Debug or Warn line per failed lookup, never per game.
9. Add the shortcut `.ico` path only if `writeIcoIcons` is enabled.

## Verification

Run three times:

1. No credentials: build succeeds, no errors, store art still used.
2. Valid credentials: cache fills, images validate, HTML shows covers.
3. Rerun: no duplicate downloads for fresh cache entries.

Also test an unreachable network and confirm the build still completes.

## Failure modes

- **Build hangs.** Missing or too-long timeout. Enforce
  `requestTimeoutSeconds`.
- **Rate limited.** Batch lookups, add delay, cache more aggressively.
- **Corrupt image in cache.** Validate before moving into place.
- **Secret leaked.** Remove it from logs, manifest, and HTML; rotate the key.

## Done when

Artwork is cached, attributed, optional, and never blocks a library build.
