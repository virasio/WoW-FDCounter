-- FDCounter: Storage module
-- Handles SavedVariables and data persistence

local ADDON_NAME, FDC = ...

-- Default structure
local defaults = {
    data = {
        count = 0,
        resetTime = 0,
        currentInstance = {},  -- per-character: { ["Name-Realm"] = { id }, ... }
        log = {},
    },
    ui = {
        panelPosition = nil,   -- {point, relativeTo, relativePoint, x, y}
        panelVisible = true,
        logWindowPosition = nil,
        logWindowSize = nil,   -- {width, height}
    },
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

-- Migrate from old flat structure to new nested structure
local function MigrateFromFlatStructure()
    -- Check if migration needed (old structure has count at root level)
    if FDCounterDB.count ~= nil or FDCounterDB.panelPosition ~= nil then
        local oldDB = FDCounterDB
        FDCounterDB = {
            data = {
                count = oldDB.count or 0,
                resetTime = oldDB.resetTime or 0,
                currentInstance = oldDB.currentInstance or {},
                log = oldDB.log or {},
            },
            ui = {
                panelPosition = oldDB.panelPosition,
                panelVisible = oldDB.panelVisible ~= false,  -- default true
                logWindowPosition = oldDB.logWindowPosition,
                logWindowSize = oldDB.logWindowSize,
            },
        }
        -- Clean up old fields that were migrated
        -- (currentInstanceID/Name migration from even older format)
        if oldDB.currentInstanceID ~= nil then
            local charKey = GetCharacterKey()
            FDCounterDB.data.currentInstance[charKey] = {
                id = oldDB.currentInstanceID,
            }
        end
    end
end

-- Initialize saved variables with defaults
function FDC:InitializeStorage()
    if FDCounterDB == nil then
        FDCounterDB = {}
    end

    -- Migrate old structure if needed
    MigrateFromFlatStructure()

    -- Ensure data subtable exists with defaults
    if FDCounterDB.data == nil then
        FDCounterDB.data = {}
    end
    for key, value in pairs(defaults.data) do
        if FDCounterDB.data[key] == nil then
            FDCounterDB.data[key] = value
        end
    end

    -- Ensure ui subtable exists with defaults
    if FDCounterDB.ui == nil then
        FDCounterDB.ui = {}
    end
    for key, value in pairs(defaults.ui) do
        if FDCounterDB.ui[key] == nil then
            FDCounterDB.ui[key] = value
        end
    end
end

-- Check if counter should be reset (past daily reset)
function FDC:CheckAndResetCounter()
    if time() >= FDCounterDB.data.resetTime then
        FDCounterDB.data.count = 0
        FDCounterDB.data.log = {}
        FDCounterDB.data.resetTime = self:GetNextResetTime()
    end
end

-- Reset data only (count, log, currentInstance)
function FDC:ResetData()
    FDCounterDB.data = {}
    for key, value in pairs(defaults.data) do
        FDCounterDB.data[key] = value
    end
    FDCounterDB.data.resetTime = self:GetNextResetTime()
end

-- Reset UI only (positions, sizes, visibility)
function FDC:ResetUI()
    FDCounterDB.ui = {}
    for key, value in pairs(defaults.ui) do
        FDCounterDB.ui[key] = value
    end
end

-- Full reset (everything)
function FDC:FullReset()
    FDCounterDB = {}
    self:InitializeStorage()
    FDCounterDB.data.resetTime = self:GetNextResetTime()
end

-- Get current count
function FDC:GetCount()
    return FDCounterDB.data.count
end

-- Set counter value (0-99, for manual input)
function FDC:SetCount(value)
    FDCounterDB.data.count = math.max(0, math.min(99, value))
end

-- Increment counter (no upper limit)
function FDC:IncrementCounterManual()
    FDCounterDB.data.count = FDCounterDB.data.count + 1
end

-- Decrement counter (min 0)
function FDC:DecrementCounter()
    if FDCounterDB.data.count > 0 then
        FDCounterDB.data.count = FDCounterDB.data.count - 1
    end
end

-- Get current instance ID being tracked (per-character)
function FDC:GetCurrentInstanceID()
    local charKey = GetCharacterKey()
    local data = FDCounterDB.data.currentInstance[charKey]
    return data and data.id or nil
end

-- Set current instance info (per-character)
function FDC:SetCurrentInstance(instanceID)
    local charKey = GetCharacterKey()
    FDCounterDB.data.currentInstance[charKey] = {
        id = instanceID,
    }
end

-- Clear current instance tracking (per-character)
function FDC:ClearCurrentInstance()
    local charKey = GetCharacterKey()
    FDCounterDB.data.currentInstance[charKey] = nil
end

-- Add event to log
function FDC:LogEvent(event, instanceID)
    local character = GetCharacterKey()
    table.insert(FDCounterDB.data.log, {
        time = time(),
        event = event,
        character = character,
        instanceID = instanceID,
    })
end

-- Get log entries
function FDC:GetLog()
    return FDCounterDB.data.log
end

-- Get reset time
function FDC:GetResetTime()
    return FDCounterDB.data.resetTime
end

-- Update reset time to next daily reset
function FDC:UpdateResetTime()
    FDCounterDB.data.resetTime = self:GetNextResetTime()
end

-- Get panel position
function FDC:GetPanelPosition()
    return FDCounterDB.ui.panelPosition
end

-- Save panel position
function FDC:SavePanelPosition(point, relativeTo, relativePoint, x, y)
    FDCounterDB.ui.panelPosition = {point, relativeTo, relativePoint, x, y}
end

-- Check if panel is visible
function FDC:IsPanelVisible()
    return FDCounterDB.ui.panelVisible
end

-- Set panel visibility
function FDC:SetPanelVisible(visible)
    FDCounterDB.ui.panelVisible = visible
end

-- Get log window position
function FDC:GetLogWindowPosition()
    return FDCounterDB.ui.logWindowPosition
end

-- Save log window position
function FDC:SaveLogWindowPosition(point, relativeTo, relativePoint, x, y)
    FDCounterDB.ui.logWindowPosition = {point, relativeTo, relativePoint, x, y}
end

-- Get log window size
function FDC:GetLogWindowSize()
    return FDCounterDB.ui.logWindowSize
end

-- Save log window size
function FDC:SaveLogWindowSize(width, height)
    FDCounterDB.ui.logWindowSize = {width, height}
end
