local function download(src, dst)
    shell.run("wget https://raw.githubusercontent.com/PB-Kronos/CcShell-runtime/main/" .. src .. " " .. dst)
end

local function install_file(cache_path, target_path, source_path)
    download(source_path, cache_path)
    if not fs.exists(cache_path) then
        error("download failed for " .. source_path, 0)
    end

    if fs.exists(target_path) then
        error("module " .. target_path .. " already exists", 0)
    end

    fs.copy(cache_path, target_path)

    if not fs.exists(target_path) then
        error("install failed, module " .. target_path .. " could not be verified", 0)
    end

    print("Installed:", target_path)
end

local function ensure_install_stub()
    local stub = "/var/.install.py"
    local dir = fs.getDir(stub)
    if dir and dir ~= "" and not fs.exists(dir) then
        fs.makeDir(dir)
    end
    download("source/var/.install.py", stub)
    if not fs.exists(stub) then
        error("failed to stage installer stub", 0)
    end
    return stub
end

local function send_install_message()
    local response = nil
    local h = http.post("http://127.0.0.1:8000/output", "install")
    if h then
        h.close()
    end

    for _ = 1, 20 do
        sleep(0.25)
        local r = http.get("http://127.0.0.1:8000/input")
        if r then
            local data = r.readAll()
            r.close()
            if data and data ~= "" then
                response = data
                break
            end
        end
    end

    return response
end

local function install()
    install_file("/var/cache/sys.lua", "/bin/sys.lua", "pkg/sys/sys.lua")
end

local function ensure_startup_hook()
    local hook = 'if fs.exists("/bin/sys.lua") then dofile("/bin/sys.lua") end'
    local path = "/bin/startup.lua"

    if not fs.exists(path) then
        error("startup file not found: " .. path, 0)
    end

    local h = fs.open(path, "r")
    local content = h.readAll()
    h.close()

    if not content:find(hook, 1, true) then
        local w = fs.open(path, "a")
        if not content:match("\n$") then
            w.write("\n")
        end
        w.write(hook)
        w.write("\n")
        w.close()
        print("Updated:", path)
    end
end

if downloader then
    shell.run("wget https://raw.githubusercontent.com/PB-Kronos/CcShell-runtime/main/pkg/sys/sys.lua /home/download/sys.lua")
elseif downloader == false then
    install()
    ensure_startup_hook()
    local stub = ensure_install_stub()
    local response = send_install_message()
    if response == "ok" then
        if fs.exists(stub) then
            fs.delete(stub)
        end
        print("Bridge installer completed")
    else
        print("Bridge installer did not confirm completion:", response or "no response")
    end
else
    error("download is nil")
end
