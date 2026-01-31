-- FDCounter: Localization
-- All user-facing strings

local ADDON_NAME, FDC = ...

-- Default locale (English)
local L = {
    -- Time formatting
    TIME_NOW = "now",
    TIME_FORMAT = "%dh %dm",

    -- Help command
    HELP_HEADER = "FDCounter %s - Follower Dungeon Account-Wide Entry Tracker",
    HELP_COMMANDS = "Commands:",
    HELP_CMD_DEFAULT = "  /fdcounter            - Show the addon panel",
    HELP_CMD_HELP = "  /fdcounter help       - Show this help message",
    HELP_CMD_RESET = "  /fdcounter reset      - Reset all data and UI",
    HELP_CMD_RESET_DATA = "  /fdcounter reset data - Reset counter and log only",
    HELP_CMD_RESET_UI = "  /fdcounter reset ui   - Reset UI positions only",
    HELP_FOOTER = "Happy hunting! - virasio",
    HINT_HELP = "  Use /fdcounter help to learn more.",

    -- Panel messages
    PANEL_SHOWN = "Panel is now visible.",
    PANEL_ALREADY_VISIBLE = "Panel is already visible.",
    RESET_FULL_CONFIRMATION = "All data and UI settings have been reset.",
    RESET_DATA_CONFIRMATION = "Counter and log have been reset.",
    RESET_UI_CONFIRMATION = "UI positions have been reset.",

    -- UI Panel
    PANEL_HEADER = "Follower Dungeons",
    PANEL_TITLE = "Visited:",
    PANEL_RESET_LABEL = "reset in:",
    PANEL_TIME_FORMAT = "%d:%02d",  -- H:mm format

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
    LOG_TAB_RAW = "Raw Log",
    LOG_TAB_TABLE = "Log Table",
    LOG_TAB_STATS = "Statistics",

    -- Event names (localized)
    EVENT_ENTRY = "Entry",
    EVENT_EXIT = "Exit",
    EVENT_REENTRY = "Re-entry",
    EVENT_COMPLETE = "Completed",

    -- Table view
    LOG_FILTER_ALL = "All",
    LOG_FILTER_CHARACTER = "Character:",
    LOG_FILTER_INSTANCE = "Instance:",
    LOG_COL_TIME = "Time",
    LOG_COL_EVENT = "Event",
    LOG_COL_CHARACTER = "Character",
    LOG_COL_INSTANCE = "Instance",

    -- Stats view
    STAT_TOTAL = "Total",
    STAT_CHARACTER = "Character",
    STATS_ADD_HOUR = "+",
    STATS_REMOVE_HOUR = "-",
    STATS_HOUR_PROMPT = "Hours:",
    STATS_HOUR_INPUT_TITLE = "Add Hour Column",
    STATS_HOUR_INPUT_LABEL = "Enter hours (1-24):",
    STATS_HOUR_DUPLICATE = "FDCounter: Column %dh already exists",
}

-- Store in namespace
FDC.L = L

-- Locale overrides will be added in Stage 3
