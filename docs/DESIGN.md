# Lantern Keeper — Design Document (Draft v1)

> Status: **draft, awaiting owner review.** All numbers are placeholders to tune in playtests.
> Engine: Godot 4.7.2, GDScript · 2D top-down · single-player · PC (Linux first, Windows later).

---

## 1. Pitch and feeling

**Pitch:** In a dark, foggy valley, you build and tend a network of lanterns that pushes the darkness back. As the light spreads, the valley shows you what happened there.

**Feeling:** *calm, curious, moody, rewarding.*
Calm, with no pressure; the fun is in planning, not reflexes. The dark should feel heavy but never hostile.

---

## 2. Core loop (minute to minute)

1. **Look** at the edge of the light. Something is half-visible in the fog: a resource, a ruin, a path.
2. **Gather** what the light has revealed: fuel, scrap, and later glass.
3. **Build or refuel.** Place a new lantern at the edge, or top up the ones that are running low.
4. **Watch the light spread.** Fog pulls back, tiles are revealed, and new resources and clues appear.
5. **Maintain.** Lanterns burn down, and wind makes some burn faster. Decide which lights to keep, move, or let go.
6. **Expand** toward the next interesting thing. Repeat, with the lit area slowly growing outward.

Over a session: *light a path → reach a new region → learn its twist → unlock a lantern type → push deeper.*

---

## 3. Systems

### 3.1 Light and fuel
- **Rule:** Every lantern has a fuel tank (placeholder: 100 units) and burns fuel over time (placeholder: 1 unit / 3 s). Its light radius scales with remaining fuel, from full radius down to about 40% just before it goes out. An empty lantern goes **cold**: it keeps its frame but gives no light.
- **Player decides:** where to place lights, which ones to refuel first, and when to let a distant light go cold.
- **Connects to:** Light clears fog (3.2) and reveals resources (3.3). Wind changes the burn rate (3.5).

### 3.2 Fog and darkness
- **Rule:** The map is a tile grid, and each tile has a fog density from 0 to 1. Lit tiles fall toward 0. Unlit tiles slowly creep back toward 1, spreading from foggy neighbours (placeholder: +0.05/s). A tile that was ever lit is **remembered**: its outline stays on the map, but resources and details are hidden until it is lit again.
- **Player decides:** which frontier to hold and which to abandon. Overlapping lights hold ground better; isolated lights get eaten at the edges.
- **Connects to:** Fog hides resources (3.3) and blocks building (3.4). Wind pushes it (3.5).

### 3.3 Resources and gathering
- **Rule:** Three resources in v1:
  - **Fuel** (resin from dead trees, peat in the marsh) burns in lanterns.
  - **Scrap** (old metal from ruins) is used to build lanterns.
  - **Glass** (found in later regions) is used for advanced lanterns.

  Resource nodes can only be seen and gathered **on lit tiles**. Gathering is a short hold-to-collect, with no minigame. Nodes are finite but regrow slowly while lit (placeholder: 1 unit / 60 s). The player has a small carry limit (placeholder: 30 per resource) that grows with upgrades found in the world.
- **Player decides:** what to gather and where to spend it, either on more light (growth) or on refuelling (upkeep).
- **Connects to:** Light reveals resources, and resources make more light. **This is the central loop.**

### 3.4 Building and placing lanterns
- **Rule:** Open the build menu, pick a lantern type, and place it on a lit or edge-of-light tile that is firm ground. A ghost preview shows the radius it will light. Building costs scrap (and glass for advanced types). A lantern can be picked up for a 50% refund. Relighting a cold lantern costs only fuel.
- **Player decides:** layout. Chains along paths, clusters to hold ground, or long reaches toward a goal.
- **Connects to:** Placement rules use terrain and fog (3.2). Shelter and exposure matter for wind (3.5).

### 3.5 Weather: wind (the only weather effect in v1)
- **Rule:** Wind blows in **gusts** from one direction at a time. Gusts are announced about 5 s ahead by sound and swaying grass. During a gust, **exposed** lanterns burn fuel 2× faster and flicker smaller, and fog drifts downwind faster. Tiles behind walls, rocks or buildings count as **sheltered**.
- **Player decides:** whether to place lanterns in sheltered spots or use shielded lanterns, and where to expect fog to push in.
- **Connects to:** Wind adds pressure on fuel (3.1) and fog (3.2), and gives terrain a meaning for placement (3.4).

---

## 4. Player failure: gentle, no game over

**Choice:** v1 has **no game over and no death.**

- The player carries a **hand lamp**. It slowly dims as the player walks through dark areas, but it never goes out: it stops at a small "ember" radius. The player can always find the way home.
- In deep fog the player moves a little slower and sees only a few tiles. There is no damage.
- When a lantern runs out, it goes cold and fog slowly reclaims its area. Nothing is destroyed. The frame stays, and relighting it costs only fuel.
- The real cost of neglect is **time and fuel**, never lost progress.

**Why:** The owner wants a relaxing game with no fail-fast pressure, played as one long run. A game over would punish experiments and break the calm. The gentle penalty still makes upkeep matter: it is easier to keep a light burning than to relight it.

---

## 5. Progression: lantern types (4 in v1)

| # | Lantern | What it does | Unlocked by |
|---|---------|--------------|-------------|
| 1 | **Post Lamp** | Basic. Medium radius, normal burn, fully exposed to wind. | Available from the start (an old frame stands next to the hut). |
| 2 | **Hooded Lamp** | Smaller radius, but wind doesn't affect it. Costs scrap and glass. | Find the glazier's workshop in the Windward Ridge (Region 3). |
| 3 | **Mirror Post** | Burns **no fuel**. It catches light from a lit lantern next to it and throws a narrow beam in a direction the player chooses. Used to reach across water and gaps. | Reach the cliff signal station on the Ridge (Region 3, after the Hooded Lamp). |
| 4 | **Reservoir Lamp** | Large tank and wide, dim light. Slowly tops up the fuel of other lanterns inside its radius. Turns upkeep into logistics. | Relight the pumphouse in the Reedmarsh (Region 2). |

