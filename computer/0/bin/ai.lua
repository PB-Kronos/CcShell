-- =========================
-- CC:TWEAKED AI AGENT (ASYNC STABLE VERSION)
-- =========================

local KEY_FILE = "/var/.ai_key"
local SYSTEM_FILE = "/var/.ai_system"
local HISTORY_FILE = "/var/.ai_history"
local MEMORY_FILE = "/var/.ai_memory.json"

local URL = "https://openrouter.ai/api/v1/chat/completions"
local MODEL = "openrouter/free"

local API_KEY = ""
local messages = {}

-- =========================
-- QUEUE SYSTEM
-- =========================
local requestQueue = {}
local activeRequest = false

-- =========================
-- SANITIZE
-- =========================
local function sanitizeText(text)
    if not text then return "" end

    text = text:gsub("\226\128\153", "'")
    text = text:gsub("\226\128\152", "'")
    text = text:gsub("\226\128\156", '"')
    text = text:gsub("\226\128\157", '"')
    text = text:gsub("\226\128\147", "-")
    text = text:gsub("\226\128\148", "--")
    text = text:gsub("\226\128\162", "*")

    local out = {}
    for i = 1, #text do
        local b = text:byte(i)
        if (b >= 32 and b <= 126) or b == 10 or b == 13 then
            out[#out + 1] = string.char(b)
        end
    end
    return table.concat(out)
end

-- =========================
-- API KEY
-- =========================
local function getApiKey()
    if fs.exists(KEY_FILE) then
        local f = fs.open(KEY_FILE, "r")
        API_KEY = f.readLine():gsub("%s+", "")
        f.close()
    else
        term.setTextColor(colors.yellow)
        print("No API key found.")
        term.setTextColor(colors.white)
        write("Enter API-Key: ")
        API_KEY = read("*"):gsub("%s+", "")

        local f = fs.open(KEY_FILE, "w")
        f.writeLine(API_KEY)
        f.close()
    end
end

-- =========================
-- PRINT WRAP
-- =========================
local function printWrapped(text)
    local w, _ = term.getSize()
    for line in text:gmatch("[^\n]+") do
        while #line > w do
            print(line:sub(1, w))
            line = line:sub(w + 1)
        end
        print(line)
    end
end

-- =========================
-- HISTORY
-- =========================
local function appendToHistoryFile(sender, text)
    local f = fs.open(HISTORY_FILE, "a")
    f.writeLine(sender .. ": " .. text)
    f.close()
end

-- =========================
-- MEMORY SAVE/LOAD
-- =========================
local function saveMemory(summary)
    local data = {
        messages = messages,
        summary = summary or ""
    }

    local f = fs.open(MEMORY_FILE, "w")
    f.write(textutils.serializeJSON(data))
    f.close()
end

local function loadMemory()
    if fs.exists(MEMORY_FILE) then
        local f = fs.open(MEMORY_FILE, "r")
        local raw = f.readAll()
        f.close()

        local ok, data = pcall(textutils.unserializeJSON, raw)
        if ok and data and data.messages then
            messages = data.messages
            return
        end
    end

    messages = {}
end

-- =========================
-- SYSTEM
-- =========================
local function loadSystem()
    if not fs.exists(SYSTEM_FILE) then
        local f = fs.open(SYSTEM_FILE, "w")
        f.writeLine("You are a CC:Tweaked AI assistant. Use [EXECUTE] blocks for commands.")
        f.close()
    end

    local f = fs.open(SYSTEM_FILE, "r")
    local sys = f.readAll()
    f.close()

    table.insert(messages, 1, { role = "system", content = sys })
end

-- =========================
-- TRIM CONTEXT
-- =========================
local function trimMessages()
    while #messages > 18 do
        table.remove(messages, 2)
    end
end

-- =========================
-- REQUEST QUEUE
-- =========================
local function queueRequest(payload, callback)
    table.insert(requestQueue, {
        payload = payload,
        callback = callback
    })
end

local function processQueue()
    if activeRequest or #requestQueue == 0 then return end

    local job = table.remove(requestQueue, 1)
    activeRequest = true

    local headers = {
        ["Authorization"] = "Bearer " .. API_KEY,
        ["Content-Type"] = "application/json",
        ["HTTP-Referer"] = "https://openrouter.ai",
        ["X-Title"] = "CcShell AI",
        ["User-Agent"] = "Mozilla/5.0"
    }

    local function attempt(payload)
        for i = 1, 3 do
            local res = http.post(URL, payload, headers)

            if res then
                local txt = res.readAll()
                local code = res.getResponseCode()
                res.close()

                if code == 200 and txt and txt:find("{") then
                    local ok, data = pcall(textutils.unserializeJSON, txt)
                    if ok and data and data.choices and data.choices[1] then
                        return data.choices[1].message.content
                    end
                end
            end

            sleep(1 + i)
        end

        return nil
    end

    local reply = attempt(job.payload)

    if job.callback then
        job.callback(reply)
    end

    activeRequest = false
end

-- =========================
-- EXECUTE CAPTURE
-- =========================
local function executeLuaCommands(text)
    for code in string.gmatch(text, "%[EXECUTE%](.-)%[%/EXECUTE%]") do
        term.setTextColor(colors.purple)
        print("\n[EXECUTE]")
        term.setTextColor(colors.gray)
        print("> " .. code)

        local output = {}
        local oldPrint = print

        print = function(...)
            local t = {...}
            local line = ""
            for i, v in ipairs(t) do
                line = line .. tostring(v) .. (i < #t and "\t" or "")
            end
            output[#output + 1] = line
            oldPrint(line)
        end

        local func = load(code, "ai_exec", "t", _ENV)

        if func then
            local results = { pcall(func) }
            local success = table.remove(results, 1)

            print = oldPrint

            local msg = ""

            if #output > 0 then
                msg = msg .. "Printed Output:\n" .. table.concat(output, "\n") .. "\n"
            end

            if #results > 0 then
                msg = msg .. "Return Values:\n"
                for _, v in ipairs(results) do
                    msg = msg .. tostring(v) .. "\n"
                end
            end

            if msg == "" then msg = "No output." end

            table.insert(messages, { role = "system", content = msg })
            saveMemory()

            if success then
                print("[Success]")
            else
                print("[Runtime Error]")
            end
        else
            print = oldPrint
            print("[Syntax Error]")
        end
    end
end

-- =========================
-- ASK AI (ASYNC)
-- =========================
local function askAI(prompt)
    table.insert(messages, { role = "user", content = prompt })
    trimMessages()

    local payload = textutils.serializeJSON({
        model = MODEL,
        messages = messages,
        max_tokens = 250
    })

    queueRequest(payload, function(reply)
        if not reply then
            printError("[AI OFFLINE]")
            return
        end

        reply = sanitizeText(reply)

        appendToHistoryFile("You", prompt)
        appendToHistoryFile("AI", reply)

        table.insert(messages, { role = "assistant", content = reply })
        saveMemory()

        term.setTextColor(colors.cyan)
        write("AI: ")
        term.setTextColor(colors.lightGray)
        printWrapped(reply)

        executeLuaCommands(reply)
        print("")
    end)
end

-- =========================
-- CLEAR
-- =========================
local function clearHistory()
    if fs.exists(HISTORY_FILE) then fs.delete(HISTORY_FILE) end
    messages = {}
    loadSystem()
    print("[System] Cleared")
end

-- =========================
-- COMPACT
-- =========================
local function compactHistory()
    print("[System] Compact not implemented in async version (optional upgrade).")
end

-- =========================
-- MAIN LOOP
-- =========================
term.clear()
term.setCursorPos(1,1)

getApiKey()
loadMemory()
loadSystem()

print("=== CC:Tweaked AI (Async Stable) ===")
print("Commands: exit | clear | compact")

while true do
    processQueue()

    term.setTextColor(colors.green)
    write("You: ")
    term.setTextColor(colors.white)

    local input = read()

    if input == "exit" then break end

    if input == "clear" then
        clearHistory()

    elseif input == "compact" then
        compactHistory()

    elseif input ~= "" then
        askAI(input)
    end
end