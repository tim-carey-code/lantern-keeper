# Lantern Keeper — Design Document

Synced to commit c6d3ee0 on `proto/kl-replan` (2026-11-27). Rewritten from the approved game plan, `docs/replan/GAME_PLAN.md` v2 (DECISIONS 2026-11-27, "the game plan approved"). **DRAFT for owner approval** (GAME_PLAN §17). The version before the rewrite is `docs/archive/DESIGN_PRE_REPLAN.md`.

> **How to read this doc**
> - **Built** means it is in the code at c6d3ee0. For what is built, the code wins over this doc.
> - **PLANNED (Mx)** means it is in the approved plan but not built. Mx is its milestone in `docs/ROADMAP.md`. **PLANNED (not placed)** means the plan names no milestone yet; ROADMAP lists these under "Not yet placed".
> - **To be cut (Mx)** marks something built that the plan removes in that milestone.
> - `docs/DECISIONS.md` wins over this doc for what was agreed. All player-facing text lives in `docs/STORY.md`.
> - Numbers are starting values for tuning. Names in `code font` are `systems/tuning.gd` entries; "(new)" marks one that doesn't exist yet. Numbers fixed in a script are marked *(code)*.
> - **Branches.** Everything action-RPG lives on the prototype line (`proto/kl-hollow` and the branches cut from it, now `proto/kl-replan`). `main` still has the older tending game with WayLamps and none of the action-RPG work. The plan merges to `main` once M1b passes. M1a is being built on `proto/kl-m1a`; nothing from it is described as built here.
> - Godot 4.7 (GDScript, Compatibility renderer) · 2D top-down · single-player · PC, Linux first · keyboard/mouse and gamepad.

---

## 1. Pitch and pillars

**Pitch.** You are the valley's new keeper. Your hand lamp throws fire-light. Burn back what lives in the fog, take the old WayLamps back one by one, and follow Oswin, the last keeper, to the cold great lamp at the Still Lake.

**Genre.** An action RPG (DECISIONS 2026-11-27, Hollow prototype playtest).

**Feeling:** calm, moody, curious, rewarding, with a quiet unease.

**Pillars** (GAME_PLAN §1):
1. **Light is your weapon.** Fireballs of light from the hand lamp, aimed with the right stick or the mouse. *Today the weapon is the beam, the burst and the dash (§4.1). The fire kit is PLANNED (M1a).*
2. **Light is your shelter, and you carry it.** Planted lamps and lit WayLamps are pockets where you refill. No upkeep. *Today lanterns still burn fuel and need tending. No upkeep is PLANNED (M1b).*
3. **The find is the key.** Each region's find is a lamp that opens its lock and answers one phase of its guardian. *Built for the Hollow (the Post Lamp burns nests).*
4. **Readable fights.** Every big hit has a tell. Every foe has a name, a level and a bar. *Built.*
5. **Every fight pays, once.** Fixed packs, level-gap wick, and loot that only fixed foes drop. Cleared ground stays cleared. *Packs and level-gap wick are built. Today a faint resets cleared packs (§12.3); the fix is PLANNED (M1b). Loot is PLANNED (M3).*
6. **Calm at the edges.** A calm start, quiet held ground, no game over. *Built.*
7. **Show, don't list.** Lures through the fog and short notes pull you on. *Built; lures that look different are PLANNED (M1b).*

**What the plan removes:** lamp tending, gathering, "planning over reflexes", "light is safety" and the quiet finale.

---

## 2. The core loop

**Today (built).** You fight with the beam, burst and dash, on lamp charge. You gather fuel, scrap and glass, build lanterns and keep them fed. In the Hollow you clear fixed packs and nests, take the Post Lamp from Oswin's crook, beat the Clinker, and feed the Hollow's WayLamp 15 fuel to wake the Ashbrood. Each level-up offers three cards. Lit WayLamps are fast travel. The Reedmarsh and the Ridge are open, with landmarks and WayLamps but no action-RPG foes yet.

**The plan** (GAME_PLAN §2):

| Scale | What you do | What you get |
|---|---|---|
| **A minute** | Aim. Stream Lampfire, which also refills charge. Spend charge on Fireglobe or Lance. Dash through the tell. Drink when low. Step into light between fights. | Wick, scrap, oil, sometimes an item |
| **A session (15-30 min)** | Rest at a lit WayLamp (full flasks). Push toward a lure. Clear 3-5 packs and an elite. Swap gear, spend a point. Reach the find or the next WayLamp and fight its guardian. Travel back to a person, or go on. | A level or two, a few items, a region held |
| **The whole game** | Five regions on one clockwise loop. Each has a find, a twist, a mid-boss, a guardian and a new skill or relic. Levels 1-12. The Soul of the Wick retreats through a portal. The valley stays open. | The great lamp relit, and a hook for later |

M1a exists to make the minute-scale loop feel good.

---

## 3. Controls

### 3.1 Built today

Button letters follow the device you used last (E on keyboard, A on a pad). The cursor hides when you aren't using the mouse. Input actions come from `tools/setup_input.gd`.

| Action | Keyboard / mouse | Gamepad |
|---|---|---|
| Move | WASD / arrows | Left stick / D-pad |
| Aim | Mouse | Right stick (else where you face) |
| Beam (hold) | Left mouse | RT |
| Burst | F | RB |
| Dash | Shift | LT |
| Interact: read, refuel or relight, turn a mirror right, travel; hold to gather | E | A |
| Build the selected lantern; next to a mirror, turn it left | Space | X |
| Pick up a lantern; close menus | Q / right mouse | B |
| Lantern list (tap to switch, hold to open); pick directly | Tab; 1-4 | Y |
| Map / Journal / Pause | M / J / Esc | LB / View / Start |
| Fullscreen; tuning panel (dev) | F11; F1 | —; L3 |

The hold-to-ward glow is still in the code (`player.gd` `update_ward()`), but nothing calls it in play. **To be cut (M1b).**

### 3.2 The planned pad map — PLANNED (M1a)

Twin-stick aim: the left thumb moves, the right thumb aims. RT, RB, LB and LT work while you aim. Y and B take the right thumb off the stick, so they hold only things that don't aim.

