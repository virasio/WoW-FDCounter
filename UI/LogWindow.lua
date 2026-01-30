-- FDCounter: Log Window
-- Scrollable window with RAW, Table, and Stats view modes

local ADDON_NAME, FDC = ...

local UI = FDC.UI

-- View modes
local VIEW_RAW = 1
local VIEW_TABLE = 2
local VIEW_STATS = 3

-- Current view mode
local currentView = VIEW_RAW

-- Event name localization mapping
local function GetLocalizedEventName(event)
    local L = FDC.L
    local eventMap = {
        [FDC.EventType.ENTRY] = L.EVENT_ENTRY,
        [FDC.EventType.EXIT] = L.EVENT_EXIT,
        [FDC.EventType.REENTRY] = L.EVENT_REENTRY,
        [FDC.EventType.COMPLETE] = L.EVENT_COMPLETE,
    }
    return eventMap[event] or event
end

-- Format log entries as RAW CSV (timestamp,event,character,instanceID)
local function FormatRawLog(entries)
    if #entries == 0 then
        return ""
    end

    local lines = {}
    for _, entry in ipairs(entries) do
        table.insert(lines, string.format("%d,%s,%s,%s",
            entry.time,
            entry.event,
            entry.character,
            entry.instanceID or ""
        ))
    end
    return table.concat(lines, "\n")
end

-- Format log entries as localized table
local function FormatTableLog(entries)
    local L = FDC.L

    if #entries == 0 then
        return L.LOG_NO_ENTRIES
    end

    local lines = { L.LOG_TABLE_HEADER }
    for _, entry in ipairs(entries) do
        local timeStr = date("%H:%M:%S", entry.time)
        local eventStr = GetLocalizedEventName(entry.event)
        local instanceStr
        if entry.instanceName then
            instanceStr = entry.instanceName .. " (" .. (entry.instanceID or "?") .. ")"
        else
            instanceStr = tostring(entry.instanceID or "?")
        end
        table.insert(lines, string.format("%-9s %-9s %-20s %s",
            timeStr,
            eventStr,
            entry.character,
            instanceStr
        ))
    end
    return table.concat(lines, "\n")
end

-- Format statistics data
local function FormatStatistics(statsData)
    local L = FDC.L

    local lines = {}

    -- Header
    local header = L.STAT_CHARACTER .. ", " .. L.STAT_TOTAL
    for _, h in ipairs(statsData.hours) do
        header = header .. ", " .. h .. "h"
    end
    table.insert(lines, header)

    if statsData.isEmpty then
        table.insert(lines, L.STAT_NO_ENTRIES)
        return table.concat(lines, "\n")
    end

    -- Per character rows
    for _, charData in ipairs(statsData.characters) do
        local line = charData.name .. ", " .. charData.total
        for _, count in ipairs(charData.hourCounts) do
            line = line .. ", " .. count
        end
        table.insert(lines, line)
    end

    -- Total row
    local totalLine = L.STAT_TOTAL .. ", " .. statsData.totals.total
    for _, count in ipairs(statsData.totals.hourCounts) do
        totalLine = totalLine .. ", " .. count
    end
    table.insert(lines, totalLine)

    return table.concat(lines, "\n")
end

-- Create a tab button
local function CreateTabButton(parent, text, viewMode, onClick)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(50, 20)
    btn:SetText(text)
    btn.viewMode = viewMode

    btn:SetScript("OnClick", function()
        currentView = viewMode
        onClick()
    end)

    return btn
end

-- Update tab button states
local function UpdateTabStates(frame)
    local buttons = { frame.tabRaw, frame.tabTable, frame.tabStats }
    for _, btn in ipairs(buttons) do
        if btn.viewMode == currentView then
            btn:SetEnabled(false)
        else
            btn:SetEnabled(true)
        end
    end
end

