# Playtests

## Readability: what to try (owner, pad)

**Build:** branch `proto/kl-readability` (the readability step, before M1b). Open its worktree in Godot and press F5. Your M1a save loads as before. Every foe's wind-up now has a marker drawn over the fog in the pale cold blue, and your keeper shows its own dash, casts, drinks and hits. Nothing else changed: lamps still burn, and the WayLamp still takes fuel. No new sounds; old ones, pitched down, mark each wind-up. What was built, with every timing, is DESIGN §8.4.

**Play on a gamepad.** All the timings are in the tuning panel (L3), under "Tell", "Spitwick", "Clinker", "Ashbrood", "Nest" and "Wickling reach", if one feels too short or too long.

**What to try**
1. **Watch each foe's wind-up** before you fight it:
   - a **Wickling**: its eyes flare when it notices you; when it reaches you, two thin tendrils stretch out for a moment before it starts to drain, and the keeper gets a frosty edge while it drains;
   - a **Spitwick**: its throat swells and a pale band shows the spit's path at its full width; the band follows you, then locks (goes solid) just before it spits;
   - the **Clinker**: it uncurls when it wakes; before a roll a full-width lane shows where it will go, filling from the Clinker; after a roll it is dizzy (pale stars) for a moment;
   - a **nest**: its ring fills, its pods swell and three small glows show where the hatchlings will rise; they fade in.
2. **Dodge each attack with the dash (LT):** a spit, a roll, the Ashbrood's ash puff, the dive's landing circle. Each should miss you if you dash through it as it lands. Dash out of a Wickling's drain too.
3. **The Ashbrood fight:** the puff's circle is full size from the start and fills in; glows show where its adds will rise; between the phases it rises out of the bowl for a moment (you can't hurt it then); in phase 2 each dive shows a circle where it will land, a dotted path, and the lamp flickers. Plant a lamp off-screen and stand away from it: an arrow at the screen edge should point at the dive. The dive is a short flight now, not a jump.
4. **"Reduce flashes" (pause, Options):** turn it on and fight a Spitwick and the Clinker again. Every warning should still show. At the end of each wind-up it turns solid instead of flashing.
5. **Your own keeper:** a dash leaves a warm smear and afterimages; Lampfire and Lance show the keeper thrusting the lamp, the Fireglobe a raised arm; a flask sends warm motes up the coat; a hit flashes the keeper cold.
6. **Feel:** is anything still unfair? Does any warning feel too long, so the fights drag?

**Questions**

| Question | Your answer |
|---|---|
| Can you see every attack coming? Which one still surprises you? | |
| Too long, too short or right: Spitwick 0.7 s, Clinker 0.9 s, ash puff 1.0 s, dive 1.0 s, Wickling reach 0.25 s | |
| Do the markers read as "get out" next to your own warm Fireglobe ring? | |
| Is the dash's look (smear and afterimages) right? The cast, drink and hit cues? | |
| With "reduce flashes" on, is every warning still clear? | |

**Your answers to steps 1-6** (pass, or what went wrong)

| Step | Result |
|---|---|
| 1. Each foe's wind-up | |
| 2. Dash through each attack | |
| 3. The Ashbrood fight | |
| 4. Reduce flashes keeps the warnings | |
| 5. The keeper's own cues | |
| 6. Anything unfair or slow | |

## M1a: what to try (owner, pad)

**Build:** branch `proto/kl-m1a` (fire in the Hollow; build commits 6663292 and 10099a8). Open its worktree in Godot and press F5. It uses the prototype save files, so a `main` save is never touched. A version 4 prototype save loads with the default bar and full flasks, but **start a new game** for step 1. Sound is on as usual; nothing new was added, old sounds stand in.

**Play on a gamepad only.** Leave the keyboard alone, and don't open the tuning panel (L3) except to tune. You need one lit WayLamp: the Hollow's. Lamps still burn fuel in M1a, and the WayLamp still takes 15 fuel and wakes the Ashbrood.

**Controls (pad)**
- Left stick: move. Right stick: aim.
- **RT** (hold): Lampfire. **RB**: Fireglobe. **LB**: the Beam at level 1, then Lance from level 2. **Y**: empty (Hearth ring goes here if you pick it). **LT**: dash.
- **B**: drink lamp oil (and close menus). **A**: read, refuel, rest, travel; hold A to gather or pick up a lamp. **X**: plant a lamp (next to a mirror: turn it left).
- D-pad up: map. D-pad down: Skills. D-pad left / right: lamp kind (hold right: the lamp list). View: journal. Start: pause (Options are in there).

