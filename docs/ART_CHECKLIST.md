# Lantern Keeper: art checklist (Pixelorama)

Your list of everything to draw. Update the **Status** column as you go.

**Updated 2026-11-27 for the approved game plan** (GAME_PLAN §15, §17). Milestones (M1a-M9) are in `docs/ROADMAP.md`. Rows marked "goes in M1b" are for things the plan removes (fuel, glass, cold lanterns); don't spend time on them. For new rows, the file path and size are **suggestions**; we can change either when you start.

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
| Palette | **23 colours only** (since 2026-11-27): import `source/palette/lantern-keeper-23.gpl` in Pixelorama's Palettes panel |
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
| 🟨 | WayLamp, lit | `assets/art/placeholders/waylamp_lit.png` | 32×48 | bottom-centre | drop-in | The old keepers' lamp, one per region, on a stone base. The light glows from the top (about pixel 16,10). The text calls it "a tall lamp with a wide iron bowl". Lit WayLamps are fast travel and, from M1a, where you rest. |
| 🟨 | WayLamp, cold | `assets/art/placeholders/waylamp_cold.png` | 32×48 | bottom-centre | drop-in | Same, cold: an empty bowl of old ash. |
| ⬜ | Great Lamp (finale), cold | `assets/art/landmarks/great_lamp_cold.png` | 48×64 | bottom-centre | needs hookup (M8) | The valley's original light on the lake island. The Still Lake's WayLamp. |
| ⬜ | Great Lamp, lit | `assets/art/landmarks/great_lamp_lit.png` | 48×64 | bottom-centre | needs hookup (M8) | |

## 2. Resources and drops

| Status | Item | File | Size | Anchor | Hookup | Notes / your notes |
|---|---|---|---|---|---|---|
| 🟨 | Dead tree (resin = fuel) | `assets/art/placeholders/dead_tree.png` | 16×32 | bottom-centre | drop-in | Bare, twisted, a few amber resin drips. **Unused since M1b** (fuel is cut; the file stays, nothing draws it). May come back as scenery. |
| 🟨 | Peat (marsh fuel) | `assets/art/placeholders/peat.png` | 16×16 | centre | drop-in | Dark brown mound, a few warm flecks. **Unused since M1b** (fuel is cut; the file stays). |
| 🟨 | Scrap pile | `assets/art/placeholders/scrap_pile.png` | 16×16 | centre | drop-in | Blue-grey metal bits. Scrap is the one material from M1b: piles are taken once. |
| 🟨 | Glass shards (Ridge resource) | `assets/art/placeholders/glass.png` | 16×16 | centre | drop-in | Pale blue-white glints. **Unused since M1b** (glass is cut; the file stays). |
| 🟨 | Keeper's satchel (carry upgrade) | `assets/art/placeholders/satchel.png` | 16×16 | bottom-centre | drop-in | Patched leather satchel, brass buckle. Shown dull once taken. From M3 it adds bag slots. |
| 🟨 | Lamp glass (hand-lamp upgrade) | `assets/art/placeholders/lamp_glass.png` | 16×16 | bottom-centre | drop-in | A clear glass lamp chimney. Shown dull once taken. Since M1b it adds 0.1 lamp charge (and 12 px of light). |
| 🟨 | Ember drop (from Wicklings) | `assets/art/fx/ember.png` | 16×16, 4 frames → 64×16 strip | centre | needs hookup | Flickering flame. Drawn by code today. From M1b its glow becomes the pickup for scrap, oil and items, so it is no longer "fuel". |
| 🟨 | Scrap drop (from Wicklings) | `assets/art/fx/scrap_drop.png` | 16×16 | centre | needs hookup | Small heap with a glint. Drawn by code today. |
| ⬜ | Lamp-oil drop (a flask charge) | `assets/art/fx/oil_drop.png` | 16×16 | centre | needs hookup (M1a) | A small stoppered flask or a drop of amber oil. Packs, elites and the Ashbrood drop it. |
| 🟨 | Wick drop (unspent wick after a faint) | `assets/art/fx/wick_drop.png` | 16×16 | centre | needs hookup | Waits where you fell. Drawn by code today. |

