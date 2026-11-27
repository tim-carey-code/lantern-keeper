# Lantern Keeper — Design Document

Synced to commit 9a2b9cc plus the Reservoir refuel fix (2026-11-26); map sizes, regions and performance synced on `proto/kl-big` (2026-11-27); the loop route and WayLamp fast travel synced on `proto/kl-loop` (2026-11-27). History of decisions: docs/DECISIONS.md.

> Describes the game **as built** at 9a2b9cc. Unbuilt content is marked **planned**; §8 is a prototype. `docs/DECISIONS.md` overrides this file; story text lives in `docs/STORY.md`.
> Numbers from `systems/tuning.gd` are **placeholders**. Numbers fixed elsewhere in the code are marked *(code)*.
> Godot 4.7 (GDScript, Compatibility renderer) · 2D top-down · single-player · PC, Linux first · keyboard/mouse and gamepad.

---

## 1. Pitch and feeling

**Pitch:** As the new keeper of a dark, foggy valley, you build and tend lanterns that push the dark back, following the last keeper, Oswin, to the cold great lamp at the Still Lake.

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
6. **Follow** the goal line and Oswin's notes onward.

Over a session: *light a path → read Oswin's next mark → unlock a lantern → reach the region it was made for.*

---

## 3. Systems

### 3.1 Light and fuel
- Fuel lanterns burn their tank, and their light shrinks as it empties (numbers in 3.4).
- An empty lantern goes **cold**: no light, but its frame shows through fog with a red pulse. Fuel alone relights it.
- **Carried fuel:** 1 unit = 10 lantern fuel. E / A pours in what the tank needs.
- Lanterns below 25% *(code)* pulse amber. Cold and low ones are flagged on the HUD, at the screen edge and on the map.
- **Hand lamp:** 104 px of light, dimming to a 44 px **ember** over 45 s in the dark. It refills at 0.5 per second in lantern light (within 85% of a lit lantern's radius *(code)*) and burns 1 carried fuel when low. It never goes out.

### 3.2 Fog and memory
- The valley is 224 × 200 tiles of 32 px *(code)*, each with fog from 0 (clear) to 1. (It was 112 × 100 until 2026-11-27, when every region grew to 4x its area.)
- Light clears fog (up to 0.8 per second). Unlit tiles fog back in (up to 0.05 per second, fastest next to fog), so lone lights get eaten at the edges. Reedmarsh fog returns 1.8× as fast; gusts make it 1.5× as fast everywhere.
- A tile once clearer than 0.3 is **remembered** *(code)*: a dim blue haze on screen and map. Never-seen ground is near-black.
- Resources and landmarks show only below 0.35 fog; building needs 0.6 or less *(code)*. Full fog slows walking to 60%.

### 3.3 Resources and gathering
- **Fuel:** resin from dead trees, peat in the Reedmarsh, the hut woodpile, Wickling embers. **Scrap:** ruins, sometimes Wicklings. **Glass:** the Ridge only (14 spots).
- Hold E / A on a lit spot to gather 1 unit per 0.25 s. You carry up to 30 of each *(code)*.
- Spots regrow while lit *(code)*: 1 unit per 45 s (peat), 60 s (resin), 75 s (scrap) or 120 s (glass).
- **No soft-lock:** the hut woodpile regrows every 10 s, even in the dark *(code)*.
- **Upgrades** lie in the far corners of each region, revealed by light like landmarks: a **keeper's satchel** (carry 10 more of each resource, so 30 → 60 with all three) and a **lamp glass** (the hand lamp reaches 12 px further, dims 25% slower and the ward costs 15% less charge, per glass). Read one to take it. Numbers in `tuning.gd` (`carry_*`, `lamp_upgrade_*`).

### 3.4 The four lanterns
Space / X (or left click) builds the selected lantern on your tile: firm ground (not rock or soft marsh), anywhere you can stand (no "too dark" rule since 2026-11-27), at least 1.5 tiles from other lanterns *(code)*. Building is quiet: no outline or cost text shows until you try, and if you can't build there, the outline and the reason show for 2 s. You can't build on top of a resource. Q / B picks a lantern up for half its cost (rounded down) plus its fuel.

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
- **Wicklings** are small pieces of the dark: 3 hp, 65 px/s, noticing things within 380 px. After 25 s, one comes every 12 s (up to 7 at once) from deep fog 10-18 tiles away *(code)*. The rate is the same everywhere; more of them far from the hut is planned.
- **Against lanterns:** they creep to the rim of the nearest lit lantern and drain 5 fuel per second (a full Post Lamp in about 20 s); a dark tendril shows which. Lit mirrors get smothered instead (3.7). A lantern's bright core (its inner 45%) burns them at 2 hp per second, and they never step into it on purpose.
- **Against the keeper:** in the dark they chase you, and their touch drains 30 warmth per second. Lantern light ends the chase.
- **Warding glow (hold F / RB / RT):** a 110 px circle that burns 4.5 hp per second (about 0.7 s per Wickling) and pushes them back, even point-blank. It spends **hand-lamp charge, never carried fuel**: 0.45 per second, so about 2 s from a full lamp and none from an ember. You walk at 60% while warding, and the lamp doesn't refill while you ward, even in lantern light (owner, 2026-11-27: combat was too easy). Lamp glasses make it cheaper.
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
- **Opening** (new games only): a three-line title card, "Your name, keeper?" (up to 16 characters *(code)*; left empty, you are "Keeper"), then Oswin's letter.
- **Goals:** 18 for the built regions, one at a time in the top banner, completed by what you do. Finish one early and the next unfinished one shows. Goal 18 waits for the Still Lake; 19-24 are planned.
- **Goal pointer:** a soft amber arrow at the screen edge, or a chevron over the target. Auto mode: on in the Hollow, off once you first walk into the Reedmarsh. The pause menu sets auto, always on or off.
- **Journal (J / View):** *Goals*, *Story so far* (Oswin's letter and the keeper's entries, 8 so far) and *Notes* (every landmark read). It is titled with the keeper's name.
- **Landmarks:** 13 built; unread ones glow, and three unlock lantern types. A region's name fades in when its ground is first seen.
- **Tips:** 12 one-time tips. "Show tips again" is in the pause menu.

### 3.9 HUD and controls
- **HUD:** top left, resources, the hand-lamp and warmth bars and the lantern you will build; top centre, the goal; top right, status chips only when something needs you (wind, smothered mirrors, cold or low lanterns, getting cold, an ember lamp).
- **Prompts** sit over the thing you can use ("[E] Refuel 62%", "[E] Read", "[E] Turn right"); a failed build shows why, for a moment. Beside a lantern, a tap refuels it and holding gathers the resource next to it.
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
- Three save slots, chosen on a screen at start (your keeper, region and play time on each), plus autosave every 60 s *(code)*, on closing the window and from the pause menu.
- Saved: the keeper, inventory, unlocks, every lantern, resource spots and dropped piles, the fog and what has been seen, and story progress. Not saved: Wicklings, embers, wind.
- **Pause menu (Esc / Start):** Resume, Save, New game (press twice; deletes the save), Save and quit, Goal pointer, Show tips again, plus the controls.
- Notes, menus, the map and the journal pause the world.

### 3.11 Performance
- Budget: game logic (process + physics) averages well under 4 ms a frame with 30 lanterns and 20 foes, measured by `tools/bench/bench.tscn` (see AGENTS.md).
- The fog steps only tiles that can change: those below full fog, and those in light this tick. The fog texture updates only those tiles.
- Foes read lantern light from one shared snapshot a frame (`systems/light/light_sense.gd`) instead of asking every lantern.
- The map is drawn once, in 16 × 16 tile chunks *(code)*, so the renderer culls what is off screen and a light redraws only the chunks under it. Lanterns redraw only when their look changes.

---

## 4. Regions

One fixed map, built by code from a fixed seed, so it is the same in every game. It never reloads; it only becomes lit. Each region adds one twist.

**Sizes (2026-11-27, owner: "make them all 4x bigger"):** every region is twice as wide and twice as tall as before, about 4x the area, and everything hand-placed kept its relative place. The map is 224 × 200 tiles *(code)*. The Hollow is an oval about 76 × 88 tiles (about 5,500 open tiles); the Reedmarsh about 112 × 96 (about 8,500); the Ridge about 120 × 52 (about 4,800). The passage to the marsh is 10 tiles wide, the climb to the Ridge 10 wide, and the marsh climb (the loop's way up, 2026-11-27) about 8 wide. The north-east quarter, above the marsh, is kept empty for the Lakeshore and the Still Lake. Resource spots, packs and nests are 4x as many, so the bigger space is as full as the old one, and each region has old caches (one-off piles of scrap, fuel or glass) at its dead ends.

**1. The Hollow** (start, built). A sheltered bowl around the keeper's hut. The hut lantern starts cold; the woodpile and a scrap pile sit close by; 72 resin trees and 64 ruins *(code)*, and three old caches. Landmarks: the letter, the lantern rack, the ledger, the carved stone at the east passage. Its WayLamp stands in the north-east, on the way east (the loop, 2026-11-27). The old climb at its top is closed by fallen stones until you push them down from the Ridge (a later shortcut). Goals 1-6, with the pointer on.

**2. The Reedmarsh** (east, built). **Twist: soft ground.** You wade at 85% speed *(code)*, but lanterns stand only on boardwalks and ten islands, and fog returns faster. 96 peat and 24 scrap spots *(code)*, and two old caches. Landmarks: old frames, chalk on the pumphouse wall, the pumphouse (Reservoir Lamp), and a cairn at the foot of the marsh climb, the path that leaves its north-west corner for the Ridge (the loop). Goals 6-11.

**3. The Windward Ridge** (north, built). Up the marsh climb to its east end (the loop, 2026-11-27; the old climb from the Hollow is a later shortcut). **Twist: wind.** 56 glass, 32 fuel and 28 scrap spots *(code)*, 88 rock outcrops, and two caches of glass. Landmarks, one way from the marsh climb to the old steps: the glazier's workshop (Hooded Lamp), a broken lens, a keeper's coat, the signal station (Mirror Post), its WayLamp, old steps going down. The far west is optional. Goals 11-18.

**4. The Still Lake** (planned). Down the old steps. **Twist: fog too thick for ordinary light.** Only beams cut through, so the player chains mirrors from the shore to the island. Oswin's camp holds a half-built mirror frame and a crate of glass; the player builds every mirror. 8 landmarks and goals 19-24 are in STORY.md.

**The finale** (planned). A confrontation of light, not a fight. The Soul of the Wick took the valley's light. It is "it", with no name and big pale eyes: a coil of living darkness around the cold great lamp. It drains the lanterns feeding the mirrors, Wicklings rise from the water, and standing near it chills the keeper. The ward pushes it back while beams strike the coil from more sides, until it lets go and slides into the water. The great lamp catches, and the fog lifts over the whole valley. The game answers **who** took the light, not **why**. Afterwards the valley stays open as a sandbox.

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
| Carry-limit and hand-lamp upgrades | built: 3 satchels and 3 lamp glasses |
| Wickling variety by region; more far from the hut | planned (M5), not built |
| People (5) with short spoken lines and errands; four new creatures, each answered by a lantern | approved 2026-11-27; planned for M5c-M5d, before the Still Lake (`PLAN_NPCS_ENEMIES.md`) |
| A Linux build | planned (M6) |

**OUT** (v1): death or game over; dialogue trees or cutscenes (short spoken lines from people are IN since 2026-11-27); more than one map, or random maps; day/night, rain, seasons; crafting beyond the lantern recipes; a Windows build.

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
- (People and four new creatures moved to v1 on 2026-11-27: see `PLAN_NPCS_ENEMIES.md`.)

---

## 7. Art and audio direction
- **Moody pixel art:** 16×16 tiles drawn at 2× (32 px on screen, one fog tile), nearest-neighbour filtering, hard edges. Tall things are 16×32.
- **14-colour palette** (`source/palette/lantern-keeper-14.gpl`): cool blues for the world; ambers only for light, fire and wood, so warmth means safety.
- **CC0 sources, recoloured to the palette:** Kenney Tiny Town and Tiny Dungeon, Puny Characters (the keeper), all listed in `assets/CREDITS.md`. The font is Ark Pixel 10px Proportional (OFL 1.1), used at 20, 30, 40 and 60 so it stays on its 10 px grid and sharp at 720p and 1080p.
- **The owner's own art** (Pixelorama) replaces placeholders over time. The Post Lamp is done; the other lanterns, resources and Ridge landmarks are placeholders, and Wicklings and embers are drawn by code (`docs/ART_CHECKLIST.md`).
- **Light and dark:** near-black darkness, a flickering 2D point light for every light, and soft-edged fog on its own layer. Not used so far: occluder shadows, a fog shader, mist particles.
- **Audio:** Kenney CC0 sound effects and a synthesized placeholder ambience; recorded night ambience is still to come. No music yet: it should be quiet and grow fuller as more of the valley is lit. No jump scares.

---

## 8. WayLamps (PROTOTYPE, owner playtest pending)

> **Built and merged into `main` on 2026-11-27** after the owner's playtest (with changes: WayLamps take fuel directly). "WayLamp" is the owner's name. Placeholder numbers in `tuning.gd`: `waylamp_fuel_need` 15, `waylamp_kindle_sec` 15, `waylamp_swarm` 4, `waylamp_sap_per_wick` 1.5 (seconds undone per second, per Wickling), `waylamp_radius` 420, `waylamp_clear_radius` 160 (no building closer), `dying_frac` 0.25, `wick_repel_speed` 160. If the playtest passes, this changes upkeep (3.1, 3.4) and the Wickling rules (3.6, 3.7). Story text (draft): STORY.md §11.

**Why.** As built, lighting all regions would take ~40-50 lanterns, each refuelled every ~3 minutes: a refuel every ~4 s. And neglect had no consequence.

**One WayLamp per region**, left by the old keepers:
- **The Hollow:** in the north-east, on the way east to the marsh (the loop, 2026-11-27; before that at the north end, below the climb, and first too close to the hut).
- **The Reedmarsh:** on the pumphouse island.
- **The Windward Ridge:** by the signal station, toward the old steps (the loop moved it 10 tiles east).
- **Lit WayLamps are fast travel** (2026-11-27, branch `proto/kl-loop`; see §9 "The loop").
- **The Still Lake:** the great lamp is the last one.

**Kindling one**
1. **Walk up to it.** No lantern has to reach it (owner, 2026-11-27: "it should just take fuel and be lit").
2. **Feed it** about 15 carried fuel.
3. **Hold it** for about 15 s while a swarm of bold Wicklings tries to sap it. The ward drives them off. It never fails: each Wickling sitting on it only pushes the kindling back.

**A held region**
- Its lanterns stop burning fuel and are refilled.
- No Wicklings spawn there.
- Lanterns built there later are held too.
- Wicklings inside fade away, with no drops.
- Its light clears fog only in its own region, so it never lights the next region for free.
- So upkeep only exists at the **frontier** region, the one you are opening up.

**Wickling rules in the prototype**
- Healthy light repels Wicklings back into the dark.
- Only a lantern below a quarter of its tank is **dying**, and only a dying lantern can be drained or snuffed.
- A dying lantern inside a healthy lantern's light is protected.
- Mirrors inside healthy light are safe; relay mirrors in the dark can still be smothered.

**Story tie.** The great lamp's plate reads IT WAS NEVER MEANT TO BE KEPT BY ONE. The keepers kept the WayLamps; the WayLamps kept the lamps. When the keepers left, one keeper could not hold them all.

**Notes for the playtest**
- "Dying" starts at 25%, where the HUD already marks lanterns as low.
- The ward is not free during the hold: the lamp doesn't refill while you ward (0.45 charge per second, about 2 s from a full lamp).
- Questions: Does holding a region feel like a reward? Is the hold tense but fair? Does frontier-only upkeep keep lanterns meaningful?

---

## 9. Keeper's Light (PROTOTYPE, branch `proto/keepers-light`)

> The owner chose this direction on 2026-11-27: the game becomes an action RPG (DECISIONS). The full design draft is being written for owner markup. This section lists only what is **built on the prototype branch**. Numbers are placeholders in `tuning.gd` (`kl_*`).

**The combat kit** (`scripts/player/combat.gd`). Lamp charge is the stamina for all three, and it is still how far your hand lamp lights.
- **Beam** (hold left click / RT; aim with the mouse or the right stick, else where you face): 240 px long and 24 px wide. It burns 6 hp per second, so a Wickling goes in half a second. It costs 0.3 charge per second (about 3 s from a full lamp), and you walk at 70% while it's on. It lights the fog along its path like a mirror beam. It is the only thing, with mirror beams, that wears down a shell.
- **Burst** (tap F / RB): a 120 px flash that does 2 damage and throws things back about 140 px. 3 s cooldown, 0.2 charge. It replaces the hold-to-ward glow.
- **Dash** (tap Shift / LT): 110 px in 0.16 s, 0.9 s cooldown, 0.08 charge. Nothing can chill you mid-dash.
- Carried fuel never tops the lamp up mid-fight, only after you've stopped using it. Building moved to Space / X only (left click is the beam).

**Shelled elites.** Every 4th Wickling out of the fog is an elite: bigger, slower (48 px/s), 9 hp behind a 4-point shell, and its touch chills 1.6x harder. Bursts and lantern cores glance off the shell; only a beam wears it down.

### Hollow prototype (branch `proto/kl-hollow`, implemented 2026-11-27; playtest pending)

Slices 1-6 of `docs/PLAN_KEEPERS_LIGHT.md` are now present: 24 fixed packs (since the 4x Hollow; Spitwicks in the middle and north), twelve core-burned nests, the shelled Clinker guarding the Post Lamp find, wick and level-up choices, and the two-phase Ashbrood on the Hollow WayLamp. Fixed enemies and pack clears persist; fainting drops unspent wick where the keeper fell and resets pack clears. The build uses a separate save path. Since the loop (branch `proto/kl-loop`), the passage east is open in normal play; the marsh and the Ridge have no Keeper's Light foes yet. F1 exposes prototype combat, enemy, progression and boss tuning. The small Leads slice, third boss phase, and polish beyond placeholder shapes/effects remain out of scope. This is implementation status, not a passed playtest; see `docs/PLAYTEST.md` for the handoff and gate questions.

**Feedback (2026-11-27):** foes flash when hit; the burst, kills and big hits shake the screen (`kl_shake_px`); a short freeze on a kill. Hurt foes, and big ones nearby, show a name and a health bar, with the shell as a pale bar above it. The Ashbrood has a boss bar across the bottom of the screen. The "Quick fill" upgrade is replaced by "Kindled kills" (each kill gives back 10% lamp charge).

**Lanterns and the dark (2026-11-27):** about half the Wicklings are timid and stay out of healthy light. The brave ones walk in, start burning after 2.5 s (1.5 hp/s) and run. Elites, the Clinker and the Ashbrood ignore lanterns completely, cores included. Numbers: `kl_timid_share`, `kl_light_tolerance`, `kl_light_burn_dps`. The boss bar shows the phase and a hint for what it wants.

**No endless spawns (2026-11-27):** the old trickle of Wicklings out of the fog is off (`kl_ambient_spawns`). Enemies wait in fixed packs (tougher further north), nests and the WayLamp fight. Cleared packs stay cleared.

**A calm start (2026-11-27):** nothing hostile within 16 tiles of the hut. The two nearest packs moved to the southern corners; the Clinker's post is now 17 tiles north (its 330 px charge range no longer reaches the hut); nests and the other packs moved out to match.

**4x Hollow (2026-11-27):** with the bigger map, the Hollow holds 24 packs and 12 nests, all at least 20 tiles from the hut. Six packs in the north, around the WayLamp, have shelled elites (4-5 Wicklings, most with a Spitwick); the middle ten have Spitwicks or 4 Wicklings; the eight in the south and west are 3 Wicklings each. Three nests sit on the road north, the rest on the flanks and in the south. The Clinker's post is under 10 tiles from the WayLamp and about 40 from the hut. Three old caches (scrap, fuel) lie at dead ends. One red lure still marks the post.

#### Leveling balance pass (2026-11-27, branch `proto/kl-balance`)

**Targets** (owner asked for a balance pass after the 4x map): about 6-8 levels across a full Hollow clear; level 2 after the first pack or two; level 3 before the Clinker; one or two levels from the Ashbrood fight (the guardian and kindling its WayLamp); no level-up wasted, so every offer shows three real cards. `tools/tests/test_leveling.tscn` measures this on the placed map. It walks two full clears: a beeline that follows the pointer to the Clinker, and an explorer who takes the nearest pack first.

**Measured wick in the Hollow** (24 packs of 90 foes, 12 nests, the Clinker, the Ashbrood, kindling):

| Source | Before | After |
|---|---|---|
| Packs: 75 Wicklings, 9 Spitwicks, 6 shelled | 99 | 111 |
| 12 nests | 96 | 60 |
| Clinker | 15 | 20 |
| Ashbrood | 40 | 50 |
| Kindling the WayLamp | 30 | 30 |
| **Fixed total** | **280** | **271** |
| Hatched and called Wicklings | about 48 more, and no limit | 0 |

**Wick per kill** (`kl_*_wick`; set by danger): Wickling 1 (unchanged); Spitwick 2 (unchanged); shelled Wickling 3 (was 1: it fell back to Foe's default; PLAN §5.1 says 3); nest 5 (was 8: twelve nests were a third of all wick, for 6 s of lantern core); Clinker 20 (was 15); Ashbrood 50 (was 40); kindling 30 (`kl_wick_kindle`, was hard-coded in `Progress.settle`). ~~Wicklings hatched by a nest, called by the Ashbrood or drawn to a kindling WayLamp pay `kl_wick_summoned` = 0, and a pack member pays its wick once.~~ Replaced by the level gap (below).

**The curve.** Before: flat steps, 15 wick to level 2 and 10 more each level (15, 25, 35, 45...). After: wick from level L to L+1 is `round(kl_wick_base * L ^ kl_wick_exp)` with base 6 and exponent 1.25 (`Progress.wick_for_level`): 6, 14, 24, 34, 45, 56, 68, 81, 94... (total to reach L8: 247). Capped at `kl_level_cap` = 12 (PLAN §5.1); at the cap wick stops and the HUD says "max".

| | Old curve, old values | New |
|---|---|---|
| After the 2nd pack | still level 1 | level 2 (beeline and explorer) |
| Before the Clinker | level 2 | level 3 (beeline), 4 (explorer) |
| Before the Ashbrood | level 7 | level 7 |
| End of the Hollow | level 7 (8 with hatches and adds; more by farming) | level 8 (7 level-ups) |

Why: the old flat 15 made the first level slow (5 small packs), then nests and the north came in a rush. Hatchlings and re-fought packs could push past the 8 upgrades. The rising curve gives a level after the first fight and spaces the later ones out. The total is fixed, so the upgrades can't run out.

**Upgrades: twelve.** Four more from PLAN §5.2, one per line, so every Hollow offer shows three cards and five are left for the Reedmarsh: *Hot core* (lantern cores burn 2x, `kl_hot_core_mult`), *Steady hand* (walk 90% while beaming, `kl_steady_hand_walk`), *Lee* (a Wickling's touch chills 25% less, `kl_lee_mult`), *Spill* (burst cooldown 2.2 s, and each foe hit gives back 0.03 charge, `kl_spill_cd`, `kl_spill_charge`). Four hard-coded upgrade numbers moved to tuning.gd: `kl_long_throw_len` 310, `kl_deep_tank_mult` 0.8, `kl_heavy_flare_knock_mult` 1.5, `kl_heavy_flare_stun` 0.6. Ranks (II, III) were not needed.

**Time to kill** (beam 6 hp/s, 0.3 charge/s, refill 0.5/s in lantern light). "Stacked" means Tight focus, Lingering burn and Deep tank, the three damage upgrades that stack on one target. Shown as seconds of beam, then seconds with refills:

| Foe | Fresh | Stacked |
|---|---|---|
| Wickling (3 hp) | 0.5 s / 0.8 s | 0.4 s / 0.6 s |
| Shelled Wickling (9 + 4) | 2.2 s / 3.5 s | 1.5 s / 2.2 s |
| Clinker (24 + 12) | 6.0 s / 9.6 s | 4.2 s / 6.1 s |
| Ashbrood, a phase (40 + 12) | 8.7 s / 13.9 s | 6.2 s / 9.1 s |

Even fully stacked, the Ashbrood still takes about two thirds of a fresh keeper's damage time (the test checks at least 60%). Dodging, puffs and dives come on top of that. So no per-level enemy scaling was added. Packs melt faster as you level, which is the ARPG reward.

**Showing progress.** The HUD row reads "Lv 3", then a 14 px wick bar, then "12/24" (Ark Pixel 20). A level-up plays the `unlock` chime (`Sfx.play_ui`, which plays through the pause). The card screen flashes in with "Level N" over "Trim the wick", and the wick row glows gold for about a second after you choose. Every number is in tuning.gd, and the curve, cap and wick values are in F1.

#### Level-gap wick (2026-11-27, branch `proto/kl-xpgap`)

**Why** (owner): "Idk about give no wick. Other games solve this by the XP they give not being proportionate to levels... eventually it doesn't pay to do so and it's too grindy." So, as in Diablo or PoE, every foe has a level, and what a kill pays depends on the gap between the keeper's level and the foe's. Hatched, called and re-fought foes pay like any other foe of their level; the gap is what stops farming. `kl_wick_summoned` and the "a pack member pays once" rule are gone. Cleared packs and "cleared stays cleared" are unchanged.

**Formula** (`Progress.kill_wick`, `Progress.wick_gap_mult`): wick = base × (1 + `kl_xp_level_growth` × (foe level − 1)) × gap factor, where gap = keeper level − foe level.

| Gap | Factor |
|---|---|
| foe above the keeper | 1 + `kl_xp_bonus` (0.1) per level, at most +`kl_xp_bonus_max` (0.3) |
| 0 to `kl_xp_band` (1) | 1 |
| 2 / 3 / 4 | × `kl_xp_falloff` (0.25) per level past the band: 1/4, 1/16, 1/64 |
| `kl_xp_zero_gap` (5) or more | 0 |

`kl_xp_level_growth` = 0.25: a Lv 5 Wickling is worth 2 wick, a Lv 6 one 2.25. Fractions carry over (`Progress.wick_frac`, saved). All of these are in tuning.gd and F1.

**Foe levels** (data: the fifth column of `HOLLOW_PACKS`, the second of `HOLLOW_NESTS` in `scripts/main/main.gd`; the rest in tuning.gd). Lv 1 on the hut row and south of it (12 packs, 5 nests), 2-4 through the middle, 5-6 at the elite packs and nests by the WayLamp. The Clinker is Lv 4 (`kl_clinker_level`), the Ashbrood Lv 7 (`kl_ashbrood_level`), and its phase-1 adds Lv 5 (`kl_ashbrood_add_level`, two below it, so standing in phase 1 isn't a farm). Hatchlings take their nest's level. Wicklings drawn to a guardian-less WayLamp are Lv 6 (`kl_waylamp_swarm_level`). Later regions start higher.

**The Hollow's last level comes on the Ashbrood kill** (owner): Ashbrood base 32 (was 50; ×2.5 at Lv 7 = 80), kindling 10 (was 30). Base wick per kill is otherwise unchanged (Wickling 1, Spitwick 2, shelled 3, nest 5, Clinker 20).

**Measured** (`test_leveling.tscn`, now counting one hatch of 3 per nest and 12 Ashbrood adds):

| | Beeline | Explorer |
|---|---|---|
| Level 2 | after pack 1 | after pack 2 |
| Before the Clinker | L4 | L5 |
| Into the Ashbrood | L7 | L7 |
| After its adds | L7 (30/68) | L7 (31/68) |
| The kill | L8 | L8 |
| After kindling | L8 | L8 |

Both routes backtrack through the low south late, which now pays almost nothing; that is the point. A farmer who camps the hut row and the south (a Lv 1 nest's 18 hatchlings a minute, and every south pack fought again after a faint every 5 minutes) reaches L4 in 4 minutes, then L5 only at 25 minutes, and earns about 1 wick a minute in the last 10 (18 at the start). The beeline reaches L8 in roughly 12 minutes on the test's walk-and-fight estimate. Why band 1 and ×0.25, not the first suggestion (band 2, ×0.5): measured on the same map, band 2 with ×0.5 lets the farmer reach L5 in 5 minutes and L6 in 10, and band 2 with ×0.25 reaches L5 in 7. Both also over-pay the forward run, which then reaches L9 by the end of the Hollow.

**What you see:** name bars read "Wickling Lv 2", dimmed when the foe is too low to pay full wick. A kill floats "+2 wick" in gold, or in dim grey when the gap cut it.

#### The first 10 minutes (2026-11-27, branch `proto/kl-onboard`)

**Why:** a newcomer met the find last (the crook and the Clinker sat 41 tiles out, 8 short of the WayLamp), a nest they could not hurt on the road, about 17 foes before the find, and no haven between the hut and the fights. `docs/PLAN_ONBOARDING.md` has the diagnosis; the owner's answers in its §8 chose **Option B**. This replaces the "Clinker guards the Post Lamp find" and "three nests on the road north" lines above.

**The main route** (tile offsets from the hut's start tile `(48, 136)`, +x east, -y north; distances in tiles, as placed after snapping; `test_prototype_onboarding.tscn` prints and checks them):

| Order | What | Offset | From the hut | Wakes at |
|---|---|---|---|---|
| 1 | The lone first Wickling (pack 20: 1 Wickling, Lv 1) | (-1, -10) | 10.0 | 5 tiles |
| 2 | **A second cold old lantern** (the north path's lamp, a haven; goal `relight_waypost`) | (+2, -12) | 12.2 | - |
| 3 | The first pack (pack 23: 3 Wicklings, Lv 1) | (+5, -17) | 17.7 | 6 tiles |
| 4 | **Oswin's crook** (the Post Lamp find) with its **small guard** (one shelled Wickling, Lv 2) and a **6-scrap cache** | (-1, -19) | 19.0 | 4 tiles (`kl_post_guard_wake_radius` 128 px) |
| 5 | **Nest A** (nest 4, Lv 2): the first lock the Post Lamp opens; goal `burn_nest` | (+2, -30) | 30.1 | 10 tiles (11.4 past the crook) |
| 6 | Pack 2 (4: one Spitwick, one shelled, Lv 4): the first ranged foe and the first elite in a pack | (+13, -32) | 34.5 | 10 tiles |
| 7 | **The Clinker**, now a mid-boss (Lv 4), with its sleep and leash as before | (+7, -40) | 40.6 | 7 tiles (9.4 from the WayLamp) |
| 8 | The WayLamp and the Ashbrood | (+15, -45) | 47.4 | - |

**Rules the test holds:** nothing wakes at the hut, its lantern, the woodpile, the scrap or the ledger, even a tile off. Only the lone Wickling is within 16 tiles of the hut (the owner allowed it closer). From the hut to the crook, at most 2 packs and 4 Wicklings, no Spitwick, no elite, no nest, no Clinker. From the crook to the WayLamp, at most 2 packs and exactly one nest, nest A. The whole route wakes 3 of the 24 packs and 1 of the 12 nests; the rest is optional. No nest is within 28 tiles of the hut, and no Spitwick or elite pack within 25. Nothing but the warm-ups can wake at the north path's lamp or the crook, nothing else wakes at nest A, and nest A is past its hatch range from the crook. The route is open ground.

**What moved:** the crook from (+10, -40) to (-1, -19). The Clinker from the crook to (+7, -40) (it was 7.1 tiles from the snapped WayLamp, inside its own 7-tile wake). Pack 20 (was 3 Wicklings at (0, +24)) and pack 23 (was 3 at (-20, -2)) became the route's first two fights, each with its own wake range (the sixth column of `HOLLOW_PACKS`; `EnemyPack.wake_radius`). Pack 2 (was 5/1/1, Lv 6 at (+12, -30)) is now 4/1/1, Lv 4 at (+13, -32). Off the route, as optional side content: pack 5 (was on the route at (-2, -32)) to (-14, -32), now 4/1/0 Lv 4; pack 8 (was beside the old crook at (0, -24)) to (+24, -16); pack 9 to (+18, -14), now 4 Wicklings Lv 2 (no Spitwick near the start); pack 10 now 4 Wicklings; pack 1 to (+26, -34). Nest 4 (was (+8, -24)) became nest A; nest 3 to (+28, -38), out of the Ashbrood fight; nest 5 (was 23 tiles from the hut) to (-26, -30). The south is unchanged (owner: optional content, maybe an NPC side quest later). With the guard, the Hollow has 25 packs: the 24 in the table and the guard.

**Guidance:** goals `gather_fuel`, `relight_first`, `read_ledger`, then `relight_waypost` (pointer: the north path's lamp), `build_post` ("Take back the lamp from Oswin's crook"), `burn_nest` (pointer: nest A, then the nearest nest left), `kindle_hollow`. The ledger's last line names the crook, then the WayLamp. Six new tips (`haven`, `burst`, `shell`, `dash`, `nest`, `build_here`) and a new `wickling_close`; `[beam]`, `[burst]`, `[dash]`, `[build]` and `[aim]` in a tip become the button for the device in use (`Story.tip_text`). The north path's lamp gets its cold ring only after the ledger, so the hut shows one cold lamp at a time. Texts: STORY.md §5, §6, §8.

**Leveling** (`test_leveling.tscn`; the beeline now follows this route and burns the nests it passes; the explorer's nests open at the guard, not the Clinker). Targets changed with a reason: "level 2 after the first pack or two" became **level 2 with the first three fights, at the find** (the lone Wickling and the pack of 3 give 4 wick of the 6; the guard brings it). "Level 3 before the Clinker", "level 7 into the Ashbrood", "L8 on its kill" and "6-8 level-ups" are unchanged and pass.

| | Beeline | Explorer |
|---|---|---|
| Level 2 | at the crook's guard (3rd fight) | at pack 23 (3rd fight, after the guard) |
| Level 3 | pack 2, before the Clinker | pack 2, before the Clinker |
| Level 4 | the Clinker | the Clinker |
| Into the Ashbrood | L7 | L7 |
| The kill | L8 | L8 |

The Hollow's fixed wick changed little (25 packs of 88 foes). The farming check still stalls (L5 only at 25 minutes); the forward run reaches L8 in about 13 minutes on the test's estimate (was 12).

**Not done:** no balance change to the guard or the Clinker (the Clinker now meets an L3 keeper, as before). Pack and nest lures still look alike above the fog (plan §9). Timings are estimates, not a playtest.

The loop (below) moved rows 6-8 of the table: pack 2, the Clinker and the WayLamp now sit east of nest A.

#### The loop and WayLamp fast travel (2026-11-27, branch `proto/kl-loop`)

**Why:** the owner chose one clockwise loop with no backtracking, and lit WayLamps as fast travel (DECISIONS, "route: one loop"). Before, you went north to the WayLamp, walked back south and east to the marsh, then back west through the Hollow to climb to the Ridge's west end, and walked its whole length east.

**The route:** the hut, the onboarding road north (unchanged: the lone Wickling, the north path's lamp, the pack of 3, the crook and its guard, nest A), then east: pack 2, the Clinker, the Hollow's WayLamp and the Ashbrood, out past the carved stone into the passage. Through the Reedmarsh eastward as before (frames, chalk, pumphouse, its WayLamp on the south-east island). Up the **marsh climb** from the marsh's north-west corner to the Ridge's east end. Across the Ridge one way, toward the north-east: the glazier, the lens, the coat, the signal station, its WayLamp, the old steps. The Lakeshore (still empty rock) begins about 8 tiles past the steps.

**What moved** (tiles; `scripts/main/main.gd`; snapped positions; `test_prototype_loop.tscn` prints them):

| What | Was | Now |
|---|---|---|
| The Hollow's WayLamp (`HOLLOW_WAYLAMP`) | (63, 91), the north end | **(78, 124)**: hut offset (+30, -12), 32.3 tiles; 8.2 tiles above the carved stone |
| The Clinker (`CLINKER_TILE`) | (55, 96) | **(70, 119)**: 9.4 tiles before the WayLamp (more than its 7-tile wake plus a tile, out of the Ashbrood fight) |
| Pack 2 (the route's Spitwick and elite, Lv 4) | (61, 104) | **(60, 113)**: 12.2 tiles past nest A, 11.7 before the Clinker |
| Pack 4 (Lv 5, elite) | (76, 112) | (66, 99), the north-east corner, above the road |
| Pack 8 (Lv 4) | (72, 120) | (36, 112), the west middle |
| Pack 9 (Lv 2) | (66, 122) | (24, 128), the west middle |
| Pack 11 (Lv 2) | (82, 126) | (52, 93), the old climb's foot |
| Pack 13 (Lv 1) | (68, 132) | (66, 140), the quiet south-east |
| Pack 15 (Lv 1) | (84, 144) | (66, 146), the quiet south-east |
| Nest 7 (Lv 3) | (79, 119) | (60, 91), the old climb's foot |
| Nest 9 (Lv 1) | (84, 136), the passage mouth | (80, 150), the south |
| The cairn (`climb_cairn`) | (48, 94), the old climb's foot | **(127, 92)**, the marsh climb's foot |
| The glazier (Hooded Lamp) | (28, 30), the far west | **(99, 51)**, 5.1 tiles from the marsh climb's top |
| The lens | (60, 18) | **(103, 46)**, 10.4 tiles from the top |
| The coat | (84, 44) | **(108, 40)** |
| The signal station | (116, 26) | (116, 26), unchanged |
| The Ridge's WayLamp | (110, 30) | **(120, 30)**, 5.7 tiles from the steps |
| The old steps | (124, 34) | (124, 34), unchanged |

Levels and counts didn't change (25 packs with the guard, 12 nests). Packs 1, 3, 5, 6, 7 and nest 3 (the north-west and north-east elites) stay where they were; the far west of the Ridge (the satchel, a lamp glass, a glass cache) is optional.

**The marsh climb:** about 8 tiles wide, from (130, 99) at the marsh's north-west corner by way of (124, 86) and (112, 72) to the Ridge's south rim at (100, 56) (`MARSH_CLIMB`, `RIDGE_ENTRY`). Ridge ground above y 76, marsh ground below, like the old climb. It stays at x 131 or less, west of the Lakeshore's space. **Gate: none. It is walkable as soon as you reach the marsh** (the brief allowed either; chosen because it can never lock you out and needs no new art). The goal order (`climb_north` comes after `kindle_marsh`) and the cairn's line ("Light the marsh before you climb") ask you to light the marsh first. The Ridge outcrops keep clear of its top.

**The old climb, a later shortcut:** fallen stones (two rows of rock, drawn as Ridge stone, at y 84-85; `ClimbStones`, `scripts/world/climb_stones.gd`) close it. They have their own collision body. Coming down from the Ridge (within 3 tiles, from the north side) the keeper pushes them down: they become ground, the body goes, and `Progress.cleared["climb_stones"]` keeps it open in the save. From the Hollow side nothing happens. The Hollow-only prototype's walls (the passage at x 94-95 and the climb at y 84-85) are gone.

**WayLamp fast travel** (`scripts/ui/travel_menu.gd`, `TravelMenu` in the main scene):
- Interact with a **lit** WayLamp. Its prompt says "Travel" (and "WayLamp: this region is held"); a cold one still takes fuel as before.
- A small code-built `UiStyle` list opens: every lit WayLamp by name, in region order. The one you stand at is greyed "(you are here)" and can't be focused. "Stay" closes it. With only one lamp lit, it says to light another. The world pauses while it is open.
- **Gamepad:** focus starts on the first place to go; the D-pad moves it; A travels; B or Start closes. **Keyboard:** arrows, E or Enter, Q or Escape. **Mouse:** click. Old buttons are removed from the list before the new ones take focus (the level-up bug); closing releases focus and blocks the closing press from reaching the game. Ark Pixel at 40 (title), 30 (buttons) and 20 (notes).
- Picking one fades to black (0.25 s), puts the keeper just below that WayLamp, in reach of it, and fades back (0.35 s).
- **Blocked** (the list won't open, a sound plays, and the WayLamp's prompt says why): while a foe hunts the keeper within 12 tiles (`travel_hunt_radius` 384 px: a chasing Wickling, any Spitwick, an awake Clinker), while any WayLamp kindles, and while a guardian (the Ashbrood) is in play.
- **Save:** which WayLamps are lit was already saved (`Progress.settled`). The only new entry is the stones' `cleared` key, so saves stay version 4 and older saves load (the stones are simply still down).

**Tests:** `test_prototype_loop.tscn` (81 checks) covers the Hollow stretch, the marsh climb and the stones, the one-way Ridge, goal and pointer order, fast travel (only lit WayLamps listed; travel moves the keeper; blocked while hunted, during kindling and during a guardian fight; pad mapping, focus, B, Escape, mouse; clean close; font sizes) and save round trips (a reloaded world, and an older save without the stones key). Changed with a reason: `test_prototype_onboarding` measures "the Clinker comes after nest A" from the crook instead of the hut, since the road turns east after nest A. `test_prototype_hollow`'s toughness check keeps "the third of the packs nearest the WayLamp outweighs the farthest third" (44 vs 32), and its "no elites in the farthest third" became "no elites south of the crook", because the WayLamp now sits beside the quiet south-east. `test_leveling`'s beeline now stops at nest A (a goal) before the Clinker.

**Leveling after the loop** (same targets, both pass): beeline and explorer L2 at the find, L3 at pack 2, L4 on the Clinker, **L7 into the Ashbrood, L8 on its kill**; the forward run takes about 13 minutes on the test's estimate (unchanged). Farming still stalls (L5 only at 25 minutes).

**Performance:** `tools/bench/bench.tscn` (headless, 30 lanterns, 20 foes, 400 frames): game logic averages 3.03-3.10 ms over three runs (worst frame about 6.0-6.4 ms), against 2.96-3.06 ms on `proto/kl-hollow` f126af7 on the same machine: no change beyond run-to-run noise, within the 4 ms budget. The travel menu only works out its block reason when you are next to a lit WayLamp; the stones check one distance a frame until they open.
