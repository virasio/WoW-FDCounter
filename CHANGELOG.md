# Changelog

## 1.0.0

### Added
- `/fdcounter show` and `/fdcounter hide` commands for show/hide panel with entry counter
- Draggable UI panel showing entry count and time until reset
- Inline counter editing on hover: reset, decrease, increase, manual input
- Quick action buttons: leave dungeon, open log window
- Log window with three view modes:
  - Statistics: table with dynamic hour columns (+/- buttons), instance filter
  - Log Table: event log with character and instance dropdown filters
  - Raw Log: CSV format for copying
- Panel and log window positions and size saved between sessions

### Fixed
- Instance tracking now correctly handles re-entries when switching between characters inside dungeons
- Dungeon names display in the current game language

## 0.2.0

### Added
- Event logging: tracks entries, exits, re-entries, and completions with timestamps
- `/fdcounter log [H]` — show event log for last H hours
- `/fdcounter stat [H1,H2,...] [ID]` — multi-character statistics with time periods and instance filtering
- `/fdcounter help` — show all available commands

## 0.1.0

### Added
- Automatic Follower Dungeon entry detection
- Counter persists between sessions
- Auto-reset at server daily reset
- Slash commands:
  - `/fdcounter` — show current count and time until reset
  - `/fdcounter reset` — manual reset
- Custom addon icon
