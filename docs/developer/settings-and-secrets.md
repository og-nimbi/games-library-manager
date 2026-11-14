# Settings, Secrets, and Storage

This document describes how configuration, user preferences, and credentials are stored and applied.

## Configuration sources

### Bundled configuration
- **Path:** `config/settings.json` (relative to the app deployment/source context)
- **Purpose:** default values and baseline feature/configuration settings
- **Load order:** loaded first at startup

### User configuration overrides
- **Path:** `%LOCALAPPDATA%\GamesLibraryManager\settings.json`
- **Purpose:** persisted user-specific settings saved from the Settings UI
- **Load order:** loaded after bundled config to override defaults

## Config management (`Config.cs`)

`Config.cs` is responsible for:

- Defining configuration fields/defaults used by the app
- Loading JSON configuration from disk
- Applying patches/updates from the UI/host bridge
- Exposing resolved values to the scan/build/UI pipeline
- Saving user settings to the per-user profile location

### Typical settings domains

- **Library/output:** `libraryRoot`, folder/shortcut generation toggles
- **Scan behavior:** shortcut folders and other scan-related inputs
- **Launchers:** manual launcher executable path overrides (`launchers` map)
- **Providers/artwork/metadata:** feature toggles and provider-specific settings (as implemented)

## Launcher path overrides

Launcher overrides allow users to specify explicit executable paths for storefront clients.

- Stored in config as a `launchers` mapping (e.g. `steam`, `itch`, `epic` or compatible key variants)
- Resolved before auto-detection when the configured path exists
- Ignored/falls back to auto-detection when invalid or missing
- Managed in the Settings UI as dynamic rows (add/remove)

The runtime resolution logic should accept key/name aliases where practical to remain compatible with user-entered values and provider display names.

## Secrets management (`Secrets.cs`)

Sensitive credentials (API keys/tokens/IDs as applicable) are stored separately from regular config.

- **Storage path:** `%LOCALAPPDATA%\GamesLibraryManager\secrets.dat`
- **Protection:** Windows DPAPI with `CurrentUser` scope
- **Purpose:** protect secrets at rest on the local machine for the current user profile

### Secret lifecycle

1. User enters a value in the Settings UI
2. UI sends a host-bridge message (e.g. set/update secret)
3. Host stores/updates the encrypted secret value
4. Metadata/artwork components read secrets at runtime when needed

### Operational notes

- Secrets do not roam across machines or Windows profiles
- Deleting `secrets.dat` removes stored credentials
- UI should avoid echoing stored secret values back in plain text
- Logs and generated files must not contain secret values

## Host bridge persistence flow

The UI (WebView2) communicates with the host via messages. Relevant actions include:

- **Save config/settings:** host applies a config patch and persists user settings
- **Save secret:** host encrypts and stores the provided secret value

Host handlers must validate message structure and expected fields before applying changes.

## Generated and cached data

### Library output
- **Location:** `<LibraryRoot>\_library\` (default `D:\Games\_library`)
- **Contents:** generated `index.html`, `settings.html`, cached artwork, and copied runtime assets needed by the local view

### Optional library shortcuts
- **Location:** `<LibraryRoot>\<ProviderFolder>\...` (when enabled)
- **Contents:** `.lnk`/`.url` shortcuts and related generated artifacts

## Reset and recovery

To reset user state:

- **Settings only:** delete `%LOCALAPPDATA%\GamesLibraryManager\settings.json`
- **Credentials only:** delete `%LOCALAPPDATA%\GamesLibraryManager\secrets.dat`
- **Generated output/cache:** delete `<LibraryRoot>\_library\` (and provider folders if desired)

Restart the app to regenerate outputs using bundled defaults and any remaining user state.

## Security considerations

- Treat all config inputs from UI/messages as untrusted; validate types/paths/keys before use
- Avoid writing secrets to HTML, manifests, logs, or crash dumps where possible
- Be cautious with launcher/path overrides since they influence local process launch behavior
- Keep user data local and minimize exposure in diagnostics shared publicly
