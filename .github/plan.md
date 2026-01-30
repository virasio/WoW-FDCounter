# FDCounter Development Plan

## Overview

A World of Warcraft addon to count Follower Dungeon entries with automatic reset at server daily reset.

## Stages

### Stage 1: Minimal Addon — "Hello" ✅
1. Create `FDCounter.toc` with `## Interface: 120000`
2. Create `FDCounter.lua` — `/fdcounter` → `"Hello from FDCounter!"`
3. Create symlink to WoW addons folder (manually, path not stored in repo)
4. Test in game: `/reload` → `/fdcounter`
5. Add custom icon in `Assets/Icon.tga`
6. Commit to `develop`

### Stage 2: Counter with Persistence and Auto-Reset ✅
1. Add `## SavedVariables: FDCounterDB` to TOC
2. Structure: `FDCounterDB = { count = 0, resetTime = <timestamp> }`
3. On load: use `C_DateAndTime.GetSecondsUntilDailyReset()` to calculate `resetTime`
4. If `time() >= resetTime` → reset `count`, update `resetTime`
5. `/fdcounter` — show counter and time until reset
6. `/fdcounter reset` — manual reset
7. `/fdcounter ++` — manual increment (for testing)
8. Commit to `develop`

### Stage 3: Auto-Count Follower Dungeons ✅
1. Listen to `PLAYER_ENTERING_WORLD` → check `GetInstanceInfo()` → `difficultyID == 205`
2. Delay check by 3 seconds (API update timing)
3. Protect against duplicates on `/reload` (ignore isLogin/isReload)
4. Protect against re-entry via portal (track `currentInstanceID`, clear on `GROUP_LEFT`)
5. Chat notification on entry
6. Create `CHANGELOG.md`
7. Update README with full description
8. Commit to `develop`

### Stage 4: GitHub Actions & Publishing ✅
1. Create `.github/workflows/release.yml` — `BigWigsMods/packager@v2`
2. Add X-identifiers to TOC: CurseForge `1447993`, Wago `qKQm8aKx`
3. Add secrets to GitHub: `CF_API_KEY`, `WAGO_API_TOKEN`
4. **Merge to `main`** — first working release  → Tag `v0.1.0` → auto-publish

### Stage 4.1: Code Refactoring ✅
1. Split monolithic `FDCounter.lua` into modules:
   - `Core.lua` — namespace, version, constants
   - `Storage.lua` — SavedVariables, data persistence
   - `Logic.lua` — business logic, event handlers
   - `Events.lua` — event registration and dispatch
   - `Commands.lua` — slash command handling
2. Add `/fdcounter help` command
3. Single `FDC:Initialize()` entry point
4. Commit to `develop`

### Stage 5: Extended Log and Statistics
#### 5.1: Event Logging ✅
1. Log structure: `FDCounterDB.log = { {time, event, character, instanceID}, ... }`
2. Events: `entry`, `exit`, `reentry`, `complete`
3. Character format: `"Name-Realm"`
4. Clear log on daily reset
5. Commit to `develop`

#### 5.2: Log Output ✅
1. `/fdcounter log [H]` — show events from last H hours (default: 24)
2. Commit to `develop`

#### 5.3: Statistics ✅
1. `/fdcounter stat [H1,H2,...] [instanceID]` — CSV-style statistics
2. Output: character, total, count per each H period
3. Last row: Total across all characters
4. Instance ID detection: standalone number > 100
5. Commit to `develop`

#### 5.4: Refactoring and Pipeline ✅
1. Separate Logic and Output layers:
   - `Logic.lua` — returns data objects, no output
   - `Output.lua` — formatting and chat output, uses localization
2. Data structures: `StatusData`, `LogData`, `StatisticsData`
3. Commands flow: Commands → Logic (data) → Output (display)
4. Pipeline configuration
5. Merge → tag `v0.2.0`

### Stage 6: UI Panel

#### 6.1: Basic Panel ✅
1. Draggable panel with entry count and time until reset (H:mm format)
2. Save position in `FDCounterDB.panelPosition`
3. Save visibility in `FDCounterDB.panelVisible`
4. Commands `/fdcounter show`, `/fdcounter hide`
5. Quick action buttons: leave dungeon, reset counter
6. Timer updates every minute
7. Commit to `develop`

#### 6.2: Counter Editing ✅
1. Inline buttons on hover: reset, minus, plus, manual input
2. Input dialog with validation (0-99)
3. Commit to `develop`

#### 6.3: UI Code Refactoring ✅
1. Split monolithic `UI.lua` (438 lines) into modular structure:
   - `UI/UIConstants.lua` — sizes, backdrop configurations
   - `UI/UIWidgets.lua` — button factories, helper functions
   - `UI/InputDialog.lua` — input dialog creation
   - `UI/Panel.lua` — main panel with local helper functions
2. Eliminated backdrop duplication (4x → 1x via `UI.ApplyBackdrop`)
3. Commit to `develop`

#### 6.4: Log and Statistics Window ✅
1. Log window with RAW/Table/Stats view tabs
2. RAW view: CSV format (timestamp,event,character,instanceID)
3. Table view: localized table with formatted time and event names
4. Stats view: statistics with 1h, 6h, 24h columns
5. Commit to `develop`

## Technical Notes

- **Interface version:** `120000` (Midnight 12.0.0)
- **Follower Dungeon difficultyID:** `205`
- **Daily reset API:** `C_DateAndTime.GetSecondsUntilDailyReset()`
- **Publishing:** BigWigsMods/packager for CurseForge, Wago, WoWInterface
