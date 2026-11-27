# Lantern Keeper: the Lakeshore (draft region)

**DRAFT for the owner's markup, 2026-11-27.** Already decided today (DECISIONS, PLAN §2 and ROADMAP at db283fa): the region itself; the Fogstilt and Ebba moving there; the Ridge keeping the Gutterkite; the Clinker roaming whatever isn't held; and the milestone order M5c, M5d, M5e. Everything else here is a proposal. Nothing is built, committed or published, and the repo is unchanged.

Sources: the docs on branch `proto/waylamps` at db283fa, which includes `main`: STORY.md, DESIGN.md (§3, §4, §8), PLAN_NPCS_ENEMIES.md, DECISIONS.md and ROADMAP.md. Map and rule numbers were checked against `scripts/main/main.gd`, `systems/fog/fog_grid.gd`, `scripts/world/waylamp.gd`, `scripts/player/player.gd`, `systems/story/story.gd` and `systems/tuning.gd`.

How to read it:
- **OWNER n:** lines are choices for the owner. Mark each one yes, no or change. Section 9 lists them all in one table.
- Every in-game text is **DRAFT**. In quoted texts, each line is one line on screen. Notes are signed "- Oswin", with a plain hyphen.
- Goal numbers are as on `proto/waylamps`, with the WayLamp rows. STORY §5's numbers, without those rows, are in brackets.
- (x,y) are tile coordinates. A tile is 32 px.

---

## 0. In short

- **Where:** a small strip of shore below the signal station, about x 66-82, y 9-37. The Still Lake keeps about x 83-111, y 0-44. You come in by the old steps and leave by a causeway.
- **Twist (recommended): thick fog.** Lanterns and the hand lamp clear fog at a quarter of the usual speed. Beams and WayLamps clear it as usual. Ordinary light still works here, slowly. On the Lake it won't work at all.
- **WayLamp:** on the old landing, out in the shallows and out of any lantern's reach, so only a beam reaches it. The great lamp is still the last one.
- **Story:** stillness after the wind. The keepers marked the water every night until it went still. A boat waits in the reeds.
- **Goals:** five new ones after `descend` (22-26). `descend` and `ridge_steps` can stay as built.
- **The Fogstilt** lives here. It rises with the first mirror lit on the shore and stays until the WayLamp kindles. The WayLamp can only be fed through a beam, so every player meets the Fogstilt with beams in play.
- **Ebba** comes back when the shore is held. The boat in the reeds is Ebba's.
- **Milestones** (decided in ROADMAP): M5c, then M5d (the Lakeshore, the Fogstilt, Ebba), then M5e (the Slowwater, the Clinker, Ivo), then the Still Lake. Section 7 gives effort ratings and the M5d playtest questions.

---

## 1. The region

### 1.1 Place in the map

| Area | Tiles (about) | Notes |
|---|---|---|
| The Windward Ridge (built) | x 4-65, y 3-37 | Its east rim is at x 63-65 for y 11-19. The station is at (58,13), its WayLamp at (55,15) and `ridge_steps` at (62,17). |
| The old steps | x 63-67, y 16-18 | A stair 3 tiles wide, cut through the rim. x 63-65 stays Ridge; x 66-67 is the Lakeshore. |
| **The Lakeshore** (new, region 4) | x 66-82, y 9-37 | An oval of about 400 open tiles, about a third of the Ridge (about 1,280). |
| The causeway | x 76-89, y 34-36 | A low stone causeway, 3 tiles wide. The only way on to the Lake. |
| **The Still Lake** (planned, region 5) | x 83-111, y 0-44 | About 900 tiles, the rest of the north-east. |
| Rock | | A line of rock at x 83-84 between the shore and the Lake, open only at the causeway. At least 3 rows of rock above the Reedmarsh. |

**Map check.** The brief puts the Reedmarsh at about y 49-87, but that is the span of its boardwalks. Its soft ground reaches higher. The marsh oval in `main.gd` (centre (80,68), radii (28,24), with its edge wobble) reaches y 42 at x 72-76, and y 43-48 across x 64-95. So the north-east box (x 66-111, y 0-48) isn't quite empty: its bottom-left corner is marsh. The split leaves 4 rows of rock between the shore and the marsh, and 6 between the Lake and the marsh. (The carve was recomputed with the same formula. In the sketch, the new regions are plain ovals.)

Sketch: one character is 2 x 2 tiles. The rock line at x 83-84 is too thin to show at this scale.

```
x      40   50   60   70   80   90   100  110
y  0   ###########################LLLL#####
y  2   r########################LLLLLLLL###
y  4   rrr#####################LLLLLLLLLL##
y  6   rrrrrrr#################LLLLLLLLLL##
y  8   rrrrrrrr########sss####LLLLLLLLLLLL#
y 10   rrrrrrrrrrrr###sssss###LLLLLLLLLLLL#
y 12   rrrrrrrrrTrrr#sssssss##LLLLLLLLLLLL#
y 14   rrrrrrrWrrrrrssssss2s#LLLLLLLLLLLLLL
y 16   rrrrrrrrrrrSrssssssss#LLLLLLLLLLLLLL
y 18   rrrrrrrrrrrrr1ssssssssLLLLLLLLLLLLLL
y 20   rrrrrrrrrrr##sssssssssLLLLLLLLLLLLLL
y 22   rrrrrrrrr####sssssssssLLLLLLLLLLLLLL
y 24   rrrrrrrrr####sssssssssLLLLLLLLLLLLLL
y 26   rrrrrrrrr####sssssssWsLLLLLLLLLLLLLL
y 28   rrrrr########ssssssss#LLLLLLLLLLLLLL
y 30   #############ssssss3s##LLLLLLLLLLLL#
y 32   ##############sssssss##LLLLLLLLLLLL#
y 34   ##############ssssCsssLLLLLLLLLLLLL#
y 36   ###############sssssssLLLLLLLLLLLL##
y 38   ########################LLLLLLLLLL##
y 40   #########################LLLLLLLL###
y 42   ###############mmmmm#######LLLL#####
y 44   ##############mmmmmmmmm#############
y 46   #############mmmmmmmmmmmmm##########
```

