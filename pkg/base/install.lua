for _,f in ipairs(textutils.unserializeJSON(http.get("https://api.github.com/repos/PB-Kronos/CcShell-runtime/git/trees/main?recursive=1").readAll()).tree) do
    if f.type == "blob" and f.path:sub(1,7) == "source/" and f.path:sub(1,10) ~= "source/py/" then
        print("Downloading:", f.path)
        local h = http.get("https://raw.githubusercontent.com/PB-Kronos/CcShell-runtime/main/"..f.path)
        if h then
            local o = "/disk/"..f.path:sub(8)
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
