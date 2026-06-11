# How to make a package

Packages live in `pkg/<name>/`.

## Required files

At minimum, a package should have:

- `manifest.lua`
- `install.lua`
- `remove.lua`

Optional:

- `upgrade.lua`
- extra Lua helpers

## Manifest format

`manifest.lua` returns a table:

```lua
return {
  version = "1.0",
  desc = "Package description",
  dependencies = { "base" },
}
```

Supported dependency formats:

- a single string
- an array of strings
- an array of tables with fields like `name`, `package`, `pkg`, or `[1]`

## Install script

`install.lua` runs when the package is installed.

Typical responsibilities:

- copy files into the runtime
- create directories
- verify installation
- print progress messages

## Remove script

`remove.lua` should undo what `install.lua` did.

Example responsibilities:

- delete installed files
- clean up startup hooks
- remove directories only if they were created by the package

## Package dependencies

If your package requires another package, declare it in `manifest.lua`.

Example:

```lua
return {
  version = "1.0",
  desc = "My addon package",
  dependencies = { "base", "sys" },
}
```

Pacman will try to install dependencies first.

## Updating a package

If your package has `upgrade.lua`, pacman can use it during upgrade.

If not, upgrade usually falls back to remove + reinstall behavior.

## Host Python helpers

If your package needs host-side Python files:

- place the files under `python/`
- make sure the user’s `python_path` points to the correct host folder
- document any host-side behavior clearly

## Example package structure

```text
pkg/example/
  manifest.lua
  install.lua
  remove.lua
  upgrade.lua
```
