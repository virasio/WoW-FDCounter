# Changelog

## 1.0.0

### Added
- Draggable UI panel showing entry count and time until reset
- `/fdcounter show` — show UI panel
- `/fdcounter hide` — hide UI panel
- Quick action buttons on panel: leave dungeon, reset counter
- Panel position saved between sessions

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
