# Lantern Keeper — Roadmap (Draft v1)

> Status: **draft, awaiting owner review.** Scope is fixed by the *Version 1 scope box* in `DESIGN.md`. Any new idea goes to the *Maybe later* list there, not into a milestone.
> No time estimates yet. A milestone is finished only when its "done when" check passes.

---

## Status

- M0 done (b9dab77). M1 done, playtest gate passed (2798574, 62f7612). M2 done, playtest gate passed; scrap rebalanced. M3 done, playtest gate passed; gust and landmark readability improved after the playtest. M4 atmosphere pass in progress: Kenney CC0 art (recoloured), placeholders for lantern posts and other gaps, soft fog, pixel font, sound effects done; ambience recordings (Freesound CC0) and keeper walk frames still to do.
- Second-tester playtest for M1 still to do.

---

## M0 — Setup

**Goal:** an empty project that runs, is tracked in git, and has a structure we won't need to rework.

**Deliverables**
- A Godot 4.7.2 project with GDScript and a 2D renderer setup.
- A git repo with a Godot `.gitignore` (ignore `.godot/` and export output).
- The folder structure below, plus `DESIGN.md` and `ROADMAP.md` copied into `docs/`.
- An input map:

  | Action | Keys |
  |--------|------|
  | `move_up` / `move_down` / `move_left` / `move_right` | WASD and arrow keys |
  | `interact` (gather / refuel / relight) | E |
  | `place` | left mouse button |
  | `cancel` | right mouse button (Esc also cancels while in build mode) |
  | `build_menu` | B |
  | `map` | M |
  | `pause` | Esc (when not in build mode) |

- `scenes/test/test_scene.tscn`: a coloured square that moves on a grey grid.
- `assets/CREDITS.md`, created empty from the template below.

**Done when:** a fresh clone opens in Godot, the test scene runs, WASD moves the square, and the first commit exists locally. Whether and where to push to a remote is the owner's decision.

---

## M1 — Core prototype ("Is tending light fun?")

**Goal:** prove the core feeling with grey-box shapes only.

**Deliverables**
- The player (a circle) moves around in darkness (`CanvasModulate` near black) and carries a hand lamp at ember radius.
- **Fog grid** (`systems/fog/`): per-tile density, creep-back toward fog, and "remembered" tiles. Drawn as plain shaded squares.
- **One lantern type** (the Post Lamp): place it, it burns fuel, its radius shrinks as fuel runs low, and it goes cold when empty. The player can refuel it from an infinite test pool.
- Lit tiles are revealed and fog returns where light fades.
- A debug panel that shows and tweaks the main placeholder numbers live (burn rate, creep rate, radius).

**Done when:** at least one other person and the owner each play for 10 minutes and answer three questions:
1. Did you want to place "just one more" lantern?
2. Did upkeep feel like caring for something, or like a chore?
3. Did watching fog return feel calm or stressful?

**Decision gate:** if the answers are mostly negative, tune or rethink the loop **before starting M2**. Don't add content to fix a loop that isn't fun.

---

## M2 — Resources and gathering (the fuel loop closes)

**Goal:** light reveals resources, and resources make more light. The infinite test fuel goes away.

**Deliverables**
- Fuel and scrap nodes that are visible and gatherable only on lit tiles, with slow regrowth while lit.
- Carry limits and a simple HUD (resource counts, fuel bar of the nearest lantern).
- A build menu with costs, a ghost placement preview, pick-up with refund, and relighting cold lanterns.
- Gentle failure in place: no game over, the hand lamp never goes fully out, a slower walk in deep fog.
- A grey-box layout of Region 1 (The Hollow).

**Done when:** the player can start with nothing and grow a self-sustaining lit area in The Hollow. Letting every lantern go cold never soft-locks the game (there is always a fuel node reachable by hand-lamp).

---

## M3 — Second lantern type and first region reveal

**Goal:** prove that a new region and a new lantern type create new decisions using the same systems.

**Deliverables**
- Region 2 (The Reedmarsh) in grey-box: soft ground, boardwalks, faster fog creep, plenty of peat fuel.
- The **Reservoir Lamp**, unlocked at the pumphouse.
- A region-reveal moment: as light enters a new region, its name fades in and the ambient layer changes (a placeholder sound is fine).
- The first 3–4 mystery objects, readable on interact.
- The map screen shows revealed and remembered areas.

**Done when:** a playtester moves from The Hollow into The Reedmarsh without help, unlocks the Reservoir Lamp, and uses it on purpose to cut down upkeep.

