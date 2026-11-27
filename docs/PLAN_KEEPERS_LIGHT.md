# Lantern Keeper: Keeper's Light (design draft)

**DRAFT for the owner's markup, 2026-11-27.** The owner chose this direction today: the game becomes an action RPG. Everything below is a proposal unless it is tagged **Built** or **DECIDED**. Nothing here was committed or published, and the repo was not edited.

**Sources (read-only).** `CORE_LOOP_RESEARCH.md`; `main` at eab9759 (DESIGN, STORY, DECISIONS, PLAN_NPCS_ENEMIES, PLAN_LAKESHORE, `systems/tuning.gd`, `scripts/`); and the prototype branch `proto/keepers-light` at 701c42e, where slice 1 of the combat kit is already built. Section 12 lists what was checked and what wasn't.

**How to read it.**
- **OWNER n:** a choice for you. Mark each yes, no or change. Section 11 lists them all in one table.
- **Built (slice 1):** already on `proto/keepers-light`. Its numbers are used here as the starting placeholders.
- **DRAFT** marks every in-game text. Each quoted line is one line on screen.
- Every number is a placeholder. Scales are today's: a Wickling has 3 hp, a full lamp is 1.0 charge, warmth is 100, and a tile is 32 px.
- All new names (creatures, guardians, lenses) are drafts.

---

## 0. In short

- **The loop:** push into the fog, burn what lives there, find the region's lamp, and use it to take the WayLamp back.
- **The kit:** an aimed beam that cracks shells, a burst, a dash. All three run on lamp charge. Lantern light refills it.
- **The find is the key:** each region hides its lamp. The road to the WayLamp has a lock only that lamp opens, and the guardian has a phase only that lamp answers. The four built lanterns become the four keys.
- **Weapons:** swappable lenses (the beam) and burners (the burst), found on side paths under an elite, or given by people.
- **Levels:** kills and kindling pay "wick". Each level, pick 1 of 3 from a pool of 16, in four lines named after the lanterns.
- **Each WayLamp has a guardian.** The 15 s hold becomes a fight in phases. The Soul of the Wick is the last one.
- **Still no game over.** Fainting costs more than today, and a guardian keeps the phase you reached.
- **The world:** lures you can see through fog, guarded caches, fixed packs, and two to four open leads instead of one goal.
- **First build:** the Hollow only, with a playtest gate. Slice 1 (the kit) is built.
- **Honest size:** this is a bigger game than the old plan. Eight milestones follow the prototype, five of them large. Most of the work is feel: enemy AI, tells, animation, hit feedback and sound.

---

## 1. Pillars and the core loop

### 1.1 Pillars