| Slot | Pad | Keyboard / mouse | Default | Rule |
|---|---|---|---|---|
| 1, basic | **RT** (hold) | Left mouse (hold) | Lampfire | Always Lampfire |
| 2 | **RB** | Right mouse | Fireglobe | Aimed skills |
| 3 | **LB** | Q | The Beam at level 1, then Lance | Aimed skills |
| 4 | **Y** | F | empty | **Self-cast skills only** (Hearth ring, Moth-lights) |
| Dash | **LT** | Space (Shift too) | Dash | Along your movement |
| Flask | **B** | R | Lamp oil | Read after the menu guard |

| Out of a fight | Pad | Keyboard / mouse |
|---|---|---|
| Interact, read, talk, rest, travel; turn a mirror right; hold to pick up your lamp | A | E |
| Plant a lamp; next to a mirror, turn it left | X | C |
| Next / previous lamp kind | D-pad right / left | Tab / Shift+Tab |
| Map; the keeper's pack (Gear, Skills, Journal, Map); pause | D-pad up; View; Start | M; I, K, J; Esc |

- **Aim hold.** While RT, RB or LB is held, a released right stick keeps its last aim (`kl_aim_hold`, new). So drinking mid-stream doesn't swing your fire. Today, releasing the stick snaps aim to your walking direction.
- **The input guard.** The flask and all combat input are read after `Progress.block_input()`. Then the B that closes a menu never drinks. A test checks every menu.
- **The D-pad** comes off movement. Map and lamp cycling are read only while no menu is open.
- **Aim assist** on pad: a gentle pull within 12 degrees, for Lampfire and Lance.
- **Pick-up** moves to "hold E / A", because right mouse becomes slot 2.
- **Cooldowns** show as a dark radial sweep, with seconds if more than 3 are left. A slot greys out when you're short of charge. The flask shows pips.
- **The L3 tuning panel** goes behind a dev-build flag. PLANNED (not placed; likely with the M1a input work).
- **Auto-fire option:** Lampfire fires whenever the right stick is pushed past 0.8. PLANNED (later; the M1a fallback if RT and RB on one finger is a problem).
- **Binding:** pick a slot in the Skills tab, then a skill. The tab is greyed while you're hunted, with the reason shown. A plain Skills list in M1a; the full tab in M2.

---

## 4. Combat and skills

### 4.1 Built today

The combat kit is in `scripts/player/combat.gd`. **Lamp charge** (0 to 1) pays for all three moves, and it is also how far your hand lamp lights.

| Move | Input | Numbers | Notes |
|---|---|---|---|
| **Beam** | hold left mouse / RT, aimed | 240 x 24 px, 6 hp/s, 0.3 charge/s, walk at 70% (`kl_beam_*`) | Lights the fog along its path. With mirror beams, the only thing that wears a shell. |
| **Burst** | F / RB | 120 px, 2 dmg, throws foes 140 px, 3 s cooldown, 0.2 charge (`kl_burst_*`) | Shells turn it aside. |
| **Dash** | Shift / LT | 110 px in 0.16 s, 0.9 s cooldown, 0.08 charge (`kl_dash_*`) | Nothing can chill you mid-dash. |

- Two small arcs under the keeper show the burst and dash cooldowns. There is no action bar.
- **Feedback:** foes flash when hit; the burst, kills and big hits shake the screen (`kl_shake_px`); a kill freezes the whole game for a moment (`Engine.time_scale`). Hurt foes and big ones show a name, a level and a health bar, with the shell as a pale bar above. The Ashbrood has a boss bar with its phase and a one-line hint.
- **Shells** (`foe.gd`): only the beam and mirror beams wear one down. A shell on the Clinker or the Ashbrood grows back after 3 s without a beam hit (`kl_shell_regrow_wait`, `kl_shell_regrow_per_sec`).

### 4.2 The planned kit — PLANNED (M1a; Moth-lights M5; Wheeling flame M6)

| Skill | Gets it | Slot | Does | Starting numbers | Shells |
|---|---|---|---|---|---|
| **Lampfire** (basic) | level 1 | RT | A fireball of light. Short trail, bursts on impact with a small splash, impact flash, and a brief light pop that clears fog. Free; each hit gives charge. | 2 dmg on the hit and 1 to others within 40 px, one per 0.35 s held (5.7 dps), 480 px/s, 320 px, +0.03 charge a hit (`kl_lampfire_*`, new) | half (the hit only) |
| **Fireglobe** | level 1 | RB | The big lobbed fireball. Arcs to where you aim, bursts, and leaves burning ground. | 8 dmg in 90 px, then 3 s at 2 dps; lands 120-280 px out (stick tilt, or the cursor); 0.6 s flight with a ground marker; 0.3 charge; 5 s cooldown (`kl_fireglobe_*`, new) | none |
| **Lance** | level 2 | LB | A fast piercing bolt: the shell-breaker. | 5 dmg, pierces 3, 700 px/s, 360 px, 0.2 charge, 0.5 s cooldown (`kl_lance_*`, new) | full |
| **Beam** (optional) | level 1 | LB / RB | The built beam, channelled. | 7.5 hp/s (was 6), 0.3 charge/s, 240 x 24 px, walk 70% (`kl_beam_*`) | full |
| **Hearth ring** (optional) | level 1 | Y | The old burst, reworked: a ring of flame that sets foes alight, with a small push. | 2 dmg and 1 dps for 2 s, 120 px, push 60 px (was 140), 4 s cooldown, 0.2 charge (`kl_burst_*`) | none |
| **Moth-lights** | level 7 (the marsh) | Y | Three motes circle you, then seek foes. | 3 dmg each, seek 240 px, 4 s, 0.25 charge, 5 s cooldown (`kl_moth_*`, new) | half |
| **Wheeling flame** | level 9 (the Ridge) | RB / LB | A disc of fire that flies out 280 px and comes back, hitting both ways. | 4 dmg a pass, 0.25 charge, 3 s cooldown (`kl_wheel_*`, new) | half |
| **Dash** | level 1 | LT | The built dash; no chill mid-dash. | 110 px in 0.16 s, 0.9 s cooldown, 0.08 charge (`kl_dash_*`) | — |