-- Create the log window
local function CreateLogWindow()
    local L = FDC.L

    local frame = CreateFrame("Frame", "FDCounterLogWindow", UIParent, "BackdropTemplate")
    frame:SetSize(UI.LOG_WINDOW_WIDTH, UI.LOG_WINDOW_HEIGHT)
    frame:SetPoint("CENTER")
    UI.ApplyBackdrop(frame, true)
    frame:SetFrameStrata("HIGH")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    -- Title bar
    frame.titleBar = CreateFrame("Frame", nil, frame)
    frame.titleBar:SetPoint("TOPLEFT", 4, -4)
    frame.titleBar:SetPoint("TOPRIGHT", -4, -4)
    frame.titleBar:SetHeight(20)
    frame.titleBar:EnableMouse(true)
    frame.titleBar:RegisterForDrag("LeftButton")
    frame.titleBar:SetScript("OnDragStart", function() frame:StartMoving() end)
    frame.titleBar:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)

    -- Title text
    frame.titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.titleText:SetPoint("TOPLEFT", 8, -8)
    frame.titleText:SetText(L.LOG_WINDOW_TITLE)

    -- Close button
    frame.closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.closeBtn:SetPoint("TOPRIGHT", 0, 0)
    frame.closeBtn:SetScript("OnClick", function()
        frame:Hide()
    end)

    -- Tab buttons
    local function OnTabClick()
        UpdateTabStates(frame)
        FDC:UpdateLogWindow()
    end

    frame.tabRaw = CreateTabButton(frame, L.LOG_TAB_RAW, VIEW_RAW, OnTabClick)
    frame.tabRaw:SetPoint("TOPLEFT", 8, -26)

    frame.tabTable = CreateTabButton(frame, L.LOG_TAB_TABLE, VIEW_TABLE, OnTabClick)
    frame.tabTable:SetPoint("LEFT", frame.tabRaw, "RIGHT", 2, 0)

    frame.tabStats = CreateTabButton(frame, L.LOG_TAB_STATS, VIEW_STATS, OnTabClick)
    frame.tabStats:SetPoint("LEFT", frame.tabTable, "RIGHT", 2, 0)

    UpdateTabStates(frame)

    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 8, -50)
    scrollFrame:SetPoint("BOTTOMRIGHT", -28, 8)
    frame.scrollFrame = scrollFrame

    -- Edit box (read-only, copyable)
    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetFontObject("GameFontHighlightSmall")
    editBox:SetWidth(scrollFrame:GetWidth() - 16)
    editBox:SetAutoFocus(false)
    editBox:EnableMouse(true)
    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    -- Make read-only by ignoring character input
    editBox:SetScript("OnChar", function() end)
    editBox:SetScript("OnKeyDown", function(self, key)
        -- Allow Ctrl+C for copy
        if key == "C" and IsControlKeyDown() then
            return
        end
        -- Allow Ctrl+A for select all
        if key == "A" and IsControlKeyDown() then
            self:HighlightText()
            return
        end
    end)
    scrollFrame:SetScrollChild(editBox)
    frame.editBox = editBox

    return frame
end

-- Create log window (lazy initialization)
function FDC:CreateLogWindow()
    if not self.logWindow then
        self.logWindow = CreateLogWindow()
    end
end

-- Update log window content based on current view
function FDC:UpdateLogWindow()
    if not self.logWindow then return end

    local text
    if currentView == VIEW_RAW then
        local logData = self:GetLogData(24)
        text = FormatRawLog(logData.entries)
    elseif currentView == VIEW_TABLE then
        local logData = self:GetLogData(24)
        text = FormatTableLog(logData.entries)
    elseif currentView == VIEW_STATS then
        local statsData = self:GetStatisticsData("1,6,24")
        text = FormatStatistics(statsData)
    end

    self.logWindow.editBox:SetText(text or "")
    self.logWindow.editBox:SetCursorPosition(0)
end

-- Show log window
function FDC:ShowLogWindow()
    self:CreateLogWindow()
    self:UpdateLogWindow()
    self.logWindow:Show()
end

-- Hide log window
function FDC:HideLogWindow()
    if self.logWindow then
        self.logWindow:Hide()
    end
end

-- Toggle log window
function FDC:ToggleLogWindow()
    self:CreateLogWindow()
    if self.logWindow:IsShown() then
        self:HideLogWindow()
    else
        self:ShowLogWindow()
    end
end
