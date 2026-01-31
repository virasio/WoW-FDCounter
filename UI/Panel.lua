-- FDCounter: Main Panel
-- Draggable panel with count and reset timer

local ADDON_NAME, FDC = ...

local UI = FDC.UI

-- Format time as H:mm for panel display
local function FormatPanelTime(seconds)
    if seconds <= 0 then
        return "0:00"
    end
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    return string.format(FDC.L.PANEL_TIME_FORMAT, hours, minutes)
end

-- Create header bar above panel
local function CreatePanelHeader(frame)
    local L = FDC.L

    local header = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    header:SetSize(UI.PANEL_WIDTH + UI.BUTTON_SIZE, UI.PANEL_HEADER_HEIGHT)
    header:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 0)
    UI.ApplyBackdrop(header, false)

    -- Header text (centered)
    header.text = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header.text:SetPoint("CENTER", 0, 0)
    header.text:SetText(L.PANEL_HEADER)

    -- Close button (hidden by default, shown on hover)
    header.closeBtn = CreateFrame("Button", nil, header, "BackdropTemplate")
    header.closeBtn:SetSize(24, 24)
    header.closeBtn:SetPoint("RIGHT", -2, 0)
    UI.ApplyBackdrop(header.closeBtn, false)

    header.closeBtn.icon = header.closeBtn:CreateTexture(nil, "ARTWORK")
    header.closeBtn.icon:SetSize(12, 12)
    header.closeBtn.icon:SetPoint("CENTER", 0, 0)
    header.closeBtn.icon:SetTexture("Interface\\Buttons\\UI-StopButton")

    header.closeBtn.highlight = header.closeBtn:CreateTexture(nil, "HIGHLIGHT")
    header.closeBtn.highlight:SetPoint("TOPLEFT", 4, -4)
    header.closeBtn.highlight:SetPoint("BOTTOMRIGHT", -4, 4)
    header.closeBtn.highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    header.closeBtn.highlight:SetBlendMode("ADD")

    header.closeBtn:SetScript("OnClick", function()
        FDC:HidePanel()
    end)
    header.closeBtn:Hide()

    -- Show/hide close button on hover
    header:SetScript("OnEnter", function()
        header.closeBtn:Show()
    end)
    header:SetScript("OnLeave", function()
        if not header:IsMouseOver() then
            header.closeBtn:Hide()
        end
    end)
    header.closeBtn:SetScript("OnLeave", function()
        if not header:IsMouseOver() then
            header.closeBtn:Hide()
        end
    end)

    -- Make header draggable (moves the main frame)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() frame:StartMoving() end)
    header:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        FDC:SavePanelPosition(frame:GetPoint())
    end)

    frame.header = header
end

-- Create panel text elements
local function CreatePanelText(frame)
    local L = FDC.L

    -- Line 1: label "Visited:"
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
end

-- Create side buttons (exit dungeon, etc.)
local function CreateSideButtons(frame)
    local L = FDC.L

    -- Button 1 (top): Exit dungeon
    frame.exitBtn = UI.CreateIconButton(
        frame,
        "common-icon-exit",
        L.BTN_EXIT_TOOLTIP,
        function()
            FDC:LeaveDungeon()
        end
    )
    frame.exitBtn:SetPoint("TOPLEFT", frame, "TOPRIGHT", UI.BUTTON_GAP, 0)

    -- Button 2 (bottom): Log window
    frame.logBtn = UI.CreateIconButton(
        frame,
        "common-icon-visual",
        L.BTN_LOG_TOOLTIP,
        function()
            FDC:ToggleLogWindow()
        end
    )
    frame.logBtn:SetPoint("TOP", frame.exitBtn, "BOTTOM", 0, -UI.BUTTON_GAP)
end

-- Create inline buttons container and buttons
local function CreateInlineButtons(frame)
    local L = FDC.L

    -- Inline buttons container (for hover state)
    -- 4 buttons * 20px = 80px total width, centered
    frame.inlineButtons = CreateFrame("Frame", nil, frame)
    frame.inlineButtons:SetSize(UI.INLINE_BUTTON_SIZE * 4, UI.INLINE_BUTTON_SIZE)
    frame.inlineButtons:SetPoint("BOTTOM", 0, 4)
    frame.inlineButtons:Hide()

    -- Inline button 1: Reset
    frame.inlineReset = UI.CreateInlineButton(
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
    frame.inlineMinus = UI.CreateInlineButton(
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
    frame.inlinePlus = UI.CreateInlineButton(
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
    frame.inlineInput = UI.CreateInlineButton(
        frame.inlineButtons,
        "UI-LFG-PendingMark",
        L.BTN_INPUT_TOOLTIP,
        function()
            FDC:ShowInputDialog()
        end
    )
    frame.inlineInput:SetPoint("LEFT", frame.inlinePlus, "RIGHT", 0, 0)
    frame.inlineInput:Show()
end

-- Setup hover behavior for inline buttons
local function SetupHoverBehavior(frame)
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
end

-- Create the UI panel
function FDC:CreatePanel()
    local frame = CreateFrame("Frame", "FDCounterPanel", UIParent, "BackdropTemplate")
    frame:SetSize(UI.PANEL_WIDTH, UI.PANEL_HEIGHT)
    UI.ApplyBackdrop(frame, false)

    -- Draggable
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        FDC:SavePanelPosition(self:GetPoint())
    end)

    -- Create UI components
    CreatePanelHeader(frame)
    CreatePanelText(frame)
    CreateSideButtons(frame)
    CreateInlineButtons(frame)
    SetupHoverBehavior(frame)

    -- Create input dialog
    self:CreateInputDialog()

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
    local seconds = self:GetResetTime() - time()
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
end

-- Hide the panel
function FDC:HidePanel()
    if not self.panel then return end
    self.panel:Hide()
    self:SetPanelVisible(false)
end
