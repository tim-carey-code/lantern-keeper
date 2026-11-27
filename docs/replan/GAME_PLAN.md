# Lantern Keeper: game plan (re-plan), v2

**DRAFT for owner approval, 2026-11-27.** This is a proposal, not a decision. Where it changes an earlier owner decision, it is listed under "Decisions this plan would supersede", and each of those needs the owner's OK.

**Inputs.** `docs/replan/AUDIT.md` (AUDIT §n), `docs/research/ARPG_REFERENCES.md` (brief §n), `docs/replan/REVIEW_GAME_PLAN.md` (review IDs B1, M1-M13, minor 1-16), `docs/DECISIONS.md` (numbered as the rows of AUDIT §3), and the loop on `proto/kl-loop` at `ff8426b` ("the loop"), treated as built.

**How to read it.** Every section ends in one recommendation. Numbers are starting values for tuning. Names in `code font` are `systems/tuning.gd` entries, and "(new)" marks one that doesn't exist yet. All in-game text named here is DRAFT. Oswin is "he", Ebba is "she", the keeper is "they". Amos, Maud, Kit and Ivo have no pronouns yet, so none are used. Original design only: other games are references for mechanics, never for names, characters, art or levels.

**Words used here.** *AoE*: an area attack. *Affix*: a bonus line on an item. *Base stat*: an item's built-in stat. *Item level*: the level of the foe that dropped it. *Respec*: take back your skill points and spend them again. *dps*: damage per second. *Cut line*: the first thing dropped if time runs short. *Shell*: a foe's pale armour that only some fire wears down. *Hunted*: an awake foe has you as its target within 12 tiles (`travel_hunt_radius`, 384 px). *Tier*: one step of a skill's branch.

## Changes since v1

| Review ID | Fix in v2 |
|---|---|
| B1 | The kit now leads with fireballs. **Lampfire** (the basic attack, RT) bursts on impact. **Fireglobe** (the big lobbed fireball, RB) is on the bar from level 1. The Beam is optional: it sits in LB only until Lance arrives at level 2. The old burst becomes **Hearth ring**, an optional pick that is not on the default bar. Lance and the Beam now do equal damage per charge. (§4) |
| M1 | Every branch pick now changes a skill's shape or behaviour; only the optional Beam keeps the old number cards. The first such pick comes at level 2. Tier 3 opens at level 6, on the Ashbrood kill. Every region adds a skill, a skill-changing relic, or a find. (§4.2, §4.4) |
| M2 | A kit question is now first. Each question says which milestone needs its answer. The supersede table can be approved in one question. There are 9 questions. (§19) |
| M3 | Added rows #16, #59/P7, #75 and #101, plus #36 (the marsh WayLamp's spot) and the playtime. (Supersede table) |
| M4 | Y now takes only self-cast skills. The aim holds while a fire button is held. The Diablo IV count is corrected to 8 inputs, aimed by facing, and the flask/dodge swap is explained. (§3) |
| M5, M6 | The D-pad no longer moves the keeper; the map and lamp keys are read only when no menu is open. The flask and all combat input are read after the menu-close guard. (§3, §16, M1a) |
| M7 | Charge from light drops from 0.5/s to 0.1/s while you're hunted. A picked-up lamp can't be replanted for 15 s. The Beam's regen rule is now stated once. (§5, §6) |
| M8 | Numbers now meet the time-to-kill targets, with the arithmetic shown. Lance gets a 0.5 s cooldown. The Beam goes to 7.5 hp/s. The Clinker and Ashbrood get more health. Scaling: foes +12% health a level, keeper +10% damage a level. (§4.6, §8.1) |
| M9 | The curve is now base 7, exponent 1.65, with a wick budget per region from a level-by-level simulation. The Hollow ends at **level 6**, not 5. (§9) |
| M10 | Summoned foes drop nothing. (§10) |
| M11 | Gear's skill changes no longer repeat a branch pick, and a stacking rule is written down. (§10) |
| M12 | M1 is split into M1a (fire in the Hollow) and M1b (no more tending). Branches move to M2 and loot to M3. `test_ridge` and `test_upgrades` are placed. (§18) |
| M13 | Every check can be done on a pad with one WayLamp lit. Added checks: "fire skills fun?", "keep the Beam?", B-guard, D-pad, and both routes. (§18) |
| Minors 1-16 | Citations fixed; the rest-versus-travel claim fixed; faint edge cases and "hunted" defined; name clashes renamed; slot rule stated; one Hollow relic; Hot core and Lee keep their approved values; L3 dev panel behind a flag; optional auto-fire; right mouse freed; pad name entry noted; Skills tab greyed while hunted; one cart for Amos; Ebba's crossing clarified; two docs added; glossary; playtime row. |
| Loop follow-ups | Ridge milestone: the stones get a line and a note, read as fallen stones, and pack 11 and nest 7 move. Marsh milestone: a U-route layout. §13: the pumphouse and cairn lines. (§12, §13, §18) |

What I did not adopt from the review is at the end, under "Review items not adopted".

---

## 0. In short

1. An action RPG in a dark, foggy valley. Your hand lamp throws fireballs of light. Light is still shelter, but now you take it by force.
2. No lamp tending. Planted lamps never burn out. Fuel becomes lamp oil: three flask charges that heal you and refill your charge.
3. **From level 1 you throw fire:** Lampfire on RT (bursts on impact) and Fireglobe on RB (a big lobbed fireball). Lance, the shell-breaker, arrives at level 2. The Beam and Hearth ring (the old burst) are optional picks.
4. **Pad:** four inputs work while you aim (RT, RB, LB, LT). Y is for self-cast skills only. B is the flask. The D-pad stops moving the keeper.
5. **Skill points** go into fixed branches, and every pick changes how a skill behaves. The first comes at level 2, and tier 3 opens on the Ashbrood kill. The random cards go.
6. **Charge** refills from Lampfire hits, slowly everywhere, and from light (fast out of a fight, 0.1/s while hunted). **Warmth** heals in light only when nothing hunts you. In a fight, flasks heal.
7. **Loot:** three rarities plus about 8 relics, four slots (lens, burner, coat, wick), salvage into scrap. Summoned foes drop nothing.
8. **One material:** scrap. Fuel and glass stop being resources.
9. **WayLamps** are lit by your flame; the guardian is the cost. Lit WayLamps are fast travel (built) and the place to rest.
10. **Levels:** cap 12. The Hollow ends at level 6, then the Reedmarsh 6-8, the Ridge 8-10, the Lakeshore 10-11 and the Still Lake 11-12.
11. **People:** five come back as regions are held, through Dialogue Manager. Amos brings the south-Hollow side quest.
12. **Build order:** M1a fire in the Hollow, M1b tending removed, then branches, loot, people, and one region at a time.

---

## 1. Pitch and pillars

**Pitch.** You are the valley's new keeper. Your hand lamp throws fire-light. Burn back what lives in the fog, take the old WayLamps back one by one, and follow Oswin, the last keeper, to the cold great lamp at the Still Lake.

**Feeling (kept, DESIGN §1):** calm, moody, curious, rewarding, with a quiet unease.

**Pillars.**
1. **Light is your weapon.** Fireballs of light from the hand lamp, aimed with the right stick or the mouse.
2. **Light is your shelter, and you carry it.** Planted lamps and lit WayLamps are pockets where you refill. No upkeep.
3. **The find is the key.** Each region's find is a lamp that opens its lock and answers one phase of its guardian (PLAN_KEEPERS_LIGHT §3.1).
4. **Readable fights.** Every big hit has a tell. Every foe has a name, a level and a bar (built, AUDIT §1.1).
5. **Every fight pays, once.** Fixed packs, level-gap wick, and loot that only fixed foes drop. Cleared ground stays cleared.
6. **Calm at the edges.** A calm start, quiet held ground, no game over.
7. **Show, don't list.** Lures through the fog and short notes pull you on.

**The ARPG adds** skill and gear choices, loot, guardians and a level curve. **It removes** tending, gathering, "planning over reflexes", "light is safety" and the quiet finale (AUDIT M14, M15).

**Recommend:** these pillars. They replace DESIGN §1 and the ARPG skill's pillars.

---

## 2. The core loop

| Scale | What you do | What you get |
|---|---|---|
| **A minute** | Aim. Stream Lampfire, which also refills charge. Spend charge on Fireglobe or Lance. Dash through the tell. Drink when low. Step into light between fights. | Wick, scrap, oil, sometimes an item |
| **A session (15-30 min)** | Rest at a lit WayLamp (full flasks). Push toward a lure. Clear 3-5 packs and an elite. Swap gear, spend a point. Reach the find or the next WayLamp and fight its guardian. Travel back to a person, or go on. | A level or two, a few items, a region held |
| **The whole game** | Five regions on one clockwise loop. Each has a find, a twist, a mid-boss, a guardian and a new skill or relic. Levels 1-12. The Soul of the Wick retreats through a portal. The valley stays open. | The great lamp relit, and a hook for later |

