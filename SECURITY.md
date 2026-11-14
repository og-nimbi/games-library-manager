# Security Policy

## Supported versions

Games Library Manager is under active development. Security fixes are provided for the latest available code/build on the default branch and the most recent release (when releases are published).

| Version / state | Supported |
| --- | --- |
| Latest release | Yes (when available) |
| Latest default-branch build | Best effort |
| Older releases/builds | No |

## Reporting a vulnerability

If you believe you have found a security vulnerability, **do not open a public issue**.

Please report it privately using one of the following methods (in order of preference):

1. **Private vulnerability reporting** on the repository host (e.g. GitHub Security Advisories), if enabled.
2. **Direct contact with the maintainers** through a private channel listed by the repository owner.

When reporting, include as much of the following as possible:

- A clear description of the issue and potential impact
- Affected component(s) and file paths (if known)
- Steps to reproduce or a proof of concept
- Environment details (Windows version, app build/version, WebView2 runtime version)
- Any suggested mitigations

Please avoid including secrets, API keys, or personal data in reports. If sensitive data is required to demonstrate the issue, describe it and provide it only through a secure/private channel.

## What to expect

- **Acknowledgment:** We aim to acknowledge reports within a reasonable time.
- **Assessment:** Reports will be triaged to confirm impact, scope, and affected versions.
- **Remediation:** Fixes will be prioritized based on severity and exploitability.
- **Disclosure:** Coordinated disclosure is preferred. Public details should be shared only after a fix or mitigation is available, or by mutual agreement.

## Security considerations

This project includes functionality that can:

- Read local system and application data to discover installed games and launchers
- Make outbound network requests to metadata/artwork providers
- Store user-provided API credentials encrypted with Windows DPAPI (CurrentUser scope)
- Launch local executables/shortcuts/protocol targets on user action

Users should treat downloaded builds and configuration changes with the same caution as any software that can access local files and launch programs.

## Out of scope (examples)

The following are generally not considered security vulnerabilities in this project:

- Issues requiring physical access to an unlocked user session (beyond documented DPAPI scope limitations)
- Social engineering or phishing unrelated to the app’s behavior
- Vulnerabilities in third-party services, storefront clients, or metadata providers
- Misconfiguration caused by intentionally setting unsafe local paths or launcher targets

If you are unsure whether an issue is in scope, report it privately and we will assess it.
