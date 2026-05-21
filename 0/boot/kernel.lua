local kernel = {}

function kernel.init()
    print("Kernel init")

    kos = kos or {}
    kos.log = function(msg) print("[KOS] " .. msg) end

    kos.log("Initialized")
end

function kernel.launch()
    print("Configuring shell")

    settings.load(".settings")

    -- IMPORTANT: FORCE PATH INTO SHELL
    shell.setPath(
        "/bin:" ..
        "/bin/system:" ..
        "/bin/dev:" ..
        "/usr/bin:")

    if term.isColor() then
        shell.setAlias("background", "bg")
        shell.setAlias("foreground", "fg")
    end

    kos.log("Shell configured")
end

function kernel.start()
dofile("/bin/shell.lua")
_G.shell = shell

kernel.launch()
end

return kernel