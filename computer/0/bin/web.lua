local args = { ... }

local ROOT = "/var/webman"
local READY = ROOT .. "/ready.json"
local EVENTS = ROOT .. "/events.json"
local STARTUP_META = ROOT .. "/startup.json"
local AUTH_FILE = ROOT .. "/auth.json"
local EVENT_LIMIT = 200
local WS_PORT = 8011

local clients = {}
local sessions = {}
local userState = {}
local server = nil

local function ensure_dir(path)
    if path ~= "" and not fs.exists(path) then
        fs.makeDir(path)
    end
end

local function read_all(path)
    if not fs.exists(path) then
        return nil
    end
    local handle = fs.open(path, "r")
    if not handle then
        return nil
    end
    local data = handle.readAll()
    handle.close()
    return data
end

local function write_all(path, data)
    ensure_dir(fs.getDir(path))
    local handle = fs.open(path, "w")
    if not handle then
        error("cannot write " .. path, 0)
    end
    handle.write(data)
    handle.close()
end

local function read_json(path, default)
    local raw = read_all(path)
    if not raw or raw == "" then
        return default
    end
    local ok, data = pcall(textutils.unserializeJSON, raw)
    if ok and type(data) == "table" then
        return data
    end
    return default
end

local function write_json(path, data)
    write_all(path, textutils.serializeJSON(data))
end

local function trim_root(path)
    if not path or path == "" then
        return "/"
    end
    if path:sub(1, 1) ~= "/" then
        return "/" .. path
    end
    return path
end

local function now_ms()
    return (os.epoch and os.epoch("utc")) or math.floor(os.clock() * 1000)
end

local function load_sys()
    if not sys or not sys.send then
        pcall(dofile, "/bin/sys.lua")
    end
    return sys and sys.taskbar_status ~= nil
end

local function taskbar_status()
    if load_sys() then
        return sys.taskbar_status()
    end
    return "unknown"
end

local function taskbar_set(action)
    print("TASKBAR ACTION:", action)

    if action == "hide" then
        local r = sys.taskbar_hide()
        print("HIDE RESULT:", tostring(r))
        return r

    elseif action == "show" then
        local r = sys.taskbar_show()
        print("SHOW RESULT:", tostring(r))
        return r

    elseif action == "toggle" then
        local r = sys.taskbar_toggle()
        print("TOGGLE RESULT:", tostring(r))
        return r

    elseif action == "status" then
        return taskbar_status()
    end

    error("unknown taskbar action: " .. tostring(action), 0)
end
local function append_event(kind, message, payload)
    local events = read_json(EVENTS, {})
    events[#events + 1] = {
        ts = now_ms(),
        type = kind,
        message = message,
        payload = payload,
    }
    while #events > EVENT_LIMIT do
        table.remove(events, 1)
    end
    write_json(EVENTS, events)
end

local function list_dir(path)
    local target = trim_root(path or "/")
    local items = {}
    if not fs.exists(target) then
        return items
    end
    for _, name in ipairs(fs.list(target)) do
        local full = fs.combine(target, name)
        items[#items + 1] = {
            name = name,
            path = full,
            type = fs.isDir(full) and "dir" or "file",
            size = fs.isDir(full) and nil or fs.getSize(full),
        }
    end
    table.sort(items, function(a, b)
        if a.type ~= b.type then
            return a.type == "dir"
        end
        return a.name < b.name
    end)
    return items
end

local function list_processes()
    local items = {}
    if multishell and multishell.getCount then
        local count = multishell.getCount()
        local focus = multishell.getFocus()
        for i = 1, count do
            items[#items + 1] = {
                pid = i,
                name = multishell.getTitle(i) or ("tab-" .. i),
                active = i == focus,
            }
        end
    else
        items[1] = { pid = 1, name = "shell", active = true }
    end
    return items
end

local function list_peripherals()
    local items = {}
    for _, name in ipairs(peripheral.getNames()) do
        items[#items + 1] = {
            side = name,
            type = peripheral.getType(name) or "peripheral",
            name = name,
        }
    end
    table.sort(items, function(a, b)
        return a.side < b.side
    end)
    return items
end

local function redstone_state()
    local sides = {}
    if redstone and redstone.getSides then
        for _, side in ipairs(redstone.getSides()) do
            sides[side] = {
                in_ = redstone.getInput(side),
                out = redstone.getOutput(side),
            }
        end
    end
    return sides
end

local function load_startup_meta()
    local meta = read_json(STARTUP_META, {})
    if type(meta) ~= "table" then
        meta = {}
    end
    return meta
end

