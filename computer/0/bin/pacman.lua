-- pacman.lua (GitHub mode package manager)

local REPO = "https://raw.githubusercontent.com/PB-Kronos/CcShell-runtime/main/pkg"
local DB_PATH = "/var/pacman.db"
local download = false
-- =========================
-- Utilities
-- =========================
local function getbase()
for _,f in ipairs(textutils.unserializeJSON(http.get("https://api.github.com/repos/PB-Kronos/CcShell-runtime/git/trees/main?recursive=1").readAll()).tree) do if f.type=="blob" and f.path:sub(1,7)=="source/" then local h=http.get("https://raw.githubusercontent.com/PB-Kronos/CcShell-runtime/main/"..f.path) if h then local o="/"..f.path:sub(8) fs.makeDir(fs.getDir(o)) local x=fs.open(o,"w") x.write(h.readAll()) x.close() h.close() end end end
end
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
	downloader = download,
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
        print("Install failed:", err)
        return
    end

    local version = "unknown"
    local desc = "no description"

    local vcode = fetch(REPO .. "/" .. pkg .. "/version.lua")
    if vcode then
        local fn = load(vcode, "@version.lua", "t", {})
        if fn then
            local ok, v = pcall(fn)
            if ok then
                if type(v) == "table" then
                    version = v.version or version
                    desc = v.desc or desc
                else
                    version = v
                end
            end
        end
    end

    local db = loadDB()
    db[pkg] = { version = version, desc = desc }
    saveDB(db)

    print("Installed:", pkg)
end

local function remove(pkg, force)
    local db = loadDB()

    if db[pkg] and not force then
        print("Removing package:", pkg)
    elseif not force then
        print("Package not installed:", pkg)
        return
    end

    local ok, err = runRemote(pkg .. "/remove.lua")
    if not ok then
        print("Remove failed:", err)
        return
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
        local ok, err = runPackage(code, path, ...)
        if not ok then
            print("Upgrade failed:", err)
        end
        return
    end

    print("No upgrade script, reinstalling...")
    remove(pkg, true)
    install(pkg, ...)
end

local function list()
    local db = loadDB()
    print("Installed packages:")

    for k, v in pairs(db) do
        if type(v) == "table" then
            print("-", k, v.version or "unknown", "-", v.desc or "")
        else
            print("-", k, v or "unknown")
        end
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
        if type(v) == "table" then
            print(pkg, v.version or "unknown", "-", v.desc or "")
        else
            print(pkg .. " version:", v)
        end
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

if cmd == "-S" or cmd == "-D" then
    if cmd == "-D" then download = true else download = false end
    for i = 2, #args do
        install(args[i])
    end
elseif cmd == "-R" then
    for i = 2, #args do
        remove(args[i], false)
    end

elseif cmd == "-Rf" then
    for i = 2, #args do
        remove(args[i], true)
    end

elseif cmd == "-U" then
    for i = 2, #args do
        upgrade(args[i])
    end

elseif cmd == "-Syu" then
    syncAll()

elseif cmd == "-Q" then
    for i = 2, #args do
        query(args[i])
    end

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