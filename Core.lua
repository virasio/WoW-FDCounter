-- FDCounter: Follower Dungeon entry counter
-- Core module: addon namespace and initialization

local ADDON_NAME, FDC = ...

-- Export addon namespace globally for debugging
FDCounter = FDC

-- Addon info
FDC.name = ADDON_NAME
FDC.version = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "dev"

-- Follower Dungeon difficulty ID
FDC.FOLLOWER_DUNGEON_DIFFICULTY = 205