local function load_auth()
    local auth = read_json(AUTH_FILE, nil)
    if type(auth) == "table" and type(auth.password) == "string" and auth.password ~= "" then
        return auth
    end
    return nil
end

local function save_auth(password)
    write_json(AUTH_FILE, {
        password = password,
    })
end

local function auth_required()
    return load_auth() == nil
end

local tokenCounter = math.random(0,9999)

local function new_token()
    tokenCounter = math.random(0,9999)
    return tostring(now_ms())
        .. "-"
        .. tostring(os.getComputerID())
        .. "-"
        .. tostring(tokenCounter)
end

local function create_session(client_id)
    local token = new_token()

    sessions[token] = {
        ts = now_ms(),
        clientID = client_id,
    }

    return token
end
local function get_session(req)
    local token = req.token

    if type(token) ~= "string" or token == "" then
        return nil
    end

    return sessions[token]
end
local function authenticate_token(token)
    return type(token) == "string" and sessions[token] ~= nil
end

local function save_startup_meta(meta)
    write_json(STARTUP_META, meta)
end

local function collect_startup_scripts()
    local meta = load_startup_meta()
    local scripts = {
        {
            path = "/bin/startup.lua",
            enabled = meta["/bin/startup.lua"] ~= false,
            runsOnBoot = true,
        },
    }

    if fs.exists("/startup") and fs.isDir("/startup") then
        for _, name in ipairs(fs.list("/startup")) do
            local path = fs.combine("/startup", name)
            if not fs.isDir(path) and path:sub(-4) == ".lua" then
                scripts[#scripts + 1] = {
                    path = path,
                    enabled = meta[path] ~= false,
                    runsOnBoot = meta[path] ~= false,
                }
            end
        end
    end

    table.sort(scripts, function(a, b)
        return a.path < b.path
    end)
    return scripts
end

local function read_file(path)
    return read_all(trim_root(path))
end

local function write_file(path, content)
    local target = trim_root(path)
    local dir = fs.getDir(target)
    if dir ~= "" then
        ensure_dir(dir)
    end
    write_all(target, content or "")
    return true
end

local function rename_path(from, to)
    fs.move(trim_root(from), trim_root(to))
    return true
end

local function delete_path(path)
    fs.delete(trim_root(path))
    return true
end

local function run_script(path)
    local target = trim_root(path)
    if not fs.exists(target) then
        error("missing script: " .. target, 0)
    end
    local ok, result = pcall(function()
        if shell and shell.run then
            return shell.run(target)
        end
        local f = assert(loadfile(target))
        return f()
    end)
    if not ok then
        error(result, 0)
    end
    return { ok = true, result = result }
end

local function run_command(cmd)
    local tokens = {}
    if type(cmd) == "table" then
        tokens = cmd
    elseif type(cmd) == "string" then
        tokens = textutils.tokenize(cmd)
    end
    if #tokens == 0 then
        error("empty command", 0)
    end
    local ok, result = pcall(function()
        return shell.run(tokens[1], table.unpack(tokens, 2))
    end)
    if not ok then
        error(result, 0)
    end
    return { ok = result ~= false, result = result and "ok" or "failed" }
end

local function snapshot()
    return {
        computerId = os.getComputerID(),
        label = os.getComputerLabel(),
        taskbar = taskbar_status(),
        processes = list_processes(),
        peripherals = list_peripherals(),
        redstone = redstone_state(),
        startup = collect_startup_scripts(),
        events = read_json(EVENTS, {}),
        cwd = shell and shell.dir and shell.dir() or "/",
    }
end

