local repo = "https://raw.githubusercontent.com/PB-Kronos/CcShell/main/pkg/ai/"
shell.run("wget " .. repo .. "ai.lua /bin/ai.lua")
shell.run("wget " .. repo .. ".ai_system /var/.ai_system")