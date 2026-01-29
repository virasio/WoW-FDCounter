-- FDCounter: Follower Dungeon entry counter
-- Core module: addon namespace and initialization

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
