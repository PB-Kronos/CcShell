local REPO = "https://raw.githubusercontent.com/PB-Kronos/CcShell/main"
local PREFIX = "pkg/base/src/bin/rom/programs/fun/"

local function ensureDir(path)
    if path ~= "" and not fs.exists(path) then
        fs.makeDir(path)
    end
end

local tree = textutils.unserializeJSON(http.get("https://api.github.com/repos/PB-Kronos/CcShell/git/trees/main?recursive=1").readAll())
for _, f in ipairs(tree.tree or {}) do
    if f.type == "blob" and f.path:sub(1, #PREFIX) == PREFIX then
        local rel = f.path:sub(#"pkg/base/src/" + 1)
        local target = "/" .. rel
        ensureDir(fs.getDir(target))
        print("Downloading:", f.path)
        shell.run("wget " .. REPO .. "/" .. f.path .. " " .. target)
    end
end