## 3. Creatures

**Where the game looks now** (the swap hook, BUILT in the readability step; layout from ART_DIRECTION §6.2, DRAFT): one PNG strip per animation in a folder per creature, `assets/art/creatures/<subject>/<subject>[_<variant>]_<anim>.png`, plus a small `<subject>.frames.cfg` (frame size; per animation fps and loop). Hooked up: the Wickling (`wickling`, variants `timid`, `brave`, `elite`, `elite_broken`), the Spitwick (`spitwick`), the nest (`nest`), the Ashbrood (`ashbrood`), the Clinker (`clinker`, on `proto/kl-clinker-art`, waiting for your approval), the keeper's poses (`assets/art/keeper/keeper_<anim>.png`) and Amos (`assets/art/people/amos/`, placed in M4). Animation names: `idle`, `move`, `notice`, `windup`, `attack`, `recover`, `hurt`, `death`, `spawn`; the Wickling adds `flee` and `crack`, the Ashbrood `windup_puff`, `attack_puff`, `windup_dive`, `attack_dive`, `phase_rise`; the Clinker `sleep`, `wake`, `roll`, `crack`; the keeper `cast`, `lob`, `thrust`, `dash`, `drink`, `kindle`. Missing ones fall back to `idle`, and with no strips at all the code shape stays.

**Sprites step (2026-11-27):** the six approved samples are in (DECISIONS, "the sprites approved"). Rebuild them with `tools/art/make_sprites.sh`; touch up any strip in Pixelorama and save it under the same name: the tool keeps your version. Rows not yet in the new layout keep their older flat paths.

