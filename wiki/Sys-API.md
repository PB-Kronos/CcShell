# sys API

`sys` is the Lua-side bridge wrapper. It sends commands to the host Python bridge and returns plain text responses.

## Load

`sys` is loaded automatically at boot when `/bin/sys.lua` exists.

Manual load:

```lua
dofile("/bin/sys.lua")
```

## Core functions

### `sys.send(msg)`

Sends a raw command string to the Python bridge.

Returns:

- `true` when the request was posted
- `false` if the bridge is not reachable

Example:

```lua
sys.send("ping")
```

### `sys.receive()`

Reads the last response from the Python bridge.

Returns:

- response text, or
- `nil` if no response is waiting

### `sys.execute(msg, timeout)`

Sends a command and waits for a response.

- `msg` is the command string
- `timeout` is optional, default `10` seconds

Returns:

- response text, or
- `nil, "no response from python scripts"`

Example:

```lua
local data, err = sys.execute("taskbar status")
```

### `sys.last()`

Returns the last response text received from the bridge.

## File functions

### `sys.fs.read(path)`

Reads a file through the bridge.

### `sys.fs.write(path, data)`

Writes text to a file.

### `sys.fs.exists(path)`

Checks whether a path exists.

### `sys.fs.list(path)`

Lists the contents of a directory.

### `sys.fs.readlines(path)`

Reads a file and returns a Lua array of lines.

### `sys.fs.copy(src, dst)`

Copies a file or directory.

### `sys.fs.move(src, dst)`

Moves a file or directory.

### `sys.fs.replace(src, dst)`

Copies to the destination and replaces the target if it already exists.

### `sys.fs.delete(path)`

Deletes a file or directory.

### `sys.fs.mkdir(path)`

Creates a directory.

### `sys.fs.run(path)`

Runs a host-side program path through the bridge.

### `sys.fs.download(src, dst)`

Downloads a file from the repository or a URL to the host filesystem.

## Taskbar functions

### `sys.taskbar_hide()`

Hides the Windows taskbar and blocks the Windows keys while hidden.

### `sys.taskbar_show()`

Shows the Windows taskbar and restores the Windows keys.

### `sys.taskbar_toggle()`

Toggles between hidden and visible taskbar state.

### `sys.taskbar_status()`

Returns `hidden` or `visible`.

## One-shot mode

If you run `sys` with arguments, it sends the arguments directly to the bridge:

```text
sys taskbar status
sys download pkg/execute/execute.lua /bin/execute.lua
```

If you run `sys` with no arguments, it prints the command list.
