-- pacman.lua (GitHub mode package manager)

local REPO = "https://raw.githubusercontent.com/PB-Kronos/CcShell-runtime/main/pkg"
local DB_PATH = "/var/pacman.db"

-- =========================
-- Utilities
-- =========================

local function fetch(url)
    local h = http.get(url)
    if not h then return nil, "Failed to fetch: " .. url end
    local data = h.readAll()
    h.close()
    return data
end

local function ensureDB()
    if not fs.exists(DB_PATH) then
        local f = fs.open(DB_PATH, "w")
        f.write("{}")
        f.close()
    end
end

local function loadDB()
    ensureDB()
    local f = fs.open(DB_PATH, "r")
    local data = f.readAll()
    f.close()
    return textutils.unserialize(data) or {}
end

local function saveDB(db)
    local f = fs.open(DB_PATH, "w")
    f.write(textutils.serialize(db))
    f.close()
end

-- =========================
-- Execution environment
-- =========================

local function runPackage(code, name, ...)
    local env = {
        fs = fs,
        shell = shell,
        os = os,
        http = http,
        textutils = textutils,
        term = term,
        paintutils = paintutils,
        colors = colors,
        vector = vector,
        sleep = sleep,
        print = print,
        pairs = pairs,
        ipairs = ipairs,
        tostring = tostring,
        tonumber = tonumber,
        error = error,
	table = table,
	pkg = pkg,
    }

    local fn, err = load(code, "@" .. name, "t", env)
    if not fn then
        return false, err
    end

    return pcall(fn, ...)
end

local function runRemote(path, ...)
    local code, err = fetch(REPO .. "/" .. path)
    if not code then
        return false, err
    end
    return runPackage(code, path, ...)
end

-- =========================
-- Package operations
-- =========================

local function install(pkg, ...)
    print("Installing package:", pkg)

    local ok, err = runRemote(pkg .. "/install.lua", ...)
    if not ok then
        return print("Install failed:", err)
    end

    local db = loadDB()
    db[pkg] = true
    saveDB(db)

    print("Installed:", pkg)
end

local function remove(pkg, force)
    local db = loadDB()

    if db[pkg] and not force then
        print("Removing package:", pkg)
    elseif not force then
        return print("Package not installed:", pkg)
    end

    local ok, err = runRemote(pkg .. "/remove.lua")
    if not ok then
        return print("Remove failed:", err)
    end

    db[pkg] = nil
    saveDB(db)

    print("Removed:", pkg)
end

local function upgrade(pkg, ...)
    local path = pkg .. "/upgrade.lua"

    local code = fetch(REPO .. "/" .. path)
    if code then
        print("Running upgrade script for:", pkg)
        return runPackage(code, path, ...)
    end

    print("No upgrade script, reinstalling...")
    remove(pkg, true)
    install(pkg, ...)
end

local function list()
    local db = loadDB()
    print("Installed packages:")

    for k in pairs(db) do
        local version = "unknown"

        local vcode = fetch(REPO .. "/" .. k .. "/version.lua")
        if vcode then
            local fn = load(vcode, "@version.lua", "t", {})
            if fn then
                local ok, v = pcall(fn)
                if ok then version = v end
            end
        end

        print("-", k, version)
    end
end

local function query(pkg)
    local code = fetch(REPO .. "/" .. pkg .. "/version.lua")
    if not code then
        return print("Package not found:", pkg)
    end

    local fn = load(code, "@version.lua", "t", {})
    if not fn then
        return print("Invalid version file")
    end

    local ok, v = pcall(fn)
    if ok then
        print(pkg .. " version:", v)
    else
        print("Error reading version")
    end
end

local function syncAll()
    local db = loadDB()
    for pkg in pairs(db) do
        upgrade(pkg)
    end
end

-- =========================
-- CLI
-- =========================

local args = {...}
local cmd = args[1]

if cmd == "-S" then
    install(args[2], table.unpack(args, 3))

elseif cmd == "-R" then
    remove(args[2], false)

elseif cmd == "-Rf" then
    remove(args[2], true)

elseif cmd == "-U" then
    upgrade(args[2], table.unpack(args, 3))

elseif cmd == "-Syu" then
    syncAll()

elseif cmd == "-Q" then
    query(args[2])

elseif cmd == "-L" then
    list()

else
    print("pacman usage:")
    print("-S <pkg> [args]   install")
    print("-R <pkg>          remove")
    print("-Rf <pkg>         force remove")
    print("-U <pkg>          upgrade")
    print("-Syu               upgrade all")
    print("-Q <pkg>          query version")
    print("-L                list installed")
end