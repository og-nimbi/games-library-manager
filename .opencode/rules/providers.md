# Provider Rules

A provider is one file in `src/Providers/` exposing one function named
`Get-<Name>Provider`. This rule defines the contract every provider must honor.

## Contract

```powershell
function Get-ExampleProvider {
    param($Config)

    # Return $null when nothing is found.
    # Otherwise return New-ProviderResult or an array of them.
    return New-ProviderResult -Key 'example' -DisplayName 'Example' `
        -Launcher $launcherEntry -Games $games -IconPath $iconPath
}
```

- `-Key` is stable, lowercase, and matches the catalog key where possible.
- `-DisplayName` is the folder name shown in the library.
- `-Launcher` is an optional `New-GameEntry` used for the `Providers\` shortcut.
- `-Games` must be a real array, even when empty. Never pass `$null`.
- `-IconPath` points to a real `.exe` or `.ico` when available.

## Registration

Every provider must be added to `Get-ProviderCatalog` in `Providers.ps1`:

```powershell
[pscustomobject]@{ Key = 'example'; DisplayName = 'Example'; File = 'Example.ps1'; Function = 'Get-ExampleProvider' }
```

`games-library.ps1` auto-loads every `.ps1` in `src/Providers/` except
`Providers.ps1`, so no import list needs editing.

## Configuration

- Add a boolean toggle under `providers` in `Get-DefaultConfig` and in
  `config/settings.json`.
- Add any scan roots under `scan` with a safe default and a matching
  `settings.json` example.
- `-Only` matching accepts the key, display name, file name, or file base name.

## Results and multiple outputs

- Most providers return one result.
- The emulator provider returns multiple results, one per installed emulator.
  `Invoke-ProviderScans` flattens results with `@(ConvertTo-Array $result)`.
- If a provider can return several folders, follow the emulator pattern.

## Launchers versus games

- A provider launcher is a shortcut to the storefront or emulator executable.
- A game entry targets a protocol (`.url`) or a real file (`.lnk`).
- Store games should prefer official protocol launch URIs when the store
  supports them, because they survive install-path changes.
- `Test-UrlTarget` decides `.url` versus `.lnk`.

## Duplicates

- `Remove-DuplicateStandaloneGames` removes standalone games already claimed by
  a store provider, using install directory and target path.
- Providers must not emit the same target twice under different names unless the
  titles genuinely differ.
- Provider-level dedupe is the provider's job. Emulators dedupe by emulator plus
  normalized title and keep the best ROM format.

## Logging

- `Debug`: scan progress, skipped candidates, "nothing found".
- `Info`: per-provider counts.
- `Warn`: a real install that cannot be resolved into a playable target.
- `Error`: reserved for failures that stop the run.
- Never log a warning for a store that is simply not installed.

## Failure behavior

- Missing launcher, missing receipt, or missing manifest means "nothing found",
  not an error.
- A leftover folder without a real uninstall/install record must not create a
  provider folder. Epic already enforces this; copy that pattern.
- Never write into the provider's own install folder.

## Documentation

- Add the provider to the `-Only` help text in `games-library.ps1`.
- Add it to the supported-sources section of `README.md`.
- Note any scan root or config key in `README.md`.
