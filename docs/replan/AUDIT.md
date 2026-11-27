# Lantern Keeper: current-state audit (for the re-plan)

**DRAFT, 2026-11-27.** Source material for the whole-game re-plan the owner asked for ("I think we need to re-plan this entire game and rethink all of the docs", `docs/DECISIONS.md:7`). This file decides nothing. It records what exists, what the docs say, and where they disagree.

**What was read.** Branch `proto/kl-replan` at `c7b457f`. Every file in `docs/`, `README.md`, `AGENTS.md`, `CLAUDE.md`, both `.agents/skills/*/SKILL.md`, `assets/CREDITS.md`, `LICENSE-ASSETS.md`, all of `systems/`, the scripts under `scripts/` (most in full, the rest by header and key functions), `scenes/main/main.tscn`, `project.godot`, `tools/setup_input.gd` and the headers of every test in `tools/tests/`.

**What was not done.** Godot was not run, and the test suite was not run: an import would write a cache into the worktree, and this task may write only this file. So "working" below means: built, used in normal play, covered by a test scene, and not contradicted by a playtest note. It is not a fresh test result. `python3 tools/check_docs.py` was run (it only reads): 0 failures, 1 warning (README older than the newest tests).

**Rules used.** Code wins over docs. Paths are from the repo root. `file:line` points at the line as of `c7b457f`. "The owner" is the human who owns the game. Oswin is "he", Ebba is "she", the keeper is "they".

---

## 0. Branch context (read this first)

- This worktree is the tip of `proto/kl-hollow` (both at `c7b457f`). It is 31 commits ahead of `main` (`55d8bdb`). The merge base is `eab9759`, the font change, from before any Keeper's Light code.
- So `main` still has the old tending game: the ward, Wicklings from the fog, three open regions, WayLamps. Everything ARPG (the combat kit, packs, nests, the Clinker, the Ashbrood, levels, cards) exists only on the prototype branches.
- `main` has three doc-only commits this branch lacks (`7db3f45`, `6824f27`, `55d8bdb`). They mirror doc commits here with small wording differences. Not compared line by line.
- `proto/kl-loop` (the loop route and WayLamp fast travel) points at `f126af7`, an ancestor of this branch. It has **no commits of its own yet**. Its worktree's uncommitted state was not read.
- **In normal play only the Hollow is reachable.** `scripts/main/main.gd:160-166` walls off the marsh passage (x 94-95, y 128-147) and the climb (y 84-85, x 32-65) unless `Story.skip_opening` is set (tests and captures). The Reedmarsh and the Ridge are in the code and the tests, but a player can't walk there.
- The prototype saves to its own files (`user://keepers_light_slot_*`, `scripts/main/main.gd:49`), so it never touches a `main` save.

---

## 1. What is built

Status key: **working** = built, in normal play, tested. **prototype** = built on this branch, placeholder numbers, not passed by a playtest gate. **stub** = in the code but unused, partial, or reached only by tests. **not built** = no code.

### 1.1 System by system

