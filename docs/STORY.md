# Lantern Keeper — Story Outline (draft for owner markup)

> **Draft, awaiting owner review** (milestone M5a). Lines starting with **OWNER:** are places to decide or rewrite.
> Sources: DESIGN.md, DECISIONS.md, ROADMAP.md, landmark texts in `scripts/main/main.gd`.
> Voice for all in-game text: short, plain sentences. Calm, a little sad, a little eerie. Never horror. No dialogue.

---

## 1. Premise and feeling

**Premise.** You are the new keeper of a dark, foggy valley. You came because of a letter from the last keeper, written when the lamps were going out faster than one person could relight them. The letter asks you to light the old lantern by the hut and follow the marks they left. Those marks are the landmarks: each carries a short note and points to the next place. The trail runs east through the marsh, north up the windy ridge, and down to the Still Lake, where the great lamp stands cold with the Soul of the Wick coiled around it. You learn **who** took the light. You do not learn **why**, or for sure what became of the last keeper.

**The feeling:**
- **Caring.** Tending light is looking after something, not a chore.
- **Following someone.** Always one step behind a person you never meet. Their notes keep you company.
- **Quietly uneasy.** The dark is not empty, but never cruel. Fainting is a rest, not a punishment.
- **Relief.** When the great lamp relights and the fog lifts, it feels like a long breath out.

OWNER: Keep "the new keeper answers a letter", or choose another way in (e.g. the keeper simply wakes in the hut)?

---

## 2. Characters

**The new keeper (player).** No name, face or voice by default. New to the valley; knows only what the player knows. Writes the journal.

OWNER: Keep the keeper unnamed, or let the player type a name that signs the journal?

**The last keeper.** Suggested name **Hester Vane**; alternatives **Tobin Ash**, **Nell Corrie**, **Oswin Reed**. Signs every note "— H.", so the full name can change cheaply. Kept the valley alone after the others left: tired, stubborn, kind. Went ahead to the Lake, lost their coat on the Ridge, left a half-built mirror on the shore. Fate not confirmed. This draft avoids pronouns for them where it can.

OWNER: Pick the name (or keep only "H.") and the pronouns.

**The Soul of the Wick.**
- A living darkness that feeds on flame. It rose out of the Still Lake, coiled around the great lamp and drank its light.
- Then it was hungry for the rest of the valley. It never speaks and has no face: a coil of black that moves like smoke under water.
- THE WICK REMEMBERS EVERY FLAME hints that it was once part of the light, or made from it.
- **Left unexplained:** why it rose, whether it was always there, whether the keepers woke it, where it goes when driven off.

OWNER: DECISIONS calls it "he"; this draft uses "it" to keep it strange. Which?

**The Wicklings.** Small pieces of the Soul of the Wick that wander the dark. They crawl toward warmth, drain lanterns and chill the keeper. Hungry, not cruel: moths turned inside out. More and bolder the farther you go from the hut.

**The old keepers' order.** Suggested name **the Keepers of the Long Light** (alternatives: **the Lampwardens**, **the Valley Watch**; in the world mostly "the keepers"). They tended the posts, ran the pump, cut glass on the Ridge and passed light by mirror to the great lamp. When it went cold, the other lamps failed one by one and the keepers left. One stayed.

OWNER: Name the order, or keep it nameless.

---

## 3. The letter and the title card

**Title card** (over black, before the letter):

> The valley had keepers once.
> Then the lamps went out, one by one.
> Now there is a letter, and you.

**The letter** (~70 words). Shown on paper at a new game; one button to continue. Also pinned to the hut door (landmark `letter`) and kept as the first journal page.

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
> — H., the last keeper

OWNER: Rewrite the letter in your words if you like (under ~90 words).

---

## 4. Beat sheet by region

| Region | Player learns | Emotional beat | Points onward |
|--------|---------------|----------------|---------------|
| **1. The Hollow** | Gather, relight, build. Many keepers once counted their lamps; one stayed longest. | Arriving somewhere abandoned but not hopeless. The first flame is a small welcome. | Ledger: "Gone east to the marsh. Follow the stones." Fresh chalk arrow on the carved stone. Pointer is on. |
| **2. The Reedmarsh** | The way to the water was kept lit. Every frame faces the lake. The lake once shone; then something dark coiled around it. The pump still works. | Curiosity turning to unease. The chalk is the first sign that something *took* the light. | Pumphouse note: "Now go up, past the Hollow. The ridge has glass." |
| **3. The Windward Ridge** | Keepers made glass and passed light by mirror. The Wick remembers every flame. H. lost their coat here and wrote: "It came up out of the water." | Exposure and worry. The loneliest place in the game. | The station's mirror has been turned down toward the lake; steps beside it lead into the fog. |
| **4. The Still Lake** | Ordinary light dies here; only beams cut through. H. camped on the shore and built a mirror with no light to give it. Every keeper's name is on the island steps. | Stillness and dread, then resolve: finishing what H. started. | H.'s mirror faces the island. Build the chain to the great lamp. |
| **5. Finale** | Who took the light: the Soul of the Wick. Light drives it off. | A quiet confrontation, not a battle. Tension, then release. | The fog lifts over the whole valley. |
| **6. After** | Nothing more is required. | Rest. The valley is lit and open; the dark is thinner, not gone. | Optional goals. Far past the lake, one small light that was not there before (hook for later). |

