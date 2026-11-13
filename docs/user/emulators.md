# Emulators and ROMs

Installed emulators are detected from their executables, install records, and
configured emulator roots. Each emulator with recognizable ROMs gets its own
folder and a launcher shortcut in `Providers\`.

## Supported emulators

Dolphin, Cemu, PCSX2, RPCS3, DuckStation, PPSSPP, melonDS, DeSmuME, Citra,
yuzu, Ryujinx, mGBA, Snes9x, Project64, Mupen64Plus, Flycast, redream, xemu,
Xenia, Vita3K, Cxbx-Reloaded, FCEUX, Mesen, Nestopia, Kega Fusion, Mednafen,
BizHawk, ScummVM, MAME, and RetroArch.

## ROM folder scaffolding

```bat
games-library.cmd -InitRoms -RomRoot D:\ROMs
```

Creates 27 per-console folders. Existing folders are preserved.

## Disambiguation

Ambiguous extensions (`.iso`, `.cue`, `.chd`, `.bin`, `.zip`) are assigned
only when a system folder name matches an emulator, or when only one emulator
can run that format. RetroArch is the fallback. Use system-named subfolders
(`PS2`, `GameCube`, `Wii`, `Switch`, `MAME`) to disambiguate.

## Notes

- RetroArch shortcuts assume cores are configured; the tool does not manage cores.
- PS3 folders containing `PS3_GAME` and Xbox 360 folders containing `default.xex`
  are also detected.