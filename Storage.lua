-- FDCounter: Storage module
-- Handles SavedVariables and data persistence

local ADDON_NAME, FDC = ...

-- Default settings
local defaults = {
    count = 0,
    resetTime = 0,
    currentInstanceID = nil,
    currentInstanceName = nil,
    log = {},
    helpShown = false,
    panelPosition = nil,  -- {point, relativeTo, relativePoint, x, y}
    panelVisible = true,
}

-- Calculate next daily reset timestamp
function FDC:GetNextResetTime()
    local secondsUntilReset = C_DateAndTime.GetSecondsUntilDailyReset()
    return time() + secondsUntilReset
end

-- Initialize saved variables with defaults
function FDC:InitializeStorage()
    if FDCounterDB == nil then
        FDCounterDB = {}
    end
    for key, value in pairs(defaults) do
        if FDCounterDB[key] == nil then
            FDCounterDB[key] = value
        end
    end
end

-- Check if counter should be reset (past daily reset)
function FDC:CheckAndResetCounter()
    if time() >= FDCounterDB.resetTime then
        FDCounterDB.count = 0
        FDCounterDB.log = {}
        FDCounterDB.resetTime = self:GetNextResetTime()
    end
end

-- Reset counter manually
function FDC:ResetCounter()
    FDCounterDB.count = 0
    FDCounterDB.log = {}
    FDCounterDB.resetTime = self:GetNextResetTime()
end

-- Get current count
function FDC:GetCount()
    return FDCounterDB.count
end

-- Get current instance ID being tracked
function FDC:GetCurrentInstanceID()
    return FDCounterDB.currentInstanceID
end

-- Get current instance name being tracked
function FDC:GetCurrentInstanceName()
    return FDCounterDB.currentInstanceName
end

-- Set current instance info
function FDC:SetCurrentInstance(instanceID, instanceName)
    FDCounterDB.currentInstanceID = instanceID
    FDCounterDB.currentInstanceName = instanceName
end

-- Clear current instance tracking
function FDC:ClearCurrentInstance()
    FDCounterDB.currentInstanceID = nil
    FDCounterDB.currentInstanceName = nil
end

-- Add event to log
-- event: FDC.EventType.ENTRY, .EXIT, .REENTRY, .COMPLETE
function FDC:LogEvent(event, instanceID, instanceName)
    local name, realm = UnitFullName("player")
    realm = realm or GetRealmName()
    local character = name .. "-" .. realm
    
    table.insert(FDCounterDB.log, {
        time = time(),
        event = event,
        character = character,
        instanceID = instanceID,
        instanceName = instanceName,
    })
end

-- Get log entries
function FDC:GetLog()
    return FDCounterDB.log
end

-- Get panel position
function FDC:GetPanelPosition()
    return FDCounterDB.panelPosition
end

-- Save panel position
function FDC:SavePanelPosition(point, relativeTo, relativePoint, x, y)
    FDCounterDB.panelPosition = {point, relativeTo, relativePoint, x, y}
end

-- Check if panel is visible
function FDC:IsPanelVisible()
    return FDCounterDB.panelVisible
end

-- Set panel visibility
function FDC:SetPanelVisible(visible)
    FDCounterDB.panelVisible = visible
end