r Ridge · s Lakeshore · L Still Lake · m Reedmarsh · # rock · T signal station · W WayLamp (Ridge, Lakeshore) · S `ridge_steps` · 1 `steps_foot` · 2 `water_post` · 3 `boat` · C the causeway's head

**Entering.** You come down the old steps by the signal station. Once the Ridge is held, its WayLamp lights the top of the steps: its light reaches about 13 tiles, and the steps are about 7 tiles away. Halfway down, the wind stops and the thick fog begins. Stepping onto the first Lakeshore tile completes `descend`, and "The Lakeshore" fades in, as region names do.

**Leaving.**
- **On to the Lake:** by the causeway. It starts at the south end of the shingle, at about (76,35), and runs east across the shallows into the Still Lake. Oswin's camp stands at its far end. Until the Lake is built, the causeway ends in rock and fog, as the steps do today, and the `causeway` goal waits on the HUD.
- **Back:** up the steps to the Ridge, any time.
- **By boat:** Ebba's boat, later and only if you want it (section 6.2). No main goal needs it.

Apart from the causeway, the shore's east edge stays closed: rock tiles, drawn as tall reeds. A single way in suits the Lake, as the passage, the climb and the steps do for the other regions. The Still Lake milestone can open more if it needs to.

**OWNER 1:** the split: the Lakeshore at about x 66-82, y 9-37 and the Still Lake at about x 83-111, y 0-44, with the causeway as the one way on, and the name "the Lakeshore". The line between the two can move a few tiles when the Lake is laid out.

### 1.2 The twist

On the Lake, the fog is too thick for ordinary light, and only beams cut it. The shore should be one step toward that.

**Option A: thick fog (recommended).**
- **Rule:** in the Lakeshore, lanterns and the hand lamp clear fog at a quarter of the usual speed (0.2 per second, not 0.8). Beams and WayLamps clear it at the usual speed. Fog comes back at the usual speed.
- **What the player sees:**
  - A new lantern's clear circle takes about 5-25 s to open, not 1-3 s, and stops a little short of its glow: at about 85-90% of its radius, not about 95%.
  - A beam cuts a clean lane in under a second.
  - Things on the ground show up slowly in lantern light and quickly in a beam, so turning a mirror becomes a way to look around.
  - Fog slows walking (as built), so beam lanes become the quick paths. Building needs thin fog, so building along a beam is quicker too.
- **Step toward the Lake:** here ordinary light is slow, and on the Lake it clears nothing. Beams already do the job they'll do there.
- **Not a copy:** every lantern still works, just slowly. Only the WayLamp on the landing needs a beam (1.4).
- **Cost:** S. One number in the fog step for region 4 (`shore_clear_mult` 0.25), plus a tip and Oswin's note. Light radius, mirror catching, building and the Wickling rules don't change.
- **Risks:** it may be too quiet to notice. The hand lamp clears slowly too, so ground you walk through stays foggier.

