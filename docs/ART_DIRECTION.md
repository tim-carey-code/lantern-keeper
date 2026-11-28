# Lantern Keeper: art and animation bible

**DRAFT for owner approval, 2026-11-27.** Nothing here is decided until the owner marks it up. The plan of record is `docs/replan/GAME_PLAN.md` (§1 pillars, §4 skills, §8 foes, §11 people, §15 art). Where this doc and the plan disagree, the plan wins.

**Why this doc exists.** The owner asked for "a whole art design concept and everything for all the monsters and NPC's", and for foe attacks to be "telegraphed and animated better, as with my abilities". This doc gives one look for every creature and person, one telegraph language for every foe attack, and a way to swap art in without code changes.

**How to read it.**
- *Built* means it is in the code. Foe code is cited on this branch (`proto/kl-replan`). The M1a skill code lives on `proto/kl-m1a` / `proto/kl-m1a-fix`, not merged here; it is cited with that branch name.
- *Proposed* means a suggestion in this doc. Timings are tuning values for `systems/tuning.gd`; "(new)" marks one that doesn't exist yet.
- Frame counts are starting points. The owner can draw more or fewer frames; the loader in §6.3 copes.
- Pronouns: Oswin is "he", Ebba is "she", the keeper is "they", the Soul of the Wick is "it". Amos, Maud, Kit and Ivo get none.
- Original design only. Other games are references for mechanics and feel, never for characters, names or art.

**Uncertainty, stated once.** I have not run the game for this draft. Screen claims come from the code (`project.godot`: 1280x720, no camera zoom). Sizes in the Puny keeper sheet are read from the file, not measured by eye.

---

## 0. In short

1. Keep the rules that exist: 16x16 art shown at 2x (32 px on screen, one tile), the 14-colour palette, hard edges (`docs/ART_CHECKLIST.md`, DESIGN §17).
2. The owner's Post Lamp (`assets/art/placeholders/post_lamp_lit.png`, `post_lamp_cold.png`, sources `source/art/*.pxo`) is the style anchor. It stays as drawn. Everything else matches it.
3. **Warm is yours, cold is theirs.** The keeper's fire and lamps use the four ambers. Foes and all foe telegraphs use the cold blues and pale blue-white. A foe tell never uses amber.
4. Foes read by **shape first, eyes second, rim third**. Each class has its own silhouette: round blob, tall drip, plated blob, low cluster, heavy boulder, huge guardian.
5. Every foe attack follows one rhythm: **notice → wind-up → commit → strike → recover**. The danger area shows at full size from the first frame of the wind-up.
6. No discrete hit lands with less than 0.5 s of warning. No hit comes from off-screen without an edge arrow.
7. Five built attacks need fixes. The biggest: the Ashbrood's ash-puff ring fades out just as it hits, and its dive can teleport to an off-screen lamp.
8. The keeper's fire VFX are built on the M1a branch, drawn by code. What's missing is the keeper's own body: cast, dash and drink poses.
9. Art goes in per-subject folders with one PNG strip per animation. A loader builds `SpriteFrames` at run time, so dropping a PNG in replaces the code-drawn placeholder.
10. Order: a telegraph pass in code first (no art needed), then the Wickling family and the Spitwick, then the keeper's poses and the icons.

---

## 1. Style foundations

### 1.1 Pixel scale

| Rule | Value | Source |
|---|---|---|
| Grid | 16x16 source px per tile, shown at 2x = 32 screen px | ART_CHECKLIST "The rules"; `systems/art/art.gd` (`SCALE`, `CELL`) |
| Filtering | Nearest-neighbour. No anti-aliasing, no sub-pixel moves in source art | DESIGN §17 |
| Screen | 1280x720, no zoom: 40 x 22.5 tiles on screen | `project.godot` |
| Code-drawn shapes | Foes, telegraphs and fire are drawn in screen px today, not in 2x source px | `scripts/enemies/*.gd` `_draw()` |

**Rule:** sprites stay at 2x. Telegraph markers and fire VFX may stay smooth vector shapes drawn by code, because they must match hit areas exactly. That mix is already how the M1a fire looks.

### 1.2 Sprite sizes per class

Sizes are source px (double them for screen px). "Today" is the code shape's rough size on screen.

| Class | Frame size | Today | Notes |
|---|---|---|---|
| Keeper | 32x32 frame, figure about 16x24 inside | Puny sheet, 768x256 = 24 x 8 frames of 32x32 (`assets/art/puny/keeper.png`) | 8 direction rows (`player.gd:25`). Drawn at 2x, so 64x64 on screen |
| Person (NPC) | 32x32 frame, same figure size as the keeper | none yet | ART_CHECKLIST §9 |
| Small foe | 16x16 | Wickling about 22 px wide (`wickling.gd:197-215`) | Wickling, Spitwick, Slowwater, Fenlight |
| Elite | **24x24** (proposed; the checklist says 16x16) | the Wickling drawn at 1.6x (`wickling.gd:198-199`) | A real bigger frame reads better than scaling a 16x16 sprite |
| Nest | 32x32 | about 36 px wide (`wick_nest.gd:196`) | Low and wide |
| Mid-boss | 32x32 | Clinker about 48 px (`clinker.gd:84`) | Region variants share the sheet layout |
| Guardian | 48x48 (the Tallest 32x64, the Galekite 64x32) | Ashbrood about 58 px (`ashbrood.gd:136`) | ART_CHECKLIST §3 |
| The Soul of the Wick | **built from parts** (proposed): eyes 32x16, coil segments 32x32, tendril tip 16x16 | none | One 48x48 sprite (checklist) is too small for a finale arena. Owner question 3 |
| Region creature (tall or wide) | Fogstilt 16x32, Gutterkite 32x16 | none | PLAN_NPCS_ENEMIES "Art" lines |
| Projectiles | 8x8 (spit, bolts), 16x16 (globe, wheel) | code | |

### 1.3 Outlines

- **Lamps, props, people, the keeper:** a 1 px outline in `#141a2e` (as the Post Lamp does). On warm parts, use `#5a2a1c` for the outline.
- **Creatures of the dark:** no full outline. Their body is already near-black. They get a **1 px rim** on the top and the side facing the keeper's light, in `#36507a` (small foes) or `#4a6a94` (elites and up). Today a code rim does this job (`wickling.gd:209-211`).
- **Shells:** pale plates in `#6d8fb3` with `#a3bcd4` edges. A plate outline is the one place a foe uses a light outline.
- No outline on fire, glows or telegraph fills.

### 1.4 Palette roles

The 14 colours stay (`source/palette/lantern-keeper-14.gpl`, ART_CHECKLIST "The palette"). This doc only assigns roles.

| Role | Colours | Used for |
|---|---|---|
| **The dark** | `#0b0e1a`, `#141a2e`, `#1d2745` | Foe bodies, deep shadow, outlines |
| **The world** | `#28385e`, `#36507a`, `#4a6a94`, `#6d8fb3` | Grass, stone, water; foe rims, shells, cold seams |
| **Cold threat** | `#a3bcd4` (plus white in additive glows) | Foe eyes, every foe telegraph, foe projectiles, the keeper's "chilled" flash |
| **The keeper's fire** | `#fff1c1`, `#ffd27a`, `#f5a742`, `#d9772b` | Lamps, the hand lamp, every skill, burning foes, the keeper's ground markers |
| **Wood and leather** | `#9c4a22`, `#5a2a1c` | Lamp posts, coats, straps, carts, boats |

