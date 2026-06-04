# CcShell-runtime

<p align="center">
  <a href="https://github.com/PB-Kronos/CcShell-runtime/stargazers">
    <img src="https://img.shields.io/github/stars/PB-Kronos/CcShell-runtime?style=for-the-badge&color=gold" alt="Stars">
  </a>
  <a href="https://github.com/PB-Kronos/CcShell-runtime/forks">
    <img src="https://img.shields.io/github/forks/PB-Kronos/CcShell-runtime?style=for-the-badge&color=blue" alt="Forks">
  </a>
  <a href="https://github.com/PB-Kronos/CcShell-runtime/watchers">
    <img src="https://img.shields.io/github/watchers/PB-Kronos/CcShell-runtime?style=for-the-badge&color=purple" alt="Watchers">
  </a>
  <a href="https://github.com/PB-Kronos/CcShell-runtime/issues">
    <img src="https://img.shields.io/github/issues/PB-Kronos/CcShell-runtime?style=for-the-badge&color=red" alt="Open Issues">
  </a>
</p>

<p align="center">
  <strong>A CraftOS-PC based OS layer with a Linux-style package workflow, Python bridge, and host-side integration.</strong>
</p>

---

## What this is

`CcShell-runtime` is a custom runtime and package layout built on top of CraftOS-PC.  
It is designed to make the CraftOS shell feel more like a small operating system:

- boot-time shell customization
- package installation with `pacman`
- optional ROM program trees by computer type
- host-side Python bridge helpers
- Windows integration for external tools and file handling
- a path toward a lightweight Linux-like addon stack for CraftOS-PC

The repo is split into:

- `pkg/` - package installers and package metadata
- `source/` - runtime source tree that gets installed into CraftOS-PC
- `python/` - host-side Python scripts used by the bridge
- `computer/` - live per-computer runtime data used for testing

---

## Features

- `pacman`-style package install, remove, upgrade, and query
- package metadata through `manifest.lua`
- automatic dependency handling
- optional program-tree installs:
  - `pocket`
  - `turtle`
  - `advanced`
  - `fun`
  - `http`
- host Python tree installed alongside `base`
- bridge access for filesystem operations and Windows taskbar control
- startup logic that loads the `sys` layer automatically

---

## Installation

### Requirements

- CraftOS-PC on Windows
- Python installed on the host machine
- access to this repository or a clone of it

### Recommended setup

1. Clone this repository into your CraftOS-PC data folder.
2. Make sure the `source/` tree is the install source for `base`.
3. Install `base` through your package flow.
4. Install `sys` and `bridgefs` if you want the bridge features.

### Base install

The base package copies the runtime layout from the source tree and installs the Python bridge files into the host `python/` directory.

Example:

```text
pacman -S base
```

Optional program trees can be forced with flags:

```text
pacman -S base --advanced --fun --http
```

### Updating the host Python tree

The `python` mapping is a special pacman target that refreshes the host Python scripts from `source/py/`.

Example:

```text
pacman -S python
```

---

## Usage

### Boot flow

The runtime loads `sys` at startup when available.  
That gives the shell access to the bridge API without extra manual setup.

### `sys`

`sys` is the main Lua-side bridge API.

Examples:

```lua
sys.execute("ping")
sys.fs.read("C:/Users/yourname/Desktop/test.txt")
sys.fs.write("C:/Users/yourname/Desktop/test.txt", "hello world")
sys.taskbar.hide()
sys.taskbar.show()
```

If you run `sys` with no arguments, it prints the available commands.

### `file`

`file` is the filesystem debug helper exposed by `bridgefs`.

Examples:

```text
file read C:/Users/yourname/Desktop/test.txt
file list C:/Users/yourname/Desktop
file download pkg/execute/execute.lua /bin/execute.lua
```

### Package installation

The package tree is meant to stay small and explicit:

- `base` installs the core runtime
- `sys` installs the Lua bridge layer
- `bridgefs` installs file helpers
- `fun` and `http` add optional ROM program trees

---

## Notes

- This project is Windows-first.
- The host Python bridge is part of the runtime, not a user-facing feature.
- `bridgefs` is treated as an addon to `sys`, not a standalone layer.
- The repository evolves quickly, so package boundaries may be adjusted when the layout improves.

---

## What This Is

This project is not strictly a full operating system in the traditional sense.  
It is better described as an addon layer for CraftOS-PC that makes the shell, package flow, and host integration behave more like a lightweight OS environment.

The goal is to extend CraftOS-PC with:

- a more structured boot process
- package-managed runtime components
- host-side Python helpers
- Windows integration where it is useful
- a cleaner, Linux-like workflow for shell users

So while it behaves like an OS in practice, the actual model is:

- CraftOS-PC remains the base
- this repository adds the runtime layer on top
- packages and helpers extend that layer over time

---

## License

No license file is currently set in this repository.
If you plan to reuse or redistribute the project, add a license first.
