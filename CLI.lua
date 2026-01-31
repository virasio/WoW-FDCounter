-- FDCounter: CLI module
-- Slash commands and chat output

local ADDON_NAME, FDC = ...

-- Print header line (used by all output functions)
local function PrintHeader()
    print(string.format(FDC.L.HELP_HEADER, FDC.version))
end

-- Print "panel is now visible" message
function FDC:PrintPanelShown()
    PrintHeader()
    print(self.L.PANEL_SHOWN)
    print(self.L.HINT_HELP)
end

-- Print "panel already visible" message
function FDC:PrintPanelVisible()
    PrintHeader()
    print(self.L.PANEL_ALREADY_VISIBLE)
    print(self.L.HINT_HELP)
end

-- Print reset confirmation
function FDC:PrintResetConfirmation(resetType)
    local L = self.L
    PrintHeader()
    if resetType == "data" then
        print(L.RESET_DATA_CONFIRMATION)
    elseif resetType == "ui" then
        print(L.RESET_UI_CONFIRMATION)
    else
        print(L.RESET_FULL_CONFIRMATION)
    end
end

-- Print help message
function FDC:PrintHelp()
    local L = self.L
    PrintHeader()
    print(L.HELP_COMMANDS)
    print(L.HELP_CMD_DEFAULT)
    print(L.HELP_CMD_HELP)
    print(L.HELP_CMD_RESET)
    print(L.HELP_CMD_RESET_DATA)
    print(L.HELP_CMD_RESET_UI)
    print("")
    print(L.HELP_FOOTER)
end

-- Reposition UI elements to center
local function ResetUIPositions()
    if FDC.panel then
        FDC.panel:ClearAllPoints()
        FDC.panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    if FDC.logWindow then
        FDC.logWindow:ClearAllPoints()
        FDC.logWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        FDC.logWindow:SetSize(FDC.UI.LOG_WINDOW_WIDTH, FDC.UI.LOG_WINDOW_HEIGHT)
    end
end

-- Reset subcommands
local resetCommands = {
    [""] = function()
        FDC:FullReset()
        ResetUIPositions()
        FDC:UpdatePanel()
        FDC:PrintResetConfirmation("full")
    end,
    ["data"] = function()
        FDC:ResetData()
        FDC:UpdatePanel()
        FDC:PrintResetConfirmation("data")
    end,
    ["ui"] = function()
        FDC:ResetUI()
        ResetUIPositions()
        FDC:PrintResetConfirmation("ui")
    end,
}

-- Command definitions
local commands = {
    [""] = function()
        FDC:CheckAndResetCounter()
        if FDC:IsPanelVisible() and FDC.panel and FDC.panel:IsShown() then
            FDC:PrintPanelVisible()
        else
            FDC:ShowPanel()
            FDC:PrintPanelShown()
        end
    end,
    ["reset"] = function(args)
        local subCmd = args:lower():trim()
        local resetCommand = resetCommands[subCmd]
        if resetCommand then
            resetCommand()
        else
            FDC:PrintHelp()
        end
    end,
    ["help"] = function()
        FDC:PrintHelp()
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
            command(args or "")
        else
            FDC:PrintHelp()
        end
    end
end
