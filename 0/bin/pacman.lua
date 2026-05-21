local args = { ... }

local REPO = "https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main/packages"
local DB_PATH = "/var/kpkg/db.json"

-- =====================
-- DB
-- =====================

local function loadDB()
    if not fs.exists(DB_PATH) then return {} end

    local f = fs.open(DB_PATH, "r")
    local data = f.readAll()
    f.close()

    return textutils.unserialize(data) or {}
end

local function saveDB(db)
    if not fs.exists("/var/kpkg") then
        fs.makeDir("/var/kpkg")
    end

    local f = fs.open(DB_PATH, "w")
    f.write(textutils.serialize(db))
    f.close()
end

-- =====================
-- HTTP
-- =====================

local function fetch(url)
    local h = http.get(url)
    if not h then return nil end

    local data = h.readAll()
    h.close()
    return data
end

-- =====================
-- SAFE MANIFEST (NO EXEC)
-- =====================

local function loadManifest(pkg)
    local src = fetch(REPO .. "/" .. pkg .. "/manifest.lua")
    if not src then return nil end

    -- SAFE: expect manifest returns a table, no code execution required later
    local fn, err = load("return " .. src)
    if not fn then
        print("Manifest error:", err)
        return nil
    end

    local ok, result = pcall(fn)
    if not ok then return nil end

    return result
end

-- =====================
-- FILE OPS
-- =====================

local function writeFile(path, content)
    local dir = fs.getDir(path)
    if dir ~= "" and not fs.exists(dir) then
        fs.makeDir(dir)
    end

    local f = fs.open(path, "w")
    if not f then return false end
    f.write(content)
    f.close()
    return true
end

-- =====================
-- INSTALL
-- =====================

local function install(pkg, db)
    if pkg == nil then error("Usage: pacman -S <pkg>") else
    local manifest = loadManifest(pkg)
    if not manifest then
        print("Package not found: " .. pkg)
        return
    end

    print("Installing " .. manifest.name)

    for _, file in ipairs(manifest.files or {}) do
        local data = fetch(REPO .. "/" .. pkg .. "/files/" .. file)

        if data then
            writeFile("/" .. file, data)
            print(" + " .. file)
        end
    end

    db[pkg] = {
        version = manifest.version,
        files = manifest.files
    }

    print("Installed " .. pkg)
end end

-- =====================
-- REMOVE
-- =====================

local function remove(pkg, db)
    local entry = db[pkg]
    if not entry then
        print("Package not installed")
        return
    end

    for _, file in ipairs(entry.files or {}) do
        local path = "/" .. file
        if fs.exists(path) then fs.delete(path) end
    end

    db[pkg] = nil
    print("Removed " .. pkg)
end

-- =====================
-- MAIN
-- =====================

local db = loadDB()

if args[1] == "-S" then
    install(args[2], db)

elseif args[1] == "-R" then
    remove(args[2], db)

elseif args[1] == "-Syu" then
    for pkg in pairs(db) do
        remove(pkg, db)
        install(pkg, db)
    end

elseif args[1] == "-Q" then
    for k, v in pairs(db) do
        print(k .. " (" .. (v.version or "?") .. ")")
    end
end

saveDB(db)