Other progression (not new types): carry-limit upgrades and hand-lamp upgrades found in ruins. The **map memory** grows as more of the valley is lit.

Suggested unlock order: Post → Reservoir → Hooded → Mirror. Each one solves the main problem of the region where it is found.

---

## 6. The valley: one map, four regions

There is one handmade map. It never reloads or switches levels; it only becomes lit and revealed. Each region **reuses the same systems with one twist**.

| Region | Twist (reused systems) | Key find |
|--------|------------------------|----------|
| **1. The Hollow** (start) | No twist. Light fog, sheltered, plenty of old frames to relight. Teaches the loop. | The keeper's hut and an empty lantern rack. |
| **2. The Reedmarsh** | Lots of fuel, but **soft ground**: lanterns can only stand on boardwalks and islands, and the fog creeps back faster. | The pumphouse (unlocks the Reservoir Lamp). |
| **3. The Windward Ridge** | **Constant strong wind** with frequent gusts. Old ruins hold glass. | The glazier's workshop and the signal station (unlock the Hooded Lamp and Mirror Post). |
| **4. The Still Lake** | Fog **too thick for ordinary light** near the water. Only Mirror Post beams cut through, so the player plans a chain of mirrors. | The great lamp on the island: the valley's original light, cold. |

**The quiet mystery (shown through the environment, no dialogue):**
Light reveals objects, never characters who explain things. Examples:
- A keepers' **ledger** with tally marks that get smaller and smaller.
- Lantern frames that all point toward the lake.
- Chalk drawings on a wall showing a bright lake, then a dark one.
- A boat tied up and never used, and a rack with one lantern missing.
- Short inscriptions on carved stones (one line each, readable on interact).

The player pieces together that the valley once had a keepers' order around a great lamp. The lamp went out, and people left. **Why it went out is only hinted at, never confirmed.** Relighting the great lamp is the v1 finale: the fog lifts across the whole valley for the first time. After that the player can keep playing freely (see Open questions).

---

## 7. Version 1 scope box

**IN**
- One map, four regions, about 15–25 mystery objects.
- Four lantern types, three resources, the hand lamp.
- The fog grid with creep and memory; one weather effect (wind gusts).
- Build, refuel, pick up, and relight actions; a simple build menu; a fuel HUD; a map that shows revealed areas.
- A gentle failure model (no game over).
- Save/load (a single save slot plus autosave).
- Atmosphere from Godot 2D lighting, a fog shader and particles, ambient sound, and CC0 art.
- A Linux build.

**OUT** (v1)
- Combat, enemies, health.
- Story told through dialogue, NPCs, cutscenes.
- More than one map, procedural generation.
- Day/night cycle, rain, seasons.
- Crafting trees beyond the lantern recipes.
- Windows build, controller support, settings beyond volume and fullscreen.

**Target playtime:** about 1–2 hours to relight the great lamp.

**Done when:**
- A new player can go from start to finale without outside help.
- No game-over states and no soft-locks: the player can always gather enough fuel to relight something.
- All four regions, lantern types and mystery objects are in the game.
- Save/load restores the lantern, fog and resource state.
- The Linux build runs from a fresh machine.
- The CC0 credits list is complete.

---

## 8. Maybe later

- Rain (puts out exposed lanterns), snow, a full weather cycle.
- Day/night cycle.
- More lantern types: colored lights that reveal hidden marks, floating lanterns, a lighthouse.
- Gentle creatures drawn to the light (they never attack).
- Map size or region expansions after v1.
- Windows build, Steam Deck/controller support.
- Custom art and an original soundtrack.
- A photo mode, and an "ambient" mode with no goals.
- Optional journal that gathers the mystery objects.

---

## 9. Art and audio direction

- **Style:** stylized, readable top-down 2D. Simple shapes, little detail; let the light do the work. Placeholder shapes are fine until M4.
- **Palette:** dark blue-black and grey-green for the world. Warm amber lantern light is the **only warm color**, so warmth means safety. The fog is cool grey with a hint of blue.
- **Atmosphere (most of the mood comes from here):**
  - `CanvasModulate` for darkness.
  - `PointLight2D` for each lantern, with `LightOccluder2D` on walls and rocks so they cast shadows.
  - A fog shader driven by the fog grid, plus `GPUParticles2D` for drifting mist.
  - A small random flicker on every light.
- **Audio:** layered ambient sound (wind, distant water, creaking wood), soft hiss and crackle near lanterns, a gust warning sound, and quiet music that grows slightly fuller as more of the valley is lit. No stingers and no jump scares.
- **CC0 first, custom later:**
  - Use CC0 packs (e.g. Kenney) for tiles, props, UI, particles and sound effects.
  - Custom work later: the lantern sprites, the great lamp, the mystery objects, and the music. These carry the game's identity.
  - Track every asset in `assets/CREDITS.md`.

---

## 10. Open questions for the owner

1. **After the finale:** should the game keep going as an open sandbox (proposed), or roll credits and end?
2. **Hand lamp:** should it use fuel too, as an extra small upkeep task (proposed: no, it only dims to an ember)?
3. **Mystery answer:** should the game leave why the lamp went out unanswered (proposed), or reveal it clearly at the end?
4. **Controls:** mouse + keyboard only for v1 (proposed), or plan for a gamepad from the start?
5. **Map size:** is a single map about 4× the starting view in each direction about right for 1–2 hours of play?
