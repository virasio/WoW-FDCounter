-- FDCounter: UI Constants
-- Centralized sizes, styles, and backdrop configurations

local ADDON_NAME, FDC = ...

FDC.UI = {}

-- Panel dimensions
FDC.UI.PANEL_WIDTH = 96
FDC.UI.PANEL_HEIGHT = 88
FDC.UI.PANEL_HEADER_HEIGHT = 28

-- Button dimensions
FDC.UI.BUTTON_SIZE = 44
FDC.UI.BUTTON_GAP = 0
FDC.UI.INLINE_BUTTON_SIZE = 20

-- Log window dimensions
FDC.UI.LOG_WINDOW_WIDTH = 400
FDC.UI.LOG_WINDOW_HEIGHT = 300
FDC.UI.LOG_WINDOW_MIN_WIDTH = 400
FDC.UI.LOG_WINDOW_MIN_HEIGHT = 200
FDC.UI.LOG_WINDOW_MAX_WIDTH = 800
FDC.UI.LOG_WINDOW_MAX_HEIGHT = 600

-- Standard backdrop configuration (reusable)
FDC.UI.STANDARD_BACKDROP = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
}

-- Backdrop colors
FDC.UI.BACKDROP_COLOR = { r = 0, g = 0, b = 0, a = 0.6 }
FDC.UI.BACKDROP_COLOR_SOLID = { r = 0, g = 0, b = 0, a = 0.9 }
FDC.UI.BORDER_COLOR = { r = 0.6, g = 0.6, b = 0.6, a = 0.8 }
FDC.UI.BORDER_COLOR_SOLID = { r = 0.6, g = 0.6, b = 0.6, a = 1 }
