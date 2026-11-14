# Title Rules

Titles flow through one central function, `Get-NormalizedGameTitle`, called by
`New-GameEntry` in `Common.ps1`. Do not normalize titles inside individual
providers.

## Pipeline order

1. **Curated override.** Exact published titles win before any regex.
2. **Locale apostrophes.** Normalize `[\u00B4\u2018\u2019\u02BC]` to ASCII `'`.
3. **Emoji removal.** `Remove-Emoji` strips non-BMP surrogate pairs, variation
   selectors, joiners, and BMP symbol blocks. This is required because Windows
   shortcut COM cannot save non-BMP names.
4. **Version and build suffix cleanup.** Remove trailing `v0.28.1`, `v0281`,
   `Version 1.2`, and similar build markers.
5. **Metadata suffix cleanup.** Remove targeted storefront suffixes, not
   arbitrary trailing words.
6. **Whitespace and punctuation tidy.** Collapse repeated spaces and trim.
7. **Safe filename conversion.** `Get-SafeFileName` removes `<>:"/\|?*`, control
   characters, reserved device names, and trailing dots; caps length at 120.

## Hard rules

- **Never strip apostrophes.** `Sarada's Rise` is correct.
- **Never strip a bare `V3`.** `Danganronpa V3` must remain intact.
- **Preserve trailing hyphens only when they are part of the published title.**
  Cosmetic trailing hyphens (e.g. `LoveKami -Divinity Stage-`) are removed.
- **Normalize " - " separators to ": " in display titles.** Shortcuts replace
  ":" with " -" because Windows filenames cannot contain ":".
- **Preserve capitalization** unless the store publishes it differently.
- **Preserve punctuation** such as `-`, `:`, `!`, `?`, and `&`.
- **Do not title-case everything.** Use the published title.

## Curated overrides

Overrides are a fallback for regex over-aggression, not a general tool. Add one
only when a real installed title is mangled.

| Id | Published title |
| --- | --- |
| Steam `421670` | `CUPID - A free to play Visual Novel` |
| Steam `1577420` | `Love Sucks: Night One` |
| Steam `1719310` | `Love Sucks: Night Two` |
| itch `1185708` | `Relicts of Aeson` |

Overrides must be keyed by stable provider id, never by the already-mangled name.

## Adding a normalization rule

1. Reproduce the bad output with a real installed title.
2. Add the narrowest regex that fixes it.
3. Confirm it does not alter `Danganronpa V3`, `LoveKami -Divinity Stage-`, or
   any title containing an apostrophe.
4. Prefer adding a curated override when a general regex would risk other
   titles.

## Filenames versus display names

- `Name` is the display title.
- The shortcut file name is derived with `Get-SafeFileName`.
- Collisions are resolved by `Get-UniqueBaseName`, producing `Title (2)`.
- Never include a full path in `Name`.

## Verification

Run a dry run and inspect the created shortcut names. For a title-specific fix,
confirm the expected `.lnk`/`.url` name exists and the character codes are
correct, for example ASCII `39` for an apostrophe.
