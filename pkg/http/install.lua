local REPO = "https://raw.githubusercontent.com/PB-Kronos/CcShell-runtime/main"

local function ensureDir(path)
    if path ~= "" and not fs.exists(path) then
        fs.makeDir(path)
    end
end

local function installPrefix(prefix)
    local tree = textutils.unserializeJSON(http.get("https://api.github.com/repos/PB-Kronos/CcShell-runtime/git/trees/main?recursive=1").readAll())
    for _, f in ipairs(tree.tree or {}) do
        if f.type == "blob" and f.path:sub(1, #prefix) == prefix then
            local rel = f.path:sub(8)
            if rel ~= "bin/rom/programs/http/wget.lua" then
                local target = "/" .. rel
                ensureDir(fs.getDir(target))
                print("Downloading:", f.path)
                shell.run("wget " .. REPO .. "/" .. f.path .. " " .. target)
            end
        end
    end
end

installPrefix("source/bin/rom/programs/http/")
installPrefix("source/bin/rom/programs/rednet/")
