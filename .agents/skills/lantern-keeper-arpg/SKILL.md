---
name: lantern-keeper-arpg
description: Build or tune Lantern Keeper's action-RPG systems (combat, enemies, bosses, leveling, Diablo-style loot, NPC dialogue) the way this project does them. Use for any combat, enemy, boss, level-up, loot, item, inventory or NPC work, and for balance passes.
---

# Lantern Keeper ARPG

Lantern Keeper is a 2D top-down **action RPG** in Godot 4.7 / GDScript. The hand lamp throws fire-light.
Read these before changing anything here:
- `docs/replan/GAME_PLAN.md`: the plan of record (approved by the owner 2026-11-27). §4 skills, §5 resources, §8 foes, §9 leveling, §10 loot, §18 milestones.
- `docs/DECISIONS.md`: newest first; it wins. The index at the top lists what stands.
- `docs/DESIGN.md`: what is **built** today and what is **PLANNED (Mx)**. Build only your milestone's scope (`docs/ROADMAP.md`).
- `docs/research/ARPG_REFERENCES.md`: how other games solve the same problems. **Original design only:** other games are references for mechanics, never for names, characters, art or levels.

## Pillars (owner-approved; don't break them)
From the game plan §1, §4 and §10.
- **Light is your weapon.** Fireballs of light from the hand lamp, aimed with the right stick or the mouse. The kit: **Lampfire** (the basic attack, RT, free, refills charge on hit), **Fireglobe** (the big lobbed fireball, RB, from level 1), **Lance** (the piercing shell-breaker, LB, from level 2), the **dash** (LT). The Beam and **Hearth ring** (the old burst) are optional picks until the owner decides after the M1a playtest. Moth-lights come at level 7, Wheeling flame at level 9. Built today: only the beam, burst and dash; the fire kit is M1a.
- **Every input is honest on a pad.** RT, RB, LB and LT work while you aim. Y holds self-cast skills only. B is the flask, read after the menu guard, so a press that closes a menu never drinks. The D-pad never moves the keeper.
- **Light is your shelter, and you carry it.** Planted lamps and lit WayLamps are pockets where you refill. No upkeep: lamps never burn (M1b). In a fight, light refills charge only slowly and never warms you; **flasks** heal. Out of a fight, light refills fast. Rest at a lit WayLamp refills flasks.
- **The find is the key.** Each region's find is a lamp that opens its lock and answers one phase of its guardian (the Hollow: the Post Lamp burns nests).
- **Readable fights.** Every big hit has a tell. Every foe has a name, a level and a bar; shells show as a pale bar; guardians get a boss bar with the phase and a hint. Hits flash; big hits shake the screen; hit-stop is per target, not global (M1a; today a kill freezes the whole game).
- **Every fight pays, once.** Fixed packs, nests, mid-bosses and guardians; no endless spawns. Level-gap wick stops farming. Cleared ground stays cleared, even after a faint (the faint rule, M1b). **Summoned foes drop nothing** but wick.
- **Every pick changes how a skill behaves.** Three tiers per skill, one pick each, from fixed branches (M2). No percentage-only picks, except the Beam's approved cards. Gear never repeats a branch pick, and numbers add, never multiply.
- **Loot is Diablo-style** (M3): Plain, Bright, Rare and Relic; four slots: **lens** (direct hits), **burner** (blasts, rings, motes, burning ground), **coat** (warmth and defence), **wick** (lamp charge). About 8 hand-made relics. Elites and bosses drop more and better. Scrap is the one material; salvage, no vendor; loot is finite.
- **Calm at the edges.** A calm start (nothing wakes at the hut), quiet held ground, **no game over**: fainting wakes you by a light.
- **Scope traps:** one projectile system and one status system for keeper and foes; no second progression track; one region fully playable before the next. Cut lines: the Tallest, Kit's re-cut, Ivo, Moth-lights' tier 3.

