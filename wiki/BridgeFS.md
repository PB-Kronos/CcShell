# BridgeFS

`bridgefs` is the host-side filesystem layer used by the Python bridge.

It is an addon to `sys`, not a standalone user feature.

## What it does

- reads and writes files on the host machine
- lists directories
- creates directories
- copies, moves, replaces, and deletes files
- downloads files from the repository or from URLs

## Host path rules

The bridge supports host paths:

- `/something` resolves under the CraftOS-PC root
- `C:/...` or `D:/...` writes directly to that drive
- relative paths are rooted to the CraftOS-PC directory

## Python path configuration

The host helper folder is controlled by `python_path`.

- blank `python_path` uses `%APPDATA%\CraftOS-PC\python` on emulator releases
- a full Windows path can be set manually

Example:

```text
set python_path "C:\Users\craftos\python"
```

## Download behavior

Downloads accept either:

- a full URL
- a repository-relative path

Examples:

```lua
sys.fs.download("pkg/bridgefs/file.lua", "/bin/file.lua")
sys.fs.download("https://example.com/file.txt", "C:/Temp/file.txt")
```

## Debug command

The `file` command is the Lua-side debug wrapper for bridgefs:

```text
file read <path>
file write <path> <data>
file exists <path>
file list [path]
file readlines <path>
file mkdir <path>
file copy <src> <dst>
file move <src> <dst>
file replace <src> <dst>
file delete <path>
file run <path>
file download <src> <dst>
```
