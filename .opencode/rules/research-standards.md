# Research Standards

These rules apply to every agent. They are non-negotiable.

## No guesswork

- Never guess how an API, library, protocol, file format, or OS feature works.
  If you are not certain, research it first.
- Never fabricate function names, parameter names, registry keys, file paths,
  JSON fields, HTTP endpoints, or command-line flags. Verify against official
  documentation or the actual code.
- Never assume a default value, default path, or default behavior without
  checking. Defaults differ between versions and platforms.
- Never "try it and see" as a substitute for understanding. A failed attempt
  that modifies state is worse than no attempt.

## Research first

- Before implementing anything that depends on an external system, fetch the
  official documentation and read it. Do not rely on memory or training data.
- Before using a library, API, or tool, verify its version, its supported
  platforms, and its current API surface. APIs change; old examples rot.
- Before writing a regex or parser, verify the input format against real data.
- Before choosing a file format or protocol, verify that the target platform
  supports it and how.
- Before claiming a feature works, run it and observe the result. "It should
  work" is not evidence.

## Sources

- Prefer official documentation (Microsoft Learn, vendor docs, RFCs, man pages).
- Prefer the version of the documentation that matches the version in use.
- When documentation is missing or contradictory, state the uncertainty
  explicitly. Do not fill gaps with plausible-sounding invention.
- Record the source URL and the date checked in the relevant research note or
  decision.

## Verification

- Every claim about behavior must be backed by a test, a run, or a
  documentation quote.
- Every new function must be exercised before it is reported as working.
- Every config key must be checked against the actual parser/merger.
- Every path must be checked against the actual filesystem.
- If you cannot verify, say so. Do not mark work done.

## Prohibited

- Do not invent flags, options, or parameters that "should" exist.
- Do not invent file formats, registry keys, or protocol schemes.
- Do not invent default values or fallback behavior.
- Do not copy-paste code from examples without understanding and verifying it.
- Do not claim a library supports a feature without checking its docs.
- Do not assume a command succeeded because it returned no error; check the
  output and the resulting state.