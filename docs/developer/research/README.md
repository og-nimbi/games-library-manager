# Research log

This directory holds modular, reusable research findings. Each note is a small
Markdown file with frontmatter. Findings are referenced from user and developer
docs instead of being duplicated.

## How to add a research note

1. Create `docs/developer/research/<topic>.md`.
2. Use the frontmatter template below.
3. Add an entry to `index.md`.
4. Reference the note from the relevant user/developer doc with a relative link.

## Note template

```markdown
---
topic: short-topic-slug
date: YYYY-MM-DD
status: draft | reviewed | superseded
sources:
  - https://example.com/page
related:
  - ../providers.md
  - ../../user/artwork.md
---

# Title

## Question

What was investigated.

## Findings

Bullet points with evidence and links.

## Conclusion

What we decided and why.

## References

Links to sources.
```

## Rules

- One topic per file. Keep files short.
- Never duplicate a finding; link to the note instead.
- Update `status` to `superseded` and link the replacement when a finding
  becomes outdated.
- Research notes are committed (they are not machine-specific).