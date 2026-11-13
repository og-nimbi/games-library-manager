# Troubleshooting

- **Parse errors**: run the parse-check snippet in `AGENTS.md`.
- **Unknown provider in -Only**: check spelling; see the provider list in
  `-Help`.
- **No ROMs found**: set `scan.romRoots` in `config/settings.json`.
- **Missing Java/Flash runtime**: install Java or Ruffle, or use a build with a
  bundled runtime.
- **Artwork not showing**: check network access and provider toggles; missing
  art is recorded as a miss and not retried.
- **Secrets not resolving**: ensure `{secret:NAME}` matches a stored secret
  (`-ListSecrets`).

For more, see `agents/context/known-issues.md` (developer-facing).