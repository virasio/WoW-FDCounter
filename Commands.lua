-- FDCounter: Commands module
-- Slash command handling

local ADDON_NAME, FDC = ...

-- Command definitions
local commands = {
    [""] = function()
        FDC:CheckAndResetCounter()
        local data = FDC:GetStatusData()
        FDC:PrintStatus(data, true)
    end,
    ["reset"] = function()
        FDC:ResetCounter()
        local data = FDC:GetStatusData()
        FDC:PrintStatus(data, false)
    end,
    ["log"] = function(args)
        local hours = tonumber(args) or 24
        local data = FDC:GetLogData(hours)
        FDC:PrintLog(data)
    end,
    ["stat"] = function(args)
        local data = FDC:GetStatisticsData(args)
        FDC:PrintStatistics(data)
    end,
    ["help"] = function()
        FDC:PrintHelp()
    end,
    ["show"] = function()
        FDC:ShowPanel()
    end,
    ["hide"] = function()
        FDC:HidePanel()
    end,
}

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
            local data = FDC:GetStatusData()
            FDC:PrintStatus(data, false)
        end
    end
end
