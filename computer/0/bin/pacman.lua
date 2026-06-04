-- pacman.lua (GitHub mode package manager)

local REPO = "https://raw.githubusercontent.com/PB-Kronos/CcShell/pkg/pkg"
local DB_PATH = "/var/pacman.db"
local download = false
local PY_ROOT = "pkg/base/src/py/"

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

local function clearCache()
    local cache_root = "/var/cache"
    if not fs.exists(cache_root) then
        return 0
    end

    local removed = 0
    local function removeTree(path)
        if not fs.exists(path) then
            return
        end

        if fs.isDir(path) then
            for _, name in ipairs(fs.list(path)) do
                removeTree(fs.combine(path, name))
            end
            fs.delete(path)
        else
            fs.delete(path)
        end
        removed = removed + 1
    end

    for _, name in ipairs(fs.list(cache_root)) do
        removeTree(fs.combine(cache_root, name))
    end

    print("Cleared cache:", cache_root)
    return removed
end

local function clearPythonTree()
    if not sys or not sys.fs then
        return false, "sys bridge is required to manage the python tree"
    end

    local root = "/python"
    if not sys.fs.exists(root) then
        return true
    end

    local listing = sys.fs.list(root)
    if not listing or listing == "" then
        return true
    end

    for name in tostring(listing):gmatch("[^\r\n]+") do
        local target = root .. "/" .. name
        sys.fs.delete(target)
    end

    return true
end

local function installPythonTree()
    if not sys or not sys.fs or not sys.fs.download then
        return false, "sys bridge is required to install python files"
    end

    local ok, err = clearPythonTree()
    if not ok then
        return false, err
    end

    local tree = fetch("https://api.github.com/repos/PB-Kronos/CcShell/git/trees/main?recursive=1")
    if not tree then
        return false, "failed to fetch source tree"
    end

    local parsed = textutils.unserializeJSON(tree)
    if not parsed or not parsed.tree then
        return false, "invalid source tree"
    end

    for _, f in ipairs(parsed.tree) do
        if f.type == "blob" and f.path:sub(1, #PY_ROOT) == PY_ROOT then
            local rel = f.path:sub(#PY_ROOT + 1)
            local target = "/python/" .. rel
            print("Downloading python file:", f.path)
            sys.fs.download(f.path, target)
        end
    end

    return true
end

local function isInstalled(pkg, db)
    db = db or loadDB()
    return db[pkg] ~= nil
end

local function readRemoteTable(path)
    local code = fetch(REPO .. "/" .. path)
    if not code then
        return nil, "missing"
    end

    local fn, err = load(code, "@" .. path, "t", {})
    if not fn then
        return nil, err
    end

    local ok, result = pcall(fn)
    if not ok then
        return nil, result
    end

    if type(result) ~= "table" then
        return nil, "expected table"
    end

    return result
end

local function getPackageManifest(pkg)
    return readRemoteTable(pkg .. "/manifest.lua")
end

local function extractDependencies(manifest)
    local deps = manifest and (manifest.dependencies or manifest.depends or manifest.deps)
    if not deps then
        return {}
    end

    local result = {}
    if type(deps) == "string" then
        result[1] = deps
    elseif type(deps) == "table" then
        for _, dep in ipairs(deps) do
            if type(dep) == "string" then
                result[#result + 1] = dep
            elseif type(dep) == "table" then
                local name = dep.name or dep.package or dep.pkg or dep[1]
                if name then
                    result[#result + 1] = name
                end
            end
        end
    end

    return result
end

local function installDependencies(pkg, manifest, seen)
    local deps = extractDependencies(manifest)
    if #deps == 0 then
        return true
    end

    seen = seen or {}
    seen[pkg] = true

    for _, dep in ipairs(deps) do
        if not isInstalled(dep) then
            if seen[dep] then
                return false, "dependency cycle detected: " .. dep
            end

            local ok, err = install(dep, seen)
            if not ok then
                return false, err
            end
        end
    end

    return true
end

local function installSpecialPackage(pkg)
    if pkg ~= "python" then
        return false
    end

    print("Installing package: python")
    local ok, err = installPythonTree()
    if not ok then
        print("Install failed:", err)
        return false, err
    end

    local db = loadDB()
    db[pkg] = { version = "source", desc = "Host python scripts" }
    saveDB(db)
    print("Installed:", pkg)
    return true
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
	sys = sys,
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

function install(pkg, seen, ...)
    if type(seen) ~= "table" then
        seen = nil
    end

    local special_ok, special_err = installSpecialPackage(pkg)
    if special_ok ~= false then
        return special_ok, special_err
    end

    print("Installing package:", pkg)

    local manifest, manifestErr = getPackageManifest(pkg)
    if not manifest then
        print("Warning: could not load manifest for", pkg, ":", manifestErr)
    end

    local okDeps, depErr = installDependencies(pkg, manifest, seen)
    if not okDeps then
        print("Dependency install failed:", depErr)
        return false, depErr
    end

    local ok, err = runRemote(pkg .. "/install.lua", ...)
    if not ok then
        print("Install failed:", err)
        return false, err
    end

    local version = "unknown"
    local desc = "no description"

    version = manifest.version or version
    desc = manifest.desc or desc

    local db = loadDB()
    db[pkg] = { version = version, desc = desc }
    saveDB(db)

    print("Installed:", pkg)
    return true
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
    if pkg == "python" then
        clearCache()
        local ok, err = installSpecialPackage(pkg)
        if not ok then
            print("Upgrade failed:", err)
        end
        return
    end

    local path = pkg .. "/upgrade.lua"

    clearCache()

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
    local code = fetch(REPO .. "/" .. pkg .. "/manifest.lua")
    if not code then
        return print("Package not found:", pkg)
    end

    local fn = load(code, "@manifest.lua", "t", {})
    if not fn then
        return print("Invalid manifest file")
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

local function isFlag(arg)
    return type(arg) == "string" and arg:sub(1, 2) == "--"
end

-- =========================
-- CLI
-- =========================

local args = {...}
local cmd = args[1]

if cmd == "-S" or cmd == "-D" then
    if cmd == "-D" then download = true else download = false end
    local baseFlags = {}
    for i = 2, #args do
        if isFlag(args[i]) then
            baseFlags[#baseFlags + 1] = args[i]
        end
    end

    for i = 2, #args do
        if not isFlag(args[i]) then
            if args[i] == "base" then
                install(args[i], nil, table.unpack(baseFlags))
            else
                install(args[i])
            end
        end
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
    clearCache()
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
