pkg = {...}
if fs.exists("/graphics") then fs.delete("/graphics") print("graphics deleted") else print("graphics not found") end
if fs.exists("/lockbox") then fs.delete("/lockbox") print("lockbox deleted") else print("lockbox not found") end
if fs.exists("/scada-common") then fs.delete("/scada-common") print("scada-common deleted") else print("scada-common not found") end
if fs.exists(pkg[1]) then fs.delete(pkg[1]) print(pkg[1] .. " deleted") else print(pkg[1] .. " not found") end
if fs.exists("/initenv.lua") then fs.delete("/initenv.lua") print("initenv.lua deleted") else print("initenv.lua not found") end
if fs.exists("/install_manifest.json") then fs.delete("/install_manifest.json") print("install_manifest.json deleted") else print("install_manifest.json not found") end
if fs.exists("/configure.lua") then fs.delete("/configure.lua") print("configure.lua deleted") else print("configure.lua not found") end
if fs.exists("/startup.lua") then fs.delete("/startup.lua") print("startup.lua deleted") else print("startup.lua not found") end
if fs.exists("/LICENSE") then fs.delete("/LICENSE") print("LICENSE deleted") else print("LICENSE not found") end