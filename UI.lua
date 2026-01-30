-- FDCounter: UI module
-- Draggable panel with count and reset timer

local ADDON_NAME, FDC = ...

local PANEL_WIDTH = 88
local PANEL_HEIGHT = 88
local BUTTON_SIZE = 44
local BUTTON_GAP = 0
local INLINE_BUTTON_SIZE = 20

-- Format time as H:mm for panel display
local function FormatPanelTime(seconds)
    if seconds <= 0 then
        return "0:00"
    end
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    return string.format(FDC.L.PANEL_TIME_FORMAT, hours, minutes)
end

-- Create a square icon button styled like a small panel
local function CreateIconButton(parent, icon, tooltipText, onClick)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(BUTTON_SIZE, BUTTON_SIZE)

    -- Same backdrop as main panel
    btn:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    btn:SetBackdropColor(0, 0, 0, 0.6)
    btn:SetBackdropBorderColor(0.6, 0.6, 0.6, 0.8)

    -- Icon
    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetPoint("TOPLEFT", 6, -6)
    btn.icon:SetPoint("BOTTOMRIGHT", -6, 6)
    btn.icon:SetAtlas(icon)

    -- Highlight inside border
    btn.highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    btn.highlight:SetPoint("TOPLEFT", 4, -4)
    btn.highlight:SetPoint("BOTTOMRIGHT", -4, 4)
    btn.highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    btn.highlight:SetBlendMode("ADD")

    -- Tooltip
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(tooltipText)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Push effect
    btn:SetScript("OnMouseDown", function(self)
        self.icon:SetPoint("TOPLEFT", 7, -7)
        self.icon:SetPoint("BOTTOMRIGHT", -5, 5)
    end)
    btn:SetScript("OnMouseUp", function(self)
        self.icon:SetPoint("TOPLEFT", 6, -6)
        self.icon:SetPoint("BOTTOMRIGHT", -6, 6)
    end)

    btn:SetScript("OnClick", onClick)

    return btn
end

-- Create a small inline button (no border)
local function CreateInlineButton(parent, icon, tooltipText, onClick)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(INLINE_BUTTON_SIZE, INLINE_BUTTON_SIZE)

    -- Icon
    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetAllPoints()
    btn.icon:SetAtlas(icon)

    -- Highlight
    btn.highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    btn.highlight:SetAllPoints()
    btn.highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    btn.highlight:SetBlendMode("ADD")

    -- Tooltip
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(tooltipText)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Push effect
    btn:SetScript("OnMouseDown", function(self)
        self.icon:SetPoint("TOPLEFT", 1, -1)
        self.icon:SetPoint("BOTTOMRIGHT", 1, -1)
    end)
    btn:SetScript("OnMouseUp", function(self)
        self.icon:ClearAllPoints()
        self.icon:SetAllPoints()
    end)

    btn:SetScript("OnClick", onClick)
    btn:Hide()

    return btn
end

-- Create input dialog for manual counter value
local function CreateInputDialog()
    local L = FDC.L

    local dialog = CreateFrame("Frame", "FDCounterInputDialog", UIParent, "BackdropTemplate")
    dialog:SetSize(200, 100)
    dialog:SetPoint("CENTER")
    dialog:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    dialog:SetBackdropColor(0, 0, 0, 0.9)
    dialog:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    dialog:SetFrameStrata("DIALOG")
    dialog:EnableMouse(true)
    dialog:Hide()

    -- Title
    dialog.title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dialog.title:SetPoint("TOP", 0, -10)
    dialog.title:SetText(L.INPUT_DIALOG_TITLE)

    -- Label
    dialog.label = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dialog.label:SetPoint("TOP", dialog.title, "BOTTOM", 0, -8)
    dialog.label:SetText(L.INPUT_DIALOG_LABEL)

    -- Edit box
    dialog.editBox = CreateFrame("EditBox", nil, dialog, "InputBoxTemplate")
    dialog.editBox:SetSize(60, 20)
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
        if value and value >= 0 and value <= 99 then
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
        if value then
            FDC:SetCount(value)
            FDC:UpdatePanel()
        end
        dialog:Hide()
    end)

    dialog.cancelBtn:SetScript("OnClick", function()
        dialog:Hide()
    end)

    return dialog
