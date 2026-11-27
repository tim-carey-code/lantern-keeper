# Lantern Keeper: people and new creatures (plan)

**DRAFT v1 plan, revised 2026-11-27 with the owner's answers.** Nothing here is built. This is the plan to build from once the owner settles the lines still marked OWNER (listed in section 8).

Sources: docs and scripts on branch `proto/waylamps` at 0ee4633. That commit merged the upgrades and the 2026-11-27 decisions from `main` while this draft was being written. The WayLamp rules come from DESIGN §8 and the WayLamp text from STORY §11. The owner's answers of 2026-11-27 win over older docs. Otherwise DECISIONS wins.

Answered decisions start with DECIDED (2026-11-27):. Open ones start with OWNER:. Mark each open one yes, no or change.

## 1. Summary and what changes

This plan adds four creatures, five people who come back as regions are held, a talk panel, People and Errands pages in the journal, and six optional errands. All of it comes before the Still Lake, in two milestones, M5c and M5d (section 6).

**What changes.** People and short spoken lines move to IN. DESIGN §5 and STORY's header already say so (commit 40f3406). This plan also adds creature kinds beyond ROADMAP's "Wickling variety per region (kept small)".

**What stays.** These are also the guardrails for every line a person says:
1. O.'s marks still lead the main path, and no main goal needs a person.
2. O. is never seen. Nobody saw O. after the letter or knows where O. went.
3. O. signs notes "- O.", with a plain hyphen. O.'s full name (Oswin Reed) never appears in the game, so people call him "O.". Lines may use "he" for O., but none need to.
4. The Soul of the Wick stays "it", with no name. It has big pale eyes. People call it only "it" or "the dark", and don't describe it.
5. Why it rose stays unexplained. People know what they saw, not what it means. The great lamp's plate stays the strongest hint.
6. Light is safe, there is no game over, and amber means safety.

DECIDED (2026-11-27): people and short spoken lines move to IN, under these guardrails. All the people and all the creatures come before the Still Lake.

DECIDED (2026-11-27): the sign-off uses a plain hyphen: "- O.". O.'s full name never appears in the game.

DECIDED (2026-11-27): the Soul of the Wick has big pale eyes. It is still "it", and why it rose is still unexplained. The blanket "no face" rule for creatures is dropped. Section 2 suggests eyes, or none, for each creature.

OWNER: keep people optional, so the game still feels like following O.

DECIDED (2026-11-27): the last keeper is **Oswin Reed**, a man ("he"); the name Hester Vane is dropped.

DECIDED (2026-11-27): he signs "- O." (it was "- H.", for Hester). The spoken lines in this plan that name him say "O.".

### Moved from the Lake (proposal)
The old plan put Ebba and the Fogstilt at the Lake. Everything now comes before the Lake, so each needs an earlier home.
- **The Fogstilt moves to the Windward Ridge, east end.** Its counter, the Mirror Post, is unlocked at the signal station. The old steps beside the station go down into the lake's still fog ("Below, the fog does not move, even in the wind"). The Ridge WayLamp's note already says "the small dark ones came up the steps". The Fogstilt comes up those steps once the Mirror Post is unlocked, and wades toward beams. Details in section 2.
- **Ebba moves to the Reedmarsh, on a boardwalk on the east side.** A rower belongs on water, and the marsh is the water the keeper can reach before the Lake. Ebba comes back once the Reedmarsh is held, and keeps a small boat tied in the reeds. The errand becomes "get light onto Ebba's boat" (a lantern or a beam), so it works before mirrors, and Ebba's tip about the tall ones comes before the Ridge. Details in section 3.

OWNER: confirm both new homes: the Fogstilt at the Ridge's east end, and Ebba in the Reedmarsh.

## 2. New creatures

**Shared rules:**
- **Light is safe.** No creature enters healthy lantern light, harms the keeper in lantern light, or drains or snuffs a lantern above a quarter tank. A dying lantern inside another lantern's healthy light is protected, as in DESIGN §8.
- **No game over.** The keeper only loses warmth or lamp charge. Fainting works as built: half the carried fuel and scrap drops where you fell, and glass is kept. Nothing is destroyed.
- **Counter first.** Each creature appears only after its counter is unlocked.
- **Held ground is quiet.** Nothing spawns in held regions, as with Wicklings. When a region becomes held, creatures inside fade away with no drops, as Wicklings do.
- **WayLamps are left alone.** No new creature targets a WayLamp. Only Wicklings come for one while it kindles.
- **Cool colours.** Amber only where light burns them. Soft sounds, no stingers.

