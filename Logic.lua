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
-- Returns: isFollowerDungeon, instanceID, instanceName
function FDC:GetFollowerDungeonInfo()
    local instanceName, _, difficultyID, _, _, _, _, instanceID = GetInstanceInfo()
    local isFollowerDungeon = (difficultyID == self.FOLLOWER_DUNGEON_DIFFICULTY)
    return isFollowerDungeon, instanceID, instanceName
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
        local isFollowerDungeon, instanceID, instanceName = self:GetFollowerDungeonInfo()
        local currentInstanceID = self:GetCurrentInstanceID()
        
        if isFollowerDungeon then
            if currentInstanceID == nil then
                -- First entry into this dungeon
                self:SetCurrentInstanceID(instanceID)
                self:IncrementCounter()
                self:LogEvent("entry", instanceID, instanceName)
                self:PrintStatus()
            elseif currentInstanceID ~= instanceID then
                -- Entry into a different dungeon (shouldn't happen often)
                self:SetCurrentInstanceID(instanceID)
                self:IncrementCounter()
                self:LogEvent("entry", instanceID, instanceName)
                self:PrintStatus()
            else
                -- Re-entry into the same dungeon (via portal)
                self:LogEvent("reentry", instanceID, instanceName)
            end
        else
            -- Not in a Follower Dungeon
            if currentInstanceID ~= nil then
                -- Just exited a Follower Dungeon (but still in group)
                local _, exitInstanceID, exitInstanceName = self:GetFollowerDungeonInfo()
                -- Use stored info since we're outside now
                self:LogEvent("exit", currentInstanceID, nil)
            end
        end
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
    local currentInstanceID = self:GetCurrentInstanceID()
    if currentInstanceID ~= nil then
        self:LogEvent("complete", currentInstanceID, nil)
    end
    self:ClearCurrentInstance()
end
