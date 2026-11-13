# Privacy Policy

Games Library Manager is a local tool. It does not collect, transmit, or store
any personal data on remote servers.

## What the tool does

- Reads installed-program records from the Windows registry and storefront
  manifests on your machine.
- Reads game folders and emulator ROM folders that you configure.
- Writes shortcut files and an HTML index into the library folder you choose
  (default `D:\Games`).
- Stores API credentials, if you provide them, encrypted with the Windows Data
  Protection API (DPAPI, current-user scope) in
  `%LOCALAPPDATA%\GamesLibraryManager\secrets.dat`.

## Network access

Network requests happen only when a metadata provider is enabled. They contact
the configured provider (Steam store, SteamGridDB, IGDB, VNDB, etc.) to fetch
cover art. No telemetry, analytics, or usage data is sent. You can disable all
network access by setting `metadata.enabled` to `false` in `config/settings.json`.

## Third parties

When metadata providers are enabled, your IP address and the game titles or IDs
being looked up are sent to those providers under their own privacy policies.
Games Library Manager does not control how those providers handle that data.

## Your control

- All data stays on your machine. Delete the library folder and the
  `%LOCALAPPDATA%\GamesLibraryManager` directory to remove everything.
- Secrets can be removed with `games-library.cmd -RemoveSecret <name>`.

## Contact

Open an issue in the project's GitHub repository for privacy questions.