-- FDCounter: Follower Dungeon entry counter

local ADDON_NAME = "FDCounter"

-- Default settings
local defaults = {
    count = 0,
    resetTime = 0,
    currentInstanceID = nil,
}

-- Follower Dungeon difficulty ID
local FOLLOWER_DUNGEON_DIFFICULTY = 205

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

-- Check if player is in a Follower Dungeon, return difficultyID and instanceID
local function GetFollowerDungeonInfo()
    local _, _, difficultyID, _, _, _, _, instanceID = GetInstanceInfo()
    local isFollowerDungeon = (difficultyID == FOLLOWER_DUNGEON_DIFFICULTY)
    return isFollowerDungeon, instanceID
end

-- Handle zone change to detect Follower Dungeon entry
local function OnPlayerEnteringWorld(isLogin, isReload)
    -- Don't count on login or reload (player was already inside)
    if isLogin or isReload then
        return
    end
    
    -- Delay check to allow GetInstanceInfo() to update
    C_Timer.After(3, function()
        local _, _, difficultyID, _, _, _, _, instanceID = GetInstanceInfo()
        local isFollowerDungeon = (difficultyID == FOLLOWER_DUNGEON_DIFFICULTY)
        
        if isFollowerDungeon then
            -- Only count if this is a new instance
            if FDCounterDB.currentInstanceID ~= instanceID then
                FDCounterDB.currentInstanceID = instanceID
                IncrementCounter()
                PrintStatus()
            end
        end
        -- Don't clear currentInstanceID here - only clear on GROUP_LEFT
    end)
end

-- Initialize saved variables on addon load
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("GROUP_LEFT")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
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
    elseif event == "PLAYER_ENTERING_WORLD" then
        local isLogin, isReload = ...
        OnPlayerEnteringWorld(isLogin, isReload)
    elseif event == "GROUP_LEFT" then
        FDCounterDB.currentInstanceID = nil
    end
end)

-- Slash command handler

SLASH_FDCOUNTER1 = "/fdcounter"

function SlashCmdList.FDCOUNTER(msg)
    msg = msg:lower():trim()
    
    if msg == "reset" then
        FDCounterDB.count = 0
        FDCounterDB.resetTime = GetNextResetTime()
    else
        CheckAndResetCounter()
    end
    PrintStatus()
end
