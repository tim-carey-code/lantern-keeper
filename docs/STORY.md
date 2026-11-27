# Lantern Keeper — Story Outline

> **Synced to commit 9a2b9cc** (2026-11-26). The title card, letter, goals 1-18, journal entries 1-8, tips and the 13 built landmark texts below match `systems/story/story.gd` and `scripts/main/main.gd` as built. **Built** = in the game at 9a2b9cc; **Planned** = written, not built yet.
> **Owner-reviewed 2026-11-26** (milestone M5a). **DECIDED** lines are owner decisions. **DEFAULT** lines keep the draft until the owner says otherwise.
> Sources: DECISIONS.md (overrides), `systems/story/story.gd`, `scripts/main/main.gd`, DESIGN.md, ROADMAP.md.
> Voice for all in-game text: short, plain sentences. Calm, a little sad, a little eerie. Never horror. Oswin never speaks or appears; people met in the valley may speak short lines (DECIDED 2026-11-27).

People and new creatures: see PLAN_NPCS_ENEMIES.md (approved for v1 on 2026-11-27, before the Still Lake).

---

## 1. Premise and feeling

**Premise.** You are the new keeper of a dark, foggy valley. You came because of a letter from the last keeper, written when the lamps were going out faster than one person could relight them. The letter asks you to light the old lantern by the hut and follow the marks they left. Those marks are the landmarks: each carries a short note and points to the next place. The trail runs east through the marsh, north up the windy ridge, and down to the Still Lake, where the great lamp stands cold with the Soul of the Wick coiled around it. You learn **who** took the light. You do not learn **why**, or for sure what became of the last keeper.

**The feeling:**
- **Caring.** Tending light is looking after something, not a chore.
- **Following someone.** Always one step behind a person you never meet. Their notes keep you company.
- **Quietly uneasy.** The dark is not empty, but never cruel. Fainting is a rest, not a punishment.
- **Relief.** When the great lamp relights and the fog lifts, it feels like a long breath out.

DECIDED: keep "the new keeper answers a letter".

---

## 2. Characters

**The new keeper (player).** No name, face or voice by default. New to the valley; knows only what the player knows. Writes the journal.

DECIDED: the player types a name at a new game; it signs the journal.
Built: the name prompt comes after the title card (up to 16 characters; left empty, the keeper is "Keeper"). The journal is titled "<name>'s journal".

**The last keeper: Oswin Reed.** Kept the valley alone after the others left: tired, stubborn, kind. Went ahead to the Lake, lost his coat on the Ridge, left a half-built mirror on the shore. Fate not confirmed. He signs with his first name; his surname does not appear in the game yet.

DECIDED (2026-11-27): the last keeper is **Oswin Reed**, a man ("he"). (Was Hester Vane; Tobin Ash and Nell Corrie were the other options.)
DECIDED (2026-11-27): he signs his notes "- Oswin", with a plain hyphen, and the journal calls him Oswin. (It was "- H." for Hester, then briefly "- O."; in the game font a capital O looks like a zero.) His surname never appears in the game.

**The Soul of the Wick.**
- A living darkness that feeds on flame. It rose out of the Still Lake, coiled around the great lamp and drank its light.
- Then it was hungry for the rest of the valley. It never speaks. A coil of black that moves like smoke under water, with big pale eyes.
- THE WICK REMEMBERS EVERY FLAME hints that it was once part of the light, or made from it.
- **Left unexplained:** why it rose, whether it was always there, whether the keepers woke it, where it goes when driven off.

DECIDED: "it". In-world texts say "it", "the dark" or "the Soul of the Wick"; never a name.
DECIDED (2026-11-27): the Soul of the Wick has **big pale eyes**. The old "no face" rule is dropped for it and for the creatures.

**The Wicklings.** Small pieces of the Soul of the Wick that wander the dark. They crawl toward warmth, drain lanterns and chill the keeper. Hungry, not cruel: moths turned inside out. More and bolder the farther you go from the hut *(planned: at 9a2b9cc they come at the same rate everywhere)*.

**The old keepers' order.** Suggested name **the Keepers of the Long Light** (alternatives: **the Lampwardens**, **the Valley Watch**; in the world mostly "the keepers"). They tended the posts, ran the pump, cut glass on the Ridge and passed light by mirror to the great lamp. When it went cold, the other lamps failed one by one and the keepers left. One stayed.

