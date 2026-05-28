local args = { ... }

local function ensure_sys()
    if not sys or not sys.fs then
        error("execute.lua wrapper is not loaded; call dofile('/bin/execute.lua') first", 0)
    end
end

local function usage()
    print("Usage: file <read|write|exists|list|readlines|mkdir|copy|move|delete|run> [args]")
end

local function run()
    ensure_sys()

    local cmd = args[1]
    if not cmd then
        usage()
        return
    end

    if cmd == "read" then
        if not args[2] then return usage() end
        local data = sys.fs.read(args[2])
        if data ~= nil then print(data) end
        return data

    elseif cmd == "write" then
        if not args[2] then return usage() end
        local data = table.concat(args, " ", 3)
        return sys.fs.write(args[2], data)

    elseif cmd == "exists" then
        if not args[2] then return usage() end
        local ok = sys.fs.exists(args[2])
        print(ok)
        return ok

    elseif cmd == "list" then
        local path = args[2] or "/"
        local listing = sys.fs.list(path)
        if listing then print(listing) end
        return listing

    elseif cmd == "readlines" then
        if not args[2] then return usage() end
        local lines = sys.fs.readlines(args[2])
        for _, line in ipairs(lines) do
            print(line)
        end
        return lines

    elseif cmd == "mkdir" then
        if not args[2] then return usage() end
        return sys.fs.mkdir(args[2])

    elseif cmd == "copy" then
        if not args[2] or not args[3] then return usage() end
        return sys.fs.copy(args[2], args[3])

    elseif cmd == "move" then
        if not args[2] or not args[3] then return usage() end
        return sys.fs.move(args[2], args[3])

    elseif cmd == "delete" then
        if not args[2] then return usage() end
        return sys.fs.delete(args[2])

    elseif cmd == "run" then
        if not args[2] then return usage() end
        return sys.fs.run(args[2])
    end

    usage()
end

return run()
