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
