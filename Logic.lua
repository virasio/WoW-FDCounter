-- FDCounter: Logic module
-- Business logic for counting and detection

local ADDON_NAME, FDC = ...

-- Format seconds into hours and minutes
function FDC:FormatTimeUntilReset()
    local seconds = FDCounterDB.resetTime - time()
    if seconds <= 0 then
        return "now"
    end
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    return string.format("%dh %dm", hours, minutes)
end

-- Increment counter
function FDC:IncrementCounter()
    self:CheckAndResetCounter()
    FDCounterDB.count = FDCounterDB.count + 1
    FDCounterDB.resetTime = self:GetNextResetTime()
end

-- Check if player is in a Follower Dungeon
-- Returns: isFollowerDungeon, instanceID
function FDC:GetFollowerDungeonInfo()
    local _, _, difficultyID, _, _, _, _, instanceID = GetInstanceInfo()
    local isFollowerDungeon = (difficultyID == self.FOLLOWER_DUNGEON_DIFFICULTY)
    return isFollowerDungeon, instanceID
end

-- Print current status to chat
function FDC:PrintStatus()
    print(string.format("FDCounter: %d entries | Reset in %s", 
        self:GetCount(), self:FormatTimeUntilReset()))
end

-- Handle zone change to detect Follower Dungeon entry
function FDC:OnPlayerEnteringWorld(isLogin, isReload)
    -- Don't count on login or reload (player was already inside)
    if isLogin or isReload then
        return
    end
    
    -- Delay check to allow GetInstanceInfo() to update
    C_Timer.After(3, function()
        local isFollowerDungeon, instanceID = self:GetFollowerDungeonInfo()
        
        if isFollowerDungeon then
            -- Only count if this is a new instance
            if self:GetCurrentInstanceID() ~= instanceID then
                self:SetCurrentInstanceID(instanceID)
                self:IncrementCounter()
                self:PrintStatus()
            end
        end
        -- Don't clear currentInstanceID here - only clear on GROUP_LEFT
    end)
end

-- Initialize addon
function FDC:Initialize()
    self:InitializeStorage()
    self:CheckAndResetCounter()
    self:RegisterCommands()
end

-- Handle group left event
function FDC:OnGroupLeft()
    self:ClearCurrentInstance()
end
