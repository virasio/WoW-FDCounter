-- FDCounter: Logic module
-- Business logic for counting and detection

local ADDON_NAME, FDC = ...

-- Increment counter
function FDC:IncrementCounter()
    self:CheckAndResetCounter()
    FDCounterDB.count = FDCounterDB.count + 1
    FDCounterDB.resetTime = self:GetNextResetTime()
    self:UpdatePanel()
end

-- Check if player is in a Follower Dungeon
-- Returns: isFollowerDungeon, instanceID
function FDC:GetFollowerDungeonInfo()
    local _, _, difficultyID, _, _, _, _, instanceID = GetInstanceInfo()
    local isFollowerDungeon = (difficultyID == self.FOLLOWER_DUNGEON_DIFFICULTY)
    return isFollowerDungeon, instanceID
end

-- Get status data for display
-- Returns: {count, secondsUntilReset}
function FDC:GetStatusData()
    return {
        count = self:GetCount(),
        secondsUntilReset = FDCounterDB.resetTime - time()
    }
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
        local currentInstanceID = self:GetCurrentInstanceID()

        if isFollowerDungeon then
            if currentInstanceID == nil then
                -- First entry into this dungeon
                self:SetCurrentInstance(instanceID)
                self:IncrementCounter()
                self:LogEvent(self.EventType.ENTRY, instanceID)
                self:PrintStatus(self:GetStatusData(), false)
            elseif currentInstanceID ~= instanceID then
                -- Entry into a different dungeon (shouldn't happen often)
                self:SetCurrentInstance(instanceID)
                self:IncrementCounter()
                self:LogEvent(self.EventType.ENTRY, instanceID)
                self:PrintStatus(self:GetStatusData(), false)
            else
                -- Re-entry into the same dungeon (via portal)
                self:LogEvent(self.EventType.REENTRY, instanceID)
            end
        else
            -- Not in a Follower Dungeon
            if currentInstanceID ~= nil then
                -- Just exited a Follower Dungeon (but still in group)
                self:LogEvent(self.EventType.EXIT, currentInstanceID)
            end
        end
    end)
end

-- Initialize addon
function FDC:Initialize()
    self:InitializeStorage()
    self:CheckAndResetCounter()
    self:RegisterCommands()
    self:CreatePanel()
    if self:IsPanelVisible() then
        self.panel:Show()
        self:UpdatePanel()
    end
    self:StartPanelTimer()
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

-- Get log data for display
-- Returns: {hours, entries[], isEmpty}
function FDC:GetLogData(hours)
    local log = self:GetLog()
    local cutoff = time() - (hours * 3600)
    local entries = {}

    for _, entry in ipairs(log) do
        if entry.time >= cutoff then
            table.insert(entries, entry)
        end
    end

    return {
        hours = hours,
        entries = entries,
        isEmpty = (#entries == 0)
    }
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

-- Get statistics data for display
-- Returns: {hours[], instanceID, characters[], totals, isEmpty}
function FDC:GetStatisticsData(args)
    local hours, instanceID = self:ParseStatArgs(args or "")
    local log = self:GetLog()
    local characterNames = self:GetCharactersFromLog(log, instanceID)

    -- Build character data
    local characters = {}
    local totalAll = 0
    local totalByHours = {}
    for i = 1, #hours do
        totalByHours[i] = 0
    end

    for _, charName in ipairs(characterNames) do
        local total = self:CountEntries(log, charName, nil, instanceID)
        totalAll = totalAll + total

        local hourCounts = {}
        for i, h in ipairs(hours) do
            local count = self:CountEntries(log, charName, h, instanceID)
            totalByHours[i] = totalByHours[i] + count
            table.insert(hourCounts, count)
        end

        table.insert(characters, {
            name = charName,
            total = total,
            hourCounts = hourCounts
        })
    end

    return {
        hours = hours,
        instanceID = instanceID,
        characters = characters,
        totals = {
            total = totalAll,
            hourCounts = totalByHours
        },
        isEmpty = (#characters == 0)
    }
end