| System | Files | Status | One line |
|---|---|---|---|
| **Combat kit: beam** | `scripts/player/combat.gd`; input `tools/setup_input.gd:43`; tuning `kl_beam_*` | prototype | Hold left click / RT, aimed. 240 x 24 px, 6 hp/s, 0.3 charge/s, walk at 70%. Only the beam (yours or a mirror's) wears a shell (`scripts/enemies/foe.gd:145-185`). Owner: "feels good" (`docs/PLAYTEST.md`, results 2026-11-27). |
| **Combat kit: burst** | `scripts/player/combat.gd` `burst()`; input `flare`, `tools/setup_input.gd:42` | prototype | Tap F / RB. 120 px, 2 dmg, knock 140 px, 3 s cooldown, 0.2 charge. Shells turn it aside. |
| **Combat kit: dash** | `scripts/player/combat.gd` `dash()`; input `tools/setup_input.gd:44` | prototype | Tap Shift / LT. 110 px in 0.16 s, 0.9 s cooldown, 0.08 charge. No chill mid-dash (`scripts/player/player.gd` `chill()`). |
| Cooldown display | `scripts/player/combat.gd` `_draw()` | prototype | Two small arcs under the keeper (burst gold, dash blue). **No action bar.** |
| **Ward (hold F)** | `scripts/player/player.gd:161-180`; tuning `ward_*` | **stub** | `update_ward()` is never called from `_physics_process` (`player.gd:85` calls only `combat.tick`). Only tests (`tools/tests/test_ridge.gd:159`, `test_threats`) and captures (`tools/capture/capture.gd:152,206`) use it. |
| Lamp charge (stamina) | `scripts/player/player.gd:58-70` | prototype | 0 to 1. Also the hand lamp's radius (104 px to a 44 px ember). Refills 0.5/s in lantern or WayLamp light, not while beaming. Under 0.25 charge, 4 s after the last action, it **burns 1 carried fuel** for 0.5 charge (`player.gd:69`). |
| Warmth and fainting | `scripts/player/player.gd` `chill()`, `faint()` | prototype | Warmth 100, +20/s in lantern light only. At 0: drop half carried fuel and scrap as piles, drop **all** unspent wick as a `WickDrop`, **reset every cleared pack** (`player.gd:211-213`), wake by the nearest lit lantern at 60%. No death. |
| **Foes: shared base** | `scripts/enemies/foe.gd` | prototype | hp, shell, shell regrowth, knock, stun, hit flash, kill freeze, level, wick on death, ember drops. Elites, the Clinker and the Ashbrood ignore lanterns (`foe.gd`, `tick_foe`). |
| Wickling | `scripts/enemies/wickling.gd` | prototype | 3 hp, 65 px/s. About half are timid (`kl_timid_share`); brave ones burn after 2.5 s in light. Drains only a **dying** lantern no healthy light covers; smothers mirrors in the dark; saps a kindling WayLamp; chills the keeper on touch. |
| Shelled Wickling (elite) | `wickling.gd` (`elite`), `foe.gd` | prototype | 9 hp + 4 shell, 48 px/s, 1.6x chill. Only in packs now (the fog trickle that made "every 4th" an elite is off). |
| Spitwick | `scripts/enemies/spitwick.gd`, `spit_projectile.gd` | prototype | 4 hp, keeps 190-250 px off, slow spit with a 0.6 s tell: 12 warmth and 0.1 charge. The first ranged foe. |
| Nest | `scripts/enemies/wick_nest.gd` | prototype | 12 hp. Only a built lantern's core hurts it (2 hp/s). Hatches 3 Wicklings every 10 s within 320 px. The Post Lamp's first "lock". |
| Clinker | `scripts/enemies/clinker.gd`; `main.gd:422` | prototype | 24 hp + 12 shell that regrows. Rolls with a 0.8 s tell (25 warmth). Sleeps at its post (wake 224 px, leash 480 px). Since Option B, a **mid-boss near the Hollow WayLamp**, Lv 4. |
| Ashbrood (guardian) | `scripts/enemies/ashbrood.gd`; `scripts/world/waylamp.gd` | prototype | Two phases, 40 hp + 12 shell each. Phase 1: in the bowl, ash puff (lamp down to 0.1), packs of 3 every 8 s. Phase 2: dives at the nearest lit lantern, **sets its fuel to 0** and sits 4 s. Its kill holds the Hollow. **No phase 3.** I found no code that resets its phase when the keeper faints. |
| Fixed packs and lures | `scripts/enemies/enemy_pack.gd`; tables `main.gd:470-500` | prototype | 24 packs + the crook's guard (88 foes: 7 Spitwicks, 6 shelled), 12 nests, all in the Hollow. Sleep until you come close (320 px; route packs 5-6 tiles; guard 4 tiles). Packs pulse through fog; nests glow; the crook has a red pulse (`scripts/world/post_lure.gd`). Caches and upgrade finds have **no** lure. |
| Ambient spawns (old trickle) | `systems/threat/wickling_spawner.gd:23` | stub | Off (`kl_ambient_spawns = false`). The node still spawns the bold swarm for a WayLamp **without** a guardian (marsh, Ridge). |
| Drops | `scripts/enemies/ember.gd`; `foe.gd` `_drop()` | prototype | Every kill: an ember worth **1 fuel**, and a 35% chance of 1 scrap. Magnet pull from 140 px. No item drops. |
| **Lanterns** (4 kinds) | `scripts/lanterns/lantern.gd`; build `player.gd` `try_place()` | working | Post Lamp, Reservoir Lamp, Hooded Lamp, Mirror Post. Tanks burn, light shrinks with fuel, cold lanterns keep their frame. Build anywhere you can stand (no "too dark" rule), not on marsh, rock or a resource, 1.5 tiles apart, not within 160 px of a WayLamp. Pick up for half cost. |
| Post Lamp as the Hollow's find | `systems/progress.gd` (`unlocks = {"post": false}`); `main.gd:430` | prototype | Locked at the start. Reading `crook_post` unlocks it. |
| Lantern tending (refuel, relight) | `player.gd` `refuel()`; `lantern.gd` | working | Tap E / A pours carried fuel (1 unit = 10 lantern fuel). **The owner no longer wants this** (DECISIONS 2026-11-27). |
| Reservoir feeding | `lantern.gd` `_feed()` | working | Feeds 0.75 fuel/s to each other fuel lantern in its light, lit or cold. Exists only to cut upkeep. |
| Dying lanterns | `lantern.gd` `is_dying()`; `tuning.gd` `dying_frac` | working | Under 25% of the tank, not held: red bar, sputter, can be drained. |
| Cold/low lantern tracking | `scripts/ui/lantern_markers.gd`; HUD chips `scripts/ui/hud.gd` | working | Frames and pulses above fog, edge arrows, HUD counts, map colours. Built for upkeep. |
| **Fuel as a resource** | `scripts/resources/resource_node.gd`; `main.gd` `_scatter()` | working | Hollow: 72 resin spots, the hut woodpile (regrows every 10 s, even in the dark), 1 fuel cache. Reedmarsh: 96 peat, 1 fuel cache. Ridge: 32 fuel spots. Plus embers from every kill. Spots regrow while lit. **Fuel as flasks: not built.** |
| Scrap and glass | same | working | Scrap: 64 Hollow, 24 marsh, 28 Ridge spots, caches, the hut pile. Glass: 56 Ridge spots, 2 glass caches. Carry 30 each before satchels. |
| **WayLamps** | `scripts/world/waylamp.gd`; placed `main.gd:270-274` | working (Hollow guardian: prototype) | Three: Hollow (tile 64,90), Reedmarsh (200,140, on the pumphouse island), Ridge (110,30). Feed 15 carried fuel; `feed()` (`waylamp.gd:73`) does not check reach, as decided. Hollow: the Ashbrood fight (`main.gd:279`). Others: a 15 s hold against a bold swarm. Held region: lanterns full and never burn, foes fade, no spawns; +10 wick. |
| WayLamp fast travel | none | not built | Decided; being built on `proto/kl-loop`, which has no commits yet. |
| **Leveling (wick)** | `systems/progress.gd` `wick_for_level`, `add_wick*`; HUD row `hud.gd:92-110` | prototype | Wick to the next level = round(6 x L^1.25): 6, 14, 24, 34, 45... Cap 12. "Lv 3", a bar and "12/24" on the HUD. Chime on level-up. |
| **Level-gap XP** | `progress.gd` `wick_gap_mult`, `kill_wick`; `tuning.gd` `kl_xp_*` | prototype | Full wick up to 1 level over the foe, then x0.25 a level, 0 at 5+. +25% base per foe level. Foes above you pay up to +30%. Fractions carry over. Names dim and popups turn grey when cut. Checked by `tools/tests/test_leveling.gd`, not by a playtest. |
| Foe levels | `main.gd:470-500`; `tuning.gd` | prototype | Lv 1 at the hut row and south, 2-4 mid, 5-6 by the WayLamp. Clinker 4, Ashbrood 7, its adds 5, guard 2. |
| **Upgrade cards** | `scripts/ui/level_up.gd:4-18` | prototype | 12 cards, pick 1 of 3, pauses the world, pad-navigable. All 12 are wired to real numbers (each `has_combat_upgrade` id is used in `foe.gd`, `combat.gd`, `player.gd` or `wickling.gd`). All 12 are about the beam, burst, dash, lanterns or touch. |
| Found upgrades (satchel, lamp glass) | `main.gd` `_place_upgrades()`; `progress.gd` | working | 3 satchels (+10 carry each), 3 lamp glasses (+12 px reach, x0.75 dimming, x0.85 ward cost). The ward part does nothing now. The note still says "wards for longer" (`scripts/world/landmark.gd:54`). |
| **Loot, items, inventory** | none (no `addons/` folder, no rarity code) | not built | Decided Diablo-style; GLoot and Dialogue Manager vetted (`.agents/skills/lantern-keeper-arpg/SKILL.md`), not installed. |
| **Fog and light** | `systems/fog/fog_grid.gd`; `systems/light/light_sense.gd`, `light_tex.gd` | working | 224 x 200 tiles of 32 px, density, creep-back, memory. Sparse fog step. The beam and mirror beams light the fog. Building does not check fog (`fog_grid.gd:117`). No fog shader, occluders or mist particles. |
| Wind | `systems/wind/wind.gd`, `wind_streaks.gd`; `lantern.gd` | working | Valley-wide gusts; constant west wind on the Ridge. Effect: exposed fuel lanterns burn faster and shrink. With no tending, this effect has no job. |
| **Map and regions** | `scripts/main/main.gd` (generation), `scripts/main/map_chunk.gd`, `scripts/ui/map_screen.gd` | working (Hollow); stub (marsh, Ridge in normal play) | Fixed seed 11. Three regions (`fog_grid.gd:19`). The NE quarter is rock, kept for the Lakeshore and the Still Lake. Region names fade in on first sight. |
| Loop route, one-way Ridge | none | not built | Decided, in progress on `proto/kl-loop`. |
| **Save slots** | `systems/save/save_game.gd` (`VERSION := 4`, line 9); `scripts/ui/slot_menu.gd`; `scenes/menu/slots.tscn` (the main scene) | working | Three slots, slot screen at start, autosave every 60 s, on close and from pause. Saves wick, level, cards, cleared foes and wick drops. Not saved: foes, embers, wind. Header comment still says "one save slot" and `user://save.json`. |
| **HUD and UI** | `scripts/ui/hud.gd`, `world_prompt.gd`, `build_menu.gd`, `journal.gd`, `map_screen.gd`, `pause_menu.gd`, `note_reader.gd`, `opening.gd`, `goal_pointer.gd`, `foe_bars.gd`, `boss_bar.gd`, `level_up.gd`, `debug_panel.gd`, `ui_style.gd`; `assets/ui/theme.tres` | working | One panel style. Resource panel, lamp, warmth and level rows; goal banner; status chips; prompts over things; lantern cards (Tab / Y, keys 1-4); 3-page journal; map; pause menu; F1 tuning. No action bar, no inventory or equipment screen, no talk panel. |
| Names, health and boss bars | `scripts/ui/foe_bars.gd`, `boss_bar.gd` | prototype | "Wickling Lv 2"; shell as a pale bar; Ashbrood boss bar with phase and a one-line hint (`boss_bar.gd:32-35`). |
| **Audio** | `systems/audio/sfx.gd`, `ambience.gd`; `assets/audio/sfx/` | stub (placeholder) | 30 Kenney CC0 effects. Ambience is synthesized live. No music, no recorded ambience. The owner does sound and music (DECISIONS, combat kit playtest). |
| **Input hints** | `systems/input/input_hint.gd`; `systems/story/story.gd` `tip_text()` | working | Button names follow the last device. `[beam]`, `[burst]`, `[dash]`, `[build]`, `[aim]` tokens in tips. Pause menu lists the controls. |
| **Story and goals** | `systems/story/story.gd`; landmark texts in `main.gd` | working (Hollow); stub (later goals) | Title card, name prompt, letter, **23 goals** (`story.gd:12-36`), **11 journal entries** (1-8, 13-15), **21 tips**, pointer (auto: on until the Reedmarsh). |
| Landmarks | `scripts/world/landmark.gd`; `main.gd:233-265, 426-430` | working | 12 readable notes + the rack (scenery). 4 unlock a lantern. 6 upgrade finds. 3 WayLamp notes. |
| NPCs and dialogue | none | not built | Five people planned (`docs/PLAN_NPCS_ENEMIES.md`). |
| Performance | `tools/bench/bench.tscn`; `light_sense.gd`; `map_chunk.gd` | working | Budget: logic under 4 ms a frame with 30 lanterns and 20 foes (DECISIONS). |
| Tests and tools | `tools/tests/` (12 scenes), `tools/run_tests.sh`, `tools/check_docs.py`, `tools/capture/`, `tools/art/` | working (not run here) | Tests cover core, combat, threats (ward), save, slots, Ridge, story, WayLamps, upgrades, leveling, the Hollow prototype and the onboarding route. |

### 1.2 Where the docs and the code disagree

Code wins in every row. "Doc" names the claim; "Code" names what is there.

| # | Doc says | Code does |
|---|---|---|
| M1 | DESIGN header: "Synced to commit 9a2b9cc" (`docs/DESIGN.md:3`); STORY header the same (`docs/STORY.md:3`) | The branch is `c7b457f`, 31 commits on. |
| M2 | README: three regions are playable (`README.md:35`) | On this branch only the Hollow is reachable (`main.gd:160-166`). True on `main`. |
| M3 | README: WayLamps are "not part of the game on `main`" (`README.md:39`) | `main` has `scripts/world/waylamp.gd`; DECISIONS says WayLamps were merged. Stale on `main` too. |
| M4 | DESIGN §3.6 and §3.9, README controls and features: hold F / RB / RT to ward (`DESIGN.md:81,114`; `README.md:137`) | No ward in play (`player.gd:85`). F / RB is the burst, left click / RT the beam, Shift / LT the dash. |
| M5 | DESIGN §3.9 and README: left click builds (`DESIGN.md:112`; `README.md:135`) | Left click is the beam. Space / X builds (`tools/setup_input.gd:37,43`). |
| M6 | DESIGN §3.6: "After 25 s, one comes every 12 s (up to 7)" (`DESIGN.md:78`) | The trickle is off (`wickling_spawner.gd:23`). |
| M7 | DESIGN §3.6: Wicklings drain "the nearest lit lantern" (`DESIGN.md:79`) | Only a dying lantern no healthy light covers (`wickling.gd`, the `SEEK_LANTERN` branch; `lantern.gd` `is_dying()`). DESIGN §8 says this; §3.6 does not. |
| M8 | DESIGN §3.2: "building needs 0.6 or less" fog (`DESIGN.md:48`) | No fog check (`fog_grid.gd:117`). DESIGN §3.4 itself says there is no "too dark" rule. |
| M9 | DESIGN §9: "Every 4th Wickling out of the fog is an elite" (`DESIGN.md:251`) | No fog Wicklings; elites are placed in packs. `kl_elite_every` is read only by the idle spawner. |
| M10 | DESIGN §3.8: 18 goals, 8 entries, 13 landmarks (three unlock), 12 tips (`DESIGN.md:97-101`) | 23 goals, 11 entries, 12 readable landmarks + 1 scenery (four unlock), 21 tips. |
| M11 | DESIGN §4: Hollow landmarks include "the letter, the lantern rack" (`DESIGN.md:139`) | The letter note is cut; the rack is scenery (`main.gd:238`). |
| M12 | DESIGN §5 and ROADMAP: "Save/load: one slot" (`DESIGN.md:164`; `ROADMAP.md:140`) | Three slots. |
| M13 | DESIGN §8 title: "PROTOTYPE, owner playtest pending" (`DESIGN.md:201`) | Its own note and DECISIONS say the playtest passed and it was merged. |
| M14 | DESIGN §1 and README: "Light is safety ... nothing chases you", "Planning over reflexes" (`DESIGN.md:18`; `README.md:29`) | Brave Wicklings walk into light; elites, the Clinker and the Ashbrood ignore it. The game is an ARPG. |
| M15 | DESIGN §4 and STORY §9: the finale is "a confrontation of light, not a fight" (`DESIGN.md:147`; `STORY.md:95, 332ff`) | Not built either way, but DECIDED 2026-11-27: a real fight, the Soul retreats through a portal. |
| M16 | `docs/PLAYTEST.md:7`: "fight the Clinker for the Post Lamp" | Since Option B a single shelled Wickling guards the crook; the Clinker is a mid-boss by the WayLamp (`main.gd:435-445`). |
| M17 | PLAYTEST: "The blue glints mark two guarded upgrades" | I found no lure for upgrade finds (`landmark.gd` shows them only when revealed) and no guard object. A pack may sit near them; not measured. **Uncertain.** |
| M18 | ARPG skill and PLAN_KEEPERS_LIGHT §1.4: "the guardian restarts its phase" on a faint | No such code found in `ashbrood.gd`, `waylamp.gd` or `player.gd faint()`. **Uncertain** (searched, not run). |
| M19 | DECISIONS (Hollow prototype playtest): "cleared ground stays cleared" | A faint resets every cleared pack (`player.gd:211-213`), the crook's guard included. DESIGN §9 says so; DECISIONS doesn't. |
| M20 | Lamp glass text: "wards for longer" (`landmark.gd:54`; STORY §6) | The ward can't be used, so that part of the upgrade does nothing (`progress.gd` `ward_drain_per_sec`). |
| M21 | Tips `kindle_attack` "Ward them off until it takes", `waylamp_seen` "then hold it until it takes" (`story.gd:78,80`; STORY §11) | Text matches STORY word for word, but the Hollow WayLamp is a guardian fight and the ward is gone. |
| M22 | Journal 13: "I held the WayLamp until it took" (`story.gd` ENTRIES; `STORY.md:427`) | The Hollow is taken by killing the Ashbrood. |
| M23 | Player-facing text missing from STORY.md | "Trim the wick" / "Choose one." and the 12 card texts (`level_up.gd`), "The Ashbrood leaves the bowl." (`ashbrood.gd` `_die`), the faint note (`player.gd faint()`), the boss-bar hints (`boss_bar.gd:32-35`). The checker does not cover these. |
| M24 | Code comments | `waylamp.gd:4-7` says "reach it with your own light" and "drive them off with your ward"; `save_game.gd` header says one slot; `wind.gd` header says 8 s gusts (tuning: 10 s). |
| M25 | AGENTS.md: `source/` holds "REAPER projects" (`AGENTS.md:24`) | `source/audio/` has only `.gitkeep`. |
| M26 | ROADMAP: "the *Done when* list in `DESIGN.md` §7" (`ROADMAP.md:157`) | It is in DESIGN §5. |
| M27 | `assets/art/placeholders/README.md` | Has no rows for `satchel.png` and `lamp_glass.png` (ART_CHECKLIST does). |

---

## 2. Every doc

"Current" means how well it matches this branch. Recommendations: **keep** (minor fixes), **rewrite** (same job, new content), **merge** (fold into another doc), **retire** (move to an archive once harvested).

| Doc | Purpose | How current | Stale or contradicted by the new direction | Recommend |
|---|---|---|---|---|
| `docs/DECISIONS.md` (173 lines) | Owner decisions, newest first. Wins over other docs. | Current to `c7b457f`; the new direction is at the top. | Nothing stale as a log, but many old entries are now superseded (§3 below). Entries carry no KEEP/superseded flag, so readers must work it out. | **Keep** (append-only). Add a short "standing decisions" index at the top after the re-plan, built from §3. |
| `docs/DESIGN.md` (380) | The game as built, numbers, regions, controls, scope. | Poor. §1-§5 describe the tending game at `9a2b9cc`; the real state is in the §8-§9 prototype notes. | Pillars (light is safety, planning over reflexes), the core loop (gather, build, refuel, tend), the ward, the fog trickle, wind as an upkeep threat, the four lanterns as upkeep tools, the quiet finale, the scope box (one slot, "Wickling variety planned", people in M5c-M5d), target playtime 1-2 h. §9's measured leveling tables stay useful. | **Rewrite** as the ARPG design doc. Keep §3.2 (fog), §3.11 (performance), §4's region facts, §7 (art) and §9's measured numbers. |
| `docs/STORY.md` (449) | Every player-facing text; DECIDED / DEFAULT / DRAFT marks. The checker enforces it against the code. | Good for text that exists; header counts stale. | Oswin as "they" (`STORY.md:14, 93`); tip and entry text written for the ward and the 15 s hold (M21, M22); entry 15 "only the lake is left" (the Lakeshore comes first); the finale as "not a battle"; goals 19-24 and the beat sheet follow the old route (marsh, then back to the climb); no text yet for the loop, fast travel, flasks, skills, loot or the cards. | **Keep and refresh.** It is the checked source of truth for text. Fix pronouns and counts now; rewrite §4, §5, §9 from the new plan; add the missing strings (M23). |
| `docs/ROADMAP.md` (211) | Milestones and status. | Stale (status dated 2026-11-26). | Lists WayLamps as awaiting playtest, M5b as awaiting playtest, M5c-M5e people and creatures under the old rules, "one slot" save; no Keeper's Light milestones (those are only in PLAN_KEEPERS_LIGHT §9). The M0-M4 sections are history. | **Rewrite** from the new plan. Move M0-M4 to a short history note. |
| `docs/PLAYTEST.md` (216) | The current playtest: how to run, what to try, questions, results. | Partly current: the top section is the Hollow prototype. | Intro still has the Clinker on the post (M16) and guarded glints (M17). The 2026-11-27 fuel-and-abilities playtest that set the new direction has **no results section** here (only in DECISIONS). Extra question sets (bigger regions, leveling, level gap, first 10 minutes) have no answers recorded. Old WayLamp, Wickling, M3, M2, M1 sections are history. | **Keep**; add the fuel-and-abilities results; move pre-ARPG sections to an archive. |
| `docs/ART_CHECKLIST.md` (147) | The owner's drawing list, with paths, sizes, status. | Partly current. | WayLamp rows still say PROTOTYPE; no rows for the Spitwick, shelled Wickling, Clinker, nest, Ashbrood, guard, crook landmark, post lure or wick drop; no rows for skill, flask, action-bar or loot icons, or for people; the boat is still a Lake item (PLAN_LAKESHORE moves it). | **Keep** (it is the owner's working list). Update rows after the re-plan. |
| `docs/PLAN_KEEPERS_LIGHT.md` (678) | The ARPG design draft with 23 OWNER lines. | Half built, half superseded. | Built and then changed: Clinker on the find, 6 packs, flat 15/25/35 wick, 8 cards, "fixed packs and a trickle". Contradicted now: the beam as the core weapon, lamp charge refilled by carried fuel, lanterns as fight jobs that need fuel, the burst as the second "weapon slot" (burners). Still useful: enemy families, guardians (Sump, Galekite, Tallest), the Soul's three phases, lenses and coats as loot ideas, people as services. | **Retire** after harvesting its enemy, guardian, finale and gear sections into the new plan. |
| `docs/PLAN_ONBOARDING.md` (256) | The first 10 minutes: diagnosis, options, owner answers. | Built (Option B, `87a065e`). | The start (woodpile, relight two cold lamps) relies on carried fuel and relighting; tips teach the beam first. Answer 4 ("one nest: decide after playing") is still open. | **Retire** to an archive; its route table already lives in DESIGN §9. Carry the open items (§4 below) into the new plan. |
| `docs/PLAN_LAKESHORE.md` (518) | Draft of the Lakeshore region. | Stale. | Coordinates are on the old 112 x 100 map ("x 66-82, y 9-37"; "the map stays 112 x 100"). The beam-only landing is REOPENED by the plan itself. Built around the ward, mirror chains and refuelling. Pre-dates the loop. | **Merge** into the new plan as a short region brief. Keep: thick fog, worn glass, Ebba, the boat after the finale, the three DRAFT landmark texts. |
| `docs/PLAN_NPCS_ENEMIES.md` (313) | People and four creatures. | Stale in places. | Creature rules assume "light is safe" and upkeep threats (the Gutterkite snuffs lanterns; the Clinker sits on cold frames). The dialogue choice was a home-made talk panel; the owner later chose Dialogue Manager. Milestones M5c-M5e are obsolete. Mentions "version-2 saves". The five people, their lines, errands and the guardrails are still good material. | **Merge** the people part into the new plan; **retire** the creature part after refitting it. |
| `README.md` (211) | Public page; describes `main` only. | Stale on both branches. | Pitch, features, controls and the `ward.png` screenshot describe the tending game; WayLamps called unmerged (M3); Oswin as "they" (`README.md:25`); test list misses the two prototype tests (AGENTS lists them). | **Rewrite** when the new direction reaches `main`. Fix M3 and the pronoun on `main` now if wanted. |
| `AGENTS.md` (87) | Agent and contributor rules, test commands. | Mostly current. | "Scope is locked" (`AGENTS.md:13`) fights the re-plan; "REAPER projects" (M25); capture view list is short. | **Keep**; update the scope rule and layout notes after the re-plan. |
| `CLAUDE.md` (1) | Points to AGENTS.md. | Current. | None. | **Keep.** |
| `.agents/skills/lantern-keeper-docs/SKILL.md` | Which doc owns what; doc rules. | Mostly current. | "Use 'they' for H. and for the keeper" (`SKILL.md:38`): H. is gone, Oswin is "he". The doc table will change with the re-plan (new plan files, archive). | **Keep**; fix the pronoun rule; update the table. |
| `.agents/skills/lantern-keeper-arpg/SKILL.md` | How ARPG systems are built here. | Current for the prototype. | Pillars name the beam as the weapon and four item slots tied to the beam and burst (lens, burner); no flasks, action bar, skills or loot pipeline yet; claims guardian phase reset (M18). | **Rewrite** the pillars from the new plan; keep "how things are built" and the balance-pass method. |
| `assets/CREDITS.md` | Third-party assets and licenses. | Current. | Kenney Pixel and Mini fonts are unused since 2026-11-27 (it says so). GLoot and Dialogue Manager rows will be needed when added. | **Keep.** |

