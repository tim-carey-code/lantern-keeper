# Lantern Keeper: game plan (re-plan)

**DRAFT for owner approval, 2026-11-27.** This is a proposal, not a decision. Nothing here is settled until the owner marks it up. Where it changes an earlier owner decision, it says so under "Decisions this plan would supersede", and each of those needs the owner's OK.

**Inputs.** `docs/replan/AUDIT.md` (cited as AUDIT §n), `docs/research/ARPG_REFERENCES.md` (cited as brief §n), `docs/DECISIONS.md` (decision numbers are the rows of AUDIT §3), and the loop build on `proto/kl-loop` at `ff8426b` (cited as "the loop"). The loop is treated as built.

**How to read it.** Every section ends in one recommendation, not a menu. Numbers are starting values for tuning; names in `code font` are `systems/tuning.gd` entries, and "(new)" marks one that doesn't exist yet. Every in-game text named here is DRAFT. Oswin is "he", Ebba is "she", the keeper is "they"; Amos, Maud, Kit and Ivo have no pronouns yet, so none are used.

**Original design only.** Diablo, Path of Exile, Last Epoch and the rest are references for mechanics. No names, characters, art or levels come from them.

---

## 0. In short

1. An action RPG in a dark, foggy valley. The keeper's hand lamp throws fire-light. Light is still shelter, but now you take it by force.
2. No lamp tending. Lamps you plant never burn out. Fuel becomes lamp oil: three flask charges that heal and refill your charge.
3. Six combat inputs on a pad, all usable while you aim: RT basic bolt, RB and LB aimed skills, Y an unaimed skill, LT dash, B flask.
4. Skills: Spark (the free basic bolt), Flare, Lance, Firepot (the big lobbed AoE), Moth-lights, and the Beam as an optional pick. Three skill slots plus Spark.
5. Each level gives one point for a fixed branch on a skill. The random "Trim the wick" cards go. All 12 card effects move into branches or gear.
6. Lamp charge is the skill resource. Spark hits refill it, light refills it fast, and it never drains by itself. Warmth heals in light only when nothing hunts you. In a fight, only flasks heal.
7. Loot: three random rarities plus a few hand-made relics, four slots (lens, burner, coat, wick), 20 affixes. Salvage into scrap. No gold.
8. One carried material, scrap. Fuel and glass stop being resources.
9. WayLamps are lit by your flame, at no cost. Lighting one wakes its guardian. Lit WayLamps are fast travel (built) and the place to rest.
10. Five people come back as regions are held, through Dialogue Manager. Amos brings a side quest to the south of the Hollow.
11. Level cap 12. The Hollow ends at level 5, so every later region has levels to give.
12. First build: the Hollow as a vertical slice, checked on a gamepad. Then loot, people, and one region at a time.

---

## 1. Pitch and pillars

**Pitch.** You are the valley's new keeper. Your hand lamp throws fire-light. Burn back what lives in the fog, take the old WayLamps back one by one, and follow Oswin, the last keeper, to the cold great lamp at the Still Lake.

**Feeling (kept, DESIGN §1):** calm, moody, curious and rewarding, with a quiet unease.

**Pillars.**
1. **Light is your weapon.** Fire-light skills from the hand lamp, aimed with the right stick or the mouse.
2. **Light is your shelter, and you carry it.** Planted lamps and lit WayLamps are pockets where you refill. No upkeep.
3. **The find is the key.** Each region's find is a lamp. It opens that region's lock and answers one phase of its guardian (PLAN_KEEPERS_LIGHT §3.1).
4. **Readable fights.** Every big hit has a tell. Every foe has a name, a level and a bar (built, AUDIT §1.1).
5. **Every fight pays, once.** Fixed packs, level-gap wick and loot. Cleared ground stays cleared.
6. **Calm at the edges.** A calm start, quiet held ground, and no game over.
7. **Show, don't list.** Lures through the fog and short notes pull you on.

**The ARPG adds** build choices (skills and gear), loot to compare, guardians, and a level curve across five regions. **It removes** tending, gathering, "planning over reflexes", "light is safety" and the quiet finale (AUDIT M14, M15).

**Recommend:** these seven pillars. They replace DESIGN §1 and the pillars in the ARPG agent skill.

---

## 2. The core loop

| Scale | What you do | What you get |
|---|---|---|
| **A minute** | Aim. Spark to build charge. Spend it on a skill. Dash through the tell. Drink a flask when low. Loot pops. Step into light between fights. | Wick, scrap, oil, sometimes an item |
| **A session (15-30 min)** | Start at a lit WayLamp and rest (full flasks). Push toward a lure. Clear 3-5 packs and an elite, maybe a cache. Swap gear and spend a point. Reach the find or the next WayLamp. Fight its guardian. Travel back to a person, or go on. | A level or two, a few items, a region held |
| **The whole game (5-7 h, a guess)** | Five regions on one clockwise loop. Each has a find, a twist, a mid-boss and a guardian. Levels 1-12. Gear from Plain to Rare, plus relics. The finale: the Soul of the Wick retreats through a portal. The valley stays open. | The great lamp relit, and a hook for later |

The playtime guess is longer than the old 1-2 h (DESIGN §5) and the 3-4 h in PLAN_KEEPERS_LIGHT §9. It is not a measurement.

**Recommend:** this loop. The minute-scale loop is the one M1 must make feel good.

---

## 3. Controls and the action bar

**The constraint.** Aiming is twin-stick: the left thumb moves, the right thumb aims. So a skill used while aiming goes on a shoulder or trigger. Face buttons are for skills that don't aim, or for moments out of a fight. Six combat inputs is the proven pad ceiling (brief §1, finding 1), and we use exactly six, with no held-modifier second bank.

| Slot | Pad | Keyboard / mouse | Default | Notes |
|---|---|---|---|---|
| 1, basic | **RT** (hold) | Left mouse (hold) | Spark | Always Spark in v1 |
| 2 | **RB** | Right mouse | the Beam at level 1 | Aimed |
| 3 | **LB** | Q | Lance from level 2 | Aimed |
| 4 | **Y** | F | Flare | On a pad, fires along your last aim: best for skills that don't aim |
| Dash | **LT** | Space (Shift too) | Dash | Goes the way you move |
| Flask | **B** | R | Lamp oil | B still means "back" in menus |

| Out of a fight | Pad | Keyboard / mouse |
|---|---|---|
| Interact, read, talk, rest, travel | A | E |
| Pick up your planted lamp | hold A on it | hold E on it |
| Plant a lamp | X | C |
| Next / previous lamp kind | D-pad right / left | Tab / Shift+Tab |
| Map | D-pad up | M |
| The keeper's pack (Gear, Skills, Journal, Map tabs) | View | I, K, J |
| Pause; tuning panel (dev) | Start; L3 | Esc; F1 |

This moves the map off LB, the lamp list off Y and Tab-hold, pick-up off B and Q, and building off Space (`tools/setup_input.gd`). Keys 1-4 no longer pick lamps.

