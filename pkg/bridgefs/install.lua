local function download(src, dst)
    shell.run("wget https://raw.githubusercontent.com/PB-Kronos/CcShell-runtime/main/" .. src .. " " .. dst)
end

download("source/py/bridgefs.py", "/python/bridgefs.py")
if not fs.exists("/python/bridgefs.py") then
    error("bridgefs install failed", 0)
end

download("pkg/bridgefs/file.lua", "/bin/file.lua")
if not fs.exists("/bin/file.lua") then
    error("file.lua install failed", 0)
end

print("Installed: /python/bridgefs.py")
