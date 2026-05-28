local function remove_file(path)
    if fs.exists(path) then
        fs.delete(path)
        print("Removed:", path)
    else
        print("Not found:", path)
    end
end

remove_file("/python/bridgefs.py")
remove_file("/bin/file.lua")
