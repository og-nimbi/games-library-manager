# Configuration

`config/settings.json` controls the library root, provider toggles, scan roots,
and custom entries. It is merged with the defaults, so you only need to list
entries you want to change.

## Key settings

```json
{
  "libraryRoot": "D:\\Games",
  "createHtmlIndex": true,
  "createFolderIcons": true,
  "removeStaleShortcuts": true,
  "providers": { "steam": true, "itch": true, "emulators": true },
  "scan": {
    "extraGameRoots": [],
    "standaloneSearchRoots": ["%ProgramFiles%", "%ProgramFiles(x86)%", "%LOCALAPPDATA%\\Programs"],
    "standaloneDepth": 4,
    "romRoots": ["D:\\ROMs"],
    "romDepth": 5,
    "emulatorRoots": ["D:\\Emulators"]
  },
  "customEntries": [],
  "customLaunchers": [],
  "customLaunchMethods": [],
  "gameOverrides": []
}
```

## Extra game roots

Use `scan.extraGameRoots` for standalone games in non-standard folders. Each
root is checked both as a game folder and as a parent folder containing games.

## ROM and emulator roots

Point `scan.romRoots` at your ROM folders and `scan.emulatorRoots` at portable
emulator installs. Standard installs are still detected through program files and
uninstall records.

## Custom entries and launchers

See the README for `customEntries` and `customLaunchers` examples. Use
`customLaunchMethods` to add alternate launch options to a game.