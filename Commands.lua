-- FDCounter: Commands module
-- Slash command handling

local ADDON_NAME, FDC = ...

-- Command definitions
local commands = {
    [""] = {
        handler = function()
            FDC:CheckAndResetCounter()
            FDC:PrintStatus(true)
        end,
        help = "Show current count and time until reset",
    },
    ["reset"] = {
        handler = function()
            FDC:ResetCounter()
            FDC:PrintStatus(false)
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
    ["stat"] = {
        handler = function(args)
            FDC:PrintStatistics(args)
        end,
        help = "Show statistics [H1,H2,...] [instanceID]",
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
    print("  /fdcounter — show current count and time until reset")
    print("  /fdcounter help — show this help message")
    print("  /fdcounter reset — reset counter and log to zero")
    print("  /fdcounter log [H] — show event log for last H hours (default: 24)")
    print("  /fdcounter stat [H1,H2,...] [ID] — show statistics")
    print("    Examples: /fdcounter stat 1,6,12")
    print("              /fdcounter stat 1,6 2648")
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
