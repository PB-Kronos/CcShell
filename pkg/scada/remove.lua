if fs.exists("/graphics") then fs.delete("/graphics") print("graphics deleted") else print("graphics not found") end
if fs.exists("/lockbox") then fs.delete("/lockbox") print("lockbox deleted") else print("lockbox not found") end
if fs.exists("/scada-common") then fs.delete("/scada-common") print("scada-common deleted") else print("scada-common not found") end
if fs.exists("/initenv.lua") then fs.delete("/initenv.lua") print("initenv.lua deleted") else print("initenv.lua not found") end
if fs.exists("/install_manifest.json") then fs.delete("/install_manifest.json") print("install_manifest.json deleted") else print("install_manifest.json not found") end
if fs.exists("/configure.lua") then fs.delete("/configure.lua") print("configure.lua deleted") else print("configure.lua not found") end
if fs.exists("/startup.lua") then fs.delete("/startup.lua") print("startup.lua deleted") else print("startup.lua not found") end
if fs.exists("/LICENSE") then fs.delete("/LICENSE") print("LICENSE deleted") else print("LICENSE not found") end
print("deleting app firmware")
if fs.exists("/supervisor") then fs.delete("/supervisor") print("supervisor deleted") end
if fs.exists("/coordinator") then fs.delete("/coordinator") print("coordinator deleted") end
if fs.exists("/reactor-plc") then fs.delete("/reactor-plc") print("reactor-plc deleted") end
if fs.exists("/rtu") then fs.delete("/rtu") print("rtu deleted") end
if fs.exists("/pocket") then fs.delete("/pocket") print("pocket deleted") end