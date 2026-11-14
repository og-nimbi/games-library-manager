# Getting Started

## System requirements

- **Operating system:** Windows 10 or Windows 11
- **WebView2 Runtime:** Required to render the app UI
  - Windows 11 includes it by default in most installations
  - On Windows 10, install the Evergreen WebView2 Runtime if prompted/missing
- **.NET Framework 4.x:** Required by the current app build
- **Supported storefront clients (for scanning):** Install and sign in to the storefronts you want detected (Steam, itch.io, Epic Games)

## Install / run

### Option A: Run a prebuilt app folder
1. Obtain/build the app output (see developer docs if building from source).
2. Ensure the following are present alongside `GamesLibraryViewer.exe` in the deployment folder:
   - `WebView2Loader.dll`
   - `Microsoft.Web.WebView2.Core.dll`
   - `Microsoft.Web.WebView2.WinForms.dll`
   - `config\settings.json` (bundled defaults)
   - app assets/resources as provided by the build
3. Run `GamesLibraryViewer.exe`.

### Option B: Build from source
See [../developer/building.md](../developer/building.md) for build prerequisites and steps.

## First run: what happens

When you launch the app, it performs a scan-and-generate cycle:

1. **Loads configuration**
   - Reads bundled defaults from `config\settings.json`
   - Reads user overrides from `%LOCALAPPDATA%\GamesLibraryManager\settings.json` (if present)
2. **Scans supported providers**
   - Detects installed games for supported storefronts
3. **Creates/updates library output**
   - Ensures `<LibraryRoot>\_library` exists (default `D:\Games\_library`)
   - Optionally creates provider folders and shortcuts in `<LibraryRoot>` (controlled by settings)
4. **Resolves artwork and metadata**
   - Uses provider/store data first
   - Fills missing fields via configured metadata sources when available
   - Caches downloaded artwork under `<LibraryRoot>\_library\artwork\`
5. **Generates and opens the UI**
   - Writes `index.html` and `settings.html` to `_library`
   - Copies required runtime/UI files into `_library` for local loading
   - Opens the library in the desktop app window

> **Note:** The first scan can take longer if metadata/artwork must be fetched over the network. Subsequent runs are typically faster due to caching.

## Where data is stored

### Library root (default: `D:\Games`)
- **Provider folders** (e.g. `Steam`, `itchio`, `EpicGames`-style naming as generated): optional game shortcuts
- **`_library\`**: generated UI and cache
  - `index.html` – main library view
  - `settings.html` – settings view
  - `artwork\` – cached images
  - copied app/runtime files used by the deployed view

### Per-user app data
- **User settings:** `%LOCALAPPDATA%\GamesLibraryManager\settings.json`
- **Encrypted API credentials:** `%LOCALAPPDATA%\GamesLibraryManager\secrets.dat` (Windows DPAPI, current user)

## Updating your library

The app regenerates its library view on launch (scan/build/generate flow). If you install/uninstall games or change settings (including launcher overrides), restart the app to refresh results.

## Uninstall / cleanup

To remove app data:

- Delete the app folder (binaries)
- Optionally delete user settings and secrets:
  - `%LOCALAPPDATA%\GamesLibraryManager\settings.json`
  - `%LOCALAPPDATA%\GamesLibraryManager\secrets.dat`
- Optionally delete generated library output:
  - `<LibraryRoot>\_library\`
  - provider shortcut folders created in `<LibraryRoot>` (only if you no longer want them)

> **Tip:** Back up anything important before deleting folders in your library root.
