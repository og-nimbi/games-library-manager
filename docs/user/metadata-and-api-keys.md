# Metadata and API Keys

Games Library Manager enriches detected games with metadata and artwork to improve browsing and discovery. The app prioritizes data provided by the storefront/provider and uses external sources to fill gaps.

## How enrichment works

For each game entry, the app generally follows this approach:

1. **Provider/store data first**
   - Uses data already known from the source (title, identifiers, install/launch info, and any available metadata/art)
2. **Metadata providers (fill gaps only)**
   - Queries configured metadata sources to add missing fields (e.g. developer, publisher, year, genres, ratings, images)
   - Does **not** overwrite values already supplied by the provider
3. **Artwork resolution and caching**
   - Downloads and caches images locally for reuse
   - Prefers available high-quality sources while avoiding unnecessary repeated requests

Actual results depend on the game, provider, region/language data, and whether credentials are configured.

## Metadata sources

### Provider/store sources (built-in)
- **Steam**: game metadata and artwork available from Steam data/store sources
- **itch.io**: page/receipt-derived metadata where available (e.g. creator/publisher/year/genres/cover)

### External enrichment sources
- **IGDB** (requires credentials)
  - Used for game metadata lookup with strict matching to reduce incorrect matches
- **VNDB** (keyless)
  - Used for visual novel metadata when titles match; provides fields such as developer, release info, rating, and images where available
- **SteamGridDB** (requires API key)
  - Used as an artwork/metadata fallback source when other sources do not provide suitable assets/fields

> Availability and field coverage vary by title and source.

## API keys and credentials

Some services require credentials:

- **Steam Web API key** (optional, for supported Steam-related lookups/features)
- **Steam 64 ID** (optional, for user-specific Steam features where applicable)
- **SteamGridDB API key**
- **IGDB Client ID** and **IGDB Client Secret**

### Where to get credentials

- **Steam Web API key:** https://steamcommunity.com/dev/apikey
- **Steam 64 ID:** https://steamid.io/
- **SteamGridDB API key:** https://www.steamgriddb.com/profile/preferences/api
- **IGDB (Twitch developer) Client ID/Secret:** https://dev.twitch.tv/console/apps

## Storing credentials securely

Credentials entered in the Settings UI are stored locally using **Windows DPAPI (CurrentUser scope)**:

- **Location:** `%LOCALAPPDATA%\GamesLibraryManager\secrets.dat`
- **Scope:** Encrypted for the current Windows user profile
- **Behavior:** Keys are not displayed in plain text in the UI after saving (leave fields blank to keep existing values)

### Important notes

- DPAPI-protected secrets do **not** roam automatically to other machines or Windows profiles.
- If you move to a new machine/profile, you must re-enter credentials.
- Do not share `secrets.dat`, screenshots of Settings, or logs that may contain sensitive data.

## Enabling/disabling enrichment behavior

- If a credential is missing, the corresponding provider is typically skipped automatically.
- Provider/store metadata remains available even when external enrichment is unavailable.
- Network access is required for remote lookups; cached artwork/data may still be used when available.

## Caching

- Artwork and related assets are cached under `<LibraryRoot>\_library\artwork\` (default library root: `D:\Games`).
- Caching improves performance and reduces repeated network requests.
- To force fresh downloads in troubleshooting scenarios, you can remove cached artwork files (with the app closed), then relaunch the app to regenerate.

## Privacy considerations

When enrichment runs, the app may send lookup information (such as game titles or IDs) to third-party services. See [../../PRIVACY.md](../../PRIVACY.md) for details.
