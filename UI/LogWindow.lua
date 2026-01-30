-- FDCounter: Log Window
-- Scrollable window with RAW, Table, and Stats view modes

local ADDON_NAME, FDC = ...

local UI = FDC.UI

-- View modes
local VIEW_STATS = 1
local VIEW_TABLE = 2
local VIEW_RAW = 3

-- Current state
local currentView = VIEW_STATS
local tableFilters = { character = nil, instance = nil }
local statsFilters = { instance = nil }
local statsHours = { 1, 6, 24 }  -- Default hour columns

-- Table row pools
local tableRowPool = {}
local statsRowPool = {}
local TABLE_ROW_HEIGHT = 16
local TABLE_HEADER_HEIGHT = 20
local STATS_COL_WIDTH = 40  -- Width for hour columns

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

-- Get unique values from log for filters
local function GetUniqueCharacters(entries)
    local seen = {}
    local list = {}
    for _, entry in ipairs(entries) do
        if not seen[entry.character] then
            seen[entry.character] = true
            table.insert(list, entry.character)
        end
    end
    table.sort(list)
    return list
end

-- Get instance name by ID (localized)
local function GetInstanceName(instanceID)
    if not instanceID then return nil end
    local name = GetRealZoneText(instanceID)
    if name and name ~= "" then
        return name
    end
    return nil
end

local function GetUniqueInstances(entries)
    local seen = {}
    local list = {}
    for _, entry in ipairs(entries) do
        local key = entry.instanceID or 0
        if not seen[key] then
            seen[key] = true
            local name = GetInstanceName(entry.instanceID) or ("ID:" .. (entry.instanceID or "?"))
            table.insert(list, {
                id = entry.instanceID,
                name = name
            })
        end
    end
    table.sort(list, function(a, b) return (a.name or "") < (b.name or "") end)
    return list
end

-- Filter entries based on current filters
local function FilterEntries(entries)
    local filtered = {}
    for _, entry in ipairs(entries) do
        local passChar = (tableFilters.character == nil) or (entry.character == tableFilters.character)
        local passInst = (tableFilters.instance == nil) or (entry.instanceID == tableFilters.instance)
        if passChar and passInst then
            table.insert(filtered, entry)
        end
    end
    return filtered
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

-- Update editBox width to match scroll frame
local function UpdateEditBoxWidth(frame)
    if frame.rawView and frame.rawView.scrollFrame then
        local scrollWidth = frame.rawView.scrollFrame:GetWidth()
        frame.rawView.editBox:SetWidth(math.max(1, scrollWidth - 16))
    end
end

-- Save window position and size
local function SaveWindowState(frame)
    FDC:SaveLogWindowPosition(frame:GetPoint())
    FDC:SaveLogWindowSize(frame:GetWidth(), frame:GetHeight())
end

-- Create dropdown menu
local function CreateDropdown(parent, name, width)
    local dropdown = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(dropdown, width)
    return dropdown
end

