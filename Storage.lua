-- FDCounter: Storage module
-- Handles SavedVariables and data persistence

local ADDON_NAME, FDC = ...

-- Default settings
local defaults = {
    count = 0,
    resetTime = 0,
    currentInstanceID = nil,
    log = {},
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

-- Set current instance ID
function FDC:SetCurrentInstanceID(instanceID)
    FDCounterDB.currentInstanceID = instanceID
end

-- Clear current instance tracking
function FDC:ClearCurrentInstance()
    FDCounterDB.currentInstanceID = nil
end

-- Add event to log
-- event: "entry", "exit", "reentry", "complete"
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
