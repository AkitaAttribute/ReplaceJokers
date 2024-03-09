--- STEAMODDED HEADER
--- MOD_NAME: ReplaceJokers
--- MOD_ID: ReplaceJokers
--- MOD_AUTHOR: [Akita Attribute]
--- MOD_DESCRIPTION: A mod to replace all jokers.  Can be used to make runs that only have a select few jokers.

----------------------------------------------
------------MOD CODE -------------------------
local originalMethodRef = G.splash_screen
local originalRarityPool = {}

function G.splash_screen(self)
    local result = originalMethodRef(self)
	
	--logToFile("Joker table size = " .. table_length(G.P_CENTER_POOLS['Joker']) .. "\tBefore")
	
	local jokers = loadJsonFromFile()
	
	--logToFile("Rarity table before = \t" .. tblToStr(G.P_JOKER_RARITY_POOLS))
	
	originalRarityPool = G.P_JOKER_RARITY_POOLS
	G.P_JOKER_RARITY_POOLS = {
        {},{},{},{}
    }
	 
	removeJokersGPCenters()
	
	if jokers then
		G.P_CENTER_POOLS['Joker'] = jokers
		setRarity(jokers)
		setGPCenters(jokers)
	else
		G.P_CENTER_POOLS['Joker'] = {}
	end
	
	--logToFile("Rarity table after = \t" .. tblToStr(G.P_JOKER_RARITY_POOLS))
	--logToFile("Joker table size = " .. table_length(G.P_CENTER_POOLS['Joker']) .. "\tAfter")
	
	return result
end

function setRarity(jokers)
	--for i, pool in ipairs(G.P_JOKER_RARITY_POOLS) do
		--table.insert(pool, "c_base")
	--end

	for id, joker in pairs(jokers) do
		table.insert(G.P_JOKER_RARITY_POOLS[joker.rarity], originalRarityPool[joker.rarity][joker.order])
	end
end

function setGPCenters(jokers)
    for id, joker in pairs(jokers) do
		if G.P_CENTERS[id] then
			G.P_CENTERS[id].set = "Joker"
		else
			G.P_CENTERS[id] = joker
		end
    end
end

function removeJokersGPCenters()
	for id, data in pairs(G.P_CENTERS) do
		if data.set == "Joker" then
			G.P_CENTERS[id].set = "Disabled"
		end
	end
end

function parseJson(json)
    local pos = 1
    json = json:gsub("%s+", "") -- Remove all whitespace

    -- Forward declare the local functions so they are known to each other
    local parseValue, parseObject, parseString, parseNumber

    parseValue = function()
        local startChar = json:sub(pos, pos)
        if startChar == "{" then
            return parseObject()  -- Ensure this matches the function's actual name
        elseif startChar == '"' then
            return parseString()
        elseif startChar:match("[%d%-]") then
            return parseNumber()
        elseif json:sub(pos, pos + 3) == "true" then
            pos = pos + 4
            return true
        elseif json:sub(pos, pos + 4) == "false" then
            pos = pos + 5
            return false
        else
            error("Unexpected value at position " .. pos)
        end
    end

    parseObject = function()  -- This matches the corrected call within parseValue
        local obj = {}
        pos = pos + 1 -- Skip opening brace
        while json:sub(pos, pos) ~= "}" do
            local key = parseString()
            pos = pos + 1 -- Skip colon
            local value = parseValue()
            obj[key] = value
            if json:sub(pos, pos) == "," then
                pos = pos + 1 -- Skip comma
            end
        end
        pos = pos + 1 -- Skip closing brace
        return obj
    end

    parseString = function()
        local sPos = pos + 1 -- Start after opening quote
        local ePos = json:find('"', sPos) - 1
        pos = ePos + 2 -- Set position after closing quote
        return json:sub(sPos, ePos)
    end

    parseNumber = function()
        local numberStr = json:match('[-%d.]+', pos)
        pos = pos + #numberStr
        return tonumber(numberStr)
    end

    local success, result = pcall(parseValue)
    if not success then
        logToFile("Error parsing JSON: " .. result)
        return nil, result
    end
    return result
end

function getJokersFilePath()
	local appDataPath = os.getenv("APPDATA")
	if not appDataPath then
		logToFile("Error retrieving %APPDATA%")
		return
	end

	-- Construct the full path to the file
	local filePath = appDataPath .. "\\Balatro\\Mods\\jokers.json"
	return filePath
end

function loadJsonFromFile()
    local filename = getJokersFilePath()
    if not filename then
        return nil
    end

    local file, err = io.open(filename, "r")
    if not file then
        logToFile("Failed to open file: " .. tostring(err))
        return nil
    end
    
    local content = file:read("*a") -- Read the entire file content
    file:close() -- It's important to close the file when you're done

    -- Parse the JSON content
    local parsedData, err = parseJson(content)
    if not parsedData then
        logToFile("Failed to parse JSON: " .. tostring(err))
        return nil
    end

    return parsedData
end

function logToFile(logString)
	local file = io.open("log.txt", "a")
	file:write(logString .. "\n")
	file:close()
end

function tblToStr(tbl, indent, done)
    done = done or {}
    indent = indent or ''
    local nextIndent = indent .. '  '
    local result = "{\n"
    for key, value in pairs(tbl) do
        result = result .. nextIndent .. tostring(key) .. " = "
        if type(value) == "table" and not done[value] then
            done[value] = true
            result = result .. tblToStr(value, nextIndent, done) .. ",\n"
        else
            result = result .. tostring(value) .. ",\n"
        end
    end
    result = result .. indent .. "}"
    return result
end

----------------------------------------------
------------MOD CODE END----------------------