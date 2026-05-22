local args = {...}
shell.run("pastebin run sqUN6VUb " .. table.concat(args, " "))
fs.delete("/tmp/ccmsi.lua")
fs.delete("/tmp/install.lua")
return