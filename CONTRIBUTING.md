# Contributing to CcShell

## Overview

CcShell is an addon layer for CraftOS-PC. Contributions should improve reliability, clarity, or maintainability without adding unnecessary complexity.

## Before You Contribute

- Read the README.
- Check the existing wiki if you are adding or changing behavior.
- Keep changes focused.
- Prefer small, testable edits.

## Development Expectations

- Keep package installers deterministic.
- Avoid hardcoding paths unless the path is intentionally host-specific.
- Preserve compatibility where possible.
- If you remove behavior, document the removal.
- If you add a new runtime path or package rule, update the docs.

## Code Style

- Use clear names.
- Keep scripts readable.
- Prefer explicit control flow over clever shortcuts.
- Match the surrounding style of the file you are editing.

## Testing

Before opening a change, verify the relevant path in the current environment.

At minimum:

- install and remove the affected package
- check startup behavior if boot files changed
- verify any bridge or host-path change with the real configured path
- confirm the change does not break unrelated packages

## Submitting Packages

Package submissions should follow the existing package layout:

- `manifest.lua`
- `install.lua`
- `remove.lua`
- optional `upgrade.lua`

Package metadata should include:

- version
- description
- dependencies when needed

Package rules:

- Packages must install cleanly from `pkg/<name>/`.
- Package scripts should not depend on hidden manual steps unless the package is explicitly a bootstrap package.
- If a package touches host-side files, document exactly what it changes.
- If a package depends on another package, declare it in `manifest.lua`.

Before submitting a package, check:

- install works from a clean state
- remove restores the previous state as much as possible
- upgrade does not leave stale files behind
- documentation exists for any new behavior

## Pull Requests

When possible, include:

- a short summary
- what changed
- how you tested it
- any follow-up work you think is still needed

## Questions

If the right implementation is unclear, open an issue first instead of shipping an unstable package interface.

