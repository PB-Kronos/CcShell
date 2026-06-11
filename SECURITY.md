# Security Policy

## Supported Versions

This project is actively developed. Security fixes should be applied to the current active branch and release line used for development.

## Reporting a Vulnerability

If you find a security issue, do not open a public issue with exploit details.

Report it through the maintainers' private contact path or a private issue if that is the only available channel.

Include:

- what component is affected
- the impact
- reproduction steps
- whether the issue affects host-side files, package installation, startup, or the bridge layer

## What Counts as Security-Relevant

- host filesystem access bugs
- path traversal or path escape issues
- unintended file overwrite behavior
- bridge command injection risks
- unsafe package installation paths
- any issue that can silently run host-side code

## Response Expectations

Maintainers should:

- acknowledge valid reports promptly
- confirm the issue privately
- fix or mitigate it before public disclosure when possible

