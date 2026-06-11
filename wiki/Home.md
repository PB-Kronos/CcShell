# Home

CcShell is a CraftOS-PC addon layer that adds package management, a bridge to host-side helpers, and a more structured runtime layout.

## Start Here

- [Sys API](Sys-API.md)
- [BridgeFS](BridgeFS.md)
- [How to Make a Package](How-To-Make-A-Package.md)
- [Contributing](Contributing.md)
- [Security Policy](Security-Policy.md)

## Current Model

- `base` installs the core runtime from `pkg/base/src/`
- `sys` provides the Lua bridge wrapper
- `bridgefs` provides host filesystem helpers and the `file` debug command
- host Python helpers live in the configured `python_path`
- `python_path` defaults to `%APPDATA%\\CraftOS-PC\\python` when left blank on the emulator
