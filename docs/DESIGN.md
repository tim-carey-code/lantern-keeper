# Lantern Keeper — Design Document

Synced to commit 9a2b9cc plus the Reservoir refuel fix (2026-11-26). History of decisions: docs/DECISIONS.md.

> Describes the game **as built** at 9a2b9cc. Unbuilt content is marked **planned**; §8 is a prototype. `docs/DECISIONS.md` overrides this file; story text lives in `docs/STORY.md`.
> Numbers from `systems/tuning.gd` are **placeholders**. Numbers fixed elsewhere in the code are marked *(code)*.
> Godot 4.7 (GDScript, Compatibility renderer) · 2D top-down · single-player · PC, Linux first · keyboard/mouse and gamepad.

---

## 1. Pitch and feeling

**Pitch:** As the new keeper of a dark, foggy valley, you build and tend lanterns that push the dark back, following the last keeper, H., to the cold great lamp at the Still Lake.

**Feeling:** calm, curious, moody, rewarding, with a quiet unease.
- **Light is safety.** In it you warm up, your lamp refills and nothing chases you.
- **The dark is not empty.** Wicklings drain lanterns and chill you, but there is no death and no game over.
- **Planning over reflexes.** The fun is deciding where the light goes.

---

## 2. Core loop

1. **Look** at the edge of the light.
2. **Gather** what it reveals: fuel, scrap, glass.
3. **Build or refuel** at the edge.
4. **Watch** the fog pull back and new things appear.
5. **Tend.** Lanterns burn down, faster in wind or with Wicklings at them. Ward Wicklings off, then recharge in the light.
6. **Follow** the goal line and H.'s notes onward.

Over a session: *light a path → read H.'s next mark → unlock a lantern → reach the region it was made for.*

---

## 3. Systems

