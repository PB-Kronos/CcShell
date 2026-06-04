local REPO = "https://raw.githubusercontent.com/PB-Kronos/CcShell/main"
local ROOT = "pkg/base/src/"

local function ensureDir(path)
    if path ~= "" and not fs.exists(path) then
        fs.makeDir(path)
    end
end

local function installPrefix(prefix)
    local tree = textutils.unserializeJSON(http.get("https://api.github.com/repos/PB-Kronos/CcShell/git/trees/main?recursive=1").readAll())
    for _, f in ipairs(tree.tree or {}) do
        if f.type == "blob" and f.path:sub(1, #prefix) == prefix then
            local rel = f.path:sub(#ROOT + 1)
            if rel ~= "bin/rom/programs/http/wget.lua" then
                local target = "/" .. rel
                ensureDir(fs.getDir(target))
                print("Downloading:", f.path)
                shell.run("wget " .. REPO .. "/" .. f.path .. " " .. target)
            end
        end
    end
end

installPrefix("pkg/base/src/bin/rom/programs/http/")
installPrefix("pkg/base/src/bin/rom/programs/rednet/")

