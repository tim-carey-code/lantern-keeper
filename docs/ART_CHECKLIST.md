# Lantern Keeper: art checklist (Pixelorama)

Your list of everything to draw. Update the **Status** column as you go.

**Status key:**
`⬜ to do` · `🟨 placeholder in game` · `✏️ in progress` · `🔧 done, needs tweaks` · `✅ done`

**Hookup key** (what happens when you save the file):
- **drop-in**: save a PNG with the same name and size over the placeholder and it appears the next time you run the game.
- **needs hookup**: tell me when it's ready and I'll wire it in (it's drawn by code today, or the feature isn't built yet).

---

## The rules (read once)

| Rule | Value |
|---|---|
| Base grid | **16×16 px** per tile. Tall things are **16×32**. The game shows everything at **2×**. |
| Palette | **14 colours only**: import `source/palette/lantern-keeper-14.gpl` in Pixelorama's Palettes panel |
| Background | **Transparent** (no filled background) |
| Anti-aliasing | None. Hard pixel edges only. |
| Anchor | Things that stand (lamps, trees) sit on the **bottom-centre** of the canvas. Flat things (piles, tiles) are centred. |
| Export (what the game loads) | PNG into `assets/art/...` (path in each table) |
| Save (your working file) | `.pxo` into `source/art/` with the same name, so you keep layers |
| Light | Lamps glow from the lamp box near the top of a 16×32 sprite (about **7 px down from the top**). Keep the lamp box around there. |

### The palette

| # | Hex | Role |
|---|---|---|
| 1 | `#0b0e1a` | deepest night, outlines in darkness |
| 2 | `#141a2e` | outlines, lamp frames |
| 3 | `#1d2745` | deep shadow |
| 4 | `#28385e` | night grass (dark), cold glass |
| 5 | `#36507a` | night grass, bark |
| 6 | `#4a6a94` | stone, metal, water |
| 7 | `#6d8fb3` | light stone, highlights |
| 8 | `#a3bcd4` | brightest cool highlight, glints |
| 9 | `#fff1c1` | flame core, hottest light |
| 10 | `#ffd27a` | lamp glass (lit), warm highlight |
| 11 | `#f5a742` | flame, embers |
| 12 | `#d9772b` | warm mid (dirt in lamplight, copper) |
| 13 | `#9c4a22` | wood |
| 14 | `#5a2a1c` | dark wood, outlines on warm things |

Rule of thumb: **cool blues for the world, ambers only for light, fire and wood.** That's what makes the lamps pop.

---

## 1. Lanterns (top priority: these are the game's signature)

| Status | Item | File | Size | Anchor | Hookup | Notes / your notes |
|---|---|---|---|---|---|---|
| ✅ | Post Lamp, lit | `assets/art/placeholders/post_lamp_lit.png` | 16×32 | bottom-centre | drop-in | **Shepherd's crook with a stone base** (owner's art, `source/art/post_lamp_lit.pxo`). Keep the hanging lamp where it is (glass centre at pixel 12,14): the light glows from there. |
| ✅ | Post Lamp, cold | `assets/art/placeholders/post_lamp_cold.png` | 16×32 | bottom-centre | drop-in | Owner's art (`source/art/post_lamp_cold.pxo`). Also shown as the outline you see through fog. |
| 🟨 | Reservoir Lamp, lit | `assets/art/placeholders/reservoir_lamp_lit.png` | 16×32 | bottom-centre | drop-in | Big tank on legs, small lamp on top. |
| 🟨 | Reservoir Lamp, cold | `assets/art/placeholders/reservoir_lamp_cold.png` | 16×32 | bottom-centre | drop-in | |
| 🟨 | Hooded Lamp, lit | `assets/art/placeholders/hooded_lamp_lit.png` | 16×32 | bottom-centre | drop-in | Wind-proof: a hood or shield around the flame. |
| 🟨 | Hooded Lamp, cold | `assets/art/placeholders/hooded_lamp_cold.png` | 16×32 | bottom-centre | drop-in | |
| 🟨 | Mirror Post, catching light | `assets/art/placeholders/mirror_post_lit.png` | 16×32 | bottom-centre | drop-in | No flame. A tilted mirror on a post, bright. |
| 🟨 | Mirror Post, dark | `assets/art/placeholders/mirror_post_dark.png` | 16×32 | bottom-centre | drop-in | Same, unlit. |
| ⬜ | Great Lamp (finale), cold | `assets/art/landmarks/great_lamp_cold.png` | 48×64 | bottom-centre | needs hookup (M5) | The valley's original light on the lake island. |
| ⬜ | Great Lamp, lit | `assets/art/landmarks/great_lamp_lit.png` | 48×64 | bottom-centre | needs hookup (M5) | |

