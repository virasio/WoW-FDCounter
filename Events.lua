-- FDCounter: Events module
-- Event registration and handling

local ADDON_NAME, FDC = ...

-- Create event frame
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("GROUP_LEFT")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == ADDON_NAME then
            FDC:Initialize()
            self:UnregisterEvent("ADDON_LOADED")
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        local isLogin, isReload = ...
        FDC:OnPlayerEnteringWorld(isLogin, isReload)
    elseif event == "GROUP_LEFT" then
        FDC:OnGroupLeft()
    end
end)
