-- FDCounter: Commands module
-- Slash command handling

local ADDON_NAME, FDC = ...

-- Command definitions
local commands = {
    [""] = {
        handler = function()
            FDC:CheckAndResetCounter()
            FDC:PrintStatus()
        end,
        help = "Show current count and time until reset",
    },
    ["reset"] = {
        handler = function()
            FDC:ResetCounter()
            FDC:PrintStatus()
        end,
        help = "Reset counter to zero",
    },
    ["log"] = {
        handler = function(args)
            local hours = tonumber(args) or 24
            FDC:PrintLog(hours)
        end,
        help = "Show log for last [H] hours (default: 24)",
    },
    ["help"] = {
        handler = function()
            FDC:PrintHelp()
        end,
        help = "Show this help message",
    },
}

-- Print help message
function FDC:PrintHelp()
    print("FDCounter v" .. self.version .. " - Commands:")
    print("  /fdcounter - " .. commands[""].help)
    print("  /fdcounter reset - " .. commands["reset"].help)
    print("  /fdcounter log [H] - " .. commands["log"].help)
    print("  /fdcounter help - " .. commands["help"].help)
end

-- Register slash commands
function FDC:RegisterCommands()
    SLASH_FDCOUNTER1 = "/fdcounter"
    
    SlashCmdList.FDCOUNTER = function(msg)
        local input = msg:trim()
        local cmd, args = input:match("^(%S*)%s*(.*)$")
        cmd = cmd:lower()
        
        local command = commands[cmd]
        if command then
            command.handler(args)
        else
            -- Unknown command - show status (original behavior)
            FDC:CheckAndResetCounter()
            FDC:PrintStatus()
        end
    end
end
