---
topic: dpapi-secrets
date: 2026-11-13
status: reviewed
sources:
  - https://learn.microsoft.com/en-us/dotnet/api/system.security.cryptography.protecteddata
related:
  - ../../user/secrets.md
---

# DPAPI for secret storage

## Question

How to store API keys on Windows without extra tools or plaintext config?

## Findings

- `System.Security.Cryptography.ProtectedData` is available in .NET Framework 4.x.
- `DataProtectionScope.CurrentUser` ties encryption to the current user profile.
- No master password or external tooling required.

## Conclusion

Use DPAPI to encrypt secrets into `%LOCALAPPDATA%\GamesLibraryManager\secrets.dat`.
Config references them as `{secret:NAME}`. Secrets never appear in config,
manifests, logs, or HTML. Secrets do not roam and must be re-entered after a
profile change.