local function process_request(req, client)
    local kind = req.kind or req.section or req.action
    local action = req.action or kind

    if kind == "auth" then
        local auth = load_auth()
        if action == "resume" then
            local token = req.token or req.sessionToken
            if authenticate_token(token) then
                return {
                    authenticated = true,
                    setupRequired = auth_required(),
                    token = token,
                    snapshot = snapshot(),
                }, false
            end
            return {
                authenticated = false,
                setupRequired = auth_required(),
            }, false

        elseif action == "setup" then
            if auth then
                error("password already configured", 0)
            end
            local password = tostring(req.password or "")
            local confirm = tostring(req.confirm or "")
            if password == "" then
                error("password required", 0)
            end
            if confirm ~= "" and confirm ~= password then
                error("password mismatch", 0)
            end
            save_auth(password)
            local token = create_session(client and client.id)
            userState[token] = {
                cwd = "/",
                selectedFile = nil,
            }
            if client then
            end
            append_event("system", "password configured")
            return {
                authenticated = true,
                setupRequired = false,
                token = token,
                snapshot = snapshot(),
            }, true

            elseif action == "login" then
                if not auth then
                    return {
                        authenticated = false,
                        setupRequired = true,
                    }, false
                end

                local password = tostring(req.password or "")

                if password ~= auth.password then
                    error("invalid password", 0)
                end

                local token = create_session(client and client.id)

                userState[token] = {
                    cwd = "/",
                    selectedFile = nil,
                }

                append_event("system", "client authenticated")

                return {
                    authenticated = true,
                    setupRequired = false,
                    token = token,
                    snapshot = snapshot(),
                }, false

            elseif action == "logout" then
        local token = req.token

        if token then
            userState[token] = nil
            sessions[token] = nil
        end

        return {
            authenticated = false,
            setupRequired = auth_required(),
        }, false
    end
        error("unknown auth action: " .. tostring(action), 0)
    end

    local session = get_session(req)

    if kind ~= "auth" and not session then
        error("auth required", 0)
    end

    if kind == "hello" then
        return {
            clientID = req.clientID,
            authenticated = false,
            setupRequired = auth_required(),
            port = WS_PORT,
            snapshot = snapshot(),
        }, false

    elseif kind == "state" then
        return snapshot(), false

    elseif kind == "taskbar" then
        if action == "show" then sys.taskbar_show() end
        if action == "hide" then sys.taskbar_hide() end
        if action == "toggle" then sys.taskbar_toggle() end
        if action == "status" then
            return {taskbar = sys.taskbar_status()}, false
        end

    elseif kind == "files" then
        local sub = action or req.op
        if sub == "list" then
            return { cwd = trim_root(req.path or "/"), entries = list_dir(req.path or "/") }, false
        elseif sub == "read" then
            return { path = trim_root(req.path or "/"), content = read_file(req.path or "") or "" }, false
        elseif sub == "write" then
            return { ok = write_file(req.path or "/", req.content or "") }, true
        elseif sub == "mkdir" then
            ensure_dir(trim_root(req.path or "/"))
            return { ok = true }, true
        elseif sub == "rename" then
            return { ok = rename_path(req.from or req.path or "/", req.to or "") }, true
        elseif sub == "delete" then
            return { ok = delete_path(req.path or "") }, true
        end
        error("unknown files action: " .. tostring(sub), 0)

    elseif kind == "startup" then
        local sub = action or req.op
        local path = trim_root(req.path or "/bin/startup.lua")
        if sub == "list" then
            return { scripts = collect_startup_scripts() }, false
        elseif sub == "read" then
            return { path = path, content = read_file(path) or "" }, false
        elseif sub == "write" then
            return { ok = write_file(path, req.content or "") }, true
        elseif sub == "toggle" then
            local meta = load_startup_meta()
            local current = meta[path]
            if current == nil then
                current = true
            end
            meta[path] = not current
            save_startup_meta(meta)
            return { path = path, enabled = meta[path] ~= false }, true
        elseif sub == "run" then
            return run_script(path), true
        end
        error("unknown startup action: " .. tostring(sub), 0)

    elseif kind == "processes" then
        return { processes = list_processes() }, false

    elseif kind == "peripherals" then
        return {
            peripherals = list_peripherals(),
            redstone = redstone_state(),
        }, false

    elseif kind == "events" then
        local sub = action or req.op
        if sub == "append" then
            append_event(req.type or "ui", req.message or "event", req.payload)
            return { ok = true }, true
        elseif sub == "clear" then
            write_json(EVENTS, {})
            return { ok = true }, true
        elseif sub == "list" or sub == nil then
            return { events = read_json(EVENTS, {}) }, false
        end
        error("unknown events action: " .. tostring(sub), 0)

    elseif kind == "command" then
        return run_command(req.cmd or req.command or req.args or ""), true
    end

    error("unknown request kind: " .. tostring(kind), 0)
end

local function json_send(ws, payload)
    local encoded = textutils.serialiseJSON(payload)
    local ok, err = pcall(function()
        ws.send(encoded)
    end)

    if not ok then
        print("SEND ERROR:", err)
    end

    return ok
end
local function send_to_client(client, payload)
    if not client then
        return false
    end

    return json_send(client.ws, payload)
end
local function send_snapshot_to_all(reason, payload)
    local data = {
        type = "snapshot",
        reason = reason,
        payload = payload,
        snapshot = snapshot(),
    }
    local raw = textutils.serializeJSON(data)
    for client_id, client in pairs(clients) do
        local ok = json_send(client.ws, payload)

        print(
            "BROADCAST:",
            client_id,
            "OK:",
            tostring(ok)
        )

        -- TEMPORARILY DISABLE REMOVAL
        -- if not ok then
        --     clients[client_id] = nil
        -- end
    end
