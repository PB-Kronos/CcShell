local pending = fs.exists("/var/.install.py")
local pythonReady = fs.exists("/python/execbridge.py") and fs.exists("/python/bridgefs.py")

if pending and not pythonReady then
    print("Python bootstrap staged; reboot will run installer.")
end

if fs.exists("/bin/startup.lua") then
    dofile("/bin/startup.lua")
end
