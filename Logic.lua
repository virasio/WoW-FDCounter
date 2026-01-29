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
                self:SetCurrentInstance(instanceID, instanceName)
                self:IncrementCounter()
                self:LogEvent(self.EventType.ENTRY, instanceID, instanceName)
                self:PrintStatus()
            elseif currentInstanceID ~= instanceID then
                -- Entry into a different dungeon (shouldn't happen often)
                self:SetCurrentInstance(instanceID, instanceName)
                self:IncrementCounter()
                self:LogEvent(self.EventType.ENTRY, instanceID, instanceName)
                self:PrintStatus()
            else
                -- Re-entry into the same dungeon (via portal)
                self:LogEvent(self.EventType.REENTRY, instanceID, instanceName)
            end
        else
            -- Not in a Follower Dungeon
            if currentInstanceID ~= nil then
                -- Just exited a Follower Dungeon (but still in group)
                self:LogEvent(self.EventType.EXIT, currentInstanceID, self:GetCurrentInstanceName())
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
    local currentInstanceName = self:GetCurrentInstanceName()
    if currentInstanceID ~= nil then
        self:LogEvent(self.EventType.COMPLETE, currentInstanceID, currentInstanceName)
    end
    self:ClearCurrentInstance()
end

-- Format timestamp for log display
function FDC:FormatLogTime(timestamp)
    return date("%H:%M:%S", timestamp)
end

-- Print log entries from last H hours
function FDC:PrintLog(hours)
    local log = self:GetLog()
    local cutoff = time() - (hours * 3600)
    local count = 0
    
    print("FDCounter: Log (last " .. hours .. "h)")
    print("Time, Event, Character, Instance")
    
    for _, entry in ipairs(log) do
        if entry.time >= cutoff then
            local instanceDisplay
            if entry.instanceName then
                instanceDisplay = entry.instanceName .. " (ID:" .. (entry.instanceID or "?") .. ")"
            else
                instanceDisplay = "ID:" .. (entry.instanceID or "?")
            end
            print(string.format("%s, %s, %s, %s",
                self:FormatLogTime(entry.time),
                entry.event,
                entry.character,
                instanceDisplay
            ))
            count = count + 1
        end
    end
    
    if count == 0 then
        print("  (no entries)")
    end
end
