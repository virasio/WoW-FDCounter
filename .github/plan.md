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

### Stage 5: Extended Log
1. Structure: `FDCounterDB.log = { {time, instance, character, realm}, ... }`
2. Log each entry with full information
3. `/fdcounter log [H]` — show entries from last H hours (default: 24)
4. Filter by instance, character
5. Merge → tag `v0.2.0`

### Stage 6: UI Panel
1. Draggable frame with text `"FD: N"`
2. Save position in `FDCounterDB.position`
3. Commands `/fdcounter show`, `/fdcounter hide`
4. Merge → tag `v1.0.0`

## Technical Notes

- **Interface version:** `120000` (Midnight 12.0.0)
- **Follower Dungeon difficultyID:** `205`
- **Daily reset API:** `C_DateAndTime.GetSecondsUntilDailyReset()`
- **Publishing:** BigWigsMods/packager for CurseForge, Wago, WoWInterface
