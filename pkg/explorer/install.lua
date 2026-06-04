local REPO = "https://raw.githubusercontent.com/PB-Kronos/CcShell/pkg"
local SOURCE_ROOT = "pkg/explorer/"
local MINEXP_ROOT = SOURCE_ROOT .. "minexp/"

local function ensureDir(path)
    if path ~= "" and not fs.exists(path) then
        fs.makeDir(path)
    end
end

local function writeRemoteFile(src, dst)
    local dir = fs.getDir(dst)
    ensureDir(dir)
    print("Downloading:", src)
    local h = http.get(REPO .. "/" .. src)
    if not h then
        error("failed to download " .. src, 0)
    end
    local f = fs.open(dst, "w")
    f.write(h.readAll())
    f.close()
    h.close()
end

writeRemoteFile(SOURCE_ROOT .. "explorer.lua", "/bin/explorer.lua")

for _, entry in ipairs(textutils.unserializeJSON(http.get("https://api.github.com/repos/PB-Kronos/CcShell/git/trees/main?recursive=1").readAll()).tree) do
    if entry.type == "blob" and entry.path:sub(1, #MINEXP_ROOT) == MINEXP_ROOT then
        local rel = entry.path:sub(#MINEXP_ROOT + 1)
        local target = "/var/minex/" .. rel
        writeRemoteFile(entry.path, target)
    end
end
