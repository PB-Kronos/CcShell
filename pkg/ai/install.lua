local repo = "https://raw.githubusercontent.com/PB-Kronos/CcShell/main/pkg/ai/"
shell.run("wget " .. repo .. "ai.lua /bin/ai.lua")
--print("Do you want to configure the AI for generic usage(1), or for CcShell(2)")
--local i = read()
--if i == "1" then shell.run("wget " .. repo .. ".ai_system /var/.ai_system") end
--if i == "2" then shell.run("wget " .. repo .. ".ai_system /var/.ai_prompt") end
shell.run("wget " .. repo .. ".ai_system /var/.ai_system")