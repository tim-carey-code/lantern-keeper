# Playtests

## PROTOTYPE build (branch `proto/kl-hollow`): Keeper's Light in the Hollow

Open the `proto/kl-hollow` worktree in Godot and press F5. This build uses a separate prototype save, so your regular save remains untouched. Automated checks use the Dummy audio driver; normal play keeps audio enabled.

The north/east exits are closed. Start by relighting the hut lantern. Find the red pulse north of the hut, fight the Clinker for the Post Lamp, and burn out the nests with a built lantern's bright core. The blue glints mark two guarded upgrades. Feed the Hollow WayLamp 15 fuel to wake the Ashbrood; break its shell with the beam, then learn its second phase. The level-up screen pauses play and offers three of eight upgrades.

**Controls:** beam: hold left click / RT; burst: F / RB; dash: Shift / LT. Move: WASD / left stick. Interact/read/refuel: E / A. Build: Space / X. F1 opens the tuning panel; Esc / Start pauses.

**Bigger regions (2026-11-27, branch `proto/kl-big`):** every region is now 4x the area (224 × 200 tiles). The Hollow holds 24 packs and 12 nests instead of 6 and 3, plus three old caches at dead ends. A save from the smaller map starts fresh. Extra questions: does the Hollow now feel big enough, or too big to walk? Is it too full of packs and nests, or too empty anywhere? Does it still run smoothly with many lanterns out?

**Prototype limits:** creatures and effects are code-drawn placeholders. Leads, journal changes, the third boss phase, regions beyond the Hollow, and full animation/audio polish are not included. Values are prototypes and can be adjusted in F1.

Questions (decision gate):
1. Did aiming and firing the beam feel good on mouse and pad? What felt off: reach, speed, sound or hit feedback?
2. Did you dash on purpose to dodge? When hit, did it feel fair?
3. Did you work out how shells and nests are damaged? Did the Clinker take too long?
4. Did finding the Post Lamp change how you fought? Did it feel earned?
5. Did the level-up choices feel distinct and useful?
6. Was the Ashbrood tense but fair? Did you understand each phase?
7. Did the lures pull you along? Did the Hollow still feel empty anywhere?
8. Did you still build lamps, and why?

### Results: 2026-11-27, owner (gamepad only so far)
1. Aiming and firing the beam feels good. **Hit feedback felt off** → added a hit flash, screen shake on the burst, kills and big hits (a short freeze on a kill was already in).
2. Dashed on purpose to dodge; hits felt fair.
3. Didn't know what the Clinker or the Ashbrood were → **names and health bars over foes, a pale shell bar above the red one, and a boss bar for the Ashbrood**.
4. The Post Lamp felt earned and changed how he fought.
5. Choices mostly distinct; **"Quick fill" was useless** (the lamp already refills fast) → replaced by **"Kindled kills"** (each kill gives back 10% charge).
6. Couldn't tell the Ashbrood's phases apart or whether it was taking damage → the boss bar shows phase, health, shell and a one-line hint for each phase.
7. The lures pulled him along.
8. Built lamps because monsters are afraid of them, which may be too strong → now about half the Wicklings are timid and stay out; the brave ones walk in, burn after 2.5 s and run. Elites, the Clinker and the Ashbrood ignore lanterns completely.

---

## PROTOTYPE build (branch `proto/waylamps`): WayLamps hold a region

The project folder is on this branch. Open it in Godot and press F5 (or `godot --path ~/Projects/lantern-keeper`).
Your save still loads: the WayLamps start cold, and the first unfinished goal points you back to the Hollow.

**WayLamps.** Each region has one old WayLamp on a stone plinth: the Hollow's is by the carved stone, the Reedmarsh's is on the pumphouse island, and the Ridge's is by the signal station.
- **Walk up to it** and feed it. No lantern has to reach it any more (changed after your first try). You can't build right next to it.
- **Feed it** 15 fuel (E / A). You can do it over several trips; what you pour in stays.
- **It kindles** for 15 s. A swarm of bold Wicklings (reddish rim) comes for it and ignores the push of your lanterns. Each one sitting on it undoes the kindling, so ward them off (F / RB / RT). It never fails, it only stalls.
- **Lit, it holds the region.** Every lantern there is refilled and stops burning down (a gold diamond replaces its fuel bar), no Wicklings spawn there, and any inside fade away. Its light clears only its own region's fog.

**Light rules.** A healthy lantern pushes Wicklings back into the dark. Only a **dying** lantern can be drained: under a quarter of its tank (the tick on the fuel bar), shown with a red bar and a flicker, and not covered by any healthy light. Mirrors out in the dark can still be smothered.

Questions (decision gate: keep, change, or drop):
1. Did kindling a WayLamp feel like a moment worth working for? Too easy, too hard?
2. Once the Hollow was held, did upkeep feel right: less of a chore, with real tending only at the frontier?
3. Was it clear which lanterns were in danger (dying) and which were safe?
4. Did Wicklings being pushed out of the light make the lanterns feel safer, or make Wicklings pointless?
5. Do 15 fuel and 15 s feel right?
6. Does a held region feel good to come back to, or too empty?

