# FDCounter

![Status](https://badgen.net/static/status/beta/yellow)
![Version](https://badgen.net/static/version/1.0.0/green)
![WoW Version](https://badgen.net/static/WoW/12.0.0/cyan)
![License](https://badgen.net/static/license/MIT/blue)

A World of Warcraft addon that counts Follower Dungeon entries.

Follower Dungeons have a daily entry limit per account. This addon automatically tracks how many times you've entered Follower Dungeons since the last server reset. It keeps a detailed event log and provides statistics across multiple characters — useful for players who farm dungeons on alts.

## Features

- **Draggable UI panel** — shows entry count and time until reset, with inline counter editing on hover
- **Quick leave button** — teleport out and leave group in one click
- **Automatic detection** — counts entries when you zone into a Follower Dungeon
- **Persistent counter** — saves between sessions
- **Auto-reset** — resets at server daily reset time
- **Duplicate protection** — won't count `/reload` or portal re-entry as new entry
- **Event log** — tracks entries, exits, re-entries, and completions with timestamps
- **Multi-character statistics** — CSV-style output with customizable time periods
- **Instance filtering** — view stats for specific dungeons by ID

## Commands

### `/fdcounter`
Shows current entry count and time until daily reset.
```
FDCounter: 3 entries | Reset in 5h 23m
```

### `/fdcounter help`
Shows all available commands with examples.

### `/fdcounter reset`
Resets the counter and clears the event log.

### `/fdcounter log [H]`
Shows event log for the last H hours (default: 24).
```
FDCounter: Log (last 24h)
Time, Event, Character, Instance
14:32:15, ENTRY, Virasio-Ravencrest, The Rookery (ID:2648)
14:32:25, EXIT, Virasio-Ravencrest, The Rookery (ID:2648)
14:34:57, REENTRY, Virasio-Ravencrest, The Rookery (ID:2648)
14:45:22, COMPLETE, Virasio-Ravencrest, The Rookery (ID:2648)
```

### `/fdcounter stat [H1,H2,...] [instanceID]`
Shows statistics per character in CSV format. Optional time columns and instance filter.

Examples:
- `/fdcounter stat` — total entries per character
- `/fdcounter stat 1,6,12` — with columns for last 1h, 6h, 12h
- `/fdcounter stat 1,6 2648` — only for instance ID 2648

```
FDCounter: Statistics
Character, Total, 1h, 6h
Virasio-Ravencrest, 8, 2, 4
Angelochka-Ravencrest, 3, 1, 2
Total, 8, 3, 6
```

### `/fdcounter show`
Shows the UI panel.

### `/fdcounter hide`
Hides the UI panel.
