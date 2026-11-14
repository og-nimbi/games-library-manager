---
name: verify-library
description: Run the full verification gate for a change and report parse, dry-run, build, idempotency, and provider results.
---

# Verify the Library

Use before reporting any behavior change as complete.

## 1. Parse check

```powershell
$bad = 0
foreach ($f in Get-ChildItem -LiteralPath . -Filter '*.ps1' -File -Recurse) {
    $errors = $null
    [Management.Automation.Language.Parser]::ParseFile($f.FullName, [ref]$null, [ref]$errors) | Out-Null
    if ($errors) { $bad++; $f.FullName; $errors | ForEach-Object { $_.Message } }
}
"parse failures: $bad"
```

Expected: `parse failures: 0`.

## 2. Dry run

```powershell
.\games-library.cmd -DryRun
```

Expected: exit code `0`, a per-provider count line, and no new warnings.

## 3. Real build and idempotency

Only when output behavior changed, and only on the configured library root.

```powershell
.\games-library.cmd
.\games-library.cmd
```

Expected on the second run: same game and provider counts, and
`0 stale item(s) removed`.

## 4. Isolated provider check

```powershell
.\games-library.cmd -Only <key> -LibraryRoot D:\GLM-test -NoFolderIcons -Force
```

Expected: only that provider is scanned, no `desktop.ini` files, and the scratch
folder can be removed safely afterwards.

## 5. Error paths

```powershell
.\games-library.cmd -Only bogus -DryRun
$LASTEXITCODE
```

Expected: exit code `1` and `ERROR: No providers matched -Only: bogus`.

## 6. Report

Record:

- Commands run and exit codes.
- Game count, provider count, stale count.
- New warnings and their exact text.
- Any check skipped and why.

Do not claim idempotency from a dry run. Do not edit code to make a check pass.
