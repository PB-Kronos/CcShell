local function remove_file(path)
    if fs.exists(path) then
        fs.delete(path)
        print("Removed:", path)
    else
        print("Not found:", path)
    end
end

local function remove_startup_hook()
    local hook = 'if fs.exists("/bin/sys.lua") then dofile("/bin/sys.lua") end'
    local path = "/bin/startup.lua"

    if not fs.exists(path) then
        print("startup file not found:", path)
        return
    end

    local h = fs.open(path, "r")
    local content = h.readAll()
    h.close()

    if not content:find(hook, 1, true) then
        print("startup hook not found")
        return
    end

    local lines = {}
    for line in (content .. "\n"):gmatch("(.-)\n") do
        if line ~= hook then
            lines[#lines + 1] = line
        end
    end

    local out = fs.open(path, "w")
    out.write(table.concat(lines, "\n"))
    if #lines > 0 then
        out.write("\n")
    end
    out.close()

    print("Updated:", path)
end

remove_file("/bin/sys.lua")
remove_startup_hook()