---

## 3. Standing owner decisions

Newest first, from `docs/DECISIONS.md` and the DECIDED lines in the plans and STORY.md. All dates are 2026-11-27 unless marked 11-26. Quotes are short extracts. Marks are judged against the fixed new direction (action RPG; no lamp tending; fuel as lamp-oil flasks; an action bar; flaming-light projectile and AoE skills with the beam optional; Diablo-style loot; NPCs via Dialogue Manager; the loop with a one-way Ridge; WayLamp fast travel; level-gap XP; fixed packs; a calm start).

**KEEP** fits the new direction. **CONFLICTS** clashes with it (the clash is named). **OBSOLETE** is superseded, done, or no longer has a subject.

### 3.1 From DECISIONS.md

| # | Date (heading) | Decision (short quote) | Mark | Note |
|---|---|---|---|---|
| 1 | 11-27 (fuel and abilities) | "Lamp tending is not wanted" | KEEP | Part of the new direction. |
| 2 | 11-27 | "Fuel becomes lamp-oil flasks" | KEEP | New direction. |
| 3 | 11-27 | "An action bar" | KEEP | New direction. |
| 4 | 11-27 | "Skills toward flaming light" | KEEP | New direction. |
| 5 | 11-27 | "The beam stays as an optional skill for now" | KEEP | New direction. |
| 6 | 11-27 | "Re-plan the whole game and rethink all the docs" | KEEP | This audit's purpose. |
| 7 | 11-27 | "Level 8 on the Ashbrood kill, as tuned" | KEEP | Measured in `test_leveling`. |
| 8 | 11-27 (route) | "one clockwise loop with no backtracking ... The Ridge is crossed one way" | KEEP | In progress (`proto/kl-loop`). See §4.5 on the Ridge geometry. |
| 9 | 11-27 (route) | "Lit WayLamps are fast travel" | KEEP | In progress. Ledger and cairn texts to be re-edited as DRAFT. |
| 10 | 11-27 (first 10 minutes) | "Onboarding, Option B ... a small guard ... the Clinker becomes a mid-boss" | KEEP | Built. The calm-start and route rules stand. |
| 11 | 11-27 (first 10 minutes) | "A second cold old lantern ... (to cut if it feels cheesy)" | CONFLICTS | Relighting runs on carried fuel; fuel becomes flasks and tending goes. The haven idea can stay in another form. |
| 12 | 11-27 (first 10 minutes) | "A 6-scrap cache at the crook lets you build at once" | KEEP | Holds if building lanterns stays; depends on the new economy. |
| 13 | 11-27 (first 10 minutes) | "The plan's §6 texts are approved (ledger line, tips, goal lines)" | CONFLICTS | The tips teach the beam first ("Hold [beam] to shine on it"); the beam is now optional. The goal lines start with fuel and relighting. |
| 14 | 11-27 (first 10 minutes) | "The south of the Hollow stays optional content (maybe an NPC side quest later)" | KEEP | Fits NPCs returning. |
| 15 | 11-27 (first 10 minutes) | "level 2 comes at the find" | KEEP | Measured. |
| 16 | 11-27 (wick by level gap) | "Wick scales with the level gap, not 'no wick'" | KEEP | New direction. Built. |
| 17 | 11-27 (wick by level gap) | "The Hollow's last level comes on the Ashbrood kill" | KEEP | Built. |
| 18 | 11-27 (wick by level gap) | "The four new upgrade cards are approved as written: Hot core, Steady hand, Lee, Spill" | CONFLICTS | Steady hand is beam-only; Spill is burst-only; Hot core is lantern cores. Cards are tied to the old kit, and the action-bar skills and loot may replace pick-1-of-3 cards. |
| 19 | 11-27 (loot) | "Loot is Diablo-style: random drops with rarity and rolled stats ... (lens, burner, coat, wick slots)" | KEEP | New direction. The slot names (lens = beam, burner = burst) need a re-check now the beam is optional. |
| 20 | 11-27 (loot) | "NPC talk uses Dialogue Manager; inventory data uses GLoot" | KEEP | New direction. Neither is installed. |
| 21 | 11-27 (loot) | "Leveling needs a balance pass ... after the bigger map" | OBSOLETE | Done (`ab88fe7`). A new pass will be needed after the kit changes. |
| 22 | 11-27 (loot) | "An ARPG skill for our agents" | KEEP | Exists; needs new pillars (§2). |
| 23 | 11-27 (bigger regions) | "Every region 4x bigger ... 224 x 200 tiles" | KEEP | Built. |
| 24 | 11-27 (performance) | "under 4 ms a frame with 30 lanterns and 20 foes" | KEEP | Bench exists. |
| 25 | 11-27 (Hollow playtest) | "Genre: action RPG" | KEEP | |
| 26 | 11-27 (Hollow playtest) | "No endless trickle ... fixed packs, nests and the WayLamp fights ... cleared ground stays cleared" | KEEP | Note M19: a faint resets cleared packs in code. |
| 27 | 11-27 (Hollow playtest) | "about half the Wicklings are timid; brave ones burn ... elites and guardians ignore lanterns. Names, health bars and a boss bar" | KEEP | Built. Lantern parts depend on whether lanterns stay. |
| 28 | 11-27 (combat kit playtest) | "The combat kit mostly feels good ... Still too easy ... Sound effects and music are the owner's job" | KEEP | Owner owns audio. Difficulty is an open thread. |
| 29 | 11-27 (combat kit playtest) | "only the pointer (on the woodpile) until you have fuel; then the cold lamp gets its ring" | CONFLICTS | Built around picking up fuel to relight. |
| 30 | 11-27 (combat kit playtest) | "The Hollow's notes follow the new route (DRAFT text)" | OBSOLETE | The ledger was replaced by the onboarding line; the cairn will be re-edited for the loop. |
| 31 | 11-27 (combat kit playtest) | "No more 'too dark' to build" | KEEP | Built. |
| 32 | 11-27 (combat kit playtest) | "Three save slots" | KEEP | Built. |
| 33 | 11-27 (KL owner answers) | "The Post Lamp becomes the Hollow's find" | KEEP | Built. Its job after "no tending" needs defining. |
| 34 | 11-27 (KL owner answers) | "The finale becomes a real fight ... a portal opens, and the keeper follows it" | KEEP | Not built. |
| 35 | 11-27 (KL owner answers) | "The keeper takes and wears Oswin's coat" | KEEP | Fits a coat loot slot. Not built. |
| 36 | 11-27 (KL owner answers) | "the Reedmarsh's WayLamp to the south-east island; the Mirror Post's unlock to the Lakeshore" | KEEP | Not built (`main.gd:272, 259`). Re-check both against the loop. |
| 37 | 11-27 (KL owner answers) | "Lamp charge stays as built ... carried fuel tops it up between fights" | CONFLICTS | Fuel becomes flasks; the auto top-up (`player.gd:69`) has no fuel to burn. |
| 38 | 11-27 (KL owner answers) | "The tuning panel (F1) shows the combat kit's numbers" | KEEP | Built. |
| 39 | 11-27 (new direction) | "direction B, 'Keeper's Light' ... aimed beam, burst, dash ... levels with pick-1-of-3 upgrades, and gear ... Each region's find is the key" | CONFLICTS (in part) | ARPG, guardians, levels, gear and "the find is the key" KEEP. The beam-burst-dash kit as the core CONFLICTS with flaming-light skills and the optional beam. Pick-1-of-3 is open. "Tides kept for later" stays on the shelf. |
| 40 | 11-27 (new direction) | "WayLamps are merged into main" | KEEP | A fact. |
| 41 | 11-27 (new direction) | "Font: Ark Pixel" | KEEP | |
| 42 | 11-27 (WayLamps playtest) | "WayLamps take fuel directly" | CONFLICTS | "No lantern has to reach them" KEEPs. "Take 15 fuel" clashes with fuel as flasks. What a WayLamp costs needs a new answer. |
| 43 | 11-27 (WayLamps playtest) | "The Hollow's WayLamp moves to the north end, below the climb" | OBSOLETE | The loop moves it north-east toward the marsh passage. |
| 44 | 11-27 (WayLamps playtest) | "Less to read at the start: the note on the hut door is cut ... the rack is scenery" | KEEP | Built. |
| 45 | 11-27 (WayLamps playtest) | "Quiet building: no outline or cost text until you try ... No building on resources" | KEEP | Holds if building stays. |
| 46 | 11-27 (WayLamps playtest) | "Lantern beside a resource: a tap refuels the lantern; holding gathers" | OBSOLETE | No refuelling under "no tending". |
| 47 | 11-27 (WayLamps playtest) | "Combat stopgap: the ward costs 0.45 charge per second" | OBSOLETE | The ward is gone. |
| 48 | 11-27 (WayLamps playtest) | "The game feels boring; rethink the core loop" | OBSOLETE | Answered by the ARPG direction. |
| 49 | 11-27 (afternoon) | "Oswin signs '- Oswin' ... His surname stays out of the game" | KEEP | |
| 50 | 11-27 (afternoon) | Lakeshore: "thick fog (lanterns only thin it; beams and WayLamps cut it)" | KEEP | Needs a refit: which "beams" (mirrors, the optional beam skill, light-fire skills). |
| 51 | 11-27 (afternoon) | Lakeshore: "its WayLamp on the old landing, reached only by a beam" | CONFLICTS | With #42's "no lantern has to reach them" (PLAN_LAKESHORE marks it REOPENED) and with the beam being optional. |
| 52 | 11-27 (afternoon) | "a few spots of worn glass on the shore" | KEEP | If glass stays a resource. |
| 53 | 11-27 (afternoon) | "Ebba is 'she'" | KEEP | |
| 54 | 11-27 (afternoon) | "her boat crosses to the Lake only after the finale" | KEEP | |
| 55 | 11-27 (later) | "Oswin signs '- O.'" | OBSOLETE | Replaced by "- Oswin" (#49). |
| 56 | 11-27 (later) | "People are drawn at the keeper's 32x32 scale, without portraits" | KEEP | Check against Dialogue Manager's balloon look. |
| 57 | 11-27 (later) | "A new region, the Lakeshore ... The Fogstilt and Ebba move there; the Ridge keeps the Gutterkite" | KEEP | Region and homes KEEP. |
| 58 | 11-27 (later) | "the Clinker roams whatever isn't held" | CONFLICTS | The built Clinker is a fixed mid-boss; roaming clashes with fixed packs. |
| 59 | 11-27 (owner answers) | "People and creatures are IN for v1 ... All of them come before the Still Lake" | KEEP | The milestone split (M5c-M5e) is OBSOLETE. |
| 60 | 11-27 (owner answers) | "WayLamp story text approved (STORY §11)" | CONFLICTS (in part) | Notes say "Feed it 15 fuel" and "Keep them off it"; entry 13 says "I held the WayLamp"; entry 15 says "only the lake is left". Inscriptions and Oswin's lines can KEEP. |
| 61 | 11-27 (owner answers) | "The last keeper is Oswin Reed, a man ('he')" | KEEP | |
| 62 | 11-27 (owner answers) | "The sign-off uses a plain hyphen" | KEEP | |
| 63 | 11-27 (owner answers) | "First Wickling after 25 s" | OBSOLETE | No fog trickle. |
| 64 | 11-27 (owner answers) | "Fainting keeps glass safe (it drops half your fuel and scrap only)" | KEEP | Re-check once fuel is flasks. |
| 65 | 11-27 (owner answers) | "Upgrades built: a keeper's satchel ... and a lamp glass ... in each region" | CONFLICTS (in part) | The ward part of the lamp glass is dead; satchels matter less with flasks; both may become loot. |
| 66 | 11-27 (owner answers) | "The Soul of the Wick has big pale eyes" | KEEP | |
| 67 | 11-26 (upkeep) | "WayLamps ... Once lit, it holds its region: lanterns there are refilled and stop burning down, and no Wicklings come" | KEEP (core) | "Held region is safe" KEEPs. "Refilled, stop burning" has no subject once tending goes. |
| 68 | 11-26 (upkeep) | "Light repels Wicklings ... They can only drain a dying lantern" | CONFLICTS | No tending means no dying lanterns to drain. |
| 69 | 11-26 (upkeep) | "People and more creatures are wanted ... STORY's 'no dialogue' rule stands" until approved | OBSOLETE | People were approved (#59). |
| 70 | 11-26 (upkeep) | "Docs follow the code" | KEEP | |
| 71 | 11-26 (upkeep) | "Fix: hand refuelling now fills a Reservoir Lamp's whole tank" | OBSOLETE | No refuelling. |
| 72 | 11-26 (HUD follow-ups) | "Mirror beams burn Wicklings fast ... Wicklings can't sense beams" | KEEP | If mirrors stay. |
| 73 | 11-26 (HUD follow-ups) | "Wicklings smother mirrors (no mirror health)" | KEEP | If mirrors stay. |
| 74 | 11-26 (HUD follow-ups) | "Wind pop-ups removed. A chip appears only while wind actually reaches your lit, unsheltered fuel lanterns" | OBSOLETE | Wind's only effect is on lantern fuel. |
| 75 | 11-26 (HUD follow-ups) | "Mirrors turn both ways" | KEEP | If mirrors stay. |
| 76 | 11-26 (HUD follow-ups) | "Tap Y/Tab to switch lanterns ... keys 1-4 pick directly" | CONFLICTS | An action bar will want 1-4 and face buttons. |
| 77 | 11-26 (HUD follow-ups) | "Journal restyled" | KEEP | |
| 78 | 11-26 (HUD redesign) | "Notes, the lantern list, the map, the journal and the pause menu all pause the world" | KEEP | |
| 79 | 11-26 (HUD redesign) | "New HUD: top-left panel (fuel/scrap/glass ...), goal banner, status chips ... prompts drawn over the thing" | CONFLICTS (in part) | Style, banner and prompts KEEP. The fuel count and the cold/low-lantern chips clash with flasks, the action bar and no tending. |
| 80 | 11-26 (story markup) | "the new keeper answers a letter from the last keeper" | KEEP | (Name since changed to Oswin.) |
| 81 | 11-26 (story markup) | "The player types a name" | KEEP | |
| 82 | 11-26 (story markup) | "The Soul of the Wick is 'it'" | KEEP | ("No face" was dropped later, #66.) |
| 83 | 11-26 (story markup) | "The goal pointer turns off on reaching the Reedmarsh" | KEEP | Re-check against the loop and fast travel. |
| 84 | 11-26 (story markup) | "The player builds every mirror" | KEEP | If mirrors stay. |
| 85 | 11-26 (story markup) | "Keep the great lamp plate" | KEEP | |
| 86 | 11-26 (story markup) | "The finale has some pressure: the coil drains the lanterns feeding the mirrors" | OBSOLETE | Superseded by the finale as a fight (#34); draining lanterns clashes with no tending. |
| 87 | 11-26 (guidance) | "a guidance-and-story milestone comes before the Still Lake" | OBSOLETE | Done (M5a). |
| 88 | 11-26 (guidance) | "a goal line + keeper's journal plus a soft pointer ... on in the first region" | KEEP | |
| 89 | 11-26 (guidance) | "coordinator drafts STORY.md ... owner marks it up" | KEEP | |
| 90 | 11-26 (Post Lamp look) | "The Post Lamp is a shepherd's crook" | KEEP | The owner's art. |
| 91 | 11-26 (M5 Ridge) | "The map grows north (112x100 tiles) ... reached by a narrow climb" | OBSOLETE | The map is 224 x 200; the loop makes the climb a later shortcut. |
| 92 | 11-26 (M5 Ridge) | "Constant west wind on the Ridge: exposed fuel lanterns burn 1.6x" | CONFLICTS | The wind's effect is on lantern fuel. The Ridge needs a new twist job. |
| 93 | 11-26 (M5 Ridge) | "Glass: third resource, only on the Ridge (14 spots)" | OBSOLETE | Now 56 spots, and worn glass on the Lakeshore is approved. Whether glass stays is open. |
| 94 | 11-26 (M5 Ridge) | "Hooded Lamp ... wind never touches it" | CONFLICTS | Its job is wind-proof fuel. |
| 95 | 11-26 (M5 Ridge) | "Mirror Post ... Throws an 11-tile beam ... This is the tool for the Still Lake" | KEEP (open) | Built. Its role with light-fire skills is open. |
| 96 | 11-26 (M5 Ridge) | "Two story landmarks on the Ridge hint at the Soul" | KEEP | |
| 97 | 11-26 (ward playtest) | "the ward on lamp charge works; push-and-pull is fun" | OBSOLETE | Ward replaced. |
| 98 | 11-26 (ward playtest) | "Embers ... drawn on the fog layer ... a magnet pull ... '+1 fuel'" | CONFLICTS | Embers are fuel pickups. The glow and magnet code can serve loot drops. |
| 99 | 11-26 (ward playtest) | "Burned Wicklings now have a 35% chance to also drop 1 scrap" | CONFLICTS | Diablo-style loot tables will replace fixed drops. |
| 100 | 11-26 (beam to ward) | "The beam is replaced by a warding glow ... Burned Wicklings drop an ember worth 1 fuel" | OBSOLETE | |
| 101 | 11-26 (combat playtest) | "Wicklings are IN v1 ... no death, no game over; warmth is the health; fainting wakes you at the nearest lit lantern" | KEEP | |
| 102 | 11-26 (combat playtest) | "The flare is replaced by a lamp beam ... 1 carried fuel per 1.5 s" | OBSOLETE | |
| 103 | 11-26 (combat playtest) | "More pressure: first Wickling after 25 s ... every 12 s, up to 7" | OBSOLETE | |
| 104 | 11-26 (combat playtest) | "The mouse cursor hides while playing with keys or a controller" | KEEP | |
| 105 | 11-26 (finale) | "The finale is a confrontation of light, not a fight ... He answers 'who took the light'" | OBSOLETE (in part) | The fight replaced it (#34). "Who, not why" KEEPs. |
| 106 | 11-26 (art style) | "Moody pixel art ... 16x16 tiles drawn at 2x ... limited palette" | KEEP | |
| 107 | 11-26 (after M3) | "Cold lanterns stay findable ... Lanterns below 25% fuel get an amber pulse" | CONFLICTS | Upkeep tracking. |
| 108 | 11-26 (M3, coordinator) | "Wind gusts are valley-wide from M3" | CONFLICTS | Same as #92. A coordinator choice, not the owner's. |
| 109 | 11-26 (M3, coordinator) | "The Reservoir Lamp also refuels cold lanterns" | OBSOLETE | Coordinator choice. |
| 110 | 11-26 (M3, coordinator) | "Ambience is synthesized live as a placeholder" | KEEP | Until the owner's audio. |
| 111 | 11-26 (M3, coordinator) | "Five landmarks in M3" | OBSOLETE | Now 12. |
| 112 | 11-26 (DESIGN §10) | "Sandbox after the finale: yes" | KEEP | Pairs with the portal hook. |
| 113 | 11-26 (DESIGN §10) | "Hand lamp uses fuel: yes ... it keeps a small ember glow" | CONFLICTS | "Never goes out" KEEPs; "uses fuel" clashes with flasks. |
| 114 | 11-26 (DESIGN §10) | "Mystery: answered in part, left open in part" | KEEP | |
| 115 | 11-26 (DESIGN §10) | "Gamepad support: in v1" | KEEP | |
| 116 | 11-26 (DESIGN §10) | "Project location" (a local folder, its own git repo) | KEEP | A fact. |
| 117 | 11-26 (coordinator notes) | "Wind moves from M5 to M3" | OBSOLETE | Done. |
| 118 | 11-26 (coordinator notes) | "Renderer: Compatibility (OpenGL)" | KEEP | |

### 3.2 DECIDED lines found only in the plans or STORY.md

| # | Source | Decision (short quote) | Mark | Note |
|---|---|---|---|---|
| P1 | `PLAN_KEEPERS_LIGHT.md` OWNER 3 | "(a), as built, for now" (charge model) | CONFLICTS | Same as #37. |
| P2 | `PLAN_ONBOARDING.md` §8, answer 4 | "One nest on the main route: decide after playing" | KEEP (open) | DECISIONS states one nest as built; the plan says it is still to judge. |
| P3 | `PLAN_LAKESHORE.md` OWNER 2 | "A, thick fog" | KEEP | Same as #50. |
| P4 | `PLAN_LAKESHORE.md` OWNER 6 | "try it on the old landing ... REOPENED" | CONFLICTS | The plan reopened it itself. |
| P5 | `PLAN_NPCS_ENEMIES.md` §2 | "keep 'Big pale eyes' in the Soul's ART_CHECKLIST entry" | KEEP | |
| P6 | `PLAN_NPCS_ENEMIES.md` §2 | "all four creatures go in v1 ... the Gutterkite in M5c, the Fogstilt in M5d ... the Slowwater and the Clinker in M5e" | OBSOLETE | Milestones obsolete. The Clinker is already in, as an elite. Creatures KEEP as ideas. |
| P7 | `PLAN_NPCS_ENEMIES.md` §3 | "keep all five people" | KEEP | |
| P8 | `PLAN_NPCS_ENEMIES.md` §6 | "build all of it after the WayLamp playtest ... in three milestones" | OBSOLETE | |
| P9 | `PLAN_NPCS_ENEMIES.md` §7 | "people's rewards add to the upgrades and don't replace them" | CONFLICTS (in part) | Depends on loot replacing the found upgrades. |
| P10 | `STORY.md` §6 `ledger` | "My lamp hangs on my crook, on the north path. Take it back. Then the WayLamp, at the top." | KEEP | Built; the loop will re-edit it as DRAFT. |
| P11 | `STORY.md` §8 `wickling_close` | "Hold [beam] to shine on it. Aim with [aim]." | CONFLICTS | The beam is optional now. |
| P12 | `STORY.md` §5 | "the pointer turns off on reaching the Reedmarsh" | KEEP | |

---

## 4. Open threads

### 4.1 Owner questions still unanswered

- **PLAN_KEEPERS_LIGHT §11:** OWNER 1, 2, 4, 5, 6, 10, 12-15 and 17-23 have no recorded answer. Some were answered by building (Spitwick name, the Ashbrood, the prototype contents). The re-plan replaces most of them.
- **PLAN_KEEPERS_LIGHT "Still open":** a healing item (flasks may answer it); a difficulty setting; whether Wicklings drain lanterns mid-fight; whether a held region can be lost; whether Kit cutting a lens counts as crafting; pronouns for Amos, Maud, Kit and Ivo; Fogstilts on the Lake; spare frames in the keeper sprite for a dash and a cast pose.
- **PLAN_NPCS_ENEMIES §1-§8:** keep people optional; held regions stop every creature; people return when a WayLamp is kindled; Errands and People pages; which readable things count toward 15-25 landmarks; rewards and trade rates; may people say the keeper's typed name; pronouns for four people; how close lines come to the hints; creatures after the finale; one soft hint toward the goal; Fogstilts in the finale; is the great lamp the Lake's WayLamp. The talk-panel question is superseded by Dialogue Manager.
- **PLAN_LAKESHORE §9:** OWNER 1 (the split, the causeway, the name), 3 (thick fog stays when held), 5 (no upgrade finds there), 7 (move the boat), 8 (landmark count), 9 (goals), 10 (`descend`, `ridge_steps`, trimming entry 15; the owner asked what "trim" meant), 11 and 13 (Fogstilt and Ebba details), 12 (Fogstilts on the Lake), 6 (REOPENED).
- **PLAN_ONBOARDING:** answer 3 (cut the second cold lamp if cheesy) and answer 4 (one nest) wait for play. The optional crook banner and the journal line after the crook were not built (STORY §8).
- **STORY DEFAULTs:** the order stays nameless; the letter as drafted; Oswin's fate open; first-person journal; the far light; the ending as drafted; "the coat is Oswin's" (now settled by #35). **DRAFT lines:** the cairn note; the six upgrade-find notes; the `crook_post` note is marked DRAFT in STORY §6, though PLAN_ONBOARDING says the §6 texts were approved. **Uncertain** which is right.

### 4.2 Playtest questions without results

- Hollow prototype extras in `docs/PLAYTEST.md`: bigger regions (3 questions), leveling balance (3), level gap (3), the first 10 minutes (7). No results recorded.
- The fuel-and-abilities playtest that set the new direction is recorded only in DECISIONS, not in PLAYTEST.md.

### 4.3 Known issues and bugs

- **Fuel glut** (owner): "fuel is ABUNDANT, its everywhere". In code: 200 fuel spots across three regions, a regrowing woodpile, fuel caches, and an ember worth 1 fuel from every kill (`foe.gd` `_drop`).
- **Combat too easy** (owner, combat-kit playtest), and lanterns as a repellent "may be too strong" (PLAYTEST result 8). Partly answered by timid and brave Wicklings.
- **A faint undoes every cleared pack** (`player.gd:211-213`), including the crook's guard. This bends "cleared stays cleared".
- **Dead code:** the ward (`player.gd:161-180`, `ward_*` tuning, the lamp glass ward discount); `kl_elite_every`; the fog trickle. Tests still exercise the ward (`test_threats`, `test_ridge`).
- **Stale comments:** `waylamp.gd:4-7`, the `save_game.gd` header, the `wind.gd` header (M24).
- **Lures look alike:** sleeping packs and nests both show as cool pulses above the fog (PLAN_ONBOARDING §9).
- **The Ashbrood** was not rechecked for a keeper arriving at level 2-3 with one lamp (PLAN_ONBOARDING §9).
- **Wickling video note** (11-26): "the editor debugger showed 13 messages (not yet identified)". No later note closes it.
- **M3 polish list** (PLAYTEST): stacked edge arrows, streaks over never-seen black, map zoom, region labels on paths, heavy seen-fog grid. Commit `7fe26eb` mentions "spread arrows" and "zoomed map"; the rest is **not verified**.
- **Tooling:** the first `--import` in a fresh checkout can crash on Godot 4.7.2 and leave the font unimported (`AGENTS.md`).
- **ROADMAP M4 items not done:** occluder shadows, a fog shader, mist particles, separate audio buses (no bus layout file found; **uncertain**), recorded ambience.

### 4.4 Planned but not built

**The new direction (all decided):**
- lamp-oil flasks; an action bar with cooldowns; flaming-light projectile and AoE skills; the beam as an optional skill;
- Diablo-style loot: drops, rarity, rolled stats, compare and swap; GLoot data; an inventory or equipment screen;
- NPCs through Dialogue Manager;
- the loop route, the one-way Ridge, WayLamp fast travel (on `proto/kl-loop`);
- removing lamp tending everywhere it is wired (§5.5).

**Approved moves:**
- the Reedmarsh WayLamp to the south-east island (`main.gd:272` still uses the pumphouse island);
- the Mirror Post unlock to the Lakeshore (`main.gd:259` still unlocks it at the signal station);
- the Hollow WayLamp north-east toward the marsh passage (loop; now at tile 64,90);
- the glazier and the lens near the Ridge's east entry (loop; the glazier now at the west end and the lens mid-Ridge, `main.gd:254, 264`);
- the keeper wears Oswin's coat;
- the finale as a fight, with the portal.

**From PLAN_KEEPERS_LIGHT:** the Ashbrood's phase 3; guardians for the Reedmarsh, Ridge and Lakeshore (Sump, Galekite, Tallest); the Soul in three phases; region families (Slowwater, Fenlight, Gutterkite, Fogstilt); four lenses, four burners, four coats; a Lamp page; leads instead of one goal; pad aim assist; a second burst on right click; the faint rules for guardians.

**Regions and content:** the Lakeshore and the Still Lake (no region ids yet, `fog_grid.gd:19`); 8 Lake landmarks, 3 Lakeshore landmarks, 3 survey stones; goals 19-24 and 5 Lakeshore goals; journal entries 9-12 and 16-18; the ending and after-game.

**People:** Amos, Maud, Kit, Ebba, Ivo; their errands, trade and gifts; journal People and Errands pages; a possible NPC side quest in the south of the Hollow.

**M6:** volume settings, a Linux export, external playtests, music.

### 4.5 Unclear points the re-plan must settle

- **One-way Ridge geometry.** The loop decision has you enter the Ridge's east end from the marsh and leave by "the old steps" after the signal station and the Ridge WayLamp "at the far end". Today the station (`_ridge_spot(116,26)`), the WayLamp (110,30) and the steps (124,34) are all at the east end, and "the far west of the Ridge becomes optional". So it is unclear which end is "far", or whether the steps move. `proto/kl-loop` will settle it.
- **Do lanterns stay buildable?** "Built lanterns should not need refuelling" suggests yes. Then the Post Lamp find, nests ("only a lantern's core burns one") and havens still work, but the Reservoir, the Hooded Lamp and wind lose their reasons.
- **What a WayLamp costs** once fuel is flasks (today: 15 carried fuel).
- **What the hand lamp's charge is** once fuel is flasks and skills are on an action bar (today: stamina and light radius, topped up by fuel).
- **Cards or loot or both.** Pick-1-of-3 cards on level-up (built) versus skills and rolled gear (decided).

---

## 5. Assets and content inventory

### 5.1 Owner-made work (preserve)

| What | Where | Evidence |
|---|---|---|
| Post Lamp, lit and cold (shepherd's crook with a stone base) | `assets/art/placeholders/post_lamp_lit.png`, `post_lamp_cold.png` | Commit `a2167bf` "Owner's Post Lamp art"; ART_CHECKLIST ✅ |
| Their Pixelorama sources | `source/art/post_lamp_lit.pxo`, `post_lamp_cold.pxo` | Same commit |
| Names the owner chose | "WayLamp", "Soul of the Wick", the crook shape | DECISIONS 11-26 (upkeep; finale; Post Lamp look) |
| Story text the owner marked up or approved | STORY.md lines marked DECIDED; the ledger line, the onboarding tips and goal lines, the WayLamp texts | STORY.md, DECISIONS |
| The owner's quotes and rulings | `docs/DECISIONS.md`, PLAYTEST results | — |

The 14-colour palette (`source/palette/lantern-keeper-14.gpl`, `.png`) is the project palette. Who drew it is **not recorded**; treat it as kept. Nothing else in `assets/art/` is recorded as owner-made.

### 5.2 Regions and places (in code)

Map 224 x 200 tiles of 32 px, seed 11. Tile coordinates below.

| Region | Shape | Content | Status |
|---|---|---|---|
| The Hollow (R1) | Ellipse at (48,136), radii 38 x 44 | Hut at the centre; woodpile; scrap pile; hut lantern (cold); north-path lamp (cold, +2,-12); 72 fuel, 64 scrap spots; 4 caches; 24 packs + guard, 12 nests, the Clinker; WayLamp (64,90) with the Ashbrood | Playable |
| The Reedmarsh (R2) | Ellipse at (160,136), radii 56 x 48; soft ground | 7 boardwalks, 10 islands, 96 peat, 24 scrap, 2 caches; WayLamp (200,140) by the pumphouse (206,138) | Walled off in normal play |
| The Windward Ridge (R3) | Ellipse at (68,34), radii 60 x 26 | 88 rock outcrops, 56 glass, 32 fuel, 28 scrap, 2 glass caches; WayLamp (110,30) | Walled off in normal play |
| Marsh passage | x 76-116, y 132-142 | Joins R1 and R2 | Walled at x 94-95 |
| The climb | x 44-54, y 52-100 | Joins R1 and R3 | Walled at y 84-85 |
| North-east quarter | rock | Kept for the Lakeshore and the Still Lake | Not built |

### 5.3 Landmarks and finds (in code)

| id | Title | Region | Effect |
|---|---|---|---|
| `rack` | Lantern rack | Hollow | Scenery only |
| `ledger` | Keepers' ledger | Hollow | Note |
| `crook_post` | A keeper's post | Hollow (-1,-19 from the hut) | Unlocks the Post Lamp |
| `climb_cairn` | A stone cairn | Hollow (48,94) | Note |
| `stone_way` | Carved stone | Hollow, marsh passage | Note |
| `frames_east` | Old lantern frames | Reedmarsh | Note |
| `chalk_lake` | Chalk on the pumphouse wall | Reedmarsh | Note |
| `pumphouse` | The pumphouse | Reedmarsh | Unlocks the Reservoir Lamp |
| `glazier` | The glazier's workshop | Ridge, west | Unlocks the Hooded Lamp |
| `lens` | A broken lens | Ridge | Note |
| `coat` | A keeper's coat | Ridge | Note |
| `station` | The signal station | Ridge, east | Unlocks the Mirror Post |
| `ridge_steps` | Old steps | Ridge, east | Note |
| `waylamp_hollow`, `_marsh`, `_ridge` | WayLamp of ... | one each | Note, then feed |
| `satchel_*` (3), `lampglass_*` (3) | A keeper's satchel / A lamp glass | one of each per region | +10 carry / better hand lamp |

Planned and not built: 8 Lake landmarks (STORY §6), 3 Lakeshore landmarks (PLAN_LAKESHORE §2), 3 survey stones (PLAN_NPCS_ENEMIES §3).

### 5.4 Foes and people

| Built foes | Where | Notes |
|---|---|---|
| Wickling (timid / brave) | Hollow packs; WayLamp swarms | 3 hp |
| Shelled Wickling | Hollow packs; the crook's guard | 9 + 4 shell |
| Spitwick | Hollow packs | ranged |
| Nest | 12 in the Hollow | core-burned only |
| Clinker | 1, near the Hollow WayLamp | mid-boss |
| The Ashbrood | the Hollow WayLamp | guardian, 2 phases |

Planned foes: Slowwater, Fenlight, Gutterkite, Fogstilt; guardians the Sump, the Galekite, the Tallest; the Soul of the Wick (PLAN_KEEPERS_LIGHT §4; PLAN_NPCS_ENEMIES §2).

People: **none built.** Planned: Amos Patch (trader), Maud Fallow (old pump keeper), Kit Brand (glazier's apprentice), Ebba Tarn (rower, "she"), Ivo Withey (mapmaker). Oswin is never seen. Pronouns for Amos, Maud, Kit and Ivo are not chosen.

### 5.5 Where lamp tending is wired (for the removal)

`scripts/lanterns/lantern.gd` (tanks, burn, wind, Reservoir feed, dying, held refill); `scripts/player/player.gd` (`refuel`, the lamp's fuel top-up, faint fuel drop); `scripts/enemies/wickling.gd` (draining dying lanterns); `scripts/enemies/ashbrood.gd` (dive empties a lantern); `scripts/world/waylamp.gd` (15 fuel); `scripts/main/main.gd` (`_on_region_settled` refills lanterns; cold start lanterns; fuel spots); `scripts/ui/lantern_markers.gd`; `scripts/ui/hud.gd` (fuel count, cold/low chips, wind chip); `scripts/ui/world_prompt.gd` ("Refuel 62%"); `systems/story/story.gd` (goals `gather_fuel`, `relight_first`, `relight_waypost`; tips `cold_lantern`, `low_lantern`, `dying_lantern`, `gust`); `systems/wind/wind.gd`; `scripts/enemies/ember.gd`. Tests that check tending: `test_core`, `test_ridge`, `test_waylamps`, `test_threats`.

### 5.6 Story texts in code

- Title card (3 lines), name prompt, letter (`story.gd:54-55`).
- 23 goals (`story.gd:12-36`): `gather_fuel` through `descend`.
- 11 journal entries: 1-8 and 13-15 (`story.gd:39-52`).
- 21 tips (`story.gd:57-80`).
- 12 landmark notes, 3 WayLamp notes, 6 upgrade-find notes (`main.gd`).
- Not in STORY.md: the level-up screen and 12 cards, the Ashbrood toast, the faint note, the boss-bar hints (M23).

### 5.7 Art, audio and other files

| Kind | Files | Source |
|---|---|---|
| Owner art | 2 PNG + 2 `.pxo` | §5.1 |
| Placeholder sprites | 15 more in `assets/art/placeholders/` (Reservoir, Hooded, Mirror, WayLamp pairs; dead tree, peat, scrap pile, glass, reeds, satchel, lamp glass) | Generated by `tools/art/make_placeholders.py`; project-original, all rights reserved |
| UI icons | 8 in `assets/art/ui/` | Generated by `tools/art/make_icons.py` |
| Tiles | `assets/art/kenney/tiny_town.png`, `tiny_dungeon.png` (recoloured); originals in `source/vendor/` | Kenney, CC0 |
| Keeper sprite | `assets/art/puny/keeper.png` (recoloured); original in `source/vendor/puny-characters/` | Puny Characters, CC0 |
| Code-drawn | every foe, embers, scrap drops, lures, the beam, the burst, bars, most landmark details | — |
| Fonts | Ark Pixel 10px (in use); Kenney Pixel and Mini (unused) | OFL 1.1; CC0 |
| Sound effects | 30 `.ogg` in `assets/audio/sfx/` (steps, gathering, lantern, UI, relight, unlock, refuel, notes) | Kenney Impact, Interface, RPG Audio; CC0 |
| Music, recorded ambience | none (`source/audio/` holds only `.gitkeep`) | Ambience is synthesized (`systems/audio/ambience.gd`) |
| Screenshots | 9 in `docs/screenshots/` (`ward.png` shows the removed ward) | `tools/capture/readme_shots.sh` |
| UI theme | `assets/ui/theme.tres` | project |

---

## 6. Uncertainties

1. Statuses come from reading code, not from running it. Tests and Godot were not run.
2. `proto/kl-loop` has no commits; its uncommitted work was not read. The loop and fast travel may be further along than this file shows.
3. The one-way Ridge's direction and where the old steps end up (§4.5).
4. Whether the two upgrade finds are "guarded" (M17) and whether a guardian resets on a faint (M18): searched, not found, not run.
5. Whether `crook_post`'s note is approved or still DRAFT (§4.1).
6. Who made the palette (§5.1).
7. The small wording differences between `main`'s three doc commits and this branch's versions were not compared line by line.
8. Each KEEP / CONFLICTS / OBSOLETE mark is a judgement against the new direction as stated in the brief. The owner may read some differently, especially where an entry is half kept (#39, #42, #60, #65, #67, #79).