-- Initialize character dropdown
local function InitCharacterDropdown(dropdown, entries, onChange)
    local L = FDC.L

    UIDropDownMenu_Initialize(dropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()

        -- "All" option
        info.text = L.LOG_FILTER_ALL
        info.value = nil
        info.checked = (tableFilters.character == nil)
        info.func = function()
            tableFilters.character = nil
            UIDropDownMenu_SetText(dropdown, L.LOG_FILTER_ALL)
            onChange()
        end
        UIDropDownMenu_AddButton(info, level)

        -- Character options
        local characters = GetUniqueCharacters(entries)
        for _, char in ipairs(characters) do
            info = UIDropDownMenu_CreateInfo()
            info.text = char
            info.value = char
            info.checked = (tableFilters.character == char)
            info.func = function()
                tableFilters.character = char
                UIDropDownMenu_SetText(dropdown, char)
                onChange()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    UIDropDownMenu_SetText(dropdown, tableFilters.character or L.LOG_FILTER_ALL)
end

-- Initialize instance dropdown
local function InitInstanceDropdown(dropdown, entries, onChange)
    local L = FDC.L

    UIDropDownMenu_Initialize(dropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()

        -- "All" option
        info.text = L.LOG_FILTER_ALL
        info.value = nil
        info.checked = (tableFilters.instance == nil)
        info.func = function()
            tableFilters.instance = nil
            UIDropDownMenu_SetText(dropdown, L.LOG_FILTER_ALL)
            onChange()
        end
        UIDropDownMenu_AddButton(info, level)

        -- Instance options
        local instances = GetUniqueInstances(entries)
        for _, inst in ipairs(instances) do
            info = UIDropDownMenu_CreateInfo()
            info.text = inst.name
            info.value = inst.id
            info.checked = (tableFilters.instance == inst.id)
            info.func = function()
                tableFilters.instance = inst.id
                UIDropDownMenu_SetText(dropdown, inst.name)
                onChange()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    -- Set current text
    if tableFilters.instance then
        local instances = GetUniqueInstances(entries)
        for _, inst in ipairs(instances) do
            if inst.id == tableFilters.instance then
                UIDropDownMenu_SetText(dropdown, inst.name)
                return
            end
        end
    end
    UIDropDownMenu_SetText(dropdown, L.LOG_FILTER_ALL)
end

-- Create or get a table row from pool
local function GetTableRow(parent, index)
    if tableRowPool[index] then
        tableRowPool[index]:Show()
        return tableRowPool[index]
    end

    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(TABLE_ROW_HEIGHT)

    -- Alternating background
    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.bg:SetColorTexture(1, 1, 1, index % 2 == 0 and 0.05 or 0)

    -- Columns: Time (60), Event (70), Character (120), Instance (rest)
    row.timeText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.timeText:SetPoint("LEFT", 4, 0)
    row.timeText:SetWidth(56)
    row.timeText:SetJustifyH("LEFT")

    row.eventText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.eventText:SetPoint("LEFT", 64, 0)
    row.eventText:SetWidth(66)
    row.eventText:SetJustifyH("LEFT")

    row.charText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.charText:SetPoint("LEFT", 134, 0)
    row.charText:SetWidth(116)
    row.charText:SetJustifyH("LEFT")

    row.instText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.instText:SetPoint("LEFT", 254, 0)
    row.instText:SetPoint("RIGHT", -4, 0)
    row.instText:SetJustifyH("LEFT")

    tableRowPool[index] = row
    return row
end

-- Hide all table rows
local function HideAllTableRows()
    for _, row in pairs(tableRowPool) do
        row:Hide()
    end
end

-- Create table header
local function CreateTableHeader(parent)
    local L = FDC.L

    local header = CreateFrame("Frame", nil, parent)
    header:SetHeight(TABLE_HEADER_HEIGHT)
    header:SetPoint("TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", 0, 0)

    header.bg = header:CreateTexture(nil, "BACKGROUND")
    header.bg:SetAllPoints()
    header.bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)

    -- Column headers
    header.timeText = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    header.timeText:SetPoint("LEFT", 4, 0)
    header.timeText:SetText(L.LOG_COL_TIME)

    header.eventText = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    header.eventText:SetPoint("LEFT", 64, 0)
    header.eventText:SetText(L.LOG_COL_EVENT)

    header.charText = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    header.charText:SetPoint("LEFT", 134, 0)
    header.charText:SetText(L.LOG_COL_CHARACTER)

    header.instText = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    header.instText:SetPoint("LEFT", 254, 0)
    header.instText:SetText(L.LOG_COL_INSTANCE)

    return header
end

-- Create RAW view container
local function CreateRawView(parent)
    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint("TOPLEFT", 8, -50)
    container:SetPoint("BOTTOMRIGHT", -8, 20)

    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", -20, 0)
    container.scrollFrame = scrollFrame

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
    editBox:SetScript("OnChar", function() end)
    editBox:SetScript("OnKeyDown", function(self, key)
        if key == "C" and IsControlKeyDown() then
            return
        end
        if key == "A" and IsControlKeyDown() then
            self:HighlightText()
            return
        end
    end)
    scrollFrame:SetScrollChild(editBox)
    container.editBox = editBox

    return container
end

-- Create Table view container
local function CreateTableView(parent)
    local L = FDC.L
    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint("TOPLEFT", 8, -50)
    container:SetPoint("BOTTOMRIGHT", -8, 20)

    -- Filter row
    local filterRow = CreateFrame("Frame", nil, container)
    filterRow:SetPoint("TOPLEFT", 0, 0)
    filterRow:SetPoint("TOPRIGHT", 0, 0)
    filterRow:SetHeight(28)

    -- Character filter label
    local charLabel = filterRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    charLabel:SetPoint("LEFT", 0, 0)
    charLabel:SetText(L.LOG_FILTER_CHARACTER)

    -- Character dropdown
    container.charDropdown = CreateDropdown(filterRow, "FDCLogCharDropdown", 100)
    container.charDropdown:SetPoint("LEFT", charLabel, "RIGHT", -10, -2)

    -- Instance filter label
    local instLabel = filterRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    instLabel:SetPoint("LEFT", container.charDropdown, "RIGHT", 10, 2)
    instLabel:SetText(L.LOG_FILTER_INSTANCE)

    -- Instance dropdown
    container.instDropdown = CreateDropdown(filterRow, "FDCLogInstDropdown", 120)
    container.instDropdown:SetPoint("LEFT", instLabel, "RIGHT", -10, -2)

    container.filterRow = filterRow

    -- Table area (below filters)
    local tableArea = CreateFrame("Frame", nil, container)
    tableArea:SetPoint("TOPLEFT", 0, -32)
    tableArea:SetPoint("BOTTOMRIGHT", 0, 0)
    container.tableArea = tableArea

    -- Table header
    container.tableHeader = CreateTableHeader(tableArea)

    -- Scroll frame for rows
    local scrollFrame = CreateFrame("ScrollFrame", nil, tableArea, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 0, -TABLE_HEADER_HEIGHT)
    scrollFrame:SetPoint("BOTTOMRIGHT", -20, 0)
    container.scrollFrame = scrollFrame

    -- Content frame for rows
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(scrollFrame:GetWidth(), 1)
    scrollFrame:SetScrollChild(content)
    container.content = content

    return container
end

-- Get or create stats row from pool
local function GetStatsRow(parent, index)
    if statsRowPool[index] then
        statsRowPool[index]:Show()
        return statsRowPool[index]
    end

    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(TABLE_ROW_HEIGHT)

    -- Alternating background
    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.bg:SetColorTexture(1, 1, 1, index % 2 == 0 and 0.05 or 0)

    -- Character name column (wider)
    row.charText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.charText:SetPoint("LEFT", 4, 0)
    row.charText:SetWidth(130)
    row.charText:SetJustifyH("LEFT")

    -- Total column
    row.totalText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.totalText:SetPoint("LEFT", 138, 0)
    row.totalText:SetWidth(STATS_COL_WIDTH)
    row.totalText:SetJustifyH("CENTER")

    -- Hour columns (created dynamically)
    row.hourTexts = {}

    statsRowPool[index] = row
    return row
end

-- Hide all stats rows
local function HideAllStatsRows()
    for _, row in pairs(statsRowPool) do
        row:Hide()
    end
end

-- Create stats table header (will be rebuilt when hours change)
local function CreateStatsHeader(parent)
    local L = FDC.L

    local header = CreateFrame("Frame", nil, parent)
    header:SetHeight(TABLE_HEADER_HEIGHT)
    header:SetPoint("TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", 0, 0)

    header.bg = header:CreateTexture(nil, "BACKGROUND")
    header.bg:SetAllPoints()
    header.bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)

    -- Character column
    header.charText = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    header.charText:SetPoint("LEFT", 4, 0)
    header.charText:SetText(L.STAT_CHARACTER)

    -- Total column
    header.totalText = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    header.totalText:SetPoint("LEFT", 138, 0)
    header.totalText:SetText(L.STAT_TOTAL)

    -- Hour column headers (created dynamically)
    header.hourTexts = {}

    return header
