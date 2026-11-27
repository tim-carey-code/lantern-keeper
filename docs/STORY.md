# Lantern Keeper — Story Outline

> **Synced to commit c6d3ee0** on `proto/kl-replan` (2026-11-27), refreshed for the approved game plan (`docs/replan/GAME_PLAN.md` §13). In the code today: the title card, the name prompt, the letter, **23 goals**, **11 journal entries** (1-8 and 13-15), **21 tips**, **12 readable landmark notes** plus the rack (scenery), **6 upgrade-find notes**, **3 WayLamp notes**, the fast-travel texts, and the UI lines in §12. They match `systems/story/story.gd`, `scripts/main/main.gd`, `scripts/world/` and `scripts/ui/` word for word. **Built** = in the game at c6d3ee0; **Planned** = written, not built yet.
> **Marks.** **APPROVED**: the owner approved this exact wording; keep it word for word, and change it only with the owner. **DECIDED**: an owner decision about the story (who, what, where). **DEFAULT**: a draft choice the owner let stand; ask before changing it. **DRAFT**: not yet approved. Owner-reviewed 2026-11-26 (milestone M5a); later approvals are dated.
> **The re-plan.** The game plan changes how the game plays (fire skills, no lamp tending, WayLamps won by fighting, a finale fight, people who speak). Approved texts below stay as they are until the owner approves new wording. §13 lists every text the plan needs rewritten, as DRAFT suggestions.
> Sources: DECISIONS.md (overrides), the game plan, `systems/story/story.gd`, `scripts/main/main.gd`, DESIGN.md, ROADMAP.md.
> Voice for all in-game text: short, plain sentences. Calm, a little sad, a little eerie. Never horror. Oswin never speaks or appears; people met in the valley may speak short lines (DECIDED 2026-11-27).
> **Pronouns.** Oswin is "he". Ebba is "she". The keeper is "they". The Soul of the Wick is "it". Amos, Maud, Kit and Ivo get no pronouns until the owner chooses (DECISIONS 2026-11-27, "the game plan approved").

People and new creatures: see PLAN_NPCS_ENEMIES.md (approved for v1 on 2026-11-27, before the Still Lake; to be merged into this file in M4).

---

## 1. Premise and feeling

**Premise.** You are the new keeper of a dark, foggy valley. You came because of a letter from the last keeper, written when the lamps were going out faster than one person could relight them. The letter asks you to light the old lantern by the hut and follow the marks he left. Those marks are the landmarks: each carries a short note and points to the next place. The trail runs east through the marsh, north up the windy ridge, and down to the Still Lake, where the great lamp stands cold with the Soul of the Wick coiled around it. You learn **who** took the light. You do not learn **why**, or for sure what became of the last keeper.

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

**The Wicklings.** Small pieces of the Soul of the Wick that wander the dark. They crawl toward warmth, drain lanterns and chill the keeper. Hungry, not cruel: moths turned inside out. More and bolder the farther you go from the hut *(built since the Hollow prototype: they wait in fixed packs that get tougher toward the WayLamp. Draining lanterns is cut in M1b, when tending goes.)*

**The old keepers' order.** Suggested name **the Keepers of the Long Light** (alternatives: **the Lampwardens**, **the Valley Watch**; in the world mostly "the keepers"). They tended the posts, ran the pump, cut glass on the Ridge and passed light by mirror to the great lamp. When it went cold, the other lamps failed one by one and the keepers left. One stayed.

DEFAULT: nameless ("the old keepers").

**People in the valley** (PLANNED, M4-M7; none built). Five people come back as regions are held. They speak short lines through Dialogue Manager; their lines will live in `dialogue/*.dialogue` and here, word for word. Until M4 their draft lines and errands stay in `PLAN_NPCS_ENEMIES.md`. Names are drafts.
- **Amos**, a trader (the Hollow, M4): the errand "Amos's cart".
- **Maud**, the old pump keeper, who knew Oswin (the Reedmarsh, M5): "Maud's lamp".
- **Kit**, the glazier's apprentice (the Ridge, M6): "Fire the kiln".
- **Ebba**, a rower, "she" (DECIDED 2026-11-27) (the Lakeshore, M7): "Show me the boat". Her boat crosses to the Lake only after the finale (DECIDED 2026-11-27).
- **Ivo**, a mapmaker (two regions held, M5; a cut line): "Walk the edges".