**Playtime** is a scope change: perhaps 5-7 hours, a guess, against DESIGN §5's 1-2 hours. It has its own row in the supersede table.

**Recommend:** this loop. M1a exists to make the minute-scale loop feel good.

---

## 3. Controls and the action bar

**The constraint.** Twin-stick aim: the left thumb moves, the right thumb aims. RT, RB, LB and LT work while you aim. Y and B take the right thumb off the stick.

The brief's Diablo IV pad fits **8 combat inputs**: 6 skill slots, a potion and an evade, with no modifier (brief §1). But Diablo IV aims by facing, so its face-button skills don't carry over to twin-stick. We use 6: four that work while aiming, plus Y and B for things that don't aim.

The brief puts the flask on LB and the dodge on B. We swap them: the owner already dashes on LT, and LB is needed for an aimed skill.

| Slot | Pad | Keyboard / mouse | Default | Rule |
|---|---|---|---|---|
| 1, basic | **RT** (hold) | Left mouse (hold) | Lampfire | Always Lampfire |
| 2 | **RB** | Right mouse | Fireglobe | Aimed skills |
| 3 | **LB** | Q | The Beam at level 1, then Lance | Aimed skills |
| 4 | **Y** | F | empty | **Self-cast skills only** (Hearth ring, Moth-lights) |
| Dash | **LT** | Space (Shift too) | Dash | Along your movement |
| Flask | **B** | R | Lamp oil | Read after the menu guard (below) |

| Out of a fight | Pad | Keyboard / mouse |
|---|---|---|
| Interact, read, talk, rest, travel; turn a mirror right; hold to pick up your lamp | A | E |
| Plant a lamp; next to a mirror, turn it left (#75) | X | C |
| Next / previous lamp kind | D-pad right / left | Tab / Shift+Tab |
| Map; the keeper's pack (Gear, Skills, Journal, Map); pause | D-pad up; View; Start | M; I, K, J; Esc |

**Y and aim (M4).** I chose "Y takes only self-cast skills" over a timed aim latch. With a latch, an aimed skill on Y fires along a direction up to half a second old, and that miss feels like the game's fault. Self-cast skills need no aim, so the rule is simple to explain.

The flask press still needs one fix. Today, releasing the stick snaps aim to your walking direction (`scripts/player/combat.gd:36-44`). Instead, **while RT, RB or LB is held, a released right stick keeps its last aim** (`kl_aim_hold`, new). So drinking mid-stream doesn't swing your fire. This is not a latch for Y.

**The input guard (M6).** Menus block a closing press with `Progress.block_input()`. Today combat input is read at `player.gd:85`, before that guard at `:101`. The flask and all combat input must be read **after** the guard. Then the B that closes a menu never drinks. A test checks every menu.

**The D-pad (M5).** Remove the D-pad from `move_*` (`tools/setup_input.gd:31-34`). Read `map` and lamp cycling only while no menu is open (`Tuning.ui_open` false), and menu handlers ignore them. A test moves through every menu with the D-pad and checks the map never opens.

**Also.** Aim assist on pad: a gentle pull within 12 degrees, for Lampfire and Lance. An option makes Lampfire fire whenever the right stick is pushed past 0.8, so RT and RB don't share one finger (minor 8). The L3 tuning panel is in dev builds only (minor 7). Right mouse is slot 2, so pick-up moves to "hold E" (minor 9). To bind, pick a slot in the Skills tab, then a skill; the tab is greyed while you're hunted, with the reason shown (minor 14). Cooldowns show as a dark radial sweep, with seconds if more than 3 are left; a slot greys out when you're short of charge; the flask shows pips.

**Recommend:** this map (owner question 2).

---

## 4. Skills

### 4.1 The kit

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

**The default bar.**
- **Level 1:** RT Lampfire, RB Fireglobe, LB the Beam, Y empty.
- The Beam sits in LB only because LB would otherwise be empty. That way the owner tries it from the first fight ("keep as optional for now", DECISIONS 2026-11-27).
- **Level 2:** Lance takes LB, and a toast says the Beam is in the Skills tab. One press puts it back.
- Hearth ring is in the Skills tab from level 1 and is never on the default bar. Y stays empty until you choose Hearth ring or get Moth-lights.

**Per charge, Lance and the Beam are equal:** 5 / 0.2 = 25 damage per charge, and 7.5 / 0.3 = 25. Lance hits harder in bursts and pierces 3, and its cooldown caps it at 10 dps. The Beam has no travel time and hits everything on its line, but slows you and stops light regen. That makes the Beam trial fair.

### 4.2 Branches instead of cards

The model is from brief §3: three tiers per skill, one pick each.
One point per level-up, 11 by level 12. Tier 1 opens once you have the skill (your first point comes at level 2), tier 2 at level 4, and tier 3 at level 6, the Ashbrood kill. **Every pick changes how the skill behaves** (brief §3); only the Beam's tree keeps the old number cards the owner approved. Respec is free when you rest at a lit WayLamp. No per-skill XP. The Beam and Hearth ring get trees only if the owner keeps them after M1a.

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

### 4.3 Where the 12 cards go

Every card in `scripts/ui/level_up.gd:4-18` keeps its effect. Lampfire gets Lingering burn and Catching. Hearth ring gets Heavy flare and **Spill** (approved). Dash gets Second step. The Beam gets **Steady hand** (approved), Long throw, Deep tank and Tight focus. Kindled kills, **Hot core** and **Lee** (both approved) become gear lines (§10); Hot core and Lee keep their approved values (cores burn 2x, touch chills 25% less) as fixed lines, not rolled. If the owner cuts the Beam or Hearth ring after M1a, their card effects go with them.

### 4.4 Something new in every region

| Region | New skill | Relic or find that changes a skill |
|---|---|---|
| The Hollow | Lampfire, Fireglobe, Lance (plus the optional Beam and Hearth ring) | The Ashbrood's relic, **Brood globe**: Fireglobe leaves 3 embers that seek foes |
| The Reedmarsh | Moth-lights (level 7) | The Sump's relic, **Steam burner**: a Fireglobe over water bursts twice |
| The Windward Ridge | Wheeling flame (level 9) | **Oswin's coat**: gusts don't push your fire. The Galekite's relic, **Kite lens**: Lance curves toward the nearest foe |
| The Lakeshore | — | The find, the **Mirror Post**: your fire crossing a mirror beam bursts at double radius. The Tallest's relic, **Prism wick**: Lampfire splits in three through a beam (Ebba's relic if the Tallest is cut) |
| The Still Lake | — | The find, the **catch ring**: inside a mirror beam, Lampfire flies twice as far and you refill charge as if in light |

That makes 8 skills in all, two of them optional. Region finds stay lamps, the keys (§6). Skills come with levels, so the bar grows at a pace you can learn.

### 4.5 The shell rule

- **Full damage:** Lance, the Beam, mirror beams, and Wheeling flame's *Cleaver*.
- **Half damage:** Lampfire's hit, Moth-lights and Wheeling flame.
- **None:** Fireglobe, Hearth ring, splash, burning ground and lamp cores. They glance off (built).
- Shells on elites never grow back once dented. Shells on the Clinker and the Ashbrood grow back after 3 s without a hit, until they break, and a broken shell stays broken (`shell_regrows`, `foe.gd`; `kl_shell_regrow_wait`).

### 4.6 Time to kill: targets and arithmetic

**Targets:** a same-level Wickling dies to 2 Lampfire hits; a shelled elite takes 3-5 s; a plain pack 2-5 s; a mixed pack 8-12 s; a mid-boss about 30 s; a guardian 2-4 minutes. **Scaling:** foes +12% health and shell per level over 1 (`kl_foe_hp_per_level`, new); the keeper +10% damage per level (`kl_dmg_per_level`, new); gear covers the gap. **Charge while hunted:** 0.06 base + 0.086 from Lampfire hits + 0.1 in light = about 0.25/s.

