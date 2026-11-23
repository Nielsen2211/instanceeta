# InstanceETA

**Keeps track of your instances for WoW: Forever.** Part of the ETA family with LevelETA, GoldETA, LayerETA, TrackETA and CraftETA.

The main window is the **instance log**, opened from the minimap button or `/ieta`:

- Your count this hour, in the last 24 hours, and when the next instance is free, at the top.
- Every run numbered and colour coded: past hour, past 24 hours, older, raid and alts.
- Click a run to post its stats to your party. Hover for every detail. Shift right-click to delete it.
- Buttons for **Settings**, **Trades** (gold trade log), **Lockouts** (raid lockouts for all characters) and **Characters** (rested XP, gold, durability, free bag slots, professions, cooldowns and last seen for every character; Shift right-click removes an old character), and a **Show alts** switch.
- A small **compact window** you can turn on in the settings.

What it tracks:

- **This hour**: how many instances you have entered in the last hour, out of the limit (5 on Forever).
- **Last 24 hours**: how many today, with an optional daily limit.
- **Next instance**: the exact time the next one is free, and a toast when it is.
- **Current run**: a timer, XP and XP per hour, looted gold and kills while you are inside.
- **Run log**: every run with time entered, time inside, XP, gold, kills and how long it still counts toward the limit. Hover a run for levels, XP per kill, runs to next level, reputation, group members and gold traded.
- **Same instance detection**: die and run back, or pop out to sell, and the two visits are merged into one run.
- **Battlegrounds**: every game is logged with honor, honorable kills, honor per hour and whether you won or lost, plus your record per battleground. Battlegrounds never count toward the instance limit, and you can hide them in the log.
- **Raid lockouts** for all your characters in the minimap tooltip.
- **Profession cooldowns** (transmutes, Mooncloth, Salt Shaker) for all your characters.
- **Reset message**: when you reset instances, your group is told so they know they can go into a new one.
- **Gold trade log** (`/ieta trades`).
- Summary in chat when you leave, optionally posted to your party.
- English and Danish.

## Commands

`/ieta` log · `/ieta compact` · `/ieta chars` · `/ieta lockouts` · `/ieta config` · `/ieta undo` (remove your last run if it was not a new instance) · `/ieta trades` · `/ieta reset` (move windows back) · `/ieta da|en`

Minimap button: left-click opens the log, right-click opens settings, Shift-click shows the compact window.
