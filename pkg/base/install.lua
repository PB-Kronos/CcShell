local function download(src, dst)
    if fs.exists(dst) then
        fs.delete(dst)
    end
    shell.run("wget https://raw.githubusercontent.com/PB-Kronos/CcShell/main/" .. src .. " " .. dst)
end

local SOURCE_ROOT = "pkg/base/src/"
local PROGRAMS_ROOT = SOURCE_ROOT .. "bin/rom/programs/"

local rawArgs = {...}
local flags = {}
for _, arg in ipairs(rawArgs) do
    if type(arg) == "string" and arg:sub(1,2) == "--" then
        flags[arg:sub(3)] = true
    end
end

local function want(flag, auto)
    return flags[flag] or auto
end

local autoAdvanced = term and term.isColor and term.isColor()
local autoTurtle = turtle ~= nil
local autoPocket = pocket ~= nil

local function startsWith(value, prefix)
    return value:sub(1, #prefix) == prefix
end

local function shouldInstallPath(path)
    if path == PROGRAMS_ROOT .. "http/wget.lua" then
        return true
    end

    if startsWith(path, PROGRAMS_ROOT .. "http/") then
        if path:sub(-8) == "wget.lua" then
            return true
        end
        return want("http", false)
    end

    if startsWith(path, PROGRAMS_ROOT .. "rednet/") then
        return want("http", false)
    end

    if startsWith(path, PROGRAMS_ROOT .. "fun/") then
        return want("fun", false)
    end

    if startsWith(path, PROGRAMS_ROOT .. "advanced/") then
        return want("advanced", autoAdvanced)
    end

    if startsWith(path, PROGRAMS_ROOT .. "turtle/") then
        return want("turtle", autoTurtle)
    end

    if startsWith(path, PROGRAMS_ROOT .. "pocket/") then
        return want("pocket", autoPocket)
    end

    return true
end

for _,f in ipairs(textutils.unserializeJSON(http.get("https://api.github.com/repos/PB-Kronos/CcShell/git/trees/main?recursive=1").readAll()).tree) do
    if f.type == "blob" and startsWith(f.path, SOURCE_ROOT) and shouldInstallPath(f.path) then
        print("Downloading:", f.path)
        local h = http.get("https://raw.githubusercontent.com/PB-Kronos/CcShell/main/"..f.path)
        if h then
            local o = "/" .. f.path:sub(#SOURCE_ROOT + 1)
            local dir = fs.getDir(o)

            if dir ~= "" and not fs.exists(dir) then
                print("MakeDir:", dir)
                fs.makeDir(dir)
            end

            print("WriteFile:", o)
            local x = fs.open(o, "w")
            x.write(h.readAll())
            x.close()
            h.close()
        else
            print("Failed download:", f.path)
        end
    end
end

