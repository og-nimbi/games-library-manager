---
topic: scss-vs-css
date: 2026-11-13
status: reviewed
sources:
  - https://sass-lang.com/documentation/
related:
  - ../../user/artwork.md
---

# SCSS vs CSS in the browser

## Question

Can the web app load SCSS directly, or must it be compiled?

## Findings

- Browsers do not parse SCSS. There is no native SCSS support.
- Client-side SCSS compilers exist but are heavy and violate the lightweight goal.
- Native CSS custom properties cover most theming needs.

## Conclusion

Compile SCSS to CSS at development time, or skip SCSS entirely and use native CSS
custom properties. The shipped artifact is always compiled CSS (or inlined CSS).
SCSS is optional authoring tooling, not a runtime dependency.