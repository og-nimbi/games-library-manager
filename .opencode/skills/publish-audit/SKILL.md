---
name: publish-audit
description: Audit the repository for machine-specific paths, secrets, and generated artifacts before publishing to GitHub.
---

# Publish Audit

Use before creating the GitHub repository or pushing a release. Git and the
GitHub CLI may need to be installed first; they are not required to run the
application.

## Steps

## Steps

1. Run the portability grep:
   ```powershell
   Select-String -Path src\*.ps1,config\*.json -Pattern "'[A-Za-z]:\\" -AllMatches
   ```
   Expected: no hits outside documented defaults such as `libraryRoot`.

2. Search for personal identifiers:
   ```powershell
   Get-ChildItem -Recurse -File |
     Where-Object { $_.Extension -in '.ps1','.json','.md','.cmd' } |
     Where-Object { $_.FullName -notmatch '\\(agents|\.opencode)(\\|$)' -and $_.Name -ne 'AGENTS.md' } |
     Select-String -Pattern 'joshu|C:\\Users\\' -ErrorAction SilentlyContinue
   ```
   Expected: no hits.

3. Search for secrets:
   ```powershell
   Get-ChildItem -Recurse -File | Where-Object { $_.Extension -in '.ps1','.json','.cmd' } |
     Select-String -Pattern 'api[_-]?key|client[_-]?secret|token|password' -ErrorAction SilentlyContinue
   ```
   Expected: only config placeholders such as `{env:...}`.

4. Confirm no generated artifacts are committed:
   ```powershell
   Get-ChildItem -Recurse -Filter 'manifest.json' -ErrorAction SilentlyContinue
   Get-ChildItem -Recurse -Filter '*.log' -ErrorAction SilentlyContinue
   ```
   Expected: none in the repo.

5. Confirm ignored machine-specific guidance is not tracked. When git is
   available, `git status --short` must not list `AGENTS.md`, `agents/`, or
   `.opencode/`. If they appear, check `.gitignore`.

6. Parse-check every `.ps1` and run a dry run:
   ```powershell
   .\games-library.cmd -DryRun
   ```

7. Verify the config parses and has no personal roots:
   ```powershell
   (Get-Content config\settings.json -Raw) | ConvertFrom-Json | Out-Null
   ```

## Failure modes

- **Drive-letter hit in `src/`.** Replace with an env var or drive enumeration.
- **Hit in `config/settings.json`.** Move it to a documented example or env var.
- **Secret hit.** Remove it and rotate the key if it was real.
- **Generated artifact present.** Add it to `.gitignore` and delete it.

## Done when

All six steps pass and the report is attached to the release notes.