**Rules.**
1. **Warm is safe and yours; cold is theirs.** A foe never glows amber. A keeper skill never glows blue.
2. A foe on fire shows amber, because that is the keeper's fire on it (built: `foe.gd` `_burning`, drawn in each foe's `_draw()`).
3. The bold swarm's red rim (`wickling.gd:210`, `Color(0.9, 0.45, 0.4)`) is off-palette and reads as warm. **Proposed:** replace it with a brighter `#a3bcd4` rim and a faster wobble.
4. **Watch item:** Plain loot uses `#a3bcd4` too (GAME_PLAN §10). Loot glints are small, still sparkles; telegraphs are lines, rings and fills. That should be enough to tell them apart. The M3 playtest should check.

### 1.5 Lighting and fog

- **Lights:** `PointLight2D` only for the hand lamp, lamps and WayLamps (GAME_PLAN §15). The keeper's fire lights the fog as small fog lights (group `light_points`, `proto/kl-m1a-fix:scripts/player/skills/fire_bolts.gd:8`).
- **Foes are not lights.** Cold glows (nest seams, eyes, a Spitwick's throat) never clear fog and never count as light. Light means shelter (GAME_PLAN §1, pillar 2).
- **Foes live on the fog layer** so they show as silhouettes in the dark (`wickling.gd:12`). In fog you see only eyes and rim. In light you see their full colours.
- **Telegraphs draw above the fog and above foes.** A wind-up hidden by fog is not a wind-up.
- **Lures through the fog** keep the plan's six looks (GAME_PLAN §7): pale eye pairs (pack), slow cold glow (nest), one big eye pair with a pale ring (elite or mid-boss), small glint (loot), red-amber pulse (unlit old lamp, built), tall still shape (WayLamp).

### 1.6 Readability rules for a dark game

1. **Silhouette test.** Fill each sprite with one colour at 1x. You must still tell its class: blob, drip, plated blob, cluster, boulder, guardian.
2. **Eyes are the anchor.** Every creature with a face has its eyes at `#a3bcd4`, at least 2x2 source px, drawn above the fog. The Fogstilt is the one exception (PLAN_NPCS_ENEMIES suggests no eyes).
3. **Value beats hue.** In the dark, brightness carries meaning. Threat cues are the brightest cold things on screen; fire is the brightest warm thing.
4. **A soft ground shadow** (`#0b0e1a` at 50%, an ellipse) under every floater, so you can see where it is.
5. **Hold the key pose.** A wind-up holds one readable pose for most of its time. The strike is 1-2 frames. The recovery is long and slumped: that is the "hit me now" window.
6. **Shape, colour and sound.** Every tell uses at least two of the three, so colour is never the only cue.
7. **Reduce flashes** (built on M1a: `Settings.flash_mult()`, used in `fire_bolts.gd` `_draw()`) dims flashes and pops. It never hides a telegraph; it swaps the commit flash for a solid colour change.

---

## 2. Creature concept briefs

Each brief gives silhouette, palette, personality and movement, fog readability, and an animation list. "f" is frames; "fps" is the playback rate. Wind-up animations are stretched to the tuning value at run time (§6.3), so the art never sets the timing.

**The family idea.** Every creature is a piece of the Soul of the Wick (STORY §2: "small pieces of the Soul of the Wick", "moths turned inside out"). They share one trait: dark smoke bodies with pale eyes. Each region bends that shape toward its place: ash in the Hollow, water in the marsh, torn cloth on the Ridge, stilts in the shore fog.

### 2.1 Wickling (timid, brave, elite)

Built: `scripts/enemies/wickling.gd`. 3 hp, 65 px/s, chill by touch (30 warmth/s). About half are timid (`kl_timid_share`).

**Shape language.** A soft, upside-down teardrop of smoke. It is wide at the bottom, with a wisp trailing below. Two small square eyes. Round = melee, close range.
- **Timid:** hunched and low. Eyes set low, wisp tucked under. It sways side to side at the light's edge.
- **Brave:** taller, leaning forward. Eyes higher and wider apart. Two wisps rise from its back like moth wings made of smoke. This lets the player see which ones will walk into light (DESIGN §8.1).
- **Elite (Shelled Wickling):** the same body at 24x24, wearing a dead, cold lantern as its shell: a grimy glass cage with a hanging ring on top. The two eyes always glow through the glass, so it never reads as a real lamp or loot. When the shell breaks, the glass cracks, then the cage falls away in pieces. Heavier, slower bob. It ignores light (built, `foe.gd:230`). *Concept reference: owner's Gemini sheet v2, 2026-11-27, kept outside the repo.*

**Palette.** Body `#0b0e1a` and `#141a2e`; rim `#36507a`; eyes `#a3bcd4`; elite lantern shell: dark, grimy glass `#4a6a94` and `#6d8fb3` with `#36507a` frame and `#a3bcd4` cracks; no white or pale fill, so it is never the brightest thing on screen.

**Personality and movement.** Hungry, not cruel. They bob on a slow sine (built wobble, `wickling.gd:200`). Wandering is aimless; hunting is a straight, eager drift. When hit, small ones flinch and flee (`_on_hurt`, `wickling.gd:75-78`).

**In the fog.** Eye pairs, and a faint rim that pulses. Eyes go brighter while hunting (built, `wickling.gd:213`). Timid and brave differ by eye height and wing-wisps, visible even as a silhouette.

| Animation | Frames | fps | Notes |
|---|---|---|---|
| idle (float) | 4 | 6 | Bob and wisp sway |
| move (drift) | 4 | 8 | Leans into the direction; flip for left |
| notice | 2 | 8 | Eyes flare when it starts hunting. Sound slot `notice` |
| latch (its "attack") | 3 | 10 | Reaches two smoke tendrils out; plays before the drain starts (§4.3) |
| drain loop | 2 | 6 | While touching the keeper |
| flee | 2 | 10 | Stretched, eyes narrowed |
| burn in light (brave) | 3 | 10 | Amber edge creeping in |
| hurt | 2 | 12 | Plus the built white flash |
| death (unravel) | 5 | 12 | Smoke pulls apart; the eyes go last. *Suggestion:* a small pale wisp drifts toward the Still Lake |
| spawn (hatch or called) | 3 | 10 | Rises from a cold glow |
| smother (on a mirror) | 2 | 6 | Kept for the Lake (GAME_PLAN §6) |
| **Elite extras:** shell crack | 3 | 12 | Plates split; shards fall |
| **Elite extras:** shell-broken idle and move | 4 + 4 | 6 / 8 | Same body, no plates |

### 2.2 Spitwick

Built: `scripts/enemies/spitwick.gd`, `spit_projectile.gd`. 4 hp. Keeps 190-250 px away and spits.

**Shape language.** A tall, narrow drip of shadow, pointed at the top, with a pale throat sac. Tall and pointed = ranged. It stands upright, unlike the Wickling's slump. The code shape is close already (`spitwick.gd:55`).

**Palette.** Body `#1d2745`, rim `#36507a`, throat sac `#4a6a94` that swells to `#a3bcd4` in the wind-up. Spit `#a3bcd4` with a white core.

**Personality and movement.** Wary and fussy. It skitters back when you close in (built `kl_spit_retreat_speed`) and creeps forward when you're far.

**In the fog.** Eyes plus the throat glow. During a wind-up the throat is the brightest cold thing nearby.

| Animation | Frames | fps | Notes |
|---|---|---|---|
| idle | 4 | 6 | Sac breathes |
| move (skitter) | 4 | 10 | |
| wind-up | 4 | stretched to `kl_spit_tell` | Head tilts back, sac swells and glows. Sound slot `windup` |
| attack (spit) | 2 | 14 | Snaps forward. Sound slot `release` |
| recover | 2 | 8 | Sac empty and dim |
| hurt / death | 2 / 5 | 12 / 12 | Death: the drip collapses into a puddle that fades |
| **Spit** (8x8) | 2 + trail | 12 | Wobbling cold drop; splash 3 f at 16x16 on a hit |

### 2.3 Nests

Built: `scripts/enemies/wick_nest.gd`. 12 hp; only a lamp's core burns it; hatches 3 Wicklings every 10 s while you are within 320 px.

**Shape language.** A low, wide cluster of dark pods, like a clutch of smoked eggs grown into the ground. Low and wide = a thing, not a creature. It never moves.

**Palette.** Pods `#141a2e` and `#1d2745`; seams `#4a6a94` pulsing to `#6d8fb3`; two dim eyes in the largest pod. Burning seams turn amber (the core's fire).

**In the fog.** A slow cold glow (the lure, GAME_PLAN §7). The pulse is slower than any foe's, so a nest never reads as a pack.

| Animation | Frames | fps | Notes |
|---|---|---|---|
| idle pulse | 4 | 3 | Slow |
| pre-hatch swell | 4 | stretched to the hatch tell (§4.3) | Pods bulge; seams brighten |
| hatch | 3 | 10 | Pods split; Wicklings rise (their spawn animation) |
| burning (in a core) | 3 | 8 | Seams amber, smoke |
| death (burned out) | 6 | 10 | Collapses to an ash ring |
| ash ring (decal) | 1 | — | *Proposed:* stays on the ground, so cleared ground looks cleared (pillar 5) |

### 2.4 The Clinker (mid-boss) and its region variants

Built: `scripts/enemies/clinker.gd`. A fixed mid-boss; sleeps on its post; rolls after a tell; shell grows back.

**Shape language.** A heavy lump of cooled furnace slag that curls into a ball. Flat-bottomed when resting, round when rolling. A ridge of pale plates along its back. Eyes under a heavy brow. Heavy and round = a charger.

**Palette.** Body `#141a2e` and `#1d2745`; plates `#6d8fb3`; cracks between plates `#4a6a94`; eyes `#a3bcd4`.

**Personality and movement.** Slow, stubborn, territorial. It trundles (built `kl_clinker_speed` 40), then curls and rolls fast (280 px/s). After a roll it should be dizzy for a moment (proposed, §4.3).

**In the fog.** One larger eye pair with a pale ring (the elite / mid-boss lure). Asleep, its eyes are closed and only the plates catch the light.

**Variants** (GAME_PLAN §8.2; each a recolour plus one detail):
- **Mire** (Reedmarsh): wet sheen (`#4a6a94` highlights), drips; its roll leaves a lane of chilling water (a cold ground decal).
- **Downwind** (Ridge): torn fins along the plates that stream with the wind.
- **In fog** (Lakeshore): plates drawn only inside a mirror beam; outside it, just the eyes.

| Animation | Frames | fps | Notes |
|---|---|---|---|
| sleep | 2 | 2 | Eyes shut |
| wake (uncurl) | 4 | stretched to `kl_clinker_wake_time` (new) | Sound slot `notice` |
| idle / walk (trundle) | 4 / 4 | 6 / 8 | |
| wind-up (curl) | 5 | stretched to `kl_clinker_roll_tell` | Tucks in; plates close; eyes stay visible to the last frame |
| roll loop | 4 | 16 | A full turn |
| recover (dizzy) | 4 | stretched to `kl_clinker_recover` (new) | Uncurls, wobbles |
| hurt / shell crack | 2 / 4 | 12 / 12 | |
| death | 6 | 10 | Cracks open; the smoke inside escapes |

### 2.5 The Ashbrood (Hollow guardian)

Built: `scripts/enemies/ashbrood.gd`. Two phases: in the WayLamp's bowl (ash puff, adds), then dives at lamps. Phase 3, "last of the brood", is PLANNED (M2).

**Shape language.** A hunched brooding mass of ash with two broad, ragged ash wings folded over its brood. A heavy hooded head. Big and rounded on top, ragged at the edges. It is the first thing that looks like it *lives* in a place: it sits in the WayLamp's cold bowl like a nest. It broods over the WayLamp's **last ember**, a small amber glow in the bowl under its wings (owner, 2026-11-27): the lamp's light, never the creature's. Head: bird-like or beak-skulled, never a hood, so it isn't person-shaped like the keeper.

**Palette.** Lighter than the Wicklings, because it is ash: `#28385e` and `#36507a`, with `#4a6a94` feather edges; shell plates `#6d8fb3`; eyes `#a3bcd4`. Ash motes drift off it at all times.

**Personality and movement.** Protective and heavy. Phase 1 it guards and calls its brood. Phase 2 it is angry and hunts your light.

**In the fog.** The arena is near a WayLamp, so it is rarely in deep fog. The drifting ash motes show its edge.

| Animation | Frames | fps | Notes |
|---|---|---|---|
| idle in bowl | 4 | 5 | Wings breathing |
| puff wind-up (inhale) | 5 | stretched to `kl_ashbrood_puff_tell` | Wings rise, body swells |
| puff release | 4 | 12 | Plus the ash-ring FX |
| call adds | 4 | stretched to `kl_ashbrood_add_tell` (new) | Head up |
| phase change (leaves the bowl) | 6 | stretched to `kl_ashbrood_phase_pause` (new) | |
| dive wind-up | 5 | stretched to `kl_ashbrood_dive_tell` | Crouches; wings back; eyes lock on the target |
| dive travel | 3 | 14 | A streak with an ash trail |
| land | 3 | 12 | Ash splash |
| sit (snuffing a lamp) | 4 | 4 | Slumped, eyes dim: the open window |
| hurt / death | 2 / 8 | 12 / 10 | Death: collapses into a heap of cooling ash |
| *Phase 3 (M2):* frantic idle, cracked wings | TBD | | Designed with M2 |

### 2.6 Reedmarsh creatures (M5)

**Slowwater.** A flat shape under the water: a slow V of ripples with two pale eyes just above the surface (PLAN_NPCS_ENEMIES). Low and flat = it is the ground. Palette: `#1d2745` under `#4a6a94` ripples, eyes `#a3bcd4`. Patient, sly. In fog: only the ripple V and the eyes. *Proposed grab tell:* a ring of ripples closes in on your feet for 0.6 s (`kl_slow_grab_tell`, new) before it holds.
Frames: ripple idle 4, follow 4, grab wind-up 3 (stretched), grab hold 2, let go 3, burned/flee 3.

**Fenlight.** A false lure that bursts (GAME_PLAN §8.2). It imitates a loot glint, badly: its glint drifts a little and flickers on the wrong beat. Real caches never move. Palette: a pale glint with a `#36507a` smoky core you see only up close. *Proposed burst tell:* within 64 px it swells cold for 0.8 s (`kl_fen_burst_tell`, new), with the blast ring shown at full size. Frames: lure flicker 4, notice 2, swell 4 (stretched), burst 4, fade 3.

**The Sump (guardian).** Under the water until Reservoir light forces it up. Shape: a wide, flat, drowned bulk, like a sluice mouth lined with weed, with a broad lid of a head that rises out of the water. Eyes set wide apart. 48x48 for the risen part; only ripples and eyes show while it's under. Palette: `#141a2e` body, `#4a6a94` wet edges, weed `#28385e`. Slow, heavy, tidal. *Attacks are not designed yet* (M5). Proposed tells to design from: "high water" (a wet ring spreads across the arena floor before it rises, 1.2 s); a surge (a lane of raised ripples, 1.0 s).
Frames (first pass): submerged ripples 4, rise 6, idle risen 4, wind-ups 5 each, attacks 3-4 each, sink 5, hurt 2, death 8.

**The mire Clinker:** see §2.4.

### 2.7 Windward Ridge creatures (M6)

**Gutterkite.** A ragged strip of dark like a torn kite, with two small pale eyes on its leading edge (PLAN_NPCS_ENEMIES). Wide and thin = it flies. 32x16. Palette `#141a2e` with `#36507a` torn edges. Flighty, rides the gusts. In fog: the eyes and a ground shadow that moves faster than anything else. *Proposed dive tell:* it folds and its eyes flare for 0.6 s; its ground shadow shrinks onto the target (`kl_kite_dive_tell`, new). Frames: flap 4, glide 2, fold (wind-up) 3, dive 2, snag on a Hooded Lamp 3, burn 2, death 4.

**The Galekite (guardian).** Out of reach until it snags on a Hooded Lamp. A great torn sail of dark, many strips stitched by cold threads, with a pale eye pair at its centre. 64x32. Palette as the Gutterkite, plus `#6d8fb3` threads. Proud, wheeling, loud. *Attacks are not designed yet* (M6). Proposed tells: a gale (wind streaks across a marked band, 1.2 s, then a push); a dive (shadow first, 1.0 s). Frames (first pass): wheel 6, gale wind-up 5, gale 4, dive wind-up 5, dive 3, snagged 4, hurt 2, death 8.

**The downwind Clinker:** see §2.4.

### 2.8 Lakeshore creatures (M7)

**Fogstilt.** A very tall, thin shadow on stilt legs, still as a heron. You see it only against beams. No eyes (suggestion from PLAN_NPCS_ENEMIES). 16x32. Palette: `#0b0e1a` body with a `#36507a` edge only where a beam touches it. It never touches the keeper (PLAN_LAKESHORE §6.1), so it has no attack tell. Its "threat" is cutting beams: show the fog thickening around it as a slow cold swirl. Frames: still 2, wade 4, step away 3, unravel 3 (from PLAN_NPCS_ENEMIES).

**The Tallest (guardian; first cut).** 32x64. A Fogstilt grown huge, with a pale eye pair high up where its head would be. Moves very slowly. *Attacks not designed.* Proposed tells: a stilt stomp (a landing circle, 1.2 s); still fog (a ring of fog closing in, 1.5 s). Frames (first pass): still 2, wade 4, stomp wind-up 5, stomp 2, fog call 5, hurt 2, death 8.

**The fog Clinker:** see §2.4.

### 2.9 The Soul of the Wick (finale, M8)

STORY §2: "a coil of black that moves like smoke under water, with big pale eyes". "It", never a name. GAME_PLAN §8.3 gives three phases.

**Shape language.** Not one sprite, but a set of parts (proposed): a coil of thick segments wrapped around the great lamp, tendrils that sweep the island, and one pair of big pale eyes. Every part moves slowly, as if under water. It is the only thing in the game that is bigger than the screen's middle third.

**Palette.** The deepest blacks, `#0b0e1a`, with `#1d2745` folds. The eyes are `#a3bcd4` at their largest. Coil shells (phase 1) are `#6d8fb3` plates. Where it has drunk light, a faint amber shows deep inside the coil, very dim: the light it took (*suggestion*; it is the one place amber sits inside the dark, and it should be hard to see).

**Personality.** Silent and patient, then desperate. It never speaks.

**In the fog.** The island is lit by beams, so it reads against them. The eyes are always visible.

| Part / animation | Frames | Notes |
|---|---|---|
| Coil segment idle | 4 at 32x32 | Chained; slow ripple along the chain |
| Coil shell crack | 4 | Phase 1 |
| Tendril sweep wind-up / sweep | 4 / 3 | Tell in §4.3 |
| Eyes open / blink / close | 3 / 2 / 4 at 32x16 | Phase 3: "until they close, three times" |
| Phase 2 "every flame" | reuses each guardian's tells | Ash puff, high water, gale, still fog |
| Hand-lamp snuff (phase 3) | 5 | The keeper's lamp dims; cold rim on the keeper |
| Retreat and portal | 8 + portal 6 | It sinks; a dark portal opens (DECIDED) |

---

## 3. The keeper and the people

All people are 32x32 frames like the keeper. No portraits (DECISIONS 2026-11-27, cited in ART_CHECKLIST §9). People stand still near a WayLamp and never fight (GAME_PLAN §11), so they need only idle and talk loops.

**People's palette rule.** People are lit by lamps, so they may use warm wood and leather (`#9c4a22`, `#5a2a1c`) and `#d9772b` in lamplight. Only the keeper carries a flame. People's eyes are dark dots, never `#a3bcd4`, so no person reads as a creature.

### 3.1 The keeper

**Now.** The Puny Characters mage (CC0), recoloured (`assets/art/puny/keeper.png`). 8 direction rows. The code uses columns 0-1 for idle and 2-3 for walk (`player.gd:423-426`). No cast, dash or drink frames are used, on this branch or on M1a (`proto/kl-m1a-fix:scripts/player/player.gd:533-535`). *Uncertain:* the sheet's other 20 columns may hold attack frames that fit as stand-ins (ART_CHECKLIST §3 says "spare frames ... may do").

**Concept (for an owner-drawn keeper later).**
- **Costume:** a long travelling coat, hood up, a strap across the chest with the satchel. The hand lamp is held out on a short hooked pole, or in the hand. The lamp is the keeper's identity.
- **Silhouette:** a hood point on top and the lamp off to one side. The coat flares at the hem when they move.
- **Palette:** coat `#36507a` and `#28385e` (cool, so the fire stands out); strap and boots `#9c4a22` and `#5a2a1c`; lamp glass `#ffd27a` with a `#fff1c1` core. The face is in hood shadow.
- **Directions:** 8 today. For an owner-drawn keeper, *proposed* 4 drawn directions (S, N, E, plus diagonals SE and NE) with W and the other diagonals flipped. That is 5 drawn rows instead of 8.

| Animation | Frames | fps | Notes |
|---|---|---|---|
| idle | 2 → 4 | 3 | Built with 2 |
| walk | 2 → 4 | 8 | Built with 2 at 0.16 s a frame |
| Lampfire throw | 3 | 18 | Lamp thrust along the aim; loops while RT is held |
| Fireglobe lob | 4 | 14 | Underarm swing |
| Lance thrust | 3 | 18 | Lamp pushed forward, body leans |
| Beam channel | 2 loop | 8 | Only if the Beam is kept |
| Hearth ring | 4 | 14 | Lamp raised overhead |
| dash | 3 | 20 | Smear frame plus afterimages (§5) |
| drink flask | 4 | 10 | Warm glow rises up the coat |
| hurt (chilled) | 2 | 12 | Cold flash, a frost edge |
| faint | 6 | 8 | Sinks to one knee, lamp set down |
| kindle (touch flame to a WayLamp) | 4 | 8 | |
| rest (at a WayLamp) | 2 loop | 3 | Sitting |
| pick up / interact | 3 | 10 | |

### 3.2 Oswin Reed (story only)

He is never met (STORY §2, §4). He needs no sprite. His traces are art: the crook (the Post Lamp, owner art), his lost coat on the Ridge (a relic icon, M6), the half-built mirror at his camp, and the chalk on the stones. His coat, if drawn, should match the keeper's cut but be older and patched: the keeper follows him.

### 3.3 Amos, trader (the Hollow, M4)

From PLAN_NPCS_ENEMIES: "cheerful and practical. Scared of the dark, and pretending not to be." A handcart.
- **Costume:** a short padded jacket, a wide-brimmed hat, a scarf, a lantern on a hook on the cart (unlit until the cart is free).
- **Silhouette:** the hat brim is the read. Usually shown beside the cart (`assets/art/landmarks/cart.png`, 32x32).
- **Palette:** jacket `#9c4a22`, scarf `#d9772b`, hat `#5a2a1c`.
- **Animations:** idle 4 (rocks on their heels, glances over a shoulder at the dark); talk 2 (hand gestures); trade 2 (leans on the cart).

### 3.4 Maud, old pump keeper (the Reedmarsh, M5)

"Blunt and dry. Guilty, but kind underneath." Ran the pump with Oswin.
- **Costume:** an old keepers' coat like the keeper's, faded; tall boots for wading; a heavy wrench.
- **Silhouette:** stooped, the wrench over one shoulder.
- **Palette:** coat `#4a6a94` faded toward `#6d8fb3`; boots `#5a2a1c`; the wrench `#6d8fb3`.
- **Animations:** idle 4 (leans on the wrench); talk 2; look at the pumphouse 2 (a sideways glance).

### 3.5 Kit, glazier's apprentice (the Ridge, M6)

"Quick, proud of the craft, talks shop."
- **Costume:** a leather apron, rolled sleeves, goggles pushed up on the forehead, a glass pane under one arm.
- **Silhouette:** the goggles and a square pane.
- **Palette:** apron `#9c4a22`; goggles `#a3bcd4` lenses (glass, not eyes: keep them small and square); shirt `#36507a`.
- **Animations:** idle 4 (turns the pane, checks it against the light); talk 3 (points with a tool); kiln 2 (crouched, near the glow).

### 3.6 Ebba, rower (the Lakeshore, M7)

"Quiet, careful, a little superstitious." She waits at the shore end of the jetty by her boat.
- **Costume:** an oilskin coat with the hood down, a knitted cap, an oar held upright.
- **Silhouette:** the tall upright oar.
- **Palette:** oilskin `#28385e` with `#4a6a94` sheen; cap `#d9772b`; oar `#9c4a22`.
- **Animations:** idle 4 (leans on her oar, looks out over the water); talk 2; rowing 4 (for the crossing after the finale, with the boat).

### 3.7 Ivo, mapmaker (two regions held; a cut line)

"Fussy, precise and warm. Measures in paces."
- **Costume:** a long scarf, a satchel stuffed with rolled maps, a measuring rod.
- **Silhouette:** map rolls sticking up from the satchel.
- **Palette:** scarf `#f5a742` (small); coat `#36507a`; maps `#a3bcd4` paper. *Watch:* the maps are pale; keep them square so they never read as eyes.
- **Animations:** idle 4 (paces, counts on fingers); talk 2; unroll map 3.

---

## 4. The telegraph spec

### 4.1 The rhythm of every foe attack

| Stage | What the player sees | Rule |
|---|---|---|
| **Notice** | Eyes flare for 0.3 s; sound slot `notice` | Once, when the foe starts hunting. Not before each attack |
| **Wind-up** | The key pose; the danger marker at full size, filling | Length per class (§4.2). Never shorter than `kl_tell_min` |
| **Commit** | Last `kl_tell_commit` s: the marker flashes (or turns solid with Reduce flashes); aim locks | After commit, nothing retargets |
| **Strike** | 1-2 frames; the hit; sound slot `release` and `impact` | The hit area equals the marker exactly |
| **Recover** | Slumped pose, dimmed eyes | The open window. Long for big attacks |

### 4.2 Standard values by class

| Class | Wind-up | Commit | Recover | Marker | Dodge (on pad) |
|---|---|---|---|---|---|
| Small foe | 0.5-0.8 s | 0.15 s | 0.3 s | Aim line, small target dot | Easy: walk sideways |
| Elite | 0.6-0.9 s | 0.15 s | 0.4 s | Short lane or ring | Easy to medium |
| Mid-boss | 0.8-1.1 s | 0.2 s | 0.6 s | Full-width lane or circle | Medium: walk or dash |
| Guardian | 0.9-1.4 s | 0.2 s | 0.8-4 s | Circles, lanes, edge arrows | Medium to hard |
| The Soul | 1.0-1.6 s | 0.25 s | per phase | Sweeps, rings, the arena edge | Hard, never unfair |

**Global values (new):** `kl_tell_min` 0.5 s, `kl_tell_commit` 0.15 s (bosses 0.2 s), `kl_notice_time` 0.3 s.

**Marker shapes.**
- **Aim line** (single shot): a thin line from the foe to the target, plus a small target dot.
- **Lane** (a charge or roll): a band as wide as the hit (2 x hit range), from the foe to the end of the move.
- **Circle** (an area or a landing): the exact hit radius, edge drawn at full size from frame 1; a fill grows from the centre to the edge as the wind-up runs.
- **Spawn glow:** a cold glow on the ground where something will appear.
- **Edge arrow:** at the screen border, pointing at an off-screen wind-up. It uses the cold colour, pulses at the wind-up rate, and shows the attack's icon shape (line, lane or circle).

**Colours.** All foe markers use `#a3bcd4` with additive white at the commit. The keeper's own markers (the Fireglobe landing ring) stay warm (built: `fire_bolts.gd` `_draw_globe`, amber). So a cold ring means "get out" and a warm ring means "your fire lands here".

**Sound slots** (owner's job, GAME_PLAN §15; Kenney stand-ins until then). Each foe gets up to four: `notice`, `windup`, `release`, `impact`. The wind-up sound starts with the wind-up, so a player who can't see the foe still hears it. Suggested path: `assets/audio/sfx/foe/<subject>_<cue>.ogg` (new folder).

### 4.3 Every built foe attack: now and proposed

Timings are tuning values. "Now" is read from the code on this branch. Nothing in this table is built yet except the "Now" column. **Update (readability step, `proto/kl-readability`):** built; what was built, with the choices made where this table left room, is in DESIGN §8.4.

| # | Attack | Code | Damage now | Telegraph now | Proposed telegraph | Timings | Dodge |
|---|---|---|---|---|---|---|---|
| 1 | Pack wakes | `enemy_pack.gd:26-27`; `wickling.gd:172-173` | — | Eyes turn white while chasing (`wickling.gd:213`) | Notice: eyes flare, the `notice` sound, one pack-wide cue | `kl_notice_time` 0.3 (new) | — |
| 2 | Wickling touch | `wickling.gd:118-125` | 30 warmth/s while touching (`warmth_drain_per_sec`) | **None.** The drain starts on contact | Latch: 3-frame reach, then the drain starts. A frost edge on the keeper while it drains | `kl_wick_latch_tell` 0.25 (new) | Easy |
| 3 | Elite touch | same, x1.6 (`kl_elite_chill_mult`) | 48 warmth/s | **None** | Latch 0.35 s; plates glint when it is within 48 px. *Optional (M2, affixes):* a short lunge, 64 px, after a 0.7 s crouch, with a lane | `kl_elite_latch_tell` 0.35; `kl_elite_lunge_tell` 0.7 (both new) | Easy-medium |
| 4 | Spitwick spit | `spitwick.gd:26-33`, `:62-66`; `spit_projectile.gd` | 12 warmth, -0.1 charge | 0.6 s line and circle that **follow the keeper until release** | 0.7 s: sac swells; the aim follows for 0.5 s, then **locks** for the last 0.2 s (line goes solid, flashes). Spit sprite with a cold trail; splash on a hit | `kl_spit_tell` 0.6 → 0.7; `kl_spit_aim_lock` 0.2 (new) | Easy |
| 5 | Spit from off-screen | `kl_spit_max_range` 500 | as #4 | **None.** 500 px reaches past the screen's 360 px half-height | A Spitwick starts a wind-up only while it is on screen (16 px margin). Otherwise it creeps closer first | `kl_spit_max_range` 500 → 340, or an on-screen check (new) | — |
| 6 | Nest hatch | `wick_nest.gd:176-188`, `:202-203` | 3 Wicklings | A ring fills over the last 1.0 s (a code constant) | Keep the ring. Add swell frames, the `windup` sound, and a 0.3 s fade-in during which hatchlings can't touch you | `kl_nest_hatch_tell` 1.0 (new, from the constant); `kl_hatch_fade` 0.3 (new) | Easy |
| 7 | Clinker wakes | `clinker.gd:47-50` | — | **None.** It acts the frame it wakes | 0.6 s uncurl, eyes open; it can't roll until done | `kl_clinker_wake_time` 0.6 (new) | — |
| 8 | Clinker roll | `clinker.gd:63-78`, `:88-91` | 25 warmth and a shove | 0.8 s: a thin line 260 px long and a ring 56 px out. Direction locks at the start (good) | 0.9 s: a **full-width lane** (44 px, 2 x `kl_clinker_hit_range`) to the roll's end, filling from the Clinker outwards. Curl frames. Commit flash. Then **0.6 s dizzy** after the roll, open to hits | `kl_clinker_roll_tell` 0.8 → 0.9; `kl_clinker_recover` 0.6 (new) | Medium |
| 9 | Ashbrood ash puff | `ashbrood.gd:43-53`, `:142-144` | 15 warmth; charge to 0.1 | 0.8 s: a ring grows from 0 to 140 px and **fades as it grows**, so the edge is faintest just as it hits | 1.0 s: the 140 px edge shown at full size from frame 1; a fill grows out to it; inhale frames; commit flash; an ash ring after. **Fix:** the charge drain should also skip a dashing keeper, as `player.chill()` does (`player.gd:195-197`) | `kl_ashbrood_puff_tell` 0.8 → 1.0 | Medium |
| 10 | Ashbrood adds | `ashbrood.gd:54-63` | 3 bold Wicklings every 8 s, 52 px out | **None.** They pop in | 0.8 s: three cold spawn glows; call frames (head up); the `windup` sound | `kl_ashbrood_add_tell` 0.8 (new) | Easy |
| 11 | Ashbrood dive at a lamp | `ashbrood.gd:65-81`, `:98-104`, `:145-146` | Lamp emptied (M1b: snuffed 8 s); 25 warmth within 36 px of where it lands | 0.7 s: a 240 px line toward the lamp. Then it **jumps there in one frame, at any distance, maybe off-screen** | 1.0 s: a landing circle at the lamp (one radius, 48 px); the lamp flickers; a lane from boss to lamp; **an edge arrow if the lamp is off-screen**; then a visible 0.3 s flight, not a teleport | `kl_ashbrood_dive_tell` 0.7 → 1.0; `kl_ashbrood_dive_travel` 0.3 (new); one landing radius (`kl_ashbrood_hit_radius` 48) | Medium |
| 12 | Ashbrood dive, no lamp | `ashbrood.gd:105-109` | 25 warmth within 48 px of the end | Same 0.7 s line, **240 px long, but the dive goes 200 px** | The lane ends at 200 px with a 48 px landing circle | `kl_ashbrood_dive_dist` 200 (unchanged) | Medium |
| 13 | Ashbrood sits | `ashbrood.gd:66-68` | — | None. It just stops for 4 s | Show it: slumped, eyes dim, shell glow lower. The open window | `kl_ashbrood_sit_sec` 4 (unchanged) | — |
| 14 | Ashbrood phase change | `ashbrood.gd:115-129` | — | A toast; phase 2 starts the same frame | A 1.5 s rise out of the bowl; it can't attack or be hurt; the boss bar ticks to phase 2 | `kl_ashbrood_phase_pause` 1.5 (new) | — |

**Planned attacks** (not built). Each gets its tell when it is built, from the class values in §4.2: Slowwater grab (§2.6), Fenlight burst (§2.6), Gutterkite dive (§2.7), the Sump, the Galekite and the Tallest (§2.6-§2.8), the Soul's tendril sweep (1.2 s lane, edge arrows for the off-screen end) and the eye snuff (1.5 s: the hand lamp flickers cold before it goes). Elite affixes (M2): *Bursting* uses a 0.6 s spawn glow on death; *Lightless* makes a lamp flicker cold 0.5 s before it is snuffed.

### 4.4 Fairness rules

1. **Minimum wind-up.** Every discrete hit (a spit, a roll, a puff, a dive) has at least `kl_tell_min` (0.5 s). The Wickling's touch is a drain, not a hit, but it still starts with a latch cue.
2. **Full size from frame 1.** A marker may fill, brighten or flash. It never grows into place.
3. **The marker is the hitbox.** Its size and shape come from the same tuning values the hit uses. One value per hit, never two (today the dive's line and dive distance differ: row 12).
4. **Aim locks at commit.** Nothing retargets after the commit begins.
5. **No surprise from off-screen.** A wind-up whose foe or landing point is off-screen shows an edge arrow and plays its sound. Small ranged foes don't start a wind-up off-screen at all.
6. **Fog never hides a tell.** Markers draw above the fog layer.
7. **The dash always works.** A dash avoids every hit and every side effect of that hit (the charge drain in row 9 is the one gap today).
8. **A dodge always exists.** Circle radius ≤ (160 px/s walk x wind-up) + 110 px dash. Lanes are no wider than 64 px. Example: the 140 px puff with a 1.0 s wind-up gives 270 px of escape.
9. **A tell budget.** At most two foe wind-ups may end within 0.3 s of each other near the keeper (within 240 px). A boss never stacks two heavy tells. Adds and packs wait their turn. (New: a shared scheduler; *uncertain* how much code that takes.)
10. **Recover after big attacks.** Every mid-boss and guardian attack has a visible recovery, so the player learns "dodge, then punish".
11. **Readable with Reduce flashes on.** The commit flash becomes a solid colour change. No telegraph is removed.
12. **A test checks the table.** *Proposed* `test_telegraphs` (new): every tell value ≥ `kl_tell_min`; every marker radius equals its hit radius.

---

## 5. Skill animation and VFX

**What is built.** On `proto/kl-m1a-fix` (not merged into this branch), the fire is drawn by code with an additive material and no sprites:
- `scripts/player/skills/fire_bolts.gd`: pooled Lampfire, Lance and Fireglobe in flight, trails, glow, the Fireglobe's ground marker and shadow.
- `scripts/fx/fire_fx.gd`: cast flares, impact flashes, sparks, blast rings, kill bursts, light pops that clear fog, scorch marks. Reduce flashes applies.
- `scripts/player/skills/burning_ground.gd`: the scorched decal with flickering flames.
- `scripts/player/skills/hearth_ring.gd`, `beam.gd`, `lampfire.gd`, `lance.gd`, `fireglobe.gd`, `skill.gd`; per-target hit-stop (`kl_hitstop` 0.06).

**What is missing everywhere:** the keeper's body. There is no cast, dash or drink pose, and no dash visual at all (`proto/kl-m1a-fix:scripts/player/combat.gd` `dash()` only moves the keeper).

**Rule:** fire VFX stay code-drawn and additive unless the owner wants to draw them. They are bright shapes, and code keeps them in step with the hit areas. Owner art goes into poses and icons first.

| Skill | Cast pose | Projectile and trail | Impact | Lingering | Built (M1a branch) | Needed |
|---|---|---|---|---|---|---|
| **Lampfire** (RT) | 3-frame throw along the aim | Warm bolt, short tapering trail, glow | White-gold flash, sparks back along the path, light pop that clears fog | Small scorch on kills | Bolt, trail, flare, impact, pop, scorch (`fire_bolts.gd`, `fire_fx.gd`) | Throw pose. *Optional* 8x8 bolt sprite (2 f) |
| **Fireglobe** (RB) | 4-frame underarm lob | Big globe on an arc, shadow below, a warm landing ring that closes in | Ring flash, camera trauma, hit-stop | Burning ground 3 s, then a scorch | All of it (`_draw_globe`, `burning_ground.gd`) | Lob pose. *Optional* 16x16 globe and 32x32 burning-ground sprites |
| **Lance** (LB) | 3-frame thrust | Thin, near-white streak, fast | Hit-stop per foe, recoil shake | — | Streak, shake, hit-stop (`lance.gd`, `fire_bolts.gd`) | Thrust pose. **A shell-shatter effect:** pale shards, 4 f. Today a cracked shell only plays a sound (`foe.gd` `_on_shell_cracked`), and Lance is the shell-breaker, so this matters |
| **Beam** (optional) | 2-frame channel loop | Three layered lines with flicker | — | — | Yes (`combat.gd` `_draw`) | Channel pose and an end-point splash, only if the owner keeps it |
| **Hearth ring** (optional, Y) | 4-frame lamp raised overhead | — | An expanding warm ring and fill | Foes burn 2 s (amber edge) | Ring, shake (`hearth_ring.gd`, `combat.gd`) | Pose; a short burning-ring decal. Only if kept |
| **Dash** (LT) | 3 frames: crouch, smear, land | Two afterimages at 50% and 25%; a small ember puff at the start | — | — | Movement only | Pose, afterimages, and a cold-proof shimmer that shows the dash avoids hits |
| **Moth-lights** (Y, M5) | 4-frame cupped hands, lamp opened | Three 8x8 moths (2-frame wing flap), warm cores; they orbit, then seek on curved trails | Small warm burst each | — | Not built | All. Branch picks change the look: *Swarm* (5), *Great moth* (one 16x16), *Lit wings* (a faint warm path) |
| **Wheeling flame** (M6) | 3-frame side throw | A 16x16 disc, 4-frame spin, a ring trail; out 280 px and back | Sparks on both passes | — | Not built | All |
| **Flask** (B) | 4-frame drink | — | Warm glow rising up the coat; HUD pip flashes | — | *Uncertain:* not checked on the M1a branch | Pose, glow |
| **Keeper hit** | 2-frame flinch | — | Cold flash and a frost edge | — | Shake on chill ≥ 5 (`player.gd:198-199`) | Flinch, frost |

**Branch picks (M2)** that change a skill's shape need a visible change too: *Twin* (two bolts in a V), *Skip* (a bounce spark), *Comet* (every 4th bolt 2x size), *Fire line*, *Cluster*, *Returning*, *Forked*. Plan one variant per pick when M2 starts.

---

## 6. Production plan

### 6.1 Who draws what, in priority order

Telegraphs and readability first. **P0 needs no drawing**: it is code work on the existing shapes.

| Priority | What | Who | When | Placeholder until then |
|---|---|---|---|---|
| **P0** | The telegraph pass: §4.3 rows 1-14 as code markers, edge arrows, the dash fix, the new tuning values, `test_telegraphs` | Code | After the M1a playtest, before or with M1b | — |
| **P1** | Wickling family: timid, brave, elite (§2.1) | Owner | M1b | Today's code blobs (`wickling.gd` `_draw()`) |
| **P1** | Spitwick and spit (§2.2) | Owner | M1b | Code shapes |
| **P2** | Keeper poses: throw, lob, thrust, dash, drink, hurt (§3.1) | Owner, or Puny stand-ins | M1b-M2 | Code: a lamp flare and a small recoil offset |
| **P2** | Skill, flask and dash icons (ART_CHECKLIST §7) | Owner | M1b-M2 | Code-drawn icons |
| **P3** | Nest and the Clinker (§2.3, §2.4) | Owner | M2 | Code shapes |
| **P3** | Shell-shatter effect (§5) | Code | With P0 | — |
| **P4** | The Ashbrood, including phase 3 (§2.5) | Owner | M2 | Code shape |
| **P5** | People, one per milestone (§3) | Owner | M4-M7 | A recoloured Puny figure |
| **P6** | Each region's creatures, mid-boss variant and guardian | Owner | M5-M7 | Code shapes |
| **P7** | The Soul of the Wick (parts) | Owner | M8 | Code shapes |
| **Later** | Fire sprites (bolt, globe, burning ground), an owner-drawn keeper | Owner, optional | M9 | The built code VFX |

### 6.2 Naming and folders

Everything under `assets/art/`. Lowercase `snake_case`, ASCII only. Subject first, then variant, then animation.

```
assets/art/
  placeholders/               unchanged: lamp drop-ins, incl. the owner's Post Lamp (never moved)
  keeper/                     later; the Puny sheet stays in assets/art/puny/ until then
  creatures/<subject>/<subject>[_<variant>]_<anim>.png
  creatures/<subject>/<subject>.frames.cfg
  people/<name>/<name>_<anim>.png  (+ <name>.frames.cfg)
  fx/<effect>.png             (+ <effect>.frames.cfg when animated)
  fx/telegraph/               optional texture skins for markers
  skills/icon_<skill>.png
  items/, ui/, tiles/, landmarks/   as in ART_CHECKLIST
source/art/<same path>/<subject>.pxo   one Pixelorama file per subject, one tag per animation
```

Examples: `creatures/wickling/wickling_brave_move.png`, `creatures/wickling/wickling_elite_crack.png`, `creatures/clinker/clinker_mire_roll.png`, `people/maud/maud_idle.png`.

**Animation names** (the same everywhere): `idle`, `move`, `notice`, `windup`, `attack`, `recover`, `hurt`, `death`, `spawn`. A foe with more than one attack adds the attack's name: `windup_puff`, `attack_puff`, `windup_dive`. Directions only where needed, as a suffix: `_s`, `_n`, `_e` (W is a flip).

**Note:** ART_CHECKLIST §3 suggests flat paths like `assets/art/creatures/wickling.png`. Those were suggestions. If the owner approves this layout, the checklist rows change to match; I have not edited the checklist.

### 6.3 Sprite sheets and Godot import

**Strips.** One PNG per animation, frames side by side, left to right, equal size, no padding (ART_CHECKLIST "Animation strips"). The frame count is the width divided by the frame width.

**The frames file.** One small `ConfigFile` per subject:

```
[sheet]
frame_size = Vector2i(16, 16)
anchor = "foot"            ; "foot" = bottom-centre, "center" for floaters
offset = Vector2i(0, 0)

[variant.elite]            ; built: a variant's own frame size (the shelled Wickling is 24x24)
frame_size = Vector2i(24, 24)

[idle]
fps = 6
loop = true

[windup]
fps = 8
loop = false
timed_by = "kl_spit_tell"  ; the loader stretches the animation to this tuning value
```

**Import.** PNGs import as `Texture2D`: lossless, no mipmaps, nearest filtering (the project already draws pixel art with hard edges, DESIGN §17). No `.tres` SpriteFrames are saved by hand.

**At run time** (proposed, new code):
- `Art.frames(subject) -> SpriteFrames` reads the frames file, slices every strip it finds, and caches the result.
- A small `FoeSprite` node (an `AnimatedSprite2D`) sits on each foe. Foe scripts call `play_anim("windup")`, never a frame number.
- `timed_by` sets `speed_scale` so the animation lasts exactly the tuning value. Art never sets gameplay timing.
- The keeper moves to the same system: the Puny sheet becomes a frames file with 8 direction rows.

### 6.4 Swapping placeholders without code changes

**Update (readability step):** built for the Wickling family, the Spitwick and the keeper's poses (`Art.frames`, `FoeSprite`; DESIGN §17).

1. Every foe keeps its code-drawn `_draw()` shape as the placeholder.
2. If `Art.frames(subject)` finds no PNG for the current animation, the `FoeSprite` hides and the `_draw()` shape shows. If it finds one, the sprite shows and `_draw()` draws only the overlays.
3. **Overlays always stay code-drawn:** telegraph markers, the shell ring (`foe.gd` `draw_shell`), the burning edge, health arcs. They must match hit areas exactly.
4. The hit flash stays `self_modulate` (built, `foe.gd` `tick_foe`), so it works on sprites with no extra frames.
5. A missing animation falls back: `windup` → `idle`, `recover` → `idle`, `hurt` → the flash only, `death` → the built fade.
6. So the owner saves `wickling_move.png` into `assets/art/creatures/wickling/`, runs the game, and it shows. No code edit, no import step beyond Godot's own.
7. The existing lamp drop-ins in `assets/art/placeholders/` keep working as they do now (same name and size).
8. The docs checker (`tools/check_docs.py`) already wants an ART_CHECKLIST row for each file in `placeholders/`. *Proposed:* extend it to the new folders when they get their first file.
9. **Built:** each strip has its own frame size. A variant's strip reads `[variant.<v>] frame_size`, a plain strip `[<anim>]` then `[sheet]`; a strip's height always wins. `FoeSprite` keeps the foot on the origin for each size.

### 6.5 The sprite pipeline (built, a tool)

`tools/art/sprite_from_sheet.gd` turns one key-pose sheet (a grid on flat magenta, e.g. a generated concept sheet) into strips in the layout above, so the owner touches up key frames instead of drawing every frame. How-to and options: `tools/art/README.md`; example manifests in `tools/art/manifests/`; tested by `test_sprite_tool`.

- It keys, crops and scales each pose (one scale and baseline per variant), snaps to the 14 colours, makes alpha hard, and repairs what 16 px loses: the eyes (`#a3bcd4`), the rim (§1.3) or the outline.
- It makes the cheap frames from a key pose: idle bob and sway, move bob, hurt flash, notice flare, death dissolve (eyes last), spawn, wind-up hold, attack lean. Each rule can be turned off per pose.
- Foes stay cold: a creature snaps to the 8 cold colours. Per cell, `warm = "ember"` keeps fire-coloured pixels amber (the Ashbrood's last ember, owner 2026-11-27); everything else, like the phase-rise flames and the bone skull, snaps cold.
- A strip the owner drew or touched up is never overwritten (only with `--force`). Generated strips are not committed until the owner approves them.
- *Uncertain:* tuned on five generated sample sheets; other sheets may need `eye_threshold`, `gain` or `keep` set per variant. Keeper sheets are drawn facing right only (see the README, "The keeper").

---

## 7. Owner questions

At most six. Each has a recommendation.

1. **Who draws what?** *Recommend:* you draw characters (creatures, the keeper's poses, people) and icons. Code draws the telegraphs, the fire VFX and every placeholder. Your Post Lamp stays the style anchor. Fire sprites are optional for M9.
2. **AI-generated concept images as mood references?** *Recommend:* not by default. The written briefs and your own quick thumbnails should be enough. If you want mood images anyway, keep them private, outside the repo, never traced, never shipped, and never prompted with another game's name or art.
3. **Sprite sizes?** *Recommend:* keep 16x16 at 2x. Small foes 16x16, elites 24x24, nests and mid-bosses 32x32, guardians 48x48 (the Tallest 32x64, the Galekite 64x32), and the Soul built from parts rather than one 48x48 sprite.
4. **The threat colour?** *Recommend:* keep the 14 colours. Foe tells, eyes and spit use pale `#a3bcd4` plus additive white; the keeper's fire keeps the ambers; drop the off-palette red rim on the bold swarm. The alternative is a 15th colour just for danger, which I don't think is needed.
5. **The order of work?** *Recommend:* first the telegraph pass in code (§4.3), after the M1a playtest and before or with M1b. Then the Wickling family and the Spitwick, then the keeper's poses and the icons, then the nest and the Clinker, then the Ashbrood.
6. **The keeper sprite?** *Recommend:* keep the recoloured Puny keeper for now, and add throw, dash and drink poses (Puny stand-ins or yours). Draw your own keeper in M9, in 5 drawn directions with flips instead of 8.

---

## Uncertainties

1. The M1a skill code is on `proto/kl-m1a-fix`; I read it there and did not run it. If M1a changes before it merges, §5's "built" column may drift.
2. The Puny sheet's unused columns may or may not hold usable attack frames.
3. The tell budget (§4.4, rule 9) needs a shared scheduler. Its size in code is a guess.
4. Planned guardians' attacks (the Sump, the Galekite, the Tallest, the Soul) are not designed in the plan. The tells given here are starting points for that design.
5. Pixelorama's export of one strip per animation tag is from memory, not checked in this repo.
6. Whether `#a3bcd4` threats and Plain loot glints are easy to tell apart needs a playtest (M3).
