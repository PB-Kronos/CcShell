local args = {...}
if fs.exists("/startup.lua") then fs.copy("/startup.lua", "/startup.bak") print("startu.bak.lua created") end
shell.run("pastebin run sqUN6VUb " .. table.concat(args, " "))
fs.delete("/tmp/ccmsi.lua")
fs.delete("/tmp/install.lua")
return