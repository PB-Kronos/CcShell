for _,f in ipairs(textutils.unserializeJSON(http.get("https://api.github.com/repos/PB-Kronos/CcShell-runtime/git/trees/main?recursive=1").readAll()).tree) do
    if f.type == "blob" and f.path:sub(1,7) == "source/" and f.path:sub(1,10) ~= "source/py/" then
        local h = http.get("https://raw.githubusercontent.com/PB-Kronos/CcShell-runtime/main/"..f.path)
        if h then
            local o = "/disk/"..f.path:sub(8)
            fs.makeDir(fs.getDir(o))
            local x = fs.open(o, "w")
            x.write(h.readAll())
            x.close()
            h.close()
        end
    end
end
