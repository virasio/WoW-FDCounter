# FDCounter

![Status](https://badgen.net/static/status/beta/yellow)
![Status](https://badgen.net/static/version/0.1.0/green)
![WoW Version](https://badgen.net/static/WoW/12.0.0/cyan)
![License](https://badgen.net/static/license/MIT/blue)

A World of Warcraft addon that counts Follower Dungeon entries.

Follower Dungeons have a daily entry limit per account. This addon automatically tracks how many times you've entered Follower Dungeons since the last server reset.

## Features

- **Automatic detection** — counts entries when you zone into a Follower Dungeon
- **Persistent counter** — saves between sessions
- **Auto-reset** — resets at server daily reset time
- **Duplicate protection** — won't count `/reload` as new entry

## Commands

| Command            | Description                             |
|--------------------|-----------------------------------------|
| `/fdcounter`       | Show current count and time until reset |
| `/fdcounter reset` | Reset counter manually                  |

## Installation

1. Download the latest release
2. Extract to `World of Warcraft/_retail_/Interface/AddOns/`
3. Restart WoW or `/reload`
