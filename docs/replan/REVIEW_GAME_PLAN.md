# Review: GAME_PLAN draft v1

**Reviewed:** `docs/replan/GAME_PLAN.md` on `proto/kl-replan` at `5413962`, 2026-11-27.
**Checked against:** `docs/replan/AUDIT.md`, `docs/research/ARPG_REFERENCES.md` (the brief), `docs/DECISIONS.md`, the code in this worktree (HEAD), and `proto/kl-loop` at `ff8426b` (read with `git show`). "loop" below means a file as it is on `proto/kl-loop`.
**Not done:** Godot and the tests were not run. All numbers below come from reading the code and doing arithmetic on the plan's own starting values.

**Counts:** 1 blocker, 13 major, 16 minor.

---

## Blocker

### B1. The starting kit is still mostly the beam and the burst the owner called boring, and nothing in the kit is a fireball
- **Section:** §3 (the bar), §4.1 (the kit and "the level-1 bar"), §18 M1.
- **Problem:** The level-1 bar is Spark, **the Beam on RB by default**, an empty LB, and **Flare, which is the built burst** (§4.1: "The built burst"). So in the first ten minutes, two of the three skills are the old kit. The owner's complaint was "the beam and the ward ... we need to shoot flaming light fireballs" (DECISIONS 2026-11-27; commit `42bcdee`).
  - The ward isn't wired into play. `player.gd:85` passes only beam, flare and dash to `combat.tick`, and `update_ward()` is never called (AUDIT §1.1). F/RB, the ward's old binding (DECISIONS 2026-11-26), now fires the burst (`tools/setup_input.gd:42`), which is a ring that pushes foes back. So the "ward" the owner played was almost certainly the burst. *(This is an inference. Confirm it with the owner through the kit question, M2.)*
  - No skill is a fireball that bursts on impact. Spark is a 2-damage bolt. Lance pierces. Firepot is lobbed at a spot on the ground and only arrives at level 3. The picks that change how a skill behaves arrive at level 7 (see M1).
  - "Optional" (DECISIONS: "keep as optional for now") means the owner can choose the Beam. Putting it on the default bar makes it the main aimed skill at the start.
- **Fix:**
  1. Add a real fireball as the default RB skill at level 1. A working spec: aimed; bursts on hit for 60-70 px; leaves about 1.5 s of flame; 0.15-0.2 charge; about 0.8 s cooldown; no damage to shells, so Lance keeps its job.
  2. Unlock the Beam at level 1 in the Skills tab, but leave it off the default bar. One press slots it, so the owner can still try it.
  3. Change Flare's base effect so it's no longer the old push ring. For example, make today's tier-3 "Ring of fire" the base: a ring that sets foes alight.
  4. Consider moving Firepot to level 2 (the crook) and Lance to level 3. Spark's half damage to shells already handles the crook's shelled guard.
  5. Add an M1 owner check: "The first packs are fought with fire skills only. The Beam is tried from the Skills tab, and the owner records keep or cut."

---

## Major

### M1. The exciting picks come too late, no new skills arrive after the Hollow, and M2 promises tier 3 it can't reach
- **Section:** §4.2, §9 ("new skills at levels 2, 3 and 5"), §18 M2.
- **Problem:**
  - Tier 3, the picks that change behaviour, needs level 7, which is the Ridge (region 3). M1 covers levels 1-5, so it offers only tiers 1-2. About 10 of those 28 picks only change a number: Quick hand, Bright, Wide, Long lance, Lean, Quick pot, Deep tank, Long-lived, Far-seeing, Quick step. The brief says "every pick should change shape or verb, not just a percentage" (brief §3).
  - All seven skills are unlocked by level 5, the end of the Hollow. Four of the five regions add no new skill.
  - M2's scope lists "tier-3 variants", but the Hollow ends at level 5 and the marsh and Ridge stay walled off until M4 and M5. Tier 3 can't be reached or playtested in M2.
