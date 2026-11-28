# Lantern Keeper — Design Document

Synced to M1c ("lamps in the fight") on `proto/kl-m1c` (2026-11-28, based on a98d41a, the play branch with M1b, the sprites and the approved lanterns addendum `docs/replan/PLAN_LANTERNS.md`): what M1c built is marked **BUILT (M1c)** and gathered in §20 (light states, combos, the Ashbrood's rework, lamp slots, the target lock, the damage fix); §3.1, §4.6, §6.1 and §8.1 point to it. Before that, synced to the sprites step on `proto/kl-sprites` (2026-11-27, based on 8436f2e, the play branch with M1b merged, plus `proto/kl-arttools`): the owner-approved sprites are in the game, marked **BUILT (sprites)** (§17). Before that, synced to M1b ("no more tending") on `proto/kl-m1b` (2026-11-27, based on b3f5cd9, the play branch with M1a, its fixes and the readability step merged): what M1b built is marked **BUILT (M1b)** (§1, §2, §4.6, §5, §6, §7, §8.1, §9, §12.3, §14, §15, §16, §19). **Owner scope change during M1b** (DECISIONS 2026-11-27, "M1b: lanterns are being redesigned"): the 3-lamp limit, the full refund and the 15 s replant delay were **not built**, and building and picking up lamps stay as they were. Before that, synced to the readability step on `proto/kl-readability` (2026-11-27, based on cb5b615, the play branch with M1a merged): the telegraph pass, the keeper's own feedback, the placeholder swap hook and the performance pass are marked **BUILT (readability)** (§4.1, §8.4, §16, §17). Before that, synced to commit f97b531 on `proto/kl-m1a` (2026-11-27): the M1a build (commits 6663292 and 10099a8) is folded in and marked **BUILT (M1a)**. The review fixes on `proto/kl-m1a-fix` (2026-11-27) are folded in too. Before that, synced to c6d3ee0 on `proto/kl-replan`. Rewritten from the approved game plan, `docs/replan/GAME_PLAN.md` v2 (DECISIONS 2026-11-27, "the game plan approved"). **DRAFT for owner approval** (GAME_PLAN §17). The version before the rewrite is `docs/archive/DESIGN_PRE_REPLAN.md`.

> **How to read this doc**
> - **Built** means it is in the code at f97b531. **BUILT (M1a)** marks what the M1a build added; it awaits the owner's playtest (`docs/PLAYTEST.md`). For what is built, the code wins over this doc.
> - **PLANNED (Mx)** means it is in the approved plan but not built. Mx is its milestone in `docs/ROADMAP.md`. **PLANNED (not placed)** means the plan names no milestone yet; ROADMAP lists these under "Not yet placed".
> - **To be cut (Mx)** marks something built that the plan removes in that milestone.
> - `docs/DECISIONS.md` wins over this doc for what was agreed. All player-facing text lives in `docs/STORY.md`.
> - Numbers are starting values for tuning. Names in `code font` are `systems/tuning.gd` entries; "(new)" marks one that doesn't exist yet. Numbers fixed in a script are marked *(code)*.
> - **Branches.** Everything action-RPG lives on the prototype line (`proto/kl-hollow` and the branches cut from it, now `proto/kl-replan`). `main` still has the older tending game with WayLamps and none of the action-RPG work. The plan merges to `main` once M1b passes. M1a is built on `proto/kl-m1a` (not merged). This doc describes that branch.
> - Godot 4.7 (GDScript, Compatibility renderer) · 2D top-down · single-player · PC, Linux first · keyboard/mouse and gamepad.

---

## 1. Pitch and pillars

**Pitch.** You are the valley's new keeper. Your hand lamp throws fire-light. Burn back what lives in the fog, take the old WayLamps back one by one, and follow Oswin, the last keeper, to the cold great lamp at the Still Lake.

**Genre.** An action RPG (DECISIONS 2026-11-27, Hollow prototype playtest).

**Feeling:** calm, moody, curious, rewarding, with a quiet unease.

**Pillars** (GAME_PLAN §1):
1. **Light is your weapon.** Fireballs of light from the hand lamp, aimed with the right stick or the mouse. *BUILT (M1a): Lampfire, Fireglobe, Lance and the dash, with the Beam and Hearth ring as options (§4.1).*
2. **Light is your shelter, and you carry it.** Planted lamps and lit WayLamps are pockets where you refill. No upkeep. *BUILT (M1b): lamps never burn, dim or need fuel (§6).*
3. **The find is the key.** Each region's find is a lamp that opens its lock and answers one phase of its guardian. *Built for the Hollow (the Post Lamp burns nests).*
4. **Readable fights.** Every big hit has a tell. Every foe has a name, a level and a bar. *Built.*
5. **Every fight pays, once.** Fixed packs, level-gap wick, and loot that only fixed foes drop. Cleared ground stays cleared. *Packs and level-gap wick are built; cleared ground stays cleared after a faint (the faint rule, BUILT M1b, §12.3). Loot is PLANNED (M3).*
6. **Calm at the edges.** A calm start, quiet held ground, no game over. *Built.*
7. **Show, don't list.** Lures through the fog and short notes pull you on. *Built; packs, nests and elites look different through the fog (BUILT, M1b, §7.1).*

**What the plan removes:** lamp tending, gathering, "planning over reflexes", "light is safety" and the quiet finale.

---

## 2. The core loop

**Today (built).** You fight with fire on lamp charge (BUILT, M1a): stream Lampfire, spend charge on Fireglobe and Lance, dash through tells, drink lamp oil when low, rest at a lit WayLamp. Since M1b there is no tending: you light the hut's old lamp and the north path's by touch, take scrap from one-off piles, and plant lamps that never burn. In the Hollow you clear fixed packs and nests, take the Post Lamp from Oswin's crook, beat the Clinker, and touch the Hollow's WayLamp to wake the Ashbrood, which broods over the lamp's last ember. Each level-up gives a skill point for the branch picks in the pack's Skills tab (BUILT, M2, §21). Lit WayLamps are fast travel. The Reedmarsh and the Ridge are open, with landmarks and WayLamps but no action-RPG foes yet.

**The plan** (GAME_PLAN §2):

| Scale | What you do | What you get |
|---|---|---|
| **A minute** | Aim. Stream Lampfire, which also refills charge. Spend charge on Fireglobe or Lance. Dash through the tell. Drink when low. Step into light between fights. | Wick, scrap, oil, sometimes an item |
| **A session (15-30 min)** | Rest at a lit WayLamp (full flasks). Push toward a lure. Clear 3-5 packs and an elite. Swap gear, spend a point. Reach the find or the next WayLamp and fight its guardian. Travel back to a person, or go on. | A level or two, a few items, a region held |
| **The whole game** | Five regions on one clockwise loop. Each has a find, a twist, a mid-boss, a guardian and a new skill or relic. Levels 1-12. The Soul of the Wick retreats through a portal. The valley stays open. | The great lamp relit, and a hook for later |

M1a exists to make the minute-scale loop feel good.

---

## 3. Controls

### 3.1 Built (M1a)

BUILT (M1a). Button letters follow the device you used last (E on keyboard, A on a pad). The cursor hides when you aren't using the mouse. Input actions come from `tools/setup_input.gd`; the button names are in `systems/input/input_hint.gd`.

Twin-stick aim: the left thumb moves, the right thumb aims. RT, RB, LB and LT work while you aim. Y and B take the right thumb off the stick, so they hold only things that don't aim.

| Slot | Pad | Keyboard / mouse | Default | Rule |
|---|---|---|---|---|
| 1, basic | **RT** (hold) | Left mouse (hold) | Lampfire | Always Lampfire |
| 2 | **RB** | Right mouse | Fireglobe | Aimed skills |
| 3 | **LB** | Q | The Beam at level 1, then Lance | Aimed skills |
| 4 | **Y** | F | empty | **Any skill** (BUILT, M1c; was self-cast only): an aimed skill on Y fires at the lock, else at the best foe within 30 degrees of the aim (pad), else straight (§20.5) |
| Dash | **LT** | Space (Shift too) | Dash | Along your movement |
| Flask | **B** | R | Lamp oil | Read after the menu guard |
| Lock | **R3** (an option: Y, L3 or a back paddle) | Middle mouse; the wheel moves it; a sticky click | none | BUILT (M1c), read after the menu guard (§20.5) |

| Out of a fight | Pad | Keyboard / mouse |
|---|---|---|
| Move | Left stick (not the D-pad) | WASD / arrows |
| Aim | Right stick (else where you face) | Mouse |
| Interact: read, light an old lamp or a WayLamp, take a scrap pile, turn a mirror right, rest, travel (M1b: no refuelling) | A | E |
| Hold by a planted lamp, with no scrap pile in reach: pick it up (0.8 s, `kl_pickup_hold`; a ring fills). M1b: no gathering | A | E |
| Plant the selected lamp; next to a mirror, turn it left | X | C |
| Next lamp kind (tap); the lamp list (hold); previous lamp kind | D-pad right; D-pad right; D-pad left | Tab; Tab; keys 1-4 pick directly |
| The pack (M2): Skills, Journal, Map tabs / its Skills tab / its Map tab / Journal / Pause | View / D-pad down / D-pad up / View then RB / Start | I / K / M / J / Esc |
| Close a menu | B | Esc (and each menu's own key) |
| Fullscreen; tuning panel (dev) | —; L3 | F11; F1 |

- **Aim hold.** While RT, RB or LB is held, a released right stick keeps its last aim (`kl_aim_hold` true). So drinking mid-stream doesn't swing your fire.
- **The input guard.** The flask and all combat input are read after `Progress.input_blocked()`. The B that closes a menu never drinks. `test_input` checks the journal, map, a note, pause, the lamp list, the Skills list, the travel list and the level-up screen end to end: one press that is both "cancel" and "flask" (as the pad's B is) closes the menu, the keeper's own frame reads the flask, no flask is spent, and the same press drinks once the block runs out. It also checks the flask's 1 s lockout ends.
- **The D-pad** is off movement. The map and lamp cycling are read only while no menu is open.
- **Aim assist** on a pad: a gentle pull onto a foe within 12 degrees, for Lampfire and Lance (`kl_aim_assist_deg`).
- **The right stick** aims once pushed past 0.3 (`kl_stick_aim_min`); its tilt from there to 0.9 (`kl_stick_tilt_full`) sets how far a Fireglobe lands.
- **Auto-fire option** (pause menu, off by default): on a pad, Lampfire fires while the right stick is pushed past 0.8 (`kl_autofire_stick`). Saved for this PC in `user://settings.cfg`.
- **The action bar** shows the button for the device used last. Cooldowns show as a dark radial sweep, with seconds when more than 3 are left. A slot greys out when you're short of charge. The flask shows pips (§14).
- **Binding** (M2: the pack's Skills tab, §21.3, replaces this list): the plain Skills list (K / D-pad down). Left and right pick slot 2, 3 or 4; up and down pick a skill; A / E / a click puts it there (pressing the skill already there takes it off). It opens on slot 3 with the first skill that's off the bar, so after level 2 one press puts the Beam back on LB. It is greyed while you're hunted, with the reason shown. The world pauses while it is open.
- **Deviations from the plan:** the keyboard has no "previous lamp kind" (the plan said Shift+Tab); keys 1-4 still pick a lamp directly. The pack screen (I) is M2. The L3 tuning panel is still on L3, not behind a dev-build flag (PLANNED, not placed).
- The hold-to-ward glow is still in the code (`player.gd` `update_ward()`), but nothing calls it in play. **To be cut (M1b).**

**Before M1a** (for reference): beam on left mouse / RT, burst on F / RB, dash on Shift / LT, build on Space / X, pick up on Q / right mouse / B, the lantern list on Tab / Y, the map on M / LB, and the D-pad moved the keeper.

### 3.2 Still planned

- **The keeper's pack** (Skills, Journal, Map tabs; I on keyboard, View on a pad) replaces the plain Skills list. BUILT (M2, §21.3); the Gear tab comes with gear (M3).
- **The L3 tuning panel** goes behind a dev-build flag. PLANNED (not placed).

---

## 4. Combat and skills

### 4.1 The kit — BUILT (M1a)

BUILT (M1a). Each skill is a script in `scripts/player/skills/`; `scripts/player/combat.gd` runs the bar. Lampfire, Lance and Fireglobe fly as pooled entries in one system (`fire_bolts.gd`). **Lamp charge** (0 to 1) pays for everything but Lampfire, and it is also how far your hand lamp lights. Texts: STORY.md §14.

| Skill | Gets it | Default slot | Does | Numbers (`systems/tuning.gd`) | Shells |
|---|---|---|---|---|---|
| **Lampfire** (basic) | level 1 | RT | A fireball of light. Short trail, bursts on impact with a small splash, impact flash, a scorch mark, and a brief light pop that clears fog. Free; each hit gives charge. | 2 dmg on the hit and 1 to others within 40 px, one per 0.35 s held (5.7 dps), 480 px/s, 320 px, +0.03 charge a hit; pop 72 px, clears 0.45 fog (`kl_lampfire_*`) | half (the hit only) |
| **Fireglobe** | level 1 | RB | The big lobbed fireball. Arcs to where you aim, bursts, and leaves burning ground. | 8 dmg in 90 px, then 3 s at 2 dps; lands 120-280 px out (stick tilt, or the cursor); 0.6 s flight with a ground marker; 0.3 charge; 5 s cooldown; clears 0.7 fog (`kl_fireglobe_*`) | none |
| **Lance** | level 2 | LB | A fast piercing bolt: the shell-breaker. At level 2 it takes LB once, with a toast saying where the old skill went. | 5 dmg, pierces 3, 700 px/s, 360 px, 0.2 charge, 0.5 s cooldown (`kl_lance_*`; `kl_lance_level` 2) | full |
| **The Beam** (optional) | level 1 | LB until level 2 | The old beam, channelled. Slows you; no charge from light while it's on. | 7.5 hp/s (was 6), 0.3 charge/s, 240 x 24 px, walk 70% (`kl_beam_*`) | full |
| **Hearth ring** (optional) | level 1 | none (Skills list; Y only) | The old burst, reworked: a ring of flame that sets foes alight, with a small push. | 2 dmg, then 1 dps for 2 s; 120 px; push 60 px (was 140); 4 s cooldown (was 3); 0.2 charge (`kl_burst_*`) | none |
| **Dash** | level 1 | LT | As before; nothing can chill you mid-dash. | 110 px in 0.16 s, 0.9 s cooldown, 0.08 charge (`kl_dash_*`) | — |

**The default bar.** Level 1: RT Lampfire, RB Fireglobe, LB the Beam, Y empty. At level 2 Lance takes LB, and the toast says the Beam is in your Skills list; one press in the Skills list puts it back. Whenever the keeper has Lance and the Beam is on no slot without that toast having said so (for example a version 4 save migrated at level 2 or more), a one-time tip says the same (`beam_off_bar`, STORY §14.3). Hearth ring is in the Skills list from level 1 and never on the default bar. **The M1a playtest decides** whether the Beam and Hearth ring stay (ROADMAP M1a, checks 8 and 9).

**Lance and the Beam are equal per charge:** 5 / 0.2 = 25 damage per charge, and 7.5 / 0.3 = 25. Lance hits harder in bursts and pierces 3; its cooldown caps it at 10 dps. The Beam has no travel time and hits everything on its line, but slows you and stops light regen.

**BUILT (M2): the cards became picks** (§21.1). Before M2: **the old cards stay until M2.** The code applies the beam cards (Deep tank and the rest) to the Beam, and Heavy flare and Spill to Hearth ring. Their texts are unchanged (STORY §12), so some still say "beam" or "burst".

**Feel** (BUILT, M1a; GAME_PLAN §15):
- **Hit-stop per target:** a big hit (5 damage or more, `kl_hitstop_big`: Lance, Fireglobe) freezes the foe it hits for 0.06 s (`kl_hitstop`); a Fireglobe that hits something, or a big kill, freezes the keeper for the same time. The old whole-game freeze (`Engine.time_scale`) is gone.
- **Shake** uses trauma: events add trauma, it decays 1.8 a second (`kl_trauma_decay`), and the offset is 16 px x trauma squared (`kl_shake_px`, was 6 px linear), times the player's shake setting. Trauma added: a Lance throw 0.12 and its hit 0.2, a Fireglobe landing 0.55, Hearth ring 0.4, a kill 0.15, a big kill (elite, shelled or boss) 0.35 (`kl_shake_lance_cast`, `kl_shake_lance_hit`, `kl_shake_globe`, `kl_shake_ring`, `kl_shake_kill`, `kl_shake_kill_big`; all in F1).
- **Damage numbers** pop over the foe, then drift: hits at once, splash smaller, shell damage in its own colour, steady damage (the Beam, burning) summed every 0.4 s.
- **Flash, sparks, scorch** on impact; a kill burst; persistent burning-ground visuals. Projectiles and impacts are additive sprites. "Reduce flashes" dims hit, impact and screen flashes.
- Foes flash when hit. Hurt foes and big ones show a name, a level and a health bar, with the shell as a pale bar above. The Ashbrood has a boss bar with its phase and a one-line hint, now above the action bar.
- No new sounds: existing Kenney cues are reused (sound is the owner's job).
- **The keeper's own feedback** — BUILT (readability), code-drawn until the owner draws poses (`scripts/fx/keeper_fx.gd`, on the fog layer; the poses in `player.gd` `pose()`):
  - **Dash:** a warm smear from where it started, afterimages (`kl_fx_dash_ghosts` 3, each fading over `kl_fx_ghost_life` 0.22 s), a small ember puff at the start, and a warm shimmer ring while nothing can hurt you.
  - **Cast** (Lampfire, Fireglobe, Lance): the lamp thrust out along the aim with a flare at its tip, for `kl_fx_cast_time` 0.14 s. The keeper's sprite uses the Puny sheet's spare frames: columns 13 then 14 (arm up, then thrust forward) for Lampfire and Lance, 12 then 13 (arm raised) for the Fireglobe's lob, in the row facing the aim.
  - **Drink:** a warm glow and motes rising up the coat for `kl_fx_drink_time` 0.6 s.
  - **Hurt:** a hit (a chill of 5 or more) shows the Puny hit silhouette (column 19) tinted cold, then the flinch frame (column 20), with a cold ring, for `kl_fx_hurt_time` 0.25 s. With "reduce flashes" there is no silhouette, only the cold flinch. While a Wickling drains you, the keeper is tinted cold and shows a **frost edge** (small ice spikes).
  - The Puny sheet has no drink or dash frames; those stay code-drawn.

### 4.2 The rest of the kit — PLANNED (Moth-lights M5; Wheeling flame M6)

| Skill | Gets it | Slot | Does | Starting numbers | Shells |
|---|---|---|---|---|---|
| **Moth-lights** | level 7 (the marsh) | Y | Three motes circle you, then seek foes. | 3 dmg each, seek 240 px, 4 s, 0.25 charge, 5 s cooldown (`kl_moth_*`, new) | half |
| **Wheeling flame** | level 9 (the Ridge) | RB / LB | A disc of fire that flies out 280 px and comes back, hitting both ways. | 4 dmg a pass, 0.25 charge, 3 s cooldown (`kl_wheel_*`, new) | half |

### 4.3 Branches instead of cards — BUILT (M2, §21.1)

Three tiers per skill, one pick each. One point per level-up, 11 by level 12. Tier 1 opens once you have the skill (your first point comes at level 2), tier 2 at level 4, and tier 3 at level 6, the Ashbrood kill. **Every pick changes how the skill behaves**; only the Beam's tree keeps the old number cards the owner approved. Respec is free when you rest at a lit WayLamp. No per-skill XP. The Beam and Hearth ring get trees only if the owner keeps them after M1a.

| Skill | Tier 1 (pick one) | Tier 2 (pick one) | Tier 3 (pick one) |
|---|---|---|---|
| Lampfire | *Lingering burn*: hit foes burn 2 s at 2 dps · *Scatter*: the burst throws 3 sparks (1 dmg) | *Twin*: two bolts in a V · *Skip*: bolts bounce once | *Catching*: a kill sets the nearest foe within 60 px alight · *Needle*: passes the first foe, bursts on the second · *Comet*: every 4th bolt is big (2x damage and splash) |
| Fireglobe | *Skipping globe*: bounces once, bursting at each landing (70%) · *Slick*: burning ground slows foes 40% | *Second globe*: a smaller one follows 0.3 s later · *Fire line*: lands as a line across your aim | *Cluster*: bursts into 4 small globes · *Beacon*: stays lit 6 s as a tiny lamp · *Undertow*: the blast pulls foes in first |
| Lance | *Burning line*: leaves 2 s of fire on its path · *Brand*: your next hit on the last foe struck does +50% | *Returning*: flies back through foes · *Forked*: splits in two at the first hit | *Breaking*: bursts into 3 Lampfire bolts at its end · *Held lance*: hold 0.6 s for double damage and unlimited pierce · *Shatter*: a broken shell bursts for 4 around |
| Moth-lights | *Swarm*: 5 motes · *Orbit*: they circle you 6 s and block spit | *Great moth*: one moth, 12 dmg, bursts · *Lit wings*: their paths count as light for charge | *Hive*: a mote that kills splits in two · *Lamp-keepers*: motes wait on your lamp for foes · *Last light*: motes burst (40 px) as they fade |
| Wheeling flame | *Two wheels* in a V · *Hover*: waits 1 s at the far end | *Downwind*: rides gusts twice as far · *Searing edge*: sets foes alight | *Orbit wheel*: circles you 5 s · *Chain wheel*: jumps between 3 foes · *Cleaver*: full damage to shells |
| Dash | *Second step*: two dashes per cooldown · *Cinder trail*: burning ground on the path | *Phase*: pass through foes, stunning them 0.4 s · *Flame step*: a small fire ring at the end | *Ember rest*: a 3 s ember that counts as light · *Blink*: instant 150 px · *Recoil*: a backward dash fires 3 Lampfire bolts forward |
| Beam (if kept) | *Steady hand*: walk at 90% · *Long throw*: 310 px | *Deep tank*: cost x0.8 · *Tight focus*: shells wear 30% faster | *Prism*: three thin beams · *Searing*: up to +50% over 1.5 s · *Stoking*: each second on a foe cuts Fireglobe's cooldown by 1 s |
| Hearth ring (if kept) | *Heavy ring*: push 140 px and stun 0.6 s · *Lasting ring*: stays 3 s | *Spill*: 2.2 s cooldown, +0.03 charge per foe hit · *Warm ring*: +2 warmth per foe hit | *Sunburst*: also throws 8 Lampfire bolts · *Crackle*: strips 2 shell from each foe · *Rising ring*: grows to 220 px over 1 s |

**Where today's 12 cards go.** Every card in `scripts/ui/level_up.gd` keeps its effect. Lampfire gets Lingering burn and Catching. Hearth ring gets Heavy flare and **Spill** (approved). Dash gets Second step. The Beam gets **Steady hand** (approved), Long throw, Deep tank and Tight focus. Kindled kills, **Hot core** and **Lee** (both approved) become fixed gear lines (§10), with their approved values (cores burn 2x; touch chills 25% less). If the owner cuts the Beam or Hearth ring after M1a, their card effects go with them. The card screen goes in M2.

### 4.4 Something new in every region — PLANNED (M2-M8)

| Region | New skill | Relic or find that changes a skill |
|---|---|---|
| The Hollow | Lampfire, Fireglobe, Lance (plus the optional Beam and Hearth ring) | The Ashbrood's relic, **Brood globe**: Fireglobe leaves 3 embers that seek foes (M3) |
| The Reedmarsh | Moth-lights (level 7) | The Sump's relic, **Steam burner**: a Fireglobe over water bursts twice (M5) |
| The Windward Ridge | Wheeling flame (level 9) | **Oswin's coat**: gusts don't push your fire. The Galekite's relic, **Kite lens**: Lance curves toward the nearest foe (M6) |
| The Lakeshore | — | The find, the **Mirror Post**: your fire crossing a mirror beam bursts at double radius. The Tallest's relic, **Prism wick**: Lampfire splits in three through a beam; Ebba's relic if the Tallest is cut (M7) |
| The Still Lake | — | The find, the **catch ring**: inside a mirror beam, Lampfire flies twice as far and you refill charge as if in light (M8) |

### 4.5 The shell rule — BUILT (M1a)

BUILT (M1a) in `foe.gd` `shell_factor()`; `test_skills` checks it. Moth-lights and Wheeling flame come with their skills (M5, M6).
- **Full damage:** Lance, the Beam, mirror beams. PLANNED: Wheeling flame's *Cleaver*.
- **Half damage:** Lampfire's hit. PLANNED: Moth-lights and Wheeling flame.
- **None:** Fireglobe, Hearth ring (and its burning), splash, burning ground and lamp cores. They glance off.
- Shells on elites never grow back once dented. Shells on the Clinker and the Ashbrood grow back after 3 s without a hit that wears shells, until they break, and a broken shell stays broken (`shell_regrows`, `foe.gd`; `kl_shell_regrow_wait`).

### 4.6 Time to kill — Clinker and Ashbrood BUILT (M1a, set by hand); scaling BUILT (M1b)

**BUILT (M1a):** `kl_clinker_hp` 48 (was 24), as planned. `kl_ashbrood_hp` **220 per phase** (was 40), shell 12, with the **two phases** built today. **Deviation from the plan:** the plan's 150 assumes three phases; phase 3 is M2. At 220 x 2 the test arithmetic in `test_skills` gives about 114 s with a lamp nearby and 145 s without, at the plan's 35% uptime: inside the ~2-minute target. Revisit when M2 adds phase 3. These are sums, not a playtest.

**BUILT (M1b): scaling, and the re-check.** Foes have +12% health and shell a level over 1 (`kl_foe_hp_per_level`; `Foe.level_mult()`, applied once after a foe's `_ready()`, and to each Ashbrood phase), and the keeper's fire does +10% a level over 1 (`kl_dmg_per_level`; `Progress.dmg_mult()`, on Lampfire's hit and splash, Lance, Fireglobe, burning ground, Hearth ring and its burn, and the Beam; not on the cards' Lingering burn and Catching, nor lamp cores or mirror beams). The re-check, with `test_skills`' sums (same uptimes as above): **the Clinker** (Lv 4, x1.36: 65 hp, 16.3 shell) against a level-3 keeper (x1.2, the beeline's level there) takes about **32 s** (target about 30 s); **the Ashbrood** (Lv 5, x1.48: 326 hp and 17.8 shell a phase) takes about **129 s** with a lamp near against a level-4 keeper (the beeline), **120 s** at level 5 (the explorer), 165 s with no lamp near (target about 2 minutes, 2.6 without a lamp). Both stay inside their targets, so **`kl_clinker_hp` 48 and `kl_ashbrood_hp` 220 are kept.** A Lv 1 Wickling still dies to 2 Lampfire hits at any keeper level.

**BUILT (M1c): the re-check with light.** `kl_ashbrood_hp` is now **340 a phase** (was 220): the Ashbrood is hurt only when lit (x1.3, shells x1.5), in phase 1 by a lamp in the bowl (35% uptime), in phase 2 only while it sits on a lamp (4 s of each 6.8 s dive cycle, 80% uptime in the sit). `test_skills` gives about **130 s** against a level-4 keeper and **121 s** at level 5 (target 2-3 minutes). At 220 the same sums gave 86 s. The Clinker: about 32 s dim (close in) and 23 s lit (a lamp by its post); in the dark its shell holds. The light-blind sums above are kept for history.

**Targets:** a same-level Wickling dies to 2 Lampfire hits; a shelled elite takes 3-5 s; a plain pack 2-5 s; a mixed pack 8-12 s; a mid-boss about 30 s; a guardian 2-4 minutes.

**Scaling (BUILT, M1b):** foes +12% health and shell per level over 1 (`kl_foe_hp_per_level`); the keeper +10% damage per level (`kl_dmg_per_level`); gear covers the gap (M3). **Charge while hunted:** 0.06 base + 0.086 from Lampfire hits + 0.1 in light = about 0.25/s.

| Fight | Foe | Keeper | Working | Time |
|---|---|---|---|---|
| A Wickling, Lv 1 | 3 hp | L1, Lampfire 2 a hit | 2 hits, 0.35 s apart. At L12: 2 x 4.2 = 8.4 against 6.96 hp, still 2 | under 1 s |
| The crook's guard (shelled, Lv 2) | hp 9 x 1.12 = 10.1, shell 4.5 | L1, Lampfire only | shell at 1 a hit: 5 hits; hp at 2 a hit: 6 hits; 11 hits at 2.86/s | about 3.5 s |
| Pack 2, Lv 4: 2 Wicklings, a Spitwick, an elite | 4.1, 4.1, 5.4, and 12.2 + 5.4 shell | L3 (x1.2): Fireglobe 9.6, Lance 6, Lampfire 2.4 | one Fireglobe kills both Wicklings; 3 Lances (0.6 charge, 1 s) kill the elite; 3 Lampfire hits kill the Spitwick | 3 s of damage; 8-12 s with waking, spit and walking |
| The Clinker, Lv 4 (`kl_clinker_hp` 24 → **48**) | 65 hp, 16.3 shell, regrowing | L4: Lampfire 7.4 dps; Lance 6.5 per 0.2 charge | about 12 dps on health and 8 on shell: about 7.5 s of damage; it rolls and you dodge, so about 25% uptime | about 30 s |
| The Ashbrood, Lv 5, 3 phases (the plan: `kl_ashbrood_hp` 40 → **150** per phase, shell 12; built: 220 x 2 phases, above) | per phase 222 hp and 17.8 shell | L5: Lampfire 8 dps, plus Lance at about 1.25 a second from charge income (8.75 dps) | about 17 dps: 14 s a phase, 43 s in all; adds, puffs and dives leave about 35% uptime | about 2 minutes (2.6 without a lamp nearby) |

These assume linear scaling and the stated uptimes. They are the plan's arithmetic for M1b, not measurements.

---

## 5. Resources

### 5.1 Built today

- **Warmth** is the keeper's health: 100. It comes back +20 per second in lantern or WayLamp light, **only while nothing hunts you** (`kl_warmth_regen`, was `warmth_regen_per_sec`; BUILT, M1a). In a fight, flasks heal. A Wickling's touch takes 30 per second.
- **Lamp charge** runs 0 to 1.0, **+0.1 per lamp glass** (`lamp_upgrade_charge`; `Progress.charge_max()`, BUILT M1b). It pays for Fireglobe, Lance, the Beam, Hearth ring and the dash, and sets the hand lamp's light: from a 44 px ember to 104 px at full charge, +12 px per glass (`hand_lamp_*`, `lamp_upgrade_radius`). It never goes out. The regen table below replaced the old rules (BUILT, M1a). The charge bar shows the share of the max.
- **Scrap is the one material** (BUILT, M1b). Ruin piles (64 in the Hollow, 24 on the marsh islands, 28 on the Ridge), the pile beside the hut (6), 8 old caches (the two old fuel caches and the two glass caches hold the same amounts of scrap now), and a 35% chance from each kill of a fixed foe. A pile is a **one-off pickup**: one press of E / A takes all of it you can carry (what doesn't fit stays), and an empty pile is gone for good. Pays for lanterns. You carry 30, +10 per satchel *(as built; the plan's "no carry cap" comes with the satchel's new job in M3, so the satchel isn't left with nothing to do)*.
- **Cut (M1b):** fuel (dead trees, peat, Ridge fuel spots, the regrowing woodpile, fuel embers from kills), glass (56 Ridge spots), gathering by holding, refuelling. The woodpile by the hut is scenery.
- **Upgrade finds** (one of each per region, in far corners): a **keeper's satchel** (+10 scrap carried) and a **lamp glass** (the hand lamp reaches 12 px further and holds 0.1 more charge, BUILT M1b; its old "dims slower" and "wards longer" went with the dimming and the ward) (`carry_*`, `lamp_upgrade_*`).

**Light and regen in one place** — BUILT (M1a) (`player.gd` `update_hand_lamp()`, `charge_rate()`; `test_core`, `test_flasks`):

| | Out of a fight | While hunted |
|---|---|---|
| Warmth in light | +20/s (`kl_warmth_regen`) | **none** |
| Charge in light | +0.5/s (`hand_lamp_recharge_per_sec`) | **+0.1/s** (`kl_light_charge_hunted`) |
| Charge anywhere (added to the above) | +0.06/s (`kl_charge_regen`) | +0.06/s |
| Lampfire hit | +0.03 charge | +0.03 charge |
| While the Beam is on | no charge from light; base +0.06/s continues | same |

- "Light" today means a lantern's or a lit WayLamp's light (within 85% of a lit lantern's radius *(code)*). PLANNED: a Fireglobe *Beacon* and the Dash's *Ember rest* (M2).
- **Hunted** (`systems/combat/hunt.gd`): an awake foe has you as its target within 12 tiles (`travel_hunt_radius`, 384 px). It counts an awake Clinker, any Spitwick, the Ashbrood, a Wickling chasing you, and a Wickling that was chasing and now waits at the edge of the light you stepped into, so you clear the area before you rest. Nests and wandering or fleeing Wicklings don't count. One rule blocks fast travel, Rest, warmth from light and changes in the Skills list; a HUD chip shows it.
- **Cut in M1a:** the passive dimming in the dark and the top-up from carried fuel (M1b removed `hand_lamp_drain_per_sec` from `tuning.gd` and the F1 panel too).
- **Why:** with free healing in a fight, players run off to heal instead of drinking. Fast refills out of a fight keep light a shelter.

**Lamp-oil flasks** — BUILT (M1a) (`player.gd` `drink()`, `rest()`; `ember.gd`; `test_flasks`):

| | Value |
|---|---|
| Charges | 3 (`kl_flask_max`). PLANNED: +1 from Maud (M5); +1 from a coat line (M3); at most 5 |
| Drink | B / R. Heals 40% of max warmth at once (+40) and gives +0.4 charge (`kl_flask_heal`, `kl_flask_charge`). 1 s lockout (`kl_flask_lockout`) |
| Rest at a lit WayLamp | "Rest" in the WayLamp's list: flasks and warmth back to full. Refused while hunted. Fast travel never rests |
| Drops (an amber flask on the ground; walk over it) | A fixed pack's last foe always drops 1 oil. An elite: 30% (`kl_elite_oil_chance`). The Clinker: 1 when its health falls past half. The Ashbrood: 1 at half health in each phase (`kl_boss_oil_step` 0.5). Every loss of health (hits, burning, the lingering burn) goes through the same check, so crossing half always drops it once, even when one hit takes the boss (or a phase) from above half to nothing. On the ground, oil slides to you at 220 px/s once you're close (`kl_oil_pull`). Summoned foes (nest hatchlings, the Ashbrood's adds) drop nothing at all, not even embers or scrap; they still pay wick |
| Timer refill | None. You can always rest in light out of a fight |

### 5.2 Still planned

**Warmth** is 100 at level 1, +8 a level (`kl_warmth_per_level`, new). Foe damage rises 8% a level (`kl_foe_dmg_per_level`, new) to match. PLANNED (not placed; it belongs with the M1b scaling).

**Scrap** also comes from salvage (M3), and pays for Amos's stock (M4) and Kit's re-cut (M6, a cut line). No carry cap (M3, with bag slots). Lamp charge +0.1 per glass and one material are BUILT (M1b, §5.1).

---

## 6. Lanterns

### 6.1 Built today (M1b: no more tending)

**BUILT (M1b).** Lamps never burn, dim or need fuel, in every region's code. A lit lamp shines at full radius. All of a lantern's effects live in one place, the "Effects" section of `scripts/lanterns/lantern.gd` (its light radius, its bright core and what the core does to each foe, whether it keeps small dark out, where it refills the keeper); foes read them through the `LightSense` snapshot, so new lantern mechanics go there (the owner is redesigning lanterns; DECISIONS 2026-11-27).

C / X plants the selected lantern on your tile: firm ground (not rock or soft marsh), anywhere you can stand, at least 1.5 tiles from other lanterns *(code)*, not on a scrap pile, not within 160 px of a WayLamp. Building is quiet: no outline or cost text until you try; a failed build shows the outline and the reason for 2 s. Holding E / A by a planted lantern for 0.8 s picks it up (with a scrap pile in reach, a tap takes the pile instead and the hold does nothing). **BUILT (M1c):** a pick-up gives all the scrap back (`pickup_refund` 1.0, was 0.5) and planting waits 8 s (`kl_lamp_replant_cd`); you plant at most your **lamp slots** (2 at levels 1-3, 3 at 4-7, 4 at 8-11, 5 at 12), shown as pips by the lamp kind; old lamps and lamps in held ground are free (§20.4). The Post Lamp is locked at the start; reading Oswin's crook unlocks it.

| | Post Lamp | Reservoir Lamp | Hooded Lamp | Mirror Post |
|---|---|---|---|---|
| **Cost** | 5 scrap | 8 scrap | 7 scrap (was 5 + 2 glass) | 8 scrap (was 4 + 3 glass) |
| **Light** | 224 px | 200 px, dim | 180 px | 40 px glow + beam |
| **Core** | inner 45% | inner 45% (as built; the plan's "no core" waits for its job in M5) | inner 45% | none |
| **Unlocked at** | Oswin's crook | the pumphouse | the glazier's workshop | the signal station |

- **Old lamps** (the hut's, the north path's and, since M1c, the one on the rim of the Ashbrood's bowl) start cold. One touch (E / A, "Light it") lights them; they can't be picked up. Until lit, each keeps its cold frame through the fog with a red-amber pulse (the north path's waits until the ledger is read). This is the only cold-lamp marker left.
- **Snuffed:** the lamp the Ashbrood sat on goes out for 8 s when its sit ends (`kl_snuff_sec`; M1c: during the sit it stays lit), and its ash puff snuffs lamps inside its circle for 4 s (M1c): dark, a curl of smoke and a small ring that fills; then it relights by itself.
- **Lantern cores** (the inner 45% of the light) burn small foes (2 hp/s) and are the only thing that hurts a nest. Elites, the Clinker and the Ashbrood ignore lanterns.
- **Mirror Post:** catches light within 90% of a lit lantern's radius, or in another catching mirror's beam. Its beam is 352 x 48 px in one of 8 directions; rock stops it. Beams clear fog and burn Wicklings at 3.5 hp/s. A Wickling clinging to a lit mirror smothers it and cuts the chain after it.
- **Wind is inert** until M6 (`kl_wind_enabled` false): no gust starts, and wind touches no lamp. The Ridge's drifting streaks still show.
- **Cut (M1b):** tanks, burn rates, shrinking light, refuelling (tap) and relighting with fuel, the Reservoir's feeding, "dying" lamps and Wicklings draining them, wind burning and shrinking lamps (valley-wide and the Ridge's constant wind), held regions refilling lamps, the cold and low lantern markers, edge arrows and HUD chips, the fuel bar and the held diamond under a lamp.

### 6.2 After tending — the plan (GAME_PLAN §6); what M1b built

**What a planted lamp does.** It never burns down and shines at full radius. Its light gives charge and, out of a fight, warmth (§5.1). Timid foes stay out, and brave ones burn after 2.5 s (as built). Its core burns small foes and nests (as built). It clears fog (as built). You wake by it after a faint.

**Limits and cost. BUILT (M1c), as lamp slots by level** (PLAN_LANTERNS §5; owner 2026-11-28, overriding M1b's "no lamp limit"): 2 to 5 slots by level (up to 6 with gear in M3), free in held regions, a full refund and an 8 s replant (§20.4). The plan's flat 3-lamp limit (`kl_lamp_limit`) is superseded.

| Piece | Verdict | New job, and why |
|---|---|---|
| Post Lamp | **keep** (BUILT) | The Hollow's find: haven and nest-burner. 5 scrap. |
| Reservoir Lamp | **repurpose (M5)** | The marsh's find: a wide dim light (200 px) with no core that forces things in water up (Slowwater, the Sump). Feeding is cut. 8 scrap. |
| Hooded Lamp | **repurpose (M6)** | The Ridge's find: the only lamp a gust can't snuff. Diving Gutterkites snag on it. 7 scrap. |
| Mirror Post | **repurpose (M7)** | The Lakeshore's find: a fixed beam that cuts fog, wears shells and makes your fire burst where it crosses. 8 scrap. Its unlock moves from the signal station to the Lakeshore (DECISIONS #36). |
| Wind | **repurpose (M6)** | Ridge only. Gusts snuff exposed Post and Reservoir Lamps until the gust ends (they relight themselves) and push projectiles downwind. Valley-wide gusts are cut. **Inert from M1b until M6 (BUILT).** |
| Old cold lamps (hut, north path) | **keep, no fuel** (BUILT, M1b) | Relit by touch: a haven and an early win. |
| Cold-lantern markers, low pulses, chips | **cut** (BUILT, M1b) | Nothing goes cold. The cold-frame lure stays for unlit old lamps. |
| Woodpile | **cut as a source** (BUILT, M1b) | Scenery. It existed to prevent a fuel soft-lock. |
| WayLamps refilling lamps | **cut** (BUILT, M1b) | Nothing to refill. Held ground is safe, plus rest and travel. |
| Dying lamps; Wicklings draining them | **cut** (BUILT, M1b) | Wicklings hunt the keeper. Mirror smothering stays, for the Lake. |
| The Ashbrood's dive emptying a lamp | **repurpose** (BUILT, M1b) | Its dive snuffs a lamp for 8 s. |
| Embers (+1 fuel) | **repurpose** (BUILT, M1b, in part) | No fuel embers; the glow and 140 px magnet carry scrap and oil drops (items in M3). |
| Refuel, relight with fuel, hold to gather | **cut** (BUILT, M1b) | No tending. Old lamps and WayLamps light by touch; scrap piles are taken with one press. |

---

## 7. Fog and light

### 7.1 Built today

- The valley is 224 x 200 tiles of 32 px *(code)*, each with fog from 0 (clear) to 1.
- Light clears fog (up to 0.8 per second). Unlit tiles fog back in (up to 0.05 per second, fastest next to fog). The Reedmarsh fogs back 1.8x as fast; gusts make it 1.5x everywhere.
- A tile once clearer than 0.3 is **remembered** *(code)*: a dim blue haze on screen and map. Never-seen ground is near-black.
- Scrap piles and landmarks show only below 0.35 fog *(code)*. Building doesn't check fog. Full fog slows walking to 60% (`fog_slow_min`).
- **Lures you can tell apart** (BUILT, M1b; drawn over the fog): a sleeping pack shows **small pale eyes in pairs**, one pair a member still to fight, each blinking now and then (`enemy_pack.gd`); a pack with a shelled elite (and the crook's guard) shows **one larger pair of eyes with a pale ring** instead; a **nest** has a slow, cold blue glow around it (`wick_nest.gd`); the crook has its red pulse (`post_lure.gd`); an **old lamp not yet lit** keeps its cold frame with a red-amber pulse (`lantern_markers.gd`). The sleeping Clinker is drawn over the fog as itself. Caches and upgrade finds have no lure.

### 7.2 The plan

- **Your fire lights the fog.** BUILT (M1a). Lampfire, Lance and Fireglobe light about 40 px of fog around them while they fly (`kl_bolt_light`). Lampfire's impact pop clears fog in 72 px, a Fireglobe's burst in 90 px, and burning ground is a light while it lasts (group `light_source`). So you can throw a Fireglobe into the dark to see what's there. The bench measured it within budget (§16).
- Fog slows walking to 85% at most, not 60% (`fog_slow_min`). PLANNED (not placed).
- **The Lakeshore's thick fog** clears at a quarter speed for your fire, and at the usual speed for mirror beams, the Beam and WayLamps. PLANNED (M7).
- **Lures you can tell apart.** BUILT (M1b) for packs, elites, nests and unlit old lamps (§7.1); the cache glint comes with loot (M3), and the WayLamp is drawn as itself.

| Lure | Look above the fog |
|---|---|
| Sleeping pack | small pale eyes in pairs |
| Nest | a slow cold blue glow |
| Elite or mid-boss | one larger pair of eyes with a pale ring |
| Cache or loot | a small glint, coloured by rarity |
| Unlit old lamp | a red-amber pulse (built) |
| WayLamp | a tall still shape |

---

## 8. Foes

### 8.1 Built today (the Hollow)

All action-RPG foes are in the Hollow. The Reedmarsh and the Ridge have none yet. The old endless trickle out of the fog is off (`kl_ambient_spawns` false); the spawner now only brings the bold swarm to a WayLamp without a guardian.

| Foe | File | Numbers | Behaviour |
|---|---|---|---|
| **Wickling** | `wickling.gd` | 3 hp, 65 px/s | About half are timid and stay out of healthy light; brave ones walk in, burn after 2.5 s at 1.5 hp/s and run (`kl_timid_share`, `kl_light_tolerance`, `kl_light_burn_dps`). Touch chills 5 warmth every 0.5 s (BUILT, M1c; was 30 warmth/s each, stacking), and all touching Wicklings together take at most 28 a second (§20.7). Smothers mirrors in the dark. (M1b: it no longer drains lamps.) |
| **Shelled Wickling** (elite) | `wickling.gd` | 9 hp + 4 shell, 48 px/s, chill x1.6 | Only in packs, and on Oswin's crook. Ignores lanterns. |
| **Spitwick** | `spitwick.gd`, `spit_projectile.gd` | 4 hp | Keeps 190-250 px off. A slow spit after a 0.7 s wind-up whose aim locks for its last 0.2 s (BUILT, readability; was 0.6 s, following you to the end): 12 warmth and 0.1 charge. Never starts a wind-up off-screen. |
| **Nest** | `wick_nest.gd` | 12 hp | Only a lantern's core hurts it (2 hp/s). Hatches 3 Wicklings every 10 s while you are within 320 px. |
| **Clinker** (mid-boss) | `clinker.gd` | 48 hp (was 24; BUILT, M1a) + 12 shell (regrows), Lv 4: with scaling (M1b) 65 hp + 16.3 shell | Sleeps at its post (wake 224 px, leash 480 px); uncurls for 0.6 s when it wakes. Rolls after a 0.9 s lane tell (was 0.8) for 30 warmth (M1c, was 25; x1.24 at Lv 4 = 37, the Hollow's hardest single hit) and throws the keeper 120 px out of its lane (M1c), then is dizzy for 0.6 s (BUILT, readability). Ignores lanterns. Drops 1 oil at half health (M1a). At (70,119), 9.4 tiles before the WayLamp. |
| **The Ashbrood** (guardian) | `ashbrood.gd`, `waylamp.gd`, `waylamp_ember.gd` | **M1c: reworked, see §20.3** (340 hp a phase, hurt only when lit, ash bolts, a wing sweep, the rim lamp, the ember flare, the smother). Before M1c: 220 hp (was 40; BUILT, M1a) + 12 shell a phase, two phases, Lv 5 (was 7; M1b): with scaling 326 hp + 17.8 shell a phase | Wakes when you light the Hollow's WayLamp by touch (M1b). It broods over the WayLamp's **last ember**, a small amber glow low in the lamp's cold cage (the lamp's light, not the creature's; DECISIONS 2026-11-27; code-drawn, BUILT M1b). Phase 1: in the bowl; an ash puff every 7 s (1.0 s wind-up, was 0.8) drops your lamp to 0.1 charge; a pack of 3 adds (Lv 4, was 5) every 8 s, after 0.8 s of spawn glows. Between phases it rises out of the bowl for 1.5 s (no attacks, no damage). Phase 2: it dives at the nearest lit lantern (1.0 s wind-up, was 0.7; then a 0.3 s flight, was a jump), **snuffs it for 8 s** (M1b; it relights itself) and sits for 4 s. BUILT (readability): §8.4. Drops 1 oil at half health in each phase (M1a). Its kill holds the Hollow: the WayLamp **takes its ember back**, the ember rising into the lamp and swelling into its flame as the lamp lights (1.4 s). **M2: phase 2's new moves and phase 3, see §21.5.** |

- **Packs:** 24 fixed packs plus the crook's guard (88 foes: 7 Spitwicks, 6 shelled), and 12 nests (tables in `main.gd`). A pack sleeps until you come within 320 px (`kl_pack_wake_radius`); the first two route packs wake at 5-6 tiles and the guard at 4. Fixed foes stay dead (`Progress.cleared`), **even after a faint** (the faint rule, BUILT M1b, §12.3).
- **Foe levels** (BUILT, M1b; GAME_PLAN §8.2): the Hollow's foes are **Lv 1-4**: 1 on the hut row and south, 2-3 through the middle, 4 in the north (the old 3/4/5/6 became 2/3/4/4). The guard is Lv 2, the Clinker Lv 4, the Ashbrood Lv 5 (was 7) and its adds Lv 4 (was 5). Hatchlings take their nest's level; the swarm at a guardian-less WayLamp is Lv 6 (the marsh's foes will be 5-7). A foe's level sets its wick (§9.1) and, since M1b, its health and shell (+12% a level over 1, §4.6).
- **A calm start:** nothing wakes at the hut, its lantern, the woodpile, the scrap or the ledger. Only the lone first Wickling is within 16 tiles.
- **Drops** (`ember.gd`, `foe.gd` `_drop()`): a kill of a fixed foe has a 35% chance of 1 scrap (it glows, drifts to you from 140 px and fades after 30 s). M1b cut the fuel ember. Since M1a, lamp oil too (§5.1), and summoned foes drop nothing. No items.
- **A faint** puts a half-fought pack back to sleep, restarts the Clinker and the Ashbrood at their phase, and clears summoned foes (BUILT, M1b; §12.3).

### 8.2 The plan

- **Packs and nests** keep working as built: fixed, asleep until you come close, never respawning on a timer. Nests are burned only by lamp cores; the Post Lamp is their key.
- **Elite affixes** (M2): 1 in the Hollow from level-4 packs, 2 from the marsh on: **Swift** (+30% speed), **Biting cold** (+50% chill), **Bursting** (2 Wicklings when it dies), **Thick shell** (x2), **Lightless** (ignores light, snuffs lamps it passes for 4 s). Shown under the name.
- **Scaling** (M1b): §4.6. **One projectile system** serves the keeper and foes, the Spitwick's spit included: the keeper's half is BUILT (M1a); the spit still has its own script (a deviation; not placed).
- **Summoned foes drop nothing**: BUILT (M1a) for embers, scrap and oil; items follow in M3. Nest hatchlings and the Ashbrood's adds still pay wick, which the level gap limits.
- **Hollow foe levels 1-4, Clinker 4, Ashbrood 5** (M1b; today 1-6 and 7).

**Families, mid-bosses and guardians.** Each mid-boss is a Clinker with one trait. Each guardian wakes when you light its WayLamp, blocks rest and travel (built for the Ashbrood), and on its first kill drops a relic and 3 items. The Clinker stays fixed and never roams.

| Region | Foe levels | Small foes | Region creature | Mid-boss | Guardian |
|---|---|---|---|---|---|
| The Hollow | 1-4 | Wickling, Spitwick, nests | — | **Clinker** (built), Lv 4 | **The Ashbrood**, Lv 5; phase 3, "last of the brood", PLANNED (M2) |
| The Reedmarsh (M5) | 5-7 | Wicklings, Spitwicks | **Slowwater** (hides in unlit water, grabs your feet); **Fenlight** (a false lure that bursts) | **mire**: its rolls leave chilling water | **The Sump**, Lv 8: under water until Reservoir light forces it up |
| The Windward Ridge (M6) | 8-9 | Wicklings in the lee, Spitwicks | **Gutterkite** (dives with gusts) | **downwind**: rolls faster with the wind | **The Galekite**, Lv 10: out of reach until it snags on a Hooded Lamp |
| The Lakeshore (M7) | 10 | Wicklings from the shallows | **Fogstilt** (thickens fog; a mirror beam with your fire crossing on it unravels it) | **in fog**: its shell shows only in a beam | **The Tallest**, Lv 11; **first cut** |
| The Still Lake (M8) | 11 | a mix | — | — | **The Soul of the Wick**, Lv 12 |

**Foes and lamp light.** About half of Wicklings are timid (built). Spitwicks spit across light. Elites, mid-bosses and guardians ignore light (built). Each region creature has one light rule: Slowwaters surface in Reservoir light, Gutterkites dive at lamps, Fogstilts step away from a single beam.

### 8.3 The finale — PLANNED (M8)

DECIDED (2026-11-27): a real fight. The Soul is not killed; it retreats through a portal.

| Phase | What happens | Your answer |
|---|---|---|
| 1. The coil | Three shelled coils around the great lamp. Tendrils sweep the island. Wicklings rise from the water. | Crack each coil where a mirror beam and your fire cross on it. |
| 2. Every flame | About 40 s of each guardian's signature: the ash puff, high water, the gale, the still fog. | Each is answered by that region's lamp. |
| 3. The eyes | It snuffs your hand lamp, so light no longer refills charge. Only Lampfire hits and flasks do. | Fire on its eyes until they close, three times. |

It pulls back into the water and a dark portal opens where it went down. The great lamp catches and the fog lifts. A faint returns you to the start of the phase. **Recommended for v1** (DRAFT for story markup): the keeper steps into the portal and the credits roll. You then wake at the great lamp in the open valley, with the portal sealed, as the hook.

### 8.4 Telegraphs — BUILT (readability)

BUILT on `proto/kl-readability` (2026-11-27), from `docs/ART_DIRECTION.md` §4 (DRAFT). One shared system, `systems/telegraph/telegraph.gd`: every foe attack goes **notice → wind-up → commit → strike → recover**. A foe starts a wind-up with `Telegraph.begin()`, ticks it, and strikes when it is done; its hit test is the marker's own shape (`Tell.contains()`). One node on the fog layer (z 13) draws every marker and edge arrow, over the fog, the foes and the fire. Markers are the cold `#a3bcd4`, never amber; the keeper's own Fireglobe ring stays warm.

**How a marker looks.** Full size from the first frame; a cold fill grows inside it as the wind-up runs. For the last `kl_tell_commit` (0.15 s; `kl_tell_commit_boss` 0.2 s for the Clinker and the Ashbrood) it flashes white (0.075 s on, 0.075 s off: one or two flashes), and once it strikes it stays solid; with **"reduce flashes"** it turns solid pale instead, never fainter. Shapes: a **circle** (the hit radius), a **lane** (a band as wide as the hit, to the end of the move, with chevrons), an **aim** (the spit's path at its full width, fainter past the target), **spawn glows** (where something will rise), and a **reach** (two tendrils, the Wickling's latch). An off-screen wind-up within `kl_tell_arrow_range` (900 px) shows an **edge arrow** at the screen border with the attack's icon (circle, lane or line), pulsing twice over the wind-up.

**Fairness rules** (ART_DIRECTION §4.4), each checked by `tools/tests/test_telegraphs.tscn`:
1. A discrete hit (a spit, a roll, a puff, a dive) always gets at least `kl_tell_min` 0.5 s of warning; `Telegraph.begin()` enforces it.
2. Full size from frame 1; 3. the marker is the hitbox: the test stands the keeper 3 px inside and 3 px outside each marker's edge and checks hit and miss.
4. Aim locks at commit (the Spitwick locks for its last `kl_spit_aim_lock` 0.2 s).
5. No hit from off-screen without an edge arrow; a Spitwick never starts a wind-up off-screen (`kl_spit_onscreen_margin` 16 px): it creeps closer first.
6. Markers draw above the fog.
7. **The dash always works:** a dash avoids every hit and its side effects, now including the puff's charge drain (it used to drain a dashing keeper).
9. **No two warnings land together on the keeper:** a hit whose wind-up would end within `kl_tell_gap` (0.3 s) of another's near the keeper (`kl_tell_budget_radius` 240 px) waits: its wind-up gets longer. Stricter than ART_DIRECTION's "at most two"; it only counts hits, not reaches or spawn glows.
11. "Reduce flashes" never hides a telegraph (§1.6 rule 7).

**Every attack as built** (all values in `systems/tuning.gd`, each with an F1 row):

| # | Attack | Marker | Wind-up | Commit / lock | Recover | Sound slot (stand-in) |
|---|---|---|---|---|---|---|
| 1 | A Wickling notices you; the Clinker wakes | eyes flare | `kl_notice_time` 0.3 s | — | — | `wickling_notice`, `clinker_notice` |
| 2 | Wickling touch | reach (tendrils), then a frost edge on the keeper while it drains | `kl_wick_latch_tell` 0.25 s (new; the drain used to start on contact) | — | — | `wickling_windup` |
| 3 | Shelled Wickling touch | the same; its plates glint within 48 px of you | `kl_elite_latch_tell` 0.35 s | — | — | `wickling_windup` |
| 4 | Spitwick spit | aim: 20 px half-width (`kl_spit_hit_radius` 12 + the keeper's 8), to you, then fainter to its 525 px reach; its throat sac swells | `kl_spit_tell` 0.7 s (was 0.6) | locks for `kl_spit_aim_lock` 0.2 s; flash 0.15 s | sac empty, 0.3 s | `spitwick_windup`, `spitwick_release` |
| 5 | Spit from off-screen | none: no wind-up unless on screen | — | — | — | — |
| 6 | Nest hatch | the ring round the nest fills, the pods swell, a spawn glow at each hatch point | `kl_nest_hatch_tell` 1.0 s (was a code constant) | — | hatchlings fade in, harmless, `kl_hatch_fade` 0.3 s | `nest_windup` |
| 7 | Clinker wakes | its eyes open as it uncurls; it can't move or roll | `kl_clinker_wake_time` 0.6 s | — | — | `clinker_notice` |
| 8 | Clinker roll | lane: 44 px wide (2 x `kl_clinker_hit_range` 22), 260 px long (`kl_clinker_roll_dist`), filling from the Clinker; it curls | `kl_clinker_roll_tell` 0.9 s (was 0.8) | 0.2 s; direction set at the start | dizzy `kl_clinker_recover` 0.6 s: no move, no roll | `clinker_windup`, `clinker_release` |
| 9 | Ashbrood ash puff | circle: 140 px (`kl_ashbrood_puff_radius`); it inhales | `kl_ashbrood_puff_tell` 1.0 s (was 0.8) | 0.2 s | an ash ring | `ashbrood_puff_windup`, `ashbrood_puff_release` |
| 10 | Ashbrood adds | spawn glows at the 3 points 52 px out; head up | `kl_ashbrood_add_tell` 0.8 s (new; they used to pop in) | — | adds fade in 0.3 s | `ashbrood_adds_windup` |
| 11 | Ashbrood dive at a lamp | circle at the landing point, 48 px (`kl_ashbrood_hit_radius`; was 36 at a lamp); a dotted path; the lamp flickers; an edge arrow if it is off-screen | `kl_ashbrood_dive_tell` 1.0 s (was 0.7), then a flight of `kl_ashbrood_dive_travel` 0.3 s (was a one-frame jump) | 0.2 s | sits `kl_ashbrood_sit_sec` 4 s | `ashbrood_dive_windup`, `ashbrood_dive_impact` |
| 12 | Ashbrood dive, no lamp lit | circle at the end of its 200 px dive (`kl_ashbrood_dive_dist`; the old line ran 240) | as 11 | as 11 | as 11 | as 11 |
| 13 | Ashbrood sits | slumped, eyes dim, its shell glow lower | `kl_ashbrood_sit_sec` 4 s | — | — | — |
| 14 | Ashbrood phase change | it rises out of the bowl; the boss bar shows phase 2 at once | `kl_ashbrood_phase_pause` 1.5 s: no attacks, no damage | — | — | `ashbrood_phase_windup` |

**Sound slots.** `Telegraph.play_slot(subject, cue)` plays `assets/audio/sfx/foe/<subject>_<cue>.ogg` when the owner adds one, otherwise a reused Kenney cue at a lower pitch (`Telegraph.SOUND_SLOTS`). No new audio. The wind-up sound starts with the wind-up.

**Choices made where §4 left room** (recorded here; ART_DIRECTION is a draft):
- **The dive's path is a dotted line, not a filled lane.** The flight doesn't hurt; only the landing circle does. A filled lane would claim a hitbox that isn't there (rule 3).
- **The spit's marker is a band as wide as the spit's reach, not a thin line.** The spit hits anything within 20 px of its path for its whole flight, so a thin line would be smaller than the hit.
- **The Clinker's lane is the roll's swept path.** The roll hits where its body passes within 22 px of you; for a keeper who stands still that is exactly the lane.
- **A Spitwick ready to spit, but off-screen or out of range, creeps closer each frame** instead of waiting a whole `kl_spit_period` again.
- **The Ashbrood can be hurt during its 0.3 s flight.** §4.3 didn't say; nothing else changes.
- The notice cue is per Wickling (eyes); its sound plays once a frame, so a pack that wakes together is heard once.
- Not built: the elite's optional lunge (§4.3 row 3, "M2, affixes"); shell-shatter shards (§5, P3).

---

## 9. Leveling

### 9.1 Built today

- **Wick** is the XP. Wick from level L to L+1 is `round(kl_wick_base x L ^ kl_wick_exp)` with **base 7 and exponent 1.65** (BUILT, M1b; was 6 and 1.25) (`Progress.wick_for_level`): 7, 22, 43, 69, 100, 135, 174, 216, 263, 313, 366. Capped at level 12 (`kl_level_cap`); at the cap the HUD says "max".
- **Base wick per kill** (`kl_*_wick`): Wickling 1, Spitwick 2, shelled Wickling 3, nest 5, Clinker **28** (was 20; M1b, so a pure beeline goes into the Ashbrood at L4), Ashbrood 32 (Lv 5: x2 = 64). Kindling a WayLamp pays 10 (`kl_wick_kindle`).
- **A level** also gives +10% damage (§4.6, BUILT M1b). The +8 warmth a level (§5.2) is not built.
- **Level-gap wick** (`Progress.kill_wick`, `Progress.wick_gap_mult`): wick = base x (1 + 0.25 x (foe level - 1)) x gap factor, where gap = keeper level - foe level. The factor is 1 up to 1 level over the foe (`kl_xp_band`), then x0.25 per level past that (`kl_xp_falloff`: 1/4, 1/16, 1/64), and 0 at 5 or more (`kl_xp_zero_gap`). A foe above you pays +10% a level, at most +30% (`kl_xp_bonus`, `kl_xp_bonus_max`). Fractions carry over and are saved. Hatched, called and re-fought foes pay like any other foe of their level; the gap is what stops farming.
- **Measured** (`tools/tests/test_leveling.tscn`, M1b): a **pure beeline** (the main route only: the north path, the crook, nest A, what wakes on the road to the Clinker, then the Ashbrood) reaches level 2 at the crook's guard, level 3 at pack 2, level 4 on the Clinker, goes into the Ashbrood at **L4**, and its kill gives **L5**. An **explorer** who clears the whole Hollow nearest-first reaches level 2 at pack 23 (the third fight, by the crook), L4 on the Clinker (its 5th stop), L5 at pack 3, goes into the Ashbrood at **L5**, and its kill gives **L6**. On both routes the Ashbrood's adds alone don't cross the line; the kill does; kindling afterwards adds wick but no level. Farming the hut row and the south stalls at L4 (L4 at 9 minutes, still L4 after 30; about 1.5 wick a minute in the last 10).
- **Level-ups** (`scripts/ui/level_up.gd`; BUILT M2): a skill point, a chime, a line on the tip strip and "+N" on the HUD's level and the pack's Skills tab; nothing pauses (§21.1). Before M2 a level-up paused the world and offered 3 of 12 cards ("Trim the wick"; STORY §12).
- **What you see:** "Lv 3", a wick bar and "12/24" on the HUD; name bars "Wickling Lv 2", dimmed when the foe pays less than full; a kill floats "+2 wick", grey when the gap cut it. A chime on level-up.

### 9.2 The plan — the curve BUILT (M1b); skill points M2

- **Keep the level-gap wick exactly as built.** Cap 12. (Done.)
- **The curve:** base 7, exponent 1.65 (`kl_wick_base`, `kl_wick_exp`): 7, 22, 43, 69, 100, 135, 174, 216, 263, 313, 366. BUILT (M1b).
- **The Hollow ends at level 6** (5 on a pure beeline), not 8. Its last level still comes on the Ashbrood kill (DECISIONS #17, kept). Level 2 still comes at the crook. `test_leveling` checks both routes. BUILT (M1b; §9.1).
- **A level gives** a skill point (M2), +8 warmth and +10% damage (§5.2, §4.6), and new skills at levels 2, 7 and 9. It shows as a chime, a toast and a mark on the Skills tab, with no pause.

**Wick budget per region.** The supply figures come from the plan's level-by-level simulation, not from `test_leveling`. They are estimates.

| Region | Size (open tiles) | Keeper levels | Wick needed | Packs / nests / elites | Foe levels | Full-clear supply |
|---|---|---|---|---|---|---|
| The Hollow | about 5,500 | 1 → 6 | 241 | 25 / 12 / 6 (built) | 1-4, Clinker 4, Ashbrood 5 | about 410 (1.7x) |
| The Reedmarsh | about 8,500, much of it water | 6 → 8 | 309 | 26 / 8 / 6 | 5-7, Sump 8 | about 570 (1.8x) |
| The Windward Ridge | about 4,800 | 8 → 10 | 479 | 22 / 6 / 6 | 8-9, Galekite 10 | about 620 (1.3x) |
| The Lakeshore | about 1,600 | 10 → 11 | 313 | 11 / 3 / 4 | 10, Tallest 11 | about 460 (1.5x) |
| The Still Lake | about 3,600, mostly water | 11 → 12 | 366 | 7 / 0 / 3, plus the Soul (base 60) | 11, Soul 12 | about 390 (1.1x) |

The bands land when you fight 75-90% of each region. At 60%, the Hollow and the Lake come out one level short. If the Lake runs short, the Soul's phases pay wick.

---

## 10. Loot — PLANNED (M3)

**Built today:** no items, no inventory screen, no add-ons. Kills sometimes drop scrap (M1b: no fuel embers).

| Rarity | Affixes | Share | Colour |
|---|---|---|---|
| Plain | none; base stat only | 70% | `#a3bcd4` |
| Bright | 1-2 | 25% | `#6d8fb3` |
| Rare | 3-4; may include a skill change | 5% (x2 from elites and bosses) | `#ffd27a` |
| Relic | fixed and hand-made; about 8 in v1 | guardians' first kills and some finds | `#f5a742` |

**The slot rule:** the lens shapes direct hits; the burner shapes blasts, rings, motes and burning ground. You start with a Plain item in each slot.

| Slot | Shapes | Bases |
|---|---|---|
| **Lens** | Lampfire's hit, Lance, the Beam, Wheeling flame | Clear lens (+damage), Far lens (+range) |
| **Burner** | Lampfire's splash, Fireglobe, Hearth ring, Moth-lights, burning ground | Wide burner (+radius), Slow burner (+burn time) |
| **Coat** | warmth and defence | Patched coat (+warmth), Oilskin (full-speed wading), Quilted coat (chills less) |
| **Wick** | lamp charge | Plain wick (+max charge), Braided wick (+regen) |

The slot named **wick** shares its name with the XP. The owner chose the name (DECISIONS, loot), so the clash is left for the owner to call.

**Affixes: 16 general, plus 4 skill changes on Rare and Relic items only.**

| Lens | Burner | Coat | Wick |
|---|---|---|---|
| +% hit damage | +% blast radius | +max warmth | +% max charge |
| +1 pierce on Lampfire | burning ground +1 s | **Lee**: touch chills 25% less (fixed) | **Kindled kills**: +0.1 charge per kill |
| +% shell damage | -% cooldowns | +1 flask charge | -% skill cost |
| +% speed and range | Hearth ring stuns 0.4 s | +% move speed | **Hot core**: lamp cores burn 2x (fixed) |

- **Skill changes** (no branch gives these): Lampfire hits on burning foes give +0.02 charge; Fireglobe lands 0.5 s later at double radius; Lance leaves a 2 s spot of lamp-light where it stops; each dash gives back 0.1 charge.
- **Stacking:** a gear effect and a branch pick both apply. Numbers add and never multiply. No gear effect repeats a branch pick; `test_loot` checks the lists.
- **Relics:** the Hollow has one (the Ashbrood's). The Reedmarsh: the Sump's and Maud's Smoulder burner. The Ridge: Oswin's coat, the Galekite's and Kit's Long lens. The Lakeshore: the Tallest's and Ebba's Shutter burner.
- **Drops** (start here, then tune): Wickling 3%, Spitwick 5%, nest 40%, elite 35%. A mid-boss drops 2 items, one Bright or better. A guardian drops 3, one Rare or better, plus its relic, and at least one for a slot where you hold only Plain. A side cache holds 1 item, Bright or better. **Summoned foes drop nothing.** A Hollow clear gives about 18-20 items, and loot stays finite.
- **Salvage, no vendor.** Hold X (or Delete) on an item to salvage it: Plain 1 scrap, Bright 3, Rare 8; relics can't be salvaged. Amos sells a small stock for scrap (M4). Kit re-cuts one affix on a lens or burner, once per item (M6; a cut line, since it touches the old "no crafting" rule).
- **The bag** has 16 slots, +4 per satchel (the 3 built satchels change job), +4 for the Wide Pack (M4). You take a drop by walking over it (the 140 px magnet). If the bag is full, the item stays on the ground.
- **Comparing on a pad.** In the Gear tab, the equipped item and the selected one sit side by side as cards, each stat marked ▲ gold or ▼ dim blue. A equips, hold X salvages, B goes back. Standing on a ground item shows one ▲ or ▼.
- **Code:** GLoot data classes only, with our own UI and rolling code, in `systems/loot/loot.gd` (new).

---

## 11. People — PLANNED (M4-M7)

**Built today:** no people and no dialogue. Oswin is never seen.

People come back when their region is held, stand near its WayLamp, and never fight. No main goal needs them. All five stay in v1 (DECISIONS, owner answers); Ivo is the cut line only if a milestone overruns. Pronouns: Ebba is "she"; Amos, Maud, Kit and Ivo get none until the owner chooses (needed before M4). People are drawn at the keeper's 32x32 scale, without portraits.

| Person | Milestone | Comes back when | Stands | Service | Errand → reward |
|---|---|---|---|---|---|
| **Amos**, trader | M4 | the Hollow is held | at the hut first. After the errand, at the cart by the Hollow WayLamp (78,124), on the road east | sells a small stock for scrap | **"Amos's cart"** (the south-Hollow side quest): the one cart is stuck among the quiet south packs. Clear them and plant a lamp by it. Then it rolls up to the WayLamp, and Amos gives the Wide Pack (+4 slots) and a Bright item |
| **Maud**, old pump keeper, who knew Oswin | M5 | the Reedmarsh is held | at the pumphouse | none | **"Maud's lamp"**: Maud's lamp lies in the north water among Slowwaters → the Smoulder burner and +1 flask charge |
| **Kit**, glazier's apprentice | M6 | the Ridge is held | at the workshop by the marsh climb's top (99,51) | re-cuts one affix (cut line) | **"Fire the kiln"**: bring the lens shard from a Ridge cache → the Long lens |
| **Ebba**, rower | M7 (her crossing M8) | the Lakeshore is held | at the shore end of the jetty | after the finale, rows you across the Lake to the island and the far shore | **"Show me the boat"**: put light on her boat (a lamp or a mirror beam) → the Shutter burner |
| **Ivo**, mapmaker | M5 (cut line) | two regions are held | at the carved stone by the marsh passage | the map marks lures and caches in held regions | **"Walk the edges"**: read 3 survey stones → the map shows caches you haven't found |

**How talk works (M4):** Dialogue Manager, with one `.dialogue` file per person in `dialogue/` (new). The balloon uses `UiStyle`; A advances, B closes, the world pauses. Lines are DRAFT in STORY.md, and `check_docs.py` learns to read `.dialogue` files. The journal gains People and Errands pages. Their draft lines and errands are in `docs/PLAN_NPCS_ENEMIES.md` until M4 merges them.

---

## 12. World and route

### 12.1 The map (built)

One fixed map, built by code from seed 11 *(code)*, so it is the same in every game. It never reloads; it only becomes lit. The map is 224 x 200 tiles (since 2026-11-27, when every region grew to 4x its area). The north-east quarter is rock, kept for the Lakeshore and the Still Lake.

| Region | Shape and size | Twist | Status |
|---|---|---|---|
| **1. The Hollow** | An oval about 76 x 88 tiles (about 5,500 open), centred on the hut (48,136) | the calm start | Built and playable, with all action-RPG content |
| **2. The Reedmarsh** | About 112 x 96 tiles (about 8,500), east, through a 10-tile passage | soft ground: you wade at 85% *(code)*; lanterns stand only on boardwalks and 10 islands; fog returns faster | Built and reachable since the loop; landmarks, resources, WayLamp; no action-RPG foes |
| **3. The Windward Ridge** | About 120 x 52 tiles (about 4,800), north | wind | Built and reachable by the marsh climb; landmarks, resources, WayLamp; no action-RPG foes |
| **4. The Lakeshore** | not carved (rock) | thick fog | PLANNED (M7) |
| **5. The Still Lake** | not carved (rock) | ordinary light dies | PLANNED (M8) |

Each built region has old caches (one-off piles) at its dead ends, and one satchel and one lamp glass in a far corner. A region's name fades in when its ground is first seen.

### 12.2 The loop (built)

DECISIONS 2026-11-27 ("route: one loop"). One clockwise loop with no backtracking. Coordinates are tiles, as placed (`test_prototype_loop.tscn` prints them).

1. **The Hollow.** From the hut north along the onboarding road (§19.2): the lone Wickling, the north path's lamp, a pack of 3, Oswin's crook with its guard, nest A. Then east: pack 2 (60,113), the Clinker (70,119), the Hollow's WayLamp (78,124) and the Ashbrood, out past the carved stone into the passage.
2. **The Reedmarsh,** eastward: the frames, the chalk, the pumphouse (Reservoir Lamp) and its WayLamp at **(200,140), on the pumphouse island**. (The old DESIGN said the south-east island; the code still has (200,140).)
3. **The marsh climb,** about 8 tiles wide, from (130,99) at the marsh's north-west corner by way of (124,86) and (112,72) to the Ridge's south rim at (100,56) (`MARSH_CLIMB`, `RIDGE_ENTRY`). The cairn stands at its foot (127,92). **No gate:** it is walkable as soon as you reach the marsh. The goal order and the cairn ask you to light the marsh first.
4. **The Ridge, one way,** toward the north-east: the glazier (99,51; Hooded Lamp), the lens (103,46), the coat (108,40), the signal station (116,26; Mirror Post), its WayLamp (120,30), the old steps (124,34). The far west is optional.
5. Past the steps, the Lakeshore (still rock).

**The old climb, a later shortcut:** fallen stones close it at y 84-85 (`scripts/world/climb_stones.gd`). Coming down from the Ridge (within 3 tiles, from the north side), the keeper pushes them down; they become ground, and `Progress.cleared["climb_stones"]` keeps it open in the save. From the Hollow side nothing happens. They have no text yet. The owner asked for a review of three loop calls (the stones, the cairn's place, the pumphouse note's place); that review is open (DECISIONS, loop texts approved).

### 12.3 WayLamps, travel and fainting (built)

- **Three WayLamps** (`scripts/world/waylamp.gd`): the Hollow (78,124), the Reedmarsh (200,140), the Ridge (120,30). **Lit by touch** (BUILT, M1b; was 15 fuel): the first touch reads its note, the next ("Light it") lights it. No lantern has to reach it.
- **Kindling:** in the Hollow, lighting it wakes the Ashbrood, which broods over the lamp's last ember; its kill takes the ember back and holds the region (§8.1). Elsewhere, until their guardians are built (M5, M6), a 15 s hold (`waylamp_kindle_sec`) while a swarm of 4 bold Wicklings (Lv 6) tries to sap it. It never fails; each Wickling on it only pushes the kindling back.
- **A held region:** no Wicklings spawn there and any inside fade away; its WayLamp clears fog only in its own region; you can rest and travel there. A banner says "{Region} is held". (Lamps there needed refilling before M1b; now nothing does.)
- **Rest and fast travel** (`scripts/ui/travel_menu.gd`): interact with a lit WayLamp (the prompt says "Rest or travel") to open a list. **Rest** comes first (BUILT, M1a): flasks and warmth back to full, with a toast. It never resets packs. Below it, every lit WayLamp, in region order. The one you stand at is greyed. Picking one fades to black and puts you just below it; arriving never rests. Pad: D-pad, A, B or Start. Keyboard: arrows, E or Enter, Escape (Q no longer closes it; Q is skill slot 3). Mouse: click. The world pauses while the list is open. **Blocked** while a foe hunts you within 12 tiles (`travel_hunt_radius` 384 px), while any WayLamp kindles, and while a guardian is in play. The prompt says why.
- **Fainting** at 0 warmth: **the faint rule** (BUILT, M1b; `player.gd` `faint()`, `systems/combat/faint_rule.gd`; `test_faint`):
  1. You wake at the nearest lit light (a lit lantern or a lit WayLamp) in the region you fell in, at 60% warmth (`kl_faint_warmth`). Any light within 320 px (`kl_faint_skip_radius`) of an unbeaten fight (a pack or nest not cleared, the Clinker's post, the Ashbrood) is skipped. No such light in the region: the nearest anywhere; none at all: the hut.
  2. You keep everything you carry (scrap, flasks).
  3. Your unspent wick waits where you fell (a wick drop). A second faint makes a second drop; nothing is lost until you collect them.
  4. Cleared packs stay cleared. A half-fought pack is whole and asleep again and keeps its dead: its living members go, and when it wakes again only they come back, at full health (`EnemyPack.sleep_again`, `dead_slots`). A half-burned nest is whole again. Summoned foes (hatchlings, the Ashbrood's adds, a hold fight's swarm) go, with no drops; other Wicklings flee for a moment.
  5. The Clinker goes back to the start of its phase: full health, shell regrown, asleep on its post, its oil armed again. The Ashbrood goes back to the start of the phase it reached, shell regrown, its oil armed again, over its WayLamp; the WayLamp still waits.
  A note says what happened. No death, no game over. (Before M1b a faint dropped half your fuel and scrap and reset every cleared pack.)

### 12.4 The plan

**WayLamps (M2).** Rest is BUILT (M1a), lighting by touch is BUILT (M1b; §12.3). Resting will also allow a respec (M2). A fixed hold fight stands in until each guardian is built (M5, M6). Fast travel stays as built.

**The faint rule** is BUILT (M1b; §12.3). Two readings recorded there: "an unbeaten pack" also covers nests, the Clinker and the Ashbrood (so faints don't chain at a boss either); and "a partly beaten pack heals" means its survivors come back at full health while its dead stay dead.

**The Reedmarsh's U-route (M5).** Today you walk east to the pumphouse, then about 80 tiles back west across the water to the climb. The approved plan: go out along the south and back along the north, with the WayLamp on the north island (168,102); the find still comes first (DECISIONS 2026-11-27, plan answer 9, row #36). This is a sketch from `main.gd`'s constants; M5 must lay it out and run a route test.

| Leg | Path | About |
|---|---|---|
| In | passage exit (116,137), along the main boardwalk to x 132, south on x 132 to the south island (152,156); `frames_east` moves here | 60 tiles |
| South | a new boardwalk (152,158) to (176,158), down x 176 to the south-east island (200,166), wade north to the pumphouse (204,136): the find | 80 tiles |
| North | wade to the NE island (190,120), along the spur to x 176, north to the north island (168,102): **the WayLamp**. The Reservoir's lane is needed here | 50 tiles |
| Out | a new boardwalk west near y 100 to the cairn (127,92) and the climb (130,99) | 40 tiles |

About 230 tiles with no ground walked twice (today about 170, half of it back the way you came). The main boardwalk (y 136) becomes the shortcut once the marsh is held.

**The Ridge (M6):** the stones get a toast, a note readable from the Hollow side and a fallen-pile look; pack 11 (52,93) and nest 7 (60,91) move off the foot of the old climb, so the shortcut lands on quiet ground.

**Regions 4 and 5 (M7, M8):** the Lakeshore at about x 132-164, y 18-74, with the marsh climb staying at x 131 or less (`PLAN_LAKESHORE.md` §1.1 scaled by two). Its WayLamp is on the old landing, reached along a mirror-lit lane. The Still Lake's WayLamp is the great lamp.

| # | Region | Levels | Find (the key) | WayLamp | Twist |
|---|---|---|---|---|---|
| 1 | The Hollow | 1-6 | the Post Lamp | (78,124), on the road east (built) | the calm start |
| 2 | The Reedmarsh | 6-8 | the Reservoir Lamp | the north island (168,102), PLANNED (M5); built at (200,140) | water |
| 3 | The Windward Ridge | 8-10 | the Hooded Lamp | (120,30) (built) | gusts |
| 4 | The Lakeshore | 10-11 | the Mirror Post | the old landing, along a mirror-lit lane | thick fog |
| 5 | The Still Lake | 11-12 | the catch ring | the great lamp | ordinary light dies |

---

## 13. Story and guidance

All text is in `docs/STORY.md`, mirrored in `systems/story/story.gd`, `scripts/main/main.gd`, `scripts/world/` and `scripts/ui/`.

**Built today:**
- **Opening** (new games only): a three-line title card, "Your name, keeper?" (up to 16 characters *(code)*; left empty, you are "Keeper"), then Oswin's letter.
- **Goals:** 23, one at a time in the top banner, completed by what you do; finish one early and the next unfinished one shows. The last, `descend`, waits for the Lakeshore.
- **Goal pointer:** a soft amber arrow at the screen edge, or a chevron over the target. Auto mode: on in the Hollow, off once you first walk into the Reedmarsh. The pause menu sets auto, always on or off.
- **Journal** (J / View): *Goals*, *Story so far* (the letter and 11 keeper's entries) and *Notes* (every note read). Titled with the keeper's name.
- **Notes:** 12 readable landmarks (4 unlock a lantern) plus the rack as scenery, 6 upgrade finds and 3 WayLamp notes. Unread ones glow.
- **Tips:** 21 one-time tips; "Show tips again" is in the pause menu. Tokens such as `[beam]` become the button for the device in use; since M1a, [beam] is Lampfire's button and [burst] is Hearth ring's slot (STORY §8, §14.10).
- **M1a texts** (skills, the Skills list, Rest, flasks, options, toasts, the boss-bar hints) are DRAFT in STORY §14.

**The plan:** keep the voice and the mystery. New text is written as DRAFT in STORY.md with the code. STORY.md §13 lists every text the plan needs rewritten, and the new lines it needs.

---

## 14. UI and HUD

**Built today.** One panel style (`UiStyle`, `assets/ui/theme.tres`). The font is Ark Pixel at 20, 30, 40 or 60 only.
- **HUD:** top left, scrap (M1b: no fuel or glass), the level row ("Lv 3", wick bar, "12/24") and the lantern you will build; top centre, the goal banner; top right, status chips only when something needs you (hunted, smothered mirrors, a hold fight's countdown, getting cold, an ember lamp; M1b cut the wind and the cold and low lantern chips). Bottom centre (BUILT, M1a; `scripts/ui/action_bar.gd`): the action bar, drawn by code, with the warmth and charge bars above it (they moved there from the top left). Tips and toasts sit above the bar; the key reminder is bottom left, on three lines.
- **Prompts** sit over the thing you can use ("[E] Read", "[E] Light it", "[E] Take  6 scrap", "[E] Turn right", "[E] Hold: pick up", "Rest or travel"; M1b texts in STORY §15). A failed build says why for a moment.
- **Menus:** the lantern list (cards), map, journal, pause menu (with Options, BUILT M1a), notes, the level-up cards, the Skills list (BUILT, M1a), the WayLamp list (Rest and travel) and the F1 tuning panel (M1a added a row for every `kl_` value it introduced). All of them pause the world.
- **Foe bars and the boss bar** as in §4.1. No inventory or equipment screen, no talk panel.

**The plan:**

| Element | What | When |
|---|---|---|
| **Action bar** | Bottom centre, laid out like the pad: LT and LB left, Y middle, RB and RT right, the flask at the right end with pips that flash when one comes back. 32 px icons, button labels at 20. Cooldown sweep and seconds; greyed when short of charge. | BUILT (M1a) |
| **Warmth and charge** | Two bars just above the bar, with skill-cost ticks on charge. | BUILT (M1a) |
| **Top of the screen** | Left: level, the wick bar and the scrap count. Centre: the goal banner (built). Right: chips only for "hunted" and "cold". The "hunted" chip is BUILT (M1a); the fuel, lamp and wind chips are gone (BUILT, M1b). | BUILT (M1a, M1b) |
| **Foe bars, boss bar** | As built, plus the elite affix line (20 px) and "phase N / 3". | BUILT (M2, §21.4, §21.5) |
| **Damage numbers** | Pop, then drift (§4.1). | BUILT (M1a). The "+wick" popup was already grey when the gap cut the wick |
| **Map** | As built, plus WayLamp icons, lures you've seen, and the share explored. | not placed |
| **Level-up** | A line on the tip strip and a Skills-tab mark. The card screen is gone. | BUILT (M2) |
| **The keeper's pack** | Skills, Journal and Map tabs (LB / RB); Gear with M3. The Skills tab is greyed while you are hunted. | BUILT (M2, §21.3) |
| **Options** | In the pause menu: a screen-shake slider (0-100%, steps of 10), "Reduce flashes" and the Lampfire auto-fire option. Saved for this PC in `user://settings.cfg`, not in a save slot. | BUILT (M1a) |
| **Skills list** | The pack's Skills tab (K / D-pad down), §21.3. | BUILT (M1a as a list; M2 as the tab) |
| **Pad name entry** | A letter grid for the keeper's name. Until then a pad player is "Keeper". | M9 |

---

## 15. Save, load and pause (built)

- Three save slots, chosen on a screen at start (keeper, region and play time on each), plus autosave every 60 s *(code)*, on closing the window and from the pause menu. Save version **7** (BUILT, M1c: the rim lamp on the Ashbrood's bowl is one of the saved lanterns; a version 6 save has no rim lamp, so loading puts every missing old lamp back cold; nothing else in the file changed). Version 6 came with M1b, version 5 with M1a (`systems/save/save_game.gd`). **A version 5 save migrates** (the owner's current save is v5): fuel and glass leave the inventory; what WayLamps were fed is dropped; lanterns lose their tanks, and only the valley's old lamps can stay cold (a v5 old lamp with an empty tank comes back cold, to be lit by touch; a planted lamp that had burned out comes back lit); fuel spots, peat, glass shards, the woodpile, dropped fuel and empty piles go; untaken fuel and glass caches become scrap caches of the same size; scrap piles keep what is left (one-off now). Level, wick, the bar, flasks, upgrades, notes, cleared fights and the story are kept. Charge is capped at the new max. `test_save` migrates a test-only v5 file. The prototype line saves to its own files (`user://keepers_light_slot_*`), so it never touches a `main` save. A version 4 save is migrated on load: it gets the default bar (with Lance on slot 3 if the keeper is level 2 or more) and full flasks. Anything older starts fresh and shows "(old save)". A loaded action bar is checked slot by slot against the binding rules; a slot holding something it may not (an unknown or unlearned skill, a self-cast skill on slots 2-3, a skill already on an earlier slot; M1c: slot 4 takes any skill) takes the default bar's skill for that slot, or stays empty if that is not allowed either.
- **Saved:** the keeper, scrap, unlocks, every lantern (kind, place, mirror direction, whether an old lamp is still cold), the scrap piles left, the fog and what has been seen, story progress, wick and level, picks (M2, version 8: picks, carried old-card lines, the respec spot; cards before), cleared foes, wick drops, lit WayLamps and the stones; since version 5, the action bar, whether Lance was given, and the flasks. **Not saved:** live foes, embers and oil on the ground, a snuffed lamp's timer, a half-fought pack's dead (a reload brings the whole pack back, asleep), wind. The M1a options (shake, flashes, auto-fire) and the M1c lock options (§20.5) are saved per PC in `user://settings.cfg`, not in a slot. Tests, captures and the bench (scenes under `res://tools/`) never read or write that file; they use the defaults.
- **Pause menu** (Esc / Start): Resume, Save, Save slots, New game (press twice), Save and quit, Goal pointer, Target lock options (BUILT, M1c: they show in place of the controls list), Show tips again, the controls, and Options (BUILT, M1a: screen shake, reduce flashes, Lampfire auto-fire).
- Later milestones add sections to the save.

---

## 16. Performance (built)

- **Budget:** game logic (process + physics) averages well under 4 ms a frame with 30 lanterns and 20 foes, measured by `tools/bench/bench.tscn` (see AGENTS.md). After the loop it measured 3.03-3.10 ms over three runs (worst frame about 6.0-6.4 ms).
- **M1a** (BUILT): the bench also runs a fight at a firing range away from the keeper: 40 Lampfire bolts always in the air, flying at 8 target foes and hitting them (about 160 hits a second, with splash, impact effects and damage numbers), and 4 burning areas under them. **It was over budget** (fixed by the readability step, below): game logic averaged 4.7-5.6 ms (worst frame 8.0-11.7 ms) over seven headless runs on 2026-11-27, against 3.0-3.5 ms for the same world with no fight (`-- 30 20 400 0 0`). The bolts' hits add about 1.2 ms of physics and the effects about 0.4 ms of process; the burning areas about 0.4 ms. The machine was also running the game at the time, so treat these as rough. (The M1a build's own figure, 3.158 ms, came from a bench whose 40 bolts stood still and hit nothing, and whose world was paused by the level-up cards from about frame 100. The bench now keeps the cards closed and reports paused frames.)
- **M1b** (BUILT): lamps no longer burn, feed, take wind or die, and nothing works out what a Wickling may drain, so the lanterns' and the foes' frames got cheaper. The bench (its quarter of "dying" lamps are snuffed, dark lamps, now): game logic **1.61 / 1.67 / 1.61 ms** (worst 3.37 / 3.77 / 3.45 ms), 160 hits a second, 0 paused frames, three headless runs on 2026-11-27. The bench is lighter than before in one way: its dark lamps used to be lit "dying" lamps, so 8 of its 30 lamps no longer clear fog.
- The fog steps only tiles that can change. Foes read lantern light from one shared snapshot a frame (`systems/light/light_sense.gd`), which also caches each lantern's core from the lantern's own Effects. The map is drawn once, in 16 x 16 tile chunks *(code)*. Lanterns redraw only when their look changes.
- **The readability step's performance pass** (BUILT, readability). Profiled with the bench's new `profile` mode (it runs each kind of node's `_process` and `_physics_process` itself and times them). Before, on this machine: game logic 4.70 / 4.63 / 4.59 ms (worst 8.95 / 7.54 / 8.20 ms). The profile put 2.37 ms in the foes and 1.05 ms in the bolts' physics, and **0.71 ms of the bolts' 1.05 ms was `Sfx.play`**: every Lampfire hit started an Ogg on its own player, and setting up its decoder cost about 0.25 ms on the main thread. Fixes, none of which change how the game plays:
  - `Sfx` mixes every effect through one `AudioStreamPolyphonic` player (about 0.04 ms a play), and a cue asked for twice in the same frame plays once.
  - Foes read WayLamps and mirrors from the `LightSense` snapshot instead of asking the scene tree every call; "is this dying lamp covered by healthy light?" was worked out once a frame for all Wicklings (`LightSense.prey_flags`; gone in M1b with the draining), not once per Wickling per lamp; Wicklings ask the keeper's light once a frame (`player.in_light_cached()`); a Wickling's own light level is read only when it needs it.
  - After: **2.60 / 2.55 / 2.61 ms** (worst 4.30 / 4.29 / 4.77 ms), 160 hits a second as before. The world with no fight (`-- 30 20 400 0 0`): 1.95 ms (was 3.0-3.5). The worst frames are the frames the fog ticks (1.3 ms a tick, every 0.1 s).
  - **With the telegraphs busy** (`-- 30 20 400 40 4 tells=8`: 8 Spitwicks winding up without a pause, the Ashbrood and the Clinker, about 9.5 wind-ups alive every frame): **2.51 / 2.55 / 2.54 ms** (worst 4.53 / 4.53 / 4.77 ms). The telegraph layer's own process costs under 0.01 ms.
  - Rendered on a virtual display (software rendering, so frame times are high): logic 3.36 ms, frame 15.9 ms, 441 draw calls on average; with `tells=8`, logic 3.40 ms, frame 16.8 ms, 516 draw calls. All numbers 2026-11-27, no other Godot process running.

---

## 17. Art and audio

**Kept as built.**
- **Moody pixel art:** 16x16 tiles drawn at 2x (32 px on screen, one fog tile), nearest-neighbour filtering, hard edges. Tall things are 16x32.
- **14-colour palette** (`source/palette/lantern-keeper-14.gpl`): cool blues for the world; ambers only for light, fire and wood.
- **CC0 sources, recoloured:** Kenney Tiny Town and Tiny Dungeon, Puny Characters (the keeper), all in `assets/CREDITS.md`. The font is Ark Pixel 10px Proportional (OFL 1.1).
- **The owner's art** replaces placeholders over time. The Post Lamp (lit and cold) is done and kept as drawn. Since the sprites step, the Wicklings, the Spitwick, the nests, the keeper and the Ashbrood are sprites too (below). Everything else is a placeholder or drawn by code: the Clinker, drops (oil included), lures, the fire skills, the action bar's icons. The list is `docs/ART_CHECKLIST.md`.
- **Light and dark:** near-black darkness, a flickering 2D point light for every light, soft-edged fog on its own layer. Not used so far: occluder shadows, a fog shader, mist particles.
- **Audio:** 30 Kenney CC0 effects and a synthesized placeholder ambience. No music. Sound and music are the owner's job (DECISIONS, combat kit playtest). No jump scares.

**The feel** — BUILT (M1a) in `scripts/fx/fire_fx.gd`, `scripts/fx/damage_numbers.gd` and `scripts/player/skills/`. What the M1a capture views showed: the action bar, a Lampfire stream with impacts, the Fireglobe marker, burning ground and the Skills list (`m1a_*` views in `tools/capture/capture.gd`). The table is the plan; recoil and per-skill sounds are not built (no new audio in M1a).

| Event | Feedback |
|---|---|
| Cast | additive flare at the lamp (built), slight recoil (not built), sound (old cues reused) |
| Flight | trail and glow; a small light that clears fog |
| Hit | white flash (built), sparks, small knockback, damage number |
| Burst / kill | Lampfire's light pop; 60 ms hit-stop on the keeper and the target only; a scorch mark that lingers |
| Fireglobe, Hearth ring | camera trauma, a ring flash, a burning-ground decal |

- **Additive sprites** for every fireball, trail and blast; `PointLight2D` only for the hand lamp, lamps and WayLamps (built).
- **Hit-stop** replaced the global `Engine.time_scale` freeze in `foe.gd` `_die()`; **shake** uses a trauma recipe (built; §4.1).
- **Collision:** the keeper's fire finds foes by shape queries against a small hurtbox on every foe (`foe.gd`, physics layer 5). Projectiles are pooled entries in `fire_bolts.gd` (built). **Deviation:** the plan wants one projectile system for keeper and foes; the Spitwick's spit still uses its own `spit_projectile.gd`.
- **The placeholder swap hook** — BUILT (readability; ART_DIRECTION §6.2-§6.4, DRAFT). `Art.frames(subject, variant)` builds a `SpriteFrames` from PNG strips (frames side by side, equal size) and a small `<subject>.frames.cfg` (frame size, anchor, and per animation fps, loop and `timed_by`, a tuning value the animation is stretched to). Each strip has its own frame size: `[variant.<v>] frame_size` for a variant's strips (the elite Wickling's 24x24 beside the 16x16 timid and brave), else the animation's or the sheet's, and a strip's height always wins; `FoeSprite` keeps the foot anchor right for each size. It looks in `assets/art/creatures/<subject>/<subject>[_<variant>]_<anim>.png` and, for the keeper, `assets/art/keeper/keeper_<anim>.png`; a strip Godot hasn't imported yet is read straight from the file. `FoeSprite.attach()` adds a sprite only when strips exist; otherwise the foe keeps its code shape. Wired up for the Wickling family (variants `timid`, `brave`, `elite`), the Spitwick and the keeper's poses (`idle`, `move`, `cast`, `lob`, `thrust`, `dash`, `drink`, `hurt`). Missing animations fall back (a wind-up to idle, a dash to move, then idle). Overlays (telegraphs, shell rings, burning edges, health arcs) stay code-drawn, and the hit flash carries over to the sprite. **No PNGs are included**; `test_telegraphs` checks the fallback, the per-variant sizes and loads test-only strips. The tool `tools/art/sprite_from_sheet.gd` (`tools/art/README.md`, `test_sprite_tool`) makes such strips from a key-pose sheet; its output waits for the owner's approval.
- **The sprites** — BUILT (sprites; DECISIONS 2026-11-27, "the sprites approved"). The owner approved the tool's strips as they are. They are made by `tools/art/make_sprites.sh` (the six manifests in `tools/art/manifests/`, from private concept sheets in `tools/art/samples/`, not committed) and committed under `assets/art/creatures/` (wickling, spitwick, nest, ashbrood), `assets/art/keeper/` and `assets/art/people/amos/`. In the game:
  - **Wicklings** (16x16; the shelled one 24x24): timid and brave idle, move, notice (with the code's cold notice arc kept on top), the timid flee, the brave reach (wind-up) and drain (attack), the hatch fade-in (spawn). An elite's breaking shell plays its crack, then the shell-less body. They face where they move.
  - **Spitwick** (16x32): idle, wind-up (stretched to `kl_spit_tell`), recover; it faces the keeper.
  - **Nest** (32x24, not the bible's 32x32): idle, the hatch wind-up (the pods swell with the code's pulse; the hatch ring and a brightening core are drawn over it), a short hatch pose. Its slow cold lure glow is still drawn.
  - **The keeper** (32x32): idle, move, thrust (for Lampfire and Lance), lob (Fireglobe), dash, drink, hurt, with the Puny frames' cold hit and frost tints. The strips face right, so every direction shows a side view, mirrored for left; the Puny sheet stays as the fallback. `kindle` is in the strips but not used yet.
  - **The Ashbrood** (48x48): phase 1 in its bowl (idle over its ember, the puff's wind-up stretched to `kl_ashbrood_puff_tell`, the release); the rise between phases; phase 2 its risen pose between dives, the crouched dive wind-up (`kl_ashbrood_dive_tell`), the flight and the slump after landing (the open window). The WayLamp's code-drawn ember is unchanged, in the cage above it.
  - **Deaths:** a foe with a death strip leaves it playing where it fell (`FoeSprite.leave_remnant`, a picture only), then it fades.
  - **Amos and his cart** (32x32 and a 48x32 prop) load (`Art.frames("amos")`, `Art.prop("amos", "amos_cart")`) but are not placed: people come in M4. The `sprites` capture view shows them beside the rest.
  - Still code-drawn: the Clinker, the spit, every overlay (telegraphs, shell rings, burning edges, health arcs, tendrils, the bold swarm's rim), the WayLamp ember. The sprite draws behind its foe's overlays (`show_behind_parent`), and the telegraph layer (z 13) is over every foe. Without the strips every foe and the keeper fall back to the code shapes and the Puny frames; `test_telegraphs` checks both.
- **The bold swarm's rim** (BUILT, readability) is the cold `#a3bcd4`, brighter and wobbling faster; it was an off-palette red that read as warm (ART_DIRECTION §1.4 rule 3).
- **New art:** skill, flask and item icons; rarity glints; sprites for the Clinker and the spit; the keeper's up and down views (optional, see DECISIONS); each region's creature and guardian; people; climb stones that read as a fallen pile.
- **Audio needed** (owner; Kenney stand-ins until then): cast, hit and burst for each skill; flask; dash; rest; loot drops by rarity; boss phases; the portal.

---

## 18. Version 1 scope

**IN** (v1):

| Item | Status |
|---|---|
| One map, five regions on one loop | 3 built (Hollow, Reedmarsh, Ridge); Lakeshore M7; Still Lake M8 |
| The fire kit, the action bar, flasks | BUILT (M1a), awaiting the owner's playtest; Moth-lights M5, Wheeling flame M6 |
| No lamp tending; one material (scrap) | PLANNED (M1b) |
| Skill branches | BUILT (M2): 42 picks over six skills, tiers 1-3 |
| Diablo-style loot, 4 slots, salvage | PLANNED (M3) |
| Five people with short lines and errands | PLANNED (M4-M7) |
| Foes, mid-bosses and guardians per region | Hollow built (Ashbrood three phases, elite affixes: M2); the rest M5-M8 |
| The finale fight, the portal, the sandbox after | PLANNED (M8) |
| Levels 1-12 with level-gap wick | built (curve to be retuned in M1b) |
| WayLamps, fast travel and Rest | built (Rest BUILT M1a; lit by touch M1b) |
| Opening, goals, pointer, journal, tips | built for 3 regions |
| Keyboard/mouse and gamepad for every action | built; the M1a pad map is BUILT |
| Save/load: three slots plus autosave | built |
| Atmosphere: lights, fog, sound, pixel art | built; placeholders remain |
| Settings: fullscreen, goal pointer, tips; shake slider, "reduce flashes" and auto-fire (BUILT, M1a); volume; accessibility (M9) | partly built |
| A Linux build | PLANNED (M9) |

**OUT** (v1): death or game over; dialogue trees or cutscenes (short spoken lines from people are IN); more than one map, or random maps; day/night, rain, seasons; crafting beyond salvage and Kit's single re-cut (a cut line); a Windows build; co-op or other platforms; a second progression track.

**Target playtime:** perhaps 5-7 hours, a guess (was 1-2 hours; DECISIONS, plan answer 9).

**Cut lines**, first to go if time runs short: the Tallest, Kit's re-cut, Ivo, Moth-lights' tier 3.

**Done when:** a new player reaches the finale without help; no soft-locks; all regions, finds and landmarks are in; save/load restores everything; both kinds of input work everywhere; the Linux build runs on a fresh machine; `assets/CREDITS.md` is complete.

**Maybe later:** rain, snow, a weather cycle, day and night; more lamp kinds (coloured lights that reveal hidden marks, floating lanterns, a lighthouse); more regions after v1 (the portal and the far light are the hooks); direction C's tides (ebb and flood), if fights need build-up; a Windows build, Steam Deck; an original soundtrack; a photo mode and an "ambient" mode.

---

## 20. Lamps in the fight — BUILT (M1c)

**BUILT (M1c)** on `proto/kl-m1c` from `docs/replan/PLAN_LANTERNS.md` §8 (approved 2026-11-27) and the owner's M1b playtest. Every number is in `systems/tuning.gd` and the tuning panel (F1 / L3). Tests: `test_light_states`, `test_combos`, `test_lock`, `test_fights`, plus M1c checks in `test_core` (slots), `test_skills` (the time-to-kill sums), `test_waylamps`, `test_input`, `test_telegraphs` and `test_save`. Awaits the owner's playtest (PLAYTEST.md).

### 20.1 Light states (`scripts/enemies/foe.gd`, `systems/light/light_sense.gd`)
- Each foe works out its state every frame (and on each hit): **dark** outside every light, **dim** inside only the keeper's hand-lamp light (44-104 px, with charge), **lit** (exposed) inside a lamp's light: a lit planted or old lamp (a flare's bigger light counts), a held WayLamp or a mirror beam. Bolt lights, pops and burning ground never expose. It stays exposed 0.5 s after it leaves light (`kl_exposed_linger`).
- **Dark:** damage x0.7 (`kl_dark_dmg_mult`); a shell wears down to 1 (`kl_dark_shell_floor`) and holds there, clinking. **Dim:** as before. **Lit:** damage x1.3 (`kl_lit_dmg_mult`), shells wear x1.5 (`kl_lit_shell_mult`). The multiplier comes last, once, after level and every add-on. Lamp cores, the brave ones' light burn and mirror beams (source `mirror`) skip it, so cores still burn 2 hp/s. Nests skip the whole rule.
- The look: a dark foe is drawn dim and cold (its body tinted `light_tint()`, copied onto owner art), its bar dimmed and, on a shell bar, a dark notch at the floor. A lit foe has full colours, a 1 px warm rim on the side facing the lamp and pale cracks on its shell (`scripts/ui/foe_bars.gd`). A stand-in sound slot `foe_exposed` plays when it steps in. A first dark hit shows the tip `dark` (DRAFT).
- Elites, the Clinker and the Ashbrood still ignore light for movement and cores, but light exposes them.

### 20.2 Combos (`scripts/player/skills/fire_bolts.gd`, `scripts/lanterns/lantern.gd`)
A combo happens at a lamp's **flame** (`Lantern.has_flame()`: a lit lamp that isn't a mirror, planted or old; WayLamps never).
- **Catch:** a Lampfire bolt within 28 px of a flame catches once: 2 → 3 damage, and 2 side bolts at ±18 degrees (2 damage, a fresh 240 px) that can't catch.
- **Flare:** a Fireglobe landing within 40 px of a flame snaps onto it (the landing marker shows on the flame) and flares the lamp: 16 in 160 px (no shell wear), burning ground in 140 px for 3 s, and the lamp's light x1.5 settling back over 3 s. A lamp flares once per 6 s (a small ember on the post shows the wait); on cooldown the globe bursts as normal.
- **Chain:** a Lance passing within 28 px of two flames up to 420 px apart with no rock between arcs fire between them: 6 to every foe within 20 px of the line between the lamps (full shell wear), then a burning seam, 2 dps for 2 s (`chain_seam.gd`). A third lamp in line chains on.
- **Feed** (the Beam is still an optional skill): while the Beam touches a flame, the lamp's light x1.3 and its core x2.
- **Ember:** a Fireglobe in the Ashbrood's bowl stirs the ember (§20.3).

### 20.3 The Ashbrood, reworked (`scripts/enemies/ashbrood.gd`)
- **Hurt only when lit** (`kl_ashbrood_needs_light`; dim counts as dark). In the dark every hit glances off with the clink and the boss bar says "It shrugs off fire in the dark. Bring a lamp." (DRAFT). A warm line under the boss bar shows while it is lit.
- **The rim lamp:** an old lamp about 180 px west of the WayLamp (`kl_rim_lamp_dist`), lit by touch, never needs scrap; its light reaches the bowl. Its lure waits until the WayLamp's note is read. It is saved like the other old lamps (save version 7, §15).
- **The ember:** one ember, at its feet in the bowl, on the sprite's own small bowl ember (`WayLamp.EMBER_BOWL`, M1c; was in the cage above it), with a thin warm thread up to the cold cage. A Fireglobe landing within 64 px of the WayLamp stirs it: amber light spills out to 120 px and exposes the Ashbrood for 4 s, at most once per 8 s.
- **No quest arrow** while it fights and the keeper is within 720 px of the WayLamp (`goal_pointer.gd` `HIDE_NEAR_FIGHT`): the owner found the ember sat on the arrow. Farther off (after a faint, say) the arrow shows the way back (review fix).
- **Real kills** (`test_ashbrood_kill`, a level-4 keeper streaming Lampfire and Lance with no dodging): the rim lamp only, **79 s** (phase 1 27 s, phase 2 52 s); Fireglobes only in phase 1, **62 s** for that phase (7 ember stirs), 113 s in all with the rim lamp in phase 2 (there is no ember in phase 2). A real fight dodges, so it is slower: about 2-2.5 minutes by the sums. Standing still, the keeper takes about 400 warmth over the fight: dodging is required.
- **Phase 1 fights back** (owner: "it just sits there"): **ash bolts**, a fan of 3 slow cold bolts (230 px/s, 10 warmth each, Lv 5 x1.32), each with its own aim marker, spaced by the warning-gap rule, every 2.2 s; a **wing sweep** when you stand within its 96 px circle (0.8 s wind-up, 16 warmth and a 90 px shove, then 4 s cooldown); the **puff** every 7 s, which now also snuffs every lamp inside its 140 px circle for 4 s (the rim lamp is outside it); the **adds** every 8 s. It never waits more than 2 s (`kl_ashbrood_idle_max`) without starting a wind-up: `test_fights` counts 13 wind-ups in 20 s, the longest wait 2.2 s. The bolts reuse the puff's strips, the sweep the dive's crouch.
- **Phase 2:** it dives 1.5 s after each sit (`kl_ashbrood_dive_period`, was 6) at the nearest lit lamp within 520 px of the WayLamp (the rim lamp counts), else at you. **Review fix:** a dive that finds no lit lamp (the rim lamp still out after its last smother) lands, sits only 1 s (`kl_ashbrood_dark_sit`) and throws a fan of ash bolts, so phase 2 never waits more than about 2 s (`test_fights`: longest 1.5 s with the rim lamp only, was 5.5 s). During its 4 s sit it **smothers** the lamp: dark wings over a flame that still burns, so the sit is the window; when the sit ends the lamp is out for 8 s. About one dive every 7 s (`test_fights`: 3 in 20 s). If it waits too long between dives it throws ash bolts.
- Health **340 a phase** (was 220), shell 12 (§4.6).

### 20.4 Lamp slots (`systems/progress.gd` `lamp_slots()`, `scripts/player/player.gd`, `scripts/ui/hud.gd`)
- Slots by level: 2 (`kl_lamp_slots_base`), +1 at levels 4, 8 and 12 (`kl_lamp_slot_level_a/b/c`), at most 6 (`kl_lamp_slots_max`; gear in M3). A slot is a planted lamp outside held ground; old lamps and lamps in a held region are free.
- A refused plant says why by the keeper: "All your lamps are lit." or "Your hands are full for %d s." (DRAFT). A pick-up gives all the scrap back and starts the 8 s replant wait.
- The HUD shows one pip per slot beside the lamp kind: a lit pip for each lamp planted, empty ones free; during the replant wait the next free pip fills as a ring.
- Nothing is saved for slots (they come from the level).

### 20.5 Target lock (`systems/combat/lock_on.gd`, `scripts/player/combat.gd`)
- **Pad:** R3 (`lock_on`) locks the best foe within 400 px in a 60-degree cone around the stick (or where you face): the smallest angle plus distance / 400, foes hunting you first; with the cone empty, the nearest in range; none: a soft tick. A flick of the right stick (past 0.8 and back within 0.25 s) switches to the nearest foe within 60 degrees that way. Holding the stick longer than 0.25 s steers (the aim assist works; the marker at half strength); letting go returns to the lock. R3 again ends it.
- **Keyboard and mouse:** middle mouse toggles the lock; while the mouse moves it steers; the wheel moves the lock around you. **Sticky click:** a left or right click within 24 px of a foe's body follows that foe while the button is held.
- **When it ends:** the target dies (it moves to the nearest foe within 160 px, hunting first, unless the option is off); more than 480 px away or off screen for 0.5 s; rock in the way for 0.75 s (sampled every 16 px, ten times a second); fog above 0.8 for 1.5 s (a lock can't start there); the button; a menu (and the menu guard); a faint; fast travel; the target fading in held ground. The dark never breaks it. While a break timer runs the brackets open by 2 px.
- **Skills:** Lampfire and Lance aim at the target led by its speed (at most 48 px); the aim assist and the aim hold are off while locked. A Fireglobe lands on the target, led by half its flight, 60-280 px out (then the flare snap). The Beam turns toward it at up to 180 degrees a second. Dash and planting don't change. With auto-fire on, Lampfire streams at the lock while any fire button or the stick is down.
- **Y** takes any skill (§3.1). On a pad an aimed skill on Y fires at the lock, else at the best foe within 30 degrees, else straight. Keyboard F is unchanged (the mouse aims).
- **The marker:** four warm corner brackets `#ffd27a` around the foe (body + 6 px, 6 px arms, 2 px), drawn by the telegraph node on the fog layer above fog and foes; they snap in from +8 px over 0.1 s and never flash; a short warm bar under them while the target is lit; break: they open and fade over 0.2 s. The locked foe's bar always shows, with warm ticks; a locked Ashbrood gets warm brackets on the boss bar. Sound slot `lock_on`: a Kenney stand-in tick.
- **Options** (pause menu, "Target lock options"; saved in `user://settings.cfg`): Target lock (press to lock · auto · off), Next foe after a kill (on · off), Lock button (R3 · Y · L3; the button chosen is taken off what used it and given back later: with Y, slot 4 moves to R3 and the bar shows R3; with L3, the dev tuning panel keeps F1. The plan's back-paddle choice was left out: a standard pad has none), Lock marker (normal · large), the mouse's sticky click (on · off; also off with the lock set to Off), Aim assist (12 · 20 degrees · off; sets `kl_aim_assist_deg`). Auto picks the nearest foe hunting you within 400 px whenever you have no lock, wherever it stands (no cone). Y's auto-target follows the lock's rules (not in deep fog, not behind rock).

### 20.6 Performance (review fix)
- A foe works its light state out every 3rd frame, staggered (`Foe.LIGHT_EVERY`), and a hit reuses it (worked out again only when it is older than that, or a lamp lit, went out or flared). Lamp lights sit in a coarse grid in `LightSense` (`lit_source`), and the keeper's fire gathers lamp flames once a tick into a 128 px grid, so a bolt only looks at nearby flames.
- The bench (30 lamps, 20 foes, 40 bolts, same machine): the base before M1c 2.00 ms average; M1c as first built 3.11 ms; after the fix about 2.3 ms. 6 lamps and 40 bolts: about 1.7 ms.

### 20.7 The damage fix (owner, M1b playtest)
- The owner: "the Clinker did less damage to me than a couple of Wicklings, they fried me". Cause: each touching Wickling drained 30 warmth a second, stacking; the Clinker's roll did 25 once; foe level scaled only health.
- Now a touching Wickling chills **5 every 0.5 s** (`kl_wick_chill_hit`, `kl_wick_chill_tick`; an elite x1.6), and every touching Wickling shares one budget that refills at **28 a second** (`kl_swarm_chill_cap`, holding at most half a second of it, `kl_swarm_chill_burst`). Measured in `test_fights`, no dodging: one Wickling about 10 s to a faint (was 3.3 s), three 3.9 s (was 1.1 s), seven 3.9 s.
- The Clinker's roll: **30** (`kl_clinker_hit_warmth`, was 25), x1.24 at Lv 4 = 37, the hardest single hit in the Hollow (the Ashbrood's dive is 33), and it throws the keeper 120 px out of its lane (`kl_clinker_knock`).
- **Foe damage grows 8% a level** over 1 (`kl_foe_dmg_per_level`; `Foe.dmg_level_mult()`): touch ticks, spit, the Clinker, every Ashbrood attack.
- A chill of 10 or more is a hit: shake and the cold flash (`kl_hurt_shake_min`; was 5), so touch ticks don't shake the screen.

## 21. Builds — BUILT (M2)

From GAME_PLAN §4.2-§4.3, §9, §14, §18 "M2: Builds", PLAN_LANTERNS §8 ("Where parts 3 and 4 slot in"), and the owner's M1c playtest (the Ashbrood's phase 2, standing at your own lamp). On `proto/kl-m2`. Every number is a `kl_` value in the tuning panel (L3); every text is DRAFT in STORY §17.

### 21.1 Skill points, tiers and respec (`systems/progress.gd`, `systems/skill_tree.gd`)
- A level-up gives **one skill point** (`kl_points_per_level`): 11 by level 12. The card screen is gone; a level-up is a chime, a line on the tip strip and "+N" on the HUD's level ("Lv 3 +1") and on the pack's Skills tab. Nothing pauses.
- **Six trees** (the Beam and Hearth ring too, since both are still kept; DECISIONS), three tiers each, one pick a tier: **42 picks** (STORY §17.1). Tier 1 opens with the skill (Lance at level 2), tier 2 at level 4 (`kl_tier2_level`), tier 3 when the Ashbrood falls (`Progress.tier3_open`).
- **Respec:** resting at a lit WayLamp (`player.rest()`) opens respec while you stay within `kl_respec_radius` (220 px) and aren't hunted. Then another pick in a taken tier swaps in for free, A on a taken pick gives it back, and a row resets every pick. Walking away closes it.
- **The old cards** (GAME_PLAN §4.3): each card is now its pick (`SkillTree.CARD_TO_PICK`; Heavy flare is Heavy ring). Kindled kills, Hot core and Lee wait for gear (M3); a version 7 save that had them keeps them as carried **lines** (`Progress.lines`). A new game can't get them until M3.

### 21.2 What each pick does (`fire_bolts.gd`, the skill scripts, `combat.gd`, `foe.gd`; `test_builds`)
- **Lampfire.** T1 *Lingering burn* (a hit foe burns 2 s at 2) / *Scatter* (3 sparks of 1 fly off the burst, not back into the foe). T2 *Twin* (two bolts at ±8°, x0.65 each) / *Skip* (a hit jumps to the nearest other foe within 140 px at x0.75). T3 *Catching* (a kill sets the nearest foe within 60 px alight) / *Needle* (passes the first foe, hitting it, and bursts on the second) / *Comet* (every 4th bolt: x2 damage and splash).
- **Fireglobe.** T1 *Skipping globe* (hops 100 px on and bursts again at x0.7) / *Slick* (its burning ground slows foes 40%; not the Clinker or the Ashbrood). T2 *Second globe* (a x0.6 globe 0.3 s behind) / *Fire line* (3 x0.6 bursts across the aim, 64 px apart). T3 *Cluster* (4 small globes of 3 out 70 px) / *Beacon* (a 110 px light for 6 s that **counts as lit**; `KeeperLight`) / *Undertow* (pulls foes within 1.7x its radius 50 px in before the blast).
- **Lance.** T1 *Burning line* (2 s of fire on its path, 2 a second) / *Brand* (the next hit on the foe it struck: x1.5, once). T2 *Returning* (at its reach it flies back toward you, through foes again) / *Forked* (two x0.6 lances at ±25° from the first hit). T3 *Breaking* (3 Lampfire bolts at its end) / *Held lance* (Lance becomes held: hold 0.6 s and let go for x2 damage through everything; a short press is a normal Lance; a ring fills at the hand lamp) / *Shatter* (a shell it breaks bursts for 4 in 60 px).
- **Dash.** T1 *Second step* (two dashes a cooldown) / *Cinder trail* (small burning patches along the dash). T2 *Phase* (foes on the path stunned 0.4 s) / *Flame step* (a 70 px fire ring of 2 where it ends). T3 *Ember rest* (a 90 px ember for 3 s where it ends that **counts as lit**) / *Blink* (an instant 150 px step, short of rock, with the dash's guard) / *Recoil* (a dash against your aim throws 3 Lampfire bolts along it).
- **The Beam** (the approved cards). T1 *Steady hand* / *Long throw*. T2 *Deep tank* / *Tight focus*. T3 *Prism* (three thin beams at ±12°, x0.5 each) / *Searing* (on one foe, up to +50% over 1.5 s) / *Stoking* (each second on a foe takes 1 s off Fireglobe's cooldown).
- **Hearth ring.** T1 *Heavy ring* (push 140 px, stun 0.6 s: the old Heavy flare) / *Lasting ring* (its ground burns 3 s). T2 *Spill* (approved) / *Warm ring* (+2 warmth per foe hit). T3 *Sunburst* (8 Lampfire bolts all around) / *Crackle* (strips 2 shell from each foe hit, not past the dark's floor) / *Rising ring* (a second ring rolls out to 220 px over 1 s).
- **Lamps** (PLAN_LANTERNS §8): Beacon and Ember rest are lights for the light rule only: they expose foes, clear fog, have no flame (no catch, flare or chain off your own fire), don't keep small dark out and have no core. A Lightless elite ignores them.

### 21.3 The pack (`scripts/ui/pack_screen.gd`, `skills_list.gd`, `journal.gd`, `map_screen.gd`)
- **View** (pad) or **I** opens it on Skills; K / D-pad down opens Skills, J opens the Journal, M / D-pad up opens the Map (from the world). Inside: **LB / RB** (Q / Tab) change tabs; on a keyboard K, J and M jump to a tab; B / Esc / Start / View closes. The D-pad never changes tabs. The world stays paused across tab changes.
- **Skills tab:** the bar's slots on top, the six skills on the left (the Beam and Hearth ring marked optional, last), the focused skill's tree on the right. D-pad up / down in a column, right into the tree, left back; **A on a skill**: choose its slot (left / right), A puts it there (A on its own slot takes it off), B backs out; **A on a pick** takes it. Greyed while hunted. With points to spend it opens on the first open tier of a skill **on the bar** (owner, 2026-11-28: nothing points at a skill that is off the bar).

### 21.4 Elite affixes (`scripts/enemies/wickling.gd`, `foe.gd`, `burst_hatch.gd`, `main.gd` `HOLLOW_AFFIXES`)
- One affix on each level-4 pack's elite in the Hollow (`kl_affix_min_level`; 2 from the marsh on, GAME_PLAN §8.1): *Swift* (x1.3 speed), *Thick shell* (x2), *Bursting* (as it dies, two 0.6 s spawn glows, then 2 summoned Wicklings; a faint clears them) and *Lightless* (lamps never light it, only dim; a lit lamp it comes within 40 px of flickers cold 0.5 s, then is snuffed 4 s). *Biting cold* (x1.5 chill) is built and tested; no Hollow elite has it (it waits for the marsh's two-affix elites).
- The affix line shows in the cold tell colour above the elite's name on its bar.

### 21.5 The Ashbrood: phase 2's new moves and phase 3 (`scripts/enemies/ashbrood.gd`, `cold_ember.gd`)
- **Health:** 300 / 300 / 220 a phase (`kl_ashbrood_hp`, `_hp2`, `_hp3`), x1.48 at Lv 5. `test_skills`' sum: about 3.3 minutes at L4 with a dodging keeper's windows; `test_ashbrood_kill`, constant fire with no dodging (shorter than a real fight): **108 s** with the rim lamp only (24 / 49 / 34 s), 124 s with Fireglobes in phase 1, and phase 3 in 42 s with no lamp at all.
- **Phase 2** alternates its dive (as M1c) with a new move, never the same new move twice running: the **ash wave** (a 60 px lane from it through you, 1.1 s, 14 warmth and a shove, then a wall of ash runs the lane), the **low pass** (a 56 px lane past you, 1.0 s, 16 warmth; it flies the lane in 0.45 s and leaves 4 **cold embers**, 26 px, which glow 0.5 s harmlessly, then chill 4 a tick for 4 s), and every 16 s it **calls 2 Wicklings from the dark** (spawn glows on your side; not while 3 of its brood are about). It recovers 0.6 s after a wave or pass.
- **Phase 3, "last of the brood":** after a 1.5 s rise (toast, STORY §17.5), wings cracked (pale cracks, warm over the bowl), every wind-up x0.8 (never under 0.5 s), and it fights in combos: it **returns to the bowl** (a landing circle on the WayLamp) and settles 2.5 s over the last ember, which shows through its cracked wings and **lights it** (the window that needs no lamp: no soft-lock), then **puffs**; it **dives** at a lit lamp (a 2.4 s sit) and sends **a wave** from where it lands; it **makes a pass** and throws **ash bolts** from the far end. Each cycle has the return, then the two combos in a random order.
- Every hit is a cold Telegraph marker equal to its hitbox; a dash avoids each; a faint during any of them (each phase, each move) resets the phase with no error (`test_fights`). It never waits more than about 2 s in any phase.

### 21.6 The catch distance (owner, M1c playtest)
- Standing at your own lamp made every Lampfire bolt catch. Now a bolt catches only once it has flown **72 px** (`kl_catch_min_travel`), past the keeper's own reach: a lamp at your feet never catches your bolts, one out ahead does (`test_combos`).

## 19. Measured numbers (built)

§19.1 is measured on `proto/kl-m1b` (M1b: the new curve, foe levels 1-4, scaling). §19.2's route is unchanged since c6d3ee0, apart from the foe levels.

### 19.1 Wick in the Hollow (M1b)

Fixed wick, before the level gap scales it: 25 packs of 88 foes, 12 nests, the Clinker, the Ashbrood and kindling. M1b set the curve to base 7, exponent 1.65 (GAME_PLAN §9), the Hollow's foes to Lv 1-4 (the Ashbrood Lv 5, its adds Lv 4), and **`kl_clinker_wick` 20 → 28**: with 20, a pure beeline went into the Ashbrood at L3 (64 of the 72 wick L4 needs), and its kill then gave two levels at once. With 28 (Lv 4: 49 wick) it goes in at L4 and the kill gives L5.

| | Pure beeline (the main route only) | Explorer (all of the Hollow, nearest first) |
|---|---|---|
| Level 2 | at the crook's guard (3rd fight) | at pack 23 (3rd fight, by the crook) |
| Level 3 | pack 2, before the Clinker | (passed on the Clinker) |
| Level 4 | the Clinker | the Clinker (its 5th stop) |
| Level 5 | the Ashbrood's kill | pack 3 (12th stop) |
| Into the Ashbrood | L4 | L5 |
| The kill | **L5** | **L6** |

A farmer who camps the hut row and the south reaches L4 in 9 minutes and is still L4 after 30, earning about 1.5 wick a minute in the last 10. The forward beeline reaches L5 in about 2 minutes on the test's rough walk-and-fight model (it counts no waking, no dodging and no rests: a floor, not a playtime).

### 19.2 The first 10 minutes (Option B)

The main route, as placed. Offsets are tiles from the hut's start tile (48,136), +x east, -y north. `test_prototype_onboarding.tscn` prints and checks them.

| Order | What | Offset | From the hut | Wakes at |
|---|---|---|---|---|
| 1 | The lone first Wickling (pack 20: 1 Wickling, Lv 1) | (-1, -10) | 10.0 | 5 tiles |
| 2 | **The north path's old lamp**, cold (a haven; goal `relight_waypost`) | (+2, -12) | 12.2 | - |
| 3 | The first pack (pack 23: 3 Wicklings, Lv 1) | (+5, -17) | 17.7 | 6 tiles |
| 4 | **Oswin's crook** (the Post Lamp find) with its small guard (one shelled Wickling, Lv 2) and a 6-scrap cache | (-1, -19) | 19.0 | 4 tiles (`kl_post_guard_wake_radius` 128 px) |
| 5 | **Nest A** (nest 4, Lv 2): the first lock the Post Lamp opens; goal `burn_nest` | (+2, -30) | 30.1 | 10 tiles |
| 6 | Pack 2 (4: one Spitwick, one shelled, Lv 3 since M1b; was 4) | (60,113) | | 10 tiles |
| 7 | The Clinker, a mid-boss (Lv 4) | (70,119) | | 7 tiles |
| 8 | The Hollow's WayLamp and the Ashbrood | (78,124), offset (+30, -12) | 32.3 | - |

**Rules the tests hold:** nothing wakes at the hut, its lantern, the woodpile, the scrap or the ledger. Only the lone Wickling is within 16 tiles of the hut. From the hut to the crook: at most 2 packs and 4 Wicklings, no Spitwick, no elite, no nest, no Clinker. The whole route wakes 3 of the 24 packs and 1 of the 12 nests; the rest is optional. No nest is within 28 tiles of the hut, and no Spitwick or elite pack within 25. The south of the Hollow is optional content (maybe Amos's side quest, M4).

Pack, nest and elite lures look different since M1b (§7.1). Timings are estimates, not a playtest.
