local function download(src, dst)
    shell.run("wget https://raw.githubusercontent.com/PB-Kronos/CcShell-runtime/main/" .. src .. " " .. dst)
end

local function install_file(source_path, target_path, label)
    download(source_path, target_path)
    if not fs.exists(target_path) then
        error(label .. " install failed: " .. target_path, 0)
    end
    print("Installed:", target_path)
end

install_file("source/py/bridgefs.py", "/python/bridgefs.py", "bridgefs")
install_file("pkg/bridgefs/file.lua", "/bin/file.lua", "file.lua")
