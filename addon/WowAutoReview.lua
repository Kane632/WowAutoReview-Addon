-- SavedVariablesPerCharacter: WowAutoReviewDB
WowAutoReviewDB = WowAutoReviewDB or {}

local frame = CreateFrame("Frame")

-- Helper to build the per-character key
local function getCharacterKey()
    local name = UnitName("player") or "Unknown"
    local realm = GetRealmName() or "UnknownRealm"
    return name .. "-" .. realm, name, realm
end

-- Perform all data collection and saving when the player logs out (game will write SavedVariables afterwards)
local ticker = nil

local function startSnapshotTicker()
    if ticker then return end
    if not C_Timer or not C_Timer.NewTicker then return end
    -- every 60 seconds capture gold and request time played when not in an instance
    ticker = C_Timer.NewTicker(60, function()
        local inInstance, instanceType = IsInInstance()
        if inInstance and instanceType and instanceType ~= "none" then
            return
        end

        local key, name, realm = getCharacterKey()
        local rec = WowAutoReviewDB[key] or {}
        rec.name = name
        rec.realm = realm
        rec.level = UnitLevel("player") or rec.level or 0
        if GetMoney then rec.gold = GetMoney() end
        WowAutoReviewDB[key] = rec

        if RequestTimePlayed then
            frame:RegisterEvent("TIME_PLAYED_MSG")
            frame._pendingRec = rec
            frame._pendingKey = key
            RequestTimePlayed()
        end
    end)
end

local function stopSnapshotTicker()
    if ticker then
        ticker:Cancel()
        ticker = nil
    end
end

local function saveOnLogout()
    local key, name, realm = getCharacterKey()
    local rec = WowAutoReviewDB[key] or {}

    rec.name = name
    rec.realm = realm
    rec.level = UnitLevel("player") or rec.level or 0

    -- Capture gold immediately
    if GetMoney then
        rec.gold = GetMoney()
    end

    rec.lastSeen = time()
    if not rec.firstSeen then rec.firstSeen = rec.lastSeen end

    -- Store pending record while we request time played asynchronously
    frame._pendingRec = rec
    frame._pendingKey = key

    if RequestTimePlayed then
        -- Register to receive TIME_PLAYED_MSG; the handler will write the saved record
        frame:RegisterEvent("TIME_PLAYED_MSG")
        RequestTimePlayed()
    else
        -- If RequestTimePlayed isn't available, just write what we have (no fallback to GetTimePlayed)
        WowAutoReviewDB[key] = rec
        frame._pendingRec = nil
        frame._pendingKey = nil
    end
end

-- Register only the logout event; everything else is captured at that time
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        -- Start periodic snapshots once the player is loaded
        startSnapshotTicker()
    elseif event == "PLAYER_LOGOUT" then
        -- stop periodic snapshots and attempt a final save
        stopSnapshotTicker()
        saveOnLogout()
    elseif event == "TIME_PLAYED_MSG" then
        -- Received authoritative playtimes from RequestTimePlayed
        local totalTimePlayed, timePlayedThisLevel = ...
        local rec = frame._pendingRec
        local key = frame._pendingKey
        if rec and key then
            if totalTimePlayed then rec.totalPlayTime = totalTimePlayed end
            if timePlayedThisLevel then rec.levelMaxTime = timePlayedThisLevel end
            WowAutoReviewDB[key] = rec
        end
        frame._pendingRec = nil
        frame._pendingKey = nil
        frame:UnregisterEvent("TIME_PLAYED_MSG")
    end
end)

-- Slash command to print the current character record to chat for debugging
SLASH_WOWAUTOREVIEW1 = "/war"
SlashCmdList["WOWAUTOREVIEW"] = function()
    local key = (UnitName("player") or "Unknown") .. "-" .. (GetRealmName() or "UnknownRealm")
    local rec = WowAutoReviewDB[key]
    if not rec then
        print("WowAutoReview: no record for this character yet.")
        return
    end
    print("WowAutoReview record for:", rec.name, rec.realm)
    print(" Level:", rec.level)
    print(" TotalPlayTime (s):", rec.totalPlayTime)
    print(" LevelMaxTime (s):", rec.levelMaxTime)
    local g = rec.gold or 0
    -- format gold: gold (g), silver (s), copper (c)
    local gold = math.floor((g or 0) / 10000)
    local silver = math.floor(((g or 0) % 10000) / 100)
    local copper = (g or 0) % 100
    print(string.format(" Gold: %d g %d s %d c", gold, silver, copper))
    print(" FirstSeen:", date("%c", rec.firstSeen or 0))
    print(" LastSeen:", date("%c", rec.lastSeen or 0))
end