Keyboard and mouse, for reference: left click Lampfire (hold), right click Fireglobe, Q Beam / Lance, F slot 4, Space or Shift dash, R flask, E interact (hold to gather or pick up), C plant, Tab lamp kind, M map, K Skills, J journal, Esc pause.

**What to try**
1. Start a new game and play to the Hollow WayLamp without touching the keyboard. Light it (15 fuel, then the Ashbrood). Your name should stay "Keeper" (there's no pad letter grid until M9).
2. Move and aim while you hold RT, then RB, LB and LT. Your right thumb should never have to leave the stick.
3. Hold RT and press B. You should drink, and the fireballs should keep their aim.
4. Close the journal, the map, a note and the pause menu with B. No flask should be spent.
5. Move through every menu with the D-pad. The map should not open and the keeper should not move.
6. Watch the cooldown sweeps on the action bar. Try a skill while you're short of charge: its slot should be greyed.
7. Clear the first packs with Lampfire, Fireglobe and Lance only.
8. Decide on each fire skill: keep, rework or cut (below).
9. Try the Beam on LB at level 1, and again after level 2: Lance takes LB then, and the Skills list (D-pad down) puts the Beam back in one press. Put Hearth ring on Y and try it too. Mark keep or cut for each (below).
10. While something hunts you, stand in a lamp's light. Charge should come back only slowly, and warmth not at all (the top-right chip says so).
11. Check that packs drop oil (an amber flask), that the Ashbrood drops oil at half health in each of its two phases, and that **Rest** at the lit WayLamp (A, then Rest) refills your flasks and warmth.

**If you have time:** turn on the auto-fire option (pause, Options) and see if it helps with RT and RB on one finger. Try the screen-shake slider and "Reduce flashes". The Clinker now has 48 hp and the Ashbrood 220 a phase: say if either fight drags.

**The two key questions**

*Are the fire skills fun? (keep / rework / cut each)*

| Skill | Keep / rework / cut | Why, or what to change |
|---|---|---|
| Lampfire | | |
| Fireglobe | | |
| Lance | | |

*Keep the Beam? Hearth ring?*

| Skill | Keep / cut | Why |
|---|---|---|
| The Beam | | |
| Hearth ring | | |

**Your answers to steps 1-11** (pass, or what went wrong)

| Step | Result |
|---|---|
| 1. New game to the lit WayLamp, pad only; name stays Keeper | |
| 2. RT, RB, LB, LT while moving and aiming | |
| 3. RT held + B: drinks, aim kept | |
| 4. B closes menus without spending a flask | |
| 5. D-pad in menus: no map, no movement | |
| 6. Cooldown sweeps; greyed when short of charge | |
| 7. First packs with Lampfire, Fireglobe, Lance | |
| 10. Light while hunted: slow charge, no warmth | |
| 11. Oil from packs and the Ashbrood; Rest refills | |

Anything else (feel, numbers, the action bar, texts):

**Texts to mark up:** every M1a text is DRAFT in STORY.md §14 (skills, the Skills list, Rest, flasks, options, toasts), plus the two changed boss-bar hints (§12) and "Rest or travel" (§11).

The checks come from the game plan (§18, M1a) and ROADMAP.md; the steps from `docs/replan/M1A_BUILD_NOTES.md`.

---

## PROTOTYPE build (branch `proto/kl-hollow`): Keeper's Light in the Hollow

Open the `proto/kl-hollow` worktree in Godot and press F5. This build uses a separate prototype save, so your regular save remains untouched. Automated checks use the Dummy audio driver; normal play keeps audio enabled.

Since the loop (branch `proto/kl-loop`), the passage east is open; the old climb north is closed by fallen stones until you come back down it from the Ridge. Start by relighting the hut lantern. Find the red pulse north of the hut, fight the Clinker for the Post Lamp, and burn out the nests with a built lantern's bright core. The blue glints mark two guarded upgrades. Feed the Hollow WayLamp 15 fuel to wake the Ashbrood; break its shell with the beam, then learn its second phase. The level-up screen pauses play and offers three of twelve upgrades.

> **Correction (2026-11-27, AUDIT M16, M17):** parts of this paragraph are older than the first-10-minutes pass. Since then one shelled Wickling guards the crook, and the Clinker is a mid-boss near the WayLamp, not on the post. For "two guarded upgrades": no lure or guard for the upgrade finds was found in the code (**uncertain**; searched, not run). The paragraph is kept as written.

**Controls:** beam: hold left click / RT; burst: F / RB; dash: Shift / LT. Move: WASD / left stick. Interact/read/refuel: E / A. Build: Space / X. F1 opens the tuning panel; Esc / Start pauses.

**Bigger regions (2026-11-27, branch `proto/kl-big`):** every region is now 4x the area (224 × 200 tiles). The Hollow holds 24 packs and 12 nests instead of 6 and 3, plus three old caches at dead ends. A save from the smaller map starts fresh. Extra questions: does the Hollow now feel big enough, or too big to walk? Is it too full of packs and nests, or too empty anywhere? Does it still run smoothly with many lanterns out?

**Leveling balance (2026-11-27, branch `proto/kl-balance`):** levels now come on a rising curve (6 wick to level 2, then 14, 24, 34, 45, 56, 68...). Expect level 2 after the first pack or two, level 3 or 4 by the Clinker, about level 7 at the Ashbrood and level 8 when it falls (since the level-gap pass). The HUD shows "Lv 3" and the wick toward the next level ("12/24"); a level-up plays a chime, flashes the card screen, and the wick row glows after you choose. Four more upgrades (Hot core, Steady hand, Lee, Spill) make twelve, so every offer has three cards. (Superseded by the level-gap pass below: hatched and re-fought foes pay again, scaled by level.) Extra questions: did levels come at a good pace, early and late? Did any stretch feel like a long wait for the next one? Is the Ashbrood still a real fight at level 7?

**Wick by level gap (2026-11-27, branch `proto/kl-xpgap`):** every foe now has a level, shown on its name bar ("Wickling Lv 2"): Lv 1 around the hut and in the south, rising to 6 by the WayLamp; the Clinker is Lv 4, the Ashbrood Lv 7. Foes well below you pay little and then nothing: the name dims and the "+wick" popup turns grey. Hatchlings and packs that come back after a faint pay again, scaled the same way. The Hollow's last level (8) now comes the moment the Ashbrood falls; lighting the WayLamp gives only a little. Extra questions: did you notice the levels and the grey popups? Did farming near the hut stop paying at about the right point? Did going north feel like the faster way up?

**The first 10 minutes (2026-11-27, branch `proto/kl-onboard`):** start a **new game** (the map changed; an old prototype save keeps old clears). The road north is now short and stepped: one lone Wickling about 10 tiles out, a second cold old lamp at 12 to relight, a pack of 3, then Oswin's crook at about 19 tiles with one shelled Wickling sleeping on it and 6 scrap beside it. The Post Lamp's first job is the nest 11 tiles past the crook. Then one pack with a Spitwick and an elite, the Clinker (now a mid-boss near the WayLamp), and the WayLamp. The rest of the Hollow, the south included, is optional. What to try: play from the letter to the WayLamp without the F1 panel, then once more wandering south and sideways first. Extra questions: did you always know where to go next? Did anything wake while you were at the hut? Was the lone Wickling a good first fight, and did the tips show at the right moment? Did the crook still feel earned with a small guard? Did burning the first nest with your own lamp click? Is the second old lamp a good safe spot, or too cheesy (owner: cut it if so)? Best of all, hand it to someone new and watch their first 10 minutes without helping.

**The loop and WayLamp fast travel (2026-11-27, branch `proto/kl-loop`):** start a **new game** (the map changed). The Hollow's road north is the same up to the first nest; then it turns east to pack 2, the Clinker and the WayLamp, which now stands north-east of the hut, a few steps above the carved stone. Kindle it and go straight on east into the Reedmarsh, and through it to the pumphouse and its WayLamp as before. Then climb north out of the marsh: the path starts at its north-west corner by a cairn (it is open as soon as you reach the marsh; the cairn asks you to light the marsh first). It comes up at the Ridge's east end, beside the glazier's workshop and the lens. From there the Ridge runs one way: the coat, the signal station, its WayLamp, the old steps (the Lakeshore below them is still empty). The far west of the Ridge is optional. The marsh and the Ridge have no Keeper's Light foes yet; their WayLamps still bring the old swarm. **Fast travel:** at any lit WayLamp, press E / A: a list of every lit WayLamp opens. Pick one and you are there after a short fade. B / Q / Esc / Start closes it. It won't open while something hunts you, while a WayLamp kindles or during the Ashbrood fight; the WayLamp says why. What to try: play the whole loop once from a new game without F1 and without looking at the map, then use fast travel back and forth: the Hollow to the marsh and back, on the pad and with the mouse. Try to open it with a pack chasing you. Walk down the old climb from the Ridge and see the stones give way. Extra questions: did you ever have to walk back the way you came? Was it clear to leave east right after the Hollow's WayLamp, and to climb out of the marsh? Did the Ridge feel like one walk, entry to steps? Should the marsh climb stay open, or open only once the marsh is lit? Did fast travel feel quick and safe? Is "pushing the stones down" a good shortcut, or should the old climb just stay open? Texts to mark up: the ledger, cairn and pumphouse lines, two goal lines and the travel texts (STORY.md, DRAFT).

**Prototype limits:** creatures and effects are code-drawn placeholders. Leads, journal changes, the third boss phase, foes beyond the Hollow, and full animation/audio polish are not included. Values are prototypes and can be adjusted in F1.

Questions (decision gate):
1. Did aiming and firing the beam feel good on mouse and pad? What felt off: reach, speed, sound or hit feedback?
2. Did you dash on purpose to dodge? When hit, did it feel fair?
3. Did you work out how shells and nests are damaged? Did the Clinker take too long?
4. Did finding the Post Lamp change how you fought? Did it feel earned?
5. Did the level-up choices feel distinct and useful?
6. Was the Ashbrood tense but fair? Did you understand each phase?
7. Did the lures pull you along? Did the Hollow still feel empty anywhere?
8. Did you still build lamps, and why?

### Results: 2026-11-27 (later), owner: fuel and abilities

The playtest that led to the re-plan. The owner's notes came as messages and were logged in DECISIONS (commits `42bcdee` and `c7b457f`; the first wording is quoted from `42bcdee`). **Uncertain:** which build was played. The notes were logged after the first-10-minutes merge (`f126af7`) and before the loop was merged, so most likely `proto/kl-hollow` at about `f126af7`.

1. **Fuel and tending.** Owner: "fuel is ABUNDANT, its everywhere, its pretty much useless... i dont want that to be a chore i didnt want that anyway but even less so because its an ARPG now". → Lamp tending is not wanted. Owner: "fuel as flasks". → Fuel becomes lamp-oil flasks (M1a), and tending goes (M1b).
2. **The abilities.** Owner: "the beam and the ward idk i feel like we need to shoot flaming light fireballs or some shit instead". → Light-fire projectile and area skills replace the beam-and-ward kit as the core (M1a). ("The ward" most likely means the burst, which replaced the ward in play; GAME_PLAN, uncertainty 7. The approved kit settles it either way.)
3. **The beam.** Owner: "keep as optional for now and we will see if i want to get rid of it when i play it". → The Beam is optional, in LB at level 1 (M1a, check 9).
4. **An action bar.** Owner: "i guess we need an action bar". → The action bar (M1a).
5. **Leveling.** Level 8 on the Ashbrood kill, as tuned. (The plan later moved the Hollow's end to level 6, in M1b.)
6. **The docs.** Owner: "I think we need to re-plan this entire game and rethink all of the docs". → The audit, the reference brief, the game plan, an independent review, and plan v2, approved on 2026-11-27 (DECISIONS, "the game plan approved").

**Not answered:** the extra question sets above (bigger regions, leveling, the level gap, the first 10 minutes, the loop). M1a and M1b change most of what they ask about. A word on any of them is still welcome.

### Results: 2026-11-27, owner (gamepad only so far)
1. Aiming and firing the beam feels good. **Hit feedback felt off** → added a hit flash, screen shake on the burst, kills and big hits (a short freeze on a kill was already in).
2. Dashed on purpose to dodge; hits felt fair.
3. Didn't know what the Clinker or the Ashbrood were → **names and health bars over foes, a pale shell bar above the red one, and a boss bar for the Ashbrood**.
4. The Post Lamp felt earned and changed how he fought.
5. Choices mostly distinct; **"Quick fill" was useless** (the lamp already refills fast) → replaced by **"Kindled kills"** (each kill gives back 10% charge).
6. Couldn't tell the Ashbrood's phases apart or whether it was taking damage → the boss bar shows phase, health, shell and a one-line hint for each phase.
7. The lures pulled him along.
8. Built lamps because monsters are afraid of them, which may be too strong → now about half the Wicklings are timid and stay out; the brave ones walk in, burn after 2.5 s and run. Elites, the Clinker and the Ashbrood ignore lanterns completely.

---

Older playtests (M1, M2, M3, the Wicklings and the WayLamps) are in `docs/archive/PLAYTEST_PRE_ARPG.md`, unchanged.