end

-- Update stats header columns
local function UpdateStatsHeaderColumns(header)
    -- Hide existing hour texts
    for _, text in ipairs(header.hourTexts) do
        text:Hide()
    end

    -- Create/show hour column headers
    for i, h in ipairs(statsHours) do
        if not header.hourTexts[i] then
            header.hourTexts[i] = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        end
        local text = header.hourTexts[i]
        text:SetPoint("LEFT", 138 + STATS_COL_WIDTH * i, 0)
        text:SetText(h .. "h")
        text:Show()
    end
end

-- Update stats row columns
local function UpdateStatsRowColumns(row, charData)
    row.charText:SetText(charData.name)
    row.totalText:SetText(tostring(charData.total))

    -- Hide existing hour texts
    for _, text in ipairs(row.hourTexts) do
        text:Hide()
    end

    -- Create/show hour values
    for i, count in ipairs(charData.hourCounts) do
        if not row.hourTexts[i] then
            row.hourTexts[i] = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.hourTexts[i]:SetWidth(STATS_COL_WIDTH)
            row.hourTexts[i]:SetJustifyH("CENTER")
        end
        local text = row.hourTexts[i]
        text:SetPoint("LEFT", 138 + STATS_COL_WIDTH * i, 0)
        text:SetText(tostring(count))
        text:Show()
    end