No pronouns for Amos, Maud, Kit or Ivo until the owner chooses (needed before M4).

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
| **1. The Hollow** | Gather, relight, build. Many keepers once counted their lamps; one stayed longest. | Arriving somewhere abandoned but not hopeless. The first flame is a small welcome. | Ledger: "My lamp hangs on my crook, on the north path. Take it back. Then the WayLamp, on the way east." (DECIDED 2026-11-27, the loop; owner approved) Fresh chalk arrow on the carved stone. Pointer is on. |
| **2. The Reedmarsh** | The way to the water was kept lit. Every frame faces the lake. The lake once shone; then something dark coiled around it. The pump still works. | Curiosity turning to unease. The chalk is the first sign that something *took* the light. | Pumphouse note: "Now go up, north of the reeds. The ridge has glass." (DECIDED 2026-11-27, the loop; owner approved) The cairn at the foot of the marsh climb. |
| **3. The Windward Ridge** | Keepers made glass and passed light by mirror. The Wick remembers every flame. Oswin lost his coat here and wrote: "It came up out of the water." | Exposure and worry. The loneliest place in the game. | The station's mirror has been turned down toward the lake; steps beside it lead into the fog. |
| **4. The Still Lake** | Ordinary light dies here; only beams cut through. Oswin camped on the shore and built a mirror with no light to give it. Every keeper's name is on the island steps. | Stillness and dread, then resolve: finishing what Oswin started. | Oswin's mirror faces the island. Build the chain to the great lamp. |
| **5. Finale** | Who took the light: the Soul of the Wick. Light drives it off. | ~~A quiet confrontation, not a battle.~~ **Superseded:** the finale is a real fight, and the Soul retreats through a portal (DECIDED 2026-11-27; §9). Tension, then release. | The fog lifts over the whole valley. |
| **6. After** | Nothing more is required. | Rest. The valley is lit and open; the dark is thinner, not gone. | Optional goals. Far past the lake, one small light that was not there before (hook for later). The sealed portal is a second hook (PLANNED, M8). |

Regions 1-3 are built. Planned: **the Lakeshore** (M7), a new region between the Ridge and the Still Lake, with thick fog and Ebba (its beats are in `PLAN_LAKESHORE.md` until M7 merges them); the Still Lake, the finale and after (M8). The beat for region 1 still says "Gather, relight, build"; that changes when tending goes (M1b; §13).

DEFAULT: keep the far light.

---

## 5. Goal list

One goal shows on the HUD at a time; the journal lists the current goal and finished ones. The pointer (amber arrow) is **on for G01-G06 (the Hollow)** and off by default after, unless turned back on in settings. If the player finishes a goal early, skip to the first unfinished one.

**Built:** 23 goals: the 20 rows in this table up to `descend` (3b and 4b included), plus `kindle_hollow`, `kindle_marsh` and `kindle_ridge` (§11). Ids, HUD texts, order and pointer targets as in `Story.GOALS`. **Planned:** goals 19-24 (the Still Lake), and the Lakeshore's goals (M7). Goals are checked four times a second.

| # | id | HUD text | Completes when | Pointer target |
|---|----|----------|----------------|----------------|
| 1 | `gather_fuel` | Take fuel from the woodpile | Carrying at least 1 fuel (also done once the old lantern is relit) | Woodpile |
| 2 | `relight_first` | Relight the old lantern by the hut | Start lantern lit | Start lantern |
| 3 | `read_ledger` | Read the ledger by the hut | `ledger` read | Ledger |
| 3b | `relight_waypost` | Relight the old lamp on the north path | The second cold old lantern, 12 tiles north of the hut, is lit (or `build_post` is done: never sent back) | The north path's lamp |
| 4 | `build_post` | Take back the lamp from Oswin's crook | The keeper reads `crook_post` (or builds a Post Lamp in tests) | `crook_post` |
| 4b | `burn_nest` | Burn out the nest with a Post Lamp | Any Hollow nest is burned out (or the Hollow is held) | Nest A, the route's nest (then the nearest nest left) |
| 5 | `stone_way` | Light the way east to the carved stone | `stone_way` read | Carved stone |
| 6 | `enter_marsh` | Follow the arrow into the marsh | Enter the Reedmarsh | Passage exit |
| 7 | `frames_east` | Find the old frames on the boardwalk | `frames_east` read | Frames |
| 8 | `chalk_lake` | Look at the chalk on the pumphouse | `chalk_lake` read (soft: done with 9 if skipped) | Chalk wall |
| 9 | `pumphouse` | Wake the old pump | `pumphouse` read (Reservoir Lamp) | Pumphouse |
| 10 | `build_reservoir` | Build a Reservoir Lamp | Reservoir Lamp placed | — |
| 11 | `climb_north` | Climb north out of the marsh | Enter the Ridge | `climb_cairn` (at the foot of the marsh climb) |
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

