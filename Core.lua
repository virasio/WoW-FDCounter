-- FDCounter: Follower Dungeon entry counter
-- Core module: addon namespace, constants, and utilities

local ADDON_NAME, FDC = ...

FDC.version = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "dev"

-- Follower Dungeon difficulty ID
FDC.FOLLOWER_DUNGEON_DIFFICULTY = 205

-- Log event types
FDC.EventType = {
    ENTRY = "ENTRY",
    EXIT = "EXIT",
    REENTRY = "REENTRY",
    COMPLETE = "COMPLETE",
}

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