## 2. Resources and drops

| Status | Item | File | Size | Anchor | Hookup | Notes / your notes |
|---|---|---|---|---|---|---|
| 🟨 | Dead tree (resin = fuel) | `assets/art/placeholders/dead_tree.png` | 16×32 | bottom-centre | drop-in | Bare, twisted, a few amber resin drips. |
| 🟨 | Peat (marsh fuel) | `assets/art/placeholders/peat.png` | 16×16 | centre | drop-in | Dark brown mound, a few warm flecks. |
| 🟨 | Scrap pile | `assets/art/placeholders/scrap_pile.png` | 16×16 | centre | drop-in | Blue-grey metal bits. |
| 🟨 | Glass shards (Ridge resource) | `assets/art/placeholders/glass.png` | 16×16 | centre | drop-in | Pale blue-white glints. |
| 🟨 | Ember drop (from Wicklings) | `assets/art/fx/ember.png` | 16×16, 4 frames → 64×16 strip | centre | needs hookup | Flickering flame. Drawn by code today. |
| 🟨 | Scrap drop (from Wicklings) | `assets/art/fx/scrap_drop.png` | 16×16 | centre | needs hookup | Small heap with a glint. Drawn by code today. |

## 3. Creatures

| Status | Item | File | Size | Anchor | Hookup | Notes / your notes |
|---|---|---|---|---|---|---|
| 🟨 | Wickling, float | `assets/art/creatures/wickling.png` | 16×16, 4 frames → 64×16 strip | centre | needs hookup | Smoky shadow blob with 2 pale eyes. Drawn by code today. Use `#0b0e1a`/`#141a2e` body, `#a3bcd4` eyes. |
| ⬜ | Wickling, hurt / burning | same file, row 2 | 16×16, 2 frames | centre | needs hookup | Amber edge. |
| ⬜ | Soul of the Wick (boss) | `assets/art/creatures/soul_of_the_wick.png` | 48×48, 4–6 frames | centre | needs hookup (M5) | Living darkness coiled around the great lamp. Big pale eyes. |
| ✅ | Keeper (player) | `assets/art/puny/keeper.png` | 32×32 frames, 24×8 sheet | — | already in | Puny Characters mage (CC0), recoloured. **Optional:** draw your own keeper with the same sheet layout. |

## 4. Ground and terrain (Kenney tiles cover these today)

These look fine already. Draw your own only if you want a fully original look.

| Status | Item | File | Size | Hookup | Notes / your notes |
|---|---|---|---|---|---|
| ✅ | Grass (3 variants) | Kenney Tiny Town (recoloured) | 16×16 | in game | Optional to replace |
| ✅ | Forest rim (pines) | Kenney Tiny Town | 16×16 | in game | Optional |
| ✅ | Boardwalk planks | Kenney Tiny Dungeon | 16×16 | in game | Optional |
| 🟨 | Reeds (marsh overlay) | `assets/art/placeholders/reeds.png` | 16×16 | drop-in | Thin stalks, a couple of brown cattail heads. |
| ⬜ | Marsh ground tile | `assets/art/tiles/marsh.png` | 16×16 | needs hookup | Today it's tinted grass. |
| ⬜ | Ridge rock / cliff tiles | `assets/art/tiles/ridge.png` | 16×16 set | needs hookup (M5) | Wind-swept stone, cliff edge. |
| ⬜ | Wind-bent grass | `assets/art/tiles/grass_windy.png` | 16×16 | needs hookup (M5) | For the Ridge. |
| ⬜ | Still Lake water | `assets/art/tiles/water.png` | 16×16, 2–4 frames | needs hookup (M5) | Very still, dark, a faint shimmer. |

