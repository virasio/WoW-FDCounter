-- FDCounter: UI Widget Factories
-- Reusable button creation and helper functions

local ADDON_NAME, FDC = ...

local UI = FDC.UI

-- Apply standard backdrop to a frame
function UI.ApplyBackdrop(frame, solid)
    frame:SetBackdrop(UI.STANDARD_BACKDROP)
    if solid then
        frame:SetBackdropColor(UI.BACKDROP_COLOR_SOLID.r, UI.BACKDROP_COLOR_SOLID.g, UI.BACKDROP_COLOR_SOLID.b, UI.BACKDROP_COLOR_SOLID.a)
        frame:SetBackdropBorderColor(UI.BORDER_COLOR_SOLID.r, UI.BORDER_COLOR_SOLID.g, UI.BORDER_COLOR_SOLID.b, UI.BORDER_COLOR_SOLID.a)
    else
        frame:SetBackdropColor(UI.BACKDROP_COLOR.r, UI.BACKDROP_COLOR.g, UI.BACKDROP_COLOR.b, UI.BACKDROP_COLOR.a)
        frame:SetBackdropBorderColor(UI.BORDER_COLOR.r, UI.BORDER_COLOR.g, UI.BORDER_COLOR.b, UI.BORDER_COLOR.a)
    end
end

-- Add tooltip to a frame
function UI.AddTooltip(frame, text)
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(text)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

-- Create a square icon button styled like a small panel
function UI.CreateIconButton(parent, icon, tooltipText, onClick)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(UI.BUTTON_SIZE, UI.BUTTON_SIZE)

    UI.ApplyBackdrop(btn, false)

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
    UI.AddTooltip(btn, tooltipText)

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
function UI.CreateInlineButton(parent, icon, tooltipText, onClick)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(UI.INLINE_BUTTON_SIZE, UI.INLINE_BUTTON_SIZE)

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
    UI.AddTooltip(btn, tooltipText)

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
