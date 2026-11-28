# Lantern Keeper — Roadmap

> Rewritten 2026-11-27 from `docs/replan/GAME_PLAN.md` §18 (approved by the owner; DECISIONS 2026-11-27, "the game plan approved"). **DRAFT for owner approval** (GAME_PLAN §17). The version before the rewrite is `docs/archive/ROADMAP_PRE_REPLAN.md`.
> Scope follows the game plan and this roadmap. New ideas go to "Maybe later" in `DESIGN.md` §18, not into a milestone.
> No time estimates. A milestone is finished only when its owner checks pass.

---

## Status (2026-11-28)

| Milestone | State |
|---|---|
| History: M0-M5b, the prototypes and the loop | done; see "History" at the end |
| **M1a** Fire in the Hollow | **built, awaiting the owner's playtest.** On `proto/kl-m1a` (commits 6663292, 10099a8), not merged. DESIGN marks it BUILT (M1a); the playtest is in PLAYTEST.md |
| **Readability step** (telegraphs and the keeper's feedback) | **built, awaiting the owner's playtest.** On `proto/kl-readability` (based on the play branch with M1a merged), not merged. DESIGN marks it BUILT (readability); the playtest is in PLAYTEST.md. The owner's order: readability, then M1b, then M2 (DECISIONS 2026-11-27) |
| **M1b** No more tending | **built, awaiting the owner's playtest.** On `proto/kl-m1b` (based on b3f5cd9), not merged. Started before the readability playtest (owner: "start m1b please"). **Scope change during the build** (owner, DECISIONS 2026-11-27): the lamp limit, full refund and replant delay are on hold while lanterns are redesigned. DESIGN marks it BUILT (M1b); the playtest is in PLAYTEST.md. **Merge to `main` once M1b passes,** with the README rewrite. |
| **M1b** playtest | **done** (owner, 2026-11-28; results in PLAYTEST.md): tending gone felt fine, light by touch stays one press, the level pace is right, the faint rule worked; the ember didn't read (fixed in M1c) |
| **M1c** Lamps in the fight | **built and played** (merged into the play branch `proto/kl-hollow`, d80fc54). On `proto/kl-m1c` (based on a98d41a: the play branch with M1b, the sprites and the approved lanterns addendum), not merged. From `docs/replan/PLAN_LANTERNS.md` §8, plus the owner's M1b playtest fixes (the damage fix, the Ashbrood fighting back, the ember) and the lamp slots (owner 2026-11-28). DESIGN marks it BUILT (M1c), §20; the playtest is in PLAYTEST.md |
| **M1c** playtest | **done** (owner, 2026-11-28; results in PLAYTEST.md): the Ashbrood fights back now, but phase 2 was still a bit boring and needed more moves; the lock-on is great; standing at your own lamp was too strong; everything else looked good. A crash when a boss hit made the keeper faint was hotfixed (d13d5b6) and the owner checked it. The Clinker sprite was approved and merged into the play branch |
| **M2** Builds | **built, awaiting the owner's playtest.** On `proto/kl-m2` (based on d13d5b6, with the play branch merged in before the push), not merged. Skill points and 42 branch picks (tiers 1-3, all six skills), respec at rest, the pack screen (Skills, Journal, Map), elite affixes, the picks that touch lamps; with the owner's M1c fixes: the Ashbrood's phase 2 moves and phase 3, and the catch distance. DESIGN marks it BUILT (M2), §21; the playtest is in PLAYTEST.md |
| **M3** Loot | planned |
| **M4** People, part 1 | planned. Needs the owner's pronoun call for Amos (and the others before their milestones) |
| **M5** The Reedmarsh | planned |
| **M6** The Windward Ridge | planned |
| **M7** The Lakeshore | planned |
| **M8** The Still Lake and the finale | planned |
| **M9** Polish and the Linux build | planned |

**Rules for every milestone**
- Every milestone ends with an owner playtest **on a gamepad**. Its checks go in `docs/PLAYTEST.md`, and the results go there too.
- Don't start the next milestone, or add content to fix a loop that isn't fun, before the checks pass.
- One branch per milestone. Docs change in the same branch as the code (`.agents/skills/lantern-keeper-docs/SKILL.md`).
- **Scope traps:** no co-op and no extra platforms before v1; one projectile system and one status system; no second progression track; one region fully playable before the next.
- **Cut lines,** first to go if time runs short: the Tallest, Kit's re-cut, Ivo, Moth-lights' tier 3.
- Every third-party asset or add-on gets a row in `assets/CREDITS.md` in the same commit, with its license checked on the source page ("free" is not always CC0).

---

## M1a: Fire in the Hollow

**Status (2026-11-27): built, awaiting the owner's playtest** on a pad (`docs/PLAYTEST.md`, "M1a: what to try"). Branch `proto/kl-m1a`, build commits 6663292 and 10099a8. The build's own report is `docs/replan/M1A_BUILD_NOTES.md`; DESIGN.md marks each part BUILT (M1a), and the new texts are DRAFT in STORY.md §14. The gate is checks 1-11 below; checks 8 and 9 are the owner's calls.

**Scope**
- Lampfire, Fireglobe, Lance and the dash. The Beam (7.5 hp/s) and Hearth ring as optional picks in a plain Skills list.
- The action bar and HUD bars, on pad and keyboard/mouse. Aim assist and aim hold. The Y rule. The flask on B, read after the menu guard. The D-pad off movement.
- The regen table (DESIGN §5.1). Oil from packs, elites and the Ashbrood. Rest at a lit WayLamp (flasks and warmth).
- Clinker and Ashbrood health set by hand against today's curve (M1b re-checks them with scaling). Summoned foes drop nothing.
- The juice baseline, the shake slider and "reduce flashes". Save version 5.
- **Stays as built for now:** lamps still burn, the WayLamp still takes fuel, and the old cards stay until M2.

**Owner checks** (pad only, one WayLamp lit)
1. A new game reaches the lit Hollow WayLamp without a keyboard. Your name stays "Keeper" (no pad letter grid until M9).
2. RT, RB, LB and LT fire while you move and aim, and the right thumb never leaves the stick.
3. Holding RT and pressing B drinks, and the fireballs keep their aim.
4. Closing the journal, map, a note and the pause menu with B never spends a flask.
5. Moving through every menu with the D-pad never opens the map or moves the keeper.
6. Cooldowns sweep, and a skill short of charge greys out.
7. The first packs fall to Lampfire, Fireglobe and Lance alone.
8. **Are the fire skills fun?** The owner marks each one keep, rework or cut in PLAYTEST.md.
9. **Keep the Beam?** Try it in LB at level 1 and again after level 2, then record keep or cut. The same for Hearth ring.
10. Mid-fight, standing in a lamp's light refills charge only slowly.
11. Packs drop oil, the Ashbrood drops oil halfway through each phase, and resting at the lit WayLamp refills.

**Tests:** `test_combat` becomes `test_skills`. New `test_flasks` and `test_input` (B after each menu, the D-pad through each menu). The bench runs 40 projectiles. **Done:** all three exist and are in AGENTS.md. The build reported 658 checks passing across 15 scenes, 0 failures, and bench logic at 3.16 ms (M1A_BUILD_NOTES). After the review fixes (`proto/kl-m1a-fix`): the B checks run end to end through the keeper's own frame for all eight menus, and the bench runs a real fight (40 moving bolts that hit, 4 burning areas), which is **over the 4 ms budget** at about 4.7-5.6 ms (DESIGN §16). The old 3.16 ms was measured with bolts that stood still and a world the level-up cards had paused. Automated tests cover the testable parts of checks 1-7 and 10-11; the feel of checks 1-3 and 7, and checks 8-9, need the owner.

**Deviations from the plan** (DESIGN has the details)
- The Ashbrood has 220 hp per phase, not 150, because only two of its three phases are built (phase 3 is M2). Test arithmetic: about 114 s with a lamp nearby, 145 s without.
- The Beam and Hearth ring cards stay on the old card screen (M2 replaces it).
- The Spitwick's spit still has its own projectile script; only the keeper's fire is pooled.
- The keyboard has no "previous lamp kind" key; keys 1-4 still pick a lamp.
- The auto-fire option, damage numbers and D-pad lamp cycling were built in M1a (they were "not yet placed").
- The landmark unlock line now names the lantern list's button for the device in use (Tab or D-pad right; was "(Tab / Y)"). The new wording is DRAFT (STORY §14.9).

**Risks**
- Feel is most of the work. If the fire doesn't feel good, do one more feel pass before M1b.
- RT and RB on one finger; the auto-fire option is the fallback.
- Fog lights may cost more than the budget allows.

---

## The readability step (before M1b)

**Status (2026-11-27): built, awaiting the owner's playtest** on a pad (`docs/PLAYTEST.md`, "Readability: what to try"). Branch `proto/kl-readability`. The owner asked foes to "telegraph/animate some of their attacks better as with my abilities", and put this step first (DECISIONS 2026-11-27).

**Scope** (from `docs/ART_DIRECTION.md` §4, §5, §6.4, DRAFT)
- One shared telegraph system: every built foe attack (§4.3 rows 1-14) gets a cold marker over the fog, full size from its first frame, the marker as its hitbox, edge arrows for off-screen wind-ups, a wind-up sound slot (old sounds reused), and the fairness rules (§4.4). Every timing is a `kl_*` tuning value with an F1 row.
- The keeper's own feedback, code-drawn: dash smear and afterimages, a cast cue (Puny spare frames), a drink glow, a cold hit flash and a frost edge.
- The bold swarm's rim becomes cold `#a3bcd4`.
- The placeholder swap hook (§6.4) for the Wickling family, the Spitwick and the keeper's poses; no PNGs included.
- A performance pass: the bench's fight under the 4 ms budget again.
- **Not in scope:** M1b (tending removal, fuel, the faint rule) and M2.

**Owner checks** (PLAYTEST.md steps 1-6): each foe's wind-up reads; the dash avoids each attack; the Ashbrood fight (phase rise, dive circle, edge arrow); "reduce flashes" keeps every warning; the keeper's own cues; nothing unfair or slow.

**Tests:** new `test_telegraphs` (in AGENTS.md): the table and F1 rows, hit and miss 3 px either side of each marker's edge, the dash against each attack, edge arrows, the Spitwick's lock and its off-screen rule, the gap between warnings, hatch and add fade-ins, reduce flashes, the keeper's cues and the swap hook. The bench: 4.59-4.70 ms before, 2.55-2.61 ms after, 2.51-2.55 ms with the telegraphs busy (DESIGN §16).

---

## M1b: No more tending

**Scope**
- Lamps never burn, in every region's code paths. Fuel and glass cut. Scrap piles one-off. The woodpile becomes scenery.
- Old lamps and WayLamps lit by touch. ~~The lamp limit (3 outside held ground) and the 15 s replant delay.~~ **On hold** (owner, during M1b: lanterns are being redesigned; building and pick-up stay as they were; DECISIONS 2026-11-27).
- The faint rule (DESIGN §12.4).
- Hollow foe levels 1-4 (Ashbrood 5), foe scaling, and the curve at base 7 and exponent 1.65.
- The lures. The Hollow's goals and tips (new text as DRAFT in STORY). The lamp glass gives charge.
- Ridge wind goes inert until M6. The unused ward code goes.
- Added during M1b (owner-approved 2026-11-27): the Ashbrood broods over the WayLamp's last ember; its kill takes the ember back, which rises into the lamp as it lights.

**Status:** built on `proto/kl-m1b`, awaiting the owner's playtest. Everything above is built except the lamp limit and replant delay (on hold). Notes: scrap keeps its carry limit (30, +10 a satchel) until the satchel becomes bag slots in M3; the Clinker's base wick went 20 → 28 so a pure beeline goes into the Ashbrood at L4 (DESIGN §19.1); the Clinker's and the Ashbrood's health stay as set in M1a (the re-check with scaling is in DESIGN §4.6).

**Owner checks**
1. No prompt, tip or HUD item says fuel, refuel or gather, and lamps never dim.
2. The hut lamp, the north-path lamp and the WayLamp light by touch; the WayLamp wakes the Ashbrood.
3. ~~A 4th lamp outside held ground is refused, with the reason. A picked-up lamp can be planted again after 15 s.~~ On hold with the lamp limit.
4. After a faint, cleared packs stay cleared, a half-fought pack is whole and asleep, the Ashbrood restarts its phase, and nothing carried is lost.
5. A pack, a nest and an elite look different through the fog.
6. The last Hollow level comes on the Ashbrood kill.

**Tests:** rewrite `test_core`, `test_threats` (light reactions; the ward goes), `test_waylamps` (light by touch, hold fights) and `test_upgrades` (the lamp glass part). **`test_ridge`:** keep its layout, trail and placement checks; delete its tending, ward and wind-burn checks (wind checks return in M6). New `test_faint`. `test_leveling` checks level 2 at the crook and the Ashbrood kill on both routes (L5 beeline, L6 explorer). `test_save`: v5 → v6 from a test-only v5 file. (All done.)

**Risks:** hidden fuel dependencies (goals, prompts, HUD); old saves. (Saves: version 5 saves migrate to version 6 and keep progress, level, the bar and flasks; DESIGN §15.)

**Then:** merge to `main`, and rewrite the README (GAME_PLAN §17).

---

## M1c: Lamps in the fight

From `docs/replan/PLAN_LANTERNS.md` §8 (approved 2026-11-27, "1-6 yes to all"), with the owner's M1b playtest fixes.

**Scope**
1. Light states (dark x0.7 with a shell floor, dim x1.0, lit x1.3 with shells x1.5), their looks, the linger, the first-time tip. Nests exempt.
2. Combos: catch, flare (with the snap), chain. Feed too, because the Beam is still kept (its keep-or-cut is open).
3. The Ashbrood: hurt only when lit; the rim lamp; the ember flare; smothering during the sit; the puff snuffs lamps; the boss bar hint. Beyond the plan (owner: "it just sits there"): ash bolts and a wing sweep in phase 1, never more than 2 s idle; dives every 1.5 s after a sit. Health re-measured to 340 a phase.
4. Lamp slots by level (2 → 5), the HUD pips, the refusal reason, an 8 s replant, a full refund (owner 2026-11-28: build them now).
5. Target lock on pad and keyboard/mouse; the marker; the breaks; per-skill use; Y takes any skill; the options.
6. The damage fix: Wicklings chill in ticks with a swarm cap, the Clinker's roll is the hardest single hit and knocks back, foe damage +8% a level.
7. The ember: one ember at the Ashbrood's feet, no quest arrow during the fight.
8. DRAFT texts in STORY §16. Save version 7 (the rim lamp).

**Status:** built on `proto/kl-m1c`, awaiting the owner's playtest. Nothing in the scope was cut. **Not in M1c:** lamp types' new jobs (turret and the rest), loot lines, claim posts, tides.

**Owner checks** (pad, one WayLamp lit, plus a save from before the Ashbrood): PLAYTEST.md, "M1c: what to try".

**Tests:** new `test_light_states`, `test_combos`, `test_lock`, `test_fights` (the damage fix and the Ashbrood's activity); M1c checks in `test_core` (slots), `test_skills` (the time-to-kill sums with light), `test_waylamps`, `test_input`, `test_telegraphs` and `test_save` (v6 → v7). Older tests turn the light rule and the slot limit off where they check other things. The bench: 6 lamps and 40 bolts, and the default 30 lamps and 20 foes, both under the 4 ms budget.

**Risks** (the plan's): the dark may feel like a chore (Spitwicks fight from the dark); combos may trivialise packs; 8 s replant may allow lamp-dragging; R3 may click by accident; the dark/lit look on near-black Wickling art is subtle.

---

## M2: Builds

**Scope:** skill points and fixed branches, tiers 1-3, for Lampfire, Fireglobe, Lance and the dash (the Beam and Hearth ring only if kept). Respec at rest. The pack screen with Skills, Journal and Map tabs; the card screen goes. Elite affixes. The Ashbrood's phase 3.

**Owner checks:** at level 2, choose a pick that changes how a skill behaves, on the pad. Tier 3 opens on the Ashbrood kill. Respec at the WayLamp. Swap a skill with View, the D-pad, A and B. An elite shows its affix.

**Tests:** `test_skills` covers gating, respec and saving.

**Risks:** 12-18 picks to build and tune. Start with tier 1 if time is short.

**Status:** built on `proto/kl-m2`, awaiting the owner's playtest. Nothing in the scope was cut: all three tiers for Lampfire, Fireglobe, Lance and the dash, and trees for the Beam and Hearth ring too (both still kept). **Added from the M1c playtest:** the Ashbrood's phase 2 moves (ash wave, low pass with cold embers, calls from the dark) and phase 3 ("last of the brood", combos, the ember window), re-tuned to about 3.3 minutes; Lampfire catches only after 72 px of flight. Save version 8 (a version 7 save migrates: its level becomes points, its cards become picks). **Not in M2:** gear (the pack's Gear tab), so Kindled kills, Hot core and Lee wait for M3 (a v7 save keeps them as carried lines).

**Tests:** `test_skills` (points, tiers, respec, saving, the owner's note), new `test_builds` (every pick) and `test_affixes`; `test_save` (v7 to v8), `test_ashbrood_kill` (three phases, real kills), `test_fights` (the new moves, phase 3, idle checks, a faint during every boss attack), `test_combos` (the catch distance), `test_input` (the pack on a pad).

---

## M3: Loot

**Scope:** GLoot data; 4 slots with Plain starting gear; 3 rarities; the Ashbrood's relic; 20 affixes; drops; the bag and compare; salvage; satchels become bag slots.

**Owner checks:** compare and equip in under 5 s on the pad; a Hollow clear gives about 18-20 items; hold X salvages; a nest left hatching drops no items.

**Tests:** `test_loot` (seeded rolls, rates, stacking, summoned foes drop nothing, save); `test_upgrades` (satchel).

**Risks:** tuning multiplies; GLoot on Godot 4.7.2 is untested.

---

## M4: People, part 1

**Scope:** Dialogue Manager, the balloon, People and Errands pages, Amos and "Amos's cart". Merge the people from `PLAN_NPCS_ENEMIES.md` into STORY and DESIGN.

**Before it starts:** the owner gives pronouns for Amos, Maud, Kit and Ivo, or keeps none (DECISIONS 2026-11-27).

**Owner checks:** talk with A, close with B; lines match STORY.md; the errand shows in the journal; the Wide Pack adds 4 slots.

**Tests:** `test_npcs`; `check_docs` reads `.dialogue` files.

**Risks:** Dialogue Manager on Godot 4.7.2 is untested.

---

## M5: The Reedmarsh

**Scope:** the U-route and the north-leg WayLamp (DESIGN §12.4); 26 packs at Lv 5-7; Slowwater, Fenlight, the mire Clinker, the Sump and its relic; the Reservoir's job; Moth-lights at level 7; Maud; Ivo (cut line).

**Owner checks** (pad): walk from the marsh's entry to the climb without crossing your own path; Reservoir light brings the Sump up; Moth-lights on Y; level 8 by the climb.

**Tests:** a marsh route test like the loop's; `test_leveling` for the region.

**Risks:** water readability; Slowwater fairness.

---

## M6: The Windward Ridge

**Scope:** 22 packs at Lv 8-9; gusts that snuff and drift; the Gutterkite; the Hooded Lamp's job; the downwind Clinker; the Galekite and its relic. Wheeling flame (level 9); Oswin's coat; Kit and the Long lens; the re-cut (cut line). **The loop's stones:** the "The way is open." toast, a note readable from below, and stones drawn as a fallen pile. Pack 11 (52,93) and nest 7 (60,91) move off the foot of the old climb, so the shortcut lands on quiet ground.

**Owner checks** (pad): the Ridge is one walk; a gust snuffs exposed lamps and pushes fireballs; the Galekite snags on a Hooded Lamp; coming down the old climb, the stones fall with the line, and from below the note reads.

**Tests:** `test_ridge` wind checks; the loop test's stones checks.

**Risks:** wind punishing more than it teaches.

---

## M7: The Lakeshore

**Scope:** carve region 4; thick fog; the Mirror Post; the Fogstilt; the fog Clinker; the Tallest and its relic (first cut); Ebba. Merge `PLAN_LAKESHORE.md` into DESIGN and STORY.

**Owner checks** (pad): a mirror lane is the quick way through the fog; fire crossing a beam on a Fogstilt unravels it.

**Tests:** shore route and fog tests.

**Risks:** fog too slow; the Tallest's scope.

---

## M8: The Still Lake and the finale

**Scope:** region 5; the catch ring; the Soul in three phases; the portal; the ending and sandbox; Ebba's crossing.

**Owner checks** (pad): the Soul takes 6-10 minutes; a faint returns you to the start of the phase; the portal and the credits; the valley stays open.

**Tests:** finale phase test.

**Risks:** the biggest milestone; phase 2 depends on M5-M7.

---

## M9: Polish and the Linux build

**Scope:** owner art and audio; a pad letter grid for the name; accessibility; a full balance pass; 3 or more external playtests; a Linux export tested on a clean machine.

**Owner checks:** the DESIGN "Done when" list (§18).

**Risks:** polish creep. Hold the cut lines.

---

## Not yet placed

The plan describes these but names no milestone. Place each one when its neighbour milestone is planned in detail. M1a built three of them: damage numbers, lamp-kind cycling on the D-pad, and the auto-fire option. **Uncertain** where each belongs; the guesses below are guesses.

| Item | Plan | Likely |
|---|---|---|
| The L3 tuning panel behind a dev-build flag | §3, §16 | not done in M1a; M1b or M9 |
| Warmth +8 a level; foe damage +8% a level | §5 | not in M1b's scope list (§18); M2 or a balance pass |
| Fog slows walking to 85% at most, not 60% | §7 | M1b |
| The map shows WayLamp icons, lures you've seen and the share explored | §14 | M1b or M2 |
| `check_docs.py` reads skill and item texts | §17 | M2 and M3 |

---

## History

What was built before the re-plan, in short. The full old roadmap is in `docs/archive/ROADMAP_PRE_REPLAN.md`; the old playtests are in `docs/archive/PLAYTEST_PRE_ARPG.md`.

**On `main` (the tending game, 2026-11-26 to 2026-11-27):**
- **M0 Setup:** the Godot project, git, the input map. Done.
- **M1 Core prototype** (light, fuel, fog): gate passed ("felt like caring, not a chore").
- **M2 Resources and gathering:** gate passed.
- **M3 The Reedmarsh and the Reservoir Lamp,** with wind moved up: gate passed.
- **M4 Atmosphere** (CC0 art, fog, font, sound): mostly done. Never done: occluder shadows, a fog shader, mist particles, recorded ambience.
- **M4b Light-based conflict** (Wicklings, the ward, warmth, fainting): done and playtested.
- **M5a Story and guidance** (opening, goals, journal, pointer, tips): done; the owner: "that was great".
- **M5b HUD redesign:** built with playtest follow-ups.
- **M5 (part):** the Windward Ridge, glass, the Hooded Lamp, the Mirror Post, save slots, satchels and lamp glasses. Done.
- **WayLamps:** playtested and merged into `main` (WayLamps take fuel directly).
- **M5c-M5e** (people and creatures in three steps) and the old **M6** were never started. The game plan replaces them.

**On the prototype line (`proto/kl-*`, 2026-11-27), not yet on `main`:**
- **Keeper's Light in the Hollow** (`proto/kl-hollow`): the beam, burst and dash; packs, nests, the Clinker, the Ashbrood; wick and level-up cards. Owner playtest done; follow-ups built.
- **Bigger regions** (`proto/kl-big`): every region 4x the area, and the performance pass.
- **Leveling balance** (`proto/kl-balance`) and **level-gap wick** (`proto/kl-xpgap`).
- **The first 10 minutes** (`proto/kl-onboard`): Option B.
- **The loop and WayLamp fast travel** (`proto/kl-loop`): built and merged into `proto/kl-hollow`. Loop texts approved; three loop calls under review.
- **The fuel-and-abilities playtest** led to the re-plan (PLAYTEST.md). The game plan v2 was approved on 2026-11-27.
- **M1a, fire in the Hollow** (`proto/kl-m1a`): built 2026-11-27; awaiting the owner's playtest.
- **The readability step** (`proto/kl-readability`): telegraphs, the keeper's feedback, the art swap hook and the performance pass; built 2026-11-27, awaiting the owner's playtest.
