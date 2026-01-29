-- FDCounter: Commands module
-- Slash command handling

local ADDON_NAME, FDC = ...

-- Command definitions
local commands = {
    [""] = function()
        FDC:CheckAndResetCounter()
        FDC:PrintStatus(true)
    end,
    ["reset"] = function()
        FDC:ResetCounter()
        FDC:PrintStatus(false)
    end,
    ["log"] = function(args)
        local hours = tonumber(args) or 24
        FDC:PrintLog(hours)
    end,
    ["stat"] = function(args)
        FDC:PrintStatistics(args)
    end,
    ["help"] = function()
        FDC:PrintHelp()
    end,
}

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

-- Register slash commands
function FDC:RegisterCommands()
    SLASH_FDCOUNTER1 = "/fdcounter"
    
    SlashCmdList.FDCOUNTER = function(msg)
        local input = msg:trim()
        local cmd, args = input:match("^(%S*)%s*(.*)$")
        cmd = cmd:lower()
        
        local command = commands[cmd]
        if command then
            command(args)
        else
            -- Unknown command - show status (original behavior)
            FDC:CheckAndResetCounter()
            FDC:PrintStatus()
        end
    end
end
