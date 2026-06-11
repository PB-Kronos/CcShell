local function remove(path)
if fs.exists(path) then fs.delete(path) else print("Skipping " .. path)
end
remove("/bin/ai.lua")
remove("/var/.ai_system")
remove("/var/.ai_history")
remove("/var/.ai_key")