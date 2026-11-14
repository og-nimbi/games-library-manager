# Configuration

Games Library Manager uses a combination of bundled defaults and per-user settings.

## Configuration layers

1. **Bundled config (defaults):** `config\settings.json` (shipped with the app/source)
2. **User config (overrides):** `%LOCALAPPDATA%\GamesLibraryManager\settings.json`

On startup, the app loads bundled config first, then loads user config to apply overrides.

## Settings managed in the app

The Settings UI can update and persist user preferences, including:

- **Library root** (`libraryRoot`)
  - Default: `D:\Games`
  - Used for generated `_library` content and (optionally) provider shortcut folders
- **Native library folders** (`createLibraryFolders`)
  - When enabled: creates provider folders and game shortcuts in the library root
  - When disabled: skips folder/shortcut creation; the app can still launch games directly from the grid
- **Shortcut folders** (`scan.shortcutFolders`)
  - A dynamic list of folder paths you want tracked/configured for your environment
- **Launcher executables** (`launchers`)
  - A dynamic map/list of launcher overrides (provider key/name -> executable path)
  - A valid configured path is used **before** auto-detection; if invalid/missing, auto-detection is used as fallback
  - Common keys: `steam`, `itch`, `epic` (the app also accepts provider display-name variants when resolving)

## Bundled `config/settings.json` (overview)

The bundled config contains defaults and feature toggles used by the app. Common sections include:

- **Top-level options**: `libraryRoot`, `createHtmlIndex`, `createFolderIcons`, `removeStaleShortcuts`, `createWindowsLibrary`, etc.
- **`scan`**: scan-related paths and depth settings (e.g. `shortcutFolders`, search roots)
- **`providers`**: provider enable/disable flags (where applicable)
- **`artwork`**: artwork cache behavior (cache directory, preferences, timeouts)
- **`metadata`**: metadata provider settings and credential references
- **`launchers`**: optional manual launcher executable paths

> The exact effective behavior depends on the current app implementation. If a key is not used by a specific build, it is ignored safely.

## Launcher path overrides

Use launcher overrides when:

- A storefront client is installed in a non-standard location
- Auto-detection cannot find the launcher (e.g. versioned install folders)
- You want to explicitly control which executable is launched

### Recommendations

- Use the full path to the launcher executable (e.g. `...\steam.exe`, `...\itch.exe`, `...\EpicGamesLauncher.exe`)
- Keep entries only for launchers you need to override
- If a launcher path becomes invalid, remove or update it; the app will fall back to auto-detection when possible

## Shortcut/folder generation behavior

When **native library folders** are enabled:

- The app creates provider folders under the library root as needed
- Game shortcuts are created for detected entries (target type depends on the game/provider)
- Generated view/cache files are written under `<LibraryRoot>\_library`

When disabled:

- The app avoids creating provider/game shortcut folders
- The in-app grid remains the primary way to browse and launch detected games

## Applying changes

- Settings saved in the UI are written to the user config file.
- Most changes take effect on the **next scan/rebuild/app restart** (the UI indicates when a rebuild/restart is required).
- Restart the app after changing launcher paths, library root, or scan-related settings to ensure a full refresh.

## Resetting configuration

To reset user-specific settings:

1. Close the app.
2. Delete `%LOCALAPPDATA%\GamesLibraryManager\settings.json`.
3. (Optional) Delete `%LOCALAPPDATA%\GamesLibraryManager\secrets.dat` to remove stored API credentials.
4. Relaunch the app to regenerate defaults-based behavior.

> Resetting user settings does not remove generated files in your library root unless you delete them manually.
