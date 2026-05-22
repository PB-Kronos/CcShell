local args = { ... }

if #args < 2 then
    print("Usage: mount <source> <target>")
    return
end

local src = args[1]
local target = args[2]

local ok, err = fs.mount(src, target)

if not ok then
    print("Mount failed: " .. tostring(err))
else
    print("Mounted " .. src .. " -> " .. target)
end