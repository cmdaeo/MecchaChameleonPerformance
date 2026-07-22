# Meccha Chameleon Performance

A configurable, low-end-PC-friendly performance mod that lets you trade visual
quality for FPS through a single, fully-commented text file — no need to dig
through console commands or engine .ini files yourself.

## What It Does

This mod applies a curated list of engine console variables ("cvars") that
control rendering quality, shadows, lighting, streaming, and more. All values
are editable in one plain text file on your Desktop, and can be toggled on
and off in-game at any time with a single keypress.

It also automatically captures your game's original settings at the start of
every session, so you can always safely revert back to how the game looked
and ran before the mod touched anything.

## Installation

1. Make sure [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS) is installed for
   your game.
2. Copy the `MecchaChameleonPerformance` folder into your game's `Mods`
   directory.
3. Launch the game.

## How to Use

| Key | Action |
|---|---|
| **F1** | Enable — applies your custom config (Desktop file) |
| **F2** | Disable — restores the game's original settings from this session |

On the very first launch, the mod creates a file on your Desktop called:

```
performance_chameleon_mod.txt
```

Open it in any text editor. Every setting has a comment above it explaining:
- What it controls
- What the numbers mean
- Which direction is "faster" vs "prettier"

Edit any value, save the file, then press **F1** in-game to apply your changes.
You do **not** need to restart the game to apply edits — just save and press F1
again (press F2 first if it's already enabled).

## Important Notes

- **Your Desktop config is never overwritten.** It's created once on first
  launch and left alone forever after that — your edits are permanent across
  sessions.
- **The "original settings" snapshot IS refreshed every time you launch the
  game.** This is intentional: it captures your actual live settings for that
  session, so F2 always restores you to exactly how the game started up that
  time (in case your normal in-game graphics settings ever change between
  sessions).
- The default config included is tuned for **low-end/older PCs** and
  prioritizes maximum FPS over visual fidelity. If something looks too plain,
  find that specific line in the config and raise the value — the comments
  explain what each one does.
- Pressing F1 or F2 while already in that state does nothing (prevents
  redundant re-application).

## Troubleshooting

- **Nothing happens when I press F1/F2**: Check the UE4SS console/log window
  for `[MecchaChameleonPerformance]` messages — they'll tell you if the
  PlayerController wasn't found or a cvar failed to apply.
- **F2 says "no captured original config found"**: This means the capture
  hook hasn't fired yet (usually happens shortly after your character spawns
  in). Wait a few seconds after loading into the game before pressing F2.
- **I want to reset my Desktop config back to defaults**: Delete
  `performance_chameleon_mod.txt` from your Desktop and relaunch the game —
  the mod will regenerate it with the default low-end preset.
Both READMEs assume the folder names match your mod structure (`MecchaChameleonPerformance` and `AccessibilityHighlight`) — let me know if you'd like the folder/mod names adjusted to match exactly what you're using, or if you want a shorter "quick start" version instead of the full troubleshooting sections.
