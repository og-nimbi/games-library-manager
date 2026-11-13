---
topic: artwork-cache
date: 2026-11-13
status: reviewed
sources: []
related:
  - ../../user/artwork.md
  - ../providers.md
---

# Artwork cache strategy

## Question

How to resolve and cache cover art without blocking builds or overusing APIs?

## Findings

- Store-provided art (Steam headers, itch covers) is available offline and
  should be used first.
- Remote metadata providers fill gaps, behind config toggles and credentials.
- Caching by provider + stable id with negative caching avoids repeat misses.
- Rate limiting and backoff prevent CDN blocks.

## Conclusion

Store-first resolution, then metadata fallbacks. Cache original bytes under
`_library\artwork\` with an `index.json`. Record misses. All requests are
throttled. Artwork is for the GUI only; shortcut icons use store-provided icons.