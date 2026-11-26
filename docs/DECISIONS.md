# Decisions log

Owner decisions that override or settle the design docs. Newest first.

## 2026-11-26 (story markup)
- Keep the premise: the new keeper answers a letter from the last keeper, **Hester Vane ("H.")**. Pronouns for H. not chosen; texts avoid them.
- The player **types a name** at a new game; it signs the journal.
- The Soul of the Wick is **"it"**: no name, no face.
- The goal pointer turns **off on reaching the Reedmarsh**.
- The player **builds every mirror** (H.'s camp holds a crate of glass instead of a free mirror).
- **Keep** the great lamp plate ("IT WAS NEVER MEANT TO BE KEPT BY ONE.").
- The finale has **some pressure**: the coil drains the lanterns feeding the mirrors; Wicklings rise from the water.
- Other draft choices stand as defaults (see STORY.md DEFAULT lines).

## 2026-11-26 (guidance and story before the Lake)
- Owner: before adding regions, the game needs story and direction (no goals, no journal). Agreed: a guidance-and-story milestone comes **before** the Still Lake, so new regions are built with it.
- Direction style **(b)**: a goal line + keeper's journal **plus a soft pointer** (amber arrow toward the current goal) that is **on in the first region and off by default after it** (can be turned back on in settings).
- Process: coordinator drafts `docs/STORY.md` (premise, characters, Soul of the Wick, beats per region, goal list, landmark texts, opening, tips); owner marks it up; the journal is then built around the owner's version.

## 2026-11-26 (Post Lamp look)
- The Post Lamp is a **shepherd's crook**: a wooden post whose arm curls over, with the lamp hanging from a chain (owner's pick of four sketches). The light now glows from the hanging lamp, and cold-lantern markers show the real cold sprite through the fog. Starter art by `tools/art/crook_lamp.py`, for the owner to refine in Pixelorama.