**The default bar (M1a).**
- **Level 1:** RT Lampfire, RB Fireglobe, LB the Beam, Y empty. The Beam sits in LB only so the owner tries it from the first fight ("keep as optional for now").
- **Level 2:** Lance takes LB, and a toast says the Beam is in the Skills tab. One press puts it back.
- Hearth ring is in the Skills tab from level 1 and is never on the default bar. Y stays empty until you choose Hearth ring or get Moth-lights.
- **The M1a playtest decides** whether the Beam and Hearth ring stay (ROADMAP M1a, checks 8 and 9).

**Lance and the Beam are equal per charge:** 5 / 0.2 = 25 damage per charge, and 7.5 / 0.3 = 25. Lance hits harder in bursts and pierces 3; its cooldown caps it at 10 dps. The Beam has no travel time and hits everything on its line, but slows you and stops light regen.

### 4.3 Branches instead of cards — PLANNED (M2)

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

### 4.5 The shell rule — PLANNED (M1a)

- **Full damage:** Lance, the Beam, mirror beams, and Wheeling flame's *Cleaver*.
- **Half damage:** Lampfire's hit, Moth-lights and Wheeling flame.
- **None:** Fireglobe, Hearth ring, splash, burning ground and lamp cores. They glance off (as built).
- Shells on elites never grow back once dented. Shells on the Clinker and the Ashbrood grow back after 3 s without a hit, until they break, and a broken shell stays broken (`shell_regrows`, `foe.gd`; `kl_shell_regrow_wait`).

### 4.6 Time to kill — PLANNED (M1a sets the Clinker and Ashbrood by hand; M1b adds scaling)

**Targets:** a same-level Wickling dies to 2 Lampfire hits; a shelled elite takes 3-5 s; a plain pack 2-5 s; a mixed pack 8-12 s; a mid-boss about 30 s; a guardian 2-4 minutes.

**Scaling (M1b):** foes +12% health and shell per level over 1 (`kl_foe_hp_per_level`, new); the keeper +10% damage per level (`kl_dmg_per_level`, new); gear covers the gap. **Charge while hunted:** 0.06 base + 0.086 from Lampfire hits + 0.1 in light = about 0.25/s.

| Fight | Foe | Keeper | Working | Time |
|---|---|---|---|---|
| A Wickling, Lv 1 | 3 hp | L1, Lampfire 2 a hit | 2 hits, 0.35 s apart. At L12: 2 x 4.2 = 8.4 against 6.96 hp, still 2 | under 1 s |
| The crook's guard (shelled, Lv 2) | hp 9 x 1.12 = 10.1, shell 4.5 | L1, Lampfire only | shell at 1 a hit: 5 hits; hp at 2 a hit: 6 hits; 11 hits at 2.86/s | about 3.5 s |
| Pack 2, Lv 4: 2 Wicklings, a Spitwick, an elite | 4.1, 4.1, 5.4, and 12.2 + 5.4 shell | L3 (x1.2): Fireglobe 9.6, Lance 6, Lampfire 2.4 | one Fireglobe kills both Wicklings; 3 Lances (0.6 charge, 1 s) kill the elite; 3 Lampfire hits kill the Spitwick | 3 s of damage; 8-12 s with waking, spit and walking |
| The Clinker, Lv 4 (`kl_clinker_hp` 24 → **48**) | 65 hp, 16.3 shell, regrowing | L4: Lampfire 7.4 dps; Lance 6.5 per 0.2 charge | about 12 dps on health and 8 on shell: about 7.5 s of damage; it rolls and you dodge, so about 25% uptime | about 30 s |
| The Ashbrood, Lv 5, 3 phases (`kl_ashbrood_hp` 40 → **150** per phase, shell 12) | per phase 222 hp and 17.8 shell | L5: Lampfire 8 dps, plus Lance at about 1.25 a second from charge income (8.75 dps) | about 17 dps: 14 s a phase, 43 s in all; adds, puffs and dives leave about 35% uptime | about 2 minutes (2.6 without a lamp nearby) |

These assume linear scaling and the stated uptimes. They are the plan's arithmetic, not measurements.

---

## 5. Resources

### 5.1 Built today

- **Warmth** is the keeper's health: 100, +20 per second in lantern or WayLamp light only (`warmth_*`). A Wickling's touch takes 30 per second.
- **Lamp charge** runs 0 to 1. It pays for the beam, burst and dash, and sets the hand lamp's light: 104 px full, down to a 44 px ember (`hand_lamp_*`). In the dark it dims to an ember over 45 s. It refills 0.5 per second in lantern or WayLamp light (within 85% of a lit lantern's radius *(code)*), but not while beaming. Under 0.25 charge, 4 s after your last action, it burns 1 carried fuel for 0.5 charge (`player.gd:69`). It never goes out.
- **Fuel:** resin from dead trees (Hollow), peat (Reedmarsh), fuel spots (Ridge), the hut woodpile (regrows every 10 s, even in the dark), caches, and an ember from every kill. 1 carried fuel = 10 lantern fuel.
- **Scrap:** ruins, caches, the hut pile, and a 35% chance from each kill. Pays for lanterns.
- **Glass:** the Ridge only (56 spots, 2 caches). Pays for the Hooded Lamp and the Mirror Post.
- **Gathering:** hold E / A on a revealed spot for 1 unit per 0.25 s. Spots regrow while lit *(code)*. You carry 30 of each *(code)*.
- **Upgrade finds** (one of each per region, in far corners): a **keeper's satchel** (+10 carry of each) and a **lamp glass** (the hand lamp reaches 12 px further and dims 25% slower; its ward discount does nothing now, since the ward is unused) (`carry_*`, `lamp_upgrade_*`).

### 5.2 The plan — PLANNED (M1a unless marked)

**Light and regen in one place (M1a):**

| | Out of a fight | While hunted |
|---|---|---|
| Warmth in light | +20/s (`warmth_regen_per_sec`) | **none** |
| Charge in light | +0.5/s (`hand_lamp_recharge_per_sec`) | **+0.1/s** (`kl_light_charge_hunted`, new) |
| Charge anywhere | +0.06/s (`kl_charge_regen`, new) | +0.06/s |
| Lampfire hit | +0.03 charge | +0.03 charge |
| While the Beam is on | no charge from light; base +0.06/s continues | same |

