# Web assets

Source for the library viewer. The PowerShell generator consumes the compiled
output in `dist/`.

## Layout

```text
web/
  scss/        Modular SCSS partials (authoring only).
  js/          Viewer JavaScript.
  dist/        Compiled CSS/JS shipped with the library.
  README.md
```

## Build

Browsers cannot parse SCSS, so compilation to CSS is mandatory:

```sh
sass scss/app.scss dist/app.css --style=compressed
```

Prefer inlining the compiled CSS into `index.html` to avoid an extra request on
`file://` loads. If the styling stays simple, skip SCSS entirely and use native
CSS custom properties.

`sass` is a development dependency only. The shipped library needs no compiler,
no Node, and no network access.

## Usage rules

- Partials are small and purpose-specific. Import only what a view needs.
- No whole-framework pulls. No large generated CSS from loops.
- Keep the compiled output small; remove unused selectors.
- The page must work from `file://` and inside WebView2.
- Search, filter, sort, and detail views operate on the in-memory entry array.
- Covers come from the local artwork cache; never request the same asset twice.