end

-- Create the UI panel
function FDC:CreatePanel()
    local L = self.L

    local frame = CreateFrame("Frame", "FDCounterPanel", UIParent, "BackdropTemplate")
    frame:SetSize(PANEL_WIDTH, PANEL_HEIGHT)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0, 0, 0, 0.6)
    frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 0.8)

    -- Draggable
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        FDC:SavePanelPosition(self:GetPoint())
    end)

    -- Line 1: label "FD Visited:"
    frame.titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.titleText:SetPoint("TOP", 0, -12)
    frame.titleText:SetText(L.PANEL_TITLE)

    -- Line 2: large counter number
    frame.countText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge4")
    frame.countText:SetPoint("TOP", frame.titleText, "BOTTOM", 0, -8)

    -- Line 4: time "H:mm" (anchored to bottom)
    frame.timeText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.timeText:SetPoint("BOTTOM", 0, 4)

    -- Line 3: label "reset in:" (anchored above time)
    frame.labelText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.labelText:SetPoint("BOTTOM", frame.timeText, "TOP", 0, 0)
    frame.labelText:SetText(L.PANEL_RESET_LABEL)

    -- Button 1 (top): Exit dungeon
    frame.exitBtn = CreateIconButton(
        frame,
        "common-icon-exit",
        L.BTN_EXIT_TOOLTIP,
        function()
            FDC:LeaveDungeon()
        end
    )
    frame.exitBtn:SetPoint("TOPLEFT", frame, "TOPRIGHT", BUTTON_GAP, 0)

    -- Button 2 (bottom): Log window (TODO)
    -- frame.logBtn = CreateIconButton(
    --     frame,
    --     "common-icon-undo",  -- TODO: find proper icon
    --     L.BTN_LOG_TOOLTIP,
    --     function()
    --         FDC:ShowLogWindow()
    --     end
    -- )
    -- frame.logBtn:SetPoint("TOP", frame.exitBtn, "BOTTOM", 0, -BUTTON_GAP)

    -- Inline buttons container (for hover state)
    frame.inlineButtons = CreateFrame("Frame", nil, frame)
    frame.inlineButtons:SetPoint("BOTTOMLEFT", 4, 4)
    frame.inlineButtons:SetPoint("BOTTOMRIGHT", -4, 4)
    frame.inlineButtons:SetHeight(INLINE_BUTTON_SIZE)
    frame.inlineButtons:Hide()

    -- Inline button 1: Reset
    frame.inlineReset = CreateInlineButton(
        frame.inlineButtons,
        "UI-LFG-DeclineMark",
        L.BTN_RESET_TOOLTIP,
        function()
            FDC:ResetCounter()
            FDC:UpdatePanel()
        end
    )
    frame.inlineReset:SetPoint("LEFT", 0, 0)
    frame.inlineReset:Show()

    -- Inline button 2: Minus
    frame.inlineMinus = CreateInlineButton(
        frame.inlineButtons,
        "communities-chat-icon-minus",
        L.BTN_MINUS_TOOLTIP,
        function()
            FDC:DecrementCounter()
            FDC:UpdatePanel()
        end
    )
    frame.inlineMinus:SetPoint("LEFT", frame.inlineReset, "RIGHT", 0, 0)
    frame.inlineMinus:Show()

    -- Inline button 3: Plus
    frame.inlinePlus = CreateInlineButton(
        frame.inlineButtons,
        "communities-chat-icon-plus",
        L.BTN_PLUS_TOOLTIP,
        function()
            FDC:IncrementCounterManual()
            FDC:UpdatePanel()
        end
    )
    frame.inlinePlus:SetPoint("LEFT", frame.inlineMinus, "RIGHT", 0, 0)
    frame.inlinePlus:Show()

    -- Inline button 4: Manual input
    frame.inlineInput = CreateInlineButton(
        frame.inlineButtons,
        "UI-LFG-PendingMark",
        L.BTN_INPUT_TOOLTIP,
        function()
            FDC:ShowInputDialog()
        end
    )
    frame.inlineInput:SetPoint("LEFT", frame.inlinePlus, "RIGHT", 0, 0)
    frame.inlineInput:Show()

    -- Create input dialog
    self.inputDialog = CreateInputDialog()

    -- Hover behavior: show inline buttons, hide time
    local function ShowInlineButtons()
        frame.labelText:Hide()
        frame.timeText:Hide()
        frame.inlineButtons:Show()
    end

    local function HideInlineButtons()
        if frame:IsMouseOver() then return end
        frame.inlineButtons:Hide()
        frame.labelText:Show()
        frame.timeText:Show()
        GameTooltip:Hide()
    end

    frame:SetScript("OnEnter", ShowInlineButtons)
    frame:SetScript("OnLeave", HideInlineButtons)

    -- Prevent flickering when hovering over inline buttons
    frame.inlineButtons:SetScript("OnLeave", HideInlineButtons)

    -- Restore position from SavedVariables
    local pos = self:GetPanelPosition()
    if pos then
        frame:ClearAllPoints()
        frame:SetPoint(pos[1], UIParent, pos[3], pos[4], pos[5])
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    -- Start hidden, will be shown in Initialize if panelVisible is true
    frame:Hide()

    self.panel = frame