- "Light" means a planted lamp, a lit old lamp, a lit WayLamp, a Fireglobe *Beacon* or the Dash's *Ember rest*.
- **Hunted** means an awake foe has you as its target within 12 tiles (`travel_hunt_radius`, 384 px). A timid Wickling waiting at your light's edge counts, so you clear the area before you rest.
- **Why:** with free healing in a fight, players run off to heal instead of drinking. Fast refills out of a fight keep light a shelter.

**Warmth** is 100 at level 1, +8 a level (`kl_warmth_per_level`, new). Foe damage rises 8% a level (`kl_foe_dmg_per_level`, new) to match. PLANNED (not placed; it belongs with the M1b scaling).

**Lamp charge** runs 0 to 1.0, +0.1 per lamp glass (`lamp_upgrade_charge`, new; M1b). It still sets how far the hand lamp lights. **To be cut (M1a/M1b):** the passive dimming (`hand_lamp_drain_per_sec`) and the fuel top-up (`player.gd:69`).

**Lamp-oil flasks (M1a):**

| | Value |
|---|---|
| Charges | 3 to start (`kl_flask_max`, new); +1 from Maud (M5); +1 from a coat line (M3); at most 5 |
| Effect | Heals 40% of max warmth at once and gives +0.4 charge (`kl_flask_heal`, `kl_flask_charge`, new). 1 s lockout |
| Rest at a lit WayLamp | Refills all. Blocked while hunted |
| Drops | A cleared pack's last foe drops 1 oil. Elites: 30% chance. A mid-boss: 1 at half health. A guardian: 1 at the half of each phase (`kl_boss_oil_step` 0.5, new) |
| Timer refill | None. You can always rest in light out of a fight |

**What fuel, glass and scrap become (M1b).** **Fuel** stops being a resource: oil exists only as flask charges and drops; fuel spots and peat become scenery or go. **Glass** stops being a resource: lamp costs fold into scrap, and the glass racks stay as Ridge story. **Scrap** is the one material: ruins become one-off piles taken with one press. Scrap also comes from drops, caches and salvage (M3), and pays for lamps, Amos's stock (M4) and Kit's re-cut (M6, a cut line). No carry cap.

---

## 6. Lanterns

### 6.1 Built today

Space / X builds the selected lantern on your tile: firm ground (not rock or soft marsh), anywhere you can stand (no "too dark" rule), at least 1.5 tiles from other lanterns *(code)*, not on a resource, not within 160 px of a WayLamp. Building is quiet: no outline or cost text until you try; a failed build shows the outline and the reason for 2 s. Q / B picks a lantern up for half its cost (rounded down) plus its fuel. The Post Lamp is locked at the start; reading Oswin's crook unlocks it.

| | Post Lamp | Reservoir Lamp | Hooded Lamp | Mirror Post |
|---|---|---|---|---|
| **Cost** | 5 scrap | 8 scrap | 5 scrap + 2 glass | 4 scrap + 3 glass |
| **Tank, burn** | 100, 0.5/s (about 3.3 min) | 200, 0.3/s (about 11 min) | 100, 0.5/s | none |
| **Light** | 224 px, shrinks to 40% | 200 px, dim, shrinks to 60% | 180 px, shrinks to 40% | 40 px glow + beam |
| **Wind** | exposed | exposed | immune | immune |
| **Unlocked at** | Oswin's crook | the pumphouse | the glazier's workshop | the signal station |

- **Tending:** E / A pours carried fuel in. An empty lantern goes cold but keeps its frame, shown through fog with a red pulse. Below 25% it is **dying**: a red bar and a sputter, and Wicklings can drain it if no healthy light covers it. Cold and low lanterns are flagged on the HUD, at the screen edge and on the map.
- **Reservoir Lamp:** feeds 0.75 fuel per second to each other fuel lantern in its light, lit or cold.
- **Lantern cores** (the inner 45% of the light) burn small foes (2 hp/s) and are the only thing that hurts a nest. Elites, the Clinker and the Ashbrood ignore lanterns.
- **Mirror Post:** catches light within 90% of a burning lantern's radius, or in another catching mirror's beam. Its beam is 352 x 48 px in one of 8 directions; rock stops it. Beams clear fog and burn Wicklings at 3.5 hp/s. A Wickling clinging to a lit mirror smothers it and cuts the chain after it.
- **Wind:** valley-wide gusts (30-55 s of calm, a 5 s warning, a 10 s gust) make exposed fuel lanterns burn 3x and shrink to 70%. On the Ridge a constant west wind adds 1.6x burn and 85% light, and gusts come every 12-22 s. Rock 1-2 tiles upwind shelters a lantern.
- **Held region:** see §12.4.

### 6.2 After tending — PLANNED (M1b unless marked)

**What a planted lamp does.** It never burns down and shines at full radius. Its light gives charge and, out of a fight, warmth (§5.2). Timid foes stay out, and brave ones burn after 2.5 s (as built). Its core burns small foes and nests (as built). It clears fog (as built). You wake by it after a faint.

**Limits and cost.** At most 3 lamps in regions not yet held (`kl_lamp_limit`, new); no limit in held regions. Picking a lamp up refunds all its scrap, but you can't plant again for 15 s (`kl_lamp_replant_cd`, new), so you can't drag a haven through a fight. Building stays quiet.

