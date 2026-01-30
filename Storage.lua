-- FDCounter: Storage module
-- Handles SavedVariables and data persistence

local ADDON_NAME, FDC = ...

-- Default settings
local defaults = {
    count = 0,
    resetTime = 0,
    currentInstance = {},  -- per-character: { ["Name-Realm"] = { id, name }, ... }
    log = {},
    helpShown = false,
    panelPosition = nil,  -- {point, relativeTo, relativePoint, x, y}
    panelVisible = true,
    logWindowPosition = nil,  -- {point, relativeTo, relativePoint, x, y}
    logWindowSize = nil,  -- {width, height}
}

-- Get current character key "Name-Realm"
local function GetCharacterKey()
    local name, realm = UnitFullName("player")
    realm = realm or GetRealmName()
    return name .. "-" .. realm
end

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
    -- Migrate from old format (global currentInstanceID/Name to per-character)
    if FDCounterDB.currentInstanceID ~= nil then
        local charKey = GetCharacterKey()
        FDCounterDB.currentInstance[charKey] = {
            id = FDCounterDB.currentInstanceID,
            name = FDCounterDB.currentInstanceName,
        }
        FDCounterDB.currentInstanceID = nil
        FDCounterDB.currentInstanceName = nil
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

-- Set counter value (0-99, for manual input)
function FDC:SetCount(value)
    FDCounterDB.count = math.max(0, math.min(99, value))
end

-- Increment counter (no upper limit)
function FDC:IncrementCounterManual()
    FDCounterDB.count = FDCounterDB.count + 1
end

-- Decrement counter (min 0)
function FDC:DecrementCounter()
    if FDCounterDB.count > 0 then
        FDCounterDB.count = FDCounterDB.count - 1
    end
end

-- Get current instance ID being tracked (per-character)
function FDC:GetCurrentInstanceID()
    local charKey = GetCharacterKey()
    local data = FDCounterDB.currentInstance[charKey]
    return data and data.id or nil
end

-- Get current instance name being tracked (per-character)
function FDC:GetCurrentInstanceName()
    local charKey = GetCharacterKey()
    local data = FDCounterDB.currentInstance[charKey]
    return data and data.name or nil
end

-- Set current instance info (per-character)
function FDC:SetCurrentInstance(instanceID, instanceName)
    local charKey = GetCharacterKey()
    FDCounterDB.currentInstance[charKey] = {
        id = instanceID,
        name = instanceName,
    }
end

-- Clear current instance tracking (per-character)
function FDC:ClearCurrentInstance()
    local charKey = GetCharacterKey()
    FDCounterDB.currentInstance[charKey] = nil
end

-- Add event to log
-- event: FDC.EventType.ENTRY, .EXIT, .REENTRY, .COMPLETE
function FDC:LogEvent(event, instanceID, instanceName)
    local character = GetCharacterKey()
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

-- Get log window position
function FDC:GetLogWindowPosition()
    return FDCounterDB.logWindowPosition
end

-- Save log window position
function FDC:SaveLogWindowPosition(point, relativeTo, relativePoint, x, y)
    FDCounterDB.logWindowPosition = {point, relativeTo, relativePoint, x, y}
end

-- Get log window size
function FDC:GetLogWindowSize()
    return FDCounterDB.logWindowSize
end

-- Save log window size
function FDC:SaveLogWindowSize(width, height)
    FDCounterDB.logWindowSize = {width, height}
end