1. **Light is your weapon and your shelter.** The hand lamp fights. Lantern light refills it and warms you.
2. **The find is the key** (the owner's rule). Each new thing found in a region helps take that region.
3. **The dark fights back.** Shells, tells, packs, elites and guardians. Aim and movement come first.
4. **Fight from light to light.** Where you plant a lamp decides where you can stand and fight. This is what is left of "planning over reflexes".
5. **No game over.** Fainting sets you back. It never ends the game.
6. **Show, don't list.** Lures and short notes pull you on. Little to read.

### 1.2 The loop

**One line:** push into the fog, burn what lives there, find the region's lamp, and use it to take the WayLamp back.

**Second by second:** aim, crack the shell, burn, dash out, refill in the light.

**A session of 10-30 minutes:**

| Minutes | You do | You get |
|---|---|---|
| 0-2 | Leave held light with two to four leads. Pick one. | a direction |
| 2-10 | Fight packs on the way. Sweep the beam to see through fog. Spot a lure. | wick, embers, scrap; a level or two |
| 10-15 | Crack the elite sitting on a cache, or on the region's lamp. | a lens, burner, coat, satchel or lamp glass; or the key |
| 15-22 | Use the key on the lock. Plant lamps as you go. | ground taken; a road to the WayLamp |
| 22-30 | Feed the WayLamp. Fight its guardian. | the region held; someone comes back; the next region |

A 10-minute session is one lure and one level. A 30-minute session runs from the key to the guardian.

### 1.3 What stays, what changes, what goes

| Thing | Stays | Changes |
|---|---|---|
| The moody world, the palette, fog and memory | as built | your beam lights the fog along it (Built, slice 1) |
| The hand lamp | a light that dims to an ember and never goes out | it is the weapon, and its charge is your stamina |
| The four lanterns | build, fuel, pick up | each gets a job in a fight, and each is its region's key. The Post Lamp is found, not given |
| WayLamps | one per region; a held region is safe and keeps its lamps | the 15 s hold becomes a guardian fight |
| Oswin's trail | the letter, the notes, "- Oswin", never seen | notes also teach fights; goals become leads |
| Warmth and fainting | as built | fainting also drops wick; a guardian keeps its phase |
| Wind, soft ground, thick fog | each region's twist | each also bends that region's fights |
| The region order | Hollow, Reedmarsh, Ridge, Lakeshore, Still Lake | each ends in a guardian |
| The ward (hold F) | | gone; the burst replaces it (Built, slice 1) |
| "Planning over reflexes"; "in light nothing chases you" | | replaced by pillars 3 and 4 |
| The finale as "a confrontation of light, not a fight" | the ending text; it lets go, it isn't killed | a fight in three phases |
| Upkeep | at the frontier only, as WayLamps made it | no longer the main activity |
| Calm | held regions | the frontier isn't calm |

**Direction C's tides** stay on the shelf. They come back only if playtests say fights lack build-up (section 9).

**OWNER 1:** the pillars and the one-line loop, as drafted.

### 1.4 No game over

**Recommendation: keep it.** It fits the valley, the save system and the story ("fainting is a rest"). The stakes come from what a faint costs:
- you drop half your fuel and scrap, as built, and keep glass;
- you also drop the wick you earned toward your next level. It waits where you fell;
- a guardian goes back to the start of the phase you reached, with its shell regrown;
- you wake at the nearest lit lantern, as built. So a lamp planted near the fight is a short walk back.

**OWNER 2:** no game over, with the stiffer faint above.

---

## 2. The combat kit

### 2.1 Beam, burst, dash

| | Beam | Burst | Dash |
|---|---|---|---|
| **Does** | a focused beam along your aim. It burns everything in it and is the only thing that cracks a shell | a flash around you that hurts and throws things back | a quick step. Nothing chills you mid-dash |
| **Press** | hold left click / RT | tap F / RB | tap Shift / LT |
| **Size** | 240 px long, 24 px wide | 120 px radius | 110 px in 0.16 s |
| **Damage** | 6 hp/s (a Wickling in 0.5 s) | 2 hp, thrown back about 140 px | none |
| **Charge** | 0.3 per second (about 3.3 s from full) | 0.2 | 0.08 |
| **Cooldown** | none | 3 s | 0.9 s |
| **Also** | you walk at 70%; it lights the fog along it | elites are thrown half as far | goes the way you walk, or along your aim if you stand still |

All of this is **Built (slice 1)**, in `tuning.gd` as `kl_*`.

**What a full lamp buys:** about 3.3 s of beam (six Wicklings), or five bursts, or twelve dashes.

**Lessons from the first beam** (dropped on 2026-11-26): it killed too slowly, ate the fuel meant for lanterns, and missed things on top of you. This one kills a Wickling in half a second and runs on charge. The burst covers point-blank. If the beam still misses things touching you, widen its first 20 px.

### 2.2 Lamp charge as stamina

- Charge runs from 0 (ember) to 1.0 (full). It is also how far your lamp lights: 104 px down to 44 px. So spending it makes your world darker.
- **In lantern light** it refills at 0.5 per second, about 2 s from empty. Not while you beam. (Built)
- **In the dark** it only dims, over 45 s. (Built)
- **Carried fuel is the reserve.** Under a quarter charge, and 4 s after your last beam, burst or dash, the lamp burns 1 fuel for half a lamp. Never mid-fight. (Built)
- At an ember you can't beam, burst or dash. You can still walk, and you outrun most things: you walk at 160 px/s, a Wickling at 65.

So a fight in the dark is three seconds of beam, then a choice: fall back to a lamp, break off and burn fuel, or run. A lamp you planted nearby is a refill two seconds long. That is why lamps matter (2.5).

**OWNER 3:** the charge model. (a) As built: light refills it, fuel tops it up between fights. Recommended to test first; your ward playtest liked the push and pull. (b) If fights in the dark stall, add a slow free trickle: 0.05 per second after 2 s of quiet.

### 2.3 Shells

- A shell is a pale ring around a creature. It thins as the beam wears it. (Built)
- Only a beam wears it: yours or a Mirror Post's. Bursts and lantern cores glance off, with a clink. (Built)
- The beam's 6 hp/s goes into the shell first. A 4-point shell takes about 0.7 s. (Built)
- **Proposed:** a shell left alone for 3 s grows back, until it breaks. Once broken, it stays broken.
- **Proposed:** shelled dark can walk into lantern light. Unshelled dark burns in a lantern's bright core, as built (2 hp/s). So crack a shell next to a lamp and the lamp helps finish the job.

### 2.4 Warmth and fainting

- Warmth is your health: 100. It refills only in lantern light, at 20 per second. (Built)
- A Wickling's touch drains 30 per second, a shelled one 1.6 times that. (Built)
- **Proposed:** big hits come as one lump with a tell: a spit 12, a roll 25, a guardian's dive 25. Each tell lasts 0.5 s or more and is drawn on the ground in pale blue.
- **Proposed:** embers warm you a little, 2 each, on top of 1 fuel. Kills then pay something back mid-fight.
- No healing item for now. Lantern light is the healing. See Still open.
- Fainting: as in 1.4.

### 2.5 Lanterns in a fight

Lantern light stops being a wall and becomes a shelter.

| Lamp | Job in a fight | Rule |
|---|---|---|
| Post Lamp | **haven and trap** | refills your lamp and warms you; small unshelled dark won't enter and burns in its core; you wake here after fainting |
| Reservoir Lamp | **well** | wide dim light that feeds every lamp around it (0.75 fuel/s each, built), so a ring of havens outlasts a long fight; forces things in the water up |
| Hooded Lamp | **shelter** | wind and dives never snuff it; things that dive at it snag and burn |
| Mirror Post | **turret and lane** | a fixed beam, 11 tiles, that burns what crosses it and wears shells; it can throw your own beam on |

What still gets through light: shelled dark, anything a creature spits, and guardians. A lantern under a quarter tank is dying and can be drained, as built. Held regions stay fully safe, as built.

**OWNER 4:** light is a shelter, not a wall: shelled dark and spit get in.

### 2.6 Controls

| Action | Keyboard / mouse | Gamepad | Status |
|---|---|---|---|
| Move | WASD / arrows | Left stick / D-pad | as built |
| Aim | mouse | right stick; with neither, the way you face | Built (slice 1) |
| Beam (hold) | left click | RT | Built (slice 1) |
| Burst | F | RB | Built (slice 1) |
| Dash | Shift | LT | Built (slice 1) |
| Build lantern; turn a mirror left | Space | X | Built (slice 1): left click no longer builds |
| Use: read, refuel, turn right; hold to gather | E | A | as built |
| Pick up lantern | Q | B | as built |
| Swap lens (later, 5.3) | R / mouse wheel | click the right stick | proposed |
| Lantern list | Tab, 1-4 | Y | as built |
| Map / Journal / Pause | M / J / Esc | LB / View / Start | as built |

Notes:
- **Right click** still picks up a lantern. In a fight that is an easy mistake. Proposed: right click becomes a second burst button, and pick-up stays on Q / B.
- **On a pad,** A, X, B and Y take your thumb off the aim stick. That is fine out of a fight and awkward in one. The beam then keeps its last aim.
- **Pad aiming is harder than mouse aiming.** A gentle aim assist (pull toward a target within 12 degrees) belongs in the first feel pass, not the prototype.

**OWNER 5:** the controls, with right click as a second burst button.

---

## 3. "The find is the key"

### 3.1 The rule

1. **Each region hides its lamp**, a third to halfway along. It can be seen through fog, and an elite sits on it.
2. **The road to the WayLamp has a lock that only that lamp opens.**
3. **The guardian has a phase that only that lamp answers.**
4. **Afterwards the lamp is in your kit everywhere,** with the same job.

The four built lanterns become the four keys, so nothing built is thrown away. This is your own example made into the rule: unlocking a lamp was the fun part, and now the lamp is what takes the region. New weapons and abilities are the side finds (3.3). They follow the same rule in small.

### 3.2 The five keys

| Region | Key find | Where | The lock on the road | In the WayLamp fight | Afterwards |
|---|---|---|---|---|---|
| **The Hollow** | **the Post Lamp** | on a cold keeper's post about halfway north. Its red pulse shows through fog (a built effect). A Clinker sits on it | **nests.** Three lie across the way north. A nest hatches Wicklings without end. Only a lantern's bright core burns one out, so you plant a lamp beside it and hold for 6 s | the Ashbrood snuffs your hand lamp to an ember. A haven by the ring is the refill. Its brood burns in the cores | your haven, trap and waking point everywhere |
| **The Reedmarsh** | **the Reservoir Lamp** | the pumphouse, as built | **dark water.** The boardwalk to the WayLamp is broken in two places. Slowwaters hold your feet in unlit water, and you can't dash while wading. A Reservoir's wide light forces them up and makes a lane | the Sump stays under until Reservoir light forces it up. Then it drinks your lamps, and the Reservoir feeds them back | the lamp for long fights: one well keeps a ring of havens alive |
| **The Windward Ridge** | **the Hooded Lamp** | the glazier's workshop in the west, as built. The WayLamp is in the east | **the open saddle.** Gusts snuff exposed Post Lamps, and Gutterkites dive on them. East of the workshop, only Hooded Lamps and the lee of rock hold | the Galekite is out of reach until its dive snags on a Hooded Lamp | a haven that wind and dives can't snuff; a snare for anything that dives |
| **The Lakeshore** | **the Mirror Post** | on the old jetty (proposed; today it unlocks at the signal station) | **thick fog.** Your beam reaches 40% here. Fogstilts thicken the fog, and one beam can't hurt them. A mirror lane cuts the fog at full strength, and two beams crossing unravel a Fogstilt. You wade to the landing along a lane | the Tallest only comes apart where two beams cross: a mirror's and yours | a turret and a kill lane anywhere. A mirror throws your own beam on, 11 tiles |
| **The Still Lake** | **the catch ring** | Oswin's camp, in the crate of cut glass | **ordinary light dies here.** No lantern refills you or warms you. With the ring, standing in a mirror's beam does both, and a beam fired from inside a lane carries twice as far. A lantern works on the Lake only where a beam touches it. So mirrors lead and lamps follow | the Soul snuffs your lamp. Only a carried beam still fires | every beam lane in the valley is a haven |

**What moves.**
- **The Post Lamp** is no longer in the kit from the start. For the first minutes the hut lantern is your only haven.
- **The Reedmarsh's WayLamp** moves off the pumphouse island to the small island at the end of the south-east spur, where the marsh lamp glass lies now. Today the pumphouse and the WayLamp share an island, so the Reservoir arrives after the marsh is already crossed. That is the problem you described. The lamp glass moves to another corner. One goal text changes.
- **The Mirror Post's unlock** moves from the signal station down to the Lakeshore. The station stays as story: its cracked mirror, turned toward the water, shows what is coming.
- **The Lakeshore's WayLamp** takes fuel directly, like the others. That settles the point reopened in PLAN_LAKESHORE: you reach the landing by wading a beam lane, and no beam has to touch the lamp.

**OWNER 6:** the rule: each region's lamp is its key, found mid-region under an elite.

**OWNER 7:** the Post Lamp becomes the Hollow's find.

**OWNER 8:** move the Reedmarsh's WayLamp to the south-east island. The alternative keeps the WayLamp and moves the Reservoir's unlock west to the old frames.

**OWNER 9:** move the Mirror Post's unlock to the Lakeshore. The alternative keeps it at the station, as the reward for holding the Ridge.

**OWNER 10:** the catch ring as the Lake's find. This also keeps "the player builds every mirror" (DECIDED).

### 3.3 Side finds

Each sits off the main road under a guard, and each has a job where it is found.

| Region | Side find | Job in that region |
|---|---|---|
| The Hollow | keeper's satchel (built, far west); lamp glass (built, south) | more scrap for havens; a longer lamp |
| The Reedmarsh | **Wide lens**; **Oilskin**; satchel and lamp glass (built) | a wide beam that lights a swathe of water; wading at full speed |
| The Windward Ridge | **Oswin's coat** (the built landmark); **a shard of the great lens**, which Kit cuts into the **Long lens**; **Signal burner**; satchel and lamp glass (built) | gusts stop dimming your lamp; a long shot for things on the wind |
| The Lakeshore | **Split lens** | three thin beams, and each one counts for a crossing |
| The Still Lake | none. Oswin's hand lamp after the finale stays story | |

**OWNER 11:** the keeper takes and wears Oswin's coat. It is a strong story beat, and it is yours to call. If no, the coat stays a note and the Ridge gets another coat.

---

## 4. Enemies

### 4.1 Shared rules

- **All of them are pieces of the Soul.** No text says so outright. Cool colours and pale eyes; amber only where light burns them.
- **Uneasy, never horror.** They come apart like smoke or ash. No stingers and no gore.
- **Every lump hit has a tell** (2.4).
- **Counter first.** A creature appears only after its counter can be had (kept from the plan).
- **Held ground is quiet,** as built.
- **More, and bolder, far from held light** (planned since M5).
- **Fixed packs and a trickle.** Most fights are packs that sit at set spots and wake when you come close (6.2). Today's trickle of Wicklings from the fog stays as the background.
- **Each region is one family:** small ones, the region's creature, an elite, and a guardian that plays by the family's rules, bigger.

### 4.2 Families

| Region | Small dark | The region's creature | Elite | Guardian |
|---|---|---|---|---|
| The Hollow | Wicklings; Spitwicks; nests | | shelled Wicklings; a Clinker on the find | the Ashbrood |
| The Reedmarsh | Wicklings on the planks | **Slowwater**; Fenlights | a Clinker on an island | the Sump |
| The Windward Ridge | Wicklings waiting in the lee; Spitwicks | **Gutterkite** | a Clinker that rolls downwind | the Galekite |
| The Lakeshore | Wicklings out of the shallows | **Fogstilt** | a Clinker in the fog | the Tallest |
| The Still Lake | all of them, mixed | | | the Soul of the Wick |

### 4.3 Behaviours and counters

| Creature | Look | Does | Counter | Numbers |
|---|---|---|---|---|
| **Wickling** (built) | small, two pale eyes | chases you in packs of 3-6; drains a dying lantern | the beam; a burst when crowded; any haven's core | 3 hp, 65 px/s, 30 warmth/s on touch |
| **Shelled Wickling** (Built, slice 1) | bigger, with a pale ring | the same, slower and harder | beam first, then anything | 9 hp, 4 shell, 48 px/s, 1.6x chill |
| **Spitwick** (new) | thin; hangs back | keeps 6-8 tiles off and spits a slow blob of cold, which crosses lantern light. Backs away if you close in | dash through the spit; a burst throws it into reach; the beam matches its range | 4 hp; spit every 2.5 s with a 0.6 s tell: 12 warmth and 0.1 charge |
| **Nest** (new) | a heap with a cold blue glow, seen through fog | hatches 3 Wicklings every 10 s while you are within 10 tiles. The beam and the burst don't hurt it | plant a lamp so its core covers the nest; hold 6 s | 12 hp, burned only by a core |
| **Clinker** (planned; refitted) | cart-sized charred heap with cold blue cracks | sits on a cache or a cold lamp "like a cat on a cold hearth". Rolls at you in a straight line. Walks through light while shelled | dash across the roll; beam the cracks; once cracked, a lamp's core burns it too | 24 hp, 12 shell, 40 px/s; roll: 0.8 s tell, 25 warmth |
| **Slowwater** (planned; refitted) | a slow V of ripples and two pale eyes | under unlit water it can't be hurt. It holds your feet and drains warmth | any wide light on the water forces it up, stunned 2 s: a Reservoir, the Wide lens, a burst | 5 hp; hold 1.5 s; 8 warmth/s |
| **Fenlight** (new) | a small pale light that flickers; never amber | drifts like an ember or a lure and leads you into water. Bursts when you're close | one touch of the beam pops it. Real lures hold steady | 1 hp; 0.3 charge on bursting |
| **Gutterkite** (planned; refitted) | a torn strip of dark with two small eyes | rides the gusts west to east and dives along a marked lane. Snuffs exposed Post Lamps; brushes you | stand in the lee; bait the dive onto a Hooded Lamp, where it snags and burns | 3 hp; brush: 10 warmth and 0.15 charge |
| **Fogstilt** (planned; refitted) | very tall and thin; seen only against a beam; no eyes | never touches you. Fog thickens around it: beams fade short and small dark near it takes half damage | one beam makes it step away; two crossing unravel it in 2 s | no hp; `stilt_unravel_sec` 2 |

A Clinker gets one trait per region: on the Ridge it rolls faster downwind, and on the Lakeshore its shell shows only in a beam.

**OWNER 12:** the roster, and the names Spitwick and Fenlight.

**OWNER 13:** the Clinker becomes the elite that sits on finds, in every region from the Hollow on. The plan had it from the Ridge on, blocking cold frames.

### 4.4 WayLamp guardians

**The flow.** Walk up, feed 15 fuel (as built), and the guardian wakes. Beat it and the WayLamp takes: the region is held, with the built banner. The fuel stays in if you faint. No building within 5 tiles of the WayLamp (built), so havens stand at the edge of the ring. Aim for 2-4 minutes, and one to three faints the first time.

| Guardian | Phase 1 | Phase 2 | Phase 3 | The key's part |
|---|---|---|---|---|
| **The Ashbrood** (the Hollow). A heap of ash-grey dark in the WayLamp's bowl, with two pale eyes | **In the bowl.** Shelled. Sends a pack of 3 every 8 s. Its ash puff (a ring, 0.8 s tell) snuffs your hand lamp to an ember | **On the wing.** It leaves the bowl and dives at your lamps. Each dive snuffs one, and it sits on the cold lamp for 4 s. That is the opening | **Last of the brood.** Back in the bowl. Every nest still alive hatches at once. Its shell regrows unless the beam stays on it | a Post Lamp is your refill after each puff, the trap for the packs, and the bait for the dive. Nests you burned out on the way hatch nothing |
| **The Sump** (the Reedmarsh). A wide flat dark under the water, with two pale eyes | **Under.** It circles the island and can't be hurt. It grabs at the planks (ripples are the tell) | **Drinking.** It clamps onto a lantern and drains it. Slowwaters rise in all unlit water. It is still while it drinks | **High water.** The low planks flood. It lunges across the island (dash), and beaches for 3 s if it lands in light | Reservoir light forces it up in phase 1, feeds the lamps it drinks in phase 2, and keeps the water lit |
| **The Galekite** (the Ridge). A great torn kite with a long tail | **High.** Out of reach. With each gust it dives along a marked lane at your brightest exposed lamp | **Turning wind.** The wind swings, so the lee moves. Its tail sweeps the ground (dash). Gutterkites ride with it | **Grounded.** After three snags its tail tears. It drags itself along. The gust never stops, and Post Lamps stay snuffed | its dive snags only on a Hooded Lamp, for 5 s. In phase 3 only Hooded Lamps refill you |
| **The Tallest** (the Lakeshore). A Fogstilt three times the height, legs like pier posts | **Standing.** Over the landing. The fog is thick, and only two beams crossing on a leg unravel it | **Wading.** It steps from spot to spot. Each step lands on a lit mirror and smothers it for 8 s. A burst frees it | **Kneeling.** A knot of fog at head height. It throws fog banks that cut beams short for 3 s. Time the crossing | a mirror lane is one half of every crossing. Your beam is the half that moves |

Each guardian is M to build. The prototype's Ashbrood has two phases; the third comes in the feel pass.

**OWNER 14:** a guardian fight replaces the 15 s hold at every WayLamp, with the flow above.

**OWNER 15:** the four guardians and their names.

### 4.5 The Soul of the Wick

It is "it". It has big pale eyes. It never speaks. Why it rose stays unexplained. You don't kill it. You make it let go, and the built ending stands word for word: it slides into the water, the great lamp catches, the fog lifts.

| Phase | What happens | How you answer |
|---|---|---|
| **1. The coil** | Three coils around the great lamp, each shelled. Tendrils sweep the island (tell, dash). Wicklings rise from the water. It drains the lanterns that feed the shore mirrors (DECIDED: some pressure) | each coil cracks only under beams from two sides: a mirror's and your carried one. Built line: *It draws back from the light.* |
| **2. Every flame** | It throws each region back at you in turn, about 40 s each: the brood and its puff, high water, the gale, the still fog. A coil opens between turns. The broken lens said it: THE WICK REMEMBERS EVERY FLAME | each turn is answered by that region's lamp: a haven, a well, a Hooded Lamp, crossed beams. Built line: *The lamp's glass is showing through.* |
| **3. The eyes** | The coil hangs loose. Its eyes come down level with you. It snuffs your hand lamp and holds it at an ember. It smothers the mirrors one by one | stand in the chain's beam: with the catch ring your lamp still fires. Bursts free the mirrors. Hold the beam on its eyes until they close, three times. Built line: *It let go.* |

- Fainting: you wake at the nearest lit lamp. It winds back to the start of the phase you reached, and never further (as the plan said).
- Aim for 6-10 minutes.
- Phase 2 is the game's final exam: every find is a key once more.

**OWNER 16:** the finale becomes a fight in three phases. This replaces "a confrontation of light, not a fight" (2026-11-26). The ending text, "it", the eyes and the unanswered why all stay.

---

## 5. Progression

### 5.1 Wick and levels

- **Wick** is XP. It shows as a thin bar under the lamp bar.

| Source | Wick |
|---|---|
| Wickling | 1 |
| Spitwick, Gutterkite, Fenlight | 2 |
| Shelled Wickling, Slowwater | 3 |
| Nest burned out; Fogstilt unravelled | 8 |
| Clinker | 15 |
| Guardian | 40 |
| Kindling a WayLamp | 30 |

- **Levels:** the first costs 15 wick, and each one after costs 10 more (15, 25, 35...). The Hollow should give four or five. The cap is 12 for v1, so you end with 12 of the 16 upgrades and no two keepers match.
- **Levelling up** pauses the world and shows three cards. Pick one. The same card never shows twice in one offer.

DRAFT screen title: **Trim the wick** · DRAFT line under it: *Choose one.*

**OWNER 17:** wick from kills and kindling only (recommended). Paying wick for first-time notes and finds is the option. It rewards exploring, and it rewards reading.

### 5.2 The upgrade pool: 16, in four lines

Each line is named after a lantern, so a build has a flavour.

| Line | 1 | 2 | 3 | 4 |
|---|---|---|---|---|
| **Ember** (burning) | *Lingering burn:* what the beam touched keeps burning 2 s at 2 hp/s | *Catching:* a burning thing that dies sets the nearest one within 60 px burning | *Warm embers:* embers give 4 warmth and fly to you from twice as far | *Hot core:* your lanterns' cores burn twice as hard |
| **Mirror** (the beam) | *Tight focus:* shells wear 30% faster | *Long throw:* the beam reaches 310 px | *Bright spot:* held on one thing, the burn climbs to +50% over 1.5 s | *Steady hand:* you walk at 90% while beaming |
| **Hood** (staying alive) | *Lee:* touch chills 25% less | *Second step:* two dashes before the cooldown | *Heavy flare:* the burst throws 50% farther and stuns 0.6 s | *Banked flame:* when your lamp hits an ember, one free burst (once every 30 s) |
| **Reservoir** (charge) | *Deep tank:* the beam costs 20% less | *Quick fill:* lantern light refills you 50% faster, and the fuel top-up waits 2.5 s | *Overpour:* with the lamp empty, the beam burns carried fuel (1 per 1.5 s) | *Spill:* burst cooldown 2.2 s, and each thing it hits gives back 0.03 charge |

The prototype uses eight: the first two of the Ember and Reservoir lines as numbered here, Tight focus, Long throw, Second step and Heavy flare.

### 5.3 Weapons: lenses and burners

The lamp has two swappable parts. A **lens** shapes the beam. A **burner** shapes the burst. With a coat (5.4) and your trims, that is a build.

| Lens | From | The beam becomes |
|---|---|---|
| Keeper's lens | the start | the steady narrow beam (2.1) |
| Wide lens | a Reedmarsh cache | a short cone, 100 degrees and 130 px. 4 hp/s to everything in it. Shells wear at half speed |
| Long lens | a shard from the Ridge, cut by Kit | hold 0.8 s, then release a 420 px bolt: 6 hp, 4 shell, 0.25 charge |
| Split lens | a Lakeshore cache | three thin beams in a fan, 2.5 hp/s each. Each counts as a beam for a crossing |

| Burner | From | The burst becomes |
|---|---|---|
| Flare | the start | the round flash (2.1) |
| Smoulder | Maud | a ring of burning ground for 4 s (2 hp/s). No throw-back. 5 s cooldown |
| Signal | a cache on the Ridge | a thrown light that lands 200 px along your aim, draws small dark for 4 s, then flashes |
| Shutter | Ebba | a forward flash that stuns for 1.5 s, shells included. 5 s cooldown |

- You swap at any lit lantern or WayLamp, on a new **Lamp** page. Later, each satchel could let you carry one spare into the field to swap with R.
- Example builds: Wide lens, Smoulder and the Ember line for crowds. Long lens, Signal and the Mirror line for picking off elites.
- "Wick" is already the XP, the Soul and the Wicklings, so the burst part is called a burner.

**OWNER 18:** lenses and burners as the two weapon slots, four of each for v1.

### 5.4 Gear

**Coats** (one worn):

| Coat | From | Does |
|---|---|---|
| Patched coat | the start | nothing |
| Oilskin | a Reedmarsh cache | you wade at full speed; a Slowwater's hold lasts half as long |
| Oswin's coat | the Ridge (the built landmark) | +25 warmth; gusts don't dim your lamp |
| Quilted coat | Amos | touch chills 20% less; you walk 5% slower |

**The built finds keep their place.**
- **Lamp glasses** (3 built, a 4th from Maud): each still adds 12 px of reach and slows dimming by 25%. The third effect was a cheaper ward. Proposed instead: beam, burst and dash cost 10% less per glass. Slice 1 hasn't refitted this yet.
- **Keeper's satchels** (3 built, the Wide Pack from Amos): each still adds 10 to what you carry. Scrap, glass and fuel still pay for lanterns and WayLamps. Satchels matter a little less now, so the spare slot in 5.3 is their second job.

No gold and no shop screens. Trade stays in fuel, scrap and glass.

### 5.5 What people give you

| Person | Gives |
|---|---|
| Amos | trade, as planned; the Quilted coat; the Wide Pack for his errand (as planned) |
| Maud | the Smoulder burner; her lamp glass (as planned); she re-trims one upgrade for 5 fuel |
| Kit | cuts the Long lens from the shard; polished mirrors, 13 tiles (as planned) |
| Ebba | the Shutter burner, off her boat lamp; the crossing after the finale (DECIDED) |
| Ivo | the map marks lures, caches and nests; he adds leads |

**OWNER 19:** the gear: four coats, the lamp glass refit, and what each person gives.

---

## 6. The world and the quest line

### 6.1 Lures seen through fog

Today things show only once lit, so the fog between landmarks reads as empty. Lures are drawn above the fog, the way cold lanterns and embers already are.

| You see | It is | It means |
|---|---|---|
| a slow red pulse | a cold keeper's lamp | a haven to relight, or the region's key |
| a cold blue glow | a nest | a fight, wick, and a road cleared |
| a small glint | a cache | a side find, with a guard |
| pale eyes, low and still | an elite, sitting on something | the best finds |
| a tall still shape with a cold bowl | the WayLamp | where the region ends |

**The density rule:** from any lamp, every direction pays off within about 15 seconds of walking: a lure, a pack, a note or a find. Sweeping the beam is how you look, because it lights the fog along it.

### 6.2 Packs, caches and elites

- **Fixed packs.** Each region has 8-12 spots, placed by the map's seed. A pack sleeps there and wakes when you come within about 10 tiles. Beaten packs stay beaten until you faint or the region is held.
- **Side caches.** Three or four per region, each under a guard: a pack, a shelled Wickling or a Clinker. The six built finds become the first six caches. The lenses, burners and coats fill the rest.
- **Elites guard finds.** Sitting on things is what a Clinker does.
- **Small life near the light:** moths at lamps, something moving under the planks. Cheap, and it keeps held ground from feeling dead.

### 6.3 Leads, not a checklist

- Two to four leads are open at once. One comes from Oswin's trail. The rest come from what you have seen: a lure adds a lead the first time it shows.
- The banner shows the lead you last walked toward. The journal's Goals page becomes **Leads**.
- A lead is one short line. No step numbers, and no "go and read X".
- The pointer rule stays: on in the Hollow, off after (DECIDED).
- Only Oswin's lead is needed. The others are yours to take or leave.

DRAFT leads for the Hollow:
> Oswin's mark points north.
> A cold lamp, north of the hut.
> A cold blue glow among the ruins.
> Something glints to the west.

**OWNER 20:** leads replace the single goal line.

### 6.4 Less to read, more that reacts

- **A fight inside the first minute.** The letter stays. The first Wickling comes at 25 s, as built.
- **Prompts, not paragraphs.** Kit tips sit over the keeper for a few seconds:

DRAFT prompts:
> Hold [Left click] to shine. Aim with the mouse.
> Light cracks a shell. Keep it on.
> [F] throws them back. [Shift] steps clear.
> A nest. Only a lantern's core burns one out.

- **Notes stay at three lines or fewer,** and each one tells you something, moves the story, or unsettles.
- **Oswin's notes teach the fights.** Each key find carries one line from him about its lock.
- **The valley answers back.** A journal line after each guardian and after a faint. People come back to held ground. The music grows fuller as the valley is lit, as planned.

DRAFT note for the Hollow's find, `crook_post`, "A keeper's post":
> A keeper's crook, fallen across the path. The lamp on it is cold, but whole.
> Tied to it: Plant one where you mean to stand. The small ones will not come into it. - Oswin
> New lantern: Post Lamp. [Space] builds one.

DRAFT lines under a WayLamp's note, replacing the built three:
> Feed it 15 fuel.
> Something will wake when you do.
> Lit, it holds this whole region: its lanterns stop burning down, and nothing comes here.

DRAFT banner as the Ashbrood wakes: *Something is sitting in the bowl.*

DRAFT journal entry 13, replacing the built text: *It came apart like ash, and the WayLamp took. Now the Hollow keeps its own lamps.*

### 6.5 What happens to lantern building

- Building stays, with the same costs and rules. Lamps now do jobs: haven, well, shelter, turret (2.5).
- Expect fewer lamps, placed with more care: perhaps 6-10 in a region, not 15 or more.
- Upkeep stays at the frontier only. In a held region lamps never burn down (built).
- In a guardian's ring, where you put your lamps is the plan. This is where the old game lives on.
- **The risk:** building gets crowded out by fighting. Making each lamp a key is the guard against that. The prototype asks about it directly (8.4, question 8).

---

## 7. People

The plan's frame stays. People come back when a region is held, stand at one spot in held ground, and never fight or need rescue. No main lead needs a person. Oswin is never seen, and nobody saw him after the letter. He signs "- Oswin". The Soul is "it" or "the dark", and nobody says why it rose.

What changes: each person is a **service** in held ground, each **errand** takes you back into the dark, and each **gift** is a piece of a build.

| Person | Comes back to | Service | Errand, refitted | Gift |
|---|---|---|---|---|
| **Amos**, trader | the hut, once the Hollow is held | trade in fuel, scrap and glass; sells the Quilted coat | **Clear the road:** burn out the nests on the marsh passage and light it | the Wide Pack |
| **Maud**, old pump keeper, who knew Oswin | the pumphouse, once the Reedmarsh is held | re-trims one upgrade for 5 fuel | **Maud's lamp:** she dropped it in the north water when she left. It glints out there, among Slowwaters | her lamp glass; the Smoulder burner |
| **Kit**, glazier's apprentice | the workshop, once the Ridge is held | cuts and polishes lenses | **Fire the kiln:** 8 fuel, 3 glass and the shard of the great lens | the Long lens; polished mirrors |
| **Ebba**, rower | the old jetty, once the Lakeshore is held | none until the finale; then she rows you across (DECIDED) | **Show me the boat:** a Fogstilt stands over her boat in the reeds. Cross two beams on it | the Shutter burner, off her bow lamp |
| **Ivo**, mapmaker | the carved stone, once two regions are held | the map marks lures, caches and nests | **Walk the edges:** three survey stones, each in ground not yet held | new leads |

The planned lines still fit. One new DRAFT line each, for the gift:
- Amos: "You came past those nests on foot? Sit down. Take the pack. You'll fill it."
- Maud: "I kept this burner when I left. It never throws them back. It just keeps burning. Like him."
- Kit: "A piece of the big lens? Give it here. I can cut a long one from that."
- Ebba: "Take the shutter off my bow lamp. She's not rowing anywhere yet."
- Ivo: "I mark what glints. You go and find out what it is."

Ebba is "she". Maud's "him" is Oswin.

**OWNER 21:** people as services with errands that fight, and the five gifts.

---

## 8. The Hollow prototype

The first build, with a playtest gate. Branch `proto/keepers-light`. Slice 1 is built. It should play for 20-30 minutes.

### 8.1 Exact contents

| # | Slice | Contents | State |
|---|---|---|---|
| 1 | **The kit** | beam, burst, dash on lamp charge; mouse and right-stick aim; shelled Wicklings (every 4th); building on Space / X | **Built** (701c42e) |
| 2 | **Enemies** | the **Spitwick**; the **Clinker**; **nests**; 6-8 fixed packs; lures above the fog for nests, caches and the cold post | to build |
| 3 | **Wick and levels** | the wick bar; the "Trim the wick" screen; eight upgrades (5.2) | to build |
| 4 | **The find** | the Post Lamp starts locked. A Clinker sits on a cold keeper's post about 10 tiles north of the hut. Three nests lie on the way north, burned out only by a lamp's core | to build |
| 5 | **The guardian** | feed 15 fuel and the **Ashbrood** wakes; phases 1 and 2; the WayLamp takes when it falls. The faint rule from 1.4 | to build |
| 6 | **Feel** | a flash on every hit, the shell's clink and crack, a short freeze on a kill, a small shake on the burst, about six placeholder sounds; every number in the F1 panel | to build |
| 7 | **Leads, the small version** | the banner shows up to three leads for the Hollow. No journal page yet | to build; the first thing to cut |

**The run.** The opening as built. Relight the hut lantern. Fight near it, with the hut as your only haven. A red pulse shows to the north. Crack the Clinker and take the Post Lamp. Burn out three nests on the way north. Two glints, west and south, are the built satchel and lamp glass, each with a guard. Feed the WayLamp. Beat the Ashbrood. "The Hollow is held", then an end card. The passage east and the climb north are closed.

### 8.2 Placeholder numbers

| What | Value | State |
|---|---|---|
| Beam | 240 px x 24 px; 6 hp/s; 0.3 charge/s; walk 70% | Built |
| Burst | 120 px; 2 hp; thrown 140 px; 3 s cooldown; 0.2 charge | Built |
| Dash | 110 px in 0.16 s; 0.9 s cooldown; 0.08 charge | Built |
| Lamp charge | refills 0.5/s in lantern light; 1 fuel for 0.5 charge after 4 s of quiet | Built |
| Warmth | 100; +20/s in lantern light; faint at 0 | Built |
| Wickling | 3 hp; 65 px/s; 30 warmth/s; one from the fog every 12 s, up to 7 | Built |
| Shelled Wickling | 9 hp; 4 shell; 48 px/s; 1.6x chill; every 4th | Built |
| Fixed packs | 6-8 spots; 3-5 Wicklings each, two with a Spitwick; wake at 10 tiles | new |
| Spitwick | 4 hp; 55 px/s; keeps 180-240 px off; spit every 2.5 s, 0.6 s tell, 150 px/s; 12 warmth and 0.1 charge | new |
| Clinker | 24 hp; 12 shell; 40 px/s; roll: 0.8 s tell, 280 px/s for 260 px, 25 warmth; shell regrows 1 per second after 3 s out of the beam | new |
| Nest | 12 hp; burned only by a lantern core (2 hp/s, so 6 s); 3 Wicklings every 10 s while you are within 320 px | new |
| Ashbrood | 40 hp and a 12-point shell per phase. Phase 1: a pack of 3 every 8 s; puff: 140 px ring, 0.8 s tell, 15 warmth, lamp down to 0.1. Phase 2: dive: 0.7 s tell, 25 warmth, snuffs one lamp, then sits 4 s | new |
| Wick | as in 5.1; levels at 15, 25, 35, 45 | new |
| Fainting | drops half your fuel and scrap (built) and your wick toward the next level; the guardian restarts its phase | new |

A Clinker takes about 6 s of beam in all, which is nearly two full lamps. So it is a fight with a refill in the middle. That is on purpose.

### 8.3 Out of scope

- The Reedmarsh, the Ridge and everything past them. Both exits are closed.
- Lenses, burners, coats and the Lamp page. One lens and one burner only.
- People, trade and errands.
- The journal's Leads page, the other eight upgrades, the Ashbrood's third phase.
- New art and animation. Creatures are code-drawn shapes, as Wicklings are today.
- Music, a difficulty setting, pad aim assist, tides.
- Old saves. The prototype should keep its own save file, so your current save is safe.

### 8.4 Playtest questions

1. In the first two minutes, did aiming and firing the beam feel good? On the mouse and on the pad? What felt off: reach, speed, sound, the hit?
2. Did you dash on purpose to dodge? When you were hit, did it feel like your fault?
3. Did you work out the shell without being told? Did the Clinker take too long, or too little?
4. When you found the Post Lamp, did it change how you fought? Did it feel like the key to the nests and the guardian?
5. Did the three level-up choices feel like real choices? Which did you want more of?
6. The Ashbrood: tense but fair? How many faints? Did you know what to do in each phase?
7. Did the lures pull you off the road? Did the Hollow still feel empty anywhere?
8. Did you still build lamps, and why? Too easy, about right, or too hard?

**The gate.** Go on if you would rather keep playing this than the old build, and questions 1 and 2 are a yes. If the kit feels off, do one more feel slice before any new content. If the lamp as a find falls flat, try an ability as the Hollow's find before the rule spreads to every region.

**OWNER 22:** the prototype's contents, the cut line and the gate.

---

## 9. Milestones after the prototype

**Effort:** S is a small slice. M is one ordinary milestone. L is a big one, the size of M5a. No dates.

| Order | Milestone | Contents | Effort | Ends with |
|---|---|---|---|---|
| 0 | **KL0: the Hollow prototype** | section 8 | L (slice 1 done) | the gate |
| 1 | **KL1: feel, and fold in** | fixes from the playtest; the Ashbrood's third phase; first pass on animation, hit feedback and sound; pad aim assist; the Leads page; DESIGN, STORY and ROADMAP rewritten to match; merge to main | M | |
| 2 | **KL2: builds** | lens, burner and coat slots; the Lamp page; all 16 upgrades; the lamp glass and satchel refit; Clinkers on caches | M | playtest: do two builds feel different? |
| 3 | **KL3: the Reedmarsh** | Slowwater, Fenlight; the Reservoir as a well; the broken boardwalk and the moved WayLamp; the Wide lens and the Oilskin; the Sump | L | playtest; decide on tides |
| 4 | **KL4: people, part 1** | the talk panel and People page; Amos and Maud; trade and re-trimming; their errands | M | |
| 5 | **KL5: the Windward Ridge** | wind in fights; Gutterkite; the Hooded Lamp as shelter; Oswin's coat; Kit and the Long lens; the Signal burner; the Galekite | L | playtest |
| 6 | **KL6: the Lakeshore** | the new region (PLAN_LAKESHORE, refitted); mirrors as lanes; Fogstilt; the Split lens; Ebba and Ivo; the Tallest | L | playtest |
| 7 | **KL7: the Still Lake and the Soul** | region 5; the catch ring; the mirror chain; the Soul in three phases; the ending and the after-game | L, the largest | playtest |
| 8 | **KL8: polish and the Linux build** | balance, art, audio and music, settings, the build (the old M6) | L | done-when list |
| if needed | **Tides** | ebb and flood at the frontier (direction C) | M | only if KL3's playtest says fights lack build-up |

**Why this order.** Feel comes before content, because every later milestone multiplies it. Builds come before regions, so each region's side finds have a slot to go in. People wait until two regions exist in the new form.

**Honest size.** The old plan had about four milestones left. This has eight, five of them large. The 1-2 hour target likely becomes 3-4 hours. Ways to cut: fold the Lakeshore into the Still Lake (saves one L), ship three lenses and three burners, or drop Ivo.

**OWNER 23:** the order, and the playtime growing to about 3-4 hours.

---

## 10. Risks

1. **Feel is most of the work.** Each creature needs a brain, a tell, a sprite with frames, a sound and tuning: S for a small one, M for a guardian. There are nine creatures, four guardians and the Soul. If the beam doesn't feel good to fire, nothing else matters.
2. **The art is placeholders.** Creatures are code-drawn shapes. A tell needs two or three frames to read. Your art list grows by about 15 animated sprites, plus beam, burst and hit effects.
3. **An aimed beam was dropped once before** (2026-11-26). This one fixes the three complaints on paper. Only the playtest can confirm it.
4. **It is a different game.** It overrides "planning over reflexes", "light is safety" and the quiet finale. The moody world, the trail and no game over are what carry over.
5. **Balance can overshoot.** You called combat too easy twice. A guardian that takes ten tries is as bad. Every number sits in the F1 panel for that reason.
6. **Pad aiming** is harder than mouse aiming, and the face buttons take your thumb off the stick.
7. **Building may fade.** If lamps feel like chores between fights, the keys have failed. Question 8 checks.
8. **Built content needs rework:** the goals, the tips, the WayLamp texts, the Post Lamp start, the marsh WayLamp's spot and the Mirror Post's unlock. The people, creature and Lakeshore plans all need a refit pass.
9. **The stingy lamp may frustrate.** Three seconds of beam, then a walk to a lamp. OWNER 3 has the fallback.

---

## 11. OWNER lines and still open

| # | Choice | Recommended | Section |
|---|---|---|---|
| 1 | The pillars and the one-line loop | as drafted | 1 |
| 2 | No game over, with a stiffer faint: wick dropped, the guardian keeps its phase | yes | 1.4 |
| 3 | Charge model: light refills, fuel tops up; a slow trickle only if fights stall | (a) first | 2.2 |
| 4 | Light is a shelter, not a wall: shelled dark and spit get in | yes | 2.5 |
| 5 | Controls; right click as a second burst button | yes | 2.6 |
| 6 | The rule: each region's lamp is its key, found mid-region under an elite | yes | 3.1 |
| 7 | The Post Lamp becomes the Hollow's find | yes | 3.2 |
| 8 | Move the Reedmarsh's WayLamp to the south-east island | yes | 3.2 |
| 9 | Move the Mirror Post's unlock to the Lakeshore | yes | 3.2 |
| 10 | The catch ring as the Lake's find | yes | 3.2 |
| 11 | The keeper wears Oswin's coat | your call | 3.3 |
| 12 | The roster; the names Spitwick and Fenlight | yes | 4.3 |
| 13 | The Clinker as the elite that sits on finds, from the Hollow on | yes | 4.3 |
| 14 | A guardian fight replaces the 15 s hold | yes | 4.4 |
| 15 | The four guardians and their names | yes; the names are drafts | 4.4 |
| 16 | The finale becomes a fight in three phases | yes | 4.5 |
| 17 | Wick from kills and kindling only | yes | 5.1 |
| 18 | Lenses and burners, four of each | yes | 5.3 |
| 19 | Four coats; the lamp glass refit; what people give | yes | 5.4-5.5 |
| 20 | Leads replace the single goal line | yes | 6.3 |
| 21 | People as services, with errands that fight | yes | 7 |
| 22 | The prototype's contents, cut line and gate | yes | 8 |
| 23 | The milestone order; playtime of about 3-4 hours | yes | 9 |

**Still open**
- Every number. The prototype is where they get tuned.
- A healing item, such as a tin cup refilled at lamps. Only if fights away from light prove too punishing.
- A difficulty setting, or an easier "story" mode. Decide in KL8.
- Whether Wicklings still drain dying lanterns in the middle of a fight, or only between fights.
- Whether a held region can be lost again (open since the people plan).
- Whether Kit cutting a lens counts as crafting. DESIGN lists crafting beyond lantern recipes as out for v1.
- Pronouns for Amos, Maud, Kit and Ivo.
- Fogstilts on the Still Lake before the finale (the old OWNER 12 in PLAN_LAKESHORE).
- Whether the keeper's sprite sheet has frames to spare for a dash and a beam pose.

---

## 12. Checks and gaps

- **Read:** everything listed under Sources. Built numbers were checked against `systems/tuning.gd` on both branches and `scripts/player/combat.gd` on the prototype branch.
- **The brief's `wt-main` path was removed while I was reading.** I read `main` (eab9759) through git from then on. A worktree for `proto/keepers-light` appeared in its place. I read it and changed nothing.
- **Slice 1 is ahead of the brief.** The kit and shelled Wicklings are built. Section 2 uses their numbers instead of new ones, and the burst is in the kit from the start, as built.
- **Docs out of step on main:** DESIGN §8 still says WayLamps are a prototype awaiting a playtest. DECISIONS says they passed and are merged.
- **Map facts:** the hut, the Hollow's WayLamp, the marsh islands and the built finds were checked in `scripts/main/main.gd`. The cold post, the nests, the broken boardwalk and the jetty are proposals, not measured against the map.
- **Untested:** every new number, the fight lengths, and the level and playtime guesses. They are reasoning, not measurements.
- **Not checked:** how the lamp glass upgrade acts on the new kit in slice 1, and the keeper's sprite sheet.
- **Names:** all new names are original drafts. No names, characters, art or levels were taken from another game. The mechanics borrowed are the ones the research doc cites.
- **Texts:** every in-game line here is DRAFT, in the game's voice. Oswin is "he" and signs "- Oswin". Ebba is "she". The Soul is "it".