| Piece | Verdict | New job, and why |
|---|---|---|
| Post Lamp | **keep** | The Hollow's find: haven and nest-burner. 5 scrap. |
| Reservoir Lamp | **repurpose (M5)** | The marsh's find: a wide dim light (200 px) with no core that forces things in water up (Slowwater, the Sump). Feeding is cut. 8 scrap. |
| Hooded Lamp | **repurpose (M6)** | The Ridge's find: the only lamp a gust can't snuff. Diving Gutterkites snag on it. 7 scrap. |
| Mirror Post | **repurpose (M7)** | The Lakeshore's find: a fixed beam that cuts fog, wears shells and makes your fire burst where it crosses. 8 scrap. Its unlock moves from the signal station to the Lakeshore (DECISIONS #36). |
| Wind | **repurpose (M6)** | Ridge only. Gusts snuff exposed Post and Reservoir Lamps until the gust ends (they relight themselves) and push projectiles downwind. Valley-wide gusts are cut. Inert from M1b until M6. |
| Old cold lamps (hut, north path) | **keep, no fuel** | Relit by touch: a haven and an early win. |
| Cold-lantern markers, low pulses, chips | **cut** | Nothing goes cold. The cold-frame lure stays for unlit old lamps. |
| Woodpile | **cut as a source** | Scenery. It existed to prevent a fuel soft-lock. |
| WayLamps refilling lamps | **cut** | Nothing to refill. Held ground is safe, with no lamp limit, plus rest and travel. |
| Dying lamps; Wicklings draining them | **cut** | Wicklings hunt the keeper. Mirror smothering stays, for the Lake. |
| The Ashbrood's dive emptying a lamp | **repurpose** | Its dive snuffs a lamp for 8 s. |
| Embers (+1 fuel) | **repurpose** | Their glow and 140 px magnet become the pickup for scrap, oil and items. |
| Refuel, relight with fuel, hold to gather | **cut** | No tending. |

---

## 7. Fog and light

### 7.1 Built today

- The valley is 224 x 200 tiles of 32 px *(code)*, each with fog from 0 (clear) to 1.
- Light clears fog (up to 0.8 per second). Unlit tiles fog back in (up to 0.05 per second, fastest next to fog). The Reedmarsh fogs back 1.8x as fast; gusts make it 1.5x everywhere.
- A tile once clearer than 0.3 is **remembered** *(code)*: a dim blue haze on screen and map. Never-seen ground is near-black.
- Resources and landmarks show only below 0.35 fog *(code)*. Building doesn't check fog. Full fog slows walking to 60% (`fog_slow_min`).
- **Lures** (`scripts/world/post_lure.gd`): sleeping packs pulse through the fog, nests glow, the crook has a red pulse, cold lanterns keep a cold frame. Packs and nests look alike. Caches and upgrade finds have no lure.

### 7.2 The plan

- **Your fire lights the fog.** Lampfire's light pop, Lance and Fireglobe are small lights of about 40 px while they fly (group `light_source`), so you can throw a Fireglobe into the dark to see what's there. PLANNED (M1a).
- Fog slows walking to 85% at most, not 60% (`fog_slow_min`). PLANNED (not placed).
- **The Lakeshore's thick fog** clears at a quarter speed for your fire, and at the usual speed for mirror beams, the Beam and WayLamps. PLANNED (M7).
- **Lures you can tell apart.** PLANNED (M1b).

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
| **Wickling** | `wickling.gd` | 3 hp, 65 px/s | About half are timid and stay out of healthy light; brave ones walk in, burn after 2.5 s at 1.5 hp/s and run (`kl_timid_share`, `kl_light_tolerance`, `kl_light_burn_dps`). Touch chills 30 warmth/s. Drains a dying lantern no healthy light covers; smothers mirrors in the dark. |
| **Shelled Wickling** (elite) | `wickling.gd` | 9 hp + 4 shell, 48 px/s, chill x1.6 | Only in packs, and on Oswin's crook. Ignores lanterns. |
| **Spitwick** | `spitwick.gd`, `spit_projectile.gd` | 4 hp | Keeps 190-250 px off. A slow spit after a 0.6 s tell: 12 warmth and 0.1 charge. |
| **Nest** | `wick_nest.gd` | 12 hp | Only a lantern's core hurts it (2 hp/s). Hatches 3 Wicklings every 10 s while you are within 320 px. |
| **Clinker** (mid-boss) | `clinker.gd` | 24 hp + 12 shell (regrows), Lv 4 | Sleeps at its post (wake 224 px, leash 480 px). Rolls after a 0.8 s tell for 25 warmth. Ignores lanterns. At (70,119), 9.4 tiles before the WayLamp. |
| **The Ashbrood** (guardian) | `ashbrood.gd`, `waylamp.gd` | 40 hp + 12 shell a phase, two phases, Lv 7 | Wakes when you kindle the Hollow's WayLamp. Phase 1: in the bowl; an ash puff every 7 s drops your lamp to 0.1 charge; a pack of 3 adds (Lv 5) every 8 s. Phase 2: it dives at the nearest lit lantern, empties it and sits for 4 s. Its kill holds the Hollow. No phase 3. |

- **Packs:** 24 fixed packs plus the crook's guard (88 foes: 7 Spitwicks, 6 shelled), and 12 nests (tables in `main.gd`). A pack sleeps until you come within 320 px (`kl_pack_wake_radius`); the first two route packs wake at 5-6 tiles and the guard at 4. Fixed foes stay dead (`Progress.cleared`), but **a faint resets every cleared pack** (`player.gd:211-213`).
- **Foe levels:** Lv 1 on the hut row and south, 2-4 through the middle, 5-6 by the WayLamp. The guard is Lv 2, the Clinker Lv 4, the Ashbrood Lv 7 and its adds Lv 5. Hatchlings take their nest's level; the swarm at a guardian-less WayLamp is Lv 6. Levels change only the wick a foe pays (§9.1).
- **A calm start:** nothing wakes at the hut, its lantern, the woodpile, the scrap or the ledger. Only the lone first Wickling is within 16 tiles.
- **Drops** (`ember.gd`, `foe.gd` `_drop()`): every kill drops an ember worth 1 fuel (it glows, drifts to you from 140 px and fades after 30 s), and a 35% chance of 1 scrap. No items.
- **Uncertain:** no code was found that restarts the Ashbrood's phase when the keeper faints (AUDIT M18; searched, not run). The plan makes it a rule in M1b (§12.4).

### 8.2 The plan

