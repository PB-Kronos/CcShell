-- =================================================================
-- Originele ComputerCraft shell.lua Alias Logica & Functionaliteit
-- =================================================================

-- De interne tabel waarin alle actieve aliassen worden opgeslagen.
local tAliases = {}

-- 1. De shell.setAlias functie (Originele implementatie)
local function setAlias( _sCommand, _sProgram )
    if type( _sCommand ) ~= "string" then
        error( "bad argument #1 (expected string, got " .. type( _sCommand ) .. ")", 2 )
    end
    if type( _sProgram ) ~= "string" then
        error( "bad argument #2 (expected string, got " .. type( _sProgram ) .. ")", 2 )
    end
    tAliases[ _sCommand ] = _sProgram
end

-- 2. De shell.clearAlias functie (Originele implementatie)
local function clearAlias( _sCommand )
    if type( _sCommand ) ~= "string" then
        error( "bad argument #1 (expected string, got " .. type( _sCommand ) .. ")", 2 )
    end
    tAliases[ _sCommand ] = nil
end

-- 3. De shell.aliases functie (Originele implementatie)
local function aliases()
    -- Maakt een veilige kopie van de tabel
    local tCopy = {}
    for k, v in pairs( tAliases ) do
        tCopy[k] = v
    end
    return tCopy
end

-- 4. De gerelateerde code: Hoe de shell aliassen vertaalt
local function resolveAlias( _sCommand )
    if type( _sCommand ) ~= "string" then
        return nil
    end

    -- Controleer of het ingetikte commando bestaat in onze alias tabel
    if tAliases[ _sCommand ] then
        return tAliases[ _sCommand ]
    end

    -- Geen alias gevonden? Retourneer de input zoals hij is
    return _sCommand
end


-- =================================================================
-- DEMONSTRATIE / VERIFICATIE VAN DE BUNDEL
-- =================================================================

print("--- Testen van de gecopieerde shell.lua alias functionaliteit ---")

-- Test 1: Alias instellen
setAlias("ls", "list")
setAlias("dir", "list")
setAlias("rm", "delete")

-- Test 2: Controleren of de resolutie werkt
local commando1 = "ls"
local vertaald1 = resolveAlias(commando1)
print("Invoer: '" .. commando1 .. "' -> Wordt uitgevoerd als: '" .. vertaald1 .. "'")

-- Test 3: Een alias wissen
clearAlias("dir")

-- Test 4: Alle actieve aliassen ophalen via de gekloonde tabel
print("\nHuidige actieve aliassen in de tabel:")
local actieveAliassen = aliases()
for aliasNaam, programma in pairs(actieveAliassen) do
    print("  " .. aliasNaam .. " => " .. programma)
end
