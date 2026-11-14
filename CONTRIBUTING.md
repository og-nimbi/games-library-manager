# Contributing to Games Library Manager

Thanks for your interest in contributing. This document explains how to propose changes, report issues, and submit pull requests for the current C# desktop app.

## Project scope (current)

The supported application is the **C# WinForms + WebView2** desktop app in `app/`. Documentation and changes should target this implementation.

Legacy scripts/prototypes may exist in the repository for historical reference, but they are not the primary runtime and should not be extended unless a maintainer explicitly requests it.

## Ways to contribute

- **Report bugs** with clear reproduction steps and environment details
- **Suggest features** with a concrete use case and proposed behavior
- **Improve documentation** (user guides, developer docs, troubleshooting, screenshots/diagrams)
- **Submit code changes** for fixes, performance, UX, or maintainability

Please search existing issues/discussions before opening a new one.

## Before you start

- Read [README.md](README.md), [docs/user/README.md](docs/user/README.md), and [docs/developer/README.md](docs/developer/README.md).
- For larger changes, open an issue or proposal first to align on scope and approach.
- Keep changes focused and avoid unrelated refactors in the same PR.

## Development setup

1. Use **Windows 10/11** with the **WebView2 Runtime** installed.
2. Ensure the **.NET Framework C# compiler** (`csc.exe`) is available (commonly at `C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe`).
3. Ensure the **WebView2 SDK** is available at the path expected by `app\build.cmd` (default: `D:\tools\WebView2SDK`) or update the build script locally for your environment (do not commit machine-specific paths).
4. Build from `app\`:

   ```cmd
   cd app
   build.cmd
   ```

See [docs/developer/building.md](docs/developer/building.md) for details.

## Coding guidelines

- **Match existing style and architecture** in `app/` (C# targeting the project’s current compiler/toolchain constraints).
- Prefer **small, reviewable changes** with clear behavior.
- **Do not add new runtime dependencies** or package managers unless discussed and approved.
- **Do not commit secrets**, API keys, personal data, or machine-specific absolute paths.
- Preserve user-visible behavior unless the change explicitly intends to modify it; update docs when behavior/config changes.
- Handle failures safely: avoid destructive actions, avoid silent data loss, and provide actionable errors/logs where appropriate.

## Testing and verification

Before submitting a PR:

- [ ] Build succeeds: `app\build.cmd`
- [ ] App launches and the affected flow works (scan, browse, launch, settings, metadata/artwork, etc.)
- [ ] No regressions in unrelated areas you touched
- [ ] Documentation updated for user-facing or developer-facing changes

Include manual test notes in the PR (what you ran, environment, and results).

## Pull requests

- Use the PR template and complete the checklist.
- Describe **what** changed and **why**.
- Include screenshots/GIFs for UI changes when practical.
- Keep commit history and diffs understandable (squash/rebase as requested by maintainers).

## Issue reports

- Use the YAML issue forms in `.github/ISSUE_TEMPLATE/`.
- For bugs: include reproduction steps, expected vs actual behavior, Windows/WebView2/app version, and sanitized logs.
- For security issues: follow [SECURITY.md](SECURITY.md) and **do not** report vulnerabilities publicly.

## Documentation contributions

- User docs live in `docs/user/`
- Developer docs live in `docs/developer/`
- Keep docs accurate to the current implementation, with examples and troubleshooting where helpful.

## Code of Conduct

By participating in this project, you agree to follow [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
