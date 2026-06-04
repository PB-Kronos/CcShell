local function removePath(path)
    if fs.exists(path) then
        fs.delete(path)
        print("Removed:", path)
    end
end

removePath("/bin/explorer.lua")
removePath("/var/minex")