DEFAULT: nameless ("the old keepers").

---

## 3. The opening: title card, name, letter

**Title card** (over black, before the letter):

> The valley had keepers once.
> Then the lamps went out, one by one.
> Now there is a letter, and you.

**Name prompt** (built; between the title card and the letter):

> Your name, keeper?

Hint line: *Type a name, then [Enter] or [A]. Leave it empty to be called Keeper.*

**The letter** (~70 words). Shown at a new game after the name prompt; one button to begin (A / E / Enter, or a click). As built it is text on the dark opening screen (no paper art yet). Also pinned to the hut door (landmark `letter`) and kept at the top of the journal's *Story so far* page.

> To whoever reads this,
>
> The lamps in the valley are going out. I cannot keep them alone any more.
>
> There is a hut at the bottom of the Hollow, with an old lantern by the door. Light that first. Then follow my marks. I left them where the light will find them.
>
> Stay in the light. The dark is not empty.
>
> If you came, thank you.
>
> \- Oswin, the last keeper

DEFAULT: the letter as drafted.

---

## 4. Beat sheet by region

| Region | Player learns | Emotional beat | Points onward |
|--------|---------------|----------------|---------------|
| **1. The Hollow** | Gather, relight, build. Many keepers once counted their lamps; one stayed longest. | Arriving somewhere abandoned but not hopeless. The first flame is a small welcome. | Ledger: "Gone east to the marsh. Follow the stones." Fresh chalk arrow on the carved stone. Pointer is on. |
| **2. The Reedmarsh** | The way to the water was kept lit. Every frame faces the lake. The lake once shone; then something dark coiled around it. The pump still works. | Curiosity turning to unease. The chalk is the first sign that something *took* the light. | Pumphouse note: "Now go up, past the Hollow. The ridge has glass." |
| **3. The Windward Ridge** | Keepers made glass and passed light by mirror. The Wick remembers every flame. Oswin lost their coat here and wrote: "It came up out of the water." | Exposure and worry. The loneliest place in the game. | The station's mirror has been turned down toward the lake; steps beside it lead into the fog. |
| **4. The Still Lake** | Ordinary light dies here; only beams cut through. Oswin camped on the shore and built a mirror with no light to give it. Every keeper's name is on the island steps. | Stillness and dread, then resolve: finishing what Oswin started. | Oswin's mirror faces the island. Build the chain to the great lamp. |
| **5. Finale** | Who took the light: the Soul of the Wick. Light drives it off. | A quiet confrontation, not a battle. Tension, then release. | The fog lifts over the whole valley. |
| **6. After** | Nothing more is required. | Rest. The valley is lit and open; the dark is thinner, not gone. | Optional goals. Far past the lake, one small light that was not there before (hook for later). |

Regions 1-3 are built; 4-6 are planned.

DEFAULT: keep the far light.

---

## 5. Goal list

One goal shows on the HUD at a time; the journal lists the current goal and finished ones. The pointer (amber arrow) is **on for G01-G06 (the Hollow)** and off by default after, unless turned back on in settings. If the player finishes a goal early, skip to the first unfinished one.

**Built:** goals 1-18 (ids, HUD texts, order and pointer targets as in `Story.GOALS`). **Planned:** goals 19-24 (the Still Lake). Goals are checked four times a second.

