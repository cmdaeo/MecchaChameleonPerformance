# MecchaChameleonPerformance

A lightweight UE4SS mod for **MECCHA CHAMELEON** that exposes the game's Unreal Engine 5 console variables through a single, human-readable config file — giving you direct control over rendering quality, texture streaming, input latency, audio, and network smoothing without digging through dev console commands every session.

## Features

- **Config-driven** — all tuning lives in `performance_chameleon_mod.txt`, generated automatically with inline comments explaining every setting.
- **Two-hotkey workflow** — `F1` applies your config, `F2` restores the game's original captured settings. No sprawling hotkey list to memorize. (not really working but almost)
- **Safe restore** — the mod captures the game's live default cvar values on first load and stores them separately (hidden from the user-facing config), so disabling always reverts to a known-good state. (not really working but almost)
- **Performance tuning** — shadow quality, Lumen GI/reflections, Nanite detail, texture pool size and VRAM cap removal, garbage collection timing.
- **Input latency reduction** — `r.GTSyncType` + `r.OneFrameThreadLag` tuned per Epic's documented guidance for lower-cost responsiveness gains.
- **Visual clarity options** — toggle off film grain, chromatic aberration, and vignette (cosmetic post-process effects with no gameplay value).
- **Audio tuning** — HRTF/binaural spatialization, channel limits, occlusion behavior.
- **Netcode tuning** — movement smoothing, interpolation, and update frequency settings for a more responsive feel.

## Requirements

- [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS) installed for MECCHA CHAMELEON.
- Windows (paths assume `%USERPROFILE%\Desktop` for the config file).

## Installation

1. Drop the mod folder into your UE4SS `Mods` directory.
2. Enable it in `mods.txt`.
3. Launch the game — a default config will be generated on your Desktop.
4. Edit values as needed, then press `F1` in-game to apply.

## Disclaimer

This mod only exposes standard Unreal Engine console variables already accessible via the in-game developer console. It does not modify game memory, inject visual overlays, or provide any gameplay-affecting information advantage. Use at your own discretion; some cvars may behave differently across game updates.