## 5. Buildings and landmarks

| Status | Item | File | Size | Hookup | Notes / your notes |
|---|---|---|---|---|---|
| ✅ | Keeper's hut | Kenney Tiny Town | 48×32 (3×2 tiles) | in game | Optional to replace with your own `assets/art/landmarks/hut.png` |
| ✅ | Pumphouse | Kenney Tiny Town + code wheel | 48×32 | in game | Optional own version |
| ✅ | Keepers' ledger (sign) | Kenney Tiny Town | 16×16 | in game | Optional |
| ✅ | Carved stone | Kenney Tiny Dungeon | 16×16 | in game | Optional |
| 🟨 | Old lantern frames (×3) | reuses `post_lamp_cold.png` | 16×32 | updates with your lamp | |
| 🟨 | Chalk drawings on the pumphouse wall | Kenney wall + code circles | 16×16 | needs hookup | Bright lake vs scribbled-over lake. |
| 🟨 | Glazier's workshop (Ridge) | Kenney tiles + code kiln today; yours: `assets/art/landmarks/glazier.png` | 48×32 | needs hookup | Unlocks the Hooded Lamp. |
| 🟨 | Signal station (Ridge) | Kenney stone + code mirror today; yours: `assets/art/landmarks/signal_station.png` | 32×48 | needs hookup | Unlocks the Mirror Post. |
| ⬜ | Moored boat (Lake) | `assets/art/landmarks/boat.png` | 32×16 | needs hookup (M5) | "Tied up and never used". |
| ⬜ | Lantern rack, one missing | `assets/art/landmarks/rack.png` | 32×32 | needs hookup (M5) | |
| ⬜ | 10–20 more small landmarks | `assets/art/landmarks/` | 16×16 or 16×32 | needs hookup (M5) | List grows as we write the story. |

## 6. UI icons (optional, for a nicer HUD)

| Status | Item | File | Size | Hookup | Notes / your notes |
|---|---|---|---|---|---|
| 🟨 | Fuel icon | `assets/art/ui/icon_fuel.png` | 16×16 | drop-in | Flame. Shown at 2× in the HUD panel. |
| 🟨 | Scrap icon | `assets/art/ui/icon_scrap.png` | 16×16 | drop-in | Metal heap (or a gear/bolt) |
| 🟨 | Glass icon | `assets/art/ui/icon_glass.png` | 16×16 | drop-in | Shards |
| 🟨 | Warmth icon | `assets/art/ui/icon_warmth.png` | 16×16 | drop-in | Heart with a small flame |
| 🟨 | Hand lamp icon | `assets/art/ui/icon_lamp.png` | 16×16 | drop-in | |
| 🟨 | Wind icon | `assets/art/ui/icon_wind.png` | 16×16 | drop-in | Status chip |
| 🟨 | Cold lantern icon | `assets/art/ui/icon_cold.png` | 16×16 | drop-in | Status chip |
| 🟨 | Goal marker | `assets/art/ui/icon_goal.png` | 16×16 | drop-in | Diamond in the goal banner |
| ⬜ | Game logo / title | `assets/art/ui/logo.png` | free size (e.g. 128×48) | needs hookup | For a title screen later |

---

## Animation strips

When something has frames, put them **side by side in one PNG**, left to right, all the same size.
Example: a 4-frame Wickling at 16×16 is one **64×16** PNG. In Pixelorama, export with the spritesheet option, or tell me the frame size and I'll cut it.

## Suggested order

1. Post Lamp lit + cold (drop-in, most visible)
2. Reservoir Lamp lit + cold (drop-in)
3. Dead tree, peat, scrap pile, reeds (drop-in)
4. Wickling + ember (I'll hook them up)
5. M5 items as we build each region
