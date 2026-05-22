kos = kos or {}

kos._processes = {}
kos._hooks = {}

function kos.log(msg)
    print("[KOS] " .. msg)
end

function kos.init()
    kos.log("OS runtime initialized")
end

-- =====================
-- HOOK SYSTEM
-- =====================

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

-- =====================
-- PROCESS SYSTEM
-- =====================

function kos.spawn(name, fn)
    local pid = #kos._processes + 1

    kos._processes[pid] = {
        pid = pid,
        name = name,
        thread = coroutine.create(fn)
    }

    return pid
end

function kos.step()
    for _, p in pairs(kos._processes) do
        if coroutine.status(p.thread) ~= "dead" then
            local ok, err = coroutine.resume(p.thread)
            if not ok then
                print("[PROC ERROR] " .. tostring(err))
            end
        end
    end
end