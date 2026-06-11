local args = {...}
local last_received = ""

sys = sys or {}
sys.fs = sys.fs or {}

local function bridge_post(msg)
  local h = http.post("http://127.0.0.1:8000/output", msg)
  if h then
    h.close()
    return true
  end
  return false
end

local function bridge_get()
  local r = http.get("http://127.0.0.1:8000/input")
  if not r then return nil end

  local data = r.readAll()
  r.close()

  if data and data ~= "" then
    last_received = data
    return data
  end

  return nil
end

function sys.receive()
  local data = bridge_get()
  if data then
    print("[RECV]", data)
  end
  return data
end

function sys.send(msg)
  return bridge_post(msg)
end

function sys.execute(msg, timeout)
  timeout = timeout or 10

  if not sys.send(msg) then
    return nil, "no response from python scripts"
  end

  local deadline = os.clock() + timeout
  repeat
    local data = sys.receive()
    if data ~= nil then
      return data
    end
    os.sleep(0.1)
  until os.clock() >= deadline

  return nil, "no response from python scripts"
end

function sys.last()
  return last_received
end

function sys.fs.read(path)
  return sys.execute("read " .. path)
end

function sys.fs.write(path, data)
  return sys.execute("write " .. path .. " " .. data)
end

function sys.fs.exists(path)
  return sys.execute("exists " .. path)
end

function sys.fs.list(path)
  return sys.execute("list " .. (path or "/"))
end

function sys.fs.readlines(path)
  local data = sys.fs.read(path)
  if not data then return {} end

  local lines = {}
  for line in tostring(data):gmatch("[^\r\n]+") do
    lines[#lines + 1] = line
  end
  return lines
end

function sys.fs.copy(src, dst)
  return sys.execute("copy " .. src .. " " .. dst)
end

function sys.fs.move(src, dst)
  return sys.execute("move " .. src .. " " .. dst)
end

function sys.fs.replace(src, dst)
  return sys.execute("replace " .. src .. " " .. dst)
end

function sys.fs.delete(path)
  return sys.execute("delete " .. path)
end

function sys.fs.mkdir(path)
  return sys.execute("mkdir " .. path)
end

function sys.fs.run(path)
  return sys.execute("run " .. path)
end

function sys.fs.download(src, dst)
  return sys.execute("download " .. src .. " " .. dst)
end

function sys.taskbar_hide()
  return sys.execute("taskbar hide")
end

function sys.taskbar_show()
  return sys.execute("taskbar show")
end

function sys.taskbar_toggle()
  return sys.execute("taskbar toggle")
end

function sys.taskbar_status()
  return sys.execute("taskbar status")
end
function sys.exit()
  send("exit")
  os.shutdown()
end
local function print_usage()
  print("sys commands:")
  print("  read <path>")
  print("  write <path> <data>")
  print("  exists <path>")
  print("  list [path]")
  print("  readlines <path>")
  print("  mkdir <path>")
  print("  copy <src> <dst>")
  print("  move <src> <dst>")
  print("  replace <src> <dst>")
  print("  delete <path>")
  print("  run <path>")
  print("  download <src> <dst>")
  print("  taskbar hide|show|toggle|status")
end

-- ONE-SHOT MODE
local running = shell and shell.getRunningProgram and shell.getRunningProgram() or ""

if #args > 0 then
  sys.execute(table.concat(args, " "))
  return
end

if running == "/bin/sys.lua" or running:sub(-8) == "sys.lua" then
  print_usage()
end