- **Fix:**
  - Gate tiers at levels 1, 3 and 5, so the first tier-3 pick lands on the Ashbrood kill. Or move "tier-3 variants" to M4.
  - Swap the number-only tier 1-2 picks for shape changes. Examples: Lean becomes "the Lance leaves a burning line"; Quick pot becomes "the pot bounces once".
  - Spread new skills over the later regions, for example one at levels 7 and 9, or one tied to each guardian's relic.

### M2. The owner questions skip the kit itself and leave most of the supersede table with no way to approve it
- **Section:** §19, and "Decisions this plan would supersede".
- **Problem:**
  - The skill list and the default bar (§4.1), which answer the owner's main complaint, have no question of their own. They sit inside Q3 ("branches, not cards ... with the kit above"), so the owner can't approve the branches and still reject the kit.
  - The table has 23 rows marked "needs the owner's OK", but only about 8 of them are covered by the 8 questions. #19 (slot jobs), #51 (the Lakeshore landing), #58 (the Clinker stays put), #65 (satchels), #92/94/108 (wind on the Ridge only) and the DESIGN §5 crafting row have no question.
  - Uncertainty 8 (salvage and Kit's re-cut count as crafting) and Ivo's cut line (see M3) also need answers, but they aren't asked.
  - Nothing marks which answers M1 needs first.
- **Fix:**
  - Add a first question: "Is this the kit you meant by fireballs?" List the skills, the default bar, and the Beam as an opt-in.
  - Add a closing question: "Approve the rest of the supersede table, except any rows you strike."
  - Tag each question "before M1", "before M2" (loot, crafting) or "before M3" (people, including the pronouns for Amos, Maud, Kit and Ivo).

### M3. Four decisions are overridden without a row in the table
- **Section:** "Decisions this plan would supersede"; §8.2, §9, §11, §3, §12.
- **Problem:**
  - **#16** (wick by level gap): "Every foe has a level (Lv 1 by the hut up to 6 by the WayLamp)". The plan sets Hollow foes to Lv 1-4 (§8.2) and the Ashbrood to Lv 5, but the code has `kl_ashbrood_level := 7` (loop `systems/tuning.gd:226`) and packs and nests at Lv 5-6 (loop `scripts/main/main.gd:528-549`). §8.2 presents "Lv 5" as if it were the built value.
  - **#59 / P7** (people are IN for v1; keep all five people): §11 and §18 make Ivo a cut line.
  - **#75** (mirrors turn both ways, "X/Space left"): §3 moves keyboard building off Space and puts dash on it. The keyboard key for turning a mirror left is gone, and the plan doesn't name a new one.
  - **#101** (in part): "fainting ... drops half your carried resources". This is superseded together with #64 but isn't listed.
- **Fix:** Add the four rows: #16 (Hollow foe levels 1-6 become 1-4; Ashbrood Lv 7 becomes 5), #59/P7 (Ivo as a cut line, needs an OK, or drop the cut line), #75 (name the new keyboard key), and #101 beside #64. The numbering of the existing rows is correct (all 23 rows checked against AUDIT §3).

### M4. Y and B take the right thumb off the stick, and the built aim then snaps to the walking direction
- **Section:** §0 item 3, §3 ("fires along your last aim"; "Any skill fits slots 2-4"), Q8.
- **Problem:**
  - §0 says all six inputs work while you aim. In twin-stick play only RT, RB, LT and LB do. Y and B are under the right thumb.
  - When the stick is released, the built aim falls back to the keeper's facing, which is the direction you walk (`scripts/player/combat.gd:36-44`, `aim = _face`). It doesn't keep the last aim. So a Lance or Firepot on Y fires where you walk, and Firepot's "stick tilt" range has no value at that moment. While B is pressed, Sparks held on RT also turn toward your walk.
  - The ceiling cited from the brief is misread. Diablo IV fits 6 skill slots plus a potion plus an evade, which is 8 inputs (brief §1). Diablo IV also aims by facing, not with a right stick, so its face-button skills don't carry over to twin-stick play.
  - The brief puts the flask on LB and the dodge on B (brief §1). The plan does the opposite for a good reason (the owner already dashes on LT), but it doesn't say that it differs.
- **Fix:**
  - Add an aim latch: keep the last stick aim for about 0.4 s after the stick is released (`kl_aim_latch`, new).
  - Let Y take only skills that don't aim (Flare, Moth-lights).
  - Reword §0 item 3: "four inputs work while you aim; Y and B are for things that don't aim."
  - Restate the brief citation, and note the swap of flask and dodge with its reason.
  - With the latch, B for the flask works mid-fight. Drinking needs no aim, and Diablo IV shows an emergency action on a face button is usable (brief §1).

### M5. The D-pad still moves the keeper, and a D-pad "map" button will fire inside menus
- **Section:** §3 (map on D-pad up, lamp kind on D-pad left and right), §14.
- **Problem:**
  - The D-pad is bound to movement today (`tools/setup_input.gd:31-34`). The plan doesn't say that binding goes.
  - `map_screen.gd:54` toggles the map on the `map` action in `_input`. With `map` on D-pad up, pressing up to move through the travel list, the Gear grid or the Skills tab opens or closes the map. That is a focus trap. Lamp-kind cycling on left and right has the same risk.
- **Fix:** Remove the D-pad from `move_*`. Read `map` and lamp cycling only when no menu is open (`Tuning.ui_open` is false), and have menu handlers ignore those actions. Add a test that moves through every menu with the D-pad and checks the map never opens.

### M6. The B press that closes a menu will also drink a flask
- **Section:** §3 (B is the flask and "still means back in menus"), §16 (Keeper: "Add the flask").
- **Problem:** Menus guard against a closing press leaking into play with `Progress.block_input()` (`journal.gd:67`, `map_screen.gd:45`, loop `travel_menu.gd:175,235`). The player checks that guard at `player.gd:101`, but combat inputs are read earlier, at `player.gd:85` (`combat.tick(...)`). If the flask is read next to the other combat inputs, the B that closes the journal, map, travel list, a note or the pack also drinks.
- **Fix:** Read the flask after the `input_blocked()` guard, or make `combat.tick` respect it. Add a test: open and close each menu with B, and check no flask charge is spent.

### M7. Light is too strong in a fight: charge refills fast in any light, even while you're hunted
- **Section:** §5 (charge regen; the regen stance), §6 (limit and full refund), §4.1 (Beam).
- **Problem:**
  - The "hunted" rule stops warmth regen, but charge still refills at +0.5/s in any light. That is about 8x the base 0.06/s, or roughly 2.8 Lances a second.
  - A planted lamp costs nothing to move (full refund), never goes out, and its core burns small foes. So the best play is to fight inside your own lamp. That makes Spark's +0.04 refund and the flask's +0.4 charge almost worthless.
  - The owner already finds combat "still too easy" (DECISIONS, combat-kit playtest), and AUDIT §4.3 notes lanterns as a repellent "may be too strong".
  - Small mismatch: §4.1 says the Beam stops all regen; §5 says "+0.5/s in light except while beaming".
- **Fix:** Apply the hunted check to charge from light too, or cut it to about 0.1/s while hunted. Consider a 10-20 s cooldown before a picked-up lamp can be planted again. Settle the Beam's regen rule in one place.

### M8. The starting numbers miss the plan's own time-to-kill targets, and Lance makes the Beam trial unfair
- **Section:** §4.6 (targets), §4.1, §8.1 (foe scaling), §9 (+6% damage a level).
- **Problem:** The targets and the numbers don't agree, even before gear (M1 has none).
  - **Wicklings:** foes gain +35% hp a level, the keeper only +6% damage. A same-level Wickling takes 3 Sparks from level 3 (5.1 hp against 2.24 damage) and 5 by level 12 (14.6 against 3.3). The target is 2.
  - **Packs:** a level-1 pack of 4 Wicklings is 12 hp. Spark alone does about 6.7 dps, so that is about 2 s of fire, not 8-12 s.
  - **Guardians:** a Lv-5 Ashbrood at the plan's scaling has about 290 hp plus 86 shell over three phases. Outside light, charge comes in at about 0.19/s (0.06 base + 0.04 × 3.3 Spark hits), which pays for about one Lance a second. Spark plus Lance give about 17 dps, so about 25 s of damage. That's roughly 1-1.5 minutes with dodging, not 2-4.
  - **Lance vs Beam:** Lance has no cooldown, pierces 3 and does full shell damage. It does about 39 damage per 1.0 charge against the Beam's 20, and the Beam also blocks regen. The Beam trial the owner asked for is rigged against it.
- **Fix:** Add a time-to-kill table worked out from the numbers (ARPG skill, balance pass step 2). Make the scaling rates agree, for example foe hp +12% a level or keeper damage +15% a level. Give Lance a cooldown of about 0.5 s. Set guardian hp from the 2-4 minute target. Or change the targets.

### M9. The XP curve and the level bands don't fit the regions' size
- **Section:** §9 (base 7, exponent 2.0; the band table).
- **Problem:**
  - Wick needed to level up is 7·L². That gives: Hollow (levels 1-5) 210; Reedmarsh (5-7) 427; Ridge (7-9) 791; Lakeshore (9-11) 1,267; Still Lake (11-12) 847.
  - A foe's value grows only +25% a level (`kl_xp_level_growth`, loop `tuning.gd:224`), about ×1.4 in the Hollow, ×3.25 on the Lakeshore and ×3.6 on the Still Lake.
  - So in base kills, the Lakeshore needs about 2.5x the Hollow's whole content and the Still Lake about 1.5x. The Still Lake is a finale island.
- **Fix:** Add a wick budget for each region (wick needed, foe count, levels, wick it supplies). Then flatten the exponent (about 1.6), steepen foe value, or give the last level from the Lakeshore guardian or the Soul's phases.

### M10. "Nothing can be farmed" isn't true
- **Section:** §1 pillar 5, §10 ("Fixed packs make loot finite").
- **Problem:** Nests hatch 3 Wicklings every 10 s while you're near (`scripts/enemies/wick_nest.gd:30-39`), and the Ashbrood calls packs of 3 every 8 s. Hatched and called foes drop like any other foe (`foe.gd:315-316`, no check for `summoned`). At the plan's 3% item rate plus scrap, a nest or a stalled phase 1 is an endless loot source. The level gap stops the wick but not the loot.
- **Fix:** Summoned foes drop no items, oil or scrap. Say so in §10 and test it in `test_loot`.

### M11. Gear effects that change a skill repeat branch picks
- **Section:** §10 (the 4 skill-changing affixes) vs §4.2.
- **Problem:** Three of the four are already branch picks. "Firepot throws two pots" is Firepot tier 2 *Second pot*. "Lance returns" is Lance tier 3 *Returning*. "Moth-lights +2" is Moth tier 1 *Swarm*, which already takes motes from 3 to 5. Whether a Rare and the matching pick stack is undefined. Undefined stacking is a code question, and duplicates make Rares feel like a free branch pick.
- **Fix:** Gear gives only effects no branch gives. Write down the stacking rule. Add a test case.

### M12. M1 is too big, and parts of it don't add up
- **Section:** §18 M1, §16 (tests).
- **Problem:**
  - M1 holds about 15 systems: six skills with 24 tier picks, a shared projectile system, a status system, the bar, aim assist, flasks, the charge and warmth rules, removing tending everywhere, lighting by touch, the lamp limit, foe scaling, the curve, the faint rule, Ashbrood changes, juice, the HUD, tips and save version 5. That isn't "soon" (brief §6, trap 2: systems multiply).
  - "Tending removed from the code everywhere" breaks `test_ridge` (it tests tending and the ward), but `test_ridge` isn't rewritten until M5. `test_upgrades` (satchel +10 carry, lamp-glass ward) isn't in any milestone. `tools/run_tests.sh` fails on any script error.
  - Pack and elite oil drops: M1 says "Flasks" and M2 says "drops and oil". Without M1 drops, the Hollow has 3 flasks and no rest until the Ashbrood falls.
  - Elite affixes (§8.1), the six lure looks (§7), damage numbers and the "reduce flashes" toggle (§14) aren't in any milestone.
- **Fix:**
  - Cut M1 to a feel slice: Spark, the fireball (B1), Firepot, Lance, dash; the bar with aim assist; flasks with pack, elite and Ashbrood oil; the charge and warmth rules; lighting by touch; tending removed from what the Hollow uses; the faint rule; per-target hit-stop and the shake slider.
  - Move to M2: branches (tier 1 for about 4 skills first, brief §6), the lamp limit, foe scaling (the Hollow's hand-set levels are enough), and moving the HUD bars.
  - Leave the Beam and Flare as built, with no trees, until the owner decides to keep them.
  - Remove marsh and Ridge tending in M4 and M5, or rewrite `test_ridge` in M1. Put `test_upgrades` in a milestone. Place elite affixes in M2 and the lures in M1 (the lure problem is a Hollow problem, AUDIT §4.3).

### M13. Some M1 owner checks can't be done, and none checks the main complaint
- **Section:** §18 M1, "Owner checks".
- **Problem:**
  - Check 5b ("travelling there doesn't [refill]") can't be done in M1. Only the Hollow WayLamp can be lit, and the travel list says "Light another WayLamp to travel to it" (loop `travel_menu.gd`).
  - No check asks whether the fire skills are fun, or for a keep/cut verdict on the Beam. That is the decision the owner deferred: "we will see ... when i play it".
  - Check 8 ("only the D-pad and A") also needs View to open the pack and B to back out.
  - Check 7 depends on the route taken unless `test_leveling` enforces both the beeline and the full clear.
  - There are no pad-specific checks for M4-M6.
- **Fix:**
  - Drop 5b, or add a dev-only second WayLamp.
  - Add: "fire skills rated keep/rework/cut; the Beam tried and judged".
  - Add: "drink with B while holding RT, and Sparks keep their aim".
  - Add: "closing each menu with B never drinks".
  - Add: "moving through each menu with the D-pad never opens the map".
  - Say check 7 holds on both routes (`test_leveling`).

---

## Minor

1. **Citations (§4.1, §5, Q7).** In Death's Door, *sword hits* refill the bow (brief §1). The plan says "as Death's Door's bow does". Q7 cites "AUDIT finding 10", which doesn't exist; the faint issue is AUDIT M19 and §4.3.
2. **Rest vs travel (§5).** "Arriving by fast travel doesn't [refill]; resting does" changes nothing in practice: rest is free and instant at any lit WayLamp, so travel plus rest is a full refill. That's fine with fixed packs. Say so, and drop the claim that it closes the brief's free-heal loop (brief §2).
3. **Faint edge cases (§12).** Waking at your own lamp inside a sleeping pack's 320 px wake radius can chain faints; wake at least that far from any pack you haven't cleared. Say what a second faint does to an uncollected `WickDrop`. Say whether guardian oil drops again on a retry. Define "hunted" for a timid Wickling waiting at the edge of your light.
4. **Name clashes.** "Wick" is the XP, a gear slot and part of the Soul's name. "Long lens" is a base and a relic. "Splitting" is an elite affix and a Lance pick. "Kindling" is a Beam pick and what a WayLamp does. "Tight focus" appears twice. "Flare" for the burst: the owner once said the old flare "wasn't really a flare" (DECISIONS 2026-11-26).
5. **Slot rule (§10).** Moth-lights and Firepot are projectiles but sit in the burner. State the rule, for example "burner = anything that bursts or burns".
6. **M2 says "2 Hollow relics"**, but §10 names only one Hollow relic, the Ashbrood's.
7. **L3 opens the dev tuning panel** (`setup_input.gd:55`). A pad player clicks the left stick by accident while moving hard. Hide it behind a dev flag in the owner's build.
8. **RT and RB share a finger.** Holding RT for Spark while tapping RB needs two fingers on the right shoulder. Offer an option where Spark fires whenever the right stick is pushed past about 0.8.
9. **Keyboard.** Right mouse is `cancel` today (`setup_input.gd:38`). §3 moves pick-up off Q but not off right mouse, which now becomes slot 2.
10. **Name entry on a pad.** It is a `LineEdit` with no on-screen keyboard (`scripts/ui/opening.gd:28-35,69`). A pad-only player can only be "Keeper". Note this beside M1 check 1.
11. **People (§11).** Amos stands "by a cart at the Hollow WayLamp", but his errand cart is "stuck among the quiet south packs": two carts, or one? Ebba "rows you to the far shore", but #54 says her boat crosses to the Lake after the finale. Which shore?
12. **Approved card values change (§4.3, Q3).** Hot core ("twice as hard") and Lee ("25% less") were approved "as written", but as affixes they become rolled x% values. Say so in Q3 and in row 18.
13. **The docs table (§17)** leaves out `LICENSE-ASSETS.md` and `assets/art/placeholders/README.md` (AUDIT M27).
14. **Skill swap while hunted (§3).** Grey the Skills tab out with the reason, as the travel list does ("Can't travel while something hunts you", loop `travel_menu.gd:15`).
15. **Jargon for the owner.** Swap or explain in a short glossary: AoE (area attack), respec (take back your points), affix (bonus line), implicit stat (built-in stat), item level, bands, dps, cut line, the "Shells" column (damage to shells). Unclear lines: Moth tier 3 "Homing home"; §4.5 "regrow ... until broken" (in the code a dented shell regrows, a broken one doesn't, and only for foes with `shell_regrows`, `foe.gd:17,224`).
16. **Playtime (§2).** 5-7 hours against DESIGN's 1-2 is a scope change. It deserves one line for the owner.

---

## Spot checks: claims about what's built (31 checked)

✓ = matches. ✗ = wrong or missing something.

| # | Plan claim | Evidence | Result |
|---|---|---|---|
| 1 | 12 cards at `scripts/ui/level_up.gd:4-18`; §4.3 places all 12 | `level_up.gd:4-18` | ✓ (all 12 placed, effects match) |
| 2 | Carried-fuel top-up at `player.gd:69` | `player.gd:69` | ✓ |
| 3 | The ward at `player.gd:161-180` | `update_ward` :161, `apply_ward` :170-180 | ✓ |
| 4 | A faint resets packs at `player.gd:211-213` | `player.gd:211-213` | ✓ |
| 5 | `kl_burst_*`: 120 px, 2 dmg, 140 px, 3 s, 0.2 | loop `tuning.gd:121-125` | ✓ |
| 6 | `kl_beam_*`: 240 × 24 px, 6 hp/s, 0.3/s, 70% walk | loop `tuning.gd:116-120` (half-width 12) | ✓ |
| 7 | `kl_dash_*`: 110 px, 0.16 s, 0.9 s, 0.08 | loop `tuning.gd:126-129` | ✓ |
| 8 | `warmth_max` 100, `warmth_regen_per_sec` 20 | loop `tuning.gd:96,98` | ✓ |
| 9 | `hand_lamp_*` 44-104 px, recharge 0.5/s, drain | loop `tuning.gd:66-69` | ✓ |
| 10 | `travel_hunt_radius` 384 px | loop `tuning.gd:108` | ✓ |
| 11 | `kl_pack_wake_radius` 320, closer on the route | loop `tuning.gd:231`; packs 20/23, wake 5/6 tiles (`main.gd:546,548`) | ✓ |
| 12 | `kl_elite_hp` 9, `kl_elite_shell` 4 | loop `tuning.gd:131-132` | ✓ |
| 13 | `kl_shell_regrow_wait` 3 s | loop `tuning.gd:136` | ✓ |
| 14 | Curve today: base 6, exponent 1.25; cap 12 | loop `tuning.gd:209-211` | ✓ |
| 15 | Level gap: full to +1, ×0.25 a level, 0 at +5 | loop `tuning.gd:219-221` | ✓ |
| 16 | `post_lamp_cost_scrap` 5, `reservoir_radius` 200, `fog_slow_min` 0.6 | loop `tuning.gd:10,36,47` | ✓ |
| 17 | `kl_timid_share`, `kl_light_tolerance` 2.5 s, `kl_light_burn_dps` | loop `tuning.gd:242-244` | ✓ |
| 18 | Loop places: Hollow WayLamp (78,124), Clinker (70,119), Ridge entry (100,56), glazier (99,51), station (116,26), Ridge WayLamp (120,30), steps (124,34) | loop `main.gd:477-478,183,304-305` | ✓ |
| 19 | Marsh WayLamp at (200,140) in code, south-east island in the loop's DESIGN | loop `main.gd:326`; loop `DESIGN.md:389` | ✓ (the loop's DESIGN also says "pumphouse island" at :209) |
| 20 | Fast travel blocked while hunted, kindling, or in a guardian fight | loop `travel_menu.gd:6,15-17,93-106` | ✓ |
| 21 | Global `Engine.time_scale` hit-stop in `foe.gd` `_die()` | `foe.gd:276-277` | ✓ |
| 22 | Plain shake offset in `player.gd` | `player.gd:193` | ✓ |
| 23 | Projectiles can join the `light_source` group | `fog_grid.gd:4,151` | ✓ |
| 24 | Ember magnet 140 px | `ember.gd:7` | ✓ |
| 25 | Hollow: 88 pack foes, 6 elites, 12 nests, 4 caches; about 20 items | loop `main.gd:527-564` (87 + guard; 5 + guard elites; 7 Spitwicks) | ✓ (fixed sources give about 18.5 items; see M10 for summoned foes) |
| 26 | Save version 4 becomes 5 | `save_game.gd:9` | ✓ |
| 27 | Test lists cover every scene | 13 scenes on the loop; plan keeps 7 and rewrites 6 | ✓ (but see M12 on timing) |
| 28 | Oswin as "they" at `README.md:25`, STORY §1 | `README.md:25`; `STORY.md:14` | ✓ |
| 29 | Input moves: map off LB, list off Y/Tab, pick-up off B/Q, build off Space | `setup_input.gd:37-41` | ✓, but D-pad movement (:31-34) and right-mouse `cancel` (:38) aren't handled ✗ (M5, minor 9) |
| 30 | Y "fires along your last aim" | `combat.gd:36-44` falls back to `_face` (walk direction) | ✗ (M4) |
| 31 | Ashbrood "Lv 5" shown as the built guardian | `kl_ashbrood_level := 7`, loop `tuning.gd:226` | ✗ the change isn't flagged (M3) |

---

## Checks performed

- Read the whole GAME_PLAN, AUDIT, brief and DECISIONS, and the ARPG agent skill.
- Compared every row of the supersede table against AUDIT §3 (numbers and marks). Looked for KEEP rows the plan changes without saying so.
- Did the arithmetic on the plan's own numbers: time-to-kill, charge income, the XP curve by region, drop counts. All of it uses starting values; none of it is a test result.
- Read the input map, the aim code, the menu input guards and the drop and hatch code on HEAD and on the loop, to check the gamepad claims.

## Not checked, and what is still uncertain

- Godot and `tools/run_tests.sh` were not run. Statements about what tests would break come from reading the test list, not from running it.
- That the owner's "ward" means the burst (B1) is an inference from the code and the bindings. The owner should confirm it.
- The time-to-kill figures assume foe scaling is linear and applies to shells too. If scaling compounds, the gaps are larger.
- Whether Dialogue Manager and GLoot work on Godot 4.7.2 (plan uncertainty 4), and what projectile fog-lights cost (uncertainty 5), weren't checked.

---

## Verdict

**Ready after fixes.** The structure, coverage of the docs and accuracy against the code are good: 28 of the 31 spot checks match, and the supersede table's numbering is right. One revision is enough if it:
- fixes B1: a real fireball, the Beam off the default bar, Flare no longer the old push;
- adds the kit question and the bulk-approval question (M2) and the four missing rows (M3);
- fixes the pad conflicts (M4-M6) and the light/charge rule (M7);
- reconciles the numbers (M8, M9);
- trims M1 and its checks (M12, M13).

None of this needs a new structure. The edits stay inside §3, §4, §5, §9, §10, §18, §19 and the table.
