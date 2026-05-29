local function download(src, dst)
    if fs.exists(dst) then
        fs.delete(dst)
    end
    shell.run("wget https://raw.githubusercontent.com/PB-Kronos/CcShell-runtime/main/" .. src .. " " .. dst)
end

local function ensure_install_stub()
    local stub = "/var/.install.py"
    local dir = fs.getDir(stub)
    if dir ~= "" and not fs.exists(dir) then
        fs.makeDir(dir)
    end
    if fs.exists(stub) then
        fs.delete(stub)
    end
    download("source/var/.install.py", stub)
    if not fs.exists(stub) then
        error("failed to stage python installer stub", 0)
    end
    return stub
end

local function bootstrap_python_tree()
    local response = nil
    for _ = 1, 10 do
        local h = http.post("http://127.0.0.1:8000/output", "install")
        if h then
            h.close()
            break
        end
        sleep(0.25)
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

local function ensure_python_tree()
    if fs.exists("/python/execbridge.py") and fs.exists("/python/bridgefs.py") then
        print("Python tree already installed; skipping bootstrap")
        return
    end

    local stub = ensure_install_stub()
    local response = bootstrap_python_tree()
    if response == "ok" then
        if fs.exists(stub) then
            fs.delete(stub)
        end
        print("Python tree installed")
    else
        if fs.exists(stub) then
            fs.delete(stub)
        end
        error("python installer did not confirm completion: " .. tostring(response or "no response"), 0)
    end
end

for _,f in ipairs(textutils.unserializeJSON(http.get("https://api.github.com/repos/PB-Kronos/CcShell-runtime/git/trees/main?recursive=1").readAll()).tree) do
    if f.type == "blob" and f.path:sub(1,7) == "source/" and f.path:sub(1,10) ~= "source/py/" and f.path ~= "source/var/.install.py" then
        print("Downloading:", f.path)
        local h = http.get("https://raw.githubusercontent.com/PB-Kronos/CcShell-runtime/main/"..f.path)
        if h then
            local o = "/"..f.path:sub(8)
            local dir = fs.getDir(o)

            if dir ~= "" and not fs.exists(dir) then
                print("MakeDir:", dir)
                fs.makeDir(dir)
            end

            print("WriteFile:", o)
            local x = fs.open(o, "w")
            x.write(h.readAll())
            x.close()
            h.close()
        else
            print("Failed download:", f.path)
        end
    end
end

ensure_python_tree()