**Binding.** In the Skills tab, pick a slot, then a skill. Any skill fits slots 2-4. You can swap anywhere except while something hunts you (the loop's `travel_hunt_radius`, 384 px). A new skill fills an empty slot by itself.

**Showing cooldowns and charge** (brief §1, an inference): a dark radial sweep over each icon, with seconds shown if more than 3 are left. A slot greys out when you lack the charge. The flask slot shows its charges as pips. Each slot shows the button for the last device used (`systems/input/input_hint.gd`, built).

**Aim assist.** A gentle pull toward a foe within 12 degrees, for Spark and Lance, on pad only. PLAN_KEEPERS_LIGHT §2.6 left it for later. The owner plays on pad, so it belongs in M1.

**Recommend:** this map (owner question 8).

---

## 4. Skills

### 4.1 The kit

All numbers are starting values. Shell damage follows 4.5.

| Skill | Unlock | Does | Starting numbers | Shells |
|---|---|---|---|---|
| **Spark** (basic) | level 1 | A quick bolt of fire-light. Free. Each hit gives charge back. Lights the fog as it flies. | 2 dmg, one per 0.3 s held, 520 px/s, 320 px, +0.04 charge a hit (`kl_spark_dmg`, `kl_spark_period`, `kl_spark_speed`, `kl_spark_range`, `kl_spark_charge_gain`, new) | half |
| **Flare** | level 1 | The built burst: a ring that hurts and throws foes back. | 120 px, 2 dmg, 140 px throw, 3 s cooldown, 0.2 charge (`kl_burst_*`) | none |
| **Beam** (optional) | level 1 | The built beam: hold to channel along your aim. No charge regen while it is on. | 240 x 24 px, 6 hp/s, 0.3 charge/s, walk 70% (`kl_beam_*`) | full |
| **Lance** | level 2 | A fast piercing bolt: the shell-breaker. | 7 dmg, 700 px/s, 360 px, through 3 foes, 0.18 charge, no cooldown (`kl_lance_*`, new) | full |
| **Firepot** | level 3 | The big lobbed AoE. A pot of burning oil lands where you aim and leaves burning ground. | lands 120-280 px out (stick tilt, or the cursor clamped), 0.6 s flight with a ground marker, 90 px blast, 8 dmg, 3 s of burning ground at 3 dps, 0.3 charge, 6 s cooldown (`kl_firepot_*`, new) | none |
| **Moth-lights** | level 5 | Three motes of light circle you, then seek foes. | 3 dmg each, seek within 240 px, 4 s life, 0.25 charge, 5 s cooldown (`kl_moth_*`, new) | half |
| **Dash** | level 1 | The built dash. Nothing chills you mid-dash. | 110 px in 0.16 s, 0.9 s cooldown, 0.08 charge (`kl_dash_*`) | — |

**The level-1 bar:** Spark, the Beam, an empty LB slot, Flare. The Beam sits on RB because the owner wants to keep trying it ("keep as optional for now", DECISIONS 2026-11-27). Lance fills LB at level 2. Firepot arrives at level 3 with no free slot: the first real choice.

### 4.2 Branches instead of cards

The brief's model fits a 12-level cap (brief §3): three branches per skill, one pick each, with the last pick changing behaviour. Random pick-1-of-3 offers suit run-based games, not ours (brief §3).

- **One point per level-up:** 11 by level 12. Seven skills x three tiers is 21 tiers, so no two keepers match.
- **Tier 1** is open once you have the skill (pick 1 of 2). **Tier 2** needs tier 1 and level 4 (1 of 2). **Tier 3** needs tier 2 and level 7 (1 of 3 variants that change behaviour).
- **Free respec when you rest at a lit WayLamp** (brief §3). No per-skill XP (brief §3, §6).

| Skill | Tier 1 (pick one) | Tier 2 (pick one) | Tier 3 variant (pick one) |
|---|---|---|---|
| Spark | *Twin*: two bolts in a V, 60% each · *Lingering burn*: hit foes burn 2 s at 2 dps | *Quick hand*: one per 0.22 s · *Bright*: +50% charge per hit | *Catching*: a kill sets the nearest foe within 60 px alight · *Ricochet*: bounces once · *Needle*: pierces one foe |
| Flare | *Heavy flare*: throw x1.5, stun 0.6 s · *Wide*: 160 px | *Spill*: 2.2 s cooldown, +0.03 charge per foe hit · *Warm flare*: +2 warmth per foe hit | *Ring of fire*: a burning ring for 3 s · *Sunburst*: also throws 8 Sparks · *Crackle*: strips 2 shell from each foe |
| Lance | *Long lance*: 480 px · *Tight focus*: shells wear 30% faster | *Pierce more*: 5 foes · *Lean*: 0.12 charge | *Splitting*: 3 Sparks at the end · *Returning*: flies back through foes · *Brand*: the next hit on a branded foe does +50% |
| Firepot | *Big pot*: 120 px · *Slow burn*: ground burns 5 s | *Second pot*: another lands 0.3 s later · *Quick pot*: 4 s cooldown | *Cluster*: bursts into 4 small pots · *Slick*: burning ground slows foes 40% · *Beacon*: the pot stays lit 6 s as a tiny lamp |
| Moth-lights | *Swarm*: 5 motes · *Long-lived*: 6 s | *Far-seeing*: seek within 360 px · *Fed*: each moth hit gives 0.02 charge | *Orbit*: circle you 6 s and block spit · *Great moth*: one moth, 12 dmg, bursts · *Homing home*: motes that end near your lamp return |
| Beam | *Steady hand*: walk at 90% · *Long throw*: 310 px | *Deep tank*: cost x0.8 · *Tight focus*: shells wear 30% faster | *Prism*: three thin beams · *Searing*: up to +50% over 1.5 s on one foe · *Kindling*: each second on a foe cuts Flare's cooldown by 1 s |
| Dash | *Second step*: two dashes per cooldown · *Long step*: 150 px | *Cinder trail*: burning ground along the path · *Quick step*: 0.6 s cooldown | *Phase*: pass through foes, stun them 0.4 s · *Flare step*: a Flare at the end · *Ember rest*: a 3 s ember that counts as light for charge |

### 4.3 Where the 12 cards go

Every card in `scripts/ui/level_up.gd:4-18` keeps its effect, and the four approved cards keep their names.
- **Into branches:** Lingering burn and Catching (Spark, tiers 1 and 3); Tight focus (Lance tier 1, Beam tier 2); Long throw and Deep tank (Beam, tiers 1 and 2); Second step (Dash, tier 1); Heavy flare (Flare, tier 1); **Steady hand** (approved: Beam, tier 1); **Spill** (approved: Flare, tier 2).
- **Into gear affixes (§10):** Kindled kills (wick: charge on kill); **Hot core** (approved: wick, your lamps' cores burn harder); **Lee** (approved: coat, touch chills less).

### 4.4 Do region finds unlock skills?

**No.** Finds unlock lamps, which are the keys (§6): the Post Lamp, Reservoir, Hooded Lamp and Mirror Post. Skills come with levels, so the bar grows at a pace you can learn. Guardians drop relics (§10), and some relics change a skill. That links regions to skills without a second unlock track.

### 4.5 The shell rule

Full damage from Lance, the Beam and mirror beams. Half from Spark and Moth-lights. None from Flare, Firepot, burning ground or lamp cores, which glance off with a clink (built). Flare's *Crackle* is the one area pick that strips shell. Shells regrow after 3 s out of focused fire, until broken (`kl_shell_regrow_wait`, built). So Spark can always break a shell slowly, and Lance covers the Beam's job, which is what keeps the Beam optional.

### 4.6 Time-to-kill targets (written first, as the ARPG skill asks)

A same-level Wickling dies to 2 Sparks. A same-level shelled elite takes 3-5 s. A 4-foe pack takes 8-12 s and costs under 30% warmth. A mid-boss takes 30-60 s. A guardian takes 2-4 minutes, with 1-3 faints the first time (PLAN_KEEPERS_LIGHT §4.4).

**Recommend:** branches, not cards (owner question 3), with the kit above.

---

## 5. Resources

**Warmth (health).** 100 at level 1, +8 a level (`warmth_max`; `kl_warmth_per_level`, new). The coat adds more.
- **The regen stance:** warmth heals only in light (a lamp, a WayLamp or a Firepot *Beacon*), and only while nothing hunts you. Then it is quick: 20/s (`warmth_regen_per_sec`). "Hunted" reuses the loop's check (`travel_hunt_radius`). **In a fight, only a flask heals** (or *Warm flare*).
- **Why:** with free regen in a fight, players run off to heal instead of drinking (Grim Dawn, brief §2). A quick refill in light outside a fight keeps "light is shelter". Fixed packs leave nothing to farm.

**Lamp charge (the skill resource).** 0 to 1.0; each lamp glass adds +0.1 (`lamp_upgrade_charge`, new). It still sets how far your hand lamp lights, 44 px at an ember to 104 px (`hand_lamp_*`). Spending charge darkens your world, and that tension is the game's own.
- **Regen:** 0.06/s everywhere (`kl_charge_regen`, new; about 17 s from empty), +0.5/s in light except while beaming (`hand_lamp_recharge_per_sec`), and +0.04 per Spark hit (the basic attack feeds the spenders, as Death's Door's bow does, brief §1).
- **Cut:** the passive dimming in the dark (`hand_lamp_drain_per_sec`) and the carried-fuel top-up (`scripts/player/player.gd:69`).

**Lamp-oil flasks.**

| | Value |
|---|---|
| Charges | 3 at the start (`kl_flask_max`, new); +1 from Maud's errand; +1 from a coat affix; at most 5 |
| Effect | Instantly heals 40% of max warmth and gives +0.4 charge (`kl_flask_heal`, `kl_flask_charge`, new). A 1 s lockout stops double-taps |
| Rest at a lit WayLamp | Refills all. Arriving by fast travel doesn't; resting does (brief §2). Blocked while hunted, like travel |
| Drops | A cleared pack's last foe drops one oil. Elites: 30% chance. Mid-bosses: one at 50% health. Guardians: one at every 25% of each phase (`kl_boss_oil_step`, new), as Last Epoch did (brief §2) |
| Timer trickle | **None.** You can always rest in light out of a fight, so nobody is stranded |

Healing a share of max warmth scales across 12 levels without retuning (brief §2). Flasks are never sold or bought.

**What fuel, glass and scrap become.**

| Today (AUDIT §1.1) | Becomes |
|---|---|
| **Fuel:** 200 spots, the woodpile, caches, a 1-fuel ember per kill | **Cut as a resource.** Oil exists only as flask charges and oil pickups. Fuel spots and peat become scenery or go. |
| **Glass:** 56 Ridge spots, 2 caches, Hooded and Mirror costs | **Cut as a resource.** Its lamp costs fold into scrap. Glass racks stay as Ridge scenery and story. |
| **Scrap:** regrowing ruins, caches, 35% drops | **The one material.** Ruins become one-off piles taken with one press. Scrap also comes from drops, caches and salvage. It pays for lamps, Amos's stock and Kit's re-cut. No carry cap. |

**Recommend:** this resource set (owner questions 1 and 4).

---

## 6. Lanterns after tending

**What a planted lamp does now.** It never burns down and shines at full radius. In its light you get +0.5/s charge, and warmth when out of a fight. Timid foes stay out, and brave ones burn after 2.5 s (built). Its core burns small foes and nests, and it clears and remembers fog (built). You wake by it after a faint.

**Limits and cost.** At most 3 planted lamps in regions not yet held (`kl_lamp_limit`, new). There is no limit in held regions, so you can still light up the valley for its own sake. Picking a lamp up refunds all its scrap, so moving a haven is free; only the first build costs. Building stays quiet (built): firm ground, 1.5 tiles apart, not near a WayLamp, no darkness rule.

| Piece (AUDIT §5.5) | Verdict | New job, and why |
|---|---|---|
| Post Lamp | **keep** | The Hollow's find. Haven and nest-burner. 5 scrap (`post_lamp_cost_scrap`). |
| Reservoir Lamp | **repurpose** | The marsh's find. A wide dim light (200 px, `reservoir_radius`) with no core. Forces things hiding in water up (the Slowwater, the Sump). Feeding is cut: nothing needs feeding. 8 scrap. |
| Hooded Lamp | **repurpose** | The Ridge's find. The only lamp a gust can't snuff. Diving Gutterkites snag on it and burn. 7 scrap (was 5 + 2 glass). |
| Mirror Post | **repurpose** | The Lakeshore's find (#36). Catches a lamp's light and throws a fixed beam: a turret that cuts thick fog, wears shells and crosses with your fire. 8 scrap (was 4 + 3 glass). |
| Wind | **repurpose** | **Ridge only.** Gusts snuff exposed Post and Reservoir Lamps until the gust ends (they relight themselves) and push projectiles downwind. Rock upwind shelters (built). Valley-wide gusts are cut. |
| Old cold lamps (hut, north path) | **keep, no fuel** | Relit by touching your flame. A permanent haven and an early win. Keeps #11 without fuel. |
| Cold-lantern markers, low pulses, edge arrows, chips | **cut** | Nothing goes cold. The cold-frame lure stays only for unlit old lamps (`scripts/ui/lantern_markers.gd`). |
| Woodpile | **cut as a source** | Scenery by the hut. It existed to prevent a fuel soft-lock. |
| WayLamps refilling lamps | **cut** | Nothing to refill. A held region is safe, unlimited for lamps, and has rest and travel. |
| Dying lamps; Wicklings draining them | **cut** | No tanks. Wicklings hunt the keeper. Mirror smothering stays as a Lake fight mechanic. |
| The Ashbrood's dive emptying a lamp | **repurpose** | Its dive snuffs a lamp for 8 s, then the lamp relights. |
| Embers (+1 fuel) | **repurpose** | Their glow and 140 px magnet (`scripts/enemies/ember.gd`) become the pickup for scrap, oil and items. |
| Refuel, relight with fuel, hold-to-gather | **cut** | No tending. |

**Recommend:** a limit of 3 lamps with a full refund (owner question 6).

---

## 7. Fog and light as exploration

- **Keep** the fog, the memory and the reveal (`systems/fog/fog_grid.gd`, built). The valley still starts dark and becomes yours.
- **Your fire lights the fog.** Sparks, Lances and Firepots are small moving lights (about 40 px) that clear fog as they fly. They join the `light_source` group while in the air. Throw a Firepot into the dark to see what's there.
- **Fog no longer drags you.** Full fog slows walking to 85%, not 60% (`fog_slow_min`).
- **The Lakeshore's thick fog** (#50, kept): your fire-light clears it at a quarter of the speed. Mirror beams, the Beam and WayLamps clear it as usual.
- **The map** shows each region's share explored. No goal asks for 100%.
- **Lures you can tell apart** (fixes PLAN_ONBOARDING §9 and AUDIT §4.3):

| Lure | Look above the fog |
|---|---|
| Sleeping pack | pairs of small pale eyes |
| Nest | a cold blue glow, pulsing slowly |
| Elite or mid-boss | one larger pair of eyes with a pale ring |
| Cache or loot | a small glint, coloured by rarity |
| Unlit old lamp | a red-amber pulse (built for the crook) |
| WayLamp | a tall still shape with a cold bowl |

**Recommend:** fire-light as the scouting tool, with lures you can tell apart.

---

## 8. Foes

### 8.1 Packs, elites and nests
- **Fixed packs** sleep and wake as you come close (`kl_pack_wake_radius` 320 px, closer on the route; built). They never respawn on a timer.
- **Elites** are shelled (`kl_elite_hp` 9, `kl_elite_shell` 4, scaled by level). They carry affixes shown under their name: 1 in the Hollow (from level-4 packs on), 2 from the Reedmarsh on. The affixes are **Swift** (+30% speed), **Biting cold** (+50% chill), **Splitting** (bursts into 2 Wicklings), **Thick shell** (x2, regrows twice as fast) and **Lightless** (ignores light, snuffs lamps it passes for 4 s).
- **Nests** stay core-burned only (built). The Post Lamp is their key.
- **Foe scaling.** None exists yet (DESIGN §9). Five regions need it: +35% hp and +20% damage per foe level over 1 (`kl_foe_hp_per_level`, `kl_foe_dmg_per_level`, new).
- **One projectile system** serves keeper and foes. The Spitwick's spit moves to it (brief §6, §7).

### 8.2 Families, mid-bosses and guardians

| Region | Foe levels | Small foes | Region creature | Mid-boss (a Clinker with one trait) | Guardian |
|---|---|---|---|---|---|
| The Hollow | 1-4 | Wickling, Spitwick, nests | — | **Clinker** (built): sleep, leash, roll | **The Ashbrood**, Lv 5. Built with 2 phases; add phase 3, "last of the brood" (PLAN_KEEPERS_LIGHT §4.4) |
| The Reedmarsh | 5-7 | Wicklings on the planks, Spitwicks | **Slowwater**: hidden in unlit water, grabs your feet. **Fenlight**: a false lure that bursts | **mire**: its rolls leave chilling water | **The Sump**, Lv 8: under water until Reservoir light forces it up; then it snuffs lamps and lunges |
| The Windward Ridge | 7-9 | Wicklings in the lee, Spitwicks | **Gutterkite**: dives with gusts at exposed lamps and at you | **downwind**: rolls faster with the wind | **The Galekite**, Lv 10: out of reach until its dive snags on a Hooded Lamp |
| The Lakeshore | 9-11 | Wicklings from the shallows | **Fogstilt**: thickens fog; a mirror beam and your fire crossing on it unravel it | **in fog**: its shell shows only in a beam | **The Tallest**, Lv 11: its legs unravel only where beams cross. **The first cut if scope bites** |
| The Still Lake | 11-12 | a mix of all | — | — | **The Soul of the Wick**, Lv 12 |

The Clinker stays fixed in each region and does not roam (#58 superseded). Every guardian wakes when you light its WayLamp and blocks rest and travel (built for the Ashbrood). The first kill drops a relic and three items (§10).

### 8.3 The finale (DECIDED: a fight; the Soul is not killed and retreats through a portal)

| Phase | What happens | Your answer |
|---|---|---|
| 1. The coil | Three shelled coils around the great lamp. Tendrils sweep the island (tell, dash). Wicklings rise from the water. | Each coil cracks only where a Mirror Post's beam and your fire cross on it. |
| 2. Every flame | It throws each guardian's signature at you, about 40 s each: the ash puff, high water, the gale, the still fog. | Each is answered by that region's lamp: a haven, a Reservoir, a Hooded Lamp, crossed beams. |
| 3. The eyes | It snuffs your hand lamp. Light no longer refills you; only Spark hits and flasks give charge. | Keep firing on its eyes until they close, three times. |

It is never killed. It pulls back into the water, and a dark portal opens where it went down (owner's pitch, #34). The great lamp catches and the fog lifts; the built ending text mostly stands (STORY §9). Fainting returns you to the start of the phase you reached. **Recommend for v1:** the keeper steps into the portal and the credits roll. Then you wake at the great lamp in the open valley (sandbox, #112), with the portal still there and sealed, as the hook for later. DRAFT for story markup.

### 8.4 Foes and lamp light

About half of Wicklings are timid and stay out of healthy light. Brave ones walk in, burn after 2.5 s and run (`kl_timid_share`, `kl_light_tolerance`, `kl_light_burn_dps`; built). Spitwicks keep their distance and spit across light (built). Elites, mid-bosses and guardians ignore light completely (built; owner, 2026-11-27). Each region creature has one light rule: Slowwaters surface in Reservoir light, Gutterkites dive at lamps, and Fogstilts step away from a single beam.

**Recommend:** this roster. Clinkers stay fixed. The Tallest is the first cut.

---

## 9. Leveling

- **Keep the level-gap wick exactly as built** (`systems/progress.gd`, `kl_xp_*`): full wick up to 1 level over the foe, x0.25 per level past that, none at 5 or more over.
- **Cap 12** (`kl_level_cap`).
- **The curve:** wick from L to L+1 is `kl_wick_base` x L^`kl_wick_exp`. Start at base 7 and exponent 2.0 (today 6 and 1.25), which gives 7, 28, 63, 112 to reach level 5. `tools/tests/test_leveling.gd` sets the final values. These are not measurements.

| Region | Keeper level | Ends on |
|---|---|---|
| The Hollow | 1 → 5 | level 2 at the crook; level 5 on the Ashbrood kill |
| The Reedmarsh | 5 → 7 | the Sump |
| The Windward Ridge | 7 → 9 | the Galekite |
| The Lakeshore | 9 → 11 | the Tallest (or its WayLamp, if cut) |
| The Still Lake | 11 → 12 | before the Soul |

- The Hollow's last level still comes on the Ashbrood kill (#17, kept). The level it reaches drops from 8 to 5 (#7 superseded); otherwise four regions would share four levels.
- **What a level gives:** one skill point, +8 max warmth, +6% skill damage (`kl_dmg_per_level`, new), and new skills at levels 2, 3 and 5.
- **Showing it:** a chime, a short toast ("Level 5. A new point to spend."), and a mark on the Skills tab. No pause and no card screen.

**Recommend:** this curve and these bands (owner question 2).

---

## 10. Loot

**Rarities** (about three, brief §6):

| Tier | Affixes | Base share | Colour (palette) |
|---|---|---|---|
| Plain | none; base stat only | 70% | pale grey-blue `#a3bcd4` |
| Bright | 1-2 | 25% | mid blue `#6d8fb3` |
| Rare | 3-4; one may change a skill | 5% (x2 from elites and bosses) | gold `#ffd27a` |
| Relic | fixed, hand-made, one of each | guardians' first kill and some finds | amber `#f5a742` |

**Slots** (the owner's four, given jobs that fit the new kit). You start with a Plain item in each.

| Slot | Shapes | Bases (implicit stat) |
|---|---|---|
| **Lens** | projectile skills: Spark, Lance, the Beam | Clear lens (+damage), Long lens (+range) |
| **Burner** | area skills: Flare, Firepot, Moth-lights, burning ground | Flare burner (+radius), Slow burner (+burn time) |
| **Coat** | warmth and defence | Patched coat (+warmth), Oilskin (full-speed wading), Quilted coat (chills less) |
| **Wick** | lamp charge | Plain wick (+max charge), Braided wick (+regen) |

**Affixes: 16 general, plus 4 that change a skill.**

| Lens | Burner | Coat | Wick |
|---|---|---|---|
| +% projectile damage | +% area radius | +max warmth | +% max charge |
| +1 pierce on Spark | burning ground +1 s | *Lee*: touch chills x% less | *Kindled kills*: +charge per kill |
| +% shell damage | -% cooldowns | +1 flask charge | -% skill cost |
| +% projectile speed and range | Flare stuns 0.4 s | +% move speed | *Hot core*: your lamps' cores burn x% harder |

The skill-changing affixes appear on Rare and Relic items only: Spark splits on a kill, Firepot throws two pots, Lance returns, Moth-lights +2. Item level equals the dropping foe's level. Affix values come in three bands: levels 1-4, 5-8 and 9-12. **About 8 relics in v1:** Oswin's coat (the Ridge landmark, #35), the Long lens (Kit), the Smoulder burner (Maud), the Shutter burner (Ebba), and one from each guardian.

**Drop sources** (starting rates, tuned per region): Wickling 3%, Spitwick 5%, nest 40%, elite 35% (Rare chance x2). A mid-boss drops 2 items, one Bright or better. A guardian drops 3, one Rare or better, plus a relic on the first kill, and at least one for a slot where you hold only Plain. A side cache holds 1 item, Bright or better.

A rough Hollow count: 88 pack foes, 12 nests, 6 elites, the Clinker, the Ashbrood and 4 caches give about 20 items. Fixed packs make loot finite, so nothing can be farmed.

**Salvage, no vendor.** Hold X (or Delete) on an item in the bag to salvage it: Plain gives 1 scrap, Bright 3, Rare 8; relics can't be salvaged. Amos sells a small stock for scrap. Kit re-cuts one affix on a lens or burner for scrap, once per item, locking the rest. That is a **cut line**: it edges toward crafting, which DESIGN §5 lists as OUT. No gold, no selling.

**The bag.** 16 slots, +4 per keeper's satchel (the 3 built satchels take this job), +4 for Amos's Wide Pack: 32 at most. Walk over a drop to take it (the 140 px magnet, built). If the bag is full, the item stays on the ground.

**Comparing on a gamepad.** The Gear tab shows the bag as a grid on the left. On the right, the equipped item and the selected one sit side by side as cards, each stat marked ▲ in gold or ▼ in dim blue with the difference. A equips, hold X salvages, B goes back, LB / RB switch tabs. Standing on an item on the ground shows a small card with one ▲ or ▼ against what you wear.

**Code.** GLoot data classes only, with our own UI and our own rolling code (owner #20; ARPG skill), in `systems/loot/loot.gd` (new).

**Recommend:** this set. It is about 20 affixes, a little over the brief's first pass of 15 (brief §6.2), because the four card effects moved here.

---

## 11. NPCs and quests

People come back when their region is held, stand near its WayLamp in held ground, and never fight (PLAN_NPCS_ENEMIES §3, kept). No main goal needs a person.

| Person | Comes back when | Stands (on the loop) | Service | Errand → reward |
|---|---|---|---|---|
| **Amos**, trader | the Hollow is held | by a cart at the Hollow WayLamp (78,124), on the road east, not by the hut: lit roads bring trade | sells a small stock for scrap | **"Amos's cart"**, the south-Hollow side quest (owner: the south stays optional, maybe with an NPC side quest). Amos's old cart is stuck among the quiet south packs. Clear them and plant a lamp by it → the Wide Pack (+4 bag slots) and a Bright item |
| **Maud**, old pump keeper, who knew Oswin | the Reedmarsh is held | at the pumphouse, by its WayLamp | none | **"Maud's lamp"**: Maud's lamp lies in the north water among Slowwaters → the Smoulder burner (relic) and +1 flask charge |
| **Kit**, glazier's apprentice | the Ridge is held | at the workshop by the top of the marsh climb (99,51) | re-cuts one affix (cut line) | **"Fire the kiln"**: bring the great lens shard from a Ridge cache → the Long lens (relic) |
| **Ebba**, rower ("she") | the Lakeshore is held | at the shore end of the old jetty | after the finale, rows you to the far shore (#54) | **"Show me the boat"**: put light on her boat in the reeds (a lamp or a mirror beam) → the Shutter burner (relic) |
| **Ivo**, mapmaker | two regions are held | at the carved stone by the marsh passage | the map marks lures and caches in held regions | **"Walk the edges"**: read 3 survey stones → the map shows caches not yet found. **Cut line** |

**How talk works.** Dialogue Manager (owner #20), with one `.dialogue` file per person under `dialogue/` (new). The balloon is drawn with `UiStyle`: A advances, B closes, the world pauses, and the font is Ark Pixel only. Every line is DRAFT in STORY.md, and `tools/check_docs.py` learns to read `.dialogue` files. The journal gains People and Errands pages.

**Recommend:** five people, with Amos and Ivo moved to travel points. Kit's re-cut and Ivo are the cut lines.

---

## 12. World and route

The loop is built (`proto/kl-loop`, ff8426b). It answers AUDIT §4.5's one-way Ridge question. You climb from the marsh's north-west corner to the Ridge entry at (100,56). The trail then runs north-east: glazier (99,51), lens, coat, station, WayLamp (120,30), and the old steps (124,34). The far west is optional, and the old climb is a shortcut you open from above.

| # | Region | Levels | Find (the key) | WayLamp | Twist |
|---|---|---|---|---|---|
| 1 | The Hollow | 1-5 | the Post Lamp, at Oswin's crook | (78,124), on the road east (built) | none: the calm start |
| 2 | The Reedmarsh | 5-7 | the Reservoir Lamp, at the pumphouse | (200,140) by the pumphouse in code; #36 moves it to the south-east island | soft ground and water |
| 3 | The Windward Ridge | 7-9 | the Hooded Lamp, at the glazier | (120,30), by the station (built) | gusts |
| 4 | The Lakeshore | 9-11 | the Mirror Post (#36) | the old landing, reached along a mirror-lit lane | thick fog |
| 5 | The Still Lake | 11-12 | the catch ring (PLAN_KEEPERS_LIGHT §3.2) | the great lamp | ordinary light dies |

- **The Reedmarsh backtracks once.** The route goes east to the pumphouse and back west to the climb, about 80 tiles. **Recommend:** in M4, lay it out as a U, out along the south boardwalks and back along the north, and do the #36 WayLamp move at the same time. (The loop's DESIGN text says the WayLamp is already on the south-east island, but `main.gd` on the loop still places it at (200,140).)
- **The Lakeshore and the Still Lake are rock today.** Scale PLAN_LAKESHORE §1.1 by two, as the loop's note in that plan says: the shore at about x 132-164, y 18-74, and the Lake east of it. The marsh climb stays at x 131 or less.
- **WayLamps.** Interact to touch your flame to one. That wakes the guardian (or a fixed hold fight until that guardian exists). Win, and the region is held. At a lit WayLamp, interact opens Travel and Rest. Rest refills flasks and warmth and allows a respec. It never resets packs (brief §5).
- **Fast travel**, as built: lit WayLamp to lit WayLamp only, blocked while hunted, during kindling and during a guardian fight. No field recall and no portal item (brief §5).

**The faint rule** (one rule, replacing `player.gd:211-213`):
1. You wake at the nearest lit light in the region (a WayLamp, an old lamp or your own lamp) at 60% warmth, as built.
2. You keep everything you carry: scrap, items and flasks.
3. Your unspent wick waits where you fell (the built `WickDrop`). It is your only stake.
4. **Cleared packs stay cleared.** Packs you only partly beat heal, go back to sleep and keep their dead.
5. A mid-boss or guardian goes back to the start of the phase you reached, with its shell regrown.

**Why:** it matches "cleared ground stays cleared" (#26), keeps loot and wick finite, and still gives a faint a cost: the walk back, the stake and the boss phase. **Recommend:** this rule (owner question 7).

---

## 13. Story

**What stays:** the letter and the name prompt; Oswin, "he", signing "- Oswin"; the trail of notes; the Soul as "it", with big pale eyes; who took the light, but not why; no game over; the great lamp plate; the ending's last lines.

**What changes:** the keeper fights with fire-light. WayLamps are taken by fighting their guardian. The finale is a fight, and the Soul retreats through a portal. People speak. The route is the loop.

**Texts that need rewriting (listed only; all DRAFT for the owner):**
- **Fix now:** Oswin as "they" in STORY §1 and §4 and in README.md:25; STORY's header counts (AUDIT M1, M10).
- **Goals:** `gather_fuel`, `relight_first`, `relight_waypost` (relight by touch); `build_reservoir`, `build_hooded`, `build_mirror` (using each lamp, not building it); the `kindle_*` lines (light it, then beat the guardian). `burn_nest` stays.
- **Tips:** cut `cold_lantern`, `low_lantern`, `dying_lantern`, `glass`. Rewrite `wickling_close` (Spark first, not the beam), `lamp_empty`, `warmth_low`, `faint`, `gust`, `mirror_placed`, `waylamp_seen`, `kindle_attack`, `haven`, `burst` (now Flare), `shell`, `dash`, `build_here`. New: flask, Lance, Firepot, rest, loot, level point, bag full.
- **WayLamp notes:** keep the inscriptions and Oswin's lines; rewrite the three-line footer ("Feed it 15 fuel...").
- **Journal:** entry 13 ("I held the WayLamp"); entry 15 ("only the lake is left", but the shore comes first); new entries for each guardian.
- **Finds:** the satchel and lamp glass notes promise carry space and "wards for longer" (AUDIT M20). `crook_post` still fits ("Plant one where you mean to stand").
- **The loop's DRAFT lines:** the ledger, cairn, pumphouse, `climb_north` and the travel texts (STORY §11 on the loop). Recommend approving them as they are.
- **Not in STORY.md yet** (AUDIT M23): the faint note, the boss-bar hints, the Ashbrood's phase toast.
- **New text:** skill names and descriptions, branch picks, item bases, affixes and relic texts, the bar and pack screens, every NPC line, the finale and portal lines, and the after-game line.

**Recommend:** keep the voice and the mystery, and write all new text as DRAFT in STORY.md in the same change as the code (docs skill, rule 2).

---

## 14. UI and HUD

The font is Ark Pixel only, at 20, 30, 40 or 60. One panel style (`scripts/ui/ui_style.gd`, built).

| Element | Where and what |
|---|---|
| **Action bar** | Bottom centre, six slots in the pad's shape: LT and LB left, Y in the middle, RB and RT right, the flask at the right end. 32 px icons (16 at 2x). Button labels at 20. Cooldown sweep and seconds; greyed when short of charge. |
| **Warmth and charge** | Two bars just above the bar: warmth (amber-red) left, charge (gold) right, with skill-cost ticks on the charge bar. They leave the top-left panel. |
| **Flask** | The right-end slot, with 3-5 pips, and a flash when a charge comes back. |
| **Top of the screen** | Left: level, the wick bar and "12/24" (built), and the scrap count; fuel and glass go. Centre: the goal banner (built). Right: chips only for "hunted" (travel and rest blocked) and "cold" (warmth under 35%); the lamp, cold-lantern and wind chips go. |
| **Foe bars** | As built, with level, plus the elite affixes in a 20 px line under the name. |
| **Boss bar** | As built, now "phase N / 3" with a one-line hint. |
| **Damage numbers** | Pop, then drift (brief §4). 20 px, or 30 px for big hits. Grey when the level gap cut the wick, like the built wick popups. |
| **Map** | As built, plus WayLamp icons (lit or cold), lures you have seen, and the share explored per region. It is also the pack's Map tab. Travel stays at WayLamps. |
| **Level-up** | A toast and a mark on the Skills tab. The card screen (`scripts/ui/level_up.gd`) goes. |
| **The keeper's pack** | One screen with Gear, Skills, Journal and Map tabs (LB / RB). Gear as in §10. Skills shows the bar and seven skill trees, with locked tiers dimmed. Journal and Map are the built ones, moved in. The world pauses. |
| **Prompts, options** | Prompts as built, with new words: Rest, Travel, Talk, Take, Light it. Options gain a screen-shake slider and a "reduce flashes" toggle from M1 (brief §4). |

**Recommend:** move health and charge down to the bar, and fold the journal and map into one pack screen.

---

## 15. Art and audio direction

**Owner art is preserved.** The Post Lamp, lit and cold, and its `.pxo` files (AUDIT §5.1) stay as drawn; it is the haven sprite. The palette and the 16x16-at-2x rule stay (DESIGN §7).

**Effects for juice** (brief §4's budget, an inference from the cited talks):

| Event | Feedback |
|---|---|
| Cast | Additive flare at the lamp, slight recoil, sound |
| Travel | Short trail and additive glow; a small fog-clearing light |
| Hit | White flash (built), sparks, small knockback, damage number |
| Kill | 40-80 ms hit-stop **on attacker and target only**, a bigger burst, a scorch mark that lingers |
| Big AoE (Firepot, Flare) | Camera trauma, a ring flash, a flickering burning-ground decal |

**Godot notes** (brief §7):
- **Glow:** additive `Sprite2D` (CanvasItemMaterial, Blend Mode Add) for projectiles, trails and blasts. Real `PointLight2D` only for the hand lamp, planted lamps and WayLamps.
- **Hit-stop:** replace the global `Engine.time_scale` freeze in `scripts/enemies/foe.gd` `_die()`, which would stutter at Spark's fire rate (brief §4).
- **Screen shake:** the trauma recipe (KidsCanCode; port its Godot 3 names) replaces the plain offset in `player.gd`.
- **Collision by job:** slow pots and motes use `Area2D` and signals. Spark, Lance and the Beam use a ray or shape cast along each tick's motion, so nothing tunnels. Blasts use one `intersect_shape` in `_physics_process`. Burning ground is a long-lived `Area2D` that ticks its overlaps.
- **Pooling:** detach projectiles, don't free them. Use servers only if the profiler asks.
- **Particles:** `GPUParticles2D`, with a CPU fallback only if profiling on the Compatibility renderer says so.

**New art for the owner's list:** 8 skill and flask icons; about 12 item-base icons; rarity glints; keeper cast and dash frames; sprites for the Spitwick, Clinker, nest, elite ring and Ashbrood (all code-drawn today); later, each region's creature and guardian.

**Audio** is the owner's job (#28), with Kenney placeholders until then. Needed: cast, hit and kill sounds per skill; flask, dash and rest; loot drops by rarity; the level-up (built), boss phases and the portal.

**Recommend:** additive sprites for all fire-light, with per-target hit-stop and the shake slider in M1.

---

## 16. The code: keep, rework or cut

| System | Files | Verdict | What changes |
|---|---|---|---|
| Combat kit | `scripts/player/combat.gd` | **rework** | Becomes `scripts/player/skills/` (new): one script per skill on a shared `Skill` base. Beam, burst (Flare) and dash move in. |
| Projectiles | `scripts/enemies/spit_projectile.gd` | **rework** | One shared `Projectile` for keeper and foes, with a pool (brief §6, §7). |
| Status effects | `systems/status/` | **new** | One system for burning, stun, slow, chill and burning ground (brief §6). |
| Keeper | `scripts/player/player.gd` | **rework** | Cut the ward (`:161-180`), refuel, gather, the fuel top-up (`:69`) and passive dimming. Add the flask, the regen rule and the faint rule (`:211-213`). |
| Foe base | `scripts/enemies/foe.gd` | **keep + extend** | Affixes, level scaling, loot and oil drops, per-target hit-stop. |
| Wickling | `scripts/enemies/wickling.gd` | **rework** | Cut lamp draining and dying-lamp targeting. Keep timid and brave, and mirror smothering. |
| Spitwick, nest, Clinker | `spitwick.gd`, `wick_nest.gd`, `clinker.gd` | **keep** | The spit uses the shared projectile; the Clinker gets a region trait. |
| Ashbrood | `scripts/enemies/ashbrood.gd` | **rework** | Phase 3, phase reset on faint, oil drops, the dive snuffs a lamp for 8 s. |
| Packs | `scripts/enemies/enemy_pack.gd` | **keep + extend** | Elite affixes; partly beaten packs reset on a faint. |
| Drops | `scripts/enemies/ember.gd` | **repurpose** | Becomes `pickup.gd`: scrap, oil and items, coloured by rarity. |
| Ambient spawner | `systems/threat/wickling_spawner.gd` | **cut the trickle** | Keep the fixed hold swarm only until each guardian exists. |
| Lanterns | `scripts/lanterns/lantern.gd` | **rework** | No tanks, burn or wind burn. A snuff timer, new jobs per kind (§6), the limit. |
| Resource spots | `scripts/resources/resource_node.gd` | **rework** | One-off scrap piles taken with one press. Cut fuel, peat and glass. |
| Landmarks and finds | `scripts/world/landmark.gd` | **keep** | The satchel gives bag slots; the lamp glass gives charge and radius. |
| WayLamps | `scripts/world/waylamp.gd` | **rework** | Lit by touch, a guardian per region, Rest. Fuel cut. |
| Fast travel, stones | `scripts/ui/travel_menu.gd`, `scripts/world/climb_stones.gd` (the loop) | **keep** | Add Rest beside Travel. |
| Lures, wick drop | `scripts/world/post_lure.gd`, `wick_drop.gd` | **keep + extend** | One lure class with the six looks in §7. |
| World generation | `scripts/main/main.gd`, `map_chunk.gd` | **rework** | Cut the fuel and glass scatter and the woodpile; old lamps relit by touch; pack, nest and cache tables in per-region data files; carve regions 4 and 5. |
| Fog and light | `systems/fog/fog_grid.gd`, `systems/light/light_sense.gd`, `light_tex.gd` | **keep** | Projectiles as small lights; a thick-fog multiplier; drop the "dying" snapshot. |
| Wind | `systems/wind/wind.gd`, `wind_streaks.gd` | **rework** | Ridge only: snuffs exposed lamps and drifts projectiles. |
| Progress | `systems/progress.gd` | **rework** | Skill points, tiers and the bar; equipped items. Wick and level-gap code unchanged. |
| Inventory, loot | `systems/inventory.gd`; `systems/loot/loot.gd` (new) | **rework; new** | Scrap only, plus the GLoot bag. Rarity and affix rolls and drop tables in our own code. |
| Save | `systems/save/save_game.gd` | **rework** | Version 5: skills, bar, items, flasks. Old saves start fresh with "(old save)", as built. |
| Story | `systems/story/story.gd` | **keep** | Goals, tips and entries rewritten (§13). |
| Input | `tools/setup_input.gd`, `systems/input/input_hint.gd` | **rework** | The §3 map; button glyphs for bar slots. |
| Tuning | `systems/tuning.gd`, `scripts/ui/debug_panel.gd` | **rework** | Cut the tending, ward, wind-burn and fuel numbers. Add skill, flask, loot and scaling numbers. F1 rows to match. |
| HUD | `scripts/ui/hud.gd`, `world_prompt.gd` | **rework** | The §14 layout. |
| Lamp list; lamp markers | `scripts/ui/build_menu.gd`; `scripts/ui/lantern_markers.gd` | **cut; rework** | D-pad cycling and a lamp-kind label on the bar replace the list. Markers show unlit old lamps only. |
| Level-up cards | `scripts/ui/level_up.gd` | **cut** | Replaced by the Skills tab. |
| Journal, map | `scripts/ui/journal.gd`, `map_screen.gd` | **keep** | Become tabs of the pack screen. |
| Other UI | `foe_bars.gd`, `boss_bar.gd`, `pause_menu.gd`, `note_reader.gd`, `opening.gd`, `goal_pointer.gd`, `slot_menu.gd`, `ui_style.gd` | **keep** | Small changes: the affix line, "phase N / 3", options. |
| Audio, art helpers | `systems/audio/*`, `systems/art/art.gd` | **keep** | |
| Add-ons, dialogue | `addons/dialogue_manager/`, `addons/gloot/`, `dialogue/` | **new** | Keep each add-on's LICENSE file; add a row to `assets/CREDITS.md`. |
| Tests | `tools/tests/` | **rework** | Rewrite `test_core`, `test_threats`, `test_ridge`, `test_waylamps`, `test_upgrades` and `test_combat`: they test tending or the ward. Keep `test_leveling` (new targets), `test_story`, `test_save`, `test_slots` and the three `test_prototype_*` route tests. Add `test_skills`, `test_flasks`, `test_faint`, `test_loot` and `test_npcs`. |
| Bench | `tools/bench/bench.tscn` | **keep + extend** | Add 40 live projectiles and 4 burning-ground areas, keeping logic under 4 ms. |

**Recommend:** rework in place, one branch per milestone. Nothing outside the cut rows is thrown away.

---

## 17. The docs

| New doc set | Job |
|---|---|
| `docs/DESIGN.md` | **Rewrite** from this plan once approved: the game as built, with planned parts marked. Numbers only from tuning.gd. |
| `docs/STORY.md` | **Keep and refresh.** Every player-facing text, NPC lines included. Fix the pronouns now. |
| `docs/DECISIONS.md` | **Keep**, append-only. Add a short "standing decisions" index at the top, from AUDIT §3 and this plan. |
| `docs/ROADMAP.md` | **Rewrite** from §18. M0-M4 become a short history note. |
| `docs/PLAYTEST.md` | **Keep.** Add the fuel-and-abilities results; move the pre-ARPG sections to the archive. |
| `docs/ART_CHECKLIST.md` | **Keep.** Add rows for skills, items, foes and people; drop the PROTOTYPE tags on WayLamps. |
| `docs/archive/` (new) | Retired plans, kept unchanged so their history stays findable. |
| `docs/replan/` | **Archive** once DESIGN and ROADMAP are rewritten. |
| `docs/research/ARPG_REFERENCES.md` | **Keep** as a reference. |

| Current doc | Verdict |
|---|---|
| PLAN_KEEPERS_LIGHT.md | **Retire** to the archive. Its families, guardians, finale and relics are harvested here (§8, §10). |
| PLAN_ONBOARDING.md | **Retire.** Its route lives in DESIGN; its open items are in AUDIT §4.1. |
| PLAN_LAKESHORE.md | **Merge** into DESIGN's Lakeshore section in M6, then retire. |
| PLAN_NPCS_ENEMIES.md | **Merge** the people into STORY and DESIGN (§11), then retire. |
| README.md | **Rewrite** when M1 merges to `main`: pitch, features, controls, screenshots. Fix the pronoun and the stale WayLamp line on `main` now. |
| AGENTS.md, CLAUDE.md | **Keep.** In AGENTS, replace "Scope is locked" with "Scope follows the game plan and ROADMAP", fix "REAPER", and add the new tests. CLAUDE.md stays a pointer. |
| `.agents/skills/lantern-keeper-docs/SKILL.md` | **Keep.** Fix "they for H." to Oswin "he". Update the doc table; add `docs/archive/` and `.dialogue` files. |
| `.agents/skills/lantern-keeper-arpg/SKILL.md` | **Rewrite** the pillars from §1, §4 and §10. Keep "how things are built" and the balance-pass method. |
| `assets/CREDITS.md` | **Keep.** Add Dialogue Manager and GLoot when they arrive. |
| `tools/check_docs.py` | **Extend** to `.dialogue` files, skill and item texts, and the strings in AUDIT M23. |

**Recommend:** archive, don't delete, so the owner's past answers stay findable.

---

## 18. Milestones and build order

**Scope traps applied (brief §6):** no co-op and no extra platforms before v1; one projectile system and one status system; no second progression track; one region fully playable before the next; named cut lines (the Tallest, Kit's re-cut, Ivo, Moth-lights' tier 3).

Every milestone ends with an owner playtest on a gamepad. **Merge to `main` once M1 passes**, so `main` stops describing a game that no longer exists.

### M1: The Hollow, reforged (the vertical slice)

**Scope:** the loop merged in. Spark, Flare, the Beam, Lance, Firepot and the dash. The action bar on pad and keyboard/mouse, with aim assist. Flasks, and the charge and warmth rules. Tending removed from the code everywhere. WayLamps and old lamps lit by touch. The planted-lamp limit and refunds. Skill points with tiers 1-2 in a plain Skills tab. The curve for levels 1-5, and foe scaling. The faint rule. Ashbrood oil drops and phase reset. The juice baseline and the shake slider. The Hollow's tips rewritten. The marsh and the Ridge stay walled off until M4 and M5.

**Owner checks on a gamepad:**
1. Play a new game to the lit Hollow WayLamp without a keyboard.
2. RT, RB, LB and LT all fire while you move and aim, and the right thumb never leaves the stick.
3. Cooldowns sweep on the bar. A skill without enough charge greys out.
4. No prompt or tip says fuel, refuel or gather.
5. B drinks a flask: it heals and a pip drops. Resting at the lit WayLamp refills; travelling there doesn't.
6. After a faint, cleared packs stay cleared and the Ashbrood restarts its phase.
7. Level 2 comes at the crook, level 5 on the Ashbrood kill.
8. You can swap a skill using only the D-pad and A.
9. Spark fired into the dark reveals fog.

**Tests:** new `test_skills`, `test_flasks` and `test_faint`. Rewrite `test_core`, `test_threats`, `test_waylamps` and `test_combat`. `test_leveling` gets the new targets. The bench must stay under 4 ms with 40 projectiles.

**Risks:** feel is most of the work (PLAN_KEEPERS_LIGHT §10); if fire-light doesn't feel good, do one more feel pass before M2. Pad aiming.

### M2: Loot and builds
- **Scope:** GLoot data; 4 slots with Plain starting gear; 3 rarities and 2 Hollow relics; 20 affixes; drops and oil; the bag and compare; salvage; tier-3 variants; Moth-lights; the Ashbrood's phase 3.
- **Owner checks:** compare and equip an item in under 5 s on the pad. A Hollow clear gives about 15-25 items. Two builds feel different. Hold X salvages. A full bag leaves the item on the ground with a prompt.
- **Tests:** `test_loot`: seeded rolls, rates, item level, save round trip.
- **Risks:** tuning multiplies (brief §6.2). GLoot on Godot 4.7 is untested here.

### M3: People, part 1
- **Scope:** Dialogue Manager, the talk balloon, the People and Errands pages, Amos and "Amos's cart" in the south of the Hollow.
- **Owner checks:** talk with A, close with B. Lines match STORY.md. The errand shows in the journal. The Wide Pack adds 4 slots.
- **Tests:** `test_npcs`; `check_docs` reads `.dialogue` files.
- **Risks:** Dialogue Manager on 4.7 is untested here; the balloon must work on the pad.

### M4: The Reedmarsh
- **Scope:** levels 5-7; the U route and the WayLamp move; Slowwater and Fenlight; the mire Clinker; the Sump; the Reservoir's job; Maud and "Maud's lamp"; Ivo once two regions are held (cut line).
- **Owner checks:** no ground walked twice. Reservoir light brings the Sump up. Levels 5-7 land. The Sump takes 2-4 minutes.
- **Tests:** a marsh route test like the loop's; `test_leveling` per region.
- **Risks:** water readability; Slowwater fairness.

### M5: The Windward Ridge
- **Scope:** levels 7-9; Ridge gusts that snuff and drift; the Gutterkite; the Hooded Lamp's job; the downwind Clinker; the Galekite; Oswin's coat relic; Kit and the Long lens; the re-cut (cut line).
- **Owner checks:** the Ridge is one walk. A gust visibly snuffs exposed lamps and pushes Sparks. The Galekite snags on a Hooded Lamp.
- **Tests:** rewrite `test_ridge`.
- **Risks:** wind punishing more than it teaches.

### M6: The Lakeshore
- **Scope:** carve region 4 (PLAN_LAKESHORE x2); thick fog; the Mirror Post find; the Fogstilt; the fog Clinker; the Tallest (first cut); Ebba.
- **Owner checks:** a mirror lane is the quick way through the fog. Crossing fire on a Fogstilt unravels it.
- **Tests:** a shore route and fog test.
- **Risks:** fog too slow; the Tallest's scope.

### M7: The Still Lake and the finale
- **Scope:** region 5; the catch ring; the Soul in three phases; the portal; the ending; the sandbox and after-game; Ebba's crossing.
- **Owner checks:** the Soul takes 6-10 minutes. A faint returns you to the start of the phase. The portal opens, the credits roll, and the valley stays open.
- **Tests:** a finale phase test.
- **Risks:** the largest milestone. Phase 2 reuses each guardian's move, so it depends on M4-M6.

### M8: Polish and the Linux build
- **Scope:** owner art and audio; accessibility; a balance pass over every region; 3 or more external playtests; a Linux export tested on a clean machine; CREDITS complete.
- **Owner checks:** the DESIGN "done when" list.
- **Risks:** polish creep. Hold the cut lines.

---

## Decisions this plan would supersede

None of these is settled. Each needs the owner's OK. The numbers are the rows of AUDIT §3.

| # | Decision now | Proposed resolution |
|---|---|---|
| 7 | Level 8 on the Ashbrood kill | Level 5 on the Ashbrood kill; still the Hollow's last level (#17 kept). §9 |
| 11 | A second cold old lamp on the north path, relit with fuel | Keep it, relit by touch: a haven and an early win, with no fuel. §6 |
| 13, P11 | Onboarding tips and goals that teach the beam and fuel first | Rewrite as DRAFT: Spark first, relight by touch. Keep the ledger line (the loop's DRAFT). §13 |
| 18 | Four cards approved "as written" | Same effects and names, moved into branches (Steady hand, Spill) and affixes (Hot core, Lee). The card screen goes. §4.3 |
| 19 | Slots lens, burner, coat, wick, tied to the beam and burst | Same names, new jobs: lens for projectile skills, burner for area skills, coat for warmth, wick for charge. §10 |
| 29 | Start: pointer on the woodpile until you have fuel | Start: relight the hut lamp by touch. The woodpile is scenery. §6 |
| 37, P1 | Charge refilled by light, topped up by carried fuel | Charge from a slow base regen, light, Spark hits and flasks. No fuel. §5 |
| 39 | Beam, burst and dash as the core; pick-1-of-3 levels | Spark plus fire-light skills, the Beam optional; fixed branches. The ARPG, guardians and "the find is the key" stay. §4 |
| 42 | WayLamps take 15 fuel directly | Lit by touching your flame; the guardian is the cost. "No lantern has to reach them" stays. §12 |
| 46 | Beside a lamp, tap refuels and hold gathers | Cut. Scrap piles are taken with one press. §5 |
| 51, P4 | The Lakeshore WayLamp reached only by a beam | On the landing, reached by walking a mirror-lit lane (PLAN_LAKESHORE's own fallback). §12 |
| 52, 93 | Glass as a resource; worn glass on the shore | Glass stops being a resource; its lamp costs fold into scrap. §5 |
| 58 | The Clinker roams whatever isn't held | A fixed mid-boss in each region, with one regional trait. §8.2 |
| 60 | WayLamp texts approved (the footer, entries 13 and 15) | Keep the inscriptions and Oswin's lines; rewrite the footer and entries 13 and 15 as DRAFT. §13 |
| 64 | Fainting drops half your fuel and scrap | Fainting drops nothing carried; unspent wick waits; cleared packs stay cleared. §12 |
| 65 | Satchels +10 carry; lamp glasses also cheapen the ward | Satchel: +4 bag slots. Lamp glass: +12 px light and +0.1 max charge. §5, §10 |
| 67, 68 | A held region refills lamps; only dying lamps can be drained | A held region is safe, unlimited for lamps, with rest and travel. Wicklings no longer drain lamps. §6 |
| 76, 79 | Tab/Y lamp list and keys 1-4; HUD fuel count and lamp chips | D-pad lamp cycling and the action bar; warmth and charge at the bar; no fuel or lamp chips. §3, §14 |
| 92, 94, 108 | Wind burns exposed lamps faster, valley-wide; the Hooded Lamp is wind-proof for fuel | Ridge gusts snuff exposed lamps until the gust ends and drift projectiles; the Hooded Lamp never snuffs. §6 |
| 98, 99 | Embers worth 1 fuel; a 35% scrap drop | Drops come from loot tables: scrap, oil and items. The ember look stays. §10 |
| 107 | Cold lamps stay findable; low lamps pulse | Cut, except the cold-frame lure on unlit old lamps. §6 |
| 113 | The hand lamp uses fuel and keeps an ember | No fuel; charge regenerates; it never goes out (kept). §5 |
| DESIGN §5 | Crafting beyond lamp recipes is OUT | Salvage into scrap is in. Kit's single re-cut is a cut line and needs the owner's OK. §10 |

---

## 19. Owner questions

1. **One material, scrap?** Fuel and glass stop being resources, and oil lives only in flasks. **Recommend yes:** three currencies plus loot is the tuning trap the brief warns about (brief §6.2), and the owner called fuel "pretty much useless".
2. **The Hollow ends at level 5, not 8?** **Recommend yes:** with a cap of 12 across five regions, only four levels would be left after the Hollow. The last level still comes on the Ashbrood kill.
3. **Fixed skill branches replace the random "Trim the wick" cards?** **Recommend yes:** branches change behaviour, and that is what makes picks memorable (brief §3). All 12 card effects survive, the four approved ones by name.
4. **Light heals only out of a fight; in a fight, only flasks heal?** **Recommend yes:** otherwise flasks don't matter, and players run off to heal (brief §2, Grim Dawn).
5. **WayLamps lit by touch, with the guardian as the cost?** **Recommend yes:** no fuel economy is left to pay with, and the fight is the moment.
6. **At most 3 planted lamps outside held regions, with a full refund on pick-up?** **Recommend yes:** havens stay a choice, not a wall of light, and moving one is never punished.
7. **The faint rule in §12?** Cleared packs stay cleared, nothing carried is lost, wick waits where you fell, and bosses keep their phase. **Recommend yes:** it fixes AUDIT finding 10 and keeps loot and wick finite.
8. **The button map in §3?** On the pad: RT Spark, RB and LB aimed skills, Y unaimed, LT dash, B flask, X plant, A interact, and the D-pad for the map and lamp kind. **Recommend yes:** every aimed input keeps the right thumb on the stick, and the dash stays where the owner already uses it.

---

## Uncertainties

1. **Every number is a starting value, not a measurement:** the curve (base 7, exponent 2.0), foe scaling, drop rates and flask values. `test_leveling` and the bench must set them.
2. **The playtime** (5-7 h) is a guess.
3. **The marsh WayLamp:** the loop's DESIGN text puts it on the south-east island, but `main.gd` on `proto/kl-loop` places it at (200,140) by the pumphouse. I went with the code.
4. **Dialogue Manager (4.2+) and GLoot (3.x) on Godot 4.7.2** were vetted per the ARPG skill. I did not check that they work on 4.7.2.
5. **Projectiles as fog lights** may cost more than the fog's sparse step allows. The bench must show it.
6. **The marsh U route** is a recommendation I have not laid out on the map.
7. **Brief items marked UNVERIFIED** (pad layouts other than Diablo IV's, the cooldown display) are used here only as inferences.
8. **Kit's re-cut and salvage** may count as crafting, which DESIGN §5 lists as OUT. Flagged as a cut line.
