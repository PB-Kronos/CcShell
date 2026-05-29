local function ensure_file(path, label)
    if not fs.exists(path) then
        error(label .. " missing: " .. path .. " (install/update python first)", 0)
    end
    print("Verified:", path)
end

local function install_file(source_path, target_path, label)
    if not sys or not sys.fs or not sys.fs.download then
        error("sys bridge is required before installing bridgefs", 0)
    end

    sys.fs.download(source_path, target_path)
    if not sys.fs.exists(target_path) then
        error(label .. " install failed: " .. target_path, 0)
    end
    print("Installed:", target_path)
end

ensure_file("/python/bridgefs.py", "bridgefs.py")
install_file("pkg/bridgefs/file.lua", "/bin/file.lua", "file.lua")
