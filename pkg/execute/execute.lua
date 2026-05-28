local args = {...}
local last_received = ""

sys = sys or {}
sys.fs = sys.fs or {}

local function bridge_post(msg)
  return http.post("http://127.0.0.1:8000/output", msg)
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

function sys.execute(msg)
  sys.send(msg)
  os.sleep(1)
  return sys.receive()
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

-- ONE-SHOT MODE
if #args > 0 then
  sys.execute(table.concat(args, " "))
  return
end
