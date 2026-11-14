---
topic: nodejs-native-gui
date: 2026-11-14
status: draft
sources:
  - https://github.com/rogerwang/node-webkit (NW.js, historical)
  - https://www.electronjs.org/docs/latest
related:
  - ../architecture.md
---

# Node.js native GUI options

## Question

What native GUI options exist for Node.js/TypeScript that avoid a browser
rendering engine, equivalent to Python's tkinter?

## Findings

- **Electron**: cross-platform, bundles Chromium. Mature but heavy. Uses web
  technologies for UI (not truly native).
- **Neutralinojs**: lightweight, uses system WebView. Minimal footprint.
- **Wails**: Go backend + native WebView. Not Node.js.
- **node-gui / libui-node**: native widgets via libui. Lightweight but
  limited widget set and less maintained.
- **qt (node-qt)**: native Qt widgets. Heavy dependency.
- **raylib / raygui for Node**: game-loop style, not a standard desktop app.
- **terminal UI (blessed/ink)**: text-based, not a GUI.

## Conclusion

No single Node.js library matches tkinter's simplicity and native widget set.
Electron is the most mature option but bundles a browser engine. Neutralinojs
is lighter but still uses a system WebView. For a truly native (non-web) UI
in Node.js, options are limited and often unmaintained.

Decision pending: evaluate whether the web-based UI (in a native window) is
acceptable, or whether a different language/runtime is needed.