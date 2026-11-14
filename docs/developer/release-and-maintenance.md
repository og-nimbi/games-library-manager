# Release and Maintenance

This document outlines maintenance practices for the C# desktop application, including verification, documentation hygiene, and release readiness.

## Maintenance principles

- Keep the **C# app (`app/`)** as the supported source of truth
- Prefer incremental, reviewable changes over broad rewrites
- Preserve backward compatibility for user settings where practical
- Avoid committing secrets, personal data, or machine-specific artifacts
- Update documentation alongside behavior/config changes

## Pre-merge / pre-release checklist

### Build and runtime
- [ ] `app\build.cmd` completes successfully
- [ ] App launches without startup crashes
- [ ] Scan/build completes for supported providers available in test environment
- [ ] Generated `_library\index.html` and `_library\settings.html` load correctly

### Core functionality
- [ ] Library grid renders on initial load
- [ ] Search, filter pills, and sorting work as expected
- [ ] Game selection/sidebar metadata display works
- [ ] Game launch actions work for supported targets
- [ ] Launcher tiles launch storefront clients (or show expected unavailable state)

### Settings and persistence
- [ ] Settings UI saves and reloads values correctly
- [ ] Dynamic launcher path rows and shortcut folder rows add/remove/save correctly
- [ ] User settings persist to `%LOCALAPPDATA%\GamesLibraryManager\settings.json`
- [ ] Secrets persist to `%LOCALAPPDATA%\GamesLibraryManager\secrets.dat` (DPAPI, current user) and are not exposed in UI/logs

### Metadata and artwork
- [ ] Provider metadata remains authoritative (not overwritten by enrichment)
- [ ] Enrichment failures degrade gracefully (no crash, no broken UI)
- [ ] Artwork caching works and missing assets do not break rendering
- [ ] HTTP/network behavior is resilient to timeouts/errors

### Docs and repo health
- [ ] `README.md` and relevant docs updated
- [ ] `CHANGELOG.md` updated for user-visible changes
- [ ] `ROADMAP.md` adjusted if priorities/status changed
- [ ] Security/privacy implications reviewed for new features

## Versioning and changelog

- Record notable changes in [../../CHANGELOG.md](../../CHANGELOG.md) under `Unreleased` until a release is cut.
- Group entries by `Added`, `Changed`, `Fixed`, `Deprecated`, `Removed`, and `Security` as appropriate.
- When publishing releases, tag versions consistently and move `Unreleased` entries into a dated/versioned section.

## Backward compatibility notes

### User settings
- Adding new config keys should be backward-compatible (safe defaults when missing).
- When changing config shape/semantics, prefer tolerant parsing and migration-friendly behavior.
- Preserve support for common alias keys where feasible (especially launcher override keys).

### Secrets
- Secret names/keys should remain stable once exposed to users.
- If a secret key is renamed or deprecated, provide a compatibility path or clear migration guidance.

## Diagnostics and supportability

- Prefer actionable error handling and user-visible fallback states.
- Avoid logging sensitive values (API keys, tokens, secrets).
- If debug/crash artifacts are generated, ensure they are useful but sanitized where possible.
- Keep troubleshooting docs updated with known failure modes and resolutions.

## Dependency and environment maintenance

- Track compatibility with supported Windows/WebView2 environments.
- Keep WebView2 SDK references and build script assumptions documented.
- Validate changes against the project’s current compiler/toolchain constraints before relying on newer language/runtime features.

## Documentation maintenance

- **User docs (`docs/user/`)**: workflows, settings, troubleshooting, and expectations
- **Developer docs (`docs/developer/`)**: architecture, build, modules, extension points
- **Root policies**: `SECURITY.md`, `PRIVACY.md`, `TOS.md`, `SUPPORT.md`, `CONTRIBUTING.md`
- **Planning/status**: `ROADMAP.md`, `CHANGELOG.md`

Documentation should reflect the current supported implementation and clearly label experimental or future areas.

## Legacy code policy

Legacy implementations may remain in the repository for historical reference during transitions, but they should not receive new feature work unless explicitly scoped. The supported application and documentation target the C# desktop app in `app/`.
