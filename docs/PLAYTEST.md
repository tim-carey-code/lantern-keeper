# Playtests

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
