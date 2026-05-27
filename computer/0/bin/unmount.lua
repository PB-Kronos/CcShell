local args = { ... }

if #args < 1 then
    print("Usage: umount <target>")
    return
end

local target = args[1]

local ok, err = fs.unmount(target)

if not ok then
    print("Unmount failed: " .. tostring(err))
else
    print("Unmounted " .. target)
end