OWNER: Is the after-game "far light" (a hint that H. is alive) right, too much, or too little?

---

## 5. Goal list

One goal shows on the HUD at a time; the journal lists the current goal and finished ones. The pointer (amber arrow) is **on for G01-G06 (the Hollow)** and off by default after, unless turned back on in settings. If the player finishes a goal early, skip to the first unfinished one.

| # | id | HUD text | Completes when | Pointer target |
|---|----|----------|----------------|----------------|
| 1 | `gather_fuel` | Take fuel from the woodpile | Carrying at least 1 fuel | Woodpile |
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
| 18 | `descend` | Take the old steps down to the lake | Enter the Still Lake | `ridge_steps` |
| 19 | `camp` | Find where H. stopped | `camp` read | Camp |
| 20 | `first_beam` | Send a beam out over the water | A beam reaches lake fog | — |
| 21 | `reach_island` | Carry light to the island | A beam reaches the island | Island |
| 22 | `great_lamp` | Climb the steps to the great lamp | Reach the great lamp | Great lamp |
| 23 | `drive_off` | Drive the dark from the great lamp | Finale done, lamp lit | Great lamp |
| 24 | `keep_valley` | The valley is yours to keep | Never (free play) | — |

Optional after-game goals (journal only): `all_notes` "Find every note H. left"; `all_frames` "Relight every old frame"; `far_light` "Look toward the far shore" (reach `far_shore`).

Lens comes before coat because it sits west of the coat (`_ridge_spot(30, 9)` vs `(42, 22)`), so the trail runs west to east: glazier, lens, coat, station.

OWNER: Too fine-grained? The build goals (4, 10, 13, 17) could merge into the unlock goals.
OWNER: Turn the pointer off on entering the marsh (draft), or later?

---

## 6. Landmark texts

### Rewrites of the 9 existing landmarks
Each quoted line is one line on screen.

**`ledger`** (Hollow, by the hut)
> Long columns of tally marks, one for every lamp lit each night.
> Near the end the columns shrink to a single mark, in a newer hand.
> Under it: Gone east to the marsh. Follow the stones. — H.

**`stone_way`** (passage to the marsh)
> KEEP THE WAY TO THE WATER LIT.
> Below the old letters, a fresh chalk arrow points east.

**`frames_east`** (marsh boardwalk)
> Three empty frames along the boardwalk, all turned east, toward the lake.
> A rag is tied to the last one: The pump still works. Wake it. — H.

**`chalk_lake`** (pumphouse wall)
> Two drawings of the same lake. In the first it shines.
> In the second, something dark is coiled around the light.
> Beside them, newer chalk: I went to look. — H.

**`pumphouse`** (unlocks Reservoir Lamp)
> The old pump still turns when you push it. Its tank could feed a lamp for a long time.
> Scratched on the tank: Light has to be fed from somewhere.
> Now go up, past the Hollow. The ridge has glass. — H.

**`glazier`** (Ridge, unlocks Hooded Lamp)
> Cold kilns and racks of cut glass. A half-finished hood sits on the bench,
> shaped to keep a flame alive in any wind.
> A note under it: Finish it. I could not stay. — H.

**`lens`** (Ridge)
> A great curved lens, split down the middle. Scratched into the frame:
> THE WICK REMEMBERS EVERY FLAME.
> Below, in a newer hand: Then it will remember ours. — H.

**`coat`** (Ridge)
> Snagged on the rocks, stiff with frost. An H is stitched inside the collar.
> In the pocket: "It came up out of the water. It drank the great lamp.
> Now it is hungry for the rest. Only mirrors reach the lake."

**`station`** (Ridge east end, unlocks Mirror Post)
> A tall post with a cracked mirror. Keepers passed light from post to post, all the way to the lake.
> Someone has turned the mirror down, toward the water.
> Old steps beside it go down into the fog.

OWNER: The coat note now belongs to H. (it was an unnamed keeper). Keep that link?

### New landmarks (12)
In the Text column, " / " marks a line break.

