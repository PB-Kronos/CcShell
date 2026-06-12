-- AI Chatbot for CC:Tweaked (CcShell Executer Fix)
local KEY_FILE = "/var/.ai_key"
local SYSTEM_FILE = "/var/.ai_system"
local HISTORY_FILE = "/var/.ai_history" -- Saves only pure text dialogue lines

-- ALWAYS USE THIS URL:
local URL = "https://openrouter.ai/api/v1/chat/completions"
local MODEL = "openrouter/free"

local API_KEY = ""
local messages = {}

-- Filter UTF-8 symbols to plain ASCII to prevent screen distortion
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

-- Load the API key
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
            print("Key saved successfully.\n")
        else
            error("Invalid Key.")
        end
    end
end

-- Word wrapping for the computer screen
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

-- Export a single line cleanly to the history file (appends to bottom)
local function appendToHistoryFile(sender, text)
    local file = fs.open(HISTORY_FILE, "a")
    file.writeLine(sender .. ": " .. text)
    file.close()
end

-- New Feature: Extracts and runs Lua code block from AI reply
local function executeLuaCommands(text)
    -- Look for [EXECUTE]...[/EXECUTE] tags
    for code in string.gmatch(text, "%[EXECUTE%](.-)%[%/EXECUTE%]") do
        term.setTextColor(colors.purple)
        print("\n[System] Executing AI command...")
        term.setTextColor(colors.gray)
        print("> " .. code)
        
        -- Compile the single line code safely
        local func, err = load(code, "ai_generated", "t", _ENV)
        if func then
            -- Run the function safely without crashing the main script
            local success, runErr = pcall(func)
            if success then
                term.setTextColor(colors.lime)
                print("[System] Success!")
            else
                term.setTextColor(colors.red)
                print("[System] Runtime Error: " .. tostring(runErr))
            end
        else
            term.setTextColor(colors.red)
            print("[System] Syntax Error: " .. tostring(err))
        end
        term.setTextColor(colors.white)
    end
end

-- Load the system prompt and populate chat context from clean text export logs
local function loadSystemAndHistory()
    if not fs.exists(SYSTEM_FILE) then
        local file = fs.open(SYSTEM_FILE, "w")
        file.writeLine("You are an advanced CC:Tweaked OS assistant. You can execute live single-line Lua commands by wrapping them exactly like this: [EXECUTE]fs.makeDir('folder')[/EXECUTE]. Only use valid ComputerCraft APIs.")
        file.close()
    end

    local file = fs.open(SYSTEM_FILE, "r")
    local systemContent = file.readAll()
    file.close()

    -- Establish live runtime table session with system context
    messages = {
        { role = "system", content = systemContent }
    }

    -- Reconstruct live context arrays using clean textual log files
    if fs.exists(HISTORY_FILE) then
        term.setTextColor(colors.gray)
        print("[Last session restored]:")
        
        local histFile = fs.open(HISTORY_FILE, "r")
        local line = histFile.readLine()
        
        while line do
            if line:sub(1, 5) == "You: " then
                local content = line:sub(6)
                table.insert(messages, { role = "user", content = content })
                
                term.setTextColor(colors.green)
                write("You: ")
                term.setTextColor(colors.white)
                print(content)
                
            elseif line:sub(1, 4) == "AI: " then
                local content = line:sub(5)
                table.insert(messages, { role = "assistant", content = content })
                
                term.setTextColor(colors.cyan)
                write("AI: ")
                term.setTextColor(colors.lightGray)
                printWrapped(content)
                print("")
            end
            
            line = histFile.readLine()
        end
        histFile.close()
        
        term.setTextColor(colors.yellow)
        print("---------------------------------------")
    end
end

-- HTTP POST request with string length fix
local function askAI(prompt)
    table.insert(messages, { role = "user", content = prompt })
    
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
        printError("\n[NETWORK ERROR] Handshake refused.")
        if err then print("Details: " .. tostring(err)) end
        table.remove(messages)
        return nil
    end
    
    local responseText = response.readAll()
    local statusCode = response.getResponseCode()
    response.close()
    
    if statusCode ~= 200 then
        printError("\n[API ERROR] Status code: " .. tostring(statusCode))
        print(responseText:sub(1, 150))
        table.remove(messages)
        return nil
    end
    
    local data = textutils.unserializeJSON(responseText)
    if data and data.choices and type(data.choices) == "table" then
        for _, choice in pairs(data.choices) do
            if choice.message and choice.message.content then
                local aiReply = sanitizeText(choice.message.content)
                
                -- Save cleanly to text log file after confirming a successful 200 status code
                appendToHistoryFile("You", prompt)
                appendToHistoryFile("AI", aiReply)
                
                table.insert(messages, { role = "assistant", content = aiReply })
                return aiReply
            end
        end
    end
    
    printError("\n[FORMAT ERROR] Invalid JSON received.")
    table.remove(messages)
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

-- Load system rules and render past text logs
loadSystemAndHistory()

while true do
    term.setTextColor(colors.green)
    write("You: ")
    term.setTextColor(colors.white)
    local input = read()
    
    if input:lower() == "exit" then 
        break
    elseif input:lower() == "clear" then
        if fs.exists(HISTORY_FILE) then fs.delete(HISTORY_FILE) end
        term.clear()
        term.setCursorPos(1,1)
        loadSystemAndHistory()
        term.setTextColor(colors.purple)
        print("[System] History cleared.\n")
    elseif input ~= "" then
        local reply = askAI(input)
        if reply then
            term.setTextColor(colors.cyan)
            write("AI: ")
            term.setTextColor(colors.lightGray)
            printWrapped(reply)
            
            -- Intercept and run code tags instantly
            executeLuaCommands(reply)
            print("")
        end
    end
end
