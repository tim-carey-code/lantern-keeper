# Playtests

## Current build: M2 (gathering)

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