end

-- Leave Follower Dungeon: teleport out, then leave group
function FDC:LeaveDungeon()
    local isFollowerDungeon = self:GetFollowerDungeonInfo()
    if isFollowerDungeon then
        -- Teleport out of dungeon first
        LFGTeleport(true)
        -- Leave instance group after a short delay
        C_Timer.After(1, function()
            C_PartyInfo.LeaveParty(LE_PARTY_CATEGORY_INSTANCE)
        end)
    else
        -- Not in dungeon, just leave instance group
        C_PartyInfo.LeaveParty(LE_PARTY_CATEGORY_INSTANCE)
    end
end

-- Update panel text
function FDC:UpdatePanel()
    if not self.panel then return end
    local data = self:GetStatusData()
    self.panel.countText:SetText(tostring(data.count))
    self.panel.timeText:SetText(FormatPanelTime(data.secondsUntilReset))
end

-- Start timer to update panel every minute
function FDC:StartPanelTimer()
    if not self.panel then return end

    -- Initial update
    self:UpdatePanel()

    -- Calculate delay until next minute boundary
    local seconds = FDCounterDB.resetTime - time()
    local delay = seconds % 60
    if delay == 0 then delay = 60 end

    -- First update at minute boundary, then every 60 seconds
    C_Timer.After(delay, function()
        self:UpdatePanel()
        self.panelTicker = C_Timer.NewTicker(60, function()
            self:UpdatePanel()
        end)
    end)
end

-- Show the panel
function FDC:ShowPanel()
    if not self.panel then return end
    self:UpdatePanel()
    self.panel:Show()
    self:SetPanelVisible(true)
    print(self.L.PANEL_SHOWN)
end

-- Hide the panel
function FDC:HidePanel()
    if not self.panel then return end
    self.panel:Hide()
    self:SetPanelVisible(false)
    print(self.L.PANEL_HIDDEN)
end

-- Show input dialog
function FDC:ShowInputDialog()
    if not self.inputDialog then return end
    local currentCount = self:GetCount()
    -- Limit displayed value to 99 for input
    local displayValue = math.min(currentCount, 99)
    self.inputDialog.editBox:SetText(tostring(displayValue))
    self.inputDialog.editBox:HighlightText()
    self.inputDialog:Show()
end
