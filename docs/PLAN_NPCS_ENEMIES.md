# Lantern Keeper: people and new creatures (plan)

**DRAFT for owner markup, 2026-11-26.** This is a plan only. Nothing here is built.

Sources: docs and scripts at snapshot 9a2b9cc; DECISIONS wins. The WayLamp and quarter-tank rules come from the brief, not the snapshot.

Every decision is on its own line starting with OWNER:. Mark each one yes, no or change.

## 1. Summary and what changes

This plan adds four creatures (two for v1), five people who come back as regions are held, a talk panel, People and Errands pages in the journal, and six optional errands.

**What changes.** DESIGN (§6 and its OUT list) and STORY.md ("No dialogue") keep characters and dialogue out. This plan moves people and short spoken lines to IN, and adds creature kinds beyond ROADMAP's "Wickling variety per region (kept small)".

**What stays.** These are also the guardrails for every line a person says:
1. H.'s marks still lead the main path, and no main goal needs a person.
2. H. is never seen. Nobody saw H. after the letter or knows where H. went.
3. No pronouns for H. (still undecided).
4. The Soul of the Wick stays "it": no name, no face. Nobody describes it beyond "it" or "the dark".
5. Why it rose stays unexplained. People know what they saw, not what it means. The great lamp's plate stays the strongest hint.
6. Light is safe, there is no game over, and amber means safety.

OWNER: approve the scope change: people and short spoken lines move to IN, under these guardrails.

OWNER: keep people optional, so the game still feels like following H.

## 2. New creatures

**Shared rules:**
- **Light is safe.** No creature enters healthy lantern light, harms the keeper in lantern light, or drains or snuffs a lantern above a quarter tank.
- **No game over.** The keeper only loses warmth or lamp charge, and fainting works as now. Nothing is destroyed.
- **Counter first.** Each creature appears only after its counter is unlocked.
- **Held ground is quiet.** Nothing spawns in held regions, as with Wicklings.
- **Cool colours.** Amber only where light burns them. Soft sounds, no stingers.

OWNER: held regions stop every creature, not only Wicklings.

### Slowwater (Reedmarsh). Counter: boardwalks and the Reservoir Lamp
- **Look:** a flat shape under the water: a slow V of ripples and two pale eyes.
- **Behaviour:** follows the keeper through unlit water and holds your feet, so you slow to a crawl and lose warmth. It lets go on planks, on firm ground, in any light, or under the ward.
- **Threat:** the keeper only. Wading in the dark becomes a risk.
- **Counter:** it can't climb onto boardwalks or surface in any light, so the Reservoir Lamp's wide, dim light makes a whole stretch of water safe.
- **Light and no game over:** never touches lanterns.
- **Art:** 16x16. A 4-frame ripple and a 2-frame grab.
- **Knobs:** `slow_max`, `slow_speed`, `slow_sense`, `slow_hold_mult` (about 0.3), `slow_chill_per_sec`.
- **Effort:** S (the Wickling brain, limited to water).

