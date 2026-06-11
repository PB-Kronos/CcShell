-- AI Chatbot voor CC:Tweaked (CcShell Fix)
local KEY_FILE = ".ai_key"
local SYSTEM_FILE = ".ai_system"
local HISTORY_FILE = ".ai_history"

-- ALWAYS USE THIS URL:
local URL = "https://openrouter.ai/api/v1/chat/completions"
local MODEL = "openrouter/free"

local API_KEY = ""
local messages = {}

-- Filter UTF-8 symbolen naar platte ASCII om schermvervorming te voorkomen
local function sanitizeText(text)
    if not text then return "" end
    text = text:gsub("\226\128\153", "'")  -- ’
    text = text:gsub("\226\128\152", "'")  -- ‘
    text = text:gsub("\226\128\156", '"')  -- “
    text = text:gsub("\226\128\157", '"')  -- ”
    text = text:gsub("\226\128\147", "-")  -- –
    text = text:gsub("\226\128\148", "--") -- —
    text = text:gsub("\226\128\162", "*")  -- •
    
    local clean = {}
    for i = 1, #text do
        local byte = text:byte(i)
        if byte >= 32 and byte <= 126 or byte == 10 or byte == 13 then
            table.insert(clean, string.char(byte))
        end
    end
    return table.concat(clean)
end

-- Laad de API-key
local function getApiKey()
    if fs.exists(KEY_FILE) then
        local file = fs.open(KEY_FILE, "r")
        API_KEY = file.readLine():gsub("%s+", "")
        file.close()
    else
        term.setTextColor(colors.yellow)
        print("No OpenRouter API-Key found.")
        term.setTextColor(colors.white)
        write("Enter API-Key: ")
        API_KEY = read("*"):gsub("%s+", "")
        
        if API_KEY and API_KEY ~= "" then
            local file = fs.open(KEY_FILE, "w")
            file.writeLine(API_KEY)
            file.close()
            print("Key saved succesfully.\n")
        else
            error("Invalid Key.")
        end
    end
end

-- Regelafbreking voor het computerscherm
local function printWrapped(text)
    local width, _ = term.getSize()
    local lines = {}
    for rawLine in string.gmatch(text .. "\n", "([^\n]*)\n") do
        local words = {}
        for word in string.gmatch(rawLine, "%S+") do table.insert(words, word) end
        local currentLine = ""
        for _, word in ipairs(words) do
            if #currentLine + #word + 1 > width then
                table.insert(lines, currentLine)
                currentLine = word
            else
                if currentLine == "" then currentLine = word else currentLine = currentLine .. " " .. word end
            end
        end
        table.insert(lines, currentLine)
    end
    for _, line in ipairs(lines) do print(line) end
end

local function saveHistory()
    local file = fs.open(HISTORY_FILE, "w")
    file.write(textutils.serializeJSON(messages))
    file.close()
end

local function loadSystemAndHistory()
    if not fs.exists(SYSTEM_FILE) then
        local file = fs.open(SYSTEM_FILE, "w")
        file.writeLine("You are CcShellAI, an advanced AI for the CcShell ecosystem.")
        file.close()
    end

    local file = fs.open(SYSTEM_FILE, "r")
    local systemContent = file.readAll()
    file.close()

    -- Check of er al een opgeslagen geschiedenis bestaat
    if fs.exists(HISTORY_FILE) then
        local histFile = fs.open(HISTORY_FILE, "r")
        local histContent = histFile.readAll()
        histFile.close()
        
        local savedMessages = textutils.unserializeJSON(histContent)
        if savedMessages and type(savedMessages) == "table" and #savedMessages > 0 then
            messages = savedMessages
            -- Werk de system prompt bij op de eerste index
            messages[1] = { role = "system", content = systemContent }
            
            -- Print de herstelde geschiedenis op het scherm
            term.setTextColor(colors.gray)
            print("[Laatste sessie hersteld]:")
            
            for i = 2, #messages do
                local msg = messages[i]
                if msg.role == "user" then
                    term.setTextColor(colors.green)
                    write("Jij: ")
                    term.setTextColor(colors.white)
                    print(msg.content)
                elseif msg.role == "assistant" then
                    term.setTextColor(colors.cyan)
                    write("AI: ")
                    term.setTextColor(colors.lightGray)
                    printWrapped(msg.content)
                    print("")
                end
            end
            term.setTextColor(colors.yellow)
            print("---------------------------------------")
            return
        end
    end

    -- Fallback als er geen geschiedenisbestand is
    messages = {
        { role = "system", content = systemContent }
    }
