# Testing

See `agents/skills/verify-library/SKILL.md`. Minimum bar:

1. Parse-check all `.ps1` files.
2. `.\games-library.cmd -DryRun` completes without new warnings.
3. Real build + rerun is idempotent (`0 stale item(s) removed`).
4. Provider changes tested with `-Only <key> -LibraryRoot D:\GLM-test`.
5. Unknown `-Only` values exit with code 1 and a clear error.

## Portability audit

Run `agents/skills/publish-audit/SKILL.md` before publishing. Check for
drive-letter literals, personal identifiers, secrets, and generated artifacts.