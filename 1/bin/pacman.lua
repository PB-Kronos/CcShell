local args = { ... }

local REPO = "https://raw.githubusercontent.com/PB-Kronos/CcShell-runtime/main/pkg"

local function fetch(url)
    local h = http.get(url)
    if not h then return nil end
    local d = h.readAll()
    h.close()
    return d
end

local function resolve(pkg)
    return {
        pkg .. "/setup.lua",
        pkg .. ".lua"
    }
end

local function find(pkg)
    for _, path in ipairs(resolve(pkg)) do
        local data = fetch(REPO .. "/" .. path)
        if data then
            return path, data
        end
    end
end

local function run(code, path)
    local env = setmetatable({
        shell = shell,
        fs = fs,
        os = os,
        http = http,
        print = print,
        pairs = pairs,
        ipairs = ipairs,
        error = error,
    }, { __index = _G })

    local fn, err = load(code, "@" .. path, "t", env)
    if not fn then
        print(err)
        return
    end

    return pcall(fn)
end

local cmd = args[1]
local target = args[2]

if cmd == "-S" then
    if not target then
        print("usage: pacman -S <pkg>")
        return
    end

    local path, data = find(target)

    if not data then
        print("package not found: " .. target)
        return
    end

    print("running " .. path)
    run(data, path)

elseif cmd == "-Q" then
    print("query not implemented")

else
    print("pacman -S <pkg>")
end