# Contributing

Contributions are welcome. Please follow these guidelines.

## Requirements

- Windows with Windows PowerShell 5.1.
- No new runtime dependencies. The tool must run with only built-in PowerShell.

## Development rules

- `.ps1` sources must be ASCII-only.
- Target Windows PowerShell 5.1 (no PowerShell 7 features).
- Never install anything to `C:` by default.
- Do not hard-code machine-specific paths; use environment variables or drive
  enumeration.
- Do not commit secrets, API keys, or personal paths.
- Keep changes focused; do not refactor unrelated code.

## Before submitting

1. Parse-check all `.ps1` files.
2. Run `.\games-library.cmd -DryRun` and confirm no new warnings.
3. For output changes, run a real build and a rerun; the rerun must report
   `0 stale item(s) removed`.
4. Update `README.md` and the relevant docs for user-visible changes.

## Pull requests

- Use a clear title and describe what changed and why.
- Reference any related issue.
- Keep pull requests small and reviewable.