DECIDED (2026-11-27): fainting keeps glass safe, as built.

DECIDED (2026-11-27): the first Wickling comes after 25 s. (Built: `wick_first_delay` is 25 s at 0ee4633; it was 60 s.)

OWNER: held regions stop every creature, not only Wicklings, and creatures inside fade away when a region becomes held.

**Where they live.** If held regions stop every creature, each one only troubles the frontier:

| Creature | Region | Appears | Stops when |
|---|---|---|---|
| Slowwater | the Reedmarsh | on the first visit (the boardwalks, its first counter, are already there) | the Reedmarsh is held |
| Gutterkite | the Windward Ridge | once the Hooded Lamp is unlocked (the glazier) | the Ridge is held |
| Fogstilt | the Ridge's east end | once the Mirror Post is unlocked (the signal station) | the Ridge is held |
| Clinker | any region not yet held | once the keeper reaches the Ridge | that region is held |

### Slowwater (Reedmarsh). Counter: boardwalks and the Reservoir Lamp
- **Look:** a flat shape under the water: a slow V of ripples and two pale eyes.
- **Eyes (suggestion):** keep the two pale eyes, just above the water. They are what you see first. No other face.
- **Behaviour:** follows the keeper through unlit water and holds your feet, so you slow to a crawl and lose warmth. It lets go on planks, on firm ground, in any light, or under the ward.
- **Threat:** the keeper only. Wading in the dark becomes a risk.
- **Counter:** it can't climb onto boardwalks or surface in any light, so the Reservoir Lamp's wide, dim light makes a whole stretch of water safe.
- **Light and no game over:** never touches lanterns.
- **Art:** 16x16. A 4-frame ripple and a 2-frame grab.
- **Knobs:** `slow_max`, `slow_speed`, `slow_sense`, `slow_hold_mult` (about 0.3), `slow_chill_per_sec`.
- **Effort:** S (the Wickling brain, limited to water).

