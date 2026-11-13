# Security Policy

## Reporting a vulnerability

Please do not open public issues for security vulnerabilities. Report them
privately via the GitHub repository's "Report a vulnerability" feature, or by
email to the maintainer. Include steps to reproduce and the affected version.

## Supported versions

Only the latest version on the default branch is supported. Fixes are released
as new commits; there are no long-term support branches.

## Security considerations

- **Secrets** are encrypted with the Windows Data Protection API (DPAPI,
  `CurrentUser` scope) and stored in `%LOCALAPPDATA%\GamesLibraryManager\secrets.dat`.
  They never appear in config, manifests, logs, or generated HTML.
- **Environment variables** take precedence over the `.env` file, which is
  gitignored and never committed.
- **Path safety**: the tool refuses to delete files outside the library root,
  and stale cleanup only removes artifacts listed in the previous manifest.
- **No remote code execution**: the tool does not download or execute binaries.
- **Protocol handler**: `gameslibrary://` is registered under `HKCU` (no admin
  required) and only launches files inside the library root.
- **Network access** is limited to enabled metadata providers and respects
  configured timeouts.

## Out of scope

- Vulnerabilities in third-party stores, emulators, or games themselves.
- Issues requiring physical access to an unlocked machine.