---

## PROTOTYPE build (branch `proto/wicklings`): calm conflict

**Wicklings** drift out of the deep fog (first one after ~40 s, then every ~16 s, max 5).
- They creep to the **rim** of a lantern's light and drain its fuel (a dark tendril shows which lantern). The bright **core** of a lantern burns them, so clustered lanterns are safer.
- In the dark they come for **you**. Their touch drains your **Warmth** (HUD). In lantern light Warmth refills.
- **Warding glow: hold F / RB / RT.** Your hand lamp swells into a bright circle that burns and pushes back every Wickling inside it (about 0.7 s each, even right on top of you). It runs on **hand-lamp charge, not fuel**: a full lamp gives ~4 s; recharge it in lantern light. Burned Wicklings drop an **ember** worth 1 fuel.
- Out of Warmth you **faint**: you wake beside the nearest lit lantern and drop half of what you carried where you fell (go back and pick it up). No game over, nothing you built is lost.
- Tuning panel (F1) has spawn rate, speed, drain, warmth loss and flare radius.

Questions (decision gate: keep, change, or drop):
1. Did the game feel more interesting with Wicklings, or more stressful?
2. Did the light still feel safe and calm?
3. Did the flare feel good to use? Too strong, too weak?
4. Did fainting feel fair?
5. Should they stay in v1?

### Results: 2026-11-26, owner (video reviewed)
1. More interesting; **not much added pressure**.
2. Light still felt **safe and calm**.
3. The flare "wasn't really a flare" and **one-shot everything close enough**: too strong. Wanted a **beam** that drains their health.
4. Fainting felt **fair**.
5. **Keep them in v1.**
From the video: the mouse cursor sat in the middle of the screen; Wicklings were hard to spot in the dark; the editor debugger showed 13 messages (not yet identified).
Beam playtest (owner): too slow to kill, used up all the fuel meant for lanterns, missed Wicklings right on top of you. Replaced by the warding glow (see DECISIONS).
Earlier changes: lamp beam replaced the flare; more Wicklings, sooner; brighter eyes, a cold rim and a health ring on hurt Wicklings; cursor hides when not using the mouse.

---

## Current build: M3 (The Reedmarsh)

The valley is bigger. East of the Hollow, through a rocky passage, is **The Reedmarsh**.

- Marsh ground is soft: you can wade through it (a bit slower) but lanterns only stand on **boardwalks** and **islands**. Fog creeps back faster here. Lots of **peat** (fuel) along the boardwalks.
- **Landmarks** glow with a small amber dot until read. Press **E / A** to look closer. There are five: two in the Hollow, three in the marsh.
- The **pumphouse** on the far eastern island unlocks the **Reservoir Lamp** (8 scrap): big tank, wide dim light, slowly refuels other lanterns in its light (even cold ones).
- **Tab / Y** opens the lantern list; up/down picks a lantern, any action button closes it.
- **Wind gusts** every 30-55 s from one direction, announced 5 s ahead. During a gust, lanterns with no rock 1-2 tiles upwind burn twice as fast and shrink. Rock upwind shelters them.
- **M / LB** opens the map: bright = lit now, dim = remembered, black = never seen.
- Region names fade in the first time you light them. Placeholder ambient sound: a low hush, reed hiss in the marsh, a rush during gusts.

Questions (roadmap "done when" in brackets):
1. Did you find your way into the Reedmarsh without help? [required]
2. Did you find the pumphouse and unlock the Reservoir Lamp? [required]
3. Did you use the Reservoir Lamp on purpose to cut down upkeep? [required]
4. Did the boardwalk-only rule make placement more interesting, or just annoying?
5. Did gusts feel like weather you plan around, or like random punishment?
6. Did the landmark texts make you curious about the valley?
7. Sound: pleasant, too loud, or irritating? (It is placeholder.)

### M3 results: 2026-11-26, owner, build 944201d/45c2853
1. Found the way into the Reedmarsh without help: **yes**.
2. Found the pumphouse and unlocked the Reservoir Lamp: **yes**.
3. Used the Reservoir Lamp on purpose: **yes, it cut back on refuelling**.
4. Boardwalk-only placement: **more interesting**.
5. Gusts: **barely noticed them**.
6. Landmarks: **"kind of", not obvious what was a landmark**.
7. Sound: **OK for now, not great**.

Gate: **passed** (1-3). Also from screenshots: tuning panel overlapped the HUD and the lantern list was cut off (fixed in 45c2853); fullscreen requested (added, F11).

