# UI Generation and Host Bridge

The app uses **WebView2** to render a locally generated HTML/CSS/JS interface inside a **WinForms** host window. This document covers UI generation, runtime loading, and host communication.

## UI architecture

- **Generated UI:** `HtmlGenerator.cs` produces `index.html` (library) and `settings.html` (settings)
- **Static/runtime scripts:** `web/js/settings.js` (source) and copied runtime variants used by the generated settings page
- **Host window:** WinForms form hosting a `WebView2` control
- **Bridge:** WebView2 messaging/host integration for privileged local actions

## Generated pages

### Library page (`index.html`)
Responsibilities include:
- Rendering the game grid/cards and artwork
- Search, provider filter pills, and sorting controls
- Details/sidebar presentation for selected games
- Launcher tiles for storefront clients
- Client-side interactions and launch requests sent to host

### Settings page (`settings.html`)
Responsibilities include:
- API credential inputs (saved securely via host)
- Dynamic launcher executable path rows (add/remove/save)
- Dynamic shortcut folder rows (add/remove/save)
- Library root and native folder/shortcut toggles
- Posting configuration updates to the host

## UI generation flow

During a scan/build run:

1. Providers are scanned and entries are enriched
2. `HtmlGenerator` serializes/embeds required data and renders HTML documents
3. Files are written to `<LibraryRoot>\_library\`
4. Required runtime assets (exe/DLLs/icon/scripts as applicable) are copied so the library can be opened locally
5. The host navigates WebView2 to the generated `index.html`

## Host bridge

The host enables the UI to request local operations that cannot/should not be performed directly by web content.

### Common message actions
- **`launch`**: request the host to start a game/launcher target
- **`setSecret`**: store or update an encrypted credential value
- **`setConfig`**: apply and persist user configuration changes

### Bridge implementation notes
- WebView2 receives messages from the page (e.g. JSON payloads via `postMessage`)
- Host parses and validates message content before acting
- Host performs local operations (process start, config save, DPAPI secret storage)
- Errors should be handled safely and surfaced appropriately without leaking secrets

## Security and validation considerations

- Treat all UI-originated messages as untrusted input
- Validate action names, expected fields, and value types
- Normalize and verify paths before launching or saving
- Avoid command injection/shell interpretation issues; launch targets directly where possible
- Do not log or persist secret values in plaintext
- Restrict actions to the app’s intended capabilities

## Styling and UX notes

- The UI is currently implemented with generated/embedded styles and scripts (not a separate frontend build pipeline)
- Keep layout responsive and avoid overflow/clipping regressions in settings forms
- Maintain accessible labels/placeholders and clear feedback for save actions
- Ensure the grid renders on initial load without requiring user interaction

## Extending the UI

When adding UI features:

1. Update `HtmlGenerator.cs` for markup/CSS/embedded script changes
2. Update `web/js/settings.js` (and any copied runtime locations) for settings interactions
3. Add/adjust host-bridge handlers for new actions (with validation)
4. Verify data serialization from C# to JS is correct for all supported .NET/JSON behaviors in use
5. Rebuild and test in the deployed `_library` context (not just source files)

## Debugging tips

- Reproduce issues against the generated files in `<LibraryRoot>\_library` to confirm deployment/runtime behavior
- Check browser/devtools-style diagnostics available through WebView2 (if enabled in your environment/build)
- Validate that `settings.js` and generated HTML are the versions actually loaded by WebView2
- Confirm host message handlers receive and parse the expected payload shapes after UI changes