---

## M4 — Atmosphere pass (CC0 assets)

**Goal:** make it look and sound moody. This is where the mood is made.

**Deliverables**
- CC0 tiles and props replace the grey-box in Regions 1–2. Every pack is logged in `assets/CREDITS.md`.
- `PointLight2D` lanterns with flicker, and `LightOccluder2D` shadows on walls and rocks.
- A fog shader driven by the fog grid, plus `GPUParticles2D` drifting mist.
- Ambient audio layers, lantern sounds, and footsteps, on separate audio buses (Ambience / SFX / Music).
- Palette check: amber light is the only warm color.
- Performance check: holds 60 fps with 50+ lanterns on target Linux hardware.

**Done when:** screenshots and a 2-minute capture of Regions 1–2 feel "dark, calm, curious" to the owner, with no placeholder shapes visible in normal play.

---

## M5 — Full v1 content and save/load

**Goal:** the whole valley, playable from start to finale.

**Deliverables**
- **Wind gusts** (if not started earlier), with warnings and sheltered tiles.
- Region 3 (The Windward Ridge): constant wind, glass, the **Hooded Lamp** and the **Mirror Post**.
- Region 4 (The Still Lake): thick fog that only mirror beams can cut, the great lamp, and the finale where the fog lifts.
- All mystery objects (15–25) placed. Carry-limit and hand-lamp upgrades placed.
- **Save/load:** one slot plus autosave. Saves lanterns (type, position, fuel, cold/lit), the fog grid, revealed/remembered tiles, resources, unlocks, and objects found.

**Done when:** the full game can be finished in one sitting in about 1–2 hours. Saving and loading at any point restores the same state. Every item on the *IN* list in `DESIGN.md` is checked off.

---

## M6 — Polish, playtest, Linux build

**Goal:** a v1 that a stranger can play.

**Deliverables**
- At least 3 external playtests, with notes. Fix the blockers. Tune the placeholder numbers.
- Minimal settings: volume per bus, fullscreen toggle.
- Title screen, pause menu, a short "how to play" hint on first launch.
- A Linux export (x86_64), tested on a machine without Godot installed.
- A final check that `assets/CREDITS.md` is complete.

**Done when:** the *Done when* list in `DESIGN.md` §7 passes, and the Linux build runs from a clean machine. Releasing or publishing the build is a separate decision for the owner.

---

## Suggested Godot folder structure

```
lantern-keeper/
├── project.godot
├── docs/                  # DESIGN.md, ROADMAP.md, playtest notes
├── scenes/
│   ├── main/              # main.tscn, title, pause
│   ├── world/             # the valley map, regions, props
│   ├── player/
│   ├── lanterns/          # one scene per lantern type
│   ├── ui/                # HUD, build menu, map screen
│   └── test/              # throwaway test scenes
├── scripts/               # scripts that belong to a scene (player, lanterns, UI)
├── systems/               # game-wide systems, mostly autoloads
│   ├── fog/               # fog grid: density, creep, memory
│   ├── light/             # lantern registry, fuel ticks, light → tile reveal
│   ├── resources/         # nodes, inventory, regrowth
│   ├── weather/           # wind gusts, shelter checks
│   └── save/              # save/load
├── data/                  # tunable numbers as .tres resources (burn rates, costs)
└── assets/
    ├── art/
    ├── audio/
    ├── fonts/
    ├── shaders/
    └── CREDITS.md
```

Notes:
- `systems/` holds the simulation. Scenes only display and trigger it. This keeps the fog and light logic testable, and it makes save/load simpler.
- Keep all placeholder numbers in `data/` so tuning doesn't mean editing code.

---

## Asset license tracking

Every external asset must be logged in `assets/CREDITS.md` **when it is added**, not at the end.

1. Before adding a pack, check its license on the source page. "Free" does not mean CC0. Some packs on asset sites are CC-BY, which requires attribution, or have other terms.
2. Keep each pack in its own folder (e.g. `assets/art/kenney_<packname>/`) and include the pack's own license file.

Template:

```markdown
# Credits and asset licenses

| Asset / pack | Author | Source URL | License | Used for | Folder | Date added |
|--------------|--------|------------|---------|----------|--------|------------|
| (example) Top-down tiles | Kenney | https://kenney.nl/assets/... | CC0 1.0 | Ground tiles | assets/art/kenney_tiles/ | YYYY-MM-DD |
```
