# Building and Running

This document describes how to build and run the C# desktop app from source.

## Prerequisites

### Required
- **Windows 10/11**
- **Microsoft Edge WebView2 Runtime**
- **.NET Framework developer tools / C# compiler (`csc.exe`)**
  - Common path: `C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe`
- **Microsoft.Web.WebView2 SDK** (assemblies + loader DLL)
  - Default path expected by `app\build.cmd`: `D:\tools\WebView2SDK`
  - Required contents (typical):
    - `build\native\x64\WebView2Loader.dll`
    - `lib\net462\Microsoft.Web.WebView2.Core.dll`
    - `lib\net462\Microsoft.Web.WebView2.WinForms.dll`

### Optional
- Installed storefront clients for end-to-end scan testing (Steam, itch.io, Epic Games)
- API credentials for metadata/artwork enrichment testing

## Build

From the repository root:

```cmd
cd app
build.cmd
```

### What `build.cmd` does

- Compiles the WinForms/WebView2 app into `GamesLibraryViewer.exe`
- References WebView2 assemblies and required .NET Framework assemblies
- Copies runtime dependencies/assets into `app\` (e.g. WebView2 DLLs, icon, settings script as configured)

A successful build prints:

```text
BUILD OK
```

## Run (development/local)

After building:

1. Run `app\GamesLibraryViewer.exe` (or the deployed copy produced by your workflow).
2. The app will:
   - load config
   - scan supported providers
   - generate `_library` UI/cache/output in the configured library root
   - launch the desktop window

### Configuration during development

- **Bundled defaults:** `config\settings.json`
- **User overrides:** `%LOCALAPPDATA%\GamesLibraryManager\settings.json`
- **Secrets:** `%LOCALAPPDATA%\GamesLibraryManager\secrets.dat`

Use a test library root if you do not want to write to your normal library path.

## Deployment notes

A runnable deployment should include at minimum:

- `GamesLibraryViewer.exe`
- `WebView2Loader.dll`
- `Microsoft.Web.WebView2.Core.dll`
- `Microsoft.Web.WebView2.WinForms.dll`
- `config\settings.json` (and any required config assets)
- UI/runtime assets expected by the app (icon, settings script if loaded externally)

The app also copies/generates runtime view files into `<LibraryRoot>\_library` during execution.

## Troubleshooting build issues

### `WebView2 SDK not found`
- Verify `D:\tools\WebView2SDK` exists or update `SDK` in `app\build.cmd` for your local environment.
- Do not commit machine-specific path changes unless the project standardizes them.

### `csc.exe` not found
- Install/repair .NET Framework developer/build tools.
- Update the `CSC` path in `app\build.cmd` if needed for your system.

### Compilation errors
- Ensure you are building the current `app/` sources together as expected by `build.cmd`.
- Check for API/signature mismatches after refactors (HTML generator, config, providers, metadata).
- Keep changes compatible with the project’s current compiler target/toolchain.

### Runtime issues after build
- Confirm WebView2 Runtime is installed.
- Confirm all WebView2 DLLs are present beside the executable.
- Check generated `crash.txt` (if produced) and sanitized logs/console output.

## Testing checklist (manual)

- [ ] Build completes (`app\build.cmd`)
- [ ] App starts and renders library UI
- [ ] Provider scan results appear for installed supported storefronts
- [ ] Search/filter/sort and sidebar selection work
- [ ] Game and launcher launch actions work
- [ ] Settings save and persist across restart
- [ ] Manual launcher overrides resolve correctly
- [ ] Metadata/artwork enrichment behaves as expected (with and without credentials)
- [ ] No secrets or personal data included in logs/screenshots shared externally
