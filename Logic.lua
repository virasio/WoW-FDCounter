-- FDCounter: Logic module
-- Business logic for counting and detection

local ADDON_NAME, FDC = ...

-- Format seconds into hours and minutes
function FDC:FormatTimeUntilReset()
    local L = self.L
    local seconds = FDCounterDB.resetTime - time()
    if seconds <= 0 then
        return L.TIME_NOW
    end
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    return string.format(L.TIME_FORMAT, hours, minutes)
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
function FDC:PrintStatus(showHint)
    local L = self.L
    print(string.format(L.STATUS_FORMAT, 
        self:GetCount(), self:FormatTimeUntilReset()))
    if showHint and not FDCounterDB.helpShown then
        print(L.HINT_HELP)
        FDCounterDB.helpShown = true
    end
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
    local L = self.L
    local log = self:GetLog()
    local cutoff = time() - (hours * 3600)
    local count = 0
    
    print(string.format(L.LOG_HEADER, hours))
    print(L.LOG_COLUMNS)
    
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
        print(L.LOG_NO_ENTRIES)
    end
end

-- Parse statistics arguments: [H1,H2,...] [instanceID]
-- Hours are comma-separated, instanceID is a standalone number > 100
function FDC:ParseStatArgs(args)
    local hours = {}
    local instanceID = nil
    
    -- Split args by space
    for part in args:gmatch("%S+") do
        if part:find(",") then
            -- Comma-separated list = hours
            for h in part:gmatch("(%d+)") do
                table.insert(hours, tonumber(h))
            end
        else
            -- Single number
            local num = tonumber(part)
            if num then
                if num > 100 then
                    -- Large number = instance ID
                    instanceID = num
                else
                    -- Small number = hours
                    table.insert(hours, num)
                end
            end
        end
    end
    
    return hours, instanceID
end

-- Count entries for a character within time period, optionally filtered by instance
function FDC:CountEntries(log, character, hoursAgo, instanceID)
    local cutoff = hoursAgo and (time() - hoursAgo * 3600) or 0
    local count = 0
    
    for _, entry in ipairs(log) do
        if entry.event == self.EventType.ENTRY then
            if entry.character == character then
                if entry.time >= cutoff then
                    if instanceID == nil or entry.instanceID == instanceID then
                        count = count + 1
                    end
                end
            end
        end
    end
    
    return count
end

-- Get unique characters from log
function FDC:GetCharactersFromLog(log, instanceID)
    local characters = {}
    local seen = {}
    
    for _, entry in ipairs(log) do
        if entry.event == self.EventType.ENTRY then
            if instanceID == nil or entry.instanceID == instanceID then
                if not seen[entry.character] then
                    seen[entry.character] = true
                    table.insert(characters, entry.character)
                end
            end
        end
    end
    
    return characters
end

-- Print statistics
function FDC:PrintStatistics(args)
    local L = self.L
    local hours, instanceID = self:ParseStatArgs(args or "")
    local log = self:GetLog()
    local characters = self:GetCharactersFromLog(log, instanceID)
    
    -- Build header
    local header = L.STAT_CHARACTER .. ", " .. L.STAT_TOTAL
    for _, h in ipairs(hours) do
        header = header .. ", " .. h .. "h"
    end
    
    -- Print header
    if instanceID then
        print(string.format(L.STAT_HEADER_INSTANCE, instanceID))
    else
        print(L.STAT_HEADER)
    end
    print(header)
    
    -- Totals
    local totalAll = 0
    local totalByHours = {}
    for i = 1, #hours do
        totalByHours[i] = 0
    end
    
    -- Print per character
    for _, character in ipairs(characters) do
        local total = self:CountEntries(log, character, nil, instanceID)
        totalAll = totalAll + total
        
        local line = character .. ", " .. total
        for i, h in ipairs(hours) do
            local count = self:CountEntries(log, character, h, instanceID)
            totalByHours[i] = totalByHours[i] + count
            line = line .. ", " .. count
        end
        print(line)
    end
    
    -- Print total row
    if #characters > 0 then
        local totalLine = L.STAT_TOTAL .. ", " .. totalAll
        for i = 1, #hours do
            totalLine = totalLine .. ", " .. totalByHours[i]
        end
        print(totalLine)
    else
        print(L.STAT_NO_ENTRIES)
    end
end
