# Contributing

See the repository-level [CONTRIBUTING.md](../CONTRIBUTING.md) for the full contribution guide.

## Package Submissions

Packages should live under `pkg/<name>/` and usually include:

- `manifest.lua`
- `install.lua`
- `remove.lua`

Optional:

- `upgrade.lua`
- helper files

Package submissions should clearly state:

- what the package installs
- whether it touches host files
- what it depends on
- whether it requires `sys` or `bridgefs`