| # | id | HUD text | Completes when | Pointer target |
|---|----|----------|----------------|----------------|
| 1 | `gather_fuel` | Take fuel from the woodpile | Carrying at least 1 fuel (also done once the old lantern is relit) | Woodpile |
| 2 | `relight_first` | Relight the old lantern by the hut | Start lantern lit | Start lantern |
| 3 | `read_ledger` | Read the ledger by the hut | `ledger` read | Ledger |
| 4 | `build_post` | Build a Post Lamp at the edge of the light | Any new Post Lamp placed | Fog edge toward the east passage |
| 5 | `stone_way` | Light the way east to the carved stone | `stone_way` read | Carved stone |
| 6 | `enter_marsh` | Follow the arrow into the marsh | Enter the Reedmarsh | Passage exit |
| 7 | `frames_east` | Find the old frames on the boardwalk | `frames_east` read | Frames |
| 8 | `chalk_lake` | Look at the chalk on the pumphouse | `chalk_lake` read (soft: done with 9 if skipped) | Chalk wall |
| 9 | `pumphouse` | Wake the old pump | `pumphouse` read (Reservoir Lamp) | Pumphouse |
| 10 | `build_reservoir` | Build a Reservoir Lamp | Reservoir Lamp placed | — |
| 11 | `climb_north` | Climb north from the top of the Hollow | Enter the Ridge | `climb_cairn` |
| 12 | `glazier` | Find the glazier's workshop | `glazier` read (Hooded Lamp) | Workshop |
| 13 | `build_hooded` | Build a Hooded Lamp in the wind | Hooded Lamp placed | — |
| 14 | `lens` | Look for the great lens | `lens` read | Broken lens |
| 15 | `coat` | Follow the ridge east | `coat` read | Coat |
| 16 | `station` | Reach the signal station | `station` read (Mirror Post) | Signal station |
| 17 | `build_mirror` | Light a Mirror Post from a lantern | A Mirror Post is lit | — |
| 18 | `descend` | Take the old steps down to the lake | Enter the Still Lake (not built yet, so this goal stays on the HUD) | `ridge_steps` |
| 19 | `camp` | Find where Oswin stopped | `camp` read | Camp |
| 20 | `first_beam` | Send a beam out over the water | A beam reaches lake fog | — |
| 21 | `reach_island` | Carry light to the island | A beam reaches the island | Island |
| 22 | `great_lamp` | Climb the steps to the great lamp | Reach the great lamp | Great lamp |
| 23 | `drive_off` | Drive the dark from the great lamp | Finale done, lamp lit | Great lamp |
| 24 | `keep_valley` | The valley is yours to keep | Never (free play) | — |

Optional after-game goals (journal only): `all_notes` "Find every note Oswin left"; `all_frames` "Relight every old frame"; `far_light` "Look toward the far shore" (reach `far_shore`).

Lens comes before coat because it sits west of the coat (`_ridge_spot(30, 9)` vs `(42, 22)`), so the trail runs west to east: glazier, lens, coat, station.

DEFAULT: keep the goals as listed; tune after playtest.
DECIDED: the pointer turns off on reaching the Reedmarsh (a setting turns it back on).

---

## 6. Landmark texts

### Built landmarks (13), as in `scripts/main/main.gd`
Each quoted line is one line on screen. The title shows on the note and in "Something catches the light: ...". A landmark that unlocks a lantern adds a line to its note: "New lantern: <name>. Pick it in the lantern list (Tab / Y)."

**`letter`**, "The letter on the hut door" (Hollow, pinned to the hut door). **Cut 2026-11-27** (owner: too much to read at the start; the letter is in the opening and the journal).
> The letter that brought you here. The ink has run a little.
> Light that first. Then follow my marks. - Oswin

**`rack`**, "Lantern rack" (Hollow, by the hut). **Scenery only since 2026-11-27** (owner: too much to read at the start): the rack stays, with nothing to read.
> Five hooks, five worn marks where lamps hung.
> Only one hook is empty. Its mark is the cleanest.

**`ledger`**, "Keepers' ledger" (Hollow, by the hut)
> Long columns of tally marks, one for every lamp lit each night.
> Near the end the columns shrink to a single mark, in a newer hand.
> Under it: Gone east to the marsh. Follow the stones. - Oswin

**`stone_way`**, "Carved stone" (Hollow, at the passage to the marsh)
> KEEP THE WAY TO THE WATER LIT.
> Below the old letters, a fresh chalk arrow points east.

**`climb_cairn`**, "A stone cairn" (top of the Hollow, at the foot of the climb)
> A small cairn, a chalk arrow on the top stone, pointing up.
> The wind is worse up there. Keep your lights sheltered. - Oswin

**`frames_east`**, "Old lantern frames" (Reedmarsh boardwalk)
> Three empty frames along the boardwalk, all turned east, toward the lake.
> A rag is tied to the last one: The pump still works. Wake it. - Oswin

