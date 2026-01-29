-- FDCounter: Localization
-- All user-facing strings

local ADDON_NAME, FDC = ...

-- Default locale (English)
local L = {
    -- Status messages
    STATUS_FORMAT = "FDCounter: %d entries | Reset in %s",
    HINT_HELP = "  Use /fdcounter help to see all available commands.",
    TIME_NOW = "now",
    TIME_FORMAT = "%dh %dm",
    
    -- Help command
    HELP_HEADER = "FDCounter v%s - Commands:",
    HELP_CMD_DEFAULT = "  /fdcounter — show current count and time until reset",
    HELP_CMD_HELP = "  /fdcounter help — show this help message",
    HELP_CMD_RESET = "  /fdcounter reset — reset counter and log to zero",
    HELP_CMD_LOG = "  /fdcounter log [H] — show event log for last H hours (default: 24)",
    HELP_CMD_STAT = "  /fdcounter stat [H1,H2,...] [ID] — show statistics",
    HELP_CMD_STAT_EX1 = "    Examples: /fdcounter stat 1,6,12",
    HELP_CMD_STAT_EX2 = "              /fdcounter stat 1,6 2648",
    
    -- Log command
    LOG_HEADER = "FDCounter: Log (last %sh)",
    LOG_COLUMNS = "Time, Event, Character, Instance",
    LOG_NO_ENTRIES = "  (no entries)",
    
    -- Statistics command
    STAT_HEADER = "FDCounter: Statistics",
    STAT_HEADER_INSTANCE = "FDCounter: Statistics (Instance ID:%d)",
    STAT_TOTAL = "Total",
    STAT_CHARACTER = "Character",
    STAT_NO_ENTRIES = "  (no entries)",
}

-- Store in namespace
FDC.L = L

-- Future: Add locale-specific overrides
-- local locale = GetLocale()
-- if locale == "ruRU" then
--     L.STATUS_FORMAT = "FDCounter: %d входов | Сброс через %s"
--     -- ...
-- end
