local function down()
    shell.run("wget https://raw.githubusercontent.com/PB-Kronos/CcShell-runtime/main/pkg/execute/execute.lua /home/download/execute.lua")
end
local function install()
    if fs.exists("/var/cache/execute.lua") then shell.run("wget https://raw.githubusercontent.com/PB-Kronos/CcShell-runtime/main/pkg/execute/execute.lua /var/cache/execute.lua") end
    if fs.exists("/bin/execute.lua") then error("module /bin/execute.lua already exists", 0) else fs.copy("/var/cache/execute.lua", "/bin/execute.lua")
    if fs.exists("/bin/execute.lua") then print("Install verified") return else error("Install failed, module /bin/execute.lua could not be verified", 0)

    if fs.exists("/var/cache/file.lua") then shell.run("wget https://raw.githubusercontent.com/PB-Kronos/CcShell-runtime/main/pkg/execute/file.lua /var/cache/file.lua") end
    if fs.exists("/bin/file.lua") then error("module /bin/file.lua already exists", 0) else fs.copy("/var/cache/file.lua", "/bin/file.lua")
    if fs.exists("/bin/file.lua") then print("Install verified") return else error("Install failed, module /bin/file.lua could not be verified", 0)

end
if downloader then down() elseif downloader == false then install() else error("download is nil") end