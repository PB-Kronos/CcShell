local fswrap = {}

function fswrap.install()
    local native = {}

    for k, v in pairs(fs) do
        native[k] = v
    end

    local function r(path)
        return vfs.resolve(path)
    end

    fs.open = function(p, m)
        return native.open(r(p), m)
    end

    fs.list = function(p)
        return native.list(r(p))
    end

    fs.exists = function(p)
        return native.exists(r(p))
    end

    fs.isDir = function(p)
        return native.isDir(r(p))
    end

    fs.makeDir = function(p)
        return native.makeDir(r(p))
    end

    fs.delete = function(p)
        return native.delete(r(p))
    end

    fs.move = function(a, b)
        return native.move(r(a), r(b))
    end

    fs.copy = function(a, b)
        return native.copy(r(a), r(b))
    end
end

return fswrap