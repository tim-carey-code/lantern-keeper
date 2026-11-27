# Lantern Keeper — Roadmap

> Rewritten 2026-11-27 from `docs/replan/GAME_PLAN.md` §18 (approved by the owner; DECISIONS 2026-11-27, "the game plan approved"). **DRAFT for owner approval** (GAME_PLAN §17). The version before the rewrite is `docs/archive/ROADMAP_PRE_REPLAN.md`.
> Scope follows the game plan and this roadmap. New ideas go to "Maybe later" in `DESIGN.md` §18, not into a milestone.
> No time estimates. A milestone is finished only when its owner checks pass.

---

## Status (2026-11-27)

| Milestone | State |
|---|---|
| History: M0-M5b, the prototypes and the loop | done; see "History" at the end |
| **M1a** Fire in the Hollow | being built on `proto/kl-m1a` (not merged; nothing in DESIGN describes it as built) |
| **M1b** No more tending | planned, after M1a passes. **Merge to `main` once M1b passes.** |
| **M2** Builds | planned |
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

**Scope**
- Lampfire, Fireglobe, Lance and the dash. The Beam (7.5 hp/s) and Hearth ring as optional picks in a plain Skills list.
- The action bar and HUD bars, on pad and keyboard/mouse. Aim assist and aim hold. The Y rule. The flask on B, read after the menu guard. The D-pad off movement.
- The regen table (DESIGN §5.2). Oil from packs, elites and the Ashbrood. Rest at a lit WayLamp (flasks and warmth).
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

**Tests:** `test_combat` becomes `test_skills`. New `test_flasks` and `test_input` (B after each menu, the D-pad through each menu). The bench runs 40 projectiles.

**Risks**
- Feel is most of the work. If the fire doesn't feel good, do one more feel pass before M1b.
- RT and RB on one finger; the auto-fire option is the fallback.
- Fog lights may cost more than the budget allows.

---

## M1b: No more tending

**Scope**
- Lamps never burn, in every region's code paths. Fuel and glass cut. Scrap piles one-off. The woodpile becomes scenery.
- Old lamps and WayLamps lit by touch. The lamp limit (3 outside held ground) and the 15 s replant delay.
- The faint rule (DESIGN §12.4).
- Hollow foe levels 1-4 (Ashbrood 5), foe scaling, and the curve at base 7 and exponent 1.65.
- The lures. The Hollow's goals and tips (new text as DRAFT in STORY). The lamp glass gives charge.
- Ridge wind goes inert until M6. The unused ward code goes.

**Owner checks**
1. No prompt, tip or HUD item says fuel, refuel or gather, and lamps never dim.
2. The hut lamp, the north-path lamp and the WayLamp light by touch; the WayLamp wakes the Ashbrood.
3. A 4th lamp outside held ground is refused, with the reason. A picked-up lamp can be planted again after 15 s.
4. After a faint, cleared packs stay cleared, a half-fought pack is whole and asleep, the Ashbrood restarts its phase, and nothing carried is lost.
5. A pack, a nest and an elite look different through the fog.
6. The last Hollow level comes on the Ashbrood kill.

**Tests:** rewrite `test_core`, `test_threats` (light reactions; the ward goes), `test_waylamps` (light by touch, hold fights) and `test_upgrades` (the lamp glass part). **`test_ridge`:** keep its layout, trail and placement checks; delete its tending, ward and wind-burn checks (wind checks return in M6). New `test_faint`. `test_leveling` checks level 2 at the crook and the Ashbrood kill on both routes (L5 beeline, L6 explorer).

**Risks:** hidden fuel dependencies (goals, prompts, HUD); old saves start fresh.

**Then:** merge to `main`, and rewrite the README (GAME_PLAN §17).

---

## M2: Builds

**Scope:** skill points and fixed branches, tiers 1-3, for Lampfire, Fireglobe, Lance and the dash (the Beam and Hearth ring only if kept). Respec at rest. The pack screen with Skills, Journal and Map tabs; the card screen goes. Elite affixes. The Ashbrood's phase 3.

**Owner checks:** at level 2, choose a pick that changes how a skill behaves, on the pad. Tier 3 opens on the Ashbrood kill. Respec at the WayLamp. Swap a skill with View, the D-pad, A and B. An elite shows its affix.

**Tests:** `test_skills` covers gating, respec and saving.

**Risks:** 12-18 picks to build and tune. Start with tier 1 if time is short.

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

The plan describes these but names no milestone. Place each one when its neighbour milestone is planned in detail. **Uncertain** where each belongs; the guesses below are guesses.

| Item | Plan | Likely |
|---|---|---|
| Damage numbers that pop and drift, grey when the gap cut the wick | §14 | M1a (the juice baseline) |
| The L3 tuning panel behind a dev-build flag | §3, §16 | M1a (the input work) |
| Lamp-kind cycling on the D-pad, replacing the lantern list on Y | §3, §16 | M1a (Y becomes a skill slot) |
| Warmth +8 a level; foe damage +8% a level | §5 | M1b (with foe scaling) |
| Fog slows walking to 85% at most, not 60% | §7 | M1b |
| The map shows WayLamp icons, lures you've seen and the share explored | §14 | M1b or M2 |
| The auto-fire option | §3, §14 | after M1a, or in M1a as the fallback |
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