| Status | Item | File | Size | Anchor | Hookup | Notes / your notes |
|---|---|---|---|---|---|---|
| ✅ | Wickling, timid and brave | `assets/art/creatures/wickling/wickling_{timid,brave}_<anim>.png` | 16×16 strips (idle and move 4 frames) | centre | in (sprites step) | Approved as made by the sprite tool. Timid: idle, move, notice, flee. Brave: idle, move, notice, windup, attack (the reach). Both: hurt, death, spawn. |
| ✅ | Wickling, hurt / burning | `wickling_<variant>_hurt.png` | 16×16, 2 frames | centre | in (sprites step) | The burning edge stays code-drawn (an amber ring over the sprite). |
| ⬜ | Soul of the Wick (boss) | `assets/art/creatures/soul_of_the_wick.png` | 48×48, 4–6 frames | centre | needs hookup (M8) | Living darkness coiled around the great lamp. Big pale eyes. Three phases: the coil, every flame, the eyes; then it sinks and a portal opens. |
| ✅ | Shelled Wickling (elite) | `assets/art/creatures/wickling/wickling_elite_<anim>.png`, `wickling_elite_broken_idle.png` | 24×24 strips | centre | in (sprites step) | The shelled body (idle, notice, crack, hurt, death, spawn), then the shell-less body once the shell breaks. The shell ring is still code-drawn over it. |
| ⬜ | Elite ring (lure above the fog) | `assets/art/fx/elite_ring.png` | 16×16 | centre | needs hookup (M1b) | "One larger pair of eyes with a pale ring" through the fog. |
| ✅ | Spitwick | `assets/art/creatures/spitwick/spitwick_<anim>.png` | 16×32 strips | bottom-centre | in (sprites step) | Idle, windup, attack, recover, notice, hurt, death, spawn. The aim marker stays code-drawn on top. |
| 🟨 | Spit (Spitwick's shot) | `assets/art/fx/spit.png` | 8×8 or 16×16 | centre | needs hookup | Slow and easy to read. Drawn by code today. |
| ✅ | Nest | `assets/art/creatures/nest/nest_<anim>.png` | 32×24 strips (1 frame each, hurt 2) | bottom-centre | in (sprites step) | Idle, windup, attack (the hatch), death, hurt. Its lure glow and the hatch ring stay code-drawn. A slow 4-frame idle pulse would be a nice touch-up. |
| 🔧 | The Clinker (mid-boss) | `assets/art/creatures/clinker/clinker_<anim>.png` | 32×32 strips | bottom-centre | in (Clinker art, `proto/kl-clinker-art`; waiting for your approval) | From the Gemini sheet (2026-11-28) by `tools/art/manifests/clinker.cfg`: sleep 2, wake 4, idle 4, move 4 (the trundle), windup 5 (the curl), roll 4 (one full turn), recover 4 (dizzy), hurt 2, crack 4, death 6 (rubble and smoke). Worth a touch-up: the dizzy spiral eyes are a single pale pixel at 32 px (the code's stars carry it); the crack's bright cracks read as grain; the hunch frame of the curl has no eye; two roll frames have a pale claw speck. Region variants (mire, downwind, fog) later. Without the strips the code shape stays. |
| 🔧 | The Ashbrood (Hollow guardian) | `assets/art/creatures/ashbrood/ashbrood_<anim>.png` | 48×48 strips | bottom-centre | in (sprites step) | Idle in the bowl (with its ember), windup_puff, attack_puff, windup_dive, attack_dive, recover (the sit), phase_rise, death, hurt. Approved as is; known: possible grey wing tips in the bowl band (touch up in Pixelorama if you like). Phase 3 comes in M2. |
| ⬜ | Slowwater (Reedmarsh) | `assets/art/creatures/slowwater.png` | 16×16 or 32×16 | centre | needs hookup (M5) | Hides in unlit water and grabs your feet. |
| ⬜ | Fenlight (Reedmarsh) | `assets/art/creatures/fenlight.png` | 16×16 | centre | needs hookup (M5) | A false lure that bursts. |
| ⬜ | The Sump (Reedmarsh guardian) | `assets/art/creatures/sump.png` | 48×48 | centre | needs hookup (M5) | Under water until Reservoir light forces it up. |
| ⬜ | Gutterkite (Ridge) | `assets/art/creatures/gutterkite.png` | 16×16 | centre | needs hookup (M6) | Dives with the gusts. |
| ⬜ | The Galekite (Ridge guardian) | `assets/art/creatures/galekite.png` | 48×48 | centre | needs hookup (M6) | Out of reach until it snags on a Hooded Lamp. |
| ⬜ | Fogstilt (Lakeshore) | `assets/art/creatures/fogstilt.png` | 16×32 | bottom-centre | needs hookup (M7) | Tall, thickens fog. |
| ⬜ | The Tallest (Lakeshore guardian) | `assets/art/creatures/tallest.png` | 32×64 | bottom-centre | needs hookup (M7) | The first cut if time runs short. |
| ✅ | Keeper (player) | `assets/art/keeper/keeper_<anim>.png` | 32×32 strips | bottom-centre | in (sprites step) | Idle, move, thrust, lob, dash, drink, hurt, kindle (kindle not used yet). Faces right; mirrored for left, and a side view for up and down too. **Optional:** `_n` and `_s` strips for up and down. The Puny sheet (`assets/art/puny/keeper.png`) stays as the fallback. |
| ✅ | Keeper, cast and dash frames | `keeper_thrust.png`, `keeper_lob.png`, `keeper_dash.png` | 32×32 | bottom-centre | in (sprites step) | One key pose each; more frames are a touch-up. |

## 4. Ground and terrain (Kenney tiles cover these today)

These look fine already. Draw your own only if you want a fully original look.

| Status | Item | File | Size | Hookup | Notes / your notes |
|---|---|---|---|---|---|
| ✅ | Grass (3 variants) | Kenney Tiny Town (recoloured) | 16×16 | in game | Optional to replace |
| ✅ | Forest rim (pines) | Kenney Tiny Town | 16×16 | in game | Optional |
| ✅ | Boardwalk planks | Kenney Tiny Dungeon | 16×16 | in game | Optional |
| 🟨 | Reeds (marsh overlay) | `assets/art/placeholders/reeds.png` | 16×16 | drop-in | Thin stalks, a couple of brown cattail heads. |
| ⬜ | Marsh ground tile | `assets/art/tiles/marsh.png` | 16×16 | needs hookup | Today it's tinted grass. |
| ⬜ | Ridge rock / cliff tiles | `assets/art/tiles/ridge.png` | 16×16 set | needs hookup (M6) | Wind-swept stone, cliff edge. |
| ⬜ | Wind-bent grass | `assets/art/tiles/grass_windy.png` | 16×16 | needs hookup (M6) | For the Ridge. |
| ⬜ | Still Lake water | `assets/art/tiles/water.png` | 16×16, 2–4 frames | needs hookup (M7, M8) | Very still, dark, a faint shimmer. The Lakeshore's shallows too. |
| 🟨 | Fallen climb stones (the old climb's shortcut) | `assets/art/landmarks/climb_stones.png` | 16×16 set, or 32×32 pieces | needs hookup (M6) | Today two rows of Ridge rock. They should read as **a fallen pile, not a built wall**, and show they can be pushed down from above. A chalk note on them comes in M6. |

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
| ⬜ | Moored boat (Ebba's) | `assets/art/landmarks/boat.png` | 32×16 | needs hookup (M7) | "Tied up and never used". Moves to the Lakeshore with Ebba (`PLAN_LAKESHORE.md`); it crosses to the Lake after the finale (M8). |
| ⬜ | Lantern rack, one missing | `assets/art/landmarks/rack.png` | 32×32 | needs hookup (any time) | Scenery by the hut. |
| 🟨 | Oswin's crook (the Post Lamp find) | reuses `post_lamp_cold.png` + code | 16×32 | updates with your lamp | Fallen across the path, with a cold lamp on it. A red pulse marks it through the fog. |
| 🟨 | Cairn (foot of the marsh climb) | Kenney stone + code | 16×16 | needs hookup | A small cairn with a chalk arrow pointing up. |
| ⬜ | Survey stones (×3, for Ivo) | `assets/art/landmarks/survey_stone.png` | 16×16 | needs hookup (M5) | Ivo is a cut line. |
| ✅ | Amos's cart | `assets/art/people/amos/amos_cart.png` | 48×32 | needs hookup (M4) | Approved (sprites step); a still prop beside Amos's strips. Stuck among the quiet south packs, then rolled up to the Hollow WayLamp. |
| ⬜ | 10–20 more small landmarks | `assets/art/landmarks/` | 16×16 or 16×32 | needs hookup (M5-M8) | List grows as we write each region. |

## 6. UI icons (optional, for a nicer HUD)

| Status | Item | File | Size | Hookup | Notes / your notes |
|---|---|---|---|---|---|
| 🟨 | Fuel icon | `assets/art/ui/icon_fuel.png` | 16×16 | drop-in | Flame. **Unused since M1b** (no fuel; the HUD shows only scrap). |
| 🟨 | Scrap icon | `assets/art/ui/icon_scrap.png` | 16×16 | drop-in | Metal heap (or a gear/bolt) |
| 🟨 | Glass icon | `assets/art/ui/icon_glass.png` | 16×16 | drop-in | Shards. **Unused since M1b** (no glass). |
| 🟨 | Warmth icon | `assets/art/ui/icon_warmth.png` | 16×16 | drop-in | Heart with a small flame |
| 🟨 | Hand lamp icon | `assets/art/ui/icon_lamp.png` | 16×16 | drop-in | |
| 🟨 | Wind icon | `assets/art/ui/icon_wind.png` | 16×16 | drop-in | Status chip. **Unused since M1b** (the wind chip is gone; wind is inert until M6). |
| 🟨 | Cold lantern icon | `assets/art/ui/icon_cold.png` | 16×16 | drop-in | Status chip. From M1a the right-hand chips are only "hunted" and "cold" (the keeper getting cold). |
| ⬜ | Hunted icon | `assets/art/ui/icon_hunted.png` | 16×16 | needs hookup (M1a) | Status chip: something hunts you. Fast travel, rest and the Skills tab are blocked. |
| 🟨 | Goal marker | `assets/art/ui/icon_goal.png` | 16×16 | drop-in | Diamond in the goal banner |
| ⬜ | Game logo / title | `assets/art/ui/logo.png` | free size (e.g. 128×48) | needs hookup | For a title screen later |

## 7. Skills and effects (PLANNED, from M1a)

Icons sit on the action bar at 2× (32 px). Fireballs, trails and blasts are drawn additive, so draw them bright on transparent; the game adds the glow.

| Status | Item | File (suggested) | Size | Hookup | Notes / your notes |
|---|---|---|---|---|---|
| ⬜ | Lampfire icon | `assets/art/skills/icon_lampfire.png` | 16×16 | needs hookup (M1a) | The basic attack (RT): a fireball of light. |
| ⬜ | Fireglobe icon | `assets/art/skills/icon_fireglobe.png` | 16×16 | needs hookup (M1a) | The big lobbed fireball (RB). |
| ⬜ | Lance icon | `assets/art/skills/icon_lance.png` | 16×16 | needs hookup (M1a) | A fast piercing bolt, the shell-breaker (LB from level 2). |
| ⬜ | Beam icon (optional skill) | `assets/art/skills/icon_beam.png` | 16×16 | needs hookup (M1a) | Only if the owner keeps the Beam after M1a. |
| ⬜ | Hearth ring icon (optional skill) | `assets/art/skills/icon_hearth_ring.png` | 16×16 | needs hookup (M1a) | The old burst, as a ring of flame. Only if kept. |
| ⬜ | Dash icon | `assets/art/skills/icon_dash.png` | 16×16 | needs hookup (M1a) | LT. |
| ⬜ | Flask icon and pip | `assets/art/ui/icon_flask.png`, `flask_pip.png` | 16×16; pip 8×8 | needs hookup (M1a) | Lamp oil on B. 3-5 pips that flash when one comes back. |
| ⬜ | Moth-lights icon | `assets/art/skills/icon_moths.png` | 16×16 | needs hookup (M5) | Level 7, the marsh. |
| ⬜ | Wheeling flame icon | `assets/art/skills/icon_wheel.png` | 16×16 | needs hookup (M6) | Level 9, the Ridge. |
| ⬜ | Lampfire bolt and trail | `assets/art/fx/lampfire.png` | 8×8 or 16×16, 2–4 frames | needs hookup (M1a) | Short trail, bursts on impact with a small splash and a light pop. |
| ⬜ | Fireglobe and its ground marker | `assets/art/fx/fireglobe.png`, `fireglobe_marker.png` | 16×16 | needs hookup (M1a) | Arcs to where you aim; a marker shows where it lands. |
| ⬜ | Lance bolt | `assets/art/fx/lance.png` | 16×8 | needs hookup (M1a) | Thin and fast. |
| ⬜ | Burst and impact flash | `assets/art/fx/impact.png` | 16×16 or 32×32, 3–4 frames | needs hookup (M1a) | For Lampfire's pop and Fireglobe's blast. |
| ⬜ | Burning ground and scorch mark | `assets/art/fx/burning_ground.png`, `scorch.png` | 32×32 | needs hookup (M1a) | Burning ground flickers for a few seconds; the scorch lingers after. |
| ⬜ | Moth mote, wheel disc | `assets/art/fx/moth.png`, `wheel.png` | 8×8; 16×16 | needs hookup (M5, M6) | |

## 8. Items and loot (PLANNED, M3)

Item icons show in the Gear tab and as cards when you compare. Rarity colours come from the palette: Plain `#a3bcd4`, Bright `#6d8fb3`, Rare `#ffd27a`, Relic `#f5a742`.

| Status | Item | File (suggested) | Size | Hookup | Notes / your notes |
|---|---|---|---|---|---|
| ⬜ | Lens bases: Clear lens, Far lens | `assets/art/items/lens_clear.png`, `lens_far.png` | 16×16 each | needs hookup (M3) | The lens shapes direct hits. |
| ⬜ | Burner bases: Wide burner, Slow burner | `assets/art/items/burner_wide.png`, `burner_slow.png` | 16×16 each | needs hookup (M3) | The burner shapes blasts and burning ground. |
| ⬜ | Coat bases: Patched coat, Oilskin, Quilted coat | `assets/art/items/coat_*.png` | 16×16 each | needs hookup (M3) | |
| ⬜ | Wick bases: Plain wick, Braided wick | `assets/art/items/wick_*.png` | 16×16 each | needs hookup (M3) | |
| ⬜ | Relics (about 8) | `assets/art/items/relic_*.png` | 16×16 each | needs hookup (M3-M7) | Brood globe (M3), Steam burner and Maud's Smoulder burner (M5), Oswin's coat, the Kite lens and Kit's Long lens (M6), the Prism wick and Ebba's Shutter burner (M7). |
| ⬜ | Rarity glints (ground items, caches) | `assets/art/fx/glint.png` | 8×8, 2–3 frames | needs hookup (M3) | One shape, tinted by rarity. Also the cache lure through fog (M1b). |
| ⬜ | Slot icons (empty slot) | `assets/art/ui/slot_lens.png` and so on | 16×16 each | needs hookup (M3) | Lens, burner, coat, wick. |

## 9. People (PLANNED, M4-M7)

Drawn at the keeper's 32×32 scale, without portraits (DECISIONS 2026-11-27, "owner answers, later"). They stand still near a WayLamp and never fight, so an idle loop of 2-4 frames is enough. Names are drafts.

| Status | Item | File (suggested) | Size | Hookup | Notes / your notes |
|---|---|---|---|---|---|
| ✅ | Amos, a trader | `assets/art/people/amos/amos_<anim>.png` | 32×32 strips | needs hookup (M4) | Approved (sprites step): idle, move, talk, wave, push, give, laugh. Loads, not placed until M4. Known: the grey hair barely shows. With a cart (section 5). |
| ⬜ | Maud, the old pump keeper | `assets/art/people/maud.png` | 32×32, 2–4 frames | needs hookup (M5) | At the pumphouse. Knew Oswin. |
| ⬜ | Kit, the glazier's apprentice | `assets/art/people/kit.png` | 32×32, 2–4 frames | needs hookup (M6) | At the workshop by the marsh climb's top. |
| ⬜ | Ebba, a rower | `assets/art/people/ebba.png` | 32×32, 2–4 frames | needs hookup (M7) | At the jetty, by her boat. |
| ⬜ | Ivo, a mapmaker | `assets/art/people/ivo.png` | 32×32, 2–4 frames | needs hookup (M5) | By the carved stone. A cut line. |

---

## Animation strips

When something has frames, put them **side by side in one PNG**, left to right, all the same size.
Example: a 4-frame Wickling at 16×16 is one **64×16** PNG. In Pixelorama, export with the spritesheet option, or tell me the frame size and I'll cut it.

## Suggested order

1. Post Lamp lit + cold (drop-in, most visible) ✅
2. For M1a: the Lampfire, Fireglobe, Lance, dash and flask icons, and the fireball sprites (code placeholders work until you get to them)
3. Wickling, Spitwick, shelled Wickling, nest (I'll hook them up)
4. The Clinker and the Ashbrood
5. Reservoir Lamp lit + cold (drop-in), then each region's lamp, foes and people as we build it (M5-M8)
6. Skip what goes in M1b: fuel and glass icons, dead tree resin, peat