**`chalk_lake`**, "Chalk on the pumphouse wall" (Reedmarsh)
> Two drawings of the same lake. In the first it shines.
> In the second, something dark is coiled around the light.
> Beside them, newer chalk: I went to look. - Oswin

**`pumphouse`**, "The pumphouse" (Reedmarsh, far-east island; unlocks the Reservoir Lamp)
> The old pump still turns when you push it. Its tank could feed a lamp for a long time.
> Scratched on the tank: Light has to be fed from somewhere.
> Now go up, past the Hollow. The ridge has glass. - Oswin

**`glazier`**, "The glazier's workshop" (Ridge, west; unlocks the Hooded Lamp)
> Cold kilns and racks of cut glass. A half-finished hood sits on the bench,
> shaped to keep a flame alive in any wind.
> A note under it: Finish it. I could not stay. - Oswin

**`lens`**, "A broken lens" (Ridge)
> A great curved lens, split down the middle. Scratched into the frame:
> THE WICK REMEMBERS EVERY FLAME.
> Below, in a newer hand: Then it will remember ours. - Oswin

**`coat`**, "A keeper's coat" (Ridge)
> Snagged on the rocks, stiff with frost. An O is stitched inside the collar.
> In the pocket: "It came up out of the water. It drank the great lamp.
> Now it is hungry for the rest. Only mirrors reach the lake."

**`station`**, "The signal station" (Ridge, east end; unlocks the Mirror Post)
> A tall post with a cracked mirror. Keepers passed light from post to post, all the way to the lake.
> Someone has turned the mirror down, toward the water.
> Old steps beside it go down into the fog.

**`ridge_steps`**, "Old steps" (Ridge, east end)
> Old steps, worn smooth, going down.
> Below, the fog does not move, even in the wind.

DEFAULT: the coat is Oswin's.

### Planned landmarks (8)
In the Text column, " / " marks a line break.

| id | Object | Region | Text |
|----|--------|--------|------|
| `boat` | A boat tied at the shore | Lake | A boat half full of rain, the oars still in it. / Past the reeds the fog is too thick to row through. |
| `drowned_frames` | Frames standing in the shallows | Lake | A row of frames in the shallows. Their glass is clean. / Someone tried to light them. The fog swallowed every one. |
| `camp` | The last keeper's camp | Lake shore | Cold ashes, a blanket, a tin cup. A half-built mirror frame, aimed at the island. / A crate of cut glass beside it. / Oswin was here. Not long ago. |
| `pier_stone` | Carved stone at the end of the pier | Lake | FROM THE ISLAND, LIGHT. FROM THE KEEPERS, CARE. |
| `island_steps` | Steps up to the great lamp | Island | A name cut into every step, one for each keeper. / The newest name is only half cut. |
| `great_lamp` | Plate on the great lamp's base | Island | THE FIRST FLAME OF THE VALLEY. / IT WAS NEVER MEANT TO BE KEPT BY ONE. |
| `hand_lamp` | A hand lamp on the top step (after the finale) | Island | A keeper's hand lamp, set down with care. It is cold. / Beside it, in chalk: Thank you. Keep it lit. - Oswin |
| `far_shore` | A post on the far shore, facing away | Lake (far side) | A new post, freshly cut. Its lamp is gone. / Far off, past the end of the valley, one small light is burning. |

Total: 21 landmarks (13 built, 8 planned; inside the 15-25 target).

DECIDED: the player builds every mirror. Oswin's camp holds a half-built mirror frame (story only) and a crate of glass instead, so the Lake can be started.
DECIDED: keep the plate.

---

### Upgrade finds (6): DRAFT for owner approval
Built on `main`: one keeper's satchel and one lamp glass in a far corner of each region. Reading one takes it: a satchel lets you carry 10 more of each resource; a lamp glass makes the hand lamp reach further, dim more slowly and ward for longer. Each quoted line is one line on screen.

**`satchel_hollow`**, "A keeper's satchel" (far west of the Hollow)
> A keeper's satchel, hung on a nail in a fallen wall.
> Patched many times, and still sound.

**`lampglass_hollow`**, "A lamp glass" (south of the Hollow)
> A spare glass for a hand lamp, wrapped in a rag.
> It is clearer than yours.

**`satchel_marsh`**, "A keeper's satchel" (north-east Reedmarsh)
> A satchel wrapped in oilcloth, wedged under an old post.
> It is dry inside.