### Gutterkite (Windward Ridge). Counter: the Hooded Lamp
- **Look:** a ragged strip of dark like a torn kite.
- **Eyes (suggestion):** two small pale eyes on its leading edge, so it reads as alive and not as torn cloth.
- **Behaviour:** rides the west wind with the gusts. It can't fly upwind or into the lee of rock. It dives at exposed lanterns under a quarter tank and snuffs them, unless another lantern's healthy light covers them. In the open it brushes the keeper, costing a little warmth and hand-lamp charge.
- **Threat:** low, exposed lanterns go cold. A small cost to the keeper.
- **Counter:** a Hooded Lamp can't be snuffed. A kite that dives at one snags and burns, so Hooded Lamps are kite traps. Rock shelter and the ward also work.
- **Light and no game over:** it veers around healthy light. A snuffed lantern keeps its frame and relights for fuel.
- **Art:** 32x16. A 4-frame flap and a 2-frame burn.
- **Knobs:** `kite_per_gust`, `kite_speed`, `kite_snuff_below` (0.25), `kite_lamp_drain`, `kite_chill`.
- **Effort:** M (reuses the wind's exposure and shelter checks).

### Fogstilt (Windward Ridge, east end; moved from the Lake). Counter: mirror beams
- **Look:** a very tall, thin shadow on stilt legs, still as a heron. You see it only against beams.
- **Eyes (suggestion):** none. An outline with no face keeps "seen only against beams" true, and keeps one creature that is only a shape.
- **Where:** it comes up the old steps out of the still fog, by the signal station, once the Mirror Post is unlocked there. From there it wades the Ridge's unlit fog.
- **Behaviour:** wades toward the nearest beam, keeping out of all light. Fog thickens around it, so a beam passing within about 2 tiles fades out short and the rest of the chain goes dark.
- **Threat:** mirror chains. Wicklings smother mirrors; Fogstilts cut the beams between them.
- **Counter:** one beam makes it step away, and two beams crossing on it unravel it: practice for the Lake and the finale.
- **Light and no game over:** it stays out of all light, the hand lamp and the ward included, so it never touches the keeper. It drains nothing. When it leaves, the beam reaches again.
- **Its time is short.** The Ridge's WayLamp stands by the signal station, and kindling it is the goal right after the first lit mirror. If held regions stop every creature, most players meet the Fogstilt only between those two goals, and few will cross two beams on it before the Lake. The M5d playtest checks this.
- **Art:** 16x32. A 4-frame wade and a 3-frame unravel.
- **Knobs:** `stilt_max`, `stilt_speed`, `stilt_reach`, `stilt_beam_cut`, `stilt_unravel_sec`.
- **Effort:** M (a beam-length hook in the Mirror Post, plus a two-beam check). The move adds only a spawn point.

### Clinker (any region not yet held, from the Ridge on). Counter: the Post Lamp
- **Look:** a slow, cart-sized heap of charred dark with cold blue cracks.
- **Eyes (suggestion):** no face; the cracks are its only marks. Option: two cracks that open like sleepy eyes when it settles, which fits "like a cat on a cold hearth".
- **Where:** any region not yet held, once the keeper has reached the Ridge. For a player who kindles each WayLamp when the goals ask, that means the Ridge.
- **Behaviour:** rolls to a cold lantern frame that no healthy light covers, and settles on it like a cat on a cold hearth. Nobody can relight that frame while it sits there.
- **Threat:** blocks relighting. Touching it chills.
- **Counter:** build a Post Lamp next to it (its core burns it away), or push it with the ward, which can't burn it, into a lantern's core or a beam.
- **Light and no game over:** never touches lit lanterns, the hut's lantern or a WayLamp (nothing may be built close enough to a WayLamp to burn it off). It rolls on by itself after about 2 minutes.
- **Art:** 32x32. A 4-frame roll, a 2-frame settle and a 2-frame burn.
- **Knobs:** `clinker_max` (1-2), `clinker_speed`, `clinker_hp`, `clinker_push_mult`, `clinker_settle_sec`.
- **Effort:** M (push handling and soft-lock guards).

DECIDED (2026-11-27): add a small **Lakeshore** region between the Ridge and the Lake, down the old steps, in the empty north-east of the map. The Fogstilt and Ebba move there (beams cut the Fogstilt's fog: a warm-up for the Lake). The Ridge keeps the Gutterkite; the Clinker roams whatever isn't held. The region's design is drafted separately for owner markup; the Fogstilt and Ebba sections below still show their earlier homes until it is approved.

### In v1
All four, before the Lake. The Gutterkite and the Fogstilt give the Hooded Lamp and the Mirror Post a second job. The Slowwater adds pressure while players are still learning, so it is the gentlest. The Clinker needs soft-lock testing. Difficulty still grows with distance from the hut, as ROADMAP plans: the marsh gets one new creature and the Ridge gets three, so the M5d playtest checks that the Ridge isn't too busy.

DECIDED (2026-11-27): all four creatures go in v1, before the Still Lake: the Gutterkite in M5c, and the Slowwater, the Clinker and the Fogstilt in M5d.

### The Soul of the Wick
All four come from the Soul, like Wicklings, though no text says so outright. The Soul has big pale eyes, and Wicklings have two pale eyes, as built. Eyes on the new creatures are suggestions, above. The finale stays a light confrontation with some pressure. When the great lamp catches, every creature unravels.

DECIDED (2026-11-27): keep "Big pale eyes" in the Soul's ART_CHECKLIST entry. (The old line proposed striking it.)

OWNER: add one or two Fogstilts to the second half of the finale, or keep it to Wicklings. With the Fogstilt now on the Ridge, this would bring it back at the end.

## 3. People: the valley comes back where it is held

When a region's WayLamp is kindled, people come back ("Someone has come back to the Reedmarsh."). Each stays at one spot in held ground with a small lamp, and never goes into the dark, follows the keeper, fights or needs rescuing. Each stands a few tiles from landmarks, upgrade finds and WayLamps, so one button never means two things.

| Region held | Who comes back | Where |
|---|---|---|
| The Hollow | Amos | by the hut |
| The Reedmarsh | Maud and Ebba; Ivo too, once two regions are held | the pumphouse; a boardwalk on the east side; the carved stone |
| The Windward Ridge | Kit | the glazier's workshop |

OWNER: approve the rule: people come back to a region once its WayLamp is kindled. (It depends on the WayLamp playtest.)

### Amos Patch, trader (the Hollow)
- **Who:** a travelling trader with a handcart, who sold the keepers oil and glass.
- **Where, when, why:** by the hut once the Hollow is held. Lit roads mean customers.
- **Errand:** "Light the road" (three lanterns lit along the marsh passage, so the cart can pass).
- **Fragment:** O.'s last order, from before the letter: only glass, no oil.
- **Reward:** trading (3 fuel for 1 scrap, and 4 scrap for 1 glass once the Ridge is held) and the Wide Pack: +10 carry of each resource, on top of the satchels (70 with all three).
- **Personality:** cheerful and practical. Scared of the dark, and pretending not to be.
- **Lines:**
  - "Lights on the road again. Lights mean people. People mean trade."
  - "O. ordered glass once. No oil. Just glass, all I had."

### Maud Fallow, old pump keeper (the Reedmarsh), who knew O.
- **Who:** an old keeper who ran the marsh pump with O. for years, then left as the lamps failed.
- **Where, when, why:** at the pumphouse once the Reedmarsh is held. Saw it lit from the hills and came back, ashamed of leaving.
- **Errand:** "Maud's lamp" (fetch it from the lantern rack by the hut).
- **Fragment:** Maud and O. argued as the ledger counts fell; Maud left, O. stayed. Maud doesn't know why it came.
- **Reward:** the old lamp's glass, fitted to your hand lamp. It counts as a fourth lamp glass, on top of the three found in the world. The rack note becomes "Two hooks are empty now."
- **Personality:** blunt and dry. Guilty, but kind underneath.
- **Lines:**
  - "You're the one who answered. O. always did find someone."
  - "We argued over that ledger. I left. O. stayed. That's all of it."
  - "Why did it come? I've had years to think. I still don't know."

### Kit Brand, glazier's apprentice (the Windward Ridge)
- **Who:** the old glazier's apprentice.
- **Where, when, why:** at the workshop once the Ridge is held, back to see if the kilns survived.
- **Errand:** "Fire the kiln" (bring 8 fuel and 3 glass).
- **Fragment:** every lamp was lit from the great lamp; the great lens split the night the lake went still.
- **Reward:** polished mirrors. Beams reach 13 tiles instead of 11. Nothing else in the game gives mirror reach.
- **Personality:** quick, proud of the craft, talks shop.
- **Lines:**
  - "You finished the hood? Not bad. The seam's a bit wide."
  - "Every lamp here was lit from the great lamp. One flame, passed along."
  - "The big lens split the night the lake went still. I heard it from this bench."

### Ebba Tarn, rower (the Reedmarsh; moved from the Lake)
- **Who:** rowed for the keepers, across the marsh and out to the island. The boat on the lake shore is Ebba's.
- **Where, when, why:** at the end of a boardwalk on the marsh's east side, once the Reedmarsh is held. Ebba's small marsh boat is tied in the reeds a few tiles out, where no lantern can stand. Ebba came back to water that still moves, and won't go near the lake. After the finale (built with the Lake): by the lake boat.
- **Errand:** "Show me the boat" (get light onto the marsh boat: a lantern's light or a beam, as for a WayLamp; the hand lamp doesn't count). After the finale, "Row out" (bail the lake boat; built with the Lake).
- **Fragment:** on the night it went dark, the lake went still. Ebba tied up the lake boat and walked away.
- **Reward:** 10 fuel and a tip about the Fogstilts on the Ridge. After the finale, a boat crossing to the island and the far shore (a map feature).
- **Personality:** quiet, careful, a little superstitious.
- **Lines:**
  - "The night it went dark, the lake didn't freeze. It went still. Even the reeds stopped."
  - "There are tall ones up by the old steps. One light moves them. Two send them off." (Was "out on the water". The Fogstilt now lives on the Ridge.)
  - "That light past the far shore? I don't know who keeps it. Nobody lived out there." (After the finale.)

### Ivo Withey, mapmaker (the marsh road)
- **Who:** drew the keepers' lamp maps.
- **Where, when, why:** at the carved stone on the marsh road once two regions are held, to draw the valley again.
- **Errand:** "Walk the edges" (read three new survey stones, one each in the Hollow, the Reedmarsh and the Ridge).
- **Fragment:** no old map shows a lamp past the lake. O. borrowed Ivo's best map and never returned it.
- **Reward:** the map shows resource spots and unread notes in held regions.
- **Personality:** fussy, precise and warm. Measures in paces.
- **Lines:**
  - "O. borrowed my best map. Never brought it back. I hope it helped."
  - "No lamps past the lake on any map. There was nothing out there to keep."
- **Landmark count:** with the stones the game has 24 story landmarks (13 built, 8 planned for the Lake, 3 stones). The three WayLamp notes would make 27. The six upgrade finds, also built as readable landmarks, would make 33. The target is 15-25.

OWNER: which readable things count toward the 15-25 landmarks? Story marks only (24 with the stones), or also the WayLamp notes (27) and the upgrade finds (33)?

DECIDED (2026-11-27): keep all five people. All of them come before the Lake.

## 4. Dialogue system

| Option | Effort | Tone | Controller |
|---|---|---|---|
| (a) Talk panel, 2-4 lines a visit | S-M (reuses the note panel, which pauses the world) | matches the notes; keeper silent | one button ("[A] Talk") |
| (b) Two-answer choices at set moments | M (choice UI, more states) | gives the keeper a voice | two buttons |
| (c) Full dialogue trees | L (a dialogue tool, many lines) | invites explaining the mystery | menus every time |

**Recommendation: (a).** Lines follow progress: first meeting, errand open, errand done, later visits and after the finale. Amos trades through a Trade menu styled like the lantern cards.

OWNER: use (a), the talk panel, for v1. Revisit (b) only if playtests ask for it. (M5c assumes (a).)

**Journal.**
- **People:** one card per person met, with name, place, one line in the keeper's voice and every fragment heard. Unmet people stay hidden.
- **Errands:** open and finished errands, apart from Goals. The goal banner and pointer stay for main goals.
- The tabs become Goals, Errands, People, Story so far and Notes.

OWNER: give Errands and People their own pages, or fold Errands into Goals. (M5c assumes their own pages.)

**What must be saved** (a new "people" section):
- for each person: arrived, met, lines seen, errand state and partial deliveries;
- people's upgrades go into the upgrades list that the satchels and lamp glasses already use (`Progress.upgrades`, saved as built). The Wide Pack is one more "carry" entry and Maud's glass one more "lamp" entry, so they stack with no new code. Polished mirrors is a new "mirror" entry that the beam length reads;
- world changes: Maud's lamp off the rack, survey stones read, and (with the Lake) the lake boat bailed;
- not saved: creatures, which respawn like Wicklings.

Read it with defaults, so version-2 saves still load.

## 5. Errands (all optional)

1. **Light the road** (Amos): lanterns along the marsh passage. Reward: trading and the Wide Pack (+10 carry, on top of the satchels).
2. **Maud's lamp** (Maud): fetch it from the rack by the hut. Reward: a fourth lamp glass.
3. **Fire the kiln** (Kit): 8 fuel and 3 glass. Reward: mirror beams reach 13 tiles.
4. **Show me the boat** (Ebba): get light onto the marsh boat. Reward: 10 fuel and a tip about Fogstilts.
5. **Row out** (Ebba, after the finale; built with the Lake): bail the lake boat. Reward: a crossing to the island and the far shore.
6. **Walk the edges** (Ivo): read three survey stones. Reward: resources and unread notes on the map.

OWNER: the rewards and trade rates are placeholders. Flag any that feel too strong (polished mirrors is the biggest).

## 6. Phasing and effort

DECIDED (2026-11-27): build all of it after the WayLamp playtest and before the Still Lake, in two milestones. Each ends in an owner playtest.

**Before M5c:** the WayLamp playtest passes, because people need "held" to work. Already done in 40f3406: the satchels and lamp glasses, which the Wide Pack and Maud's glass stack on, and the 25 s first Wickling.

1. **M5c: talk, and the first three people.** The talk panel, the journal's People and Errands pages, the save section and the arrival line; Amos (with the Trade menu and the Wide Pack), Maud and Kit; the Gutterkite. Effort L, about the size of M5a. Ends with an owner playtest.
2. **M5d: the other creatures and people.** The Slowwater, the Clinker and the Fogstilt (on the Ridge); Ebba (with the marsh boat) and Ivo (three survey stones and the map reward). The save section grows to cover them. Effort L: three creatures, and the Clinker's soft-lock guards are the biggest unknown. Ends with an owner playtest.
3. **With the Still Lake, or later:** Ebba's "Row out" and the crossing, and Fogstilts in the finale if chosen.

**Why this split.** It keeps the suggested split, because no swap is clearly better. M5c builds every shared system once and tests it with one person per held region and one creature. M5d is mostly creatures, so its playtest can look at pressure, the busy Ridge and soft-locks. Ebba's tip names the Fogstilt, so the two land together. Moving the Slowwater (S) into M5c would show a creature earlier, but M5d would then hold all three Ridge creatures with nothing light to balance them.

**M5c playtest questions:**
1. Did a held region feel better to come back to with someone there?
2. Was the talk panel quick, and did the lines sound like the notes?
3. Did the errands feel optional, and worth doing?
4. Did the Gutterkite give the Hooded Lamp a second job, or just punish open lanterns?

**M5d playtest questions:**
1. Did you meet the Fogstilt before the Ridge was held? Did crossing two beams make sense?
2. Was the Ridge too busy with kites, stilts and the Clinker?
3. Did a Clinker ever leave a frame you couldn't relight?
4. Did the Slowwater make wading a choice, not a chore?
5. Three people come back when the Reedmarsh is held. Too many at once?

**New art.**
- People: five 16x16 sprites, each with a 2-frame idle and a 2-frame talk. The keeper's frames are 32x32 (recoloured Puny Characters), so 16x16 people may look small; more Puny Characters can stand in. No portraits in v1 (the panel shows the name and the sprite at 4x).
- Props: Amos's cart (32x16), three survey stones (16x16) and Ebba's marsh boat (32x16; it can reuse the lake boat already on the art list).
- Creatures: as in section 2.

DECIDED (2026-11-27): people are drawn at the keeper's 32x32 scale; no portraits in v1.

**New sounds.** No voices. One soft sound per person when the panel opens (cart bell, pump creak, glass chime, oar knock, paper rustle) and a chime when people come back. Creatures: kite flutter, slow wading, bubbles, a low grind. No stingers.

## 7. Open questions for the owner

OWNER: can a held region be lost again? If so, people shelter indoors until its WayLamp is relit.

OWNER: is the great lamp the Lake's WayLamp? Then the Lake is held only after the finale, when Ebba goes down to the lake boat. (STORY §11 and DESIGN §8 already say "the great lamp is the last one".)

DECIDED (2026-11-27): people's rewards add to the upgrades and don't replace them. The upgrades are built (40f3406) as finds in the world: three keeper's satchels (+10 carry of each resource) and three lamp glasses (per glass: the hand lamp reaches 12 px further, dims 25% more slowly, and the ward costs 15% less charge), one of each per built region. Mirror reach (Kit) stays a people-only reward.

OWNER: may people say the keeper's typed name once, at the first meeting?

OWNER: all names are drafts. Choose pronouns for the five people, or keep avoiding them, as for O.

OWNER: how close may people come to existing hints? Draft: Kit echoes the plate and the lens ("every flame"); nobody says how many kept the great lamp.

OWNER: after the finale, do region creatures stop for good, leaving a few Wicklings in unheld dark ("thinner, not gone")?

OWNER: with the pointer off after the Hollow, may people give one soft hint toward the current goal?

## 8. Still open

Needed before M5c:
- The WayLamp playtest result, and §7: can a held region be lost again?
- §3: people come back when a region's WayLamp is kindled.
- §2: held regions stop every creature, and creatures fade when a region becomes held.
- §4: the talk panel (a), and Errands and People as their own pages. M5c assumes both.
- §1: keep people optional. Guardrail 1 already says no main goal needs a person.

Needed before M5d:
- The Lakeshore design (region, WayLamp, notes, goals), drafted separately.
- §1: the new homes for the Fogstilt and Ebba.
- §3: which readable things count toward the 15-25 landmarks.

Before lines are written:
- §7: the keeper's typed name, pronouns for the five, how close to the hints, and one soft hint toward the goal.
- §5: rewards and trade rates (tune in the playtests).

With the Still Lake:
- §2: Fogstilts in the finale.
- §7: the great lamp as the Lake's WayLamp, and creatures after the finale.
