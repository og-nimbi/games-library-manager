# Portability Rules

This project is published as a template. Nothing in the committed source may
depend on one developer's machine.

## Must not

- Hard-code a drive letter in `src/` or `config/settings.json`, except the
  documented default `libraryRoot = D:\Games`.
- Hard-code a user name, profile path, or machine-specific install location.
- Commit API keys, client secrets, or personal tokens.
- Commit generated artifacts from a real run (`manifest.json` with real paths,
  cached artwork, logs).
- Assume a store is installed at a fixed path. Use registry records, env vars,
  or drive enumeration instead.

## Must

- Prefer environment variables (`%ProgramFiles%`, `%LOCALAPPDATA%`, `%APPDATA%`,
  `%ProgramData%`, `%USERPROFILE%`) and `Get-AllFixedDriveRoots`.
- Keep official, common install paths only when they are genuinely standard, and
  still gate them behind existence checks.
- Treat `config/settings.json` as a portable template: env-based scan roots and
  no personal folders.
- Document any drive-specific example in `README.md` as an example, not a
  default.

- A local `.env` file in the repository root is gitignored and loaded at
  startup. Use `.env.example` as the template. Never commit real keys.

- The project, Node.js, and all development libraries and tools live on the `D:`
  drive. Nothing is installed to `C:` by default.
- When installing a dev tool, prefer a `D:` path and document it in
  `agents/context/known-issues.md` or the relevant skill.

Run before publishing:

```powershell
# Drive-letter literals in source or committed config
Select-String -Path src\*.ps1,src\**\*.ps1,config\*.json -Pattern "'[A-Za-z]:\\" -AllMatches

# Personal identifiers (replace with your own checks)
Select-String -Path . -Recurse -Pattern 'joshu|C:\\Users\\' -Exclude '*.ico','*.png','*.jpg'

# Secrets
Select-String -Path . -Recurse -Pattern 'api[_-]?key|client[_-]?secret|token' -Exclude '*.md'
```

Any hit must be either removed or justified in `agents/context/decisions.md`.
