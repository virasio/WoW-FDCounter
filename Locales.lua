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
    HELP_CMD_SHOW = "  /fdcounter show — show UI panel",
    HELP_CMD_HIDE = "  /fdcounter hide — hide UI panel",
    
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

    -- UI Panel
    PANEL_TITLE = "FD Visited:",
    PANEL_RESET_LABEL = "reset in:",
    PANEL_TIME_FORMAT = "%d:%02d",  -- H:mm format
    PANEL_SHOWN = "FDCounter: Panel shown",
    PANEL_HIDDEN = "FDCounter: Panel hidden",

    -- Panel buttons
    BTN_EXIT_TOOLTIP = "Leave Follower Dungeon",
    BTN_RESET_TOOLTIP = "Reset counter",
    BTN_MINUS_TOOLTIP = "Decrease counter",
    BTN_PLUS_TOOLTIP = "Increase counter",
    BTN_INPUT_TOOLTIP = "Set counter value",

    -- Input dialog
    INPUT_DIALOG_TITLE = "Set Counter",
    INPUT_DIALOG_LABEL = "Enter value (0-99):",

    -- Log window
    BTN_LOG_TOOLTIP = "Show event log",
    LOG_WINDOW_TITLE = "FDCounter Log",
    LOG_TAB_RAW = "RAW",
    LOG_TAB_TABLE = "Table",
    LOG_TAB_STATS = "Stats",

    -- Event names (localized)
    EVENT_ENTRY = "Entry",
    EVENT_EXIT = "Exit",
    EVENT_REENTRY = "Re-entry",
    EVENT_COMPLETE = "Complete",

    -- Table view
    LOG_TABLE_HEADER = "Time      Event     Character            Instance",
    LOG_FILTER_ALL = "All",
    LOG_FILTER_CHARACTER = "Character:",
    LOG_FILTER_INSTANCE = "Instance:",
    LOG_COL_TIME = "Time",
    LOG_COL_EVENT = "Event",
    LOG_COL_CHARACTER = "Character",
    LOG_COL_INSTANCE = "Instance",
}

-- Store in namespace
FDC.L = L

-- Future: Add locale-specific overrides
-- local locale = GetLocale()
-- if locale == "ruRU" then
--     L.STATUS_FORMAT = "FDCounter: %d входов | Сброс через %s"
--     -- ...
-- end
