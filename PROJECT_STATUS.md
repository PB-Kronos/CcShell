# Project Status

Last updated: 2026-06-18

## Current Focus

- CcShell is a CraftOS-PC addon layer, not a standalone OS.
- The main runtime pieces are `base`, `sys`, and `bridgefs`.
- Host-side Python helpers are configured through `python_path`.
- The repo is being prepared for a local web management interface and an AI chat agent package.
- A single-file `computer/0/webman/index.html` preview now exists for the dashboard UI, with a CraftOS WebSocket daemon on port `8011` and a login gate before the app is revealed.

## Major Recent Changes

- Added GitHub issue and PR templates under `.github/`.
- Added `AI_USAGE.md` to define allowed AI use and restrictions.
- Removed the obsolete `python` pacman package mapping.
- Moved package logic toward the `base` / `sys` / `bridgefs` split.
- Added and updated wiki documentation for current package and bridge behavior.
- Added governance docs:
  - `CODE_OF_CONDUCT.md`
  - `CONTRIBUTING.md`
  - `SECURITY.md`

## Current Conventions

- Package source lives under `pkg/<name>/`.
- Base package content lives under `pkg/base/src/`.
- Python helpers are host-side files, not pacman packages.
- `python_path` is a manual host path setting.
- Blank `python_path` falls back to `%APPDATA%\CraftOS-PC\python` for emulator installs.

## Open Work

- Finalize the local web management interface.
- Wire the `computer/0/webman` UI to any new backend features once the preview UI stabilizes.
- Integrate the AI chat agent package cleanly.
- Keep wiki pages in sync with the current command and package surface.
- Confirm launch and Python path behavior across emulator and Minecraft-style installs.

## Notes

- Update this file whenever you change package structure, startup behavior, or host helper layout.
