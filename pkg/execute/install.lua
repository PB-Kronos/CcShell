local function down()
    shell.run("
end
local function install()
    shell.run("wget https://github.com/PB-Kronos/CcShell-runtime/main/pkg/execute.lua /bin/execute.lua
end
if download then down() elseif download == false then install() else error("download is nil") end