- **Packs and nests** keep working as built: fixed, asleep until you come close, never respawning on a timer. Nests are burned only by lamp cores; the Post Lamp is their key.
- **Elite affixes** (M2): 1 in the Hollow from level-4 packs, 2 from the marsh on: **Swift** (+30% speed), **Biting cold** (+50% chill), **Bursting** (2 Wicklings when it dies), **Thick shell** (x2), **Lightless** (ignores light, snuffs lamps it passes for 4 s). Shown under the name.
- **Scaling** (M1b): §4.6. **One projectile system** (M1a) serves the keeper and foes, the Spitwick's spit included.
- **Summoned foes drop nothing** (M1a for oil and scrap; M3 for items): nest hatchlings and the Ashbrood's adds still pay wick, which the level gap limits.
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

---

## 9. Leveling

### 9.1 Built today

- **Wick** is the XP. Wick from level L to L+1 is `round(kl_wick_base x L ^ kl_wick_exp)` with base 6 and exponent 1.25 (`Progress.wick_for_level`): 6, 14, 24, 34, 45, 56, 68, 81, 94... Capped at level 12 (`kl_level_cap`); at the cap the HUD says "max".
- **Base wick per kill** (`kl_*_wick`): Wickling 1, Spitwick 2, shelled Wickling 3, nest 5, Clinker 20, Ashbrood 32. Kindling a WayLamp pays 10 (`kl_wick_kindle`).
- **Level-gap wick** (`Progress.kill_wick`, `Progress.wick_gap_mult`): wick = base x (1 + 0.25 x (foe level - 1)) x gap factor, where gap = keeper level - foe level. The factor is 1 up to 1 level over the foe (`kl_xp_band`), then x0.25 per level past that (`kl_xp_falloff`: 1/4, 1/16, 1/64), and 0 at 5 or more (`kl_xp_zero_gap`). A foe above you pays +10% a level, at most +30% (`kl_xp_bonus`, `kl_xp_bonus_max`). Fractions carry over and are saved. Hatched, called and re-fought foes pay like any other foe of their level; the gap is what stops farming.
- **Measured** (`tools/tests/test_leveling.tscn`, after the loop): beeline and explorer both reach level 2 at the find, level 3 at pack 2, level 4 on the Clinker, level 7 into the Ashbrood and **level 8 on its kill**. The forward run takes about 13 minutes on the test's walk-and-fight estimate. Farming stalls: level 5 only at 25 minutes.
- **Level-up cards** (`scripts/ui/level_up.gd`): a level-up pauses the world and offers 3 of 12 cards ("Trim the wick"). All 12 change real numbers. Texts: STORY.md §12.
- **What you see:** "Lv 3", a wick bar and "12/24" on the HUD; name bars "Wickling Lv 2", dimmed when the foe pays less than full; a kill floats "+2 wick", grey when the gap cut it. A chime on level-up.

### 9.2 The plan — PLANNED (M1b; skill points M2)

