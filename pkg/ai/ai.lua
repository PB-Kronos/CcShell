-- AI Chatbot for CC:Tweaked (Stable + Output Capture)

local KEY_FILE = "/var/.ai_key"
local SYSTEM_FILE = "/var/.ai_system"
local HISTORY_FILE = "/var/.ai_history"

local URL = "https://openrouter.ai/api/v1/chat/completions"
local MODEL = "openrouter/free"

local API_KEY = ""
local messages = {}

-- ========================
-- TEXT SANITIZER
-- ========================
local function sanitizeText(text)
    if not text then return "" end
    text = text:gsub("\226\128\153", "'")
    text = text:gsub("\226\128\152", "'")
    text = text:gsub("\226\128\156", '"')
    text = text:gsub("\226\128\157", '"')
    text = text:gsub("\226\128\147", "-")
    text = text:gsub("\226\128\148", "--")
    text = text:gsub("\226\128\162", "*")

    local clean = {}
    for i = 1, #text do
        local b = text:byte(i)
        if (b >= 32 and b <= 126) or b == 10 or b == 13 then
            table.insert(clean, string.char(b))
        end
    end
    return table.concat(clean)
end

-- ========================
-- API KEY
-- ========================
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

-- ========================
-- PRINT WRAP
-- ========================
local function printWrapped(text)
    local w = term.getSize()
    for line in text:gmatch("[^\n]+") do
        while #line > w do
            print(line:sub(1, w))
            line = line:sub(w + 1)
        end
        print(line)
    end
end

-- ========================
-- HISTORY
-- ========================
local function appendToHistoryFile(sender, text)
    local f = fs.open(HISTORY_FILE, "a")
    f.writeLine(sender .. ": " .. text)
    f.close()
end

-- ========================
-- SAFE HTTP REQUEST
-- ========================
local function sendRequest()
    local payload = textutils.serializeJSON({
        model = MODEL,
        messages = messages,
        max_tokens = 250
    })

    local headers = {
        ["Authorization"] = "Bearer " .. API_KEY,
        ["Content-Type"] = "application/json",
        ["Content-Length"] = tostring(#payload),
        ["HTTP-Referer"] = "https://openrouter.ai",
        ["X-Title"] = "CcShell AI",
        ["User-Agent"] = "Mozilla/5.0"
    }

    for attempt = 1, 3 do
        print("[Request attempt " .. attempt .. "]")

        local res, err = http.post(URL, payload, headers)

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

        sleep(1)
    end

    return nil
end

-- ========================
-- ASK AI
-- ========================
local function askAI(prompt)
    table.insert(messages, { role = "user", content = prompt })

    if #messages > 20 then
        table.remove(messages, 2)
    end

    local reply = sendRequest()

    if reply then
        reply = sanitizeText(reply)

        appendToHistoryFile("You", prompt)
        appendToHistoryFile("AI", reply)

        table.insert(messages, { role = "assistant", content = reply })
        return reply
    end

    table.remove(messages)
    printError("[FAILED] No valid response.")
    return nil
end

-- ========================
-- SEND ROLE MESSAGE
-- ========================
local function sendRoleMessage(role, content)
    table.insert(messages, { role = role, content = content })

    local reply = sendRequest()

    if reply then
        reply = sanitizeText(reply)

        appendToHistoryFile(role, content)
        appendToHistoryFile("AI", reply)

        table.insert(messages, { role = "assistant", content = reply })
        return reply
    end

    table.remove(messages)
    return nil
end

-- ========================
-- EXECUTE + CAPTURE OUTPUT
-- ========================
local function executeLuaCommands(text)
    for code in string.gmatch(text, "%[EXECUTE%](.-)%[%/EXECUTE%]") do
        term.setTextColor(colors.purple)
        print("\n[Executing]")
        term.setTextColor(colors.gray)
        print("> " .. code)

        local output = {}
        local oldPrint = print

        print = function(...)
            local t = {}
            for i, v in ipairs({...}) do
                t[i] = tostring(v)
            end
            local line = table.concat(t, "\t")
            table.insert(output, line)
            oldPrint(line)
        end

        local func, err = load(code, "ai", "t", _ENV)

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

            sendRoleMessage("output", msg)

            if success then
                term.setTextColor(colors.lime)
                print("[Success]")
            else
                term.setTextColor(colors.red)
                print("[Runtime Error]")
            end
        else
            print = oldPrint
            term.setTextColor(colors.red)
            print("[Syntax Error]")
            sendRoleMessage("output", "Syntax Error: " .. tostring(err))
        end

        term.setTextColor(colors.white)
    end
end

-- ========================
-- LOAD SYSTEM + HISTORY
-- ========================
local function loadSystemAndHistory()
    if not fs.exists(SYSTEM_FILE) then
        local f = fs.open(SYSTEM_FILE, "w")
        f.writeLine("You are a CC:Tweaked assistant. Use [EXECUTE]...[/EXECUTE] for commands.")
        f.close()
    end

    local f = fs.open(SYSTEM_FILE, "r")
    local sys = f.readAll()
    f.close()

    messages = {
        { role = "system", content = sys }
    }
end

-- ========================
-- MAIN LOOP
-- ========================
term.clear()
term.setCursorPos(1,1)

getApiKey()

term.setTextColor(colors.yellow)
print("=== CcShell AI ===")
term.setTextColor(colors.white)

loadSystemAndHistory()

while true do
    term.setTextColor(colors.green)
    write("You: ")
    term.setTextColor(colors.white)

    local input = read()

    if input == "exit" then break end

    if input ~= "" then
        local reply = askAI(input)

        if reply then
            term.setTextColor(colors.cyan)
            write("AI: ")
            term.setTextColor(colors.lightGray)
            printWrapped(reply)

            executeLuaCommands(reply)
            print("")
        end
    end
end