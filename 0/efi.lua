term.clear()
term.setCursorPos(1,1)
if not fs.exists("/") then error("INVALID FILESYSTEM") end
print("[BOOT]: BIOS loaded after " .. os.clock())
if fs.exists("/rom") then print("loaded base " .. os.version()) else error("ROM NOT FOUND") end
if fs.exists("/mnt") then print("found root fs") else error("No root found") end