## How things are built here
- **Foes** extend `scripts/enemies/foe.gd`, which holds hp, shell, `hurt(amount, scare, source)`, knock, stun, flash, `foe_name` and `hp_max`. As built, only `source == "beam"` wears a shell down; the plan's shell rule (full, half, none per skill) comes in M1a (DESIGN §4.5). Set `foe_name`, `wick_value` and `body_radius()`. Fixed foes get a `foe_id` so they stay cleared (`Progress.cleared`). Foes a nest or guardian makes are "summoned" and drop nothing.
- **Numbers** all live in `systems/tuning.gd` under the `kl_` prefix, and the tunable ones go in the F1 panel (`scripts/ui/debug_panel.gd`). Never hard-code a balance number in a script. The plan names each new one (`kl_lampfire_*`, `kl_flask_*` and so on).
- **Leveling:** wick (XP) comes from kills and kindling. Wick from level L to L+1 is `round(kl_wick_base * L ^ kl_wick_exp)` (`Progress.wick_for_level`), up to `kl_level_cap`; each foe has a base `kl_*_wick` and a `level` (packs and nests: the `HOLLOW_PACKS` / `HOLLOW_NESTS` tables; bosses: tuning.gd; hatched and called foes take their maker's). A kill pays `Progress.kill_wick`: base grown by the foe's level, times the level-gap factor (full up to `kl_xp_band` levels over, then ×`kl_xp_falloff` a level, nothing at `kl_xp_zero_gap`). Never stop farming with "pays 0" rules: give foes a level and let the gap do it (owner, 2026-11-27). The test also checks that farming stalls. `tools/tests/test_leveling.tscn` checks a full clear against the targets in DESIGN §9. Today's level-up cards are in `scripts/ui/level_up.gd` (they become branch picks in M2). Upgrades must change real numbers, be saved, and be checked with `Progress.has_combat_upgrade(id)`.
- **Skills** (M1a): one script per skill in `scripts/player/skills/` on a shared `Skill` base; one pooled `Projectile` for keeper and foes; status effects (burning, stun, slow, chill, burning ground) in `systems/status/`. Additive `Sprite2D` for fireballs, trails and blasts; `PointLight2D` only for the hand lamp, lamps and WayLamps. A ray or shape cast per tick for fast bolts; `intersect_shape` for instant blasts.
- **UI** is code-built with `UiStyle`, works with keyboard, mouse and gamepad, and `interact` (A) presses the focused button. Remove old buttons from their parent before focusing new ones (that bug happened). Use Ark Pixel at sizes 20, 30, 40 or 60 only. Every menu blocks its closing press with `Progress.block_input()`; read combat input after that guard.
- **Plugins (vetted 2026-11-27):** Dialogue Manager 4.2+ (MIT, from its GitHub release) for NPC talk (M4), one `.dialogue` file per person in `dialogue/`, lines word for word as in STORY.md. GLoot 3.x (MIT), **data classes only**, for inventory (M3), with our own controller UI. Loot rolling is our own code (`systems/loot/loot.gd`). Keep each add-on's LICENSE file, and add a row to `assets/CREDITS.md`. Both are untested on Godot 4.7.2.

## Balance passes
1. Write the target first, as a number: "a same-level Wickling dies to 2 Lampfire hits", "a shelled elite takes 3-5 s", "a mixed pack 8-12 s", "level 2 at the crook", "a guardian takes 2-4 minutes" (the plan's targets are in DESIGN §4.6 and §9.2).
2. Measure it with a headless test or the benchmark, not by feel. Compute time-to-kill from the dps, hp and shell in `tuning.gd`, and wick per region from the packs, nests and guardian.
3. Change `tuning.gd` only, and record the old and new values and why in DESIGN (the measured numbers section, §19).
4. Check that the owner's latest playtest notes in `docs/PLAYTEST.md` are answered.

## Every change
- Add or extend a test in `tools/tests/`. Tests set process_mode ALWAYS, strip joypad events, set `Story.skip_opening`, and use a test save path, never `user://save_*.json`.
- Run `tools/run_tests.sh` (it fails on any SCRIPT ERROR) and `python3 tools/check_docs.py`. Look at a capture frame (`tools/capture/capture.gd`) for anything visible.
- New player-facing text (skills, items, toasts, people's lines) goes into STORY.md as DRAFT in the same change (`.agents/skills/lantern-keeper-docs/SKILL.md`).
- Run silently (`--audio-driver Dummy`). Never write under /tmp.
- Work in your own git worktree. The owner plays from `wt-hollow` and `~/Projects/lantern-keeper`.
