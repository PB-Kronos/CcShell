# CcShell

<p align="center">
  <a href="https://github.com/PB-Kronos/CcShell/stargazers">
    <img src="https://img.shields.io/github/stars/PB-Kronos/CcShell?style=for-the-badge&color=gold" alt="Stars">
  </a>
  <a href="https://github.com/PB-Kronos/CcShell/forks">
    <img src="https://img.shields.io/github/forks/PB-Kronos/CcShell?style=for-the-badge&color=blue" alt="Forks">
  </a>
  <a href="https://github.com/PB-Kronos/CcShell/watchers">
    <img src="https://img.shields.io/github/watchers/PB-Kronos/CcShell?style=for-the-badge&color=purple" alt="Watchers">
  </a>
  <a href="https://github.com/PB-Kronos/CcShell/issues">
    <img src="https://img.shields.io/github/issues/PB-Kronos/CcShell?style=for-the-badge&color=red" alt="Open Issues">
  </a>
</p>

<p align="center">
  <strong>A CraftOS-PC based OS layer with a Linux-style package workflow, Python bridge, and host-side integration.</strong>
</p>

---

## What this is

`CcShell` is a custom runtime and package layout built on top of CraftOS-PC.  
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

### Not an OS

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
- bridge access for filesystem operations and Windows taskbar control
- startup logic that loads the `sys` layer automatically

---

## Installation

### Requirements

- Python on the host machine is only needed for the bridge features.
- Emulator releases include the Python helpers by default.

### Recommended setup

1. Download and install the latest release.
2. Run the program CraftOS-PC startup
3. Install `base` through your package flow. Optional, but recommended.
4. Install `sys` and `bridgefs` if you want the bridge features. Optional.

### Minecraft / vanilla install

If you are not using the emulator release, fetch `pacman.lua` directly:

```text
wget https://raw.githubusercontent.com/PB-Kronos/CcShell/main/pacman.lua /rom/programs/pacman.lua
```

Then use `pacman` to install the packages you want.

### Base install

The base package copies the runtime layout from the source tree. On emulator releases, the host Python helper folder is already included alongside the bundle.
```text
pacman -S base
```
Optional program trees can be forced with flags:

```text
pacman -S base --advanced --fun --http
```

### Python path configuration

The host Python folder can be changed with the normal `set` command:

```text
set python_path "C:\Users\craftos\AppData\Roaming\CraftOS-PC\python"
```

To restore the default launcher behavior, leave it blank:

```text
set python_path ""
```

The default points at the CraftOS-PC `python` folder under `%APPDATA%`.
You can also point it at any other Windows path if you want the helpers installed elsewhere.

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


---

## License

No license file is currently set in this repository.
If you plan to reuse or redistribute the project, add a license first.
