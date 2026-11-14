# Developer Documentation

This section documents the current **Games Library Manager** implementation: a Windows desktop application built with **C#**, **WinForms**, and **WebView2**.

> **Important:** Legacy PowerShell scripts/prototypes may exist in the repository history/tree, but they are not part of the supported application. New development should target the `app/` C# codebase.

## Contents

1. [Architecture overview](architecture.md)
2. [Building and running](building.md)
3. [Project structure](project-structure.md)
4. [Provider system](providers.md)
5. [Metadata, artwork, and enrichment](metadata-and-artwork.md)
6. [Settings, secrets, and storage](settings-and-secrets.md)
7. [UI generation and host bridge](ui-and-host-bridge.md)
8. [Release and maintenance](release-and-maintenance.md)
9. [Research notes](research/README.md) (background/exploratory material)

## Development goals

- **Reliable local scanning** of supported storefronts
- **Safe defaults** (no destructive behavior without intent, no silent data loss)
- **Provider-first data** with optional enrichment to fill gaps
- **Local-first UX** with cached assets and in-app settings
- **Maintainable, dependency-light** implementation compatible with the current build toolchain

## Quick start (developers)

```cmd
cd app
build.cmd
```

After a successful build, run `GamesLibraryViewer.exe` from the output/deployment context used by your workflow. See [building.md](building.md) for prerequisites and deployment notes.

## Contributing

- Read [../../CONTRIBUTING.md](../../CONTRIBUTING.md)
- Follow [../../SECURITY.md](../../SECURITY.md) for vulnerability reporting
- Use the issue/PR templates under `.github/`
