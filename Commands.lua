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
    print("  /fdcounter help - " .. commands["help"].help)
end

-- Register slash commands
function FDC:RegisterCommands()
    SLASH_FDCOUNTER1 = "/fdcounter"
    
    SlashCmdList.FDCOUNTER = function(msg)
        local cmd = msg:lower():trim()
        
        local command = commands[cmd]
        if command then
            command.handler()
        else
            -- Unknown command - show status (original behavior)
            FDC:CheckAndResetCounter()
            FDC:PrintStatus()
        end
    end
end