| Fight | Foe | Keeper | Working | Time |
|---|---|---|---|---|
| A Wickling, Lv 1 | 3 hp | L1, Lampfire 2 a hit | 2 hits, 0.35 s apart. At L12: 2 x 4.2 = 8.4 against 6.96 hp, still 2 | under 1 s |
| The crook's guard (shelled, Lv 2) | hp 9 x 1.12 = 10.1, shell 4.5 | L1, Lampfire only | shell at 1 a hit: 5 hits; hp at 2 a hit: 6 hits; 11 hits at 2.86/s | about 3.5 s |
| Pack 2, Lv 4: 2 Wicklings, a Spitwick, an elite | 4.1, 4.1, 5.4, and 12.2 + 5.4 shell | L3 (x1.2): Fireglobe 9.6, Lance 6, Lampfire 2.4 | one Fireglobe kills both Wicklings; 3 Lances (0.6 charge, 1 s) kill the elite; 3 Lampfire hits kill the Spitwick | 3 s of damage; 8-12 s with waking, spit and walking |
| The Clinker, Lv 4 (`kl_clinker_hp` 24 → **48**) | 65 hp, 16.3 shell, regrowing | L4: Lampfire 7.4 dps; Lance 6.5 per 0.2 charge | about 12 dps on health and 8 on shell: about 7.5 s of damage; it rolls and you dodge, so about 25% uptime | about 30 s |
| The Ashbrood, Lv 5, 3 phases (`kl_ashbrood_hp` 40 → **150** per phase, shell 12) | per phase 222 hp and 17.8 shell | L5: Lampfire 8 dps, plus Lance at about 1.25 a second from charge income (8.75 dps) | about 17 dps: 14 s a phase, 43 s in all; adds, puffs and dives leave about 35% uptime | about 2 minutes (2.6 without a lamp nearby) |

**Recommend:** this kit and these numbers (owner question 1).

---

## 5. Resources

**Light and regen in one place:**

| | Out of a fight | While hunted |
|---|---|---|
| Warmth in light | +20/s (`warmth_regen_per_sec`) | **none** |
| Charge in light | +0.5/s (`hand_lamp_recharge_per_sec`) | **+0.1/s** (`kl_light_charge_hunted`, new) |
| Charge anywhere | +0.06/s (`kl_charge_regen`, new) | +0.06/s |
| Lampfire hit | +0.03 charge | +0.03 charge |
| While the Beam is on | no charge from light; base +0.06/s continues | same |

"Light" means a planted lamp, a lit old lamp, a lit WayLamp, a Fireglobe *Beacon* or the Dash's *Ember rest*. "Hunted" is defined in the glossary. A timid Wickling waiting at your light's edge counts, so you clear the area before you rest.

**Why:** with free healing in a fight, players run off to heal instead of drinking (brief §2, Grim Dawn). Fast refills out of a fight keep "light is shelter", and fixed packs leave nothing to farm.

**Warmth** is 100 at level 1, +8 a level (`kl_warmth_per_level`, new). Foe damage rises 8% a level (`kl_foe_dmg_per_level`, new) to match.

**Lamp charge** runs 0 to 1.0, +0.1 per lamp glass (`lamp_upgrade_charge`, new). It still sets how far your hand lamp lights, 44 to 104 px (`hand_lamp_*`). Cut: the passive dimming (`hand_lamp_drain_per_sec`) and the fuel top-up (`player.gd:69`).

**Lamp-oil flasks:**

| | Value |
|---|---|
| Charges | 3 to start (`kl_flask_max`, new); +1 from Maud; +1 from a coat line; at most 5 |
| Effect | Heals 40% of max warmth at once and gives +0.4 charge (`kl_flask_heal`, `kl_flask_charge`, new). 1 s lockout |
| Rest at a lit WayLamp | Refills all. Travel plus rest is a full refill, which is fine with fixed packs. Blocked while hunted |
| Drops | A cleared pack's last foe drops 1 oil. Elites: 30% chance. A mid-boss: 1 at half health. A guardian: 1 at the half of each phase (`kl_boss_oil_step` 0.5, new), so 3 in the Ashbrood fight (brief §2, Last Epoch) |
| Timer refill | None. You can always rest in light out of a fight |

**What fuel, glass and scrap become.** **Fuel** stops being a resource: oil exists only as flask charges and drops, and fuel spots and peat become scenery or go. **Glass** stops being a resource: lamp costs fold into scrap, and the glass racks stay as Ridge story. **Scrap** is the one material: ruins become one-off piles taken with one press, scrap also comes from drops, caches and salvage, and it pays for lamps, Amos's stock and Kit's re-cut. No carry cap.

**Recommend:** this stance (owner question 3) and one material (owner question 8).

---

## 6. Lanterns after tending

**What a planted lamp does.** It never burns down and shines at full radius. Its light gives charge and, out of a fight, warmth (§5). Timid foes stay out, and brave ones burn after 2.5 s (built). Its core burns small foes and nests (built). It clears fog (built). You wake by it after a faint.

**Limits and cost.** At most 3 lamps in regions not yet held (`kl_lamp_limit`, new); no limit in held regions. Picking a lamp up refunds all its scrap, but you can't plant again for 15 s (`kl_lamp_replant_cd`, new), so you can't drag a haven through a fight (M7). Building stays quiet (built).

