local function down()
    
    shell.run("wget https://github.com/PB-Kronos/CcShell-runtime/main/pkg/execute/execute.lua /home/download/execute.lua")
end
local function install()
    shell.run("wget https://github.com/PB-Kronos/CcShell-runtime/main/pkg/execute/execute.lua /bin/execute.lua")
end
if downloader then down() elseif downloader == false then install() else error("download is nil") end