end

-- Create Stats view container
local function CreateStatsView(parent)
    local L = FDC.L
    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint("TOPLEFT", 8, -50)
    container:SetPoint("BOTTOMRIGHT", -8, 20)

    -- Filter/control row
    local filterRow = CreateFrame("Frame", nil, container)
    filterRow:SetPoint("TOPLEFT", 0, 0)
    filterRow:SetPoint("TOPRIGHT", 0, 0)
    filterRow:SetHeight(28)

    -- Instance filter label
    local instLabel = filterRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    instLabel:SetPoint("LEFT", 0, 0)
    instLabel:SetText(L.LOG_FILTER_INSTANCE)

    -- Instance dropdown
    container.instDropdown = CreateDropdown(filterRow, "FDCStatsInstDropdown", 120)
    container.instDropdown:SetPoint("LEFT", instLabel, "RIGHT", -10, -2)

    -- Hour controls label
    local hourLabel = filterRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hourLabel:SetPoint("LEFT", container.instDropdown, "RIGHT", 20, 2)
    hourLabel:SetText(L.STATS_HOUR_PROMPT)

    -- Remove hour button
    container.removeHourBtn = CreateFrame("Button", nil, filterRow, "UIPanelButtonTemplate")
    container.removeHourBtn:SetSize(20, 20)
    container.removeHourBtn:SetPoint("LEFT", hourLabel, "RIGHT", 4, 0)
    container.removeHourBtn:SetText(L.STATS_REMOVE_HOUR)

    -- Add hour button
    container.addHourBtn = CreateFrame("Button", nil, filterRow, "UIPanelButtonTemplate")
    container.addHourBtn:SetSize(20, 20)
    container.addHourBtn:SetPoint("LEFT", container.removeHourBtn, "RIGHT", 2, 0)
    container.addHourBtn:SetText(L.STATS_ADD_HOUR)

    container.filterRow = filterRow

    -- Table area
    local tableArea = CreateFrame("Frame", nil, container)
    tableArea:SetPoint("TOPLEFT", 0, -32)
    tableArea:SetPoint("BOTTOMRIGHT", 0, 0)
    container.tableArea = tableArea

    -- Table header
    container.tableHeader = CreateStatsHeader(tableArea)

    -- Scroll frame for rows
    local scrollFrame = CreateFrame("ScrollFrame", nil, tableArea, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 0, -TABLE_HEADER_HEIGHT)
    scrollFrame:SetPoint("BOTTOMRIGHT", -20, 0)
    container.scrollFrame = scrollFrame

    -- Content frame for rows
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(scrollFrame:GetWidth(), 1)
    scrollFrame:SetScrollChild(content)
    container.content = content

    return container
end