- **Keep the level-gap wick exactly as built.** Cap 12.
- **The curve:** base 7, exponent 1.65 (`kl_wick_base`, `kl_wick_exp`): 7, 22, 43, 69, 100, 135, 174, 216, 263, 313, 366.
- **The Hollow ends at level 6** (5 on a pure beeline), not 8. Its last level still comes on the Ashbrood kill (DECISIONS #17, kept). Level 2 still comes at the crook. `test_leveling` checks both routes.
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

**Built today:** no items, no inventory screen, no add-ons. Kills drop embers (fuel) and sometimes scrap.

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

- **Three WayLamps** (`scripts/world/waylamp.gd`): the Hollow (78,124), the Reedmarsh (200,140), the Ridge (120,30). Walk up and feed one 15 carried fuel (`waylamp_fuel_need`); no lantern has to reach it.
- **Kindling:** in the Hollow, it wakes the Ashbrood; its kill holds the region. Elsewhere, a 15 s hold (`waylamp_kindle_sec`) while a swarm of 4 bold Wicklings (Lv 6) tries to sap it. It never fails; each Wickling on it only pushes the kindling back.
- **A held region:** its lanterns are refilled and stop burning; no Wicklings spawn there and any inside fade away; its WayLamp clears fog only in its own region. A banner says "{Region} is held".
- **Fast travel** (`scripts/ui/travel_menu.gd`): interact with a lit WayLamp to open a list of every lit WayLamp, in region order. The one you stand at is greyed. Picking one fades to black and puts you just below it. Pad: D-pad, A, B or Start. Keyboard: arrows, E or Enter, Q or Escape. Mouse: click. The world pauses while the list is open. **Blocked** while a foe hunts you within 12 tiles (`travel_hunt_radius` 384 px), while any WayLamp kindles, and while a guardian is in play. The prompt says why.
- **Fainting** at 0 warmth (`player.gd` `faint()`): half your carried fuel and scrap drop where you fell (glass is kept); all unspent wick drops as a wick drop (`wick_drop.gd`) to collect later; **every cleared pack resets**; you wake by the nearest lit lantern (or the hut) at 60% warmth, as Wicklings back off. A note says what happened. No death, no game over.

### 12.4 The plan

**WayLamps (M1a, M1b).** Rest at a lit WayLamp refills flasks and warmth and allows a respec (M2). It never resets packs and is blocked while hunted (M1a). WayLamps are lit by touching your flame to them, and the guardian is the cost (M1b; today 15 fuel). A fixed hold fight stands in until each guardian is built. Fast travel stays as built.

**The faint rule** (M1b; replaces `player.gd:211-213`):
1. You wake at the nearest lit light in the region at 60% warmth. Any light within 320 px of an unbeaten pack is skipped, so faints don't chain.
2. You keep everything you carry.
3. Your unspent wick waits where you fell (the built wick drop). A second faint makes a second drop; nothing is lost until you collect them.
4. Cleared packs stay cleared. A partly beaten pack heals, sleeps again, and keeps its dead.
5. A mid-boss or guardian goes back to the start of the phase you reached, shell regrown. Its phase oil drops again on each try; the flask cap (5) stops any hoarding.

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
- **Tips:** 21 one-time tips; "Show tips again" is in the pause menu. Tokens such as `[beam]` become the button for the device in use.

**The plan:** keep the voice and the mystery. New text is written as DRAFT in STORY.md with the code. STORY.md §13 lists every text the plan needs rewritten, and the new lines it needs.

---

## 14. UI and HUD

**Built today.** One panel style (`UiStyle`, `assets/ui/theme.tres`). The font is Ark Pixel at 20, 30, 40 or 60 only.
- **HUD:** top left, resources (fuel, scrap, glass), the hand-lamp and warmth bars, the level row ("Lv 3", wick bar, "12/24") and the lantern you will build; top centre, the goal banner; top right, status chips only when something needs you (wind, smothered mirrors, cold or low lanterns, getting cold, an ember lamp).
- **Prompts** sit over the thing you can use ("[E] Refuel 62%", "[E] Read", "[E] Turn right", "Travel"). A failed build says why for a moment.
- **Menus:** the lantern list (cards), map, journal, pause menu, notes, the level-up cards, the travel list and the F1 tuning panel. All of them pause the world.
- **Foe bars and the boss bar** as in §4.1. No action bar, no inventory or equipment screen, no talk panel.

**The plan:**

| Element | What | When |
|---|---|---|
| **Action bar** | Bottom centre, laid out like the pad: LT and LB left, Y middle, RB and RT right, the flask at the right end with 3-5 pips that flash when one comes back. 32 px icons, button labels at 20. Cooldown sweep and seconds; greyed when short of charge. | M1a |
| **Warmth and charge** | Two bars just above the bar, with skill-cost ticks on charge. | M1a |
| **Top of the screen** | Left: level, the wick bar and the scrap count. Centre: the goal banner (built). Right: chips only for "hunted" and "cold". The fuel, lamp and wind chips go. | M1a / M1b |
| **Foe bars, boss bar** | As built, plus the elite affix line (20 px) and "phase N / 3". | M2 |
| **Damage numbers** | Pop, then drift. Grey when the gap cut the wick. | not placed (likely the M1a juice pass) |
| **Map** | As built, plus WayLamp icons, lures you've seen, and the share explored. | not placed |
| **Level-up** | A toast and a Skills-tab mark. The card screen goes. | M2 |
| **The keeper's pack** | Gear, Skills, Journal and Map tabs (LB / RB). The Skills tab is greyed while you are hunted. The journal and map stay separate until then. | M2 |
| **Options** | A screen-shake slider and "reduce flashes". Later, the auto-fire option. | M1a |
| **Pad name entry** | A letter grid for the keeper's name. Until then a pad player is "Keeper". | M9 |

---

## 15. Save, load and pause (built)

- Three save slots, chosen on a screen at start (keeper, region and play time on each), plus autosave every 60 s *(code)*, on closing the window and from the pause menu. Save version 4 (`systems/save/save_game.gd`). The prototype line saves to its own files (`user://keepers_light_slot_*`), so it never touches a `main` save. An older save starts fresh and shows "(old save)".
- **Saved:** the keeper, inventory, unlocks, every lantern, resource spots and dropped piles, the fog and what has been seen, story progress, wick and level, cards, cleared foes, wick drops, lit WayLamps and the stones. **Not saved:** live foes, embers, wind.
- **Pause menu** (Esc / Start): Resume, Save, Save slots, New game (press twice), Save and quit, Goal pointer, Show tips again, plus the controls.
- **PLANNED:** version 5 in M1a (the bar and flasks); later sections add to it. Old saves start fresh.

---

## 16. Performance (built)

- **Budget:** game logic (process + physics) averages well under 4 ms a frame with 30 lanterns and 20 foes, measured by `tools/bench/bench.tscn` (see AGENTS.md). After the loop it measured 3.03-3.10 ms over three runs (worst frame about 6.0-6.4 ms).
- The fog steps only tiles that can change. Foes read lantern light from one shared snapshot a frame (`systems/light/light_sense.gd`). The map is drawn once, in 16 x 16 tile chunks *(code)*. Lanterns redraw only when their look changes.
- **PLANNED (M1a):** the bench adds 40 projectiles and 4 burning areas, and logic stays under 4 ms. The cost of projectile fog lights is not yet measured.

---

## 17. Art and audio

**Kept as built.**
- **Moody pixel art:** 16x16 tiles drawn at 2x (32 px on screen, one fog tile), nearest-neighbour filtering, hard edges. Tall things are 16x32.
- **14-colour palette** (`source/palette/lantern-keeper-14.gpl`): cool blues for the world; ambers only for light, fire and wood.
- **CC0 sources, recoloured:** Kenney Tiny Town and Tiny Dungeon, Puny Characters (the keeper), all in `assets/CREDITS.md`. The font is Ark Pixel 10px Proportional (OFL 1.1).
- **The owner's art** replaces placeholders over time. The Post Lamp (lit and cold) is done and kept as drawn. Everything else is a placeholder or drawn by code: foes, drops, lures, the beam and burst. The list is `docs/ART_CHECKLIST.md`.
- **Light and dark:** near-black darkness, a flickering 2D point light for every light, soft-edged fog on its own layer. Not used so far: occluder shadows, a fog shader, mist particles.
- **Audio:** 30 Kenney CC0 effects and a synthesized placeholder ambience. No music. Sound and music are the owner's job (DECISIONS, combat kit playtest). No jump scares.

**The plan (M1a for the feel; art per milestone):**

| Event | Feedback |
|---|---|
| Cast | additive flare at the lamp, slight recoil, sound |
| Flight | trail and glow; a small light that clears fog |
| Hit | white flash (built), sparks, small knockback, damage number |
| Burst / kill | Lampfire's light pop; 40-80 ms hit-stop on attacker and target only; a scorch mark that lingers |
| Fireglobe, Hearth ring | camera trauma, a ring flash, a burning-ground decal |

- **Additive `Sprite2D`** for every fireball, trail and blast; `PointLight2D` only for the hand lamp, lamps and WayLamps. Particles: `GPUParticles2D`.
- **Hit-stop** replaces the global `Engine.time_scale` freeze in `foe.gd` `_die()`. **Shake** uses a trauma recipe in place of the offset in `player.gd`.
- **Collision:** a ray or shape cast per tick for Lampfire, Lance and the Beam; `Area2D` for globes and motes; `intersect_shape` for blasts; a long-lived `Area2D` for burning ground. Pool projectiles.
- **New art:** skill, flask and item icons; rarity glints; keeper cast and dash frames; sprites for the Spitwick, Clinker, nest, elite ring and Ashbrood; each region's creature and guardian; people; climb stones that read as a fallen pile.
- **Audio needed** (owner; Kenney stand-ins until then): cast, hit and burst for each skill; flask; dash; rest; loot drops by rarity; boss phases; the portal.

---

## 18. Version 1 scope

**IN** (v1):

| Item | Status |
|---|---|
| One map, five regions on one loop | 3 built (Hollow, Reedmarsh, Ridge); Lakeshore M7; Still Lake M8 |
| The fire kit, the action bar, flasks | PLANNED (M1a); the beam, burst and dash are built |
| No lamp tending; one material (scrap) | PLANNED (M1b) |
| Skill branches | PLANNED (M2); 12 cards built |
| Diablo-style loot, 4 slots, salvage | PLANNED (M3) |
| Five people with short lines and errands | PLANNED (M4-M7) |
| Foes, mid-bosses and guardians per region | Hollow built (Ashbrood two phases); the rest M2, M5-M8 |
| The finale fight, the portal, the sandbox after | PLANNED (M8) |
| Levels 1-12 with level-gap wick | built (curve to be retuned in M1b) |
| WayLamps and fast travel | built (lit by touch M1b; Rest M1a) |
| Opening, goals, pointer, journal, tips | built for 3 regions |
| Keyboard/mouse and gamepad for every action | built; the pad map changes in M1a |
| Save/load: three slots plus autosave | built |
| Atmosphere: lights, fog, sound, pixel art | built; placeholders remain |
| Settings: fullscreen, goal pointer, tips; shake slider and "reduce flashes" (M1a); volume; accessibility (M9) | partly built |
| A Linux build | PLANNED (M9) |

**OUT** (v1): death or game over; dialogue trees or cutscenes (short spoken lines from people are IN); more than one map, or random maps; day/night, rain, seasons; crafting beyond salvage and Kit's single re-cut (a cut line); a Windows build; co-op or other platforms; a second progression track.

**Target playtime:** perhaps 5-7 hours, a guess (was 1-2 hours; DECISIONS, plan answer 9).

**Cut lines**, first to go if time runs short: the Tallest, Kit's re-cut, Ivo, Moth-lights' tier 3.

**Done when:** a new player reaches the finale without help; no soft-locks; all regions, finds and landmarks are in; save/load restores everything; both kinds of input work everywhere; the Linux build runs on a fresh machine; `assets/CREDITS.md` is complete.

**Maybe later:** rain, snow, a weather cycle, day and night; more lamp kinds (coloured lights that reveal hidden marks, floating lanterns, a lighthouse); more regions after v1 (the portal and the far light are the hooks); direction C's tides (ebb and flood), if fights need build-up; a Windows build, Steam Deck; an original soundtrack; a photo mode and an "ambient" mode.

---

## 19. Measured numbers (built)

These are measurements of the code at c6d3ee0. The plan changes most of them in M1a and M1b; keep this section until then.

### 19.1 Wick in the Hollow

Fixed wick, before the level gap scales it: 25 packs of 88 foes, 12 nests, the Clinker, the Ashbrood and kindling. The balance pass (2026-11-27) set the curve to base 6, exponent 1.25, and wick by danger. The level-gap pass made the Ashbrood's kill the Hollow's last level (base 32, x2.5 at Lv 7 = 80; kindling 10).

| | Beeline | Explorer |
|---|---|---|
| Level 2 | at the crook's guard (3rd fight) | at pack 23 (3rd fight, after the guard) |
| Level 3 | pack 2, before the Clinker | pack 2, before the Clinker |
| Level 4 | the Clinker | the Clinker |
| Into the Ashbrood | L7 | L7 |
| The kill | L8 | L8 |

A farmer who camps the hut row and the south reaches L4 in 4 minutes, then L5 only at 25 minutes, and earns about 1 wick a minute in the last 10. Band 1 and x0.25 were chosen over band 2 and x0.5, which let the farmer reach L5 in 5 minutes and over-paid the forward run (L9 by the end of the Hollow).

### 19.2 The first 10 minutes (Option B)

The main route, as placed. Offsets are tiles from the hut's start tile (48,136), +x east, -y north. `test_prototype_onboarding.tscn` prints and checks them.

| Order | What | Offset | From the hut | Wakes at |
|---|---|---|---|---|
| 1 | The lone first Wickling (pack 20: 1 Wickling, Lv 1) | (-1, -10) | 10.0 | 5 tiles |
| 2 | **The north path's old lamp**, cold (a haven; goal `relight_waypost`) | (+2, -12) | 12.2 | - |
| 3 | The first pack (pack 23: 3 Wicklings, Lv 1) | (+5, -17) | 17.7 | 6 tiles |
| 4 | **Oswin's crook** (the Post Lamp find) with its small guard (one shelled Wickling, Lv 2) and a 6-scrap cache | (-1, -19) | 19.0 | 4 tiles (`kl_post_guard_wake_radius` 128 px) |
| 5 | **Nest A** (nest 4, Lv 2): the first lock the Post Lamp opens; goal `burn_nest` | (+2, -30) | 30.1 | 10 tiles |
| 6 | Pack 2 (4: one Spitwick, one shelled, Lv 4) | (60,113) | | 10 tiles |
| 7 | The Clinker, a mid-boss (Lv 4) | (70,119) | | 7 tiles |
| 8 | The Hollow's WayLamp and the Ashbrood | (78,124), offset (+30, -12) | 32.3 | - |

**Rules the tests hold:** nothing wakes at the hut, its lantern, the woodpile, the scrap or the ledger. Only the lone Wickling is within 16 tiles of the hut. From the hut to the crook: at most 2 packs and 4 Wicklings, no Spitwick, no elite, no nest, no Clinker. The whole route wakes 3 of the 24 packs and 1 of the 12 nests; the rest is optional. No nest is within 28 tiles of the hut, and no Spitwick or elite pack within 25. The south of the Hollow is optional content (maybe Amos's side quest, M4).

**Not done:** pack and nest lures still look alike (M1b). Timings are estimates, not a playtest.
