-- FDCounter: Output module
-- All formatting and chat output functions

local ADDON_NAME, FDC = ...

-- Format seconds into "Xh Ym" string
function FDC:FormatTimeUntilReset(seconds)
    local L = self.L
    if seconds <= 0 then
        return L.TIME_NOW
    end
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    return string.format(L.TIME_FORMAT, hours, minutes)
end

-- Format timestamp for log display (HH:MM:SS)
function FDC:FormatLogTime(timestamp)
    return date("%H:%M:%S", timestamp)
end

-- Print status to chat
-- statusData: {count, secondsUntilReset}
-- showHint: boolean, whether to show help hint (updates helpShown flag)
function FDC:PrintStatus(statusData, showHint)
    local L = self.L
    local timeStr = self:FormatTimeUntilReset(statusData.secondsUntilReset)
    print(string.format(L.STATUS_FORMAT, statusData.count, timeStr))
    if showHint and not FDCounterDB.helpShown then
        print(L.HINT_HELP)
        FDCounterDB.helpShown = true
    end
end

-- Print event log to chat
-- logData: {hours, entries[], isEmpty}
function FDC:PrintLog(logData)
    local L = self.L

    print(string.format(L.LOG_HEADER, logData.hours))
    print(L.LOG_COLUMNS)

    if logData.isEmpty then
        print(L.LOG_NO_ENTRIES)
        return
    end

    for _, entry in ipairs(logData.entries) do
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
    end
end

-- Print statistics table to chat
-- statsData: {hours[], instanceID, characters[], totals, isEmpty}
function FDC:PrintStatistics(statsData)
    local L = self.L

    -- Print header
    if statsData.instanceID then
        print(string.format(L.STAT_HEADER_INSTANCE, statsData.instanceID))
    else
        print(L.STAT_HEADER)
    end

    -- Build and print column header
    local header = L.STAT_CHARACTER .. ", " .. L.STAT_TOTAL
    for _, h in ipairs(statsData.hours) do
        header = header .. ", " .. h .. "h"
    end
    print(header)

    if statsData.isEmpty then
        print(L.STAT_NO_ENTRIES)
        return
    end

    -- Print per character rows
    for _, charData in ipairs(statsData.characters) do
        local line = charData.name .. ", " .. charData.total
        for _, count in ipairs(charData.hourCounts) do
            line = line .. ", " .. count
        end
        print(line)
    end

    -- Print total row
    local totalLine = L.STAT_TOTAL .. ", " .. statsData.totals.total
    for _, count in ipairs(statsData.totals.hourCounts) do
        totalLine = totalLine .. ", " .. count
    end
    print(totalLine)
end

-- Print help message
function FDC:PrintHelp()
    local L = self.L
    print(string.format(L.HELP_HEADER, self.version))
    print(L.HELP_CMD_DEFAULT)
    print(L.HELP_CMD_HELP)
    print(L.HELP_CMD_RESET)
    print(L.HELP_CMD_LOG)
    print(L.HELP_CMD_STAT)
    print(L.HELP_CMD_STAT_EX1)
    print(L.HELP_CMD_STAT_EX2)
end
