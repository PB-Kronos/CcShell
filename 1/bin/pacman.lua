-- =========================
-- CONFIG
-- =========================

local REPO_BASE = "https://raw.githubusercontent.com/PB-Kronos/CcShell-runtime/main/pkg/"
local DB_FILE = "/var/pacman/db.txt"

-- =========================
-- HTTP FETCH
-- =========================

local function fetch(path)
    local url = REPO_BASE .. path

    if not http then
        return nil, "HTTP API not enabled"
    end

    local res = http.get(url)
    if not res then
        return nil, "Failed to fetch: " .. url
    end

    local data = res.readAll()
    res.close()

    return data
end

local function runRemote(path, ...)
    local code, err = fetch(path)
    if not code then
        return false, err
    end

    local env = setmetatable({
        shell = shell,
        fs = fs,
        http = http,
        textutils = textutils,
        term = term,
        print = print,
        pairs = pairs,
        ipairs = ipairs,
        tostring = tostring,
        tonumber = tonumber,
        error = error,
    }, { __index = _G })

    local fn, err2 = load(code, "@" .. path, "t", env)
    if not fn then
        return false, err2
    end

    return pcall(fn, ...)
end
-- =========================
-- DB SYSTEM
-- =========================

local function ensureDB()
    if not fs.exists("/var/pacman") then
        fs.makeDir("/var/pacman")
    end
    if not fs.exists(DB_FILE) then
        local f = fs.open(DB_FILE, "w")
        f.write("")
        f.close()
    end
end

local function readDB()
    ensureDB()
    local f = fs.open(DB_FILE, "r")
    local data = f.readAll() or ""
    f.close()

    local db = {}
    for line in data:gmatch("[^\r\n]+") do
        db[line] = true
    end
    return db
end

local function writeDB(db)
    local f = fs.open(DB_FILE, "w")
    for k, _ in pairs(db) do
        f.writeLine(k)
    end
    f.close()
end

local function dbAdd(pkg)
    local db = readDB()
    db[pkg] = true
    writeDB(db)
end

local function dbRemove(pkg)
    local db = readDB()
    db[pkg] = nil
    writeDB(db)
end

local function dbHas(pkg)
    return readDB()[pkg] ~= nil
end

-- =========================
-- VERSION
-- =========================

local function getVersion(pkg)
    local path = pkg .. "/version.lua"

    local code = fetch(path)
    if not code then return "unknown" end

    local fn = load(code, "@" .. path, "t", _G)
    if not fn then return "error" end

    local ok, result = pcall(fn)
    if not ok then return "error" end

    if type(result) == "table" then
        return result.version or "unknown"
    end

    return tostring(result)
end

-- =========================
-- PACKAGE OPS
-- =========================

local function install(pkg, args)
    print("Installing:", pkg)

    local ok, err = runRemote(pkg .. "/install.lua", table.unpack(args or {}))
    if not ok then
        return false, err
    end

    dbAdd(pkg)
    return true
end

local function remove(pkg, force)
    if not force and not dbHas(pkg) then
        return false, "Not installed: " .. pkg
    end

    print("Removing:", pkg)

    local ok, err = runRemote(pkg .. "/remove.lua")
    if not ok then
        return false, err
    end

    dbRemove(pkg)
    return true
end

local function upgrade(pkg)
    local path = pkg .. "/upgrade.lua"

    local code = fetch(path)
    if code then
        print("Upgrading:", pkg)
        local fn = load(code, "@" .. path, "t", _G)
        return pcall(fn)
    else
        print("Reinstalling:", pkg)
        remove(pkg, true)
        return install(pkg)
    end
end

local function upgradeAll()
    for pkg, _ in pairs(readDB()) do
        upgrade(pkg)
    end
end

-- =========================
-- VERSION FILE SAFETY CHECK
-- =========================

local function listPackages(verbose)
    local db = readDB()

    for pkg, _ in pairs(db) do
        if verbose then
            print(pkg .. " " .. getVersion(pkg))
        else
            print(pkg)
        end
    end
end

local function query(pkg)
    if not dbHas(pkg) then
        print("Not installed:", pkg)
        return
    end

    print("Package:", pkg)
    print("Version:", getVersion(pkg))
end

-- =========================
-- CLI
-- =========================

local args = { ... }
local cmd = args[1]
local pkg = args[2]

if cmd == "-S" then
    if not pkg then
        print("Usage: pacman -S <pkg> [args...]")
        return
    end

    local installArgs = {}
    for i = 3, #args do
        installArgs[#installArgs + 1] = args[i]
    end

    local ok, err = install(pkg, installArgs)
    if not ok then print("Error:", err) end

elseif cmd == "-R" then
    if not pkg then
        print("Usage: pacman -R <pkg>")
        return
    end
    local ok, err = remove(pkg, false)
    if not ok then print("Error:", err) end

elseif cmd == "-Rf" then
    if not pkg then
        print("Usage: pacman -Rf <pkg>")
        return
    end
    local ok, err = remove(pkg, true)
    if not ok then print("Error:", err) end

elseif cmd == "-U" then
    if not pkg then
        print("Usage: pacman -U <pkg>")
        return
    end
    upgrade(pkg)

elseif cmd == "-Syu" then
    upgradeAll()

elseif cmd == "-Q" then
    if pkg then
        query(pkg)
    else
        listPackages(true)
    end

elseif cmd == "-Qq" then
    listPackages(false)

elseif cmd == "-Qv" then
    listPackages(true)

else
    print("Pacman commands:")
    print(" -S <pkg> [args...]")
    print(" -R <pkg>")
    print(" -Rf <pkg>")
    print(" -U <pkg>")
    print(" -Syu")
    print(" -Q [pkg]")
    print(" -Qq")
    print(" -Qv")
end