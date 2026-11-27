---
name: lantern-keeper-arpg
description: Build or tune Lantern Keeper's action-RPG systems (combat, enemies, bosses, leveling, Diablo-style loot, NPC dialogue) the way this project does them. Use for any combat, enemy, boss, level-up, loot, item, inventory or NPC work, and for balance passes.
---

# Lantern Keeper ARPG

Lantern Keeper is a 2D top-down **action RPG** in Godot 4.7 / GDScript. The keeper's light is the weapon.
Read `docs/PLAN_KEEPERS_LIGHT.md` (the design), `docs/DECISIONS.md` (newest first; it wins) and
`docs/DESIGN.md` §9 (what's built) before changing anything here.

## Pillars (owner decisions; don't break them)
- **Light is the weapon.** The beam (aimed, hold), the burst (tap, cooldown) and the dash run on **lamp charge**, the stamina. Lantern light refills it.
- **The find is the key.** Each region's find (the Hollow: the Post Lamp) is needed to clear that region and win its WayLamp guardian fight.
- **ARPG pacing.** No endless spawns. Enemies wait in fixed packs, nests and guardian fights, and get tougher toward the WayLamp. Cleared stays cleared. **The start is calm:** nothing hostile within 16 tiles of the hut. Elites sleep on their post until you come close (wake radius, leash).
- **Lanterns:** about half the Wicklings are timid; brave ones burn after a while in light. Elites and guardians ignore lanterns.
- **Readable fights:** every foe has a name. Hurt or big foes show a health bar, with the shell as a pale bar above it. Guardians get a boss bar with the phase and a one-line hint. Hits flash; bursts, kills and big hits shake the screen.
- **Loot is Diablo-style** (owner, 2026-11-27): random drops with rarity and rolled stats that you compare and swap. Item slots: **lens** (changes the beam), **burner** (changes the burst), **coat** (armor and warmth), **wick** (charge). Elites and bosses drop more and better.
- **No game over:** fainting costs carried resources and the guardian restarts its phase.

## How things are built here
- **Foes** extend `scripts/enemies/foe.gd`, which holds hp, shell, `hurt(amount, scare, source)`, knock, stun, flash, `foe_name` and `hp_max`. Only `source == "beam"` wears a shell down. Set `foe_name`, `wick_value` and `body_radius()`. Fixed foes get a `foe_id` so they stay cleared (`Progress.cleared`).
- **Numbers** all live in `systems/tuning.gd` under the `kl_` prefix, and the tunable ones go in the F1 panel (`scripts/ui/debug_panel.gd`). Never hard-code a balance number in a script.
- **Leveling:** wick (XP) comes from kills and kindling. The thresholds are `kl_wick_first_level + kl_wick_level_step * (level - 1)` (`systems/progress.gd`). Level-up cards are in `scripts/ui/level_up.gd`. Upgrades must change real numbers, be saved, and be checked with `Progress.has_combat_upgrade(id)`.
- **UI** is code-built with `UiStyle`, works with keyboard, mouse and gamepad, and `interact` (A) presses the focused button. Remove old buttons from their parent before focusing new ones (that bug happened). Use Ark Pixel at sizes 20, 30, 40 or 60 only.
- **Plugins (vetted 2026-11-27):** Dialogue Manager 4.2+ (MIT, from its GitHub release) for NPC talk. GLoot 3.x (MIT), **data classes only**, for inventory, with our own controller UI. Loot rolling is our own code. Keep each add-on's LICENSE file, and add a row to `assets/CREDITS.md`.

## Balance passes
1. Write the target first, as a number: "a fresh keeper clears a 4-Wickling pack in about 8 s and loses under 30% warmth", "level 2 by the first nest", "a guardian takes 60-90 s".
2. Measure it with a headless test or the benchmark, not by feel. Compute time-to-kill from the dps, hp and shell in `tuning.gd`, and wick per region from the packs, nests and guardian.
3. Change `tuning.gd` only, and record the old and new values and why in DESIGN §9.
4. Check that the owner's latest playtest notes in `docs/PLAYTEST.md` are answered.

## Every change
- Add or extend a test in `tools/tests/`. Tests set process_mode ALWAYS, strip joypad events, set `Story.skip_opening`, and use a test save path, never `user://save_*.json`.
- Run `tools/run_tests.sh` (it fails on any SCRIPT ERROR) and `python3 tools/check_docs.py`. Look at a capture frame (`tools/capture/capture.gd`) for anything visible.
- Run silently (`--audio-driver Dummy`). Never write under /tmp.
- Work in your own git worktree. The owner plays from `wt-hollow` and `~/Projects/lantern-keeper`.