-- Create hour input dialog
local function CreateHourInputDialog(onConfirm)
    local L = FDC.L

    local dialog = CreateFrame("Frame", "FDCHourInputDialog", UIParent, "BackdropTemplate")
    dialog:SetSize(200, 100)
    dialog:SetPoint("CENTER")
    UI.ApplyBackdrop(dialog, true)
    dialog:SetFrameStrata("DIALOG")
    dialog:EnableMouse(true)
    dialog:Hide()

    -- Title
    dialog.title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dialog.title:SetPoint("TOP", 0, -10)
    dialog.title:SetText(L.STATS_HOUR_INPUT_TITLE)

    -- Label
    dialog.label = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dialog.label:SetPoint("TOP", dialog.title, "BOTTOM", 0, -8)
    dialog.label:SetText(L.STATS_HOUR_INPUT_LABEL)

    -- Edit box
    dialog.editBox = CreateFrame("EditBox", nil, dialog, "InputBoxTemplate")
    dialog.editBox:SetSize(40, 20)
    dialog.editBox:SetPoint("TOP", dialog.label, "BOTTOM", 0, -5)
    dialog.editBox:SetAutoFocus(true)
    dialog.editBox:SetNumeric(true)
    dialog.editBox:SetMaxLetters(2)

    -- OK button
    dialog.okBtn = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    dialog.okBtn:SetSize(60, 22)
    dialog.okBtn:SetPoint("BOTTOMLEFT", 20, 10)
    dialog.okBtn:SetText("OK")
    dialog.okBtn:Disable()

    -- Cancel button
    dialog.cancelBtn = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    dialog.cancelBtn:SetSize(60, 22)
    dialog.cancelBtn:SetPoint("BOTTOMRIGHT", -20, 10)
    dialog.cancelBtn:SetText("Cancel")

    -- Validation
    local function ValidateInput()
        local text = dialog.editBox:GetText()
        local value = tonumber(text)
        if value and value >= 1 and value <= 24 then
            dialog.okBtn:Enable()
        else
            dialog.okBtn:Disable()
        end
    end

    dialog.editBox:SetScript("OnTextChanged", ValidateInput)
    dialog.editBox:SetScript("OnEnterPressed", function()
        if dialog.okBtn:IsEnabled() then
            dialog.okBtn:Click()
        end
    end)
    dialog.editBox:SetScript("OnEscapePressed", function()
        dialog:Hide()
    end)

    dialog.okBtn:SetScript("OnClick", function()
        local value = tonumber(dialog.editBox:GetText())
        if value and onConfirm then
            onConfirm(value)
        end
        dialog:Hide()
    end)

    dialog.cancelBtn:SetScript("OnClick", function()
        dialog:Hide()
    end)

    return dialog
end

