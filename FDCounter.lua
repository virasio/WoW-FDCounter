-- FDCounter: Follower Dungeon entry counter

local ADDON_NAME = "FDCounter"

-- Default settings
local defaults = {
    count = 0,
    resetTime = 0,
}

-- Calculate next daily reset timestamp
local function GetNextResetTime()
    local secondsUntilReset = C_DateAndTime.GetSecondsUntilDailyReset()
    return time() + secondsUntilReset
end

-- Check if counter should be reset (past daily reset)
local function CheckAndResetCounter()
    if time() >= FDCounterDB.resetTime then
        FDCounterDB.count = 0
        FDCounterDB.resetTime = GetNextResetTime()
    end
end

-- Format seconds into hours and minutes
local function FormatTimeUntilReset()
    local seconds = FDCounterDB.resetTime - time()
    if seconds <= 0 then
        return "now"
    end
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    return string.format("%dh %dm", hours, minutes)
end

-- Increment counter
local function IncrementCounter()
    CheckAndResetCounter()
    FDCounterDB.count = FDCounterDB.count + 1
    FDCounterDB.resetTime = GetNextResetTime()
end

-- Print current status
local function PrintStatus()
    print(string.format("FDCounter: %d entries | Reset in %s", 
        FDCounterDB.count, FormatTimeUntilReset()))
end

-- Initialize saved variables on addon load
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == ADDON_NAME then
        -- Initialize saved variables with defaults
        if FDCounterDB == nil then
            FDCounterDB = {}
        end
        for key, value in pairs(defaults) do
            if FDCounterDB[key] == nil then
                FDCounterDB[key] = value
            end
        end
        
        -- Check for daily reset
        CheckAndResetCounter()
        
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

-- Slash command handler

SLASH_FDCOUNTER1 = "/fdcounter"

function SlashCmdList.FDCOUNTER(msg)
    msg = msg:lower():trim()
    
    if msg == "reset" then
        FDCounterDB.count = 0
        FDCounterDB.resetTime = GetNextResetTime()
    elseif msg == "++" then
        IncrementCounter()
    else
        CheckAndResetCounter()
    end
    PrintStatus()
end
