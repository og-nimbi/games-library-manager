# FAQ

## What is Games Library Manager?

A Windows desktop app that scans supported game storefront installations, enriches games with metadata/artwork, and provides a unified library UI for browsing and launching.

## Which storefronts are supported?

The current C# app supports:

- Steam
- itch.io
- Epic Games

Additional providers may be added in future releases (see [../../ROADMAP.md](../../ROADMAP.md)).

## Does the app install or modify my games?

No. It discovers installed games and creates a browsable library view. It can optionally create shortcut folders in your configured library root, but it does not install/uninstall games or modify game files.

## Where are my settings stored?

- **User settings:** `%LOCALAPPDATA%\GamesLibraryManager\settings.json`
- **Encrypted API credentials:** `%LOCALAPPDATA%\GamesLibraryManager\secrets.dat`

Generated library files and artwork cache are stored under `<LibraryRoot>\_library` (default `D:\Games\_library`).

## Why do I need to restart the app after changing settings?

Many settings affect scanning, enrichment, launcher resolution, and generated output. Restarting triggers a fresh scan/build so the UI reflects the new configuration.

## Why are some games missing covers or metadata?

Possible reasons include:

- The provider/store did not supply that data
- External metadata services were unavailable or rate-limited
- Required API credentials are not configured
- Title matching did not find a confident result

Add credentials (if needed), restart the app, and check [troubleshooting.md](troubleshooting.md).

## Are my API keys safe?

Keys entered in Settings are stored locally using Windows DPAPI for the current Windows user (`%LOCALAPPDATA%\GamesLibraryManager\secrets.dat`). They are not stored in plain text in generated UI files. However, anyone with access to your Windows account/session may be able to use your local app configuration.

## Can I use the app without creating shortcut folders?

Yes. Disable **Native library folders** in Settings. The app can still scan and launch supported games directly from the grid.

## Why is a launcher tile marked "not found"?

Auto-detection may have failed (non-standard install path, versioned folder layout, or missing client). Add a manual launcher executable path in **Settings > Launcher executables** and restart the app.

## Does the app collect telemetry?

No built-in telemetry or analytics is enabled by default. Network requests are made to metadata/artwork services only as needed for enrichment features. See [../../PRIVACY.md](../../PRIVACY.md).

## Does this work on macOS or Linux?

The current supported application is Windows-only (WinForms + WebView2).

## Where can I report a bug or request a feature?

See [../../SUPPORT.md](../../SUPPORT.md) and [../../CONTRIBUTING.md](../../CONTRIBUTING.md). For security issues, follow [../../SECURITY.md](../../SECURITY.md).
