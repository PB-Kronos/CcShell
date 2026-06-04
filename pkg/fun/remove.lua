local function removeTree(path)
    if not fs.exists(path) then
        return
    end

    if fs.isDir(path) then
        for _, name in ipairs(fs.list(path)) do
            removeTree(fs.combine(path, name))
        end
    end

    fs.delete(path)
end

removeTree("/bin/rom/programs/fun")