**The loop (2026-11-27, owner):** the goals run one way round. The Hollow's WayLamp is on the way east, so after `kindle_hollow` you go straight on to the carved stone and the marsh. After `kindle_marsh` you climb north out of the marsh (`climb_north`) to the Ridge's east end, and walk the Ridge one way, toward the old steps: glazier, lens, coat, station, its WayLamp, the steps. Each stop is nearer the steps than the one before (`main.gd` `RIDGE_TRAIL`). The order of the goals didn't change; their places did.

APPROVED (2026-11-27, the loop texts; DECISIONS "loop texts approved"): `climb_north` "Climb north out of the marsh" (was "Climb north from the top of the Hollow").
APPROVED (2026-11-27, onboarding; DECISIONS "the first 10 minutes": "The plan's §6 texts are approved"): `relight_waypost` "Relight the old lamp on the north path", `build_post` "Take back the lamp from Oswin's crook", `burn_nest` "Burn out the nest with a Post Lamp".

DEFAULT: keep the goals as listed; tune after playtest.
DECIDED: the pointer turns off on reaching the Reedmarsh (a setting turns it back on).

---

## 6. Landmark texts

### Built landmarks (12 readable notes, plus the rack as scenery; `letter` cut)
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
> Under it: My lamp hangs on my crook, on the north path. Take it back. Then the WayLamp, on the way east. - Oswin
APPROVED (2026-11-27, the loop texts; DECISIONS "loop texts approved"): the WayLamp now stands on the way east, not at the top. Was, DECIDED (onboarding plan §6): "My lamp hangs on my crook, on the north path. Take it back. Then the WayLamp, at the top. - Oswin"; before that "The north lamps first. Wake the WayLamp up there, then follow the stones east." (DRAFT), and "Gone east to the marsh. Follow the stones."

**`stone_way`**, "Carved stone" (Hollow, at the passage to the marsh)
> KEEP THE WAY TO THE WATER LIT.
> Below the old letters, a fresh chalk arrow points east.

