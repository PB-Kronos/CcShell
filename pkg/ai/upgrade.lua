if not fs.exists("/bin/ai.lua") then shell.run("wget https://raw.githubusercontent.com/PB-Kronos/CcShell/main/pkg/ai/ai.lua /bin/ai.lua") else
fs.delete("/bin/ai.lua")
shell.run("wget https://raw.githubusercontent.com/PB-Kronos/CcShell/main/pkg/ai/ai.lua /bin/ai.lua") end
print("Update system prompt?")
local i = read()
if i == "Y" or i == "y" or i == "yes" or i == "Yes" or "" then 
if not fs.exists("/var/.ai_system") then shell.run("wget https://raw.githubusercontent.com/PB-Kronos/CcShell/main/pkg/ai/.ai_system /var/.ai_system") else
fs.delete("/var/.ai_system")
shell.run("wget https://raw.githubusercontent.com/PB-Kronos/CcShell/main/pkg/ai/.ai_system /var/.ai_system") end end