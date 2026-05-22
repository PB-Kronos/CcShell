local kos = {}

kos.log = function(msg)
    print("[KOS] " .. tostring(msg))
end

kos._hooks = {}

function kos.on(event, fn)
    kos._hooks[event] = kos._hooks[event] or {}
    table.insert(kos._hooks[event], fn)
end

function kos.trigger(event, ...)
    local list = kos._hooks[event]
    if not list then return end

    for _, fn in ipairs(list) do
        pcall(fn, ...)
    end
end

function kos.init()
    kos.log("initialized (addon mode)")
end

return kos