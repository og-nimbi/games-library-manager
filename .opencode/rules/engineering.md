# Engineering Rules

These constraints apply to every change in this repository.

## Runtime

- Target Node.js (latest LTS) with TypeScript (ESM). No PowerShell, no bash.
- Use only Node.js built-in modules where possible (`fs`, `path`, `os`, `child_process`,
  `crypto`, `http`). Minimize npm dependencies.
- No external runtimes required at runtime (Node.js is the runtime).
- Nothing may be installed to `C:` by default. Use `D:` for all development tools.

## Source hygiene

- TypeScript sources (`.ts`) are the primary source. Compiled output (`.js`) is
  generated, not hand-edited.
- Use ESM (`import`/`export`) exclusively. No CommonJS (`require`/`module.exports`).
- Keep one clear responsibility per module. Prefer small helpers over deep nesting.
- Use strict TypeScript (`strict: true` in tsconfig).
- Comment non-obvious logic and platform quirks. Do not narrate obvious code.

## Platform support

- The tool must work on Windows, Linux, and macOS.
- Use `os.platform()` / `process.platform` to branch platform-specific logic.
- Never assume a Windows path separator or drive letter. Use `path.join`/`path.sep`.
- Registry access is Windows-only; guard with platform checks.
- File shortcuts: `.lnk` on Windows, `.desktop` on Linux, `.app` bundle on macOS.

## Error handling

- Wrap operations that are allowed to fail in try/catch and log a useful message.
- Never swallow an exception without either logging it or deliberately treating
  it as "not installed".
- A provider must never throw out of the scan pipeline; catch and log.
- Return null or an empty result rather than an invalid object.

## Verification

- Type-check all TypeScript with `tsc --noEmit`.
- Run the scanner in dry-run mode after scan or output changes.
- Run a real build plus a rerun when output paths or stale cleanup changed.
  The rerun must report zero stale items and identical counts.
- Never claim a build works without a type check and, where relevant, an
  actual run.

## Scope discipline

- Do not refactor unrelated code while fixing a bug.
- Do not rename files, flags, or config keys without updating docs and defaults.
- Do not add a dependency to solve a problem that Node.js built-ins handle.