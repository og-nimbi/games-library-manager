# Emulator Rules

`src/Providers/Emulators.ps1` detects installed emulators, scans ROM roots, and
emits one provider result per emulator. These rules keep detection predictable
and non-destructive.

## Definitions

Each emulator is a hashtable in `Get-EmulatorDefinitions`:

```powershell
@{
    Key             = 'dolphin'          # stable id, used in provider key emu-dolphin
    Name            = 'Dolphin'          # display name and folder name
    UninstallPattern = '(?i)^Dolphin'    # registry DisplayName match
    ExeNames        = @('Dolphin.exe')   # candidate executable names
    ExePaths        = @('%ProgramFiles%\Dolphin\Dolphin.exe')
    Extensions      = @('.iso', '.rvz')  # accepted ROM extensions
    Hints           = @('(?i)(^|\\)(gamecube|gc|wii)(\\|$)')
    ArgPrefix       = '-e'               # optional argument prefix
    RequireHint     = $false             # true for MAME .zip
    Fallback        = $false             # true only for RetroArch
    ArgumentStyle   = 'rom-name'         # optional, used by MAME
}
```

## Installation detection

Search order, first hit wins:

1. Explicit `ExePaths` with environment expansion.
2. Store install candidates for `<Name>\<exe>` and `Emulators\<Name>\<exe>`.
3. Uninstall registry records whose `DisplayName` matches `UninstallPattern`.
4. An executable index built from `scan.emulatorRoots`.

An emulator is "installed" only when a real executable file exists. A leftover
data folder with no executable is not installed.

## ROM scanning

- Roots come from `scan.romRoots`. When empty, safe defaults are probed:
  `D:\ROMs`, `D:\Roms`, `D:\Emulation\roms`, `D:\Emulators\roms`,
  `%USERPROFILE%\ROMs`, `%USERPROFILE%\Documents\ROMs`.
- Depth comes from `scan.romDepth`, default `5`.
- If no ROM root exists, return `$null` and log at Debug. Do not warn.
- If no supported emulator is installed, return `$null` and log at Debug.

## Matching

1. Build an extension map from installed emulators only.
2. Skip track files that belong to a multi-file disc image:
   `.bin` with a sibling `.cue`/`.gdi`, `.mdf` with `.mds`, `.img` with
   `.ccd`/`.cue`.
3. Prefer an emulator whose `Hints` match a system folder in the path.
4. Otherwise, if only one installed emulator accepts the extension, use it.
5. For non-ambiguous extensions, use the first candidate.
6. For ambiguous extensions with no hint, use the `Fallback` emulator
   (RetroArch). If none exists, log at Debug and skip. Never guess.
7. `RequireHint` emulators such as MAME are excluded unless a hint matches.

## Duplicate ROM formats

The same title can exist as `.chd` and `.cue`. Dedupe per emulator plus
normalized title, keeping the highest-ranked format:

```text
chd > rvz > gcz > wbfs > cso > iso > nsp > xci > gdi > ccd > cue > mds > pbp >
3ds > cci > vpk > pkg > default > bin > mdf > img
```

Track files are ranked lowest and normally skipped earlier anyway.

## Folder-based games

- PS3: a folder containing `PS3_GAME` becomes an RPCS3 entry targeting that
  folder.
- Xbox 360: a folder containing `default.xex` becomes a Xenia entry.
- These are only scanned when the matching emulator is installed.

## Arguments

- Default: `"<rom path>"`, quoted.
- `ArgPrefix`: `-e "<rom path>"` (Dolphin, Cemu, xemu DVD path).
- `ArgumentStyle = 'rom-name'`: pass only the ROM base name (MAME).
- Working directory is the emulator's own folder.

## Output

- One provider result per emulator that actually has entries.
- Key is `emu-<key>`, display name is the emulator name.
- Launcher is a `Providers\` shortcut to the emulator executable.
- Game icon is the emulator executable unless a better icon exists.
- Deterministic order: definitions are emitted in catalog order.

## Verification

Use a synthetic tree rather than a real ROM collection when testing:

```powershell
# Create Emulators\<Name>\<exe> stubs and a ROMs tree, then call:
Get-EmulatorProvider -Config @{ scan = @{ romRoots = @($roms); emulatorRoots = @($emu); romDepth = 6 } }
```

Check hints, ambiguity fallback, disc-pair skipping, and format dedupe.
