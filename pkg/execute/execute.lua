
local args = {...}
local last_received = ""

sys = {}
function sys.receive()
  local r = http.get("http://127.0.0.1:8000/input")
  if not r then return end

  local data = r.readAll()
  r.close()

  if data and data ~= "" then
    last_received = data
    print("[RECV]", data)
  end
end

function sys.send(msg)
  http.post("http://127.0.0.1:8000/output", msg)
end


function sys.execute(msg)
  sys.send(msg)
  os.sleep(1)
  sys.receive()
end

-- ONE-SHOT MODE
if #args > 0 then
  sys.execute(table.concat(args, " "))
  return
end