| id | Object | Region | Text |
|----|--------|--------|------|
| `letter` | The letter, pinned to the hut door | Hollow | The letter that brought you here. The ink has run a little. / Light that first. Then follow my marks. — H. |
| `rack` | Lantern rack in the hut | Hollow | Five hooks, five worn marks where lamps hung. / Only one hook is empty. Its mark is the cleanest. |
| `climb_cairn` | Stone cairn at the foot of the climb | Hollow (top) | A small cairn, a chalk arrow on the top stone, pointing up. / The wind is worse up there. Keep your lights sheltered. — H. |
| `ridge_steps` | Steps cut into the rock | Ridge (east end) | Old steps, worn smooth, going down. / Below, the fog does not move, even in the wind. |
| `boat` | A boat tied at the shore | Lake | A boat half full of rain, the oars still in it. / Past the reeds the fog is too thick to row through. |
| `drowned_frames` | Frames standing in the shallows | Lake | A row of frames in the shallows. Their glass is clean. / Someone tried to light them. The fog swallowed every one. |
| `camp` | The last keeper's camp | Lake shore | Cold ashes, a blanket, a tin cup. / A Mirror Post aimed at the island, waiting for light. / H. was here. Not long ago. |
| `pier_stone` | Carved stone at the end of the pier | Lake | FROM THE ISLAND, LIGHT. FROM THE KEEPERS, CARE. |
| `island_steps` | Steps up to the great lamp | Island | A name cut into every step, one for each keeper. / The newest name is only half cut. |
| `great_lamp` | Plate on the great lamp's base | Island | THE FIRST FLAME OF THE VALLEY. / IT WAS NEVER MEANT TO BE KEPT BY ONE. |
| `hand_lamp` | A hand lamp on the top step (after the finale) | Island | A keeper's hand lamp, set down with care. It is cold. / Beside it, in chalk: Thank you. Keep it lit. — H. |
| `far_shore` | A post on the far shore, facing away | Lake (far side) | A new post, freshly cut. Its lamp is gone. / Far off, past the end of the valley, one small light is burning. |

Total: 21 landmarks (inside the 15-25 target).

OWNER: `camp` gives a ready-made Mirror Post as a teaching aid. Keep, or have the player build every mirror?
OWNER: The `great_lamp` plate is the only hint at "why". Keep, soften, or cut?

---

## 7. Journal "story so far"

One entry after each beat, written by the keeper. Notes read are listed under each entry.

1. **Arrival** (goal 2): *I came because of the letter. The old lantern took the flame on the first try. One hook on the rack is empty.*
2. **The ledger** (3): *The keepers counted every lamp they lit. At the end, one mark a night. H. went east.*
3. **The marsh** (7): *The frames all face east, toward a lake I cannot see.*
4. **The pumphouse** (9): *The chalk shows the lake, bright, then dark. Something coiled around its light. The pump still works.*
5. **The climb** (11): *H. sent me up. The wind pulls at every flame.*
6. **The workshop** (12): *H. could not stay to finish the hood. I did.*
7. **The coat** (15): *H.'s coat, caught in the rocks. Something came up out of the water and drank the great lamp. I hope H. found somewhere warm.*
8. **The station** (16): *H. turned the last mirror toward the lake. That is where H. went.*
9. **The lake** (19): *Ordinary light dies here. H. built a mirror and had nothing to give it. I do.*
10. **The island** (22): *A name on every step. The newest is not finished. The great lamp is cold, and it is not alone.*
11. **The light returns** (23): *It let go. The great lamp caught, and the fog lifted. I could see the hut from the island.*
12. **After** (`hand_lamp` read): *H. left their lamp for me. Past the far shore there is a small light. I will keep this one lit.*

OWNER: First person (draft), or a neutral log ("The keeper found...")?

---

## 8. First-time tips

Shown once each, at the bottom of the screen, for a few seconds. The ward tip shows the real bound key (F / RB / RT).

| Trigger | Tip |
|---------|-----|
| First cold lantern | A cold lantern keeps its frame. A little fuel will wake it. |
| First low lantern | Lanterns burn down. Top them up before they go cold. |
| First fog edge | Fog comes back where light fades. Light holds the ground. |
| First gust warning | Wind is coming. Rock on the windward side shelters a flame. |
| First Wickling seen | Something small moves in the dark. It is drawn to your lights. |
| First Wickling close | Hold F to swell your lamp. Wicklings cannot bear it. |
| Hand lamp empty | Your lamp is down to an ember. Rest in a lantern's light to fill it. |
| Warmth low | You are getting cold. Stand in a lantern's light. |
| First faint | You woke by the nearest light. What you dropped waits where you fell. |
| First glass | Glass. The keepers on the ridge made lamps from it. |
| First Mirror Post placed | A mirror needs light. Stand it inside a burning lantern's glow. |
| First lit mirror | Interact to turn the beam. Beams pass from mirror to mirror. |

OWNER: Add a "show tips again" option in settings?

---

## 9. The finale

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

OWNER: Calm puzzle (light every side, no clock), or some pressure (the coil drains the lanterns feeding the mirrors)?

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

OWNER: Rewrite the ending in your words if you like (under ~80 words).

---

## 10. Open questions for the owner

1. **Premise:** keep the letter from the last keeper, or another way in?
2. **H.'s fate:** open (hand lamp + far light, as drafted), confirmed alive, or never mentioned?
3. **Names:** last keeper, the order, and whether the player keeper has a name.
4. **The Soul of the Wick:** "it" or "he"; and is it only hungry, or something more?
5. **The "why" hint:** keep the great lamp plate, or keep "why" fully silent for now?
6. **Pointer:** off on entering the marsh, or later?
7. **Finale:** calm puzzle or light pressure?
8. **Goals:** 24 steps, or merge build goals into unlock goals?
