# Provider System

Providers are responsible for discovering games from a specific source (storefront/client/library format) and returning normalized entries that the app can enrich, display, and launch.

## Current providers

The C# app currently includes providers for:

- **Steam** (`SteamProvider`)
- **itch.io** (`ItchProvider`)
- **Epic Games** (`EpicProvider`)

Each provider encapsulates source-specific detection logic (install paths, manifests, registry/config locations, local caches) and maps discovered items into the app’s common game entry model.

## Responsibilities

A provider typically:

1. **Detect availability** of the storefront/client on the local machine
2. **Locate game/install records** (libraries, manifests, databases, receipts, etc.)
3. **Extract core fields**
   - Display title
   - Provider identifier/key
   - Stable game/app ID (when available)
   - Launch target (executable path, protocol URL, or client launch command)
   - Install directory / working directory hints
   - Icon/cover hints (if available)
4. **Return normalized entries** for downstream processing
5. **Fail gracefully** when the source is missing, partially readable, or contains unexpected data

Providers should avoid destructive behavior and should not guess in ways that cause incorrect launches or data loss.

## Game entry normalization

Discovered entries are normalized so the rest of the app can operate consistently:

- **Identity:** provider name/key and source-specific ID
- **Launch:** target, arguments, working directory, shortcut path (if generated)
- **Presentation:** title, cover/hero paths, metadata fields
- **Attribution:** developer/publisher/year/genres/rating when known

Provider-supplied metadata is treated as authoritative for those fields unless a field is empty and later filled by enrichment.

## Provider-specific notes

### Steam
- Discovers installed Steam games and resolves local/library information.
- May use Steam-provided identifiers and artwork/metadata where available.
- Launcher tile resolution can use auto-detected Steam executable or a manual override.

### itch.io
- Discovers games installed via the itch app.
- Launcher detection accounts for versioned `app-*` installations and common local paths.
- Metadata/artwork may be derived from local records and itch.io page/receipt data where accessible.

### Epic Games
- Discovers installed games from Epic Games Launcher manifests.
- Launcher detection can use known install locations or a manual override.

## Launcher resolution

Storefront launcher tiles are resolved separately from game entries:

- A configured launcher path (from user settings) is preferred when it points to an existing executable.
- If no valid override exists, provider-specific auto-detection is used.
- Resolution supports common key/name variants (e.g. `steam`/`Steam`, `itch`/`itch.io`, `epic`/`Epic Games`) to remain compatible with dynamic settings entries.

## Adding or extending a provider (guidelines)

When implementing a new provider in the C# app:

1. **Create a dedicated provider class** in `app/` following existing naming/patterns.
2. **Implement robust discovery**
   - Check multiple known locations (registry/config/default paths) where appropriate
   - Validate paths and handle missing/locked files safely
3. **Map to the shared game entry model** with consistent provider keys/names.
4. **Preserve launch correctness**
   - Prefer official/known launch targets
   - Record enough context (arguments, working directory) when required
5. **Integrate into the scan pipeline** (`Program.cs` / orchestration) and launcher resolution if applicable.
6. **Support enrichment/artwork hooks** where provider-specific IDs/URLs are available.
7. **Update configuration and UI/docs**
   - Settings (if overrides are needed)
   - User and developer documentation
8. **Test thoroughly**
   - Installed/not installed states
   - Multiple library locations
   - Missing metadata/artwork
   - Re-scan/idempotent behavior where relevant

## Error handling and logging

- Provider failures should be isolated where possible so one source does not prevent others from scanning.
- Prefer actionable diagnostics (which source/path failed and why) without exposing secrets or excessive personal data.
- Network-dependent provider enrichment should tolerate timeouts and external service variability.

## Future direction

The provider model is intended to expand to additional storefronts, standalone games/launchers, and potentially emulators/ROMs. New providers should keep detection deterministic, launches reliable, and metadata enrichment additive rather than destructive.
