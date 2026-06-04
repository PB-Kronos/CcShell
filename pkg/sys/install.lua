local function install_file(target_path, source_path)
    if fs.exists(target_path) then
        error("module " .. target_path .. " already exists", 0)
    end

    shell.run("wget https://raw.githubusercontent.com/PB-Kronos/CcShell/main/" .. source_path .. " " .. target_path)

    if not fs.exists(target_path) then
        error("install failed, module " .. target_path .. " could not be verified", 0)
    end

    print("Installed:", target_path)
end

local function append_unique_line(path, line)
    if not fs.exists(path) then
        error("file not found: " .. path, 0)
    end

    local h = fs.open(path, "r")
    local content = h.readAll()
    h.close()

    if content:find(line, 1, true) then
        return false
    end

    local w = fs.open(path, "a")
    if not content:match("\n$") then
        w.write("\n")
    end
    w.write(line)
    w.write("\n")
    w.close()
    return true
end

local function install()
    install_file("/bin/sys.lua", "pkg/sys/sys.lua")
end

local function ensure_startup_hook()
    local hook = 'if fs.exists("/bin/sys.lua") then dofile("/bin/sys.lua") end'
    local path = "/bin/startup.lua"
    if append_unique_line(path, hook) then
        print("Updated:", path)
    end
end

if downloader then
    shell.run("wget https://raw.githubusercontent.com/PB-Kronos/CcShell/main/pkg/sys/sys.lua /home/download/sys.lua")
elseif downloader == false then
    install()
    ensure_startup_hook()
    print("Sys installed")
else
    error("download is nil")
end