| Piece (AUDIT §5.5) | Verdict | New job, and why |
|---|---|---|
| Post Lamp | **keep** | The Hollow's find: haven and nest-burner. 5 scrap. |
| Reservoir Lamp | **repurpose** | The marsh's find: a wide dim light (200 px) with no core that forces things in water up (Slowwater, the Sump). Feeding is cut. 8 scrap. |
| Hooded Lamp | **repurpose** | The Ridge's find: the only lamp a gust can't snuff. Diving Gutterkites snag on it. 7 scrap (was 5 + 2 glass). |
| Mirror Post | **repurpose** | The Lakeshore's find (#36): a fixed beam that cuts fog, wears shells and makes your fire burst where it crosses. 8 scrap (was 4 + 3 glass). |
| Wind | **repurpose** | Ridge only. Gusts snuff exposed Post and Reservoir Lamps until the gust ends (they relight themselves) and push projectiles downwind. Valley-wide gusts are cut. |
| Old cold lamps (hut, north path) | **keep, no fuel** | Relit by touch: a haven and an early win (#11). |
| Cold-lantern markers, low pulses, chips | **cut** | Nothing goes cold. The cold-frame lure stays for unlit old lamps. |
| Woodpile | **cut as a source** | Scenery. It existed to prevent a fuel soft-lock. |
| WayLamps refilling lamps | **cut** | Nothing to refill. Held ground is safe, with no limit on lamps, plus rest and travel. |
| Dying lamps; Wicklings draining them | **cut** | Wicklings hunt the keeper. Mirror smothering stays, for the Lake. |
| The Ashbrood's dive emptying a lamp | **repurpose** | Its dive snuffs a lamp for 8 s. |
| Embers (+1 fuel) | **repurpose** | Their glow and 140 px magnet become the pickup for scrap, oil and items. |
| Refuel, relight with fuel, hold to gather | **cut** | No tending. |

**Recommend:** 3 lamps, full refund, a 15 s replant delay (owner question 4).

---

## 7. Fog and light as exploration

Keep the fog, its memory and the reveal (`fog_grid.gd`, built). **Your fire lights the fog:** Lampfire's light pop, Lance and Fireglobe are small lights of about 40 px while they fly (group `light_source`), so you can throw a Fireglobe into the dark to see what's there. Fog slows walking to 85% at most, not 60% (`fog_slow_min`). The Lakeshore's thick fog (#50) clears at a quarter speed for your fire, and at the usual speed for mirror beams, the Beam and WayLamps. **Lures you can tell apart** (AUDIT §4.3):

| Lure | Look above the fog |
|---|---|
| Sleeping pack | small pale eyes in pairs |
| Nest | a slow cold blue glow |
| Elite or mid-boss | one larger pair of eyes with a pale ring |
| Cache or loot | a small glint, coloured by rarity |
| Unlit old lamp | a red-amber pulse (built) |
| WayLamp | a tall still shape |

**Recommend:** fire-light as the way you scout.

---

## 8. Foes

### 8.1 Packs, elites and nests
- **Fixed packs** sleep until you come close (`kl_pack_wake_radius` 320 px; built) and never respawn on a timer. **Nests** are burned only by lamp cores (built); the Post Lamp is their key.
- **Elites** are shelled (`kl_elite_hp` 9, `kl_elite_shell` 4) and carry affixes under their name, 1 in the Hollow from level-4 packs and 2 from the marsh on: **Swift** (+30% speed), **Biting cold** (+50% chill), **Bursting** (2 Wicklings when it dies), **Thick shell** (x2), **Lightless** (ignores light, snuffs lamps it passes for 4 s).
- **Scaling:** see §4.6 (today foe levels change only their wick, DESIGN §9). **One projectile system** serves keeper and foes, including the Spitwick's spit (brief §6, §7).

### 8.2 Families, mid-bosses and guardians

Foe levels below are proposed. The built Hollow has foes at levels 1-6 and the Ashbrood at Lv 7 (`kl_ashbrood_level`). Row #16 in the supersede table covers the change.

| Region | Foe levels | Small foes | Region creature | Mid-boss (a Clinker with one trait) | Guardian |
|---|---|---|---|---|---|
| The Hollow | 1-4 | Wickling, Spitwick, nests | — | **Clinker** (built), Lv 4 | **The Ashbrood**, Lv 5; add phase 3, "last of the brood" |
| The Reedmarsh | 5-7 | Wicklings, Spitwicks | **Slowwater** (hides in unlit water, grabs your feet); **Fenlight** (a false lure that bursts) | **mire**: its rolls leave chilling water | **The Sump**, Lv 8: under water until Reservoir light forces it up |
| The Windward Ridge | 8-9 | Wicklings in the lee, Spitwicks | **Gutterkite** (dives with gusts) | **downwind**: rolls faster with the wind | **The Galekite**, Lv 10: out of reach until it snags on a Hooded Lamp |
| The Lakeshore | 10 | Wicklings from the shallows | **Fogstilt** (thickens fog; a mirror beam and your fire crossing on it unravel it) | **in fog**: its shell shows only in a beam | **The Tallest**, Lv 11; **first cut** |
| The Still Lake | 11 | a mix | — | — | **The Soul of the Wick**, Lv 12 |

The Clinker stays fixed and never roams (#58). Each guardian wakes when you light its WayLamp, blocks rest and travel (built for the Ashbrood), and on its first kill drops a relic and 3 items.

### 8.3 The finale (DECIDED: a fight; the Soul is not killed and retreats through a portal)

| Phase | What happens | Your answer |
|---|---|---|
| 1. The coil | Three shelled coils around the great lamp. Tendrils sweep the island. Wicklings rise from the water. | Crack each coil where a mirror beam and your fire cross on it. |
| 2. Every flame | About 40 s of each guardian's signature: the ash puff, high water, the gale, the still fog. | Each is answered by that region's lamp. |
| 3. The eyes | It snuffs your hand lamp, so light no longer refills charge. Only Lampfire hits and flasks do. | Fire on its eyes until they close, three times. |

It pulls back into the water and a dark portal opens where it went down (#34). The great lamp catches and the fog lifts. A faint returns you to the start of the phase.

**Recommend for v1:** the keeper steps into the portal and the credits roll. You then wake at the great lamp in the open valley (#112), with the portal sealed, as the hook. DRAFT for story markup.

### 8.4 Foes and lamp light

About half of Wicklings are timid; brave ones burn after 2.5 s and run (`kl_timid_share`, `kl_light_tolerance`, `kl_light_burn_dps`; built). Spitwicks spit across light. Elites, mid-bosses and guardians ignore light (built). Each region creature has one light rule: Slowwaters surface in Reservoir light, Gutterkites dive at lamps, Fogstilts step away from a single beam.

**Recommend:** this roster, with the Tallest as the first cut.

---

## 9. Leveling

**Keep the level-gap wick exactly as built** (`progress.gd`, `kl_xp_*`): full wick up to 1 level over the foe, x0.25 a level past that, none at 5 or more, and foe value +25% a level (`kl_xp_level_growth`, unchanged). Cap 12. **The curve:** wick from L to L+1 is `kl_wick_base` x L^`kl_wick_exp`, at **base 7, exponent 1.65** (today 6 and 1.25; v1 proposed 7 and 2.0, which in the simulation ends the game at level 9-10, as review M9 said). That gives 7, 22, 43, 69, 100, 135, 174, 216, 263, 313, 366.

**Wick budget per region.** The supply figures come from a level-by-level simulation: the built gap rule, each region's foes fought in route order, and one hatch of 3 per nest. They are estimates; `test_leveling` sets the final values.

| Region | Size (open tiles) | Keeper levels | Wick needed | Packs / nests / elites | Foe levels | Full-clear supply |
|---|---|---|---|---|---|---|
| The Hollow | about 5,500 | 1 → 6 | 241 | 25 / 12 / 6 (built) | 1-4, Clinker 4, Ashbrood 5 | about 410 (1.7x) |
| The Reedmarsh | about 8,500, much of it water | 6 → 8 | 309 | 26 / 8 / 6 | 5-7, Sump 8 | about 570 (1.8x) |
| The Windward Ridge | about 4,800 | 8 → 10 | 479 | 22 / 6 / 6 | 8-9, Galekite 10 | about 620 (1.3x) |
| The Lakeshore | about 1,600 | 10 → 11 | 313 | 11 / 3 / 4 | 10, Tallest 11 | about 460 (1.5x) |
| The Still Lake | about 3,600, mostly water | 11 → 12 | 366 | 7 / 0 / 3, plus the Soul (base 60) | 11, Soul 12 | about 390 (1.1x) |

- **The bands land** when you fight 75-90% of each region; at 60%, the Hollow and the Lake come out one level short. The Lake is the tightest: if it runs short, the Soul's phases pay wick. Level 2 still comes at the crook (7.75 wick against 7 needed).
- **The Hollow ends at level 6, not 5** (the maths doesn't support 5) **and not 8** (#7). On a pure beeline it's level 5. Either way, the last Hollow level comes on the Ashbrood kill (#17, kept). `test_leveling` checks both routes.
- **A level gives** a skill point, +8 warmth, +10% damage, and new skills at levels 2, 7 and 9. It shows as a chime, a toast and a mark on the Skills tab, with no pause.

**Recommend:** this curve and these bands (owner question 6).

---

## 10. Loot

| Rarity | Affixes | Share | Colour |
|---|---|---|---|
| Plain | none; base stat only | 70% | `#a3bcd4` |
| Bright | 1-2 | 25% | `#6d8fb3` |
| Rare | 3-4; may include a skill change | 5% (x2 from elites and bosses) | `#ffd27a` |
| Relic | fixed and hand-made; about 8 in v1 | guardians' first kills and some finds | `#f5a742` |

**The slot rule (minor 5):** the lens shapes direct hits; the burner shapes blasts, rings, motes and burning ground.

| Slot | Shapes | Bases |
|---|---|---|
| **Lens** | Lampfire's hit, Lance, the Beam, Wheeling flame | Clear lens (+damage), Far lens (+range) |
| **Burner** | Lampfire's splash, Fireglobe, Hearth ring, Moth-lights, burning ground | Wide burner (+radius), Slow burner (+burn time) |
| **Coat** | warmth and defence | Patched coat (+warmth), Oilskin (full-speed wading), Quilted coat (chills less) |
| **Wick** | lamp charge | Plain wick (+max charge), Braided wick (+regen) |

The slot named **wick** shares its name with the XP; the owner chose that name (#19), so the clash is left for the owner to call. You start with a Plain item in each slot.

**Affixes: 16 general, plus 4 skill changes on Rare and Relic items only.**

| Lens | Burner | Coat | Wick |
|---|---|---|---|
| +% hit damage | +% blast radius | +max warmth | +% max charge |
| +1 pierce on Lampfire | burning ground +1 s | **Lee**: touch chills 25% less (fixed) | **Kindled kills**: +0.1 charge per kill |
| +% shell damage | -% cooldowns | +1 flask charge | -% skill cost |
| +% speed and range | Hearth ring stuns 0.4 s | +% move speed | **Hot core**: lamp cores burn 2x (fixed) |

**Skill changes (no branch gives these, M11):** Lampfire hits on burning foes give +0.02 charge; Fireglobe lands 0.5 s later at double radius; Lance leaves a 2 s spot of lamp-light where it stops; each dash gives back 0.1 charge.

**Stacking:** a gear effect and a branch pick both apply. Numbers add and never multiply. No gear effect repeats a branch pick, and `test_loot` checks the lists.

**Relics:** the Hollow has one (the Ashbrood's). The Reedmarsh: the Sump's and Maud's Smoulder burner. The Ridge: Oswin's coat (#35), the Galekite's and Kit's Long lens. The Lakeshore: the Tallest's and Ebba's Shutter burner.

**Drops** (start here, then tune): Wickling 3%, Spitwick 5%, nest 40%, elite 35%. A mid-boss drops 2 items, one Bright or better. A guardian drops 3, one Rare or better, plus its relic, and at least one for a slot where you hold only Plain. A side cache holds 1 item, Bright or better. **Summoned foes drop nothing** (no items, oil or scrap; M10): that covers nest hatchlings and the Ashbrood's adds, which still pay wick that the level gap limits. A Hollow clear gives about 18-20 items, and loot stays finite.

**Salvage, no vendor.** Hold X (or Delete) on an item to salvage it: Plain gives 1 scrap, Bright 3, Rare 8; relics can't be salvaged. Amos sells a small stock for scrap. Kit re-cuts one affix on a lens or burner, once per item: a **cut line**, since it touches DESIGN §5's "no crafting". No gold.

**The bag** has 16 slots, +4 per satchel (3 built), +4 for the Wide Pack. You take a drop by walking over it (the 140 px magnet). If the bag is full, the item stays on the ground.

**Comparing on a pad.** In the Gear tab, the equipped item and the selected one sit side by side as cards, each stat marked ▲ gold or ▼ dim blue. A equips, hold X salvages, B goes back. Standing on a ground item shows one ▲ or ▼.

**Code:** GLoot data only, with our UI and our rolling code (#20), in `systems/loot/loot.gd` (new).

**Recommend:** this set (owner question 8).

---

## 11. NPCs and quests

People come back when their region is held, stand near its WayLamp, and never fight (PLAN_NPCS_ENEMIES §3). No main goal needs them. All five stay in v1 (#59/P7); Ivo is the cut line only if a milestone overruns.

| Person | Comes back when | Stands | Service | Errand → reward |
|---|---|---|---|---|
| **Amos**, trader | the Hollow is held | at the hut first. After the errand, at the cart by the Hollow WayLamp (78,124), on the road east | sells a small stock for scrap | **"Amos's cart"** (the south-Hollow side quest): the one cart is stuck among the quiet south packs. Clear them and plant a lamp by it. Then it rolls up to the WayLamp, and Amos gives the Wide Pack (+4 slots) and a Bright item |
| **Maud**, old pump keeper, who knew Oswin | the Reedmarsh is held | at the pumphouse | none | **"Maud's lamp"**: Maud's lamp lies in the north water among Slowwaters → the Smoulder burner and +1 flask charge |
| **Kit**, glazier's apprentice | the Ridge is held | at the workshop by the marsh climb's top (99,51) | re-cuts one affix (cut line) | **"Fire the kiln"**: bring the lens shard from a Ridge cache → the Long lens |
| **Ebba**, rower ("she") | the Lakeshore is held | at the shore end of the jetty | after the finale, rows you across the Lake to the island and the far shore (#54) | **"Show me the boat"**: put light on her boat (a lamp or a mirror beam) → the Shutter burner |
| **Ivo**, mapmaker | two regions are held | at the carved stone by the marsh passage | the map marks lures and caches in held regions | **"Walk the edges"**: read 3 survey stones → the map shows caches you haven't found |

**How talk works:** Dialogue Manager (#20), with one `.dialogue` file per person in `dialogue/` (new). The balloon uses `UiStyle`; A advances, B closes, the world pauses. Lines are DRAFT in STORY.md, and `check_docs.py` learns to read `.dialogue` files. The journal gains People and Errands pages.

**Recommend:** five people, with Kit's re-cut as the cut line.

---

## 12. World and route

The loop is built (ff8426b). It settles the one-way Ridge question: you climb from the marsh's north-west corner to the Ridge entry (100,56), then walk north-east past the glazier (99,51), lens, coat, station, WayLamp (120,30) and old steps (124,34). The old climb is a shortcut you open from above.

| # | Region | Levels | Find (the key) | WayLamp | Twist |
|---|---|---|---|---|---|
| 1 | The Hollow | 1-6 | the Post Lamp | (78,124), on the road east (built) | the calm start |
| 2 | The Reedmarsh | 6-8 | the Reservoir Lamp | proposed: the north island (168,102); built at (200,140) | water |
| 3 | The Windward Ridge | 8-10 | the Hooded Lamp | (120,30) (built) | gusts |
| 4 | The Lakeshore | 10-11 | the Mirror Post (#36) | the old landing, reached along a mirror-lit lane | thick fog |
| 5 | The Still Lake | 11-12 | the catch ring | the great lamp | ordinary light dies |

**The Reedmarsh's U-route.** Today you walk east to the pumphouse, then about 80 tiles back west across the water to the climb. The decided WayLamp move (#36) is not built: the code still has (200,140), and the loop's `DESIGN.md:389` wrongly says it is on the south-east island. Building that move before a new route makes the walk back longer, about 85 tiles from the far corner. **The proposal:** go out along the south and back along the north, with the WayLamp on the north leg; the find still comes first, as #36 wanted. Tiles come from `main.gd`'s constants.

| Leg | Path | About |
|---|---|---|
| In | passage exit (116,137), along the main boardwalk to x 132, south on x 132 to the south island (152,156); `frames_east` moves here | 60 tiles |
| South | a new boardwalk (152,158) to (176,158), down x 176 to the south-east island (200,166), wade north to the pumphouse (204,136): the find | 80 tiles |
| North | wade to the NE island (190,120), along the spur to x 176, north to the north island (168,102): **the WayLamp**. The Reservoir's lane is needed here | 50 tiles |
| Out | a new boardwalk west near y 100 to the cairn (127,92) and the climb (130,99) | 40 tiles |

That's about 230 tiles with no ground walked twice. Today it's about 170, half of it back the way you came. The main boardwalk (y 136) becomes the shortcut once the marsh is held. This is a sketch: M5 must lay it out and run a route test.

**Other places.** The Lakeshore and the Still Lake are rock today; scale PLAN_LAKESHORE §1.1 by two (the loop's note): the shore at about x 132-164, y 18-74, with the marsh climb staying at x 131 or less. **WayLamps:** touch your flame to one to wake its guardian (a fixed hold fight stands in until that guardian is built). At a lit WayLamp, interact offers Travel and Rest; Rest refills flasks and warmth, allows a respec, and never resets packs (brief §5). **Fast travel** as built: lit WayLamp to lit WayLamp, blocked while hunted, kindling or in a guardian fight.

**The faint rule** (replaces `player.gd:211-213`; AUDIT M19, §4.3):
1. You wake at the nearest lit light in the region at 60% warmth. Any light within 320 px of an unbeaten pack is skipped, so faints don't chain.
2. You keep everything you carry.
3. Your unspent wick waits where you fell (the built `WickDrop`). A second faint makes a second drop; nothing is lost until you collect them.
4. Cleared packs stay cleared. A partly beaten pack heals, sleeps again, and keeps its dead.
5. A mid-boss or guardian goes back to the start of the phase you reached, shell regrown. Its phase oil drops again on each try; the flask cap (5) stops any hoarding.

**Recommend:** the U-route with the north-leg WayLamp, and this faint rule (owner question 5).

---

## 13. Story

**What stays:** the letter and the name prompt; Oswin, "he", signing "- Oswin"; the notes; the Soul as "it", with big pale eyes; who took the light, but not why; no game over; the great lamp plate; the ending's last lines.

**What changes:** fireballs; WayLamps won by fighting; a finale fight and the portal; people speak; the loop.

**Texts to rewrite (listed only; all DRAFT for the owner):**
- **Fix now:** Oswin as "they" in STORY §1 and §4 and `README.md:25`; STORY's header counts (AUDIT M1, M10).
- **Goals:** `gather_fuel`, `relight_first`, `relight_waypost` (relight by touch); `build_reservoir`, `build_hooded`, `build_mirror` (using each lamp); the `kindle_*` lines (light it, then fight). `burn_nest` stays.
- **Tips:** cut `cold_lantern`, `low_lantern`, `dying_lantern`, `glass`. Rewrite `wickling_close` (teach Lampfire first), `lamp_empty`, `warmth_low`, `faint`, `gust`, `mirror_placed`, `waylamp_seen`, `kindle_attack`, `haven`, `burst`, `shell`, `dash`, `build_here`. New: flask, Fireglobe, Lance, rest, loot, level point, bag full.
- **WayLamp notes:** keep the inscriptions and Oswin's lines; rewrite the footer ("Feed it 15 fuel...").
- **Journal:** entry 13 ("I held the WayLamp") and entry 15 ("only the lake is left"); new entries per guardian.
- **The satchel and lamp-glass notes** (AUDIT M20). `crook_post` still fits.
- **Suggestions only** (the owner approved the current wording): the pumphouse's "Light has to be fed from somewhere" (nothing is fed now) and "The ridge has glass" (glass is no longer a resource); optionally the cairn's "The wind is worse up there", which reads oddly if the marsh has no wind ("The wind starts up there" would fit).
- **The loop's DRAFT lines** (ledger, cairn, pumphouse, `climb_north`, travel): approve them as they are, apart from the two suggestions above.
- **New lines:** a toast when the climb stones fall ("The way is open."); a chalk note on the stones, readable from the Hollow side ("Stones down. The way up is through the marsh."); skills, branch picks, items and relics; the bar and pack screens; every NPC line; the finale, portal and after-game lines.
- **Not in STORY.md yet** (AUDIT M23): the faint note, the boss-bar hints, the Ashbrood's toast.

**Recommend:** keep the voice and the mystery, and write all new text as DRAFT in STORY.md with the code (docs skill rule 2).

---

## 14. UI and HUD

The font is Ark Pixel only, at 20, 30, 40 or 60 (built `ui_style.gd`).

| Element | What |
|---|---|
| **Action bar** | Bottom centre, laid out like the pad: LT and LB left, Y middle, RB and RT right, the flask at the right end with 3-5 pips that flash when one comes back. 32 px icons, button labels at 20. Cooldown sweep and seconds; greyed when short of charge. |
| **Warmth and charge** | Two bars just above the bar, with skill-cost ticks on charge. In M1a, because the bar shows costs. |
| **Top of the screen** | Left: level, the wick bar and the scrap count. Centre: the goal banner (built). Right: chips only for "hunted" and "cold". The fuel, lamp and wind chips go. |
| **Foe bars, boss bar** | As built, plus the elite affix line (20 px) and "phase N / 3". |
| **Damage numbers** | Pop, then drift (brief §4). Grey when the gap cut the wick. |
| **Map** | As built, plus WayLamp icons, lures you've seen, and the share explored. |
| **Level-up** | A toast and a Skills-tab mark. The card screen (`level_up.gd`) goes in M2. |
| **The keeper's pack** | Gear, Skills, Journal and Map tabs (LB / RB). The Skills tab is greyed while you are hunted. Built in M2; the journal and map stay separate until then. |
| **Options** | A screen-shake slider and "reduce flashes", from M1a. Later, the auto-fire option. |

**Recommend:** the bar with health and charge beside it in M1a, and the pack screen in M2.

---

## 15. Art and audio direction

**Owner art is kept as drawn:** the Post Lamp, lit and cold, and its `.pxo` files. The palette and the 16x16-at-2x rule stay.

| Event | Feedback (brief §4) |
|---|---|
| Cast | additive flare at the lamp, slight recoil, sound |
| Flight | trail and glow; a small light that clears fog |
| Hit | white flash (built), sparks, small knockback, damage number |
| Burst / kill | Lampfire's light pop; 40-80 ms hit-stop on attacker and target only; a scorch mark that lingers |
| Fireglobe, Hearth ring | camera trauma, a ring flash, a burning-ground decal |

**Godot (brief §7):**
- **Additive `Sprite2D`** for every fireball, trail and blast; `PointLight2D` only for the hand lamp, lamps and WayLamps. Particles: `GPUParticles2D`, with a CPU fallback only if profiling says so.
- **Hit-stop:** replace the global `Engine.time_scale` freeze in `foe.gd` `_die()`, which would stutter at Lampfire's rate. **Shake:** port the trauma recipe (KidsCanCode) in place of the offset in `player.gd`.
- **Collision:** a ray or shape cast per tick for Lampfire, Lance and the Beam; `Area2D` with signals for globes and motes; `intersect_shape` for blasts; a long-lived `Area2D` for burning ground. Pool projectiles by detaching them.

**New art:** skill, flask and item icons; rarity glints; keeper cast and dash frames; sprites for the Spitwick, Clinker, nest, elite ring and Ashbrood; later, each region's creature and guardian; climb stones that read as a fallen pile, not a built wall.

**Audio** is the owner's job (#28), with Kenney sounds standing in until then. Needed: cast, hit and burst for each skill; flask; dash; rest; loot drops by rarity; boss phases; the portal.

**Recommend:** additive sprites and per-target hit-stop in M1a.

---

## 16. The code: keep, rework or cut

| System | Files | Verdict | Change |
|---|---|---|---|
| Combat kit | `scripts/player/combat.gd` | **rework** | One script per skill in `scripts/player/skills/` (new), on a shared `Skill` base. The aim hold and the Y rule live in `update_aim` (:30-44). |
| Projectiles | `scripts/enemies/spit_projectile.gd` | **rework** | One pooled `Projectile` for keeper and foes. |
| Status effects | `systems/status/` | **new** | Burning, stun, slow, chill and burning ground (brief §6). |
| Keeper | `scripts/player/player.gd` | **rework** | **Read combat input and the flask after `input_blocked()`** (:85 → after :101). Cut the ward (:161-180), refuel, gather, the fuel top-up (:69) and dimming. Add the flask, the regen table and the faint rule (:211-213). |
| Input | `tools/setup_input.gd`, `systems/input/input_hint.gd`, `scripts/ui/map_screen.gd` | **rework** | The §3 map. The D-pad comes off `move_*` (:31-34). `map` is read only when no menu is open (`map_screen.gd:54`). L3 only in a dev build (:55). |
| Foe base | `scripts/enemies/foe.gd` | **keep + extend** | Scaling, affixes, drops (none from `summoned`), per-target hit-stop. |
| Wickling | `scripts/enemies/wickling.gd` | **rework** | Cut lamp draining. Keep timid and brave, and smothering. |
| Other foes, packs, drops, spawner | `spitwick.gd`, `wick_nest.gd`, `clinker.gd`, `enemy_pack.gd`, `ember.gd`, `systems/threat/wickling_spawner.gd` | **keep; extend; repurpose; cut the trickle** | Shared projectile, region traits, `kl_clinker_hp` 48. Packs get elite affixes, and a partly beaten pack resets on a faint. `ember.gd` becomes `pickup.gd` (scrap, oil, items). The spawner keeps only hold swarms until each guardian exists. |
| Ashbrood | `scripts/enemies/ashbrood.gd` | **rework** | 150 hp a phase, phase 3, phase reset on a faint, oil at half of each phase, the dive snuffs a lamp for 8 s, adds at Lv 4. |
| Lanterns | `scripts/lanterns/lantern.gd` | **rework** | No tanks or fuel; snuff timer; new jobs; the limit and the replant delay. |
| Resources, finds | `resource_node.gd`, `landmark.gd` | **rework; keep** | One-off scrap piles; fuel and glass cut. Satchel → bag slots (M3); lamp glass → charge (M1b). |
| WayLamps | `scripts/world/waylamp.gd` | **rework** | Lit by touch, guardians, Rest. |
| Travel, stones, lures, wick drop | `travel_menu.gd`, `climb_stones.gd` (the loop), `post_lure.gd`, `wick_drop.gd` | **keep + extend** | Rest beside Travel. The stones get the toast, the note and the fallen look (M6). One lure class with six looks. |
| World | `scripts/main/main.gd`, `map_chunk.gd` | **rework** | Cut fuel, glass and the woodpile; data tables per region; move pack 11 and nest 7 (loop `main.gd:546`, `:530`); the marsh U-route; regions 4 and 5. |
| Fog, light, wind | `fog_grid.gd`, `light_sense.gd`, `light_tex.gd`, `wind.gd`, `wind_streaks.gd` | **keep; rework wind** | Projectile lights, thick fog, no "dying" snapshot. Wind is Ridge only (snuff and drift, M6) and inert from M1b until then. |
| Progress, inventory, loot | `progress.gd`, `inventory.gd`, `systems/loot/loot.gd` (new) | **rework; new** | Points, tiers, the bar, gear; scrap only and the GLoot bag. Level-gap code unchanged. |
| Save | `save_game.gd` | **rework** | Version 5 in M1a (bar, flasks); later sections add to it. Old saves start fresh. |
| Story, tuning | `story.gd`; `tuning.gd`, `debug_panel.gd` | **keep; rework** | Text per §13. Cut tending, ward and fuel numbers; add §4-§9 numbers and F1 rows. |
| HUD | `hud.gd`, `world_prompt.gd` | **rework** | §14. |
| Other UI | `build_menu.gd`, `lantern_markers.gd`, `level_up.gd`; journal, map, foe and boss bars, pause, note, opening, pointer, slots, `ui_style.gd` | **cut; rework; cut in M2; keep** | The lamp list gives way to D-pad cycling; markers only for unlit old lamps; the card screen gives way to the Skills tab (M2). The rest keep small changes; the pad name grid comes in M9. |
| Add-ons | `addons/dialogue_manager/`, `addons/gloot/`, `dialogue/` | **new** | Keep each LICENSE file; add rows to `assets/CREDITS.md`. |
| Tests | `tools/tests/` | **rework** | Per milestone in §18. New: `test_skills`, `test_flasks`, `test_input`, `test_faint`, `test_loot`, `test_npcs`, and a marsh route test. |
| Bench | `tools/bench/bench.tscn` | **extend** | 40 projectiles and 4 burning areas, logic still under 4 ms. |

**Recommend:** rework in place, one branch per milestone.

---

## 17. The docs

| New doc set | Job |
|---|---|
| `docs/DESIGN.md` | **Rewrite** from this plan: the game as built, with planned parts marked. |
| `docs/STORY.md` | **Keep and refresh**: every player-facing text, NPC lines included. Fix the pronouns now. |
| `docs/DECISIONS.md` | **Keep**, append-only, with a "standing decisions" index at the top. |
| `docs/ROADMAP.md` | **Rewrite** from §18; M0-M4 become a history note. |
| `docs/PLAYTEST.md` | **Keep**. Add the fuel-and-abilities results; archive the pre-ARPG sections. |
| `docs/ART_CHECKLIST.md` | **Keep**. Add skills, items, foes, people and the fallen stones; drop the PROTOTYPE tags. |
| `docs/archive/` (new) | Retired plans, unchanged. `docs/replan/` goes here once DESIGN and ROADMAP are rewritten. |
| `docs/research/ARPG_REFERENCES.md` | **Keep** as a reference. |

| Current doc | Verdict |
|---|---|
| The four PLAN_*.md files | PLAN_KEEPERS_LIGHT and PLAN_ONBOARDING: **retire** to the archive (harvested in §8, §10, §12). PLAN_LAKESHORE: **merge** into DESIGN in M7. PLAN_NPCS_ENEMIES: **merge** the people into STORY and DESIGN. Then retire both. |
| README.md | **Rewrite** when M1b merges to `main`. Fix the pronoun and the stale WayLamp line on `main` now. |
| AGENTS.md, CLAUDE.md | **Keep**. In AGENTS: "Scope follows the game plan and ROADMAP"; fix "REAPER"; add the new tests. |
| `.agents/skills/lantern-keeper-docs/SKILL.md` | **Keep**. Oswin is "he"; update the doc table, `docs/archive/` and `.dialogue`. |
| `.agents/skills/lantern-keeper-arpg/SKILL.md` | **Rewrite** the pillars from §1, §4 and §10; keep the balance method. |
| LICENSE-ASSETS.md, `assets/CREDITS.md`, `assets/art/placeholders/README.md` | **Keep.** Add the add-ons to CREDITS when they arrive, and the missing satchel and lamp-glass rows to the placeholders README (AUDIT M27). |
| `tools/check_docs.py` | **Extend** to `.dialogue` files, skill and item texts, and AUDIT M23's strings. |

**Recommend:** archive, don't delete.

---

## 18. Milestones and build order

**Scope traps (brief §6):** no co-op and no extra platforms before v1; one projectile system and one status system; no second progression track; one region fully playable before the next; cut lines (the Tallest, Kit's re-cut, Ivo, Moth-lights' tier 3).

Every milestone ends with an owner playtest on a gamepad. **Merge to `main` once M1b passes.**

### M1a: Fire in the Hollow
- **Scope:** Lampfire, Fireglobe, Lance and the dash. The Beam (7.5 hp/s) and Hearth ring as optional picks in a plain Skills list. The action bar and HUD bars on pad and keyboard/mouse; aim assist and aim hold; the Y rule; the flask on B after the guard; the D-pad off movement. The §5 regen table; oil from packs, elites and the Ashbrood; Rest at a lit WayLamp (flasks and warmth); Clinker and Ashbrood health set by hand against today's curve (M1b re-checks them with scaling); summoned foes drop nothing. The juice baseline, the shake slider and "reduce flashes"; save version 5. **Stays as built for now:** lamps still burn, the WayLamp still takes fuel, and the old cards stay until M2.
- **Owner checks (pad only, one WayLamp lit):**
  1. A new game reaches the lit Hollow WayLamp without a keyboard. Your name stays "Keeper" (no pad letter grid until M9).
  2. RT, RB, LB and LT fire while you move and aim, and the right thumb never leaves the stick.
  3. Holding RT and pressing B drinks, and the fireballs keep their aim.
  4. Closing the journal, map, a note and the pause menu with B never spends a flask.
  5. Moving through every menu with the D-pad never opens the map or moves the keeper.
  6. Cooldowns sweep, and a skill short of charge greys out.
  7. The first packs fall to Lampfire, Fireglobe and Lance alone.
  8. **Are the fire skills fun?** The owner marks each one keep, rework or cut in PLAYTEST.md.
  9. **Keep the Beam?** Try it in LB at level 1 and again after level 2, then record keep or cut. The same for Hearth ring.
  10. Mid-fight, standing in a lamp's light refills charge only slowly.
  11. Packs drop oil, the Ashbrood drops oil halfway through each phase, and resting at the lit WayLamp refills.
- **Tests:** `test_combat` becomes `test_skills`. New `test_flasks` and `test_input` (B after each menu, the D-pad through each menu). The bench runs 40 projectiles.
- **Risks:**
  - Feel is most of the work (PLAN_KEEPERS_LIGHT §10). If the fire doesn't feel good, do one more feel pass before M1b.
  - RT and RB on one finger; the auto-fire option is the fallback.
  - Fog lights cost more than the budget allows.

### M1b: No more tending
- **Scope:** lamps never burn, in every region's code paths; fuel and glass cut; scrap piles one-off; the woodpile becomes scenery. Old lamps and WayLamps lit by touch. The lamp limit and the replant delay. The faint rule. Hollow foe levels 1-4 (Ashbrood 5), foe scaling, and the curve at 7 and 1.65. The lures; the Hollow's goals and tips; the lamp glass gives charge. Ridge wind goes inert until M6.
- **Owner checks:**
  1. No prompt, tip or HUD item says fuel, refuel or gather, and lamps never dim.
  2. The hut lamp, the north-path lamp and the WayLamp light by touch; the WayLamp wakes the Ashbrood.
  3. A 4th lamp outside held ground is refused, with the reason. A picked-up lamp can be planted again after 15 s.
  4. After a faint, cleared packs stay cleared, a half-fought pack is whole and asleep, the Ashbrood restarts its phase, and nothing carried is lost.
  5. A pack, a nest and an elite look different through the fog.
  6. The last Hollow level comes on the Ashbrood kill.
- **Tests:** rewrite `test_core`, `test_threats` (light reactions; the ward goes), `test_waylamps` (light by touch, hold fights) and `test_upgrades` (the lamp glass part). **`test_ridge`:** keep its layout, trail and placement checks; delete its tending, ward and wind-burn checks (wind checks return in M6). New `test_faint`. `test_leveling` checks level 2 at the crook and the Ashbrood kill on both routes (L5 beeline, L6 explorer).
- **Risks:** hidden fuel dependencies (goals, prompts, HUD); old saves start fresh.

### M2: Builds
- **Scope:** skill points and fixed branches, tiers 1-3, for Lampfire, Fireglobe, Lance and the dash (the Beam and Hearth ring only if kept). Respec at rest. The pack screen with Skills, Journal and Map tabs; the card screen goes. Elite affixes. The Ashbrood's phase 3.
- **Owner checks:** at level 2, choose a pick that changes how a skill behaves, on the pad. Tier 3 opens on the Ashbrood kill. Respec at the WayLamp. Swap a skill with View, the D-pad, A and B. An elite shows its affix.
- **Tests:** `test_skills` covers gating, respec and saving.
- **Risks:** 12-18 picks to build and tune. Start with tier 1 if time is short.

### M3: Loot
- **Scope:** GLoot data; 4 slots with Plain starting gear; 3 rarities; the Ashbrood's relic; 20 affixes; drops; the bag and compare; salvage; satchels → bag slots.
- **Owner checks:** compare and equip in under 5 s on the pad; a Hollow clear gives about 18-20 items; hold X salvages; a nest left hatching drops no items.
- **Tests:** `test_loot` (seeded rolls, rates, stacking, summoned foes drop nothing, save); `test_upgrades` (satchel).
- **Risks:** tuning multiplies; GLoot on 4.7.2 is untested.

### M4: People, part 1
- **Scope:** Dialogue Manager, the balloon, People and Errands pages, Amos and "Amos's cart".
- **Owner checks:** talk with A, close with B; lines match STORY.md; the errand shows in the journal; the Wide Pack adds 4 slots.
- **Tests:** `test_npcs`; `check_docs` reads `.dialogue` files.
- **Risks:** Dialogue Manager on 4.7.2 is untested.

### M5: The Reedmarsh
- **Scope:** the U-route (§12) and the north-leg WayLamp; 26 packs at Lv 5-7; Slowwater, Fenlight, the mire Clinker, the Sump and its relic; the Reservoir's job; Moth-lights at level 7; Maud; Ivo (cut line).
- **Owner checks (pad):** walk from the marsh's entry to the climb without crossing your own path; Reservoir light brings the Sump up; Moth-lights on Y; level 8 by the climb.
- **Tests:** a marsh route test like the loop's; `test_leveling` for the region.
- **Risks:** water readability; Slowwater fairness.

### M6: The Windward Ridge
- **Scope:** 22 packs at Lv 8-9; gusts that snuff and drift; the Gutterkite; the Hooded Lamp's job; the downwind Clinker; the Galekite and its relic. Wheeling flame (level 9); Oswin's coat; Kit and the Long lens; the re-cut (cut line). **The loop's stones:** the "The way is open." toast, a note readable from below, and stones drawn as a fallen pile. Pack 11 (52,93) and nest 7 (60,91) move off the foot of the old climb (loop `main.gd:546`, `:530`), so the shortcut lands on quiet ground.
- **Owner checks (pad):** the Ridge is one walk; a gust snuffs exposed lamps and pushes fireballs; the Galekite snags on a Hooded Lamp; coming down the old climb, the stones fall with the line, and from below the note reads.
- **Tests:** `test_ridge` wind checks; the loop test's stones checks.
- **Risks:** wind punishing more than it teaches.

### M7: The Lakeshore
- **Scope:** carve region 4; thick fog; the Mirror Post; the Fogstilt; the fog Clinker; the Tallest and its relic (first cut); Ebba.
- **Owner checks (pad):** a mirror lane is the quick way through the fog; fire crossing a beam on a Fogstilt unravels it.
- **Tests:** shore route and fog tests.
- **Risks:** fog too slow; the Tallest's scope.

### M8: The Still Lake and the finale
- **Scope:** region 5; the catch ring; the Soul in three phases; the portal; the ending and sandbox; Ebba's crossing.
- **Owner checks (pad):** the Soul takes 6-10 minutes; a faint returns you to the start of the phase; the portal and the credits; the valley stays open.
- **Tests:** finale phase test.
- **Risks:** the biggest milestone; phase 2 depends on M5-M7.

### M9: Polish and the Linux build
- **Scope:** owner art and audio; a pad letter grid for the name; accessibility; a full balance pass; 3+ external playtests; a Linux export on a clean machine.
- **Owner checks:** the DESIGN "done when" list.
- **Risks:** polish creep. Hold the cut lines.

---

## Decisions this plan would supersede

None is settled. The owner can approve the table as a whole and strike rows (question 9). The numbers are AUDIT §3 rows.

| # | Decision now | Proposed |
|---|---|---|
| 7 | Level 8 on the Ashbrood kill | Level 6 (5 on a pure beeline); still the Hollow's last level (#17). §9 |
| 11, 29 | A second cold old lamp, relit with fuel; the pointer on the woodpile until you have fuel | Both old lamps (hut, north path) relit by touch; the woodpile is scenery. §6 |
| 13, P11, 60 | Onboarding tips and goals teach the beam and fuel first; WayLamp texts approved | Rewritten as DRAFT: Lampfire first, relight by touch. WayLamp inscriptions kept; the footer and entries 13 and 15 rewritten. §13 |
| 16 | Foe levels 1-6 by the WayLamp; Ashbrood Lv 7 | Hollow foes 1-4, Clinker 4, Ashbrood 5; the gap formula is unchanged. §8.2, §9 |
| 18 | Four cards approved "as written" | Effects and names kept, in branches (Steady hand, Spill) and fixed gear lines (Hot core 2x, Lee 25%). The card screen goes. §4.3 |
| 19 | Slots lens, burner, coat, wick, tied to beam and burst | Same names, new jobs (lens for direct hits, burner for blasts). §10 |
| 36 (part) | The Reedmarsh WayLamp moves to the south-east island | The north island (168,102), with the U-route; the find still comes first. §12 |
| 37, P1, 113 | Charge topped up by carried fuel; the hand lamp uses fuel | Regen table, Lampfire hits and flasks; no fuel; the lamp never goes out. §5 |
| 39 | Beam, burst and dash as the core; pick-1-of-3 | Lampfire and Fireglobe lead; the Beam and Hearth ring are optional; fixed branches. ARPG, guardians and "the find is the key" stay. §4 |
| 42 | WayLamps take 15 fuel | Lit by touch; the guardian is the cost. §12 |
| 46 | Tap refuels, hold gathers | Cut; scrap taken with one press. §5 |
| 51, P4 | The Lakeshore WayLamp reached only by a beam | Reached along a mirror-lit lane. §12 |
| 52, 93 | Glass as a resource; worn glass on the shore | Glass stops being a resource. §5 |
| 58 | The Clinker roams | A fixed mid-boss per region. §8.2 |
| 59, P7 | All five people in v1 | Kept; Ivo is the cut line only if a milestone overruns. Needs an OK. §11 |
| 64, 101 | A faint drops half your fuel and scrap | Nothing carried is dropped; wick waits; cleared packs stay cleared. §12 |
| 65 | Satchels +10 carry; lamp glass cheapens the ward | Satchel +4 bag slots; lamp glass +12 px and +0.1 charge. §5, §10 |
| 67, 68, 107 | A held region refills lamps; only dying lamps can be drained; cold lamps findable, low lamps pulse | Held ground is safe, with no lamp limit, rest and travel; no draining; cold markers cut except the lure on unlit old lamps. §6 |
| 75 | Mirrors turn both ways (X/Space for left) | Kept: X or C next to a mirror turns it left; A or E turns it right. §3 |
| 76, 79 | Tab/Y lamp list and keys 1-4; HUD fuel count and lamp chips | D-pad cycling; the bar; no fuel or lamp chips. §3, §14 |
| 92, 94, 108 | Wind burns exposed lamps, valley-wide | Ridge gusts snuff and drift; the Hooded Lamp never snuffs. §6 |
| 98, 99 | Embers worth 1 fuel; 35% scrap | Loot-table drops; summoned foes drop nothing. §10 |
| DESIGN §5 | No crafting beyond lamps | Salvage is in; Kit's single re-cut is a cut line. §10 |
| DESIGN §5 | Target playtime 1-2 h | Perhaps 5-7 h (a guess). §2 |

---

## 19. Owner questions

Each question is tagged with the milestone that needs its answer. My recommendation for each is yes.

1. **[before M1a] Is this the kit you meant by fireballs?** Lampfire on RT (a fireball that bursts on impact) and Fireglobe on RB (a big lobbed fireball), both from level 1; Lance on LB from level 2. The Beam is optional: in LB at level 1 only, then in the Skills tab. The old burst becomes Hearth ring, optional and off the bar; Y starts empty. Recommended because it leads with fire and still lets you judge the Beam.
2. **[before M1a] The pad map?** Aimed skills on RT, RB and LB; dash on LT; Y self-cast only; the flask on B, read after the menu guard; the D-pad off movement, holding the map and lamp keys. Recommended because every aimed input keeps your thumb on the stick, and no menu press leaks into play.
3. **[before M1a] Light in a fight?** Warmth from light only when nothing hunts you. Charge from light drops from 0.5/s to 0.1/s while hunted. Flasks heal in fights. Recommended because otherwise flasks don't matter and lamps make fights trivial.
4. **[before M1b] Lamps and WayLamps?** All lit by touch; lamps never burn. At most 3 planted outside held ground, with a full refund and a 15 s replant delay. WayLamps cost a guardian fight, not fuel. Recommended because no fuel economy remains, and the limit keeps havens a choice.
5. **[before M1b] The faint rule (§12)?** Cleared packs stay cleared, nothing carried is lost, wick waits where you fell, and bosses keep their phase. Recommended because it fixes the reset bug (AUDIT M19) and keeps loot finite.
6. **[before M1b] Levels?** Base 7, exponent 1.65, cap 12. The Hollow ends at 6 (not 8), then 6-8, 8-10, 10-11, 11-12, with Hollow foes at 1-4. Recommended because it is the only setting in the simulation that lands every region.
7. **[before M2] Fixed branches replace the cards?** Every pick changes a skill's behaviour. Hot core and Lee become fixed gear lines with their approved values. Recommended because changed behaviour is what makes picks memorable (brief §3).
8. **[before M3] One material, and salvage?** Scrap only, salvage in, and Kit's single re-cut as a cut line (DESIGN §5's crafting rule). Recommended because three currencies plus loot is the tuning trap (brief §6.2).
9. **[any time; pronouns before M4] Approve the supersede table as a whole**, striking any rows you don't accept. And give pronouns for Amos, Maud, Kit and Ivo, or keep none.

---

## Review items not adopted

- **B1, step 4** (Firepot at level 2, Lance at 3): the coordinator asked for the lobbed fireball at level 1, so Fireglobe is level 1 and Lance level 2.
- **B1's "no damage to shells" for the fireball:** Lampfire's hit does half to shells, so the basic attack can always break the crook guard's shell. Fireglobe does none.
- **M4's timed aim latch:** I chose "Y takes only self-cast skills" (§3), and kept the aim held only while a fire button is down.
- **M12, putting foe scaling in M2:** it stays in M1b, because the curve and the time-to-kill targets depend on it, and it is one formula in `foe.gd`.
- **M12, the HUD bars in M2:** they stay in M1a, because the bar shows skill costs against charge.
- **M13's dev-only second WayLamp:** dropped. The travel half of that check is simply gone.
- **Minor 4, the "wick" slot name:** the owner chose it (#19), so it is flagged, not renamed.
- **Minor 10, a pad name grid in M1:** deferred to M9; M1a check 1 accepts "Keeper".

## Uncertainties

1. Every number is a starting value. The curve and the wick budgets come from my simulation of the built gap rule, not from `test_leveling`. The time-to-kill figures assume linear scaling and the uptimes stated.
2. The content budgets for the marsh, Ridge, Lakeshore and Lake (pack counts) are proposals; those regions have no Keeper's Light foes yet.
3. The U-route is sketched from `main.gd`'s constants, not laid out or walked.
4. The playtime of 5-7 h is a guess.
5. Dialogue Manager and GLoot on Godot 4.7.2 are untested here.
6. The cost of projectile fog lights is unmeasured.
7. That the owner's "ward" meant the burst is the review's inference. Question 1 lets the owner confirm it.
