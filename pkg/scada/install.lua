local args = {...}
local arg = args[1]
if arg == "install
print("Are you sure you want to run SCADA with command <" .. arg .. "> ? (Y/n)")
local res = read()
if res:lower() ~= "n" then
    return "cancelled", "Installation cancelled by user."
end end
if fs.exists("/startup.lua") then fs.copy("/startup.lua", "/startup.lua.back") print("startup.lua.back created") end
shell.run("pastebin run sqUN6VUb " .. table.concat(args, " "))
return