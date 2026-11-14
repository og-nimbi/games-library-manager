---
topic: gui-viewer-fixes
date: 2026-11-14
status: research
sources:
  - https://learn.microsoft.com/en-us/microsoft-edge/webview2/get-started/winforms (WebView2 WinForms, postMessage, navigation events, scripting)
  - https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/object-fit (MDN object-fit)
  - https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/object-position (MDN object-position)
  - https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/aspect-ratio (MDN aspect-ratio)
  - https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies (Execution policies)
  - https://learn.microsoft.com/en-us/dotnet/api/system.diagnostics.process.start (Process.Start)
  - https://learn.microsoft.com/en-us/dotnet/api/system.componentmodel.backgroundworker (BackgroundWorker)
related:
  - ../architecture.md
  - ../decisions.md
---

# Research: GUI viewer (no implementation yet)

This note records research only. No code changes are made from this note.
Implementation requires explicit user direction. Do not skip any section.

## 1. WebView2 host <-> web content communication

Source: Microsoft Learn, "Get started with WebView2 in WinForms apps"
(https://learn.microsoft.com/en-us/microsoft-edge/webview2/get-started/winforms), Step 10.

Findings:
- Web content posts to host via `window.chrome.webview.postMessage(...)`.
- Host receives via `CoreWebView2.WebMessageReceived` event.
- Host reads message with `args.TryGetWebMessageAsString()`.
- Host -> web content uses `CoreWebView2.PostWebMessageAsString` or
  `PostWebMessageAsJSON`.
- Web content receives host messages via
  `window.chrome.webview.addEventListener('message', event => ...)`.
- Host objects via `AddHostObjectToScript` are the legacy approach and require
  COM-visible classes; `postMessage` is the documented modern approach.
- Scripting: `CoreWebView2.ExecuteScriptAsync` runs arbitrary JS at runtime;
  `AddScriptToExecuteOnDocumentCreatedAsync` injects JS before page scripts.
- Navigation events: NavigationStarting, SourceChanged, ContentLoading,
  HistoryChanged, NavigationCompleted.

Current implementation status:
- `app/GamesLibraryViewer.cs` uses `WebMessageReceived` + `TryGetWebMessageAsString()`.
  Matches documented approach.
- `web/js/app.js` uses `window.chrome.webview.postMessage(JSON.stringify(...))`.
  Matches documented approach.
- Launch runs inside `Task.Run` to avoid blocking the UI thread.

## 2. Image filling for cover art grids and hero image

Sources:
- MDN "object-fit" (https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/object-fit)
- MDN "object-position" (https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/object-position)
- MDN "aspect-ratio" (https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/aspect-ratio)

Findings:
- `object-fit: cover` sizes replaced content to maintain aspect ratio while
  filling the element's entire content box; content is clipped if needed.
- `object-fit: contain` fits within the box (letterboxed/pillarboxed).
- `object-position` (default 50% 50%) aligns content within the box.
- `aspect-ratio` sets desired width-to-height ratio; for replaced elements
  with intrinsic ratio, `auto` uses the natural ratio.
- Initial value of object-fit is `fill` (stretches). For cover art, `cover`
  is correct.
- Applies to replaced elements (img, video). Not iframe/embed/fencedframe.

Application to current code:
- `web/js/app.js` `card()` creates `<img class="card__cover">`.
- `web/dist/app.css` defines `.card__cover`. Must inspect to confirm whether
  it sets fixed height/width and `object-fit`. Likely missing or contain.
- Hero image: `#sidebar-hero` img. Needs `object-fit: cover` + fixed height.

## 3. Provider section as tile cards

No official Microsoft documentation for "Explorer tile view" as a web standard
(it is a Windows Shell concept). Reproducing it in HTML is a styling choice.

Proposed approach (pending user direction):
- Replace the provider `<div class="chips">` pill bar with a grid of cards
  (`.provider-tile`) showing icon + name, similar to `.card` but wider.
- Each tile clickable to filter the grid by provider.
- Layout: CSS grid with `grid-template-columns: repeat(auto-fill, minmax(...))`.
- Use `object-fit: cover` for provider icons.

Files affected: `web/dist/app.css`, `web/js/app.js`, `src/Core/Index.ps1`.

## 4. Sidebar default state (no game selected)

Current code:
- `src/Core/Index.ps1` renders `#sidebar-empty` ("Select a game...") and
  `#sidebar-content` (hidden).
- `web/js/app.js` toggles visibility in `selectEntry()` / `clearSelection()`.

Required change (per user): when no game selected, sidebar shows app title +
config buttons (app cog, settings). When a game is selected, show hero +
metadata + edit cog + clear.

Implementation: restructure the empty state in Index.ps1 HTML and update
selectEntry/clearSelection in app.js.

## 5. Bundling scripts into the GUI app file system

Current layout: scripts at repo root (`games-library.ps1`, `src/`, `config/`).
Host in `app/`. User wants scripts internal to the GUI app.

Options:
- Copy script tree into `app/` (app/src, app/config, app/games-library.ps1).
- Host resolves script root as its own directory (`AppContext.BaseDirectory`)
  instead of a hardcoded repo path.
- Host exposes a `Rebuild()` method that runs the bundled script via
  `powershell.exe -ExecutionPolicy Bypass -File ...`.

Execution policy research (Microsoft Learn, about_Execution_Policies):
- `Bypass`: nothing blocked, no warnings/prompts. Designed for configurations
  where a PowerShell script is built into a larger application.
- `-ExecutionPolicy` parameter of pwsh.exe sets policy for that session only;
  stored in `$Env:PSExecutionPolicyPreference`, deleted when session closes.
- Process-scope policy does not take precedence over Group Policy.
- On non-Windows, default is Unrestricted and cannot be changed.
- The cmd wrapper already passes `-ExecutionPolicy Bypass`. The protocol handler
  command also passes it. The GUI invoking PowerShell must pass it too.

## 6. Background workers / UI responsiveness

Source: Microsoft Learn BackgroundWorker docs + WebView2 guide.

Findings:
- `BackgroundWorker` runs operations on a separate thread; reports progress via
  `ProgressChanged`, completion via `RunWorkerCompleted`.
- DoWork handler must not touch UI; communicate via events.
- Modern alternative: `Task.Run` + `async/await` with `IProgress<T>`.
- WebView2 `EnsureCoreWebView2Async` is async; navigation events are async.
- For the host: launch already uses `Task.Run`. Scanning/rebuild (if added)
  must run off the UI thread and report progress via `PostWebMessageAsJSON`.

Current host: uses `async void MainForm_Load` with await, and `Task.Run` for
launch. Matches documented async pattern.

## 7. Native launch speed

Source: Microsoft Learn Process.Start docs.

Findings:
- `Process.Start(fileName)` with a document file (e.g. .lnk) uses shell
  association (UseShellExecute=true implicitly for documents).
- "Starting a process by specifying its file name ... is similar to typing
  the file name in the Run dialog box."
- `UseShellExecute=true` requires STAThread apartment state on the calling
  thread (documented warning: MTA state conflicts with UseShellExecute).
- Current host is `[STAThread]` (Main has STAThread attribute). Good.
- `Process.Start` returns immediately; the target app (Steam, etc.) starting
  is outside our control. The observed delay is the target app, not the host.
- No optimization available without bypassing shortcuts (loses working dir/args).

## 8. Embedding resources in .NET

Source: Microsoft Learn (general knowledge, not fetched). Standard approach:
`/resource:` compiler flag or `Properties.Resources`. For WebView2, the host
loads HTML from file path (file://). No embedding needed for current design.

## 9. Master-detail sidebar pattern

No official doc fetched. Standard web pattern: sidebar shows detail for selected
item; empty state shows app-level info. Already partially implemented
(`#sidebar-empty` / `#sidebar-content`). Required: empty state shows app title +
config buttons instead of "Select a game...".

## Verification status

- postMessage launch: verified working.
- Image filling: not verified (CSS not inspected).
- Provider tiles: not implemented.
- Sidebar default state: not implemented.
- Script bundling: not implemented.
- Execution policy bypass in GUI: not implemented (host does not invoke PS yet).
- Background workers: partially (Task.Run for launch).

## 10. Storefront-specific launch methods

Source: actual code in `src/Providers/*.ps1` (verified by reading, not guessing).

Findings (each provider's game Target):
- Steam: `steam://rungameid/<appId>` (protocol URL) -> .url shortcut.
- Epic: `com.epicgames.launcher://apps/<name>?action=launch&silent=true` (protocol) -> .url.
- GOG: `goggalaxy://openGameView/<gameId>` (protocol) -> .url.
- Ubisoft: `uplay://launch/<installId>/0` (protocol) -> .url.
- Battle.net: `battlenet://<key>` (protocol) -> .url.
- Xbox: `explorer.exe shell:AppsFolder\<aumid>` (executable + args) -> .lnk.
- Amazon, EA, Hi-Rez, Legacy, Riot, Rockstar, Wargaming: the game .exe directly -> .lnk.
- Standalone: the game .exe directly -> .lnk.
- Emulators: emulator .exe + ROM args -> .lnk.
- itch.io: the game .exe (or .jar/.swf/.bat) directly -> .lnk.

Implication for the GUI:
- The GUI MUST launch the shortcut file (.lnk/.url), NOT the executable.
- The shortcut file encodes the storefront-specific protocol/target.
- Launching the .exe directly would bypass the storefront and "interfere with
  executables" (user's complaint).
- Current app.js sends `e.shortcut` (absolute shortcut path, e.g.
  "D:\\Games\\Steam\\Game.url"); host Process.Start on that path with
  UseShellExecute=true. This preserves the storefront launch method. Correct.

Verification: each provider's Target field confirmed by reading src/Providers/*.ps1.
No code changes.
