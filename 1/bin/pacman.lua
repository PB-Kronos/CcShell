-- pacman.lua (file execution GitHub package manager)

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
        fs.makeDir("/var")
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

local function writeTmp(path, content)
    fs.makeDir("/tmp")
    local f = fs.open(path, "w")
    f.write(content)
    f.close()
end

local function runTmp(path, ...)
    return shell.run(path, ...)
end

-- =========================
-- Remote execution layer
-- =========================

local function runRemote(pkgPath, tmpPath, ...)
    local url = REPO .. "/" .. pkgPath

    local code, err = fetch(url)
    if not code then
        return false, err
    end

    writeTmp(tmpPath, code)
    return runTmp(tmpPath, ...)
end

-- =========================
-- DB
-- =========================

local function isInstalled(pkg)
    local db = loadDB()
    return db[pkg] == true
end

local function markInstalled(pkg)
    local db = loadDB()
    db[pkg] = true
    saveDB(db)
end

local function markRemoved(pkg)
    local db = loadDB()
    db[pkg] = nil
    saveDB(db)
end

-- =========================
-- Package commands
-- =========================

local function install(pkg, ...)
    print("Installing:", pkg)

    local ok, err = runRemote(
        pkg .. "/install.lua",
        "/tmp/install.lua",
        ...
    )

    if not ok then
        return print("Install failed:", err)
    end

    markInstalled(pkg)
    print("Installed:", pkg)
end

local function remove(pkg, force)
    if isInstalled(pkg) or force then
        print("Removing:", pkg)
    else
        return print("Package not installed:", pkg)
    end

    local ok, err = runRemote(
        pkg .. "/remove.lua",
        "/tmp/remove.lua"
    )

    if not ok then
        return print("Remove failed:", err)
    end

    markRemoved(pkg)
    print("Removed:", pkg)
end

local function upgrade(pkg, ...)
    print("Upgrading:", pkg)

    local code = fetch(REPO .. "/" .. pkg .. "/upgrade.lua")

    if code then
        writeTmp("/tmp/upgrade.lua", code)
        return runTmp("/tmp/upgrade.lua", ...)
    end

    print("No upgrade script, reinstalling...")

    remove(pkg, true)
    install(pkg, ...)
end

local function list()
    local db = loadDB()
    print("Installed packages:")

    for pkg in pairs(db) do
        local version = "unknown"

        local code = fetch(REPO .. "/" .. pkg .. "/version.lua")
        if code then
            local fn = load(code, "@version.lua", "t", {})
            if fn then
                local ok, v = pcall(fn)
                if ok then version = v end
            end
        end

        print("-", pkg, version)
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
    print("-Syu              upgrade all")
    print("-Q <pkg>          query version")
    print("-L                list installed")
end