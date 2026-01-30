-- FDCounter: Input Dialog
-- Dialog for manual counter value entry

local ADDON_NAME, FDC = ...

local UI = FDC.UI

-- Create input dialog for manual counter value
local function CreateInputDialog()
    local L = FDC.L

    local dialog = CreateFrame("Frame", "FDCounterInputDialog", UIParent, "BackdropTemplate")
    dialog:SetSize(200, 100)
    dialog:SetPoint("CENTER")
    UI.ApplyBackdrop(dialog, true)
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

-- Create and store input dialog
function FDC:CreateInputDialog()
    self.inputDialog = CreateInputDialog()
end

-- Show input dialog with current count
function FDC:ShowInputDialog()
    if not self.inputDialog then return end
    local currentCount = self:GetCount()
    -- Limit displayed value to 99 for input
    local displayValue = math.min(currentCount, 99)
    self.inputDialog.editBox:SetText(tostring(displayValue))
    self.inputDialog.editBox:HighlightText()
    self.inputDialog:Show()
end
