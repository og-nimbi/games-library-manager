---
name: add-provider
description: Add or repair a storefront, launcher, or emulator provider and wire it into the catalog, config, and docs.
---

# Add a Provider

Use when the user asks to support a new storefront, official launcher, community
launcher, or emulator family.

## Inputs to gather

- Where the store records installs: registry key, receipt JSON, manifest file, or
  install folder.
- How it launches: protocol URI, executable, document file, or emulator argument.
- What identifies a game: app id, product id, receipt id, or ROM path.
- What art is already available locally.

Inspect the real machine before writing code. Do not guess paths.

## Steps

1. Create `src/Providers/<Name>.ps1` from
   `agents/templates/provider.ps1.template`.
2. Implement `Get-<Name>Provider -Config $Config`.
3. Resolve installs from the real record. If there is no install record, return
   `$null`; do not create a folder from leftover files.
4. Resolve the launch target:
   - Protocol URI when the store supports it.
   - Real game executable when it does not.
   - For engine builds, reject runtime binaries explicitly.
5. Build entries with `New-GameEntry`; let it normalize the title.
6. Return `New-ProviderResult -Key ... -DisplayName ... -Launcher ... -Games ...`.
7. Add the catalog entry in `src/Providers/Providers.ps1`.
8. Add the `providers` toggle in `Get-DefaultConfig` and `config/settings.json`.
9. Add any scan roots under `scan` with safe defaults.
10. Add the provider to the `-Only` help text in `games-library.ps1`.
11. Update `README.md`.

## Verification

```powershell
# Parse check
$e = $null
[Management.Automation.Language.Parser]::ParseFile((Resolve-Path .\src\Providers\<Name>.ps1), [ref]$null, [ref]$e) | Out-Null

# Isolated scan, no writes
.\games-library.cmd -Only <key> -DryRun -NoFolderIcons

# Scratch real run
.\games-library.cmd -Only <key> -LibraryRoot D:\GLM-test -NoFolderIcons -Force
```

Confirm: expected count, sensible titles, real launch targets, no warnings for
absent software, and a second run removes zero items.

## Failure modes

- **Folder appears for software that is not installed.** You trusted leftover
  files instead of an install record. Fix the detection.
- **Shortcut points at `python.exe` or a helper.** Tighten executable rejection.
- **Duplicate entries.** Alternate 32-bit build or a sub-launcher was selected.
  Score the real binary higher or dedupe.
- **Title mangled.** Add a narrow normalization rule or a curated override.

## Done when

Catalog, config, docs, isolated dry run, and scratch build all agree.