-- Initialize stats instance dropdown
local function InitStatsInstanceDropdown(dropdown, entries, onChange)
    local L = FDC.L

    UIDropDownMenu_Initialize(dropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()

        -- "All" option
        info.text = L.LOG_FILTER_ALL
        info.value = nil
        info.checked = (statsFilters.instance == nil)
        info.func = function()
            statsFilters.instance = nil
            UIDropDownMenu_SetText(dropdown, L.LOG_FILTER_ALL)
            onChange()
        end
        UIDropDownMenu_AddButton(info, level)

        -- Instance options
        local instances = GetUniqueInstances(entries)
        for _, inst in ipairs(instances) do
            info = UIDropDownMenu_CreateInfo()
            info.text = inst.name
            info.value = inst.id
            info.checked = (statsFilters.instance == inst.id)
            info.func = function()
                statsFilters.instance = inst.id
                UIDropDownMenu_SetText(dropdown, inst.name)
                onChange()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    -- Set current text
    if statsFilters.instance then
        local instances = GetUniqueInstances(entries)
        for _, inst in ipairs(instances) do
            if inst.id == statsFilters.instance then
                UIDropDownMenu_SetText(dropdown, inst.name)
                return
            end
        end
    end
    UIDropDownMenu_SetText(dropdown, L.LOG_FILTER_ALL)
end

-- Update stats view with data
local function UpdateStatsView(frame, statsData)
    local L = FDC.L

    -- Update header
    UpdateStatsHeaderColumns(frame.statsView.tableHeader)

    HideAllStatsRows()

    local content = frame.statsView.content
    local rowCount = #statsData.characters + 1  -- +1 for totals row
    local totalHeight = rowCount * TABLE_ROW_HEIGHT
    content:SetHeight(math.max(1, totalHeight))

    -- Character rows
    for i, charData in ipairs(statsData.characters) do
        local row = GetStatsRow(content, i)
        row:SetPoint("TOPLEFT", 0, -(i - 1) * TABLE_ROW_HEIGHT)
        row:SetPoint("TOPRIGHT", 0, -(i - 1) * TABLE_ROW_HEIGHT)
        UpdateStatsRowColumns(row, charData)
    end

    -- Totals row
    local totalIndex = #statsData.characters + 1
    local totalRow = GetStatsRow(content, totalIndex)
    totalRow:SetPoint("TOPLEFT", 0, -(totalIndex - 1) * TABLE_ROW_HEIGHT)
    totalRow:SetPoint("TOPRIGHT", 0, -(totalIndex - 1) * TABLE_ROW_HEIGHT)
    totalRow.bg:SetColorTexture(0.3, 0.3, 0.1, 0.3)  -- Highlight totals row
    UpdateStatsRowColumns(totalRow, {
        name = L.STAT_TOTAL,
        total = statsData.totals.total,
        hourCounts = statsData.totals.hourCounts
    })
end

-- Update table view with filtered data
local function UpdateTableView(frame, entries)
    local filtered = FilterEntries(entries)
    local content = frame.tableView.content

    HideAllTableRows()

    local totalHeight = #filtered * TABLE_ROW_HEIGHT
    content:SetHeight(math.max(1, totalHeight))

    for i, entry in ipairs(filtered) do
        local row = GetTableRow(content, i)
        row:SetPoint("TOPLEFT", 0, -(i - 1) * TABLE_ROW_HEIGHT)
        row:SetPoint("TOPRIGHT", 0, -(i - 1) * TABLE_ROW_HEIGHT)

        row.timeText:SetText(date("%H:%M:%S", entry.time))
        row.eventText:SetText(GetLocalizedEventName(entry.event))
        row.charText:SetText(entry.character)

        local instanceName = GetInstanceName(entry.instanceID)
        local instStr
        if instanceName then
            instStr = instanceName .. " (" .. entry.instanceID .. ")"
        else
            instStr = "ID:" .. (entry.instanceID or "?")
        end
        row.instText:SetText(instStr)
    end
end

-- Show/hide view containers
local function ShowView(frame, view)
    frame.rawView:Hide()
    frame.tableView:Hide()
    frame.statsView:Hide()

    if view == VIEW_RAW then
        frame.rawView:Show()
    elseif view == VIEW_TABLE then
        frame.tableView:Show()
    elseif view == VIEW_STATS then
        frame.statsView:Show()
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
    frame:SetResizable(true)
    frame:SetResizeBounds(
        UI.LOG_WINDOW_MIN_WIDTH, UI.LOG_WINDOW_MIN_HEIGHT,
        UI.LOG_WINDOW_MAX_WIDTH, UI.LOG_WINDOW_MAX_HEIGHT
    )
    frame:Hide()

    -- Title bar (drag area)
    frame.titleBar = CreateFrame("Frame", nil, frame)
    frame.titleBar:SetPoint("TOPLEFT", 4, -4)
    frame.titleBar:SetPoint("TOPRIGHT", -24, -4)
    frame.titleBar:SetHeight(20)
    frame.titleBar:EnableMouse(true)
    frame.titleBar:RegisterForDrag("LeftButton")
    frame.titleBar:SetScript("OnDragStart", function() frame:StartMoving() end)
    frame.titleBar:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        SaveWindowState(frame)
    end)

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
        ShowView(frame, currentView)
        FDC:UpdateLogWindow()
    end

    frame.tabStats = CreateTabButton(frame, L.LOG_TAB_STATS, VIEW_STATS, OnTabClick)
    frame.tabStats:SetPoint("TOPLEFT", 8, -26)

    frame.tabTable = CreateTabButton(frame, L.LOG_TAB_TABLE, VIEW_TABLE, OnTabClick)
    frame.tabTable:SetPoint("LEFT", frame.tabStats, "RIGHT", 2, 0)

    frame.tabRaw = CreateTabButton(frame, L.LOG_TAB_RAW, VIEW_RAW, OnTabClick)
    frame.tabRaw:SetPoint("LEFT", frame.tabTable, "RIGHT", 2, 0)

    UpdateTabStates(frame)

    -- Create view containers
    frame.rawView = CreateRawView(frame)
    frame.tableView = CreateTableView(frame)
    frame.statsView = CreateStatsView(frame)

    -- Initially show Stats view
    ShowView(frame, VIEW_STATS)

    -- Resize handle (bottom-right corner)
    local resizeBtn = CreateFrame("Button", nil, frame)
    resizeBtn:SetSize(16, 16)
    resizeBtn:SetPoint("BOTTOMRIGHT", -4, 4)
    resizeBtn:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeBtn:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeBtn:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeBtn:SetScript("OnMouseDown", function()
        frame:StartSizing("BOTTOMRIGHT")
    end)
    resizeBtn:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        SaveWindowState(frame)
    end)
    frame.resizeBtn = resizeBtn

    -- Update editBox width when frame size changes
    frame:SetScript("OnSizeChanged", function()
        UpdateEditBoxWidth(frame)
    end)

    -- Restore saved position and size
    local pos = FDC:GetLogWindowPosition()
    if pos then
        frame:ClearAllPoints()
        frame:SetPoint(pos[1], UIParent, pos[3], pos[4], pos[5])
    end
    local size = FDC:GetLogWindowSize()
    if size then
        frame:SetSize(size[1], size[2])
    end

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

    local logData = self:GetLogData(24)

    if currentView == VIEW_RAW then
        local text = FormatRawLog(logData.entries)
        self.logWindow.rawView.editBox:SetText(text)
        self.logWindow.rawView.editBox:SetCursorPosition(0)

    elseif currentView == VIEW_TABLE then
        -- Update dropdowns
        local function onFilterChange()
            UpdateTableView(self.logWindow, logData.entries)
        end
        InitCharacterDropdown(self.logWindow.tableView.charDropdown, logData.entries, onFilterChange)
        InitInstanceDropdown(self.logWindow.tableView.instDropdown, logData.entries, onFilterChange)
        UpdateTableView(self.logWindow, logData.entries)

    elseif currentView == VIEW_STATS then
        -- Build hours string from statsHours (empty string if no hours)
        local hoursStr = #statsHours > 0 and table.concat(statsHours, ",") or ""
        local instanceArg = statsFilters.instance and (" " .. statsFilters.instance) or ""
        local statsData = self:GetStatisticsData(hoursStr .. instanceArg)

        -- Update instance dropdown
        local function onFilterChange()
            self:UpdateLogWindow()
        end
        InitStatsInstanceDropdown(self.logWindow.statsView.instDropdown, logData.entries, onFilterChange)

        -- Wire up hour buttons
        self.logWindow.statsView.addHourBtn:SetScript("OnClick", function()
            -- Create dialog if not exists
            if not self.hourInputDialog then
                self.hourInputDialog = CreateHourInputDialog(function(value)
                    -- Check for duplicate
                    for _, h in ipairs(statsHours) do
                        if h == value then
                            print(string.format(self.L.STATS_HOUR_DUPLICATE, value))
                            return
                        end
                    end
                    -- Add and sort
                    table.insert(statsHours, value)
                    table.sort(statsHours)
                    self:UpdateLogWindow()
                end)
            end
            self.hourInputDialog.editBox:SetText("")
            self.hourInputDialog:Show()
        end)

        self.logWindow.statsView.removeHourBtn:SetScript("OnClick", function()
            if #statsHours > 0 then
                table.remove(statsHours)  -- Remove last
                self:UpdateLogWindow()
            end
        end)

        -- Update button states
        self.logWindow.statsView.removeHourBtn:SetEnabled(#statsHours > 0)

        UpdateStatsView(self.logWindow, statsData)
    end
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