### 3.1 Light and fuel
- Fuel lanterns burn their tank, and their light shrinks as it empties (numbers in 3.4).
- An empty lantern goes **cold**: no light, but its frame shows through fog with a red pulse. Fuel alone relights it.
- **Carried fuel:** 1 unit = 10 lantern fuel. E / A pours in what the tank needs.
- Lanterns below 25% *(code)* pulse amber. Cold and low ones are flagged on the HUD, at the screen edge and on the map.
- **Hand lamp:** 104 px of light, dimming to a 44 px **ember** over 45 s in the dark. It refills at 0.5 per second in lantern light (within 85% of a lit lantern's radius *(code)*) and burns 1 carried fuel when low. It never goes out.

### 3.2 Fog and memory
- The valley is 112 × 100 tiles of 32 px *(code)*, each with fog from 0 (clear) to 1.
- Light clears fog (up to 0.8 per second). Unlit tiles fog back in (up to 0.05 per second, fastest next to fog), so lone lights get eaten at the edges. Reedmarsh fog returns 1.8× as fast; gusts make it 1.5× as fast everywhere.
- A tile once clearer than 0.3 is **remembered** *(code)*: a dim blue haze on screen and map. Never-seen ground is near-black.
- Resources and landmarks show only below 0.35 fog; building needs 0.6 or less *(code)*. Full fog slows walking to 60%.

### 3.3 Resources and gathering
- **Fuel:** resin from dead trees, peat in the Reedmarsh, the hut woodpile, Wickling embers. **Scrap:** ruins, sometimes Wicklings. **Glass:** the Ridge only (14 spots).
- Hold E / A on a lit spot to gather 1 unit per 0.25 s. You carry up to 30 of each *(code)*.
- Spots regrow while lit *(code)*: 1 unit per 45 s (peat), 60 s (resin), 75 s (scrap) or 120 s (glass).
- **No soft-lock:** the hut woodpile regrows every 10 s, even in the dark *(code)*.
- **Planned, not built:** carry-limit and hand-lamp upgrades (ROADMAP M5).

### 3.4 The four lanterns
Space / X (or left click) builds the selected lantern on your tile: firm ground (not rock or soft marsh), lit or at the edge of the light, at least 1.5 tiles from other lanterns *(code)*. The outline shows its light and cost, or why it can't be built. Q / B picks a lantern up for half its cost (rounded down) plus its fuel.

| | Post Lamp | Reservoir Lamp | Hooded Lamp | Mirror Post |
|---|---|---|---|---|
| **Cost** | 5 scrap | 8 scrap | 5 scrap + 2 glass | 4 scrap + 3 glass |
| **Tank, burn** | 100, 0.5/s (~3.3 min) | 200, 0.3/s (~11 min) | 100, 0.5/s | none |
| **Light** | 224 px, shrinks to 40% | 200 px, dim, shrinks to 60% | 180 px, shrinks to 40% | 40 px glow + beam |
| **Wind** | exposed | exposed | immune | immune |
| **Unlocked at** | start | the pumphouse | the glazier's workshop | the signal station |

- **Post Lamp:** a shepherd's crook with a hanging lamp. The old one by the hut starts cold.
- **Reservoir Lamp:** from its own tank, feeds 0.75 fuel per second to each other fuel lantern in its light, lit or cold (so it relights them), but not to other Reservoirs or mirrors.

### 3.5 Wind
- **Gusts, valley-wide:** 30-55 s of calm, a 5 s warning, then a 10 s gust from one of four directions. Exposed fuel lanterns burn 3× as fast and shrink to 70%.
- **Shelter:** rock, or the map edge, 1-2 tiles upwind *(code)*. Hooded Lamps and Mirror Posts ignore wind.
- **The Ridge's constant west wind:** exposed lanterns there always burn 1.6× as fast and shine at 85%; rock to the west shelters them (22 outcrops *(code)*). On the Ridge, calm gaps shrink to 12-22 s, and gusts stack on top (4.8× burn).
- **Feedback:** wind streaks, a wind mark and a flashing fuel bar on exposed lanterns, and a chip ("Wind rising" or "Gust: 3 lanterns exposed") only while a coming or current gust would hit them. No pop-ups.

### 3.6 Wicklings, the ward, warmth and fainting
- **Wicklings** are small pieces of the dark: 3 hp, 65 px/s, noticing things within 380 px. After 60 s, one comes every 12 s (up to 7 at once) from deep fog 10-18 tiles away *(code)*. The rate is the same everywhere; more of them far from the hut is planned.
- **Against lanterns:** they creep to the rim of the nearest lit lantern and drain 5 fuel per second (a full Post Lamp in about 20 s); a dark tendril shows which. Lit mirrors get smothered instead (3.7). A lantern's bright core (its inner 45%) burns them at 2 hp per second, and they never step into it on purpose.
- **Against the keeper:** in the dark they chase you, and their touch drains 30 warmth per second. Lantern light ends the chase.
- **Warding glow (hold F / RB / RT):** a 110 px circle that burns 4.5 hp per second (about 0.7 s per Wickling) and pushes them back, even point-blank. It spends **hand-lamp charge, never carried fuel**: 0.25 per second, so 4 s from a full lamp and none from an ember. You walk at 60% while warding. In lantern light the lamp refills faster than the ward drains it, so the ward only runs dry in the dark.
- **Drops:** an ember worth 1 fuel (it glows, drifts to you and fades after 30 s), and a 35% chance of 1 scrap.
- **Warmth** is the keeper's health: 100, refilling 20 per second in lantern light only.
- **Fainting** at 0 warmth: half your carried fuel and scrap drops where you fell (glass is kept), and you wake by the nearest lit lantern (or the hut) at 60% warmth as the Wicklings back off *(code)*. No death, no game over.

### 3.7 Mirror beams, chains and smothering
- A Mirror Post **catches** light within 90% of a burning lantern's current radius, or in another catching mirror's beam, so chains pass light along.
- Its **beam** is 352 px (11 tiles) long and 48 px wide, in one of 8 directions; rock stops it. Beams clear fog fully and burn Wicklings in about a second (3.5 hp per second); Wicklings can't sense them coming.
- Standing next to a mirror, E / A turns it right and Space / X turns it left.
- Lantern light shrinks with fuel and wind, so a mirror near the edge can drop out and break the chain.
- **Smothering:** a Wickling clinging to a lit mirror turns it dark and cuts the chain after it. It drinks any beam instead of burning, so only the ward drives it off. Mirrors have no health; a chip counts smothered mirrors.
- A mirror deep in a lantern's bright core is out of reach; mirrors farther out, and relays lit only by beams, can be smothered.

### 3.8 Story and guidance
Text lives in STORY.md, mirrored in `systems/story/story.gd` and `scripts/main/main.gd`.
- **Opening** (new games only): a three-line title card, "Your name, keeper?" (up to 16 characters *(code)*; left empty, you are "Keeper"), then H.'s letter.
- **Goals:** 18 for the built regions, one at a time in the top banner, completed by what you do. Finish one early and the next unfinished one shows. Goal 18 waits for the Still Lake; 19-24 are planned.
- **Goal pointer:** a soft amber arrow at the screen edge, or a chevron over the target. Auto mode: on in the Hollow, off once you first walk into the Reedmarsh. The pause menu sets auto, always on or off.
- **Journal (J / View):** *Goals*, *Story so far* (H.'s letter and the keeper's entries, 8 so far) and *Notes* (every landmark read). It is titled with the keeper's name.
- **Landmarks:** 13 built; unread ones glow, and three unlock lantern types. A region's name fades in when its ground is first seen.
- **Tips:** 12 one-time tips. "Show tips again" is in the pause menu.

### 3.9 HUD and controls
- **HUD:** top left, resources, the hand-lamp and warmth bars and the lantern you will build; top centre, the goal; top right, status chips only when something needs you (wind, smothered mirrors, cold or low lanterns, getting cold, an ember lamp).
- **Prompts** sit over the thing you can use ("[E] Refuel 62%", "[E] Read", "[E] Turn right"); the build outline shows the cost, or why you can't build.
- **Device-aware:** button letters follow the device you used last (E on keyboard, A on a controller). The cursor hides when you aren't using the mouse.

| Action | Keyboard / mouse | Gamepad |
|---|---|---|
| Move | WASD / arrows | Left stick / D-pad |
| Read, refuel/relight, turn mirror right; hold to gather | E | A |
| Build lantern; next to a mirror, turn it left | Space / left click | X |
| Pick up lantern | Q / right click | B |
| Ward (hold) | F | RB / RT |
| Switch lantern (tap), list (hold), pick directly | Tab, 1-4 | Y |
| Map / Journal / Pause | M / J / Esc | LB / View / Start |
| Fullscreen; tuning panel (dev) | F11; F1 | —; L3 |

### 3.10 Save, load and pause
- One save slot, plus autosave every 60 s *(code)*, on closing the window and from the pause menu.
- Saved: the keeper, inventory, unlocks, every lantern, resource spots and dropped piles, the fog and what has been seen, and story progress. Not saved: Wicklings, embers, wind.
- **Pause menu (Esc / Start):** Resume, Save, New game (press twice; deletes the save), Save and quit, Goal pointer, Show tips again, plus the controls.
- Notes, menus, the map and the journal pause the world.

---

## 4. Regions

One fixed map, built by code from a fixed seed, so it is the same in every game. It never reloads; it only becomes lit. Each region adds one twist.

**1. The Hollow** (start, built). A sheltered bowl around the keeper's hut. The hut lantern starts cold; the woodpile and a scrap pile sit close by; 18 resin trees and 16 ruins *(code)*. Landmarks: the letter, the lantern rack, the ledger, the carved stone at the east passage, a cairn at the foot of the climb. Goals 1-6, with the pointer on.

**2. The Reedmarsh** (east, built). **Twist: soft ground.** You wade at 85% speed *(code)*, but lanterns stand only on boardwalks and six islands, and fog returns faster. 24 peat and 6 scrap spots *(code)*. Landmarks: old frames, chalk on the pumphouse wall, the pumphouse (Reservoir Lamp). Goals 6-10.

**3. The Windward Ridge** (north, built). Up a narrow climb from the Hollow. **Twist: wind.** 14 glass, 8 fuel and 7 scrap spots *(code)*. Landmarks, west to east: the glazier's workshop (Hooded Lamp), a broken lens, a keeper's coat, the signal station (Mirror Post), old steps going down. Goals 11-18.

**4. The Still Lake** (planned). Down the old steps. **Twist: fog too thick for ordinary light.** Only beams cut through, so the player chains mirrors from the shore to the island. H.'s camp holds a half-built mirror frame and a crate of glass; the player builds every mirror. 8 landmarks and goals 19-24 are in STORY.md.

**The finale** (planned). A confrontation of light, not a fight. The Soul of the Wick took the valley's light. It is "it", with no name and no face: a coil of living darkness around the cold great lamp. It drains the lanterns feeding the mirrors, Wicklings rise from the water, and standing near it chills the keeper. The ward pushes it back while beams strike the coil from more sides, until it lets go and slides into the water. The great lamp catches, and the fog lifts over the whole valley. The game answers **who** took the light, not **why**. Afterwards the valley stays open as a sandbox.

---

## 5. Version 1 scope box

**IN** (status at 9a2b9cc)

| Item | Status |
|---|---|
| One map, four regions; 15-25 landmarks | 3 regions and 13 landmarks built; 21 written |
| Four lantern types, three resources, the hand lamp, fog, wind | built |
| **Combat, enemies, health, in light-based form:** Wicklings, warding glow, warmth, fainting | built |
| The finale with the Soul of the Wick, then sandbox play | planned |
| Opening, goals, pointer, journal, tips | built for 3 regions |
| Build, refuel, pick up, relight; lantern list; HUD; map | built |
| Keyboard/mouse and gamepad for every action | built |
| Save/load: one slot plus autosave | built |
| Atmosphere: lights, fog, sound, pixel art | built; placeholders remain |
| Settings: fullscreen, goal pointer, tips; volume | volume planned (M6) |
| Carry-limit and hand-lamp upgrades | planned (M5), not built |
| Wickling variety by region; more far from the hut | planned (M5), not built |
| A Linux build | planned (M6) |

**OUT** (v1): death or game over; story told through dialogue, NPCs or cutscenes; more than one map, or random maps; day/night, rain, seasons; crafting beyond the lantern recipes; a Windows build.

**Target playtime:** about 1-2 hours to relight the great lamp.

**Done when:** a new player reaches the finale without help; no soft-locks; all regions, lanterns and landmarks are in; save/load restores everything; both kinds of input work everywhere; the Linux build runs on a fresh machine; `assets/CREDITS.md` is complete.

---

## 6. Maybe later
- Rain (puts out exposed lanterns), snow, a weather cycle; day and night.
- More lantern types: coloured lights that reveal hidden marks, floating lanterns, a lighthouse.
- More regions after v1 (the small light past the lake is the hook).
- A Windows build; Steam Deck.
- An original soundtrack.
- A photo mode, and an "ambient" mode with no goals.
- NPCs and more enemy types (a separate proposal is pending).

---

## 7. Art and audio direction
- **Moody pixel art:** 16×16 tiles drawn at 2× (32 px on screen, one fog tile), nearest-neighbour filtering, hard edges. Tall things are 16×32.
- **14-colour palette** (`source/palette/lantern-keeper-14.gpl`): cool blues for the world; ambers only for light, fire and wood, so warmth means safety.
- **CC0 sources, recoloured to the palette:** Kenney Tiny Town and Tiny Dungeon, Puny Characters (the keeper) and Kenney fonts, all listed in `assets/CREDITS.md`.
- **The owner's own art** (Pixelorama) replaces placeholders over time. The Post Lamp is done; the other lanterns, resources and Ridge landmarks are placeholders, and Wicklings and embers are drawn by code (`docs/ART_CHECKLIST.md`).
- **Light and dark:** near-black darkness, a flickering 2D point light for every light, and soft-edged fog on its own layer. Not used so far: occluder shadows, a fog shader, mist particles.
- **Audio:** Kenney CC0 sound effects and a synthesized placeholder ambience; recorded night ambience is still to come. No music yet: it should be quiet and grow fuller as more of the valley is lit. No jump scares.

---

## 8. WayLamps (PROTOTYPE, owner playtest pending)

> Owner-approved direction; **not in the game at 9a2b9cc** and not yet playtested. "WayLamp" is the owner's name. Numbers are placeholders, not yet in `tuning.gd`. If the playtest passes, this changes upkeep (3.1, 3.4) and the Wickling rules (3.6, 3.7). Draft story text: STORY.md §11.

**Why.** As built, lighting all regions would take ~40-50 lanterns, each refuelled every ~3 minutes: a refuel every ~4 s. And neglect had no consequence.

**One WayLamp per region**, left by the old keepers:
- **The Hollow:** by the carved stone at the east passage.
- **The Reedmarsh:** on the pumphouse island.
- **The Windward Ridge:** by the signal station.
- **The Still Lake:** the great lamp is the last one.

**Kindling one**
1. **Reach it** with your own light: a burning lantern, or a mirror beam.
2. **Feed it** about 15 carried fuel.
3. **Hold it** for about 15 s while a swarm of bold Wicklings tries to sap it. The ward drives them off.

**A held region**
- Its lanterns stop burning fuel and are refilled.
- No Wicklings spawn there.
- Lanterns built there later are held too.
- So upkeep only exists at the **frontier** region, the one you are opening up.

**Wickling rules in the prototype**
- Healthy light repels Wicklings back into the dark.
- Only a lantern below a quarter of its tank is **dying**, and only a dying lantern can be drained or snuffed.
- A dying lantern inside a healthy lantern's light is protected.
- Mirrors inside healthy light are safe; relay mirrors in the dark can still be smothered.

**Story tie.** The great lamp's plate reads IT WAS NEVER MEANT TO BE KEPT BY ONE. The keepers kept the WayLamps; the WayLamps kept the lamps. When the keepers left, one keeper could not hold them all.

**Notes for the playtest**
- "Dying" starts at 25%, where the HUD already marks lanterns as low.
- As built, the ward is free inside lantern light (the lamp refills at 0.5 per second; the ward spends 0.25), so during the hold the limit is how much one 110 px circle can cover, not lamp charge.
- Questions: Does holding a region feel like a reward? Is the hold tense but fair? Does frontier-only upkeep keep lanterns meaningful?