### Gutterkite (Windward Ridge). Counter: the Hooded Lamp
- **Look:** a ragged strip of dark like a torn kite. No face.
- **Behaviour:** rides the west wind with the gusts. It can't fly upwind or into the lee of rock. It dives at exposed lanterns under a quarter tank and snuffs them. In the open it brushes the keeper, costing a little warmth and hand-lamp charge.
- **Threat:** low, exposed lanterns go cold. A small cost to the keeper.
- **Counter:** a Hooded Lamp can't be snuffed. A kite that dives at one snags and burns, so Hooded Lamps are kite traps. Rock shelter and the ward also work.
- **Light and no game over:** it veers around healthy light. A snuffed lantern keeps its frame and relights for fuel.
- **Art:** 32x16. A 4-frame flap and a 2-frame burn.
- **Knobs:** `kite_per_gust`, `kite_speed`, `kite_snuff_below` (0.25), `kite_lamp_drain`, `kite_chill`.
- **Effort:** M (reuses the wind's exposure and shelter checks).

### Fogstilt (Still Lake). Counter: mirror beams
- **Look:** a very tall, thin shadow on stilt legs, still as a heron. No face. You see it only against beams.
- **Behaviour:** wades the lake fog, out of reach, toward the nearest beam. Fog thickens around it, so a beam passing within about 2 tiles fades out short and the rest of the chain goes dark.
- **Threat:** mirror chains. Wicklings smother mirrors; Fogstilts cut the beams between them.
- **Counter:** one beam makes it step away, and two beams crossing on it unravel it: practice for the finale.
- **Light and no game over:** it stays out of all light, drains nothing and never comes ashore. When it leaves, the beam reaches again.
- **Art:** 16x32. A 4-frame wade and a 3-frame unravel.
- **Knobs:** `stilt_max`, `stilt_speed`, `stilt_reach`, `stilt_beam_cut`, `stilt_unravel_sec`.
- **Effort:** M (a beam-length hook in the Mirror Post, plus a two-beam check).

### Clinker (any region not yet held, after the Ridge). Counter: the Post Lamp
- **Look:** a slow, cart-sized heap of charred dark with cold blue cracks. No face.
- **Behaviour:** rolls to a cold lantern frame and settles on it like a cat on a cold hearth. Nobody can relight that frame while it sits there.
- **Threat:** blocks relighting. Touching it chills.
- **Counter:** build a Post Lamp next to it (its core burns it away), or push it with the ward, which can't burn it, into a lantern's core or a beam.
- **Light and no game over:** never touches lit lanterns or the hut's lantern, and rolls on by itself after about 2 minutes.
- **Art:** 32x32. A 4-frame roll, a 2-frame settle and a 2-frame burn.
- **Knobs:** `clinker_max` (1-2), `clinker_speed`, `clinker_hp`, `clinker_push_mult`, `clinker_settle_sec`.
- **Effort:** M (push handling and soft-lock guards).

### Recommendation
- **In v1: the Gutterkite and the Fogstilt.** They give the Hooded Lamp and the Mirror Post a second job, and the Fogstilt teaches the finale. Difficulty grows with distance from the hut, as ROADMAP plans.
- **Later: the Slowwater**, which adds pressure while players are still learning, **and the Clinker**, which needs soft-lock testing.

OWNER: the Gutterkite and the Fogstilt go in v1; the Slowwater and the Clinker wait. Swap any.

### The Soul of the Wick
All four come from the Soul, like Wicklings, though no text says so outright. Only small creatures have the Wicklings' eye-dots, so "no face" reads as a rule. The finale stays a light confrontation with some pressure. When the great lamp catches, every creature unravels.

OWNER: add one or two Fogstilts to the second half of the finale, or keep it to Wicklings.

OWNER: strike "Big pale eyes" from the Soul's ART_CHECKLIST entry, because it conflicts with "no face" in DECISIONS.

## 3. People: the valley comes back where it is held

When a region's WayLamp is kindled, people come back ("Someone has come back to the Reedmarsh."). Each stays at one spot in held ground with a small lamp, and never goes into the dark, follows the keeper, fights or needs rescuing.

OWNER: approve the rule: people come back to a region once its WayLamp is kindled.

### Amos Patch, trader (the Hollow)
- **Who:** a travelling trader with a handcart, who sold the keepers oil and glass.
- **Where, when, why:** by the hut once the Hollow is held. Lit roads mean customers.
- **Errand:** "Light the road" (three lanterns lit along the marsh passage, so the cart can pass).
- **Fragment:** H.'s last order: only glass, no oil.
- **Reward:** trading (3 fuel for 1 scrap, and 4 scrap for 1 glass once the Ridge is held) and the Wide Pack (carry 30 to 40).
- **Personality:** cheerful and practical. Scared of the dark, and pretending not to be.
- **Lines:**
  - "Lights on the road again. Lights mean people. People mean trade."
  - "H. ordered glass once. No oil. Just glass, all I had."

### Maud Fallow, old pump keeper (the Reedmarsh), who knew H.
- **Who:** an old keeper who ran the marsh pump with H. for years, then left as the lamps failed.
- **Where, when, why:** at the pumphouse once the Reedmarsh is held. Saw it lit from the hills and came back, ashamed of leaving.
- **Errand:** "Maud's lamp" (fetch it from the rack in the hut).
- **Fragment:** Maud and H. argued as the ledger counts fell; Maud left, H. stayed. Maud doesn't know why it came.
- **Reward:** the old lamp's glass, fitted to your hand lamp, gives 50% more charge (about 6 s of ward instead of 4). The rack note becomes "Two hooks are empty now."
- **Personality:** blunt and dry. Guilty, but kind underneath.
- **Lines:**
  - "You're the one who answered. H. always did find someone."
  - "We argued over that ledger. I left. H. stayed. That's all of it."
  - "Why did it come? I've had years to think. I still don't know."

### Kit Brand, glazier's apprentice (the Windward Ridge)
- **Who:** the old glazier's apprentice.
- **Where, when, why:** at the workshop once the Ridge is held, back to see if the kilns survived.
- **Errand:** "Fire the kiln" (bring 8 fuel and 3 glass).
- **Fragment:** every lamp was lit from the great lamp; the great lens split the night the lake went still.
- **Reward:** polished mirrors. Beams reach 13 tiles instead of 11.
- **Personality:** quick, proud of the craft, talks shop.
- **Lines:**
  - "You finished the hood? Not bad. The seam's a bit wide."
  - "Every lamp here was lit from the great lamp. One flame, passed along."
  - "The big lens split the night the lake went still. I heard it from this bench."

### Ebba Tarn, rower (the Lake)
- **Who:** rowed the keepers to the island. The boat on the shore is Ebba's.
- **Where, when, why:** at the signal station above the old steps once the Ridge is held (Ebba won't go down into the fog); by the boat after the finale.
- **Errand:** "Show me the boat" (land a mirror beam on it). After the finale, "Row out" (bail it).
- **Fragment:** on the night it went dark, the lake went still. Ebba tied up the boat and walked away.
- **Reward:** 10 fuel and a tip about Fogstilts. After the finale, a boat crossing to the island and the far shore (a map feature).
- **Personality:** quiet, careful, a little superstitious.
- **Lines:**
  - "The night it went dark, the lake didn't freeze. It went still. Even the reeds stopped."
  - "There are tall ones out on the water. One light moves them. Two send them off."
  - "That light past the far shore? I don't know who keeps it. Nobody lived out there."

### Ivo Withey, mapmaker (the marsh road)
- **Who:** drew the keepers' lamp maps.
- **Where, when, why:** at the carved stone on the marsh road once two regions are held, to draw the valley again.
- **Errand:** "Walk the edges" (read three new survey stones, one each in the Hollow, the Reedmarsh and the Ridge; 24 landmarks in all, inside the 15-25 target).
- **Fragment:** no old map shows a lamp past the lake. H. borrowed Ivo's best map and never returned it.
- **Reward:** the map shows resource spots and unread notes in held regions.
- **Personality:** fussy, precise and warm. Measures in paces.
- **Lines:**
  - "H. borrowed my best map. Never brought it back. I hope it helped."
  - "No lamps past the lake on any map. There was nothing out there to keep."

OWNER: keep, cut or swap any of the five people. If one has to go, cut Ivo first.

## 4. Dialogue system

| Option | Effort | Tone | Controller |
|---|---|---|---|
| (a) Talk panel, 2-4 lines a visit | S-M (reuses the note panel, which pauses the world) | matches the notes; keeper silent | one button ("[A] Talk") |
| (b) Two-answer choices at set moments | M (choice UI, more states) | gives the keeper a voice | two buttons |
| (c) Full dialogue trees | L (a dialogue tool, many lines) | invites explaining the mystery | menus every time |

**Recommendation: (a).** Lines follow progress: first meeting, errand open, errand done, later visits and after the finale. Amos trades through a Trade menu styled like the lantern cards.

OWNER: use (a), the talk panel, for v1. Revisit (b) only if playtests ask for it.

**Journal.**
- **People:** one card per person met, with name, place, one line in the keeper's voice and every fragment heard. Unmet people stay hidden.
- **Errands:** open and finished errands, apart from Goals. The goal banner and pointer stay for main goals.
- The tabs become Goals, Errands, People, Story so far and Notes.

OWNER: give Errands and People their own pages, or fold Errands into Goals.

**What must be saved** (a new "people" section):
- for each person: arrived, met, lines seen, errand state and partial deliveries;
- upgrades: carry limit (not saved today), hand-lamp charge and mirror reach;
- world changes: Maud's lamp off the rack, the boat bailed, survey stones read;
- not saved: creatures, which respawn like Wicklings.

Read it with defaults, so version-2 saves still load.

## 5. Errands (all optional)

1. **Light the road** (Amos): lanterns along the marsh passage. Reward: trading and the Wide Pack.
2. **Maud's lamp** (Maud): fetch it from the hut rack. Reward: 50% more hand-lamp charge.
3. **Fire the kiln** (Kit): 8 fuel and 3 glass. Reward: mirror beams reach 13 tiles.
4. **Show me the boat** (Ebba): beam onto the boat. Reward: 10 fuel and a Fogstilt tip.
5. **Row out** (Ebba, after the finale): bail the boat. Reward: a crossing to the island and the far shore.
6. **Walk the edges** (Ivo): read three survey stones. Reward: resources and unread notes on the map.

OWNER: the rewards and trade rates are placeholders. Flag any that feel too strong (polished mirrors is the biggest).

## 6. Phasing and effort

Start after the WayLamp playtest, because people need "held" to work.

1. **N1, before the Lake (recommended):** the talk panel, journal pages, save section and arrival line; Amos, Maud and Kit; the Gutterkite. Effort L, about the size of M5a.
2. **N2, with the Lake:** the Fogstilt, Ebba's first errand and the finale option. Effort M.
3. **N3, after the finale (M6 or later):** Ebba's crossing, Ivo, then the Slowwater and the Clinker if wanted. Effort M.

As with the story milestone, the Lake is best built with its person and creature in place.

OWNER: do N1 before the Lake (recommended), or finish the Lake first and add people after.

**New art.**
- People: five 16x16 sprites, each with a 2-frame idle and a 2-frame talk. The keeper's frames are 32x32 (recoloured Puny Characters), so 16x16 people may look small; more Puny Characters can stand in. No portraits in v1 (the panel shows the name and the sprite at 4x).
- Props: Amos's cart (32x16) and three survey stones (16x16). The boat is already on the art list.
- Creatures: as in section 2.

OWNER: draw people at 16x16 (as in the brief) or at the keeper's 32x32 scale; no portraits in v1.

**New sounds.** No voices. One soft sound per person when the panel opens (cart bell, pump creak, glass chime, oar knock, paper rustle) and a chime when people come back. Creatures: kite flutter, slow wading, bubbles, a low grind. No stingers.

## 7. Open questions for the owner

OWNER: can a held region be lost again? If so, people shelter indoors until its WayLamp is relit.

OWNER: is the great lamp the Lake's WayLamp? Then the Lake is held only after the finale, when Ebba goes down to the shore.

OWNER: should people's rewards replace the carry-limit and hand-lamp upgrades planned for ruins (not placed yet), or add to them?

OWNER: may people say the keeper's typed name once, at the first meeting?

OWNER: all names are drafts. Choose pronouns for the five people, or keep avoiding them, as for H.

OWNER: how close may people come to existing hints? Draft: Kit echoes the plate and the lens ("every flame"); nobody says how many kept the great lamp.

OWNER: after the finale, do region creatures stop for good, leaving a few Wicklings in unheld dark ("thinner, not gone")?

OWNER: with the pointer off after the Hollow, may people give one soft hint toward the current goal?
