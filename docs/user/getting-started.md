# Getting started

## Quick start

```bat
games-library.cmd -DryRun
games-library.cmd -Force
```

- `-DryRun` scans and reports without writing anything.
- `-Force` is required the first time, because `D:\Games` already exists and
  was not created by this tool. The old folder is moved to a sibling backup
  such as `D:\Games_backup_20261113_143000`.

After the first run:

```bat
games-library.cmd
games-library.cmd -Open
```

`-Open` opens `_library\index.html` in an Edge application window.

## Requirements

- Windows with Windows PowerShell 5.1 (built in).
- No Node, Python, Git, or npm required at runtime.

## Options

```text
-LibraryRoot <path>   Library folder. Defaults to config libraryRoot (D:\Games).
-Config <path>        Settings file. Defaults to config\settings.json.
-DryRun               Scan and report without writing files.
-Open                 Open the HTML index or library folder when done.
-Force                Back up and replace an unmanaged non-empty library root.
-NoIndex              Skip _library\index.html.
-NoClean              Keep shortcuts from the previous run.
-NoFolderIcons        Skip desktop.ini folder icons.
-Only <providers>     Run only selected providers, e.g. steam,itch,standalone.
-InitRoms             Create a per-console ROM folder structure and exit.
-RomRoot <path>       Target for -InitRoms.
-SetSecret <name>     Store an API key securely (DPAPI) and exit.
-RemoveSecret <name>  Remove a stored secret and exit.
-ListSecrets          List stored secret names.
-ApplySettings <file>  Merge a config patch and rebuild.
-ApplyGameSettings <file>  Merge a per-game patch and rebuild.
-RegisterProtocol     Register the gameslibrary:// handler.
-UnregisterProtocol   Remove the gameslibrary:// handler.
-Help                 Show built-in help.
```

## Library layout

```text
D:\Games\
  Providers\          storefront and emulator launcher shortcuts
  Steam\              Steam game shortcuts (.url)
  itch.io\            itch.io game shortcuts (.lnk)
  Dolphin\            emulator ROM shortcuts (.lnk)
  _library\
    manifest.json
    index.html
    artwork\          cached cover images
    last-run.log
```

See [Configuration](configuration.md) for scan roots and provider toggles.