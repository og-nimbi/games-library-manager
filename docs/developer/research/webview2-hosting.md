---
topic: webview2-hosting
date: 2026-11-13
status: reviewed
sources:
  - https://learn.microsoft.com/en-us/microsoft-edge/webview2/
related:
  - ../../user/getting-started.md
---

# WebView2 hosting options

## Question

How to display the HTML viewer as a desktop app without extra runtimes?

## Findings

- Tauri v2 provides a similar shell but pulls in extra runtimes.
- .NET Framework 4.8 + WebView2 SDK requires build tooling and a loader DLL.
- Edge application mode (`msedge.exe --app=<file-uri>`) uses the Chromium/WebView2
  engine already shipped with Windows 11. No host binary, no runtime, no build
  toolchain.

## Conclusion

Use Edge app mode. It is zero-install, uses a native Windows 11 component, and
gives a windowed PWA-like experience. Settings and secrets are managed via the
PowerShell CLI.