Follow-up fixes for 5 and 6:
- Gusts: wind streaks blow across the screen (faint while building, many during the gust), a centre-screen message on warning and gust, lantern flames lean downwind and the fuel bar flashes red on exposed lanterns.
- Landmarks: unread ones glow and have a pulsing amber marker; a centre-screen "Something catches the light: ..." message when the light first finds one.
- Sound: replaced with real sounds in M4.

Follow-up screenshots (owner): gust streaks + centre message + HUD line all visible; cold-lantern arrows and "Needs fuel: 3 cold" HUD line working; map readable.
Owner tuning notes: lanterns going cold was not mainly the gusts; gusts don't affect lanterns enough; lanterns burn a little too slow.
Changed: Post Lamp burn 0.33 -> 0.5 fuel/s (tank ~3.3 min), Reservoir burn 0.2 -> 0.3, gust burn x2 -> x3, gust light radius x0.85 -> x0.7, gust length 8 -> 10 s, Reservoir feed 0.5 -> 0.75 fuel/s (must out-pace the faster burn).
Polish list for M4: arrows for lanterns in the same direction stack on one spot (add a count or spread them); streaks also draw over never-seen black (consider only over seen ground); map should zoom to the explored area; region labels can sit on paths; seen-fog tile outlines read as a heavy grid.

---

## Previous build: M2 (gathering)

Start with nothing in The Hollow and grow a lit area that keeps itself going.

- Hold **E / A** next to a dead tree (resin = fuel) or a ruin (scrap) to gather. Resources only show on lit ground.
- **Space / X** builds a Post Lamp for 5 scrap. **E / A** on a lantern pours in carried fuel (1 carried fuel = 10 lantern fuel). **Q / B** picks a lantern up: half the scrap back, plus its fuel.
- Your hand lamp dims in the dark and burns a carried fuel when low. It never goes out. It refills for free in lantern light.
- The woodpile by the hut always regrows, so you can never get stuck.
- Fog you have seen stays as a dim blue haze with tile outlines; never-seen fog is black.
- You can carry 30 of each resource.

Questions:
1. Did gathering feel worth it, or like busywork?
2. Did each new lantern feel like a real choice?
3. Did you ever feel stuck or short of something? Where?
4. Is "seen" fog clearly different from never-seen dark?

---

## M2 results

### 2026-11-26: owner, M2 build b604c71 (screenshot reviewed)
1. Gathering: **felt worth it**, but there was a lot more fuel than scrap.
2. New lanterns felt like real choices: **yes**.
3. Ran short: **yes, of scrap**.
4. Seen vs never-seen fog: **easier to tell now**.

Gate: **passed**. Change made: scrap spots 14 -> 20 (4-7 each, regrow 75 s), fuel spots 30 -> 22.
Rough totals at start: scrap ~63 -> ~115 (about 23 Post Lamps), fuel ~180 -> ~130 units.
Screenshot note: the game ran on software rendering (Mesa llvmpipe) instead of the GPU.

---

# M1 playtest: "Is tending light fun?"

Play for about 10 minutes. Grey-box only: circles and squares, no real art or sound yet.

## Controls
| Action | Keyboard / mouse | Gamepad |
|---|---|---|
| Move | WASD / arrows | Left stick / D-pad |
| Place lantern (on lit ground) | Space / left click | X (left button) |
| Refuel nearby lantern | E | A (bottom button) |
| Pick up nearby lantern | Q / right click | B (right button) |
| Tuning panel | F1 | Select / Back |

In the tuning panel, D-pad up/down picks a slider and left/right changes it. The keeper stands still while it is open.

## What to try
- Spread lanterns out to see how far you can push the dark.
- Let one go cold and watch the fog come back. Seen tiles keep a faint outline.
- Open the tuning panel and change burn rate, fog creep and radius. Note values that felt best.

## Three questions (from the roadmap)
1. Did you want to place "just one more" lantern?
2. Did upkeep feel like caring for something, or like a chore?
3. Did watching fog return feel calm or stressful?

Also note: best tuning values, anything confusing, anything that felt good.

## Known M1 limits
- Fuel and lanterns are unlimited (resources arrive in M2).
- The hand lamp has a fixed small radius (its fuel arrives later).
- No sound, no real art, no save.

## Results

### 2026-11-26: owner, M1 build 2798574 (screenshot reviewed)
1. Wanted "just one more" lantern: **yes**.
2. Upkeep: **felt like caring, not a chore**.
3. Fog returning: **calm, not stressful**.

Gate: **passed**. Proceed to M2.

Observations from the screenshot (47 lanterns placed, 41 lit, 99% of the valley seen):
- With unlimited lanterns the whole valley gets lit quickly. Expected for M1; M2 makes lanterns and fuel cost resources.
- Fog reads as plain darkness: the grey fog is darkened by the scene's darkness overlay, so fogged, seen and never-seen ground look almost the same, and the seen-tile outlines are invisible.
- Fog edges are blocky (32 px squares). Smoothing is planned for the M4 atmosphere pass.
- Second tester still to do.
