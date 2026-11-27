# Decisions log

Owner decisions that override or settle the design docs. Newest first.

## 2026-11-27 (loot and agent skills)
- **Loot is Diablo-style:** random drops with rarity and rolled stats you compare and swap (lens, burner, coat, wick slots). Rolling is our own code. NPC talk uses Dialogue Manager; inventory data uses GLoot (both MIT; vetted).
- **Leveling needs a balance pass** (owner), after the bigger map lands (it changes how much wick there is).
- **An ARPG skill for our agents:** `.agents/skills/lantern-keeper-arpg/` holds the pillars, how foes, numbers, leveling, loot and UI are built, and how to run a balance pass.
## 2026-11-27 (performance budget; bigger regions)
- **Every region 4x bigger** (owner: "we need to expand the regions by a lot, make them all 4x bigger"). Read as 4x the area: twice as wide and twice as tall. The map goes from 112 × 100 to 224 × 200 tiles; the Hollow, Reedmarsh, Ridge and the space kept for the Lakeshore and Still Lake all scale, and every hand-placed thing keeps its relative place. Resource spots, packs and nests are 4x per region so the space isn't emptier; a few side caches were added, no new enemy types. The calm start (16 tiles), the Clinker by the WayLamp, packs tougher toward the WayLamp, cleared stays cleared and the regrowing woodpile all still hold. Saves from before (version 3) start fresh and show "(old save)".
- **Performance budget:** game logic (process + physics) averages well under 4 ms a frame with 30 lanterns and 20 foes, measured by `tools/bench/bench.tscn`. Before the pass it took about 17 ms. The benchmark is not a test.

## 2026-11-27 (Hollow prototype playtest)
- **Genre: action RPG.** Lantern Keeper is labelled an ARPG from here on.
- **No endless trickle of enemies.** Enemies wait in fixed packs, nests and the WayLamp fights; you meet them as you push into new ground and clear it, and cleared ground stays cleared. (`kl_ambient_spawns` is off.) Shelled elites now sit in the northern packs.
- Lanterns: about half the Wicklings are timid; brave ones burn after a while in light; elites and guardians ignore lanterns. Names, health bars and a boss bar; hit flash and screen shake.

## 2026-11-27 (combat kit playtest)
- The combat kit mostly feels good; the owner dashed on purpose to dodge. Still too easy, but more fun. Sound effects and music are the owner's job.
- **Start of the game:** only the pointer (on the woodpile) until you have fuel; then the cold lamp gets its ring.
- **The Hollow's notes follow the new route** (DRAFT text): the ledger sends you north to the WayLamp first, then east; the cairn says to come back once the marsh is lit.
- **No more "too dark" to build**: a lantern can go anywhere you can stand. Bringing light into the dark is the point (owner).
- **Three save slots**, picked on a screen at start; the old single save becomes slot 1 (a later one goes to the next empty slot). The pause menu has "Save slots".

## 2026-11-27 (Keeper's Light: owner answers)
- **The Post Lamp becomes the Hollow's find**: you start with no lanterns to build and earn it from an elite north of the hut.
- **The finale becomes a real fight.** Owner's pitch: the Soul of the Wick is not killed; it retreats into a dark realm, a portal opens, and the keeper follows it. That is the hook for expanding the game after v1.
- **The keeper takes and wears Oswin's coat** on the Ridge.
- **Moves approved:** the Reedmarsh's WayLamp to the south-east island; the Mirror Post's unlock to the Lakeshore.
- **Lamp charge stays as built** for now: lantern light refills it, carried fuel tops it up between fights.
- **The tuning panel (F1)** shows the combat kit's numbers too (beam, burst, dash, elites, warmth); the old ward rows are gone.

## 2026-11-27 (new direction and font)
- **The game becomes an action RPG: direction B, "Keeper's Light".** The hand lamp becomes a weapon (aimed beam, burst, dash), with enemy families and elites, a guardian fight at each WayLamp, levels with pick-1-of-3 upgrades, and gear. **Each region's find is the key to conquering that region and lighting its WayLamp** (owner's rule). Direction C's tides (ebb and flood) are kept for later, if fights need build-up. The owner: the cozy idea "will just end up being too boring". Research: `CORE_LOOP_RESEARCH` (drafts). Next: a design draft for owner markup, and a prototype in the Hollow with a playtest gate. People, creatures and the Lakeshore wait, to be refitted to it.
- **WayLamps are merged into main** (the WayLamp playtest passed with changes); the new direction builds on them.
- **Font: Ark Pixel** (OFL 1.1), at sizes on its 10 px grid. Kenney Pixel smeared at in-between sizes and drew O and 0 the same.

## 2026-11-27 (WayLamps playtest feedback)
- **WayLamps take fuel directly**: no lantern or beam has to reach them ("it should just take fuel and be lit").
- **The Hollow's WayLamp moves to the north end**, below the climb (it was too close to the hut). Goal order: build a Post Lamp, kindle it, then the carved stone.
- **Less to read at the start:** the note on the hut door is cut (the letter is the opening) and the rack is scenery.
- **Quiet building:** no outline or cost text until you try; a failed build says why for 2 s. No building on resources.
- **Lantern beside a resource:** a tap refuels the lantern; holding gathers the resource.
- **Combat stopgap:** the ward costs 0.45 charge per second (was 0.25) and the lamp doesn't refill while warding, so it's never free. A proper answer comes from the core-loop rethink.
- **The game feels boring; rethink the core loop** (owner). Research and 2-3 directions are being prepared, leveling and a real combat system included. People and creatures (M5c-M5e) wait for it.

