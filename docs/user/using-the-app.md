# Using the App

This guide covers the main screens and interactions in Games Library Manager.

## Main window

The app opens a desktop window hosting the library UI. The interface is generated locally and loaded from your library’s `_library` folder.

## Library grid

The **game grid** displays all detected games as cards.

- **Cover art:** Shown when available; cached locally for faster loading.
- **Game details:** Click a game card to open the **details sidebar**.
- **Play/launch:** Use the card’s launch action (or sidebar action, depending on UI state) to start the game.

The grid loads automatically on startup and shows all games by default.

## Search, filters, and sorting

At the top of the library view:

- **Search**: Type to filter games by title/text in the current view.
- **Filter pills (providers/stores)**: Narrow the grid to a specific storefront/provider. Use **All** to show everything.
- **Sort**: Change ordering (e.g. by name/provider) using the available sort controls.

> Filters affect which games are shown in the grid. They do not launch storefront clients.

## Details sidebar

Selecting a game opens a sidebar with available metadata, such as:

- Title and provider/store
- Developer / publisher (when known)
- Release year, genres/tags (when available)
- Rating (when available)
- Hero/cover imagery (when available)

Empty fields are hidden to keep the view clean. Metadata quality depends on provider data and configured enrichment sources.

## Launchers section

The **Launchers** section contains tiles for detected/configured storefront clients.

- Clicking a launcher tile **launches the storefront client** (e.g. Steam, itch.io, Epic Games Launcher).
- Launcher availability depends on auto-detection and/or manual launcher path overrides in Settings.
- The Launchers section does **not** include an "All" tile and does not act as a grid filter.

## Settings

Open **Settings** from the gear/control in the UI to manage:

- **Metadata providers / credentials**: Store API keys securely for enrichment sources (where required)
- **Launcher executables**: Add one or more manual launcher paths as fallbacks when auto-detection fails
- **Native library folders**: Enable/disable shortcut/folder generation and configure the library root
- **Existing shortcut folders**: Maintain a list of shortcut folders used by your setup

Changes are saved to your user settings profile and typically apply on the next library rebuild/app restart (as indicated in the UI).

See [configuration.md](configuration.md) and [metadata-and-api-keys.md](metadata-and-api-keys.md).

## Launch behavior and permissions

- Launch actions are initiated by you from the UI.
- The desktop host starts the selected game target, shortcut, or launcher executable locally.
- If a target is missing, moved, or invalid, launching may fail; check launcher paths, storefront installation state, and library settings.

## Tips

- If a game appears without cover art or metadata, configure API keys (if applicable) and restart the app to re-run enrichment.
- If a launcher tile is missing or not found, add a manual launcher executable path in Settings.
- If you prefer not to create folders/shortcuts in your library root, disable native library folder creation (the app can still launch directly from the grid).