end
local function make_client(ws, client_id)
    return {
        id = client_id,
        ws = ws,
    }
end

local function serve_message(client_id, client, message)
    print("RX:", message)
    local ok, req = pcall(textutils.unserializeJSON, message)
    if not ok or type(req) ~= "table" then
        json_send(client.ws, {
            id = nil,
            ok = false,
            error = "invalid request",
            snapshot = client.authenticated and snapshot() or nil,
        })
        return
    end

    req.clientID = req.clientID or client_id
    local handled, result, mutated = pcall(process_request, req, client)
    local response
    if handled then
        response = {
            id = req.id,
            ok = true,
            result = result,
            snapshot = client.authenticated and snapshot() or nil,
        }
    else
        response = {
            id = req.id,
            ok = false,
            error = tostring(result),
            snapshot = client.authenticated and snapshot() or nil,
        }
    end
    local ok = json_send(client.ws, response)
    print("SEND OK:", ok)

    --if not ok then
        --clients[client_id] = nil
        --return
    --end

    if handled and mutated then
        append_event(req.kind or req.action or "request", "handled", req)
        send_snapshot_to_all(req.kind or req.action or "request", req)
    elseif not handled then
        append_event(req.kind or req.action or "request", "error", req)
    end
end

local function accept_loop()
    while true do
        local ok, ws = pcall(function()
            return server.listen()
        end)
        if not ok or not ws then
            return
        end

        local client_id = tostring(ws.clientID or ws.clientId or ws.id or (#clients + 1))
        clients[client_id] = make_client(ws, client_id)
        print("CONNECTED CLIENT:", client_id)
        append_event("system", "client connected", { clientID = client_id })
        json_send(ws, {
            type = "hello",
            clientID = client_id,
            port = WS_PORT,
            authenticated = false,
            setupRequired = auth_required(),
        })
    end
end

local function event_loop()
    while true do
        local event, a, b, c = os.pullEvent()
        if event == "websocket_server_message" then
            local client_id = tostring(a)
            print("MESSAGE CLIENT:", tostring(a))
            local client = clients[client_id]
            print("CLIENT EXISTS:", client ~= nil)
            for id in pairs(clients) do
                print("KNOWN:", id)
            end
            if client and not c then
                serve_message(client_id, client, b)
            end
            elseif event == "websocket_server_closed" then
                local client_id = tostring(a)

                print("CLIENT CLOSED:", client_id)

                clients[client_id] = nil
            append_event("system", "client disconnected", { clientID = client_id, code = b, message = c })
        elseif event == "terminate" then
            if server and server.close then
                pcall(function()
                    server:close()
                end)
            end
            for _, ws in pairs(clients) do
                pcall(function()
                    ws:close()
                end)
            end
            error("terminated", 0)
        end
    end
end

local function daemon()
    ensure_dir(ROOT)
    math.randomseed(now_ms() + os.getComputerID())
    math.random(); math.random(); math.random()
    server = assert(http.websocketServer(WS_PORT))
    write_json(READY, {
        ready = true,
        port = WS_PORT,
        ts = now_ms(),
    })
    append_event("system", "dashboard websocket server started", { port = WS_PORT })
    print("web websocket server listening on ws://0.0.0.0:" .. WS_PORT)
    parallel.waitForAny(accept_loop, event_loop)
end

local function print_usage()
    print("Usage:")
    print("  web daemon")
    print("  web state")
    print("  web taskbar hide|show|toggle|status")
    print("  web files list|read|write|mkdir|rename|delete ...")
    print("  web startup list|read|write|toggle|run ...")
    print("  web processes")
    print("  web peripherals")
    print("  web events")
    print("  web command <cmd>")
    print("  websocket server: ws://0.0.0.0:" .. WS_PORT)
end

if #args == 0 then
    print_usage()
    return
end

if args[1] == "daemon" then
    daemon()
    return
end

local cli = { kind = args[1], action = args[2] }
if cli.kind == "files" then
    cli.path = args[3]
    cli.from = args[3]
    cli.to = args[4]
    cli.content = table.concat(args, " ", 4)
elseif cli.kind == "startup" then
    cli.path = args[3]
    cli.content = table.concat(args, " ", 4)
elseif cli.kind == "taskbar" then
    cli.action = args[2] or "status"
elseif cli.kind == "command" then
    cli.cmd = table.concat(args, " ", 2)
end

local ok, result = pcall(process_request, cli)
if not ok then
    print(textutils.serializeJSON({ ok = false, error = tostring(result) }))
    error(result, 0)
end
print(textutils.serializeJSON({ ok = true, result = result, snapshot = snapshot() }))