## 2026-11-27 (owner answers, afternoon)
- **Oswin signs "- Oswin"** (it was "- H.", then briefly "- O."; in the game font a capital O looks like a zero), and the journal calls him Oswin. His surname stays out of the game.
- **The Lakeshore:** thick fog (lanterns only thin it; beams and WayLamps cut it); its WayLamp on the old landing, reached only by a beam (to try in the M5d playtest); a few spots of worn glass on the shore; Ebba is "she"; her boat crosses to the Lake only after the finale.

## 2026-11-27 (owner answers, later)
- **Oswin signs "- O."** The sign-off changed from "- H." (for Hester) in every built text: the letter, his notes, journal entries and the initial stitched in his coat.
- **People are drawn at the keeper's 32x32 scale**, without portraits.
- **A new region, the Lakeshore**, goes between the Ridge and the Still Lake (down the old steps), because the Ridge was getting crowded. The Fogstilt and Ebba move there; the Ridge keeps the Gutterkite; the Clinker roams whatever isn't held. A design draft is being written for owner markup.

## 2026-11-27 (owner answers)
- **People and creatures are IN for v1:** people with short spoken lines and errands, and the four creatures from `docs/PLAN_NPCS_ENEMIES.md`. **All of them come before the Still Lake.** The plan is being revised to match (two milestones, after the WayLamp playtest).
- **WayLamp story text approved** (STORY §11).
- **The last keeper is Oswin Reed, a man ("he").** He replaces Hester Vane. His full name doesn't appear in the game yet. Open: whether he now signs "- O." instead of "- H.".
- **The sign-off uses a plain hyphen**, "- H.", as built.
- **First Wickling after 25 s** (`wick_first_delay`; was 60 s).
- **Fainting keeps glass safe** (it drops half your fuel and scrap only), as built.
- **Upgrades built:** a keeper's satchel (carry +10 of each) and a lamp glass (hand lamp reaches further, dims slower, wards longer) in each region, found by exploring. Texts are DRAFT in STORY §6.
- **The Soul of the Wick has big pale eyes.** The "no face" rule is dropped, for the Soul and for the creatures.

## 2026-11-26 (lantern upkeep, docs, people and creatures)
- **WayLamps (prototype; the owner named them).** One old WayLamp per region. Reach it with your own light, feed it fuel, and hold it while it kindles. Once lit, it **holds its region**: lanterns there are refilled and stop burning down, and no Wicklings come. Why: lighting the built regions takes about 40-50 lanterns, which means a refuel about every 4 s, and letting lanterns go cold had no stakes. Built on branch `proto/waylamps`. Its playtest is the gate before the Still Lake. Design: DESIGN §8; draft text: STORY §11.
- **Light repels Wicklings (same prototype).** Healthy light pushes Wicklings back into the dark. They can only drain a **dying** lantern, one under a quarter of its tank that no healthy light covers.
- **People and more creatures are wanted** (owner). The proposal is `docs/PLAN_NPCS_ENEMIES.md`, waiting for owner markup. Until it is approved, people and spoken lines stay out of scope, and STORY's "no dialogue" rule stands.
- **Docs follow the code.** The code is the authority on what is in the game. Docs change in the same branch as the code they describe. `tools/check_docs.py` and the docs skill (`.agents/skills/lantern-keeper-docs/`) keep them in step. The README was rewritten with screenshots.
- **Fix:** hand refuelling now fills a Reservoir Lamp's whole tank (it used to stop at 100 of 200).

## 2026-11-26 (HUD playtest follow-ups)
- **Mirror beams burn Wicklings fast** (about 1 s), and Wicklings can't sense beams, so they walk into them.
- **Wicklings smother mirrors** (no mirror health): one clinging to a mirror turns it dark and cuts the chain after it; it drinks any beam that reaches it, so only your ward drives it off. A status chip counts smothered mirrors.
- **Wind pop-ups removed.** A chip appears only while wind actually reaches your lit, unsheltered fuel lanterns ("Gust: 3 lanterns exposed"); exposed lanterns show a small wind mark.
- **Mirrors turn both ways**: A/E right, X/Space left (building is blocked next to a mirror anyway).
- **Lantern list redesigned** as cards (sprite, name, cost with icons, description; locked ones dim). **Tap Y/Tab to switch lanterns without opening it; hold to open; keys 1-4 pick directly.** The HUD panel shows which lantern you'll build.
- **Journal** restyled to match the HUD.

## 2026-11-26 (HUD redesign, owner-approved mockup)
- Notes, the lantern list, the map, the journal and the pause menu all **pause the world** (owner: Wicklings hurt you while reading).
- New HUD: top-left panel (fuel/scrap/glass icons + counts, hand-lamp and warmth bars); top-centre goal banner; top-right status chips only when something needs you (wind, cold/low lanterns, getting cold, lamp an ember); prompts drawn over the thing you can use ("[A] Refuel 62%", "[A] Read", "[A] Turn", "Hold to gather"); build cost or reason under the placement outline; a key reminder that fades after a minute; full controls in the pause menu. Button letters follow the device in use (A vs E). One panel style (navy, wood/amber trim) for menus, notes and tips.

## 2026-11-26 (story markup)
- Keep the premise: the new keeper answers a letter from the last keeper, **Hester Vane ("H.")**. Pronouns for H. not chosen; texts avoid them. *(Changed 2026-11-27: Oswin Reed, "he".)*
- The player **types a name** at a new game; it signs the journal.
- The Soul of the Wick is **"it"**: no name, no face. *(Changed 2026-11-27: it has big pale eyes.)*
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