end

-- HTTP POST aanroep met string-lengte fix
local function askAI(prompt)
    table.insert(messages, { role = "user", content = prompt })
    saveHistory()
    
    local payloadData = textutils.serializeJSON({
        model = MODEL, 
        messages = messages,
        max_tokens = 250
    })
    
    local headers = {
        ["Authorization"] = "Bearer " .. API_KEY,
        ["Content-Type"] = "application/json",
        ["Content-Length"] = tostring(#payloadData),
        ["HTTP-Referer"] = "https://openrouter.ai", 
        ["X-Title"] = "CcShell Terminal Assistant",
        ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0 Safari/537.36"
    }
    
    print("\n[CcShellAI] Sending direct API request...")
    
    local response, err = http.post(URL, payloadData, headers)
    
    if not response then
        printError("\n[NETWERK FOUT] Handshake geweigerd.")
        if err then print("Details: " .. tostring(err)) end
        table.remove(messages)
        saveHistory()
        return nil
    end
    
    local responseText = response.readAll()
    local statusCode = response.getResponseCode()
    response.close()
    
    if statusCode ~= 200 then
        printError("\n[API FOUT] Statuscode: " .. tostring(statusCode))
        print(responseText:sub(1, 150))
        table.remove(messages)
        saveHistory()
        return nil
    end
    
    local data = textutils.unserializeJSON(responseText)
    if data and data.choices and type(data.choices) == "table" then
        for _, choice in pairs(data.choices) do
            if choice.message and choice.message.content then
                local aiReply = sanitizeText(choice.message.content)
                table.insert(messages, { role = "assistant", content = aiReply })
                saveHistory()
                return aiReply
            end
        end
    end
    
    printError("\n[FORMAAT FOUT] Ongeldige JSON ontvangen.")
    table.remove(messages)
    saveHistory()
    return nil
end

-- Start Terminal Loop
term.clear()
term.setCursorPos(1,1)
getApiKey()

term.clear()
term.setCursorPos(1,1)
term.setTextColor(colors.yellow)
print("=== CcShell AI Terminal ===")
term.setTextColor(colors.white)
print("Model: " .. MODEL)
print("Commands: 'exit' | 'clear'\n")

-- Laad de geschiedenis netjes in de actieve terminal
loadSystemAndHistory()

while true do
    term.setTextColor(colors.green)
    write("Jij: ")
    term.setTextColor(colors.white)
    local input = read()
    
    if input:lower() == "exit" then break
    elseif input:lower() == "clear" then
        if fs.exists(HISTORY_FILE) then fs.delete(HISTORY_FILE) end
        loadSystemAndHistory()
        term.clear()
        term.setCursorPos(1,1)
        term.setTextColor(colors.yellow)
        print("=== CcShell AI Terminal ===")
        term.setTextColor(colors.white)
        print("Model: " .. MODEL)
        print("Commands: 'exit' | 'clear'\n")
        term.setTextColor(colors.purple)
        print("[System] History cleared.\n")
    elseif input ~= "" then
        local reply = askAI(input)
        if reply then
            term.setTextColor(colors.cyan)
            write("AI: ")
            term.setTextColor(colors.lightGray)
            printWrapped(reply)
            print("")
        end
    end
end
