# AGENTS.md

Primary entry point for every agent working in this repository. Read this file
first, then load only the rule and skill files that match the task.

## Project

Games Library Manager is a cross-platform desktop tool written in TypeScript (ESM)
that scans storefronts, standalone games with official launchers, community
launchers, and emulator ROMs, then rebuilds an organized shortcut library.
The default library root is `D:\Games` on Windows.

It is not a package manager dependency; it uses Node.js built-ins where possible.
Do not initialize git, commit, or push unless the user explicitly asks.

## Non-negotiables

0. **Read `.opencode/rules/authority.md` first.** It is absolute and overrides
   all other guidance. The user's word is final. "Start over" means abandon all
   current code and rebuild from scratch. Never disobey.
1. **Windows PowerShell 5.1 only.** No PowerShell 7 features, no external
   modules, no `pwsh`-only syntax.
2. **No new dependencies.** No Node, Python, npm, or Git required at runtime.
3. **Never install to `C:` by default.** The tool reads and writes only the
   configured library root and explicit scan roots.
4. **`.ps1` sources stay ASCII-only.** Use `\u` escapes in regex instead of
   literal non-ASCII characters, except where a pattern is intentionally
   matching a Unicode code point.
5. **Backup first.** The first run against an unmanaged non-empty library root
   requires `-Force` and moves the old folder to a sibling backup.
6. **Idempotent output.** A second run with the same inputs must remove zero
   items and report zero stale shortcuts.
7. **Preserve real titles.** Keep apostrophes, punctuation, and meaningful
   capitalization. Strip emoji only because shortcut COM cannot save non-BMP
   names.
8. **No silent data loss.** If a game or ROM cannot be resolved, log it at
   Debug or Warn and skip it. Never guess a destructive path.

## Repository map

```text
AGENTS.md                  This entry point (also see .opencode/ for the full ecosystem).
.opencode/                 OpenCode configuration and agent ecosystem.
  opencode.jsonc           Project config: default agent and skill paths.
  .opencode/                  Agent role cards (OpenCode agents).
  rules/                   Normative project rules.
  skills/                  Repeatable procedures.
  templates/               Copy-paste scaffolds.
  context/                 Architecture, decisions, roadmap, known issues.
  README.md                How the ecosystem works.
games-library.cmd          User-facing wrapper.
games-library.ps1          Entrypoint, flags, module loading, orchestration.
config/settings.json       Default configuration.
app/                       Native .NET desktop viewer (WPF, compiled with csc.exe).
web/                       Legacy web assets (deprecated in favor of the .NET app).
src/Core/                  Shared engine.
  Common.ps1               Config, logging, names, entries, provider results.
  Discovery.ps1            Registry, drives, executables, bitness, JSON.
  Titles.ps1               Title normalization and curated overrides.
  Shortcuts.ps1            .lnk and .url creation, icons.
  Index.ps1                HTML index generation.
  Library.ps1              Root backup, folder build, manifest, stale cleanup.
src/Providers/             One file per source, plus the catalog.
  Providers.ps1            Catalog, selection, execution, merging.
  Emulators.ps1            Emulator detection and ROM matching.
README.md                  End-user documentation.
```

## Task routing

| Task | Load |
| --- | --- |
| Any task | `.opencode/rules/authority.md` first, always |
| Core scanning, discovery, shortcut, or config change | `.opencode/rules/engineering.md`, `.opencode/powershell-engineer.md` |
| Add or fix a storefront / launcher provider | `.opencode/rules/providers.md`, `.opencode/skills/add-provider/SKILL.md` |
| Emulator or ROM detection change | `.opencode/rules/emulators.md` |
| Title cleanup or filename issue | `.opencode/rules/titles.md` |
| Artwork, metadata sources, cover grid | `.opencode/rules/artwork.md`, `.opencode/skills/add-artwork-source/SKILL.md` |
| HTML library page or TypeScript desktop app | `.opencode/typescript-app-engineer.md` |
| Verify a build end to end | `.opencode/skills/verify-library/SKILL.md` |
| Portability / publish audit | `.opencode/rules/portability.md`, `.opencode/skills/publish-audit/SKILL.md` |
| Git protection | `.opencode/rules/git-protection.md` |
| Decide or record an architectural choice | `.opencode/context/decisions.md` |
| Understand current state and next steps | `.opencode/context/architecture.md`, `.opencode/context/roadmap.md` |

## Standard workflow

1. Read this file and the matching rule file. Do not skip the rule file.
2. Inspect the actual code before editing. Treat unfamiliar changes as user work.
3. Make the smallest coherent change that satisfies the request.
4. Parse-check every `.ps1` file you touched (or all of them after a refactor).
5. Run `.\games-library.cmd -DryRun` when scanning or output behavior changed.
6. Run a real build and an idempotency rerun when output paths, providers, or
   stale cleanup changed and the user has not restricted you from writing.
7. Update `README.md` and the relevant `.opencode/context/` note when behavior or
   configuration changes.

## Verification commands

Parse-check all PowerShell sources:

```powershell
$bad = 0
foreach ($f in Get-ChildItem -LiteralPath . -Filter '*.ps1' -File -Recurse) {
    $errors = $null
    [Management.Automation.Language.Parser]::ParseFile($f.FullName, [ref]$null, [ref]$errors) | Out-Null
    if ($errors) { $bad++; $f.FullName; $errors | ForEach-Object { $_.Message } }
}
"parse failures: $bad"
```

Dry run:

```powershell
.\games-library.cmd -DryRun
```

Full rebuild then idempotency check:

```powershell
.\games-library.cmd
.\games-library.cmd
```

The second run should end with `0 stale item(s) removed`, and the game and
provider counts should match the first run.

Targeted provider run:

```powershell
.\games-library.cmd -Only steam,itch -NoFolderIcons
```

## Definition of done

- All `.ps1` files parse cleanly.
- `-DryRun` completes without warnings caused by the change.
- Real build and rerun are idempotent when output behavior changed.
- New config keys have defaults in `Get-DefaultConfig` and an example in
  `config/settings.json`.
- New providers appear in the catalog, `-Only` help, and `README.md`.
- User-visible behavior is documented.