**`climb_cairn`**, "A stone cairn" (Reedmarsh, at the foot of the marsh climb, the loop's way up to the Ridge; moved 2026-11-27 from the foot of the old climb)
> A small cairn, a chalk arrow on the top stone, pointing up.
> The wind is worse up there. Light the marsh before you climb. - Oswin
APPROVED (2026-11-27, the loop texts; DECISIONS "loop texts approved"): the marsh climb is open as soon as you reach the marsh, so the cairn asks you to light the marsh first. An optional suggestion for "worse" is in §13. The cairn's place is one of the three loop calls still under review. Was: "The wind is worse up there. Come back when the marsh is lit. - Oswin" (DRAFT), and before that "Keep your lights sheltered."

**`crook_post`**, "A keeper's post" (Hollow, about 19 tiles north of the hut on the main route; a shelled Wickling sleeps on it and a 6-scrap cache lies beside it; Keeper's Light prototype)
> A keeper's crook, fallen across the path. The lamp on it is cold, but whole.
> Tied to it: Plant one where you mean to stand. The small ones will not come into it. - Oswin
Likely APPROVED; **uncertain**. This note is one of the onboarding plan's §6 texts, and the owner approved those (DECISIONS 2026-11-27, "the first 10 minutes"), but this file still marked it DRAFT (AUDIT §4.1). The plan's version had a third line, "New lantern: Post Lamp. [build] builds one."; the game adds the general unlock line instead. Owner to confirm. The Post Lamp unlocks when the keeper reads this find.

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
> Now go up, north of the reeds. The ridge has glass. - Oswin
APPROVED (2026-11-27, the loop texts; DECISIONS "loop texts approved"): you climb to the Ridge from the marsh now, not back past the Hollow. Two of its lines no longer fit the game plan; suggestions are in §13. The note's place is one of the three loop calls still under review. Was: "Now go up, past the Hollow. The ridge has glass. - Oswin"

**`glazier`**, "The glazier's workshop" (Ridge, by the top of the marsh climb since the loop, 2026-11-27; unlocks the Hooded Lamp)
> Cold kilns and racks of cut glass. A half-finished hood sits on the bench,
> shaped to keep a flame alive in any wind.
> A note under it: Finish it. I could not stay. - Oswin

**`lens`**, "A broken lens" (Ridge, just past the glazier)
> A great curved lens, split down the middle. Scratched into the frame:
> THE WICK REMEMBERS EVERY FLAME.
> Below, in a newer hand: Then it will remember ours. - Oswin

**`coat`**, "A keeper's coat" (Ridge)
> Snagged on the rocks, stiff with frost. An O is stitched inside the collar.
> In the pocket: "It came up out of the water. It drank the great lamp.
> Now it is hungry for the rest. Only mirrors reach the lake."

**`station`**, "The signal station" (Ridge, north-east end, near the old steps; unlocks the Mirror Post)
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

Total: 21 landmarks (13 built, 8 planned; inside the 15-25 target). As of c6d3ee0, the game has 12 readable landmarks, plus the rack as scenery; `letter` is cut. The Lakeshore adds 3 (M7).

DECIDED: the player builds every mirror. Oswin's camp holds a half-built mirror frame (story only) and a crate of glass instead, so the Lake can be started.
DECIDED: keep the plate.

---

### Upgrade finds (6): DRAFT for owner approval
Built (on `main` and on the prototype line): one keeper's satchel and one lamp glass in a far corner of each region. Reading one takes it: a satchel lets you carry 10 more of each resource; a lamp glass makes the hand lamp reach further, dim more slowly and ward for longer. Each quoted line is one line on screen.

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

One entry after each beat, written by the keeper. **Built:** entries 1-8 here and 13-15 (§11), as in `Story.ENTRIES`. **Planned:** 9-12, and new entries per guardian (§13).

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

Shown once each, in a panel near the bottom of the screen, for 6 s, one at a time. Built: these 12, the 6 onboarding tips below and the 3 WayLamp tips (§11), 21 in all, as in `Story.TIPS`. A token such as [beam] becomes the button for the device in use (`Story.tip_text`).

| id | Trigger (as built) | Tip |
|----|--------------------|-----|
| `cold_lantern` | First cold lantern (shows at the start: the hut lantern starts cold) | A cold lantern keeps its frame. A little fuel will wake it. |
| `low_lantern` | First lit lantern below 25% | Lanterns burn down. Top them up before they go cold. |
| `fog_edge` | After 90 s of play (stands in for "first fog edge") | Fog comes back where light fades. Light holds the ground. |
| `gust` | First gust warning | Wind is coming. Rock on the windward side shelters a flame. |
| `wickling_seen` | First Wickling within 420 px | Something small moves in the dark. It is drawn to your lights. |
| `wickling_close` | First Wickling within 130 px | Hold [beam] to shine on it. Aim with [aim]. (APPROVED 2026-11-27, onboarding; was "Hold your beam on them: left click or RT, aimed. F or RB throws them back.") |
| `lamp_empty` | Hand lamp down to an ember | Your lamp is down to an ember. Rest in a lantern's light to fill it. |
| `warmth_low` | Warmth below 35% | You are getting cold. Stand in a lantern's light. |
| `faint` | First faint | You woke by the nearest light. What you dropped waits where you fell. |
| `glass` | First glass carried | Glass. The keepers on the ridge made lamps from it. |
| `mirror_placed` | First Mirror Post placed | A mirror needs light. Stand it inside a burning lantern's glow. |
| `mirror_lit` | First lit mirror | Interact to turn the beam. Beams pass from mirror to mirror. |

**The first 10 minutes** (onboarding, `docs/archive/PLAN_ONBOARDING.md` §6; text APPROVED by the owner 2026-11-27). In brackets: the button for the device in use (`Story.tip_text`): [beam] left click / RT, [burst] F / RB, [dash] Shift / LT, [build] Space / X, [aim] the mouse / the right stick.

| id | Trigger (as built) | Tip |
|----|--------------------|-----|
| `haven` | The north path's old lamp is lit | Lantern light fills your lamp and warms you. Fight near it. |
| `burst` | Two Wicklings within 130 px | Too close. [burst] throws them back. |
| `shell` | First beam on a shell (the crook's guard) | Light cracks a shell. Keep it on. |
| `dash` | The Clinker's first roll tell | It is gathering itself. [dash] steps clear. |
| `nest` | First nest within 416 px (its wake range and 2 tiles) | A nest. Your light can't touch it. A lantern's core can. |
| `build_here` | By a nest with the Post Lamp unlocked and 5 scrap carried | Plant a Post Lamp beside it. Then hold. |

Not built from §6: the optional "Something is sitting on the crook." banner and the journal line after the crook (they were written for the Clinker on the crook, Option A).

DEFAULT: yes, a "show tips again" option (built, in the pause menu).

---

## 9. The finale (planned)

> **Superseded in part.** DECIDED (2026-11-27, "Keeper's Light: owner answers"): the finale is a real fight. The Soul of the Wick is not killed; it retreats, a portal opens, and the keeper follows it. The sequence below was written for the older "confrontation of light, not a fight" and is kept as source material: its lines are DRAFT candidates for the fight. The ending text and the after-game line stay (GAME_PLAN §13: "the ending's last lines" stay).

### The fight (PLANNED, M8; DRAFT)
From GAME_PLAN §8.3. Three phases: **the coil** (three shelled coils around the great lamp; crack each where a mirror beam and your fire cross on it), **every flame** (about 40 s of each guardian's signature, each answered by that region's lamp), **the eyes** (it snuffs your hand lamp; fire on its eyes until they close, three times). It pulls back into the water, and a dark portal opens where it went down. The great lamp catches and the fog lifts. A faint returns you to the start of the phase.

Recommended for v1 (DRAFT for story markup): the keeper steps into the portal and the credits roll. You then wake at the great lamp in the open valley, with the portal sealed, as the hook. No lines are written for the fight, the portal or the credits yet (§13).

### Sequence (the older confrontation; superseded, kept as source)
1. **Arrival.** The keeper climbs the island steps. The great lamp is a dark shape; around it, something black is coiled, moving like smoke under water. The music drops to one low note. Line: *It is coiled around the lamp. It has been feeding a long time.*
2. **It reaches out.** Tendrils spread over the island and Wicklings rise from them. Where a tendril touches light, the light shrinks. Standing near it slowly chills the keeper.
3. **The player works the light.** The warding glow pushes tendrils back and burns Wicklings. Mirror beams from the shore chain onto the island; the player adds and turns mirrors so beams strike the coil from more sides. Each lit side makes it pull tighter.
   - After the first beam hits: *It draws back from the light.*
   - About halfway: *The lamp's glass is showing through.*
4. **It lets go.** With enough sides lit at once, the Soul of the Wick unwinds, slides into the water and is gone. No death, no scream. The lake goes very still. Line: *It let go.*
5. **The great lamp catches.** A small flame, then a slow amber swell. The light rolls across the lake and the fog lifts over the valley, region by region, as the view pulls back. Every lantern the player lit glows at once.
6. **Ending text** (below), one button, then back to play on the island, with `hand_lamp` now on the top step.

Fainting here works as everywhere: wake at the nearest lit lantern; the coil grows back to where it was, never further.

DECIDED: some pressure (the coil drains the lanterns feeding the mirrors, and Wicklings rise from the water). *Superseded by the fight (2026-11-27); draining lanterns goes with tending in M1b.*

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

## 11. WayLamps (text APPROVED 2026-11-27; the mechanic is built)

> **Approved by the owner on 2026-11-27.** Built on branch `proto/waylamps`, playtested and merged into `main` (DESIGN §12.3), and mirrored in `story.gd` and `main.gd`.
> APPROVED (2026-11-27, DECISIONS "owner answers": "WayLamp story text approved (STORY §11)"): the goal rows, the three inspection texts, the footer, journal entries 13-15, the held banner and its line, and the three tips in this section. The fast-travel texts are DRAFT. Several of these no longer fit the game plan (fuel, the hold, the ward, the marsh WayLamp's place); see §13.

**Story tie.** The old keepers kept the WayLamps; the WayLamps kept the lamps. There is one in each region: in the north-east of the Hollow, on the way east (the loop, 2026-11-27; it was at the north end below the climb, and before that by the carved stone, too close to the hut), on the pumphouse island (Reedmarsh) and by the signal station, toward the old steps (Ridge). The great lamp on the Lake is the last one. When the keepers left, the WayLamps went cold, and one keeper could not hold them and every lamp too. The great lamp's plate says it plainly at the end: IT WAS NEVER MEANT TO BE KEPT BY ONE.

### Goal rows to insert

| Insert after | id | HUD text | Chars | Completes when | Pointer target |
|---|---|---|---|---|---|
| `build_post` (4) | `kindle_hollow` | Kindle the WayLamp on the way east | 34 | The Hollow's WayLamp is kindled (the Hollow is held) | `waylamp_hollow` |
| `build_reservoir` (10) | `kindle_marsh` | Kindle the WayLamp by the pumphouse | 35 | The Reedmarsh's WayLamp is kindled | `waylamp_marsh` |
| `build_mirror` (17) | `kindle_ridge` | Kindle the WayLamp by the signal station | 40 | The Ridge's WayLamp is kindled | `waylamp_ridge` |

- The Hollow text is the working text. The other two change "on the pumphouse island" and "at the signal station" to "by ...", so all three read alike, and the marsh one is shorter (the player knows the pumphouse by then). The working texts also fit (42 and 40 characters).
- With these rows the goals run 1-27: 21 for the built regions, 6 planned for the Lake. The pointer rule stays "on until the Reedmarsh" (it would cover goals 1-7). Every kindle goal has a target.
- `kindle_hollow` comes right after `burn_nest` (since the onboarding pass, 2026-11-27: `relight_waypost`, `build_post`, `burn_nest`, then the WayLamp). Since the loop (2026-11-27) its WayLamp stands in the north-east of the Hollow, on the way east, so you go north to the crook and nest A, turn east to the WayLamp, and leave east past the carved stone right after kindling. WayLamps take fuel directly; no lantern has to reach them (owner, 2026-11-27).
- APPROVED (2026-11-27, the loop texts): `kindle_hollow` "Kindle the WayLamp on the way east" (was "Kindle the WayLamp in the north Hollow").

### WayLamp inspection texts
Each quoted line is one line on screen.

**`waylamp_hollow`**, "WayLamp of the Hollow" (north-east of the hut, on the way east to the marsh)
> A tall lamp with a wide iron bowl, cold and full of old ash.
> Cut into the base: WHILE THIS BURNS, THE HOLLOW IS KEPT.
> Tied to the post: This has to be held until it takes. I could not hold it and keep the rest. - Oswin

**`waylamp_marsh`**, "WayLamp of the Reedmarsh" (on the pumphouse island)
> A WayLamp on a stone footing, above the damp. Its bowl is dry.
> Cut into the base: WHILE THIS BURNS, THE MARSH IS KEPT.
> Under it, a tin of dry wicks and a tag in an old hand: For whoever comes next.

**`waylamp_ridge`**, "WayLamp of the Ridge" (by the signal station, toward the old steps)
> A WayLamp in the lee of the station wall. Frost has cracked its hood.
> Cut into the base: WHILE THIS BURNS, THE RIDGE IS KEPT.
> Under a stone: When this went out, the small dark ones came up the steps. - Oswin

Under each inspection text, the note explains the WayLamp (one line on screen each):
> Feed it 15 fuel.
> While it kindles, the dark will come for it. Keep them off it.
> Lit, it holds this whole region: its lanterns stop burning down, and nothing comes here.

### Fast travel (DRAFT, 2026-11-27, branch `proto/kl-loop`)
Lit WayLamps are fast travel (owner, 2026-11-27). Texts in `scripts/ui/travel_menu.gd` and the WayLamp prompt (`scripts/ui/world_prompt.gd`). All DRAFT for owner approval.

| Where | Text |
|---|---|
| Prompt over a lit WayLamp (with the button) | Travel |
| Second line of that prompt (in code; added to this table 2026-11-27) | WayLamp: this region is held |
| List title | WayLamps |
| Under the title | Travel to a lit WayLamp. |
| The WayLamp you stand at | WayLamp of the Hollow (you are here) |
| Close button | Stay |
| Only one WayLamp lit | Light another WayLamp to travel to it. |
| Blocked: a foe hunting the keeper | Can't travel while something hunts you |
| Blocked: a WayLamp kindling | Can't travel while a WayLamp kindles |
| Blocked: a guardian fight | Can't travel during a guardian fight |

The list names each WayLamp by its title ("WayLamp of the Hollow", "WayLamp of the Reedmarsh", "WayLamp of the Ridge").

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

---

## 12. Other texts in the code (added 2026-11-27)

These texts are in the game but were missing from this file (AUDIT M23). They are copied here **as they stand in the code**, word for word. Unless marked APPROVED, none was shown to the owner as text, so treat them as DRAFT. Most of them change with the re-plan (§13).

### Level-up screen (`scripts/ui/level_up.gd`; the card screen goes in M2)

| Where | Text |
|---|---|
| Title | Trim the wick |
| Under the title | Choose one. |
| Above the cards | Level {N} |

Each card shows its title, then its text. Three of the twelve are offered at each level-up.

| id | Title | Text | Mark |
|---|---|---|---|
| `lingering_burn` | Lingering burn | Things touched by your beam keep burning for 2 seconds. | DRAFT |
| `catching` | Catching | A kill catches the nearest foe within 60 px. | DRAFT |
| `tight_focus` | Tight focus | Your beam wears shells 30% faster. | DRAFT |
| `long_throw` | Long throw | Your beam reaches 310 px. | DRAFT |
| `second_step` | Second step | Dash twice before its cooldown. | DRAFT |
| `heavy_flare` | Heavy flare | Your burst throws foes farther and stuns them. | DRAFT |
| `deep_tank` | Deep tank | Your beam costs 20% less lamp charge. | DRAFT |
| `kindled_kills` | Kindled kills | Every kill gives back 10% of your lamp charge. | DRAFT |
| `hot_core` | Hot core | Your lanterns' cores burn twice as hard. | APPROVED (2026-11-27, "approved as written") |
| `steady_hand` | Steady hand | You walk at 90% speed while beaming. | APPROVED (2026-11-27) |
| `lee` | Lee | A Wickling's touch chills you 25% less. | APPROVED (2026-11-27) |
| `spill` | Spill | Burst cooldown 2.2 s; each foe it hits gives back 3% lamp charge. | APPROVED (2026-11-27) |

The four APPROVED cards: DECISIONS 2026-11-27 ("wick by level gap"): "The four new upgrade cards are approved as written (owner): Hot core, Steady hand, Lee, Spill." In M2 their names and effects move into branch picks and fixed gear lines (DESIGN §4.3).

### The Ashbrood (`scripts/enemies/ashbrood.gd`, `scripts/ui/boss_bar.gd`)

A toast when phase 1 ends:
> The Ashbrood leaves the bowl.

The boss bar's title reads "{name}   phase {N} / 2: {hint}". The hints:

| When | Hint |
|---|---|
| Phase 1, shell up | crack its shell with your beam |
| Phase 1, shell broken | burn it now, before the shell grows back |
| Phase 2, shell up | crack its shell with your beam, then hit it while it sits |
| Phase 2, shell broken | it dives at your lanterns: hit it while it sits |

### Fainting (`scripts/player/player.gd` `faint()`)

A note with a title and two lines:
> **You faint...**
> The cold takes you. You wake by the warmth of a lantern.
> Some of what you carried lies where you fell.

### HUD lines (`scripts/ui/hud.gd`, `scripts/world/landmark.gd`)

| When | Text |
|---|---|
| A goal is done (toast) | Done: {goal text} |
| The light first finds a landmark (toast) | Something catches the light: {title} |
| A lantern kind unlocks (toast) | New lantern unlocked: {name}   [{button}] |
| Under a note that unlocks a lantern | New lantern: {name}. Pick it in the lantern list (Tab / Y). |
| The level row | Lv {N}; at the cap the count reads "max" |

---

## 13. Texts needing rewrite (DRAFT)

From GAME_PLAN §13. **Everything in this section is DRAFT, for the owner.** Nothing here changes an APPROVED text: approved wording stays in the game, word for word, until the owner approves a new line. The milestone says when the code needs the new text. Suggested lines are marked "Suggestion"; the owner may keep the old line instead.

### Done in this pass (2026-11-27)
- Oswin as "they": fixed to "he" in §1 and §4 here and in `README.md`.
- This file's header counts.
- Missing texts from the code: added in §12 (the cards, the level-up screen, the Ashbrood toast, the boss-bar hints, the faint note, HUD lines) and in §11 (the "this region is held" prompt line).

### Suggestions only (the owner approved the current wording)
1. **Pumphouse, line 2:** "Scratched on the tank: Light has to be fed from somewhere." Nothing is fed once tending goes (M1b), and the Reservoir Lamp's new job is to force things up out of the water (M5).
   - Suggestion: "Scratched on the tank: What hides in the water hates this light."
   - Related, not flagged by the plan: line 1, "Its tank could feed a lamp for a long time.", also talks about feeding. Owner's call.
2. **Pumphouse, line 3:** "Now go up, north of the reeds. The ridge has glass. - Oswin". Glass stops being a resource (M1b).
   - Suggestion: "Now go up, north of the reeds. The glazier worked up there. - Oswin"
3. **Cairn (optional):** "The wind is worse up there." reads oddly if the marsh has no wind (the plan makes wind Ridge-only, M6).
   - Suggestion (from the plan): "The wind starts up there. Light the marsh before you climb. - Oswin"

### Goals
- `gather_fuel` "Take fuel from the woodpile", `relight_first` "Relight the old lantern by the hut", `relight_waypost` (APPROVED) "Relight the old lamp on the north path": lamps are relit by touch, and there is no fuel (M1b).
- `build_reservoir`, `build_hooded`, `build_mirror`: become "use each lamp" goals, matching each find's new job (M5, M6, M7).
- `kindle_hollow` (APPROVED), `kindle_marsh`, `kindle_ridge`: WayLamps are lit by touch, then you fight (M1b for the Hollow; M5 and M6 for the others). `kindle_marsh` "Kindle the WayLamp by the pumphouse" is also wrong once the marsh WayLamp moves to the north island (M5).
- `burn_nest` (APPROVED) stays.
- New: the Lakeshore's goals (M7); goals 19-24 for the Still Lake (M8) need a look against the fight.

### Tips
- **Cut** (M1b): `cold_lantern`, `low_lantern`, `dying_lantern` (APPROVED), `glass`.
- **Rewrite:**
  - `wickling_close` (APPROVED): teach Lampfire first, not the beam (M1a).
  - `burst`, `shell`, `dash` (all APPROVED): the burst becomes the optional Hearth ring, and Lance breaks shells (M1a).
  - `haven` (APPROVED), "...Fight near it.": in a fight, light no longer warms you and refills charge only slowly (M1a).
  - `build_here` (APPROVED): the plan lists it for rewrite without a reason; likely the new lamp rules (M1b). **Uncertain.**
  - `lamp_empty`, `warmth_low`, `faint`: flasks heal in a fight, and a faint loses nothing (M1a, M1b).
  - `waylamp_seen`, `kindle_attack` (both APPROVED): lit by touch, then a guardian; no ward (M1b).
  - `gust` (M6), `mirror_placed` (M7).
- **New** (M1a unless marked): the flask, Fireglobe, Lance, rest at a WayLamp, a level point (M2), loot and a full bag (M3).

### Notes
- **WayLamp notes:** keep the inscriptions and Oswin's lines (APPROVED). Rewrite the footer: "Feed it 15 fuel." / "While it kindles, the dark will come for it. Keep them off it." / "Lit, it holds this whole region: its lanterns stop burning down, and nothing comes here." (M1b). The Hollow note's Oswin line, "This has to be held until it takes. I could not hold it and keep the rest.", is APPROVED and is kept unless the owner says otherwise.
- **The marsh WayLamp's place:** its notes and the §11 story tie say "on the pumphouse island"; it moves to the north island in M5.
- **Upgrade finds:** the lamp glass line "Your hand lamp reaches further, dims more slowly and wards for longer." (the ward is gone, and the glass gives charge from M1b). The satchel line "You can carry {N} of each now." (satchels become bag slots in M3). Both DRAFT already.
- `crook_post` still fits.
- **The stones** (M6): a toast when they fall, "The way is open."; a chalk note on them, readable from the Hollow side, "Stones down. The way up is through the marsh." Both are the plan's DRAFT lines.

### Journal
- Entry 13 (APPROVED), "I held the WayLamp until it took. Now the Hollow keeps its own lamps.": the Hollow is won by killing the Ashbrood, and lamps no longer need keeping (M1b).
- Entry 15 (APPROVED), "...and only the lake is left.": the Lakeshore comes before the Lake (M7).
- New entries for each guardian (M1b for the Ashbrood; M5-M8).

### Code texts in §12
- The boss-bar hints say "your beam" (M1a: Lance and fire) and "phase N / 2" (M2: three phases).
- The faint note says "Some of what you carried lies where you fell." (M1b: nothing carried is lost; wick waits where you fell).
- The card screen and its 12 cards go in M2. The four APPROVED names stay as branch picks and gear lines.
- "Pick it in the lantern list (Tab / Y)": Y becomes a skill slot in M1a.

### Story beats and feeling
- §1, "**Caring.** Tending light is looking after something, not a chore.": tending goes in M1b. The beat needs a new line (owner's call).
- §4, region 1: "Gather, relight, build." (M1b).
- §9: the finale's lines for the fight, the portal, the credits and waking after (M8).

### New lines the plan needs (none written yet)
- Skills, branch picks, items and relics (M1a-M3); the action bar and the pack screen (M1a, M2).
- Every line for Amos, Maud, Kit, Ebba and Ivo (M4-M7), from `PLAN_NPCS_ENEMIES.md` and `PLAN_LAKESHORE.md`.
- The finale, the portal and the after-game (M8).
