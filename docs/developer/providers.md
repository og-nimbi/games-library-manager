# Providers

See `agents/rules/providers.md` for the full contract. Summary:

- Each provider is a file in `src/Providers/` exposing `Get-<Name>Provider`.
- Register in `Get-ProviderCatalog` in `Providers.ps1`.
- Add a config toggle and any scan roots.
- Return `New-ProviderResult` or `$null`.
- The emulator provider returns multiple results (one per emulator).

## Adding a provider

Follow `agents/skills/add-provider/SKILL.md`. Key steps: inspect real install
records, resolve the real executable (not runtime helpers), return a valid result,
wire catalog + config + docs, test with `-Only <key>`.

## itch.io build formats

Native exe, then `.jar`, Java launcher script, Flash player + `.swf`, HTML entry
point, raw `.swf`. See `agents/rules/providers.md`.