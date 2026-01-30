-- FDCounter: UI module
-- Draggable panel with count and reset timer

local ADDON_NAME, FDC = ...

local PANEL_WIDTH = 80
local PANEL_HEIGHT = 80
local BUTTON_SIZE = 40
local BUTTON_GAP = 0

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
    frame.titleText:SetPoint("TOP", 0, -6)
    frame.titleText:SetText(L.PANEL_TITLE)

    -- Line 2: large counter number
    frame.countText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    frame.countText:SetPoint("TOP", frame.titleText, "BOTTOM", 0, -2)

    -- Line 3: label "reset in:" with small gap
    frame.labelText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.labelText:SetPoint("TOP", frame.countText, "BOTTOM", 0, -6)
    frame.labelText:SetText(L.PANEL_RESET_LABEL)

    -- Line 4: time "H:mm"
    frame.timeText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.timeText:SetPoint("TOP", frame.labelText, "BOTTOM", 0, -2)

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

    -- Button 2 (bottom): Reset counter
    frame.resetBtn = CreateIconButton(
        frame,
        "common-icon-undo",
        L.BTN_RESET_TOOLTIP,
        function()
            FDC:ResetCounter()
            FDC:UpdatePanel()
        end
    )
    frame.resetBtn:SetPoint("TOP", frame.exitBtn, "BOTTOM", 0, -BUTTON_GAP)

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
