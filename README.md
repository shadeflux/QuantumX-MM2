# Quantum X — Murder Mystery 2

> **Version:** v1.6.6 &nbsp;|&nbsp; **Platform:** Roblox &nbsp;|&nbsp; **UI:** WindUI  
> **Discord:** [discord.gg/2W2MUCEDCB](https://discord.gg/2W2MUCEDCB)

---

## Overview

Quantum X is a two-file exploit script for Roblox. `loader.lua` acts as the universal entry point and works in **any Roblox game**. When it detects Murder Mystery 2, it automatically downloads and executes `mm2.lua`, which contains the full MM2 feature set.

---

## Quick Start

Paste the following single line into your executor:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/shadeflux/QuantumX-MM2/main/loader.lua"))()
```

The loader will handle everything else automatically.  
If you are already inside Murder Mystery 2, `mm2.lua` loads within 3 seconds.  
You can also press the **"Load MM2 Features"** button in the MM2 tab manually.

---

## Supported Games

| Game | PlaceId | Support level |
|---|---|---|
| Murder Mystery 2 | `142823291` | ✅ Full |
| Any other Roblox game | — | ⚡ Universal only (Speed, Noclip, Dev Tools) |

---

## Features

### Universal (all games)

| Feature | Description |
|---|---|
| Speed Hack | Adjustable WalkSpeed slider (16 – 350). |
| Noclip | Disables collision on all character parts every frame. |
| Rejoin Server | Teleports to a fresh server instance of the current game. |
| Infinite Yield | Loads the Infinite Yield admin console. |
| Dex Explorer | Loads the Dex object explorer. |
| SimpleSpy | Loads the SimpleSpy remote spy. |

---

### MM2 — ESP

| Feature | Description |
|---|---|
| Player ESP | Highlight + nameplate on every player. Color-coded by role: **red** = Murderer, **blue** = Sheriff, **green** = Innocent. Always visible through walls. |
| Gun ESP | Orange highlight on any Sheriff gun that is dropped on the map. Automatically re-scans after the Sheriff dies so new drops are detected immediately. |
| Teleport to Gun | One-click teleport to the nearest dropped gun. |

---

### MM2 — Auto Farm

| Feature | Description |
|---|---|
| Auto Farm Coins | Teleports to coins automatically. Scores every coin by its distance from the Murderer. Only teleports to coins that are **60+ studs** from the Murderer. If all coins are unsafe, picks the least-dangerous one. |
| Auto Open Crates | Teleports to each crate on the map and fires the `OpenCrate` remote. |

---

### MM2 — Coin Bag

| Feature | Description |
|---|---|
| Die at Full Bag | Sets Humanoid Health to 0 when the coin bag reaches maximum capacity. |
| Teleport Under Map | Teleports the character to Y = −500 when the bag is full. |
| Reset Character | Calls `BreakJoints()` on the character when the bag is full. |

---

### MM2 — Weapons

| Feature | Description |
|---|---|
| Auto Pickup Gun | Teleports the character directly onto the dropped gun every 0.4 seconds, triggering the game's built-in touch-collection. Also attempts a direct backpack parent as a fallback. Works even after the Sheriff dies. |

---

### MM2 — Kill

| Feature | Description |
|---|---|
| Kill All as Murderer | Auto-equips the Knife from the Backpack, then teleports to each player and fires the `Attack` remote. |
| Kill Murderer as Sheriff | Auto-equips the Gun from the Backpack, teleports behind the Murderer, and fires the `Shoot` remote. |
| Auto Fling Murderer | As Sheriff, rushes close to the Murderer and fires the `Shoot` remote at high frequency. |

---

## File Structure

```
QuantumX-MM2/
├── loader.lua   Universal loader. Run this file only.
├── mm2.lua      MM2-specific script. Auto-loaded by loader.lua.
└── README.md    This file.
```

---

## Architecture

`loader.lua` exposes three global references that `mm2.lua` reads on startup:

| Global | Type | Purpose |
|---|---|---|
| `getgenv().QuantumX_Loader_Loaded` | `boolean` | Prevents duplicate loader execution. |
| `getgenv().QuantumX_Window` | WindUI Window | Shared GUI window. `mm2.lua` adds its tabs here instead of creating a new window. |
| `getgenv().QuantumX_WindUI` | WindUI instance | Shared library reference so WindUI is only downloaded once. |
| `getgenv().QuantumX_Config` | `table` | Speed and Noclip settings. Written by the loader, read by `mm2.lua` so both files share the same values without conflicts. |
| `getgenv().MM2Config` | `table` | All MM2-specific settings. Written by `mm2.lua`. |
| `getgenv().QuantumX_MM2_Loaded` | `boolean` | Prevents duplicate `mm2.lua` execution. |

`mm2.lua` also works fully standalone (without the loader). When run alone it detects the absence of `QuantumX_Window` and creates its own GUI window, including a Movement tab with Speed and Noclip controls.

---

## Requirements

- A Roblox executor that supports `getgenv()`, `loadstring`, `game:HttpGet`, and `setclipboard` (e.g. Delta, Solara, Wave, Fluxus).
- An active internet connection to download WindUI and the script files from GitHub.

---

## Disclaimer

This script is provided for educational purposes only. Use it responsibly and at your own risk. The developers are not responsible for any account actions taken by Roblox.

---

*Developed by Quantum Team — [discord.gg/2W2MUCEDCB](https://discord.gg/2W2MUCEDCB)*