**Option B: mist off the water.**
- **Rule:** banks of mist roll in from the lake on their own clock, like gusts: 40-70 s of calm, a 5 s warning ("Mist rising"), then a 15 s bank. During a bank, in the Lakeshore only, lanterns and the hand lamp shine at half their radius, and fog comes back twice as fast. Beams and WayLamps are untouched.
- **What the player sees:** every minute or so the shore goes almost dark except for its beams, and then it clears.
- **Step toward the Lake:** for 15 s at a time, the shore is almost the Lake.
- **Not a copy:** it passes, and lanterns work between banks.
- **Cost:** M. A second weather clock, chip, tip and sound, on top of the gusts.
- **Risks:**
  - A second timed weather right after the Ridge's wind feels samey.
  - Halving lantern light drops mirrors out of catching range (90% of a lantern's radius), so chains break in every bank. That's harsh for a warm-up.
  - It also exposes mirrors that DESIGN §8 keeps safe inside healthy light.

**Recommendation: A.**
- It is always on, so the lesson is steady.
- It changes one number in a system that already exists.
- It gives beams a new job, seeing and opening paths, without another clock or HUD chip.
- It never breaks a chain by itself.

Keep B as the fallback if A proves too quiet in the playtest.

**OWNER 2:** the twist: A, thick fog (recommended), or B, mist off the water.

DECIDED (2026-11-27): A, thick fog.

**OWNER 3:** with A, the thick fog stays after the shore is held, as the Ridge's wind does. Recommended: yes. Held lanterns are full anyway, and the WayLamp clears at the usual speed. And the hand lamp counts as ordinary light. Recommended: yes. If walking feels slow in the playtest, let the hand lamp clear at the usual speed.

### 1.3 Terrain, resources and creatures

No new kinds of ground:
- **Shingle** (firm ground): the west half, under the Ridge's cliff. Lanterns stand here.
- **Reed shallows** (soft ground, as in the Reedmarsh): the east half. You wade at 85%, and nothing can be built.
- **The old jetty** (boardwalk): runs from the shingle out into the shallows at about y 26 (x 69-73). Its last stretch is gone, about 8 tiles short of the landing.
- **The old landing** (firm ground): a small stone platform in the shallows at about (81,26), holding the WayLamp. It lies inside the WayLamp's no-build radius.
- **The causeway** (firm ground): see 1.1.
- **Boulders** (rock): about 6 small clusters on the shingle, placed like the Ridge's outcrops. They stop beams, so they shape where mirrors go. They also shelter lanterns from gusts.
- **Wind:** no constant wind; that stays on the Ridge. Gusts blow here as they do everywhere (built).

Resources (placeholder numbers):

| Kind | Spots | Each | Regrows | Where |
|---|---|---|---|---|
| Fuel, labelled "Driftwood" | 8 | 3-6 | 60 s | the shingle and the waterline |
| Scrap | 5 | 3-6 | 75 s | broken planks by the jetty, near the foot of the steps |
| Glass, labelled "Worn glass" (OWNER 4) | 4 | 1-3 | 120 s | the waterline |

That covers the WayLamp (15 fuel) and two mirrors (8 scrap, 6 glass) without a trip back up.

No upgrade finds here: the three satchels and three lamp glasses stay one per built region.

**Creatures:**
- Wicklings, as everywhere. If "more Wicklings far from the hut" is built, keep the shore at the Ridge's level: it's a warm-up.
- The Fogstilt (6.1).
- The Clinker, while the shore isn't held (from M5e).
- No Gutterkite (it needs the Ridge's wind), and no Slowwater (it stays in the Reedmarsh).

**OWNER 4:** worn glass on the shore (4 small spots). DESIGN §3.3 says glass is found only on the Ridge. Recommended: yes, so the shore's mirrors don't need a trip back up. Amos's trade (4 scrap for 1 glass) is the other way, but Amos is at the hut. If no, the player carries glass down from the Ridge.

DECIDED (2026-11-27): yes, a few spots of worn glass on the shore, so its mirrors don't need a trip back up the steps.

**OWNER 5:** no upgrade finds on the shore (recommended).

### 1.4 The WayLamp

- **Where:** on the old landing, about (81,26), out in the shallows and about 8 tiles past the end of the broken jetty.
  - No firm ground or boardwalk lies within 8 tiles of it, apart from the landing itself.
  - A full Post Lamp's light reaches 7 tiles, so no lantern can reach it.
  - A mirror at the jetty's end can, since beams run 11 tiles (13 with Kit's polished mirrors). The boulders make a second angle easy.
- **The rules don't change** (DESIGN §8): reach it with your own light, feed it 15 fuel and hold it for 15 s. A beam already counts as your own light. This is the first WayLamp that only a beam can reach.
- **Feeding:** the keeper wades out to the landing. `waylamp.gd` checks reach each time you feed, so a beam has to be touching the landing at every feed. Once kindling starts, reach isn't checked again.
- **The hold is harder here.**
  - At the other WayLamps, a lantern just outside the no-build radius covers the keeper, so the ward refills during the hold (DESIGN §8's playtest note).
  - No lantern light reaches the landing. So the ward runs on the hand lamp's charge: about 4 s from full, about 6.5 s with all three lamp glasses. Warmth doesn't refill either (`player.gd`, `in_lantern_light`).
  - Beams help. They burn Wicklings in about a second, and Wicklings can't sense them, so a second beam across the landing guards it.
  - Oswin's note asks for that second beam, and the Fogstilt leaves when kindling starts (6.1).
  - If the hold is still too hard: a smaller swarm here (2 instead of 4).

**`waylamp_shore`**, "WayLamp of the Lakeshore" (on the old landing, out in the shallows). DRAFT
> A WayLamp on the old landing, out in the shallows. Still water stands around its foot.
> Cut into the base: WHILE THIS BURNS, THE SHORE IS KEPT.
> In chalk: No lamp can reach it from the shore. Send a beam, and one more to keep it. - Oswin

Under the note, the game adds the three lines it shows under every WayLamp note, starting "Reach it with your own light, then feed it 15 fuel."

- **Banner** (DRAFT): "The Lakeshore is held". It is 21 characters, so "The Windward Ridge is held" (26) stays the longest.
- **Arrival line for people** (DRAFT): "Someone has come back to the Lakeshore."
- **Is the great lamp still "the last one"?** Yes. The shore's WayLamp is the fourth, and the great lamp stays the fifth and last. STORY §11 and DESIGN §8 only need the shore added to their lists. This doesn't settle PLAN §7's open question of whether the great lamp holds the Lake like a WayLamp.

**OWNER 6:** the WayLamp stands on the old landing, where only a beam reaches it (recommended). The alternative is the shingle, where a lantern can reach it, as in the other regions. The Fogstilt fix in 6.1 relies on the landing.

DECIDED (2026-11-27): try it on the old landing, reached only by a beam; judge it in the M5d playtest.

REOPENED (2026-11-27, later): after the WayLamps playtest the owner wants WayLamps to just take fuel, with no lantern having to reach them. A beam-only landing goes against that. Rethink this with the core-loop rethink (for example: the landing is reached by walking a beam-lit path through the thick fog).

---

## 2. Landmarks (DRAFT)

There are three, from the steps out along the shore. One of them is the planned Lake landmark `boat`, moved here because the boat is Ebba's. Ebba stands at least 3 tiles from each of them and from the WayLamp (PLAN §3).

**`steps_foot`**, "The foot of the steps" (Lakeshore, north-west, about (67,18)). DRAFT
> The steps end on wet shingle. The wind does not follow you down.
> On the last step, a chalk arrow points along the shore.
> Under it: The fog is thick down here. A lamp only thins it. A mirror cuts it. - Oswin

With Option B, the last line becomes: "Under it: Mist comes off the water here. Keep a mirror lit. It cuts through. - Oswin"

**`water_post`**, "The water post" (Lakeshore, in the shallows, about (79,14)). DRAFT
> A tall post in the shallows. The keepers cut a line where the water stood, one line a night.
> The lines stop. The water still stands at the last one, exactly.

**`boat`**, "A boat in the reeds" (Lakeshore, in the reeds south of the landing, about (79,31); moved from the Lake). DRAFT
> A boat tied in the reeds, half full of rain. The oars are still in it.
> Past the reeds the fog is too thick to row through.

The planned Lake text was "A boat half full of rain, the oars still in it. / Past the reeds the fog is too thick to row through." Only the first line changes, to say where the boat is. Like the lantern rack, `boat` has no goal. It is the target of Ebba's errand.

**Counts:**
- Story landmarks: 13 built, plus 7 planned for the Lake (8 without `boat`), plus these 3, makes 23.
- With Ivo's 3 survey stones: 26, one over the 15-25 target.
- With the four WayLamp notes as well: 30. With the six upgrade finds as well: 36.
- This is PLAN §3's open question, with new numbers.

**OWNER 7:** move the planned `boat` landmark from the Lake to the Lakeshore, so there is one boat, and it is Ebba's.

**OWNER 8:** the landmark count. Either count Oswin's trail and the story marks only, not errand props like the survey stones (23, recommended), or count the stones and drop `water_post` (25).

---

## 3. Goals

There are five new goals. With the WayLamp rows, the goals run 1-32: 21 built, 5 for the Lakeshore and 6 planned for the Lake. Without the WayLamp rows they run 1-28.

| # | id | HUD text (DRAFT) | Chars | Completes when | Pointer target |
|---|---|---|---|---|---|
| 20 [—] | `kindle_ridge` | Kindle the WayLamp by the signal station | 40 | (built) | `waylamp_ridge` |
| 21 [18] | `descend` | Take the old steps down to the lake | 35 | Enter the Lakeshore (region 4) | `ridge_steps` |
| **22 [19]** | `steps_foot` | Find Oswin's mark below the steps | 30 | `steps_foot` read (entry 16) | `steps_foot` |
| **23 [20]** | `shore_beam` | Cut through the fog with a beam | 31 | A Mirror Post in the Lakeshore is lit | — |
| **24 [21]** | `water_post` | Find the post in the shallows | 29 | `water_post` read (entry 17) | `water_post` |
| **25 [—]** | `kindle_shore` | Kindle the WayLamp on the old landing | 37 | The Lakeshore is held (entry 18) | `waylamp_shore` |
| **26 [22]** | `causeway` | Follow the causeway out over the water | 38 | Enter the Still Lake (region 5). The Lake isn't built yet, so this goal waits on the HUD, as `descend` does now. | `causeway`, a named spot at the causeway's head (like `passage`) |
| 27-32 [23-28] | `camp`, `first_beam`, `reach_island`, `great_lamp`, `drive_off`, `keep_valley` | planned, unchanged | | | |

- The order follows the walk: the foot of the steps (north-west), the post (north-east), the landing (east) and the causeway (south-east).
- `descend` needs no code change. It checks `visited.has(4)`, and the Lakeshore takes region id 4. Only its comment, "the Still Lake (not built yet)", changes. The Still Lake becomes region 5, which `causeway` checks.
- The pointer is off after the Reedmarsh by default (DECIDED). Every new goal has a target except `shore_beam`, a build goal like `build_mirror`.
- `shore_beam` only counts a mirror standing in the Lakeshore. Most players' first mirror will face the landing, or sweep the shallows for the post.

**DRAFT changes to built text**
- `descend` (goal 21): **no change recommended.** The steps still go down to the lake, and the Lakeshore is its shore. If the owner wants the HUD to name the new region instead: "Take the old steps down to the shore" (36).
- `ridge_steps`: **no change recommended.** "Below, the fog does not move, even in the wind" already describes the shore's thick, still fog. An optional third line gives a first hint of the Fogstilt: "Somewhere below, a boat knocks once against wood."
- Journal entry 15 (built on `proto/waylamps`, text approved 2026-11-27): "The ridge is held. Nothing comes up the steps now, and only the lake is left."
  - With the shore in between, "only the lake is left" comes one region early.
  - **Recommended:** "The ridge is held. Nothing comes up the steps now." The words "only the lake is left" move to entry 18.
  - "Nothing comes up the steps" still holds: the Ridge WayLamp's light covers the top of the steps.

**OWNER 9:** the five goals, their order and the numbering (1-32 with the WayLamp rows).

**OWNER 10:** keep `descend` and `ridge_steps` as built (recommended), or take the changes above. And trim entry 15 (recommended).

---

## 4. Journal entries (DRAFT)

The new entries are numbered 16-18, after the WayLamp entries (13-15), so the built numbers (1-8, 13-15) and the planned ones (9-12) don't move. The journal lists entries in the order they are written.

| # | Written when | Title | Entry (DRAFT) |
|---|---|---|---|
| 16 | `steps_foot` read (goal 22) | The shore | *The wind stopped on the steps. The fog below is thick and still, and nothing moves on the water.* |
| 17 | `water_post` read (goal 24) | The water post | *The keepers marked the water every night. The marks stop on one night, and the lake has not moved since.* |
| 18 | `kindle_shore` done (goal 25) | The shore WayLamp | *The landing is lit again. The boats came in here once. Now only the lake is left.* |

---

## 5. Tips (DRAFT)

Each is shown once, like the built tips. The longest built tip is 85 characters.

| id | Trigger | Tip (DRAFT) | Chars |
|---|---|---|---|
| `thick_fog` | The first lantern lit in the Lakeshore | The fog is thick here. Lanterns only thin it. A beam cuts straight through. | 75 |
| `fogstilt` | The first time a Fogstilt cuts a beam | Something tall is cutting your beam. Cross two beams on it to send it off. | 74 |

With Option B, `thick_fog` becomes `mist`, triggered by the first mist warning: "Mist is coming off the water. Lanterns shrink in it. Beams cut through." (71)

`fogstilt` is new. Ebba's tip ("One light moves them. Two send them off.") used to teach the counter, but Ebba now arrives after the Fogstilt has gone.

---

## 6. The Fogstilt and Ebba at the Lakeshore

These replace parts of PLAN_NPCS_ENEMIES: "Moved from the Lake" in §1, the Fogstilt part of §2, the Ebba part of §3, and the table rows that name them.

### 6.1 Fogstilt (the Lakeshore). Counter: mirror beams

- **Look:** unchanged. A very tall, thin shadow on stilt legs, still as a heron. You see it only against beams. No eyes, as the plan suggests.
- **Home:** the Lakeshore's reed shallows. It rises out of the deep reeds at the shore's east edge.
- **Appears:** once a Mirror Post is lit in the Lakeshore, within about 12 tiles of that beam. The counter comes first: the Mirror Post is unlocked at the station, before the steps.
- **Stops:** when the Lakeshore is held. Like every creature, it fades away with no drops, if the held-region rule in PLAN §2 is approved. No Fogstilts come to the Ridge any more.
- **Behaviour:** unchanged. It wades toward the nearest beam and stays out of all light. Fog thickens around it, so a beam that passes within about 2 tiles fades out short, and the rest of the chain goes dark.
- **Near WayLamps** (this applies PLAN §2's rule, "WayLamps are left alone"):
  - It never comes within 5 tiles of a WayLamp.
  - It can cut the beam you need to feed the landing's WayLamp. While it stands in that beam's way, you can't feed.
  - When kindling starts, it sinks back into the water, so the hold belongs to the Wicklings alone.
- **Threat:** mirror chains, including the one that feeds the WayLamp.
- **Counter:** one beam on it makes it step away, and two beams crossing on it unravel it. The way out to the landing and the boulders make a second beam easy, and Oswin's note asks for one.
- **Light and no game over:** unchanged. It never touches the keeper or a mirror, and drains nothing. When it leaves, the beam reaches again.
- **How many:** one at a time (`stilt_max` 1). After one unravels, the next rises about a minute later (`stilt_respawn_sec` 60), until kindling starts.
- **Art:** unchanged (16x32; a 4-frame wade and a 3-frame unravel).
- **Knobs:** as planned (`stilt_max`, `stilt_speed`, `stilt_reach`, `stilt_beam_cut`, `stilt_unravel_sec`), plus `stilt_respawn_sec`. The WayLamp distance reuses `waylamp_clear_radius` (160 px, 5 tiles).
- **Effort:** M, as planned (a beam-length hook in the Mirror Post and a two-beam check). The move adds a spawn rule and the WayLamp distance.

**The short window, fixed.** On the Ridge, the Fogstilt came up at the station. The Ridge's WayLamp, about 4 tiles from the station, was the very next goal after the first lit mirror, so most players would have met it for a minute or less. On the shore:
1. It rises with the first lit mirror there (goal 23). The shore's WayLamp comes two goals later (goal 25).
2. The goal in between, the water post, stands out in the shallows in thick fog, where a beam is the quick way to see.
3. Only a beam reaches the landing, and the beam has to touch the landing at every feed. So every player who holds the shore has had a beam in play while a Fogstilt was about, and most will have to move one on.
4. The `fogstilt` tip teaches the two-beam answer the first time a Fogstilt cuts a beam.

Rough time with it: 5-10 minutes, instead of about one.

**Where they live** (replaces the table in PLAN §2):

| Creature | Region | Appears | Stops when |
|---|---|---|---|
| Slowwater | the Reedmarsh | on the first visit | the Reedmarsh is held |
| Gutterkite | the Windward Ridge | once the Hooded Lamp is unlocked | the Ridge is held |
| Fogstilt | the Lakeshore | once a mirror is lit there | the Lakeshore is held (it leaves when kindling starts) |
| Clinker | any region not yet held | once the keeper reaches the Ridge | that region is held |

This also answers the worry about a busy Ridge. The Ridge keeps the Gutterkite, plus the Clinker only while the Ridge isn't held.

**OWNER 11:** its home on the Lakeshore is decided. The details: it rises with the first mirror lit there, keeps 5 tiles from any WayLamp, may cut the beam that feeds the landing (recommended: yes, that is the lesson), and sinks back when kindling starts.

**OWNER 12:** Fogstilts also wade the Still Lake until the finale. Decide this with the Lake, together with PLAN §2's question about Fogstilts in the finale. A yes makes Ebba's line about the tall ones useful (6.2).

### 6.2 Ebba Tarn, rower (the Lakeshore; was the Reedmarsh)

- **Who:** rowed for the keepers, out to the island and back. The boat in the reeds (`boat`) is Ebba's.
- **Where, when, why:** on the shore end of the old jetty, about (69,26), once the Lakeshore is held. Ebba saw the landing lit again and came back, but still won't row into the still fog. The old plan kept Ebba away from the lake; now Ebba comes back to its shore and stops at the water.
- **Errand, "Show me the boat":** get your own light onto the boat in the reeds, as for a WayLamp: a lantern's light or a beam (the hand lamp doesn't count). The shore is held by then, so it's a calm errand.
- **Fragment:** on the night it went dark, the lake went still. Ebba tied up the boat and walked away. Oswin always sat in the bow, to see the lamp coming.
- **Reward:** 10 fuel (placeholder), and Ebba bails the boat out.
  - After the finale, **"Row out"**: Ebba rows you to the island and the far shore (a map feature, built with the Lake).
  - The old reward, a tip about the Fogstilts, is now the `fogstilt` tip (section 5).
- **Personality:** quiet, careful, a little superstitious.
- **Lines** (DRAFT; one per talk):
  - First meeting: "I saw the landing lit. For a moment I thought Oswin had come back."
  - Errand open: "My boat's out in the reeds. I can't see it from here. Put a light on it?"
  - Errand done: "Still there. Still mine. I'll bail it out."
  - Fragment (kept): "The night it went dark, the lake didn't freeze. It went still. Even the reeds stopped."
  - About Oswin: "Oswin always sat in the bow. He said he liked to see the lamp coming."
  - Later visits: "I won't row into that. Not while the water stands still."
  - After the finale (built with the Lake): "It moves again. Get in. I'll row."
  - After the finale (kept): "That light past the far shore? I don't know who keeps it. Nobody lived out there."
  - Only if Fogstilts wade the Lake (OWNER 12): "The tall ones wade out there too. One light moves them. Two send them off."
- **Guardrails:**
  - Oswin is remembered, never seen. "I thought Oswin had come back" keeps his fate open.
  - In "it went dark", "it" is the night, not the Soul. Nobody says why it rose.
  - "He" for Oswin appears once. If the owner wants no pronouns: "Oswin always sat in the bow, to see the lamp coming."
- **Art and sound:** unchanged (32x32, oar knock). The boat reuses the sprite already on the art list for the Lake. There's no separate marsh boat.
- **Effort:** S, on top of M5c's talk panel.

**Who comes back where** (replaces the table in PLAN §3):

| Region held | Who comes back | Where |
|---|---|---|
| The Hollow | Amos | by the hut |
| The Reedmarsh | Maud; Ivo too, once two regions are held | the pumphouse; the carved stone |
| The Windward Ridge | Kit | the glazier's workshop |
| The Lakeshore | Ebba | the old jetty |

The Reedmarsh now brings back two people, not three, so the old M5d question about three arrivals at once goes away.

**Errands** (PLAN §5, items 4 and 5):
- 4. "Show me the boat" (Ebba): light the boat in the Lakeshore's reeds. Reward: 10 fuel, and the boat is bailed.
- 5. "Row out" (Ebba, after the finale; built with the Lake): a crossing from the jetty to the island and the far shore.

**The boat and "on to the Lake".** The brief says Ebba's boat can later take you on to the Lake. No main goal may need a person, so the causeway stays the way in. Recommended: the boat crosses only after the finale, as "Row out" planned.

**OWNER 13:** Ebba's home on the Lakeshore is decided. The details: the spot on the old jetty, coming back when the shore is held, and the errand, reward and lines above.

**OWNER 14:** when the boat crosses. Only after the finale (recommended), or also before it, as an optional ride from the jetty to Oswin's camp once the Lake is built.

DECIDED (2026-11-27): the boat crosses only after the finale.

**OWNER 15:** the brief calls Ebba "she", but PLAN §7 still leaves pronouns for the five people open, and the lines above use none for Ebba. Confirm "she"?

DECIDED (2026-11-27): Ebba is "she".

---

## 7. Milestones

The order is decided (ROADMAP, owner decision 2026-11-27), and it is also what this draft would recommend. M5c builds the shared people systems that Ebba needs. M5d puts the Fogstilt and Ebba in with their new home, and it tests the beam lessons the Lake relies on. M5e's Clinker also roams the shore, so it gets tested with the shore already in place.

| Step | Milestone | Contents | Effort |
|---|---|---|---|
| Gate | The WayLamp playtest | As planned. People and the shore's WayLamp both need "held". | — |
| 1 | **M5c: people, part 1** | As planned: the talk panel, People and Errands pages, save section and arrival line; Amos, Maud and Kit; the Gutterkite. | L |
| 2 | **M5d: the Lakeshore** | The region: carve, steps, causeway stub, region 4, thick fog, resources, 3 landmarks, the WayLamp, 5 goals, 3 entries, 2 tips and a map label. The Fogstilt. Ebba and the boat errand. | L (region M, Fogstilt M, Ebba S) |
| 3 | **M5e: creatures and Ivo** | The Slowwater (Reedmarsh). The Clinker (any region not held, the shore included). Ivo, with three survey stones and the map reward. | M-L (the Clinker's soft-lock guards are the biggest unknown) |
| 4 | **The Still Lake** | Region 5 and the finale; Ebba's "Row out"; Fogstilts at the Lake if chosen. | the largest; not rated here |

Each milestone ends with an owner playtest.

Doc sync: PLAN §2 and §6 still carry the old split ("two milestones", and "the Slowwater, the Clinker and the Fogstilt in M5d"). They need updating to match ROADMAP.

Saves: the map stays 112 x 100, and the new tiles were rock before, so a version-2 save should still load. Check that before bumping `SaveGame.VERSION`.

**M5d playtest questions**
1. Did the thick fog feel like a step toward the lake? Did you use beams to see and to move, or wait for lanterns?
2. Did walking through the shore's fog feel too slow?
3. Did you meet the Fogstilt before the shore was held? Did you work out that crossing two beams on it sends it off?
4. When the WayLamp wasn't reached, was it clear why? Was it fair that the Fogstilt cut that beam?
5. Was the hold at the landing fair without lantern light to refill your ward? Did you think of a guard beam?
6. Did you have enough glass for the mirrors the shore asked for?
7. After the Ridge, did the shore feel still and calm? Did the notes and goals carry you from the steps to the causeway with the pointer off?
8. Was lighting Ebba's boat worth doing? Did Ebba's lines sound like the notes?
9. How long did the shore take? (Aim: 10-15 minutes.)

M5e keeps the old M5d questions about the Slowwater, the Clinker and the busy Ridge, without the one about three arrivals. It adds: is the shore too busy with the Fogstilt and the Clinker?

---

## 8. Checks against STORY and DESIGN §8

**Conflicts.** Each one has an OWNER line or a fix.
1. Built journal entry 15 says "only the lake is left". With the shore in between, that comes one region early. The fix is in section 3 (OWNER 10).
2. DESIGN §8's playtest note expects the ward to be free during a hold, inside a nearby lantern's light. No lantern light reaches the landing, so the ward runs on lamp charge and warmth doesn't refill. Handled with a guard beam and by the Fogstilt leaving when kindling starts. The fallback is a smaller swarm (OWNER 6).
3. PLAN §2, "WayLamps are left alone": the Fogstilt never comes within 5 tiles of one and leaves when kindling starts. But it can stop you feeding the landing by cutting its beam (OWNER 11).
4. DESIGN §3.3, "Glass: the Ridge only": this breaks only if worn glass is approved (OWNER 4).
5. The 15-25 landmark target: 26 if the survey stones count (OWNER 8).
6. DESIGN §5, "One map, four regions": there are now five. The owner approved the region today, so this is a doc update.
7. Doc sync only: PLAN §2 and §6 still describe the old two-milestone split, with the Slowwater, the Clinker and the Fogstilt in M5d. ROADMAP has the decided M5c, M5d, M5e order (section 7).
8. The brief's map facts: the Reedmarsh reaches y 42, not 49. The split allows for it (1.1).
9. The brief calls Ebba "she", and PLAN §7 leaves that open (OWNER 15).
10. Doc wording only: STORY §2 says Oswin "left a half-built mirror on the shore", and §6 places the camp on the "Lake shore". The camp is past the causeway, on the Lake, not on the Lakeshore. Suggest "at the water's edge" in those two places. No in-game text names the camp's spot.

**Rules that hold**

| Rule | Source | Holds |
|---|---|---|
| Short, plain sentences; calm, a little sad, a little eerie; never horror | STORY header | yes |
| Oswin never speaks or appears; notes signed "- Oswin"; his surname never in the game | STORY header, PLAN §1 | yes |
| The Soul is "it"; people don't describe it; why it rose stays unexplained | STORY §2, PLAN §1 | yes; no shore text mentions it |
| Oswin's fate stays open | STORY §10 | yes |
| Each quoted line is one line on screen; HUD goals about 40 characters or fewer | STORY §6, brief | yes (29-38) |
| The pointer is off after the Reedmarsh; goals have targets | STORY §5 | yes; only the build goal has none |
| Built and planned journal numbers don't move | brief | yes (16-18) |
| One twist per region | DESIGN §4 | yes |
| The player builds every mirror | DECISIONS 2026-11-26 | yes; no free mirrors |
| No main goal needs a person | PLAN §1 | yes; the causeway is the way on |
| Counter first; held ground is quiet; light is safe | PLAN §2 | yes |
| One WayLamp per region: reach it (a beam counts), feed 15 fuel, hold 15 s; kindling never fails | DESIGN §8 | yes; the first WayLamp that only a beam reaches |
| A held region: lanterns refilled and held, no spawns, creatures fade, its light clears only its own region | DESIGN §8 | yes; the thick fog stays, but the WayLamp clears at the usual speed |
| Nothing may be built close enough to burn a WayLamp | DESIGN §8 | yes; nothing can be built within reach of the landing |
| Mirrors inside healthy light are safe | DESIGN §8 | yes with A. The Fogstilt shortens beams but never touches a mirror. (B would break this rule in every bank.) |
| The great lamp is the last WayLamp | STORY §11, DESIGN §8 | yes |
| The station, steps and Ridge WayLamp texts | STORY §6, §11 | yes. "The fog does not move" fits the shore, and "the small dark ones came up the steps" now has a place they came from. |
| The `waylamp_seen` tip says "a lantern's light" | STORY §11 | no change needed. It fires at the Hollow, and the shore's note says "Send a beam". |

**Doc changes, if approved** (for the docs pass that goes with the build):
- STORY §4: a new row 4 (below). The Lake becomes 5, the finale 6 and After 7.
- STORY §5: the goal rows (section 3).
- STORY §6: the three landmarks. `boat` leaves the Lake's list.
- STORY §7: entries 16-18.
- STORY §8: the two tips.
- STORY §11: add the shore's WayLamp to the story tie ("... and on the old landing (Lakeshore). The great lamp on the Lake is the last one."), the goal rows, the texts, the journal table and the banners.
- DESIGN §4: a Lakeshore entry (below). The Still Lake becomes region 5, reached "along the causeway from the Lakeshore".
- DESIGN §5: "five regions".
- DESIGN §8: add "The Lakeshore: on the old landing, out in the shallows."
- PLAN_NPCS_ENEMIES: section 6 of this draft.
- ROADMAP: the M5d and M5e rows.

STORY §4 row (DRAFT):

| Region | Player learns | Emotional beat | Points onward |
|---|---|---|---|
| **4. The Lakeshore** | Below the steps the wind stops. The fog is thick and still: lamps only thin it, beams cut it. The keepers marked the water every night until it went still. | Stillness after the wind. A held breath before the lake. | The causeway runs out over the still water, toward where Oswin stopped. |

DESIGN §4 entry (DRAFT):

**4. The Lakeshore** (planned, M5d). Down the old steps by the signal station. **Twist: thick fog.** Lanterns and the hand lamp clear fog at a quarter of the usual speed; beams and WayLamps clear it as usual. Wet shingle under the Ridge's cliff, reed shallows (soft ground, as in the Reedmarsh), an old jetty, and a causeway on to the Lake. 8 driftwood and 5 scrap spots (and 4 of worn glass, if approved). Landmarks: the foot of the steps, the water post, a boat in the reeds. Its WayLamp stands on the old landing, out of any lantern's reach. Goals 22-26. Home of the Fogstilt; Ebba comes back once it is held.

---

## 9. OWNER lines and still open

Decided by the owner on 2026-11-27: 2 (thick fog), 4 (worn glass: yes), 6 (try the beam-only landing), 14 (the boat crosses after the finale) and 15 (Ebba is "she"). 10: the owner asked what trimming entry 15 means; the proposal is in section 3.

| # | Choice | Recommended | Section |
|---|---|---|---|
| 1 | The split, the causeway as the one way on, the name | as drafted | 1.1 |
| 2 | The twist | A, thick fog | 1.2 |
| 3 | Thick fog stays when held; the hand lamp counts as ordinary light | yes; yes | 1.2 |
| 4 | Worn glass on the shore | yes | 1.3 |
| 5 | No upgrade finds on the shore | yes | 1.3 |
| 6 | The WayLamp on the old landing, reached only by a beam | yes | 1.4 |
| 7 | Move `boat` to the shore | yes | 2 |
| 8 | Landmark count rule | story marks only (23) | 2 |
| 9 | Five goals and the numbering 1-32 | yes | 3 |
| 10 | `descend` and `ridge_steps` as built; trim entry 15 | yes; yes | 3 |
| 11 | The Fogstilt's details: when it rises, and its rules near WayLamps (its home is decided) | yes | 6.1 |
| 12 | Fogstilts on the Lake until the finale | decide with the Lake | 6.1 |
| 13 | Ebba's details: the spot, errand, reward and lines (the home is decided) | yes | 6.2 |
| 14 | When the boat crosses | after the finale only | 6.2 |
| 15 | Ebba's pronoun | the owner's call | 6.2 |

Already decided, so not asked again: the region, the new homes for the Fogstilt and Ebba, and the milestone order (DECISIONS, PLAN §2 and ROADMAP at db283fa).

**Still open**
- The thick-fog number (`shore_clear_mult` 0.25) and the hold at the landing. Settle both in the M5d playtest.
- From PLAN §7, and now touching the shore:
  - whether held regions stop every creature (the Fogstilt fix assumes they do);
  - whether a held region can be lost again;
  - whether the great lamp holds the Lake like a WayLamp.
- For the Still Lake: Oswin's camp stands at the far end of the causeway, in fog no lantern clears. A beam along the straight causeway would show it, so the Lake may want `first_beam` before `camp`.
- Pronouns for the other four people (PLAN §7).