**`lampglass_marsh`**, "A lamp glass" (south-east Reedmarsh)
> A lamp glass in a tin box, packed in dry moss.
> Not a crack in it.

**`satchel_ridge`**, "A keeper's satchel" (north Ridge)
> A satchel under a flat stone, its strap mended with wire.
> Someone meant to come back for it.

**`lampglass_ridge`**, "A lamp glass" (west Ridge, below the glazier's workshop)
> A thin lamp glass from the glazier's racks, cut clear as water.
> It fits your hand lamp.

Added under the note when it is taken (one of these):
> You can carry {40, 50 or 60} of each now.
> Your hand lamp reaches further, dims more slowly and wards for longer.

## 7. Journal "story so far"

One entry after each beat, written by the keeper. **Built:** entries 1-8 (as in `Story.ENTRIES`). **Planned:** 9-12.

As built, the journal has three pages: *Goals*, *Story so far* (Oswin's letter, then these entries) and *Notes* (every landmark read, in full, to read again). Notes have their own page; they are not listed under each entry. Each new entry shows "New journal entry: <title>" with the journal button.

1. **Arrival** (goal 2): *I came because of the letter. The old lantern took the flame on the first try. One hook on the rack is empty.*
2. **The ledger** (3): *The keepers counted every lamp they lit. At the end, one mark a night. Oswin went east.*
3. **The marsh** (7): *The frames all face east, toward a lake I cannot see.*
4. **The pumphouse** (9): *The chalk shows the lake, bright, then dark. Something coiled around its light. The pump still works.*
5. **The climb** (11): *Oswin sent me up. The wind pulls at every flame.*
6. **The workshop** (12): *Oswin could not stay to finish the hood. I did.*
7. **The coat** (15): *Oswin's coat, caught in the rocks. Something came up out of the water and drank the great lamp. I hope Oswin found somewhere warm.*
8. **The station** (16): *Oswin turned the last mirror toward the lake. That is where Oswin went.*
9. **The lake** (19): *Ordinary light dies here. Oswin started a mirror and left the glass to finish it. I will.*
10. **The island** (22): *A name on every step. The newest is not finished. The great lamp is cold, and it is not alone.*
11. **The light returns** (23): *It let go. The great lamp caught, and the fog lifted. I could see the hut from the island.*
12. **After** (`hand_lamp` read): *Oswin left me the hand lamp. Past the far shore there is a small light. I will keep this one lit.*

DEFAULT: first person.

---

## 8. First-time tips

Shown once each, in a panel near the bottom of the screen, for 6 s, one at a time. Built: all 12, as in `Story.TIPS`. As built, the ward tip lists all three bindings (F / RB / RT) rather than only the device in use.

| id | Trigger (as built) | Tip |
|----|--------------------|-----|
| `cold_lantern` | First cold lantern (shows at the start: the hut lantern starts cold) | A cold lantern keeps its frame. A little fuel will wake it. |
| `low_lantern` | First lit lantern below 25% | Lanterns burn down. Top them up before they go cold. |
| `fog_edge` | After 90 s of play (stands in for "first fog edge") | Fog comes back where light fades. Light holds the ground. |
| `gust` | First gust warning | Wind is coming. Rock on the windward side shelters a flame. |
| `wickling_seen` | First Wickling within 420 px | Something small moves in the dark. It is drawn to your lights. |
| `wickling_close` | First Wickling within 130 px | Hold your beam on them: left click or RT, aimed. F or RB throws them back. (PROTOTYPE text, Keeper's Light) |
| `lamp_empty` | Hand lamp down to an ember | Your lamp is down to an ember. Rest in a lantern's light to fill it. |
| `warmth_low` | Warmth below 35% | You are getting cold. Stand in a lantern's light. |
| `faint` | First faint | You woke by the nearest light. What you dropped waits where you fell. |
| `glass` | First glass carried | Glass. The keepers on the ridge made lamps from it. |
| `mirror_placed` | First Mirror Post placed | A mirror needs light. Stand it inside a burning lantern's glow. |
| `mirror_lit` | First lit mirror | Interact to turn the beam. Beams pass from mirror to mirror. |

DEFAULT: yes, a "show tips again" option (built, in the pause menu).

---

## 9. The finale (planned)

### Sequence
1. **Arrival.** The keeper climbs the island steps. The great lamp is a dark shape; around it, something black is coiled, moving like smoke under water. The music drops to one low note. Line: *It is coiled around the lamp. It has been feeding a long time.*
2. **It reaches out.** Tendrils spread over the island and Wicklings rise from them. Where a tendril touches light, the light shrinks. Standing near it slowly chills the keeper.
3. **The player works the light.** The warding glow pushes tendrils back and burns Wicklings. Mirror beams from the shore chain onto the island; the player adds and turns mirrors so beams strike the coil from more sides. Each lit side makes it pull tighter.
   - After the first beam hits: *It draws back from the light.*
   - About halfway: *The lamp's glass is showing through.*
4. **It lets go.** With enough sides lit at once, the Soul of the Wick unwinds, slides into the water and is gone. No death, no scream. The lake goes very still. Line: *It let go.*
5. **The great lamp catches.** A small flame, then a slow amber swell. The light rolls across the lake and the fog lifts over the valley, region by region, as the view pulls back. Every lantern the player lit glows at once.
6. **Ending text** (below), one button, then back to play on the island, with `hand_lamp` now on the top step.

Fainting here works as everywhere: wake at the nearest lit lantern; the coil grows back to where it was, never further.

DECIDED: some pressure (the coil drains the lanterns feeding the mirrors, and Wicklings rise from the water).

### Ending text (~65 words)

> The great lamp is burning.
>
> For the first time in a long time, the fog has lifted from the valley. You can see the hut from here, and the marsh, and the ridge.
>
> The dark is not gone. It went down into the water, and the water is deep.
>
> But the valley has a keeper again.
>
> Keep it lit.

### After-game line
HUD goal: **The valley is yours to keep.**
One-time line: *Far past the lake, one small light is burning. It was not there before.*

DEFAULT: the ending as drafted.

---

## 10. Open questions for the owner (answered 2026-11-26)

1. **Premise:** keep the letter from the last keeper, or another way in? **DECIDED:** keep the letter.
2. **Oswin's fate:** open (hand lamp + far light, as drafted), confirmed alive, or never mentioned? **DEFAULT:** open, as drafted.
3. **Names:** last keeper, the order, and whether the player keeper has a name. **DECIDED:** Oswin Reed ("Oswin", he; was Hester Vane until 2026-11-27); the player types a name. **DEFAULT:** the order stays nameless.
4. **The Soul of the Wick:** "it" or "he"; and is it only hungry, or something more? **DECIDED:** "it", no name; big pale eyes (2026-11-27, replacing "no face"). **DEFAULT:** the rest stays unexplained, as drafted.
5. **The "why" hint:** keep the great lamp plate, or keep "why" fully silent for now? **DECIDED:** keep the plate.
6. **Pointer:** off on entering the marsh, or later? **DECIDED:** off on reaching the Reedmarsh (built).
7. **Finale:** calm puzzle or light pressure? **DECIDED:** some pressure.
8. **Goals:** 24 steps, or merge build goals into unlock goals? **DEFAULT:** keep the goals as listed; tune after playtest.

---

## 11. WayLamps (text DECIDED 2026-11-27; the mechanic is a prototype on branch `proto/waylamps`)

> **Approved by the owner on 2026-11-27.** Built on branch `proto/waylamps` (DESIGN.md §8, owner playtest pending) and mirrored in `story.gd` and `main.gd`.

**Story tie.** The old keepers kept the WayLamps; the WayLamps kept the lamps. There is one in each region: at the north end of the Hollow below the climb (moved 2026-11-27; it was by the carved stone, too close to the hut), on the pumphouse island (Reedmarsh) and by the signal station (Ridge). The great lamp on the Lake is the last one. When the keepers left, the WayLamps went cold, and one keeper could not hold them and every lamp too. The great lamp's plate says it plainly at the end: IT WAS NEVER MEANT TO BE KEPT BY ONE.

### Goal rows to insert

| Insert after | id | HUD text | Chars | Completes when | Pointer target |
|---|---|---|---|---|---|
| `build_post` (4) | `kindle_hollow` | Kindle the WayLamp in the north Hollow | 38 | The Hollow's WayLamp is kindled (the Hollow is held) | `waylamp_hollow` |
| `build_reservoir` (10) | `kindle_marsh` | Kindle the WayLamp by the pumphouse | 35 | The Reedmarsh's WayLamp is kindled | `waylamp_marsh` |
| `build_mirror` (17) | `kindle_ridge` | Kindle the WayLamp by the signal station | 40 | The Ridge's WayLamp is kindled | `waylamp_ridge` |

- The Hollow text is the working text. The other two change "on the pumphouse island" and "at the signal station" to "by ...", so all three read alike, and the marsh one is shorter (the player knows the pumphouse by then). The working texts also fit (42 and 40 characters).
- With these rows the goals run 1-27: 21 for the built regions, 6 planned for the Lake. The pointer rule stays "on until the Reedmarsh" (it would cover goals 1-7). Every kindle goal has a target.
- `kindle_hollow` comes right after `build_post`. Its WayLamp stands at the north end of the Hollow, below the climb, so you light your way north first, then east to the carved stone and the marsh. (Moved 2026-11-27: the owner felt it was too close to the hut.) WayLamps take fuel directly; no lantern has to reach them (owner, 2026-11-27).

### WayLamp inspection texts
Each quoted line is one line on screen.

**`waylamp_hollow`**, "WayLamp of the Hollow" (at the north end of the Hollow, below the climb)
> A tall lamp with a wide iron bowl, cold and full of old ash.
> Cut into the base: WHILE THIS BURNS, THE HOLLOW IS KEPT.
> Tied to the post: This has to be held until it takes. I could not hold it and keep the rest. - Oswin

**`waylamp_marsh`**, "WayLamp of the Reedmarsh" (on the pumphouse island)
> A WayLamp on a stone footing, above the damp. Its bowl is dry.
> Cut into the base: WHILE THIS BURNS, THE MARSH IS KEPT.
> Under it, a tin of dry wicks and a tag in an old hand: For whoever comes next.

**`waylamp_ridge`**, "WayLamp of the Ridge" (by the signal station)
> A WayLamp in the lee of the station wall. Frost has cracked its hood.
> Cut into the base: WHILE THIS BURNS, THE RIDGE IS KEPT.
> Under a stone: When this went out, the small dark ones came up the steps. - Oswin

Under each inspection text, the note explains the WayLamp (one line on screen each):
> Feed it 15 fuel.
> While it kindles, the dark will come for it. Keep them off it.
> Lit, it holds this whole region: its lanterns stop burning down, and nothing comes here.

### Journal entries (one per kindling)
Suggested entry numbers 13-15, so the existing numbers don't move. The journal lists entries in the order they are written.

| # | Written when | Title | Entry |
|---|---|---|---|
| 13 | `kindle_hollow` done | The first WayLamp | *I held the WayLamp until it took. Now the Hollow keeps its own lamps.* |
| 14 | `kindle_marsh` done | The marsh WayLamp | *The old keepers left dry wicks for whoever came next. The marsh is held again.* |
| 15 | `kindle_ridge` done | The ridge WayLamp | *The ridge is held. Nothing comes up the steps now, and only the lake is left.* |

### Banner when a region becomes held
Shown in the large centre banner where region names fade in:

> {Region name} is held

"The Hollow is held", "The Reedmarsh is held", "The Windward Ridge is held" (longest: 26 characters).

With it, a line on the tip line at the bottom of the screen:
> The WayLamp took. Its lanterns won't burn down now, and nothing comes here.

### Tips (shown once each)

| id | Trigger | Tip |
|----|---------|-----|
| `waylamp_seen` | The light first finds a WayLamp | A WayLamp. Feed it fuel, then hold it until it takes. |
| `dying_lantern` | First lantern below a quarter of its tank | A lantern below a quarter is dying. Wicklings can drain it, so keep it fed. |
| `kindle_attack` | First time Wicklings come for a WayLamp being kindled | Wicklings have come for the WayLamp. Ward them off until it takes. |

`dying_lantern` fires at the same moment as the built `low_lantern` tip (also below 25%). Suggestion: while the prototype is on, show `dying_lantern` instead of `low_lantern`.