## 2026-11-26 (M5: the Windward Ridge)
- The map grows north (112x100 tiles): the Ridge sits above the Hollow, reached by a narrow climb from the top of the Hollow. Old saves (version 1) start fresh.
- **Constant west wind** on the Ridge: exposed fuel lanterns burn 1.6x and shrink to 85%, on top of gusts (which come every 12-22 s while you are there). Rock outcrops 1-2 tiles to the west shelter a lantern. Wind streaks never stop on the Ridge.
- **Glass**: third resource, only on the Ridge (14 spots).
- **Hooded Lamp** (glazier's workshop): 5 scrap + 2 glass, 180 px light, wind never touches it.
- **Mirror Post** (signal station): 4 scrap + 3 glass, no fuel. Catches light when it stands inside 90% of a burning lantern's light or in another lit mirror's beam (chains work). Throws an 11-tile beam (blocked by rock) in one of 8 directions; interact turns it. Beams clear fog and burn Wicklings. This is the tool for the Still Lake.
- Two story landmarks on the Ridge hint at the Soul of the Wick (a keeper's coat with a note; a broken lens: THE WICK REMEMBERS EVERY FLAME).

## 2026-11-26 (ward playtest)
- Owner: the ward on lamp charge works; push-and-pull is fun ("explore while killing Wicklings, collecting fuel and scrap").
- Embers looked like a flower on the ground. Now drawn on the fog layer so they glow through the dark: a flickering flame with a pulsing ring and sparks, a magnet pull when you are close, and a floating "+1 fuel".
- Burned Wicklings now have a 35% chance to also drop 1 scrap (cool blue heap with a glint).

## 2026-11-26 (beam playtest -> warding glow)
- Owner: the beam killed too slowly, ate all the fuel meant for lanterns, and missed Wicklings right on top of the keeper. Root cause: the weapon competed with building for the same fuel.
- **The beam is replaced by a warding glow** (owner's choice, no aiming): hold F / RB / RT and the hand lamp swells into a ~110 px circle that burns (about 0.7 s per Wickling) and pushes back every Wickling inside it, including point blank.
- **The ward runs on hand-lamp charge, never carried fuel.** A full lamp gives about 4 s of ward; an empty lamp drops to an ember and can't ward, so you retreat to lantern light to recharge. The lamp's auto top-up from carried fuel no longer fires right after warding.
- **Burned Wicklings drop an ember** worth 1 fuel (walk over it; fades after 30 s), so fights pay a little back instead of costing the lantern economy.

## 2026-11-26 (combat prototype playtest)
- **Wicklings are IN v1** (scope change; owner playtest: "more interesting", light still felt safe and calm, fainting felt fair). Combat, enemies and a health stat move from OUT to IN, in the light-based form: no death, no game over; warmth is the health; fainting wakes you at the nearest lit lantern and drops half your carried resources where you fell.
- **The flare is replaced by a lamp beam** (owner: the flare one-shot everything and "wasn't really a flare"; wanted a beam that drains their health). Hold F / RB / RT; aim with the right stick, the mouse, or the way you walk. 1 carried fuel per 1.5 s. A Wickling takes about 2 s in the beam. You walk at half speed while beaming.
- **More pressure** (owner: "not much added pressure"): first Wickling after 25 s (was 40), then every 12 s (was 16), up to 7 (was 5), a bit faster, drain 5 fuel/s (was 4).
- The mouse cursor hides while playing with keys or a controller.

## 2026-11-26 (finale)
- **The finale is a confrontation of light, not a fight.** The Soul of the Wick (owner's name) is the one who robbed the valley of its light. At the Still Lake he is coiled around the cold great lamp as living darkness. The player drives him off by surrounding him with light (a Mirror Post chain), and the lamp relights. He answers "who took the light"; "why" stays open for later (consistent with the partly-answered mystery). Landmark texts should start hinting at him. Built in M5.
- Settled later the same day: v1 gets light-based conflict (Wicklings), see above.

## 2026-11-26 (art style)
- **Art style: moody pixel art.** Small crisp pixel art on 16x16 tiles drawn at 2x (32 px on screen, matching the fog grid), limited palette of deep blues and warm ambers, nearest-neighbour filtering. Chosen because it is simple and the owner can draw his own in Pixelorama. Free CC0 packs may be used and recoloured to the palette; every pack goes in assets/CREDITS.md.

## 2026-11-26 (after M3 playtest)
- Cold lanterns stay findable, as DESIGN 3.1/4 intended ("keeps its frame"): their frame and a pulse are drawn above fog and darkness. Lanterns below 25% fuel get an amber pulse. Off-screen cold/low lanterns get an arrow at the screen edge. The HUD counts them and the map colours them (red cold, yellow low).

## 2026-11-26 (M3 build choices, coordinator)
- Wind gusts are valley-wide from M3 (not only the Windward Ridge), as the one weather effect. Shelter = rock 1-2 tiles upwind. The Ridge will get stronger, more frequent gusts later.
- The Reservoir Lamp also refuels cold lanterns in its light (relights them), not only lit ones.
- Ambience is synthesized live as a placeholder; real CC0/REAPER sounds arrive in M4.
- Five landmarks in M3: ledger, carved stone, eastward frames, chalk lake drawings, pumphouse.

## 2026-11-26 (answers to DESIGN §10)
1. **Sandbox after the finale: yes.** After the great lamp is relit the valley stays open; the player can keep building, tending and finishing the map.
2. **Hand lamp uses fuel: yes.** It burns fuel and dims as it runs low, but it never fully goes out: when empty it keeps a small ember glow (enough to walk home safely, too dim to reveal resources). This keeps the "no game over" rule.
3. **Mystery: answered in part, left open in part.** v1 resolves the immediate arc (why the great lamp went cold, and relighting it). The deeper "why" of the valley stays hinted, leaving room for future regions/updates. Every hint should still feel satisfying on its own.
4. **Gamepad support: in v1.** Moved from OUT to IN. All actions must work on keyboard/mouse and gamepad; UI must be navigable without a mouse.
5. **Project location:** `~/Projects/lantern-keeper`, its own git repo.

## Coordinator notes
- Wind moves from M5 to M3 so it is tested earlier.
- Renderer: Compatibility (OpenGL) for broad PC support; revisit only if a needed effect requires Forward+.
