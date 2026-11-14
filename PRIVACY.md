# Privacy Policy

_Last updated: 2026-11-14_

This Privacy Policy describes how Games Library Manager ("the app") handles information when you use it.

## Summary

- The app runs locally on your Windows device.
- The app does **not** require an account and does **not** include built-in telemetry or analytics by default.
- The app reads local game/library information to build your library view and may contact third-party metadata/artwork services when needed.
- API credentials you provide are stored locally and encrypted for the current Windows user using DPAPI.

## Information the app accesses locally

To function, the app may access and process local data such as:

- **Installed game data** from supported storefronts/launchers (e.g. Steam, itch.io, Epic Games), including titles, install locations, identifiers, and launch targets
- **Configuration and settings** (bundled config and user settings)
- **Library output** you choose to generate (e.g. shortcuts, generated HTML files, cached artwork) in your configured library root
- **Local application data** used by the app (e.g. user settings and encrypted secrets stored under `%LOCALAPPDATA%\GamesLibraryManager\`)

This information is used to scan, organize, display, enrich, and launch your games.

## Information stored on your device

The app may store the following locally:

- **User settings:** `%LOCALAPPDATA%\GamesLibraryManager\settings.json`
  - Includes preferences such as library root, shortcut folders, and launcher path overrides.
- **Encrypted secrets:** `%LOCALAPPDATA%\GamesLibraryManager\secrets.dat`
  - Stores API keys/credentials you enter (e.g. SteamGridDB, IGDB) encrypted with Windows DPAPI (`CurrentUser` scope).
- **Library data and cache:** `<LibraryRoot>\_library\` (default library root is `D:\Games`)
  - Generated UI files, copied runtime assets, and cached artwork/metadata-related artifacts as applicable.

Secrets are not intended to be written into generated UI files. However, you are responsible for protecting your device, user profile, and any exported/shared files.

## Network requests and third-party services

When metadata/artwork enrichment is enabled or available, the app may send requests to third-party services to retrieve information such as game metadata, cover art, screenshots, ratings, and related content. Depending on configuration and detected games, this may include:

- **Steam** storefront/community endpoints (for Steam-related data/artwork)
- **itch.io** pages/endpoints (for installed itch.io titles and assets)
- **IGDB** (requires API credentials)
- **VNDB** (keyless)
- **SteamGridDB** (requires API key)

These requests may include data necessary to perform a lookup (for example, a game title, storefront/app identifier, or other query parameters). Third-party services may receive standard network information such as your IP address and user-agent as part of normal HTTP communication, and they handle data according to their own privacy policies and terms.

## How information is used

Information accessed or retrieved by the app is used to:

- Discover and list games in your library
- Display covers, metadata, and storefront/launcher actions
- Launch games and launchers at your request
- Save your preferences and optional credentials
- Cache results locally to improve performance and reduce repeated lookups

## Sharing and selling of data

- The app does **not** sell your personal information.
- The app does **not** share your library data with the project maintainers by default.
- Data is only transmitted to third-party services when the app makes requests needed for metadata/artwork enrichment or related functionality you use.

## Data retention and control

Because data is stored locally, you control retention by managing files on your device. You can:

- Remove user settings: delete `%LOCALAPPDATA%\GamesLibraryManager\settings.json`
- Remove stored credentials: delete `%LOCALAPPDATA%\GamesLibraryManager\secrets.dat`
- Remove generated library/cache data: delete `<LibraryRoot>\_library\` (and any generated provider folders/shortcuts you no longer want)

Uninstalling/removing the app binaries does not automatically remove user data stored in your profile or library root.

## Security

The app uses Windows DPAPI (CurrentUser scope) to encrypt stored API credentials on disk. DPAPI protection is tied to your Windows user profile; other users or machines cannot decrypt the secrets without access to that profile context, but anyone with access to your unlocked account/session may be able to use the app and its configured data.

No method of storage or transmission is 100% secure. Use caution when sharing logs, screenshots, or configuration files.

## Children's privacy

The app is a general-purpose library manager and is not directed to children. It does not knowingly collect personal information from children.

## Changes to this policy

This Privacy Policy may be updated as the app evolves. Changes will be reflected in this file with an updated "Last updated" date.

## Contact

For privacy questions or concerns, please open an issue in the repository (without including sensitive information) or contact the repository maintainers through the project’s published channels.
