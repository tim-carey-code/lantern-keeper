# Lantern Keeper: the first 10 minutes (onboarding plan)

**DRAFT for owner markup, 2026-11-27.** This is a plan only. No code or docs in the repo were changed.
Everything the player sees is marked **DRAFT**. Each OWNER line is a decision for you.

**Sources (read-only):** branch `proto/kl-hollow`: `docs/DECISIONS.md`, `docs/PLAN_KEEPERS_LIGHT.md` §3, §6 and §8, `docs/DESIGN.md` §9, `docs/STORY.md`, `docs/PLAYTEST.md`, `.agents/skills/lantern-keeper-arpg/SKILL.md`, `scripts/main/main.gd` (the `HOLLOW_PACKS`, `HOLLOW_NESTS` and `CACHES` tables, `_place_hollow_prototype`), `systems/story/story.gd`, `systems/tuning.gd` and `scripts/enemies/enemy_pack.gd`.

**How to read the positions.** Positions are tile offsets from the hut's start tile `(48, 136)`: **+x is east and −y is north**, so `(+1, −22)` is 1 tile east and 22 tiles north. The distances are straight lines from `HOLLOW_PACKS` and `HOLLOW_NESTS`, before `_spot_in_region` snaps each one to open ground. A pack "is on the route" if it lies within its wake radius of the route: 320 px, which is 10 tiles.

---

## 0. In short

- **The recommendation is Option A: bring the find home.** Move the keeper's crook (the Post Lamp find) and its **Clinker** to **about 22 tiles north** of the hut. That is a bit under halfway to the WayLamp, which fits the owner's rule ("a third to halfway along"). Before it go **one lone Wickling**, then **a pack of three**. Put **a cold old lantern you can relight** at 12 tiles north as a haven. Right after the find, **one nest on the road** is the first lock the Post Lamp opens. Then one tougher pack, then the WayLamp.
- **Main route:** 3 of the 24 packs, 1 of the 12 nests, and the Clinker. The other 21 packs and 11 nests become optional side content on the flanks and in the south.
- **What the player gets in 10 minutes:** a relit hut lantern (about 0:40), a first kill (about 2:00), a second haven (about 3:00), the Clinker, the Post Lamp and level 2 (about 6:30), a first nest burned out with their own lamp (about 8:30), and the WayLamp in sight by about 10:00.
- **Builder size: S to M.** The work is new positions and two small additions: an optional wake radius for each pack, and three goal rows. It also needs about five new tips and one route test. No new systems.

---

## 1. Diagnosis: why the current first 10 minutes lose a newcomer

| # | Problem | Evidence (code) | What a newcomer feels |
|---|---|---|---|
| 1 | **The find is last, not a third of the way.** | The crook and Clinker are at `(+10, −40)`, 41 tiles out. The WayLamp is at `(+16, −46)`, 49 tiles out. The key arrives about 8 tiles before the end of the road, so it is never used as a key before the boss. | "Where am I going, and why does it take so long?" The goal banner names something you won't see for minutes. |
| 2 | **A nest you can't hurt sits on the route.** | Nest 4 is at `(+8, −24)`, about 2 tiles off the straight line to the crook. Nests hatch 3 Wicklings every 10 s while you are within 10 tiles, and only a lantern's core burns them. You have no lanterns yet. | An endless stream of enemies with no visible answer. This is most likely the main source of "way too many enemies". |
| 3 | **Too many fights stack up on the way.** | About 4 packs (8, 9, 5 and 2) wake within 10 tiles of the route before the crook: roughly 17 foes, including Spitwicks and two shelled elites. Pack 2 sits 4 tiles from the Clinker, so the elite fight overlaps a pack. | Being swarmed before learning the kit. |
| 4 | **The first fight is the wrong lesson.** | The endless trickle of Wicklings is off (`kl_ambient_spawns = false`), so there is no lone first Wickling. The first contact is pack 8 (4 Wicklings and a Spitwick) at about 24 tiles. The `wickling_close` tip fires in the middle of that pack. | A ranged foe and four melee foes on first contact, with the beam taught in a 6-second tip. |
| 5 | **There's no haven between the hut and the find.** | The hand lamp dims to an ember after 45 s in the dark. Lamp charge (needed for the beam, burst and dash) refills only in lantern light, and the only lantern is the hut, 41 tiles back. | Each fight drains you, and the only refill is a long walk back through cleared ground. |
| 6 | **No early win.** | After you relight the hut lantern, the next reward is the crook at 41 tiles. Level 2 needs 15 wick: one per Wickling, two per Spitwick, or 15 for the Clinker. | Minutes with nothing gained. |
| 7 | **The goal and the note disagree.** | The ledger says "The north lamps first. Wake the WayLamp up there…", but the banner says "Find the keeper's post north of the hut". Neither mentions that something guards it. | Two targets, and no warning about the Clinker. |
| 8 | **The pointer points straight through the danger.** | The arrow aims at `crook_post`, and the straight line crosses packs 8 and 5 and nest 4. | Following the arrow walks you into the worst of it. |
| 9 | **The hut is in the middle of the Hollow, not the south.** | The Hollow is an ellipse centred on the start tile (radius 38 × 44), so it runs about 44 tiles south of the hut. Nine packs, three nests and the lamp glass are down there. | Going south first meets fights and nests that lead nowhere. *Note: this differs from the brief's "hut in the south"; the code was checked.* |
| 10 | **Too many lures at once.** | 24 pale-blue pack pulses and 12 nest glows show above the fog, and the two kinds look alike. | Noise. You can't tell a fight from a nest from the goal. |

---

## 2. The first 10 minutes, beat by beat

Times start when the letter closes. Assumed walking speed: 5 tiles/s, or about 3 tiles/s in fog. Walking the whole route takes under 30 s, so nearly all the time below is fights and reading.

```
            N
  (+16,-46)  WayLamp + Ashbrood           <- beat 7 (in sight ~10:00)
  (+14,-40)  pack 2': 4 incl. 1 Spitwick, 1 elite
  (+4,-34)   nest A  (the first lock)      <- beat 6
  (+1,-22)   keeper's crook + Clinker + 6-scrap cache  <- beat 5
  (+7,-19)   pack of 3 Wicklings           <- beat 4
  (-3,-16)   one lone Wickling             <- beat 2
  (+2,-12)   cold old lantern (haven 2)    <- beat 3
  - - - - - - - - -  16 tiles: the calm line (nothing hostile inside)
  (+3,0)     hut lantern   (-2,+1) woodpile   (+2,-1) scrap   (-3,-2) ledger
            HUT (0,0)
            S  (the south is optional: side finds, quiet packs)
```

| # | When | Where | What happens | What the player learns | Win |
|---|---|---|---|---|---|
| 1 | 0:00-1:00 | The hut, `(0,0)` to `(+3,0)` | Take fuel from the woodpile, relight the hut lantern, read the ledger. All as built, except the new ledger text. | Gathering, refuelling, reading. Light is safety. | **First win:** the hut lantern takes. Journal entry 1. |
| 2 | 1:00-2:00 | Leaving the hut's light, about `(0,−7)`. The **lone Wickling** is posted at `(−3,−16)` and wakes and comes to you. | One Wickling (3 hp; the beam kills it in 0.5 s). The beam prompt shows as it closes. If it's a timid one, it hangs at the light's edge, and you step out and beam it. | **The beam:** hold and aim. | First kill, +1 wick. |
| 3 | 2:00-3:00 | A **cold old lantern** at `(+2,−12)`. The pointer turns to it. The existing cold-lantern frame and pulse show it through the fog. | Relight it with 1-2 carried fuel. It refills lamp charge and warmth. | **Havens:** fight near light, and come back to refill. | **Second lit lantern.** You now have a haven by the coming fights. |
| 4 | 3:00-4:30 | A **pack of 3 Wicklings** at `(+7,−19)`, which wakes as you approach from the haven (wake radius 7 tiles, §7). | Three plain Wicklings: no Spitwick, no elite. When two are close, the burst prompt shows. | **The burst:** throw them back. Timid ones won't come into the light. | +3 wick (4 in all). |
| 5 | 4:30-7:00 | The **keeper's crook** at `(+1,−22)`, with its red pulse on screen from the haven, 10 tiles away. The **Clinker** sleeps on it and wakes at 7 tiles. | The Clinker's roll has a 0.8 s tell, which teaches the **dash**. Its shell teaches **keep the beam on**. With 2 lamps' worth of beam and the haven 10 tiles back, it is a fight with a refill in the middle (PLAN §8.2), but a short trip. | **The dash, and shells.** | **First find:** the Post Lamp unlocks. Clinker +15 wick (19 in all) gives **level 2** and the "Trim the wick" choice. A **6-scrap cache** at the crook means you can build right away. |
| 6 | 7:00-9:00 | **Nest A** at `(+4,−34)`, 12 tiles past the crook, so it doesn't hatch during the Clinker fight. Nothing else wakes near it. | The banner asks you to burn it out. Plant a Post Lamp beside it and hold for 6 s while its hatchlings come. | **The find is the key:** your new lamp does what your beam can't. | **First lantern you built**, and the first nest burned out (+8 wick). The road north is open. |
| 7 | 9:00-10:00+ | North-east to the WayLamp at `(+16,−46)`. On the way, **pack 2'** at `(+14,−40)` (4 Wicklings: one Spitwick, one shelled elite). | The first ranged foe and the first elite in a pack, met at level 2 with a lamp to plant. | Putting it all together. | The WayLamp is in sight, and the `kindle_hollow` goal is up. The Ashbrood fight comes after minute 10. |

**A newcomer who goes south or sideways first** meets only optional content (§5). Nothing hostile is within 16 tiles, no nest is within 30, and no Spitwick within 25. So wandering is safe, and the pointer always leads back to the route.

---

## 3. Making the find reachable early: the options

| | Option | For | Against |
|---|---|---|---|
| **A (recommended)** | **Move the crook and the Clinker to about 22 tiles north** (`(+1,−22)`), with a cold lantern as a haven at `(+2,−12)`. The Clinker no longer sits by the WayLamp. | One fight is still the find, so "earned" survives (owner's playtest: "the Post Lamp felt earned"). It matches PLAN §3.1 ("a third to halfway along") and the original slice-4 idea (about 10, then 17 tiles). It needs the fewest new things. | The Clinker is a level-1 fight. That is offset by the nearby haven and two warm-up fights. A balance check is needed (§7.4). |
| B | A **smaller guard first:** a single shelled Wickling sits on the crook at about 20 tiles, and the Clinker stays near the WayLamp as a mid-boss. | A gentler first elite. | The Clinker would guard nothing, so it becomes a second gate before the Ashbrood. Two elites in one region dilute "an elite sits on the find". The find feels cheaper. |
| C | Find first, fight later: the crook is unguarded at about 15 tiles, and the Clinker guards the first nest. | The fastest lantern. | It breaks the owner's rule that an elite sits on each find, and the Post Lamp no longer feels earned. |

**The brief suggested 15-20 tiles.** Exactly 15-20 doesn't fit if we keep the **16-tile calm rule** *and* put two warm-up fights before the crook (each needs its own space so they don't wake together). About 22 is the nearest that keeps all three. See OWNER 2 if you'd rather relax the calm rule for the lone Wickling.

---

## 4. The difficulty ramp from the hut to the WayLamp

| Zone | Distance north | On the route | Purpose |
|---|---|---|---|
| 0: calm | 0-15 | nothing hostile; woodpile, scrap, hut lantern, ledger, the cold lantern at 12 | read, relight, breathe |
| 1: learn | 16-22 | 1 Wickling, then 3 Wicklings, then the Clinker on the crook | the beam, then the burst, then the dash and shells |
| 2: the key | 23-35 | nest A, alone | the Post Lamp as the answer |
| 3: approach | 36-49 | pack 2' (one Spitwick, one elite), then the WayLamp and the Ashbrood | everything together; the boss |

Foes the route wakes, in order: **1, 3, the Clinker, a nest, 4, the Ashbrood.** Before this plan, about 17 foes and a nest you couldn't hurt stood before the find.

---

## 5. Pack and nest layout (keeping 24 packs and 12 nests)

**Rules for the builder:**
- **The main route holds at most 3 packs and 1 nest** within wake radius of the route, plus the Clinker and the Ashbrood.
- **Near the start:** nothing hostile within 16 tiles. No nest within 30 tiles, because a nest you can't yet burn must never be the first thing in any direction. No Spitwick within 25 tiles.
- **Key fight spots are clear:** nothing else wakes within 10 tiles of the crook, nest A or the haven, apart from the two warm-up packs, which are meant to.
- **Optional content** sits on the flanks (west and east, toughest in the north) and in the south (quiet, with 3 Wicklings each). The side finds and caches stay guarded there.

Offsets from the hut. "n/S/E" is Wicklings in the pack / of them Spitwicks / of them shelled elites, as in `HOLLOW_PACKS`.

| Pack | Now (offset, n/S/E) | Proposed | Role |
|---|---|---|---|
| 20 | (0,+24) 3/0/0 | **(−3,−16) 1/0/0** | **route: the lone Wickling** |
| 23 | (−20,−2) 3/0/0 | **(+7,−19) 3/0/0**, wake 7 tiles | **route: the first pack** |
| 2 | (+12,−30) 5/1/1 | **(+14,−40) 4/1/1** | **route: the last pack before the WayLamp** |
| 5 | (−2,−32) 4/1/1 | (−12,−30) 4/1/0 | optional (it was on the route) |
| 8 | (0,−24) 4/1/0 | (+16,−28) 4/1/0 | optional (it was beside the crook) |
| 9 | (+14,−18) 4/1/0 | (+18,−16) **4/0/0** | optional, east, near the start |
| 10 | (−18,−16) 4/1/0 | same place, **4/0/0** | optional, west, near the start |
| 1 | (+22,−36) 5/1/1 | (+26,−34) 5/1/1 | optional, east by the WayLamp |
| 3, 4, 6, 7, 11-19, 21, 22, 24 | as now | unchanged | optional (flanks and the south) |

| Nest | Now | Proposed | Role |
|---|---|---|---|
| 4 | (+8,−24) | **(+4,−34)** | **route: nest A, the first lock** |
| 3 | (+22,−40) | (+28,−42) | optional. This also keeps it out of the Ashbrood fight; today it is 8.5 tiles from the WayLamp. |
| 5 | (−12,−20) | (−26,−30) | optional, west (today it is 23 tiles from the hut, and unburnable then) |
| 1, 2, 6-12 | as now | unchanged | optional; all are now 30 or more tiles from the hut |

**Checked against the table above** (a straight-line route through hut, haven, crook, nest A and WayLamp; positions before snapping):

| Check | Result |
|---|---|
| Hut to crook | 2 packs (4 Wicklings), no Spitwicks, no elites, no nests |
| Crook to WayLamp | 1 pack (pack 2'), 1 nest (nest A) |
| Hostile within 16 tiles of the hut | none |
| Nests within 30 tiles of the hut | none |
| Spitwicks within 25 tiles | none, once pack 9 is changed to 4/0/0 |
| Around the crook | only the two warm-up packs |
| Around nest A | nothing |
| Totals | still 24 packs and 12 nests. 21 packs and 11 nests are optional. |

The builder's route test (§7.4) must re-check this after snapping.

---

## 6. Guidance: what a newcomer sees at each step

There is one goal at a time in the banner, the pointer is on, and a tip shows once, at the bottom, for 6 s. Button names follow the device in use, as built.

| Beat | Banner goal | Pointer | Through the fog | Tip or note (**DRAFT**) |
|---|---|---|---|---|
| 1 | Take fuel from the woodpile *(built)*, then Relight the old lantern by the hut *(built)*, then Read the ledger by the hut *(built)* | woodpile, lantern, ledger | | **Ledger, line 3 (DRAFT, replaces the current line):** *Under it: My lamp hangs on my crook, on the north path. Take it back. Then the WayLamp, at the top. - Oswin* |
| 2 | **DRAFT:** *Relight the old lamp on the north path* | the cold lantern at `(+2,−12)` | its cold frame and pulse (built) | `wickling_seen` (built): *Something small moves in the dark. It is drawn to your lights.* Then **`wickling_close` (DRAFT, replaces the current text):** *Hold [beam] to shine on it. Aim with [aim].* |
| 3 | *(the same goal completes)* | | the crook's red pulse comes on screen | **`haven` (DRAFT, new; on relighting it):** *Lantern light fills your lamp and warms you. Fight near it.* |
| 4 | **DRAFT:** *Take back the lamp from Oswin's crook* (replaces "Find the keeper's post north of the hut") | the crook | red pulse | **`burst` (DRAFT, new; two foes within 130 px):** *Too close. [burst] throws them back.* |
| 5 | *(the same goal)* | the crook | the Clinker's pale eyes | **Banner as the Clinker wakes (DRAFT, optional):** *Something is sitting on the crook.* **`shell` (DRAFT, new; first beam on a shell):** *Light cracks a shell. Keep it on.* **`dash` (DRAFT, new; first roll tell):** *It is gathering itself. [dash] steps clear.* **Crook note (PLAN §6.4 draft, kept):** *A keeper's crook, fallen across the path. The lamp on it is cold, but whole. / Tied to it: Plant one where you mean to stand. The small ones will not come into it. - Oswin / New lantern: Post Lamp. [build] builds one.* |
| 6 | **DRAFT:** *Burn out the nest with a Post Lamp* | nest A | cold blue glow | **`nest` (DRAFT, new; first nest in sight):** *A nest. Your light can't touch it. A lantern's core can.* **`build_here` (DRAFT, new; first time 5 scrap is carried in front of a nest):** *Plant a Post Lamp beside it. Then hold.* |
| 7 | Kindle the WayLamp in the north Hollow *(built)* | the WayLamp | the WayLamp's shape | `waylamp_seen` (built). The Ashbrood banner is in PLAN §6.4. |

**Text rules followed:** short, plain and calm, never horror. Oswin signs "- Oswin" and is "he". Notes are three lines or fewer. No step numbers.

**Optional journal line** after the crook (**DRAFT**): *His lamp was under something that would not let go. It is mine now.* (OWNER 6.)

---

## 7. Concrete changes for a builder

### 7.1 `scripts/main/main.gd`
1. **The crook and the Clinker:** `_spot_in_region(Vector2i(58, 96), …)` becomes `HOLLOW_C + (+1,−22)`, which is tile **(49, 114)**. Update its comment ("owner: near the WayLamp").
2. **The haven:** add `_add_lantern(start + Vector2(2, −12) * FogGrid.TILE)` with `fuel = 0.0`, as for the hut lantern. Keep a reference to it (for example `waypost_lantern_pos`) for the goal and the pointer. It is friendly, so the calm rule allows it.
3. **The cache at the crook:** add a `CACHES` row `[FogGrid.R_HOLLOW, Vector2i(50, 115), "scrap", 6]`, so the keeper can afford a Post Lamp (5 scrap) on the spot.
4. **`HOLLOW_PACKS` and `HOLLOW_NESTS`:** apply §5. Add a sixth, optional column to `HOLLOW_PACKS` (after the foe level, added 2026-11-27) for a wake radius in tiles. Use it only for pack 23 (7 tiles), so it doesn't wake during the lone Wickling's fight.

### 7.2 `scripts/enemies/enemy_pack.gd`
- `var wake_radius := -1.0`. When it is below 0, use `Tuning.kl_pack_wake_radius`.
- Packs already support `count = 1`. No other change is needed.

### 7.3 `systems/story/story.gd`
**`GOALS` in order:**

| Goal | Status |
|---|---|
| `gather_fuel`, `relight_first`, `read_ledger` | unchanged |
| **`relight_waypost`** | new. Done when the haven lantern is lit. The target needs handling like `start_lantern`. |
| `build_post` | new text (§6) |
| **`burn_nest`** | new. Done when `Progress.cleared` has `nest_hollow_4`, or any nest. Target: nest A. |
| `kindle_hollow` | unchanged |

**`TIPS`:**
- New: `haven`, `burst`, `shell`, `dash`, `nest` and `build_here`.
- Replace the text of `wickling_close`.
- Add triggers in `_check_tips` from existing signals (foe distance, `elite` or Clinker hit by the beam, the Clinker's roll tell, a nest seen, scrap ≥ `post_lamp_cost_scrap` near a nest).

**Ledger:** change line 3 to the §6 text, both in `main.gd` and in STORY §6, in the same branch. Docs follow the code.

### 7.4 `systems/tuning.gd` (and the F1 panel)

| Value | Now | Change | Why |
|---|---|---|---|
| `kl_first_pack_wake_radius` | n/a | **new, 224.0** (7 tiles) | the per-pack override for pack 23 |
| `kl_clinker_leash` | 480 | keep | It reaches the haven (10 tiles) but not the hut (22): a refill mid-fight, and a safe hut. |
| `kl_clinker_shell` | 12 | keep. **Drop to 8 only if** the balance check below misses its target | The first elite now meets a level-1 keeper. |
| `kl_wick_first_level` | 15 | keep | 4 Wicklings plus the Clinker (15) gives 19, so level 2 lands at the find. |
| `kl_pack_wake_radius`, `kl_nest_wake_radius`, `kl_clinker_wake_radius` | 320 / 320 / 224 | keep | The layout is built around them. |

**Balance target** (written first, as the ARPG skill asks): *a fresh level-1 keeper with the haven 10 tiles away beats the Clinker in 30-60 s and faints at most once.*

The arithmetic: (24 hp + 12 shell) ÷ 6 dps is 6 s of beam. At 0.3 charge/s that is 1.8 lamps, so one refill at the haven. Measure this with a headless test, then record the numbers in DESIGN §9.

### 7.5 Tests (`tools/tests/test_prototype_hollow.gd`, or a new `test_onboarding.gd`)

**Change the existing ones:**
- Line ~105, "the Clinker guards its post near the WayLamp", becomes **"the Clinker guards the crook 18-26 tiles north of the hut"**.
- The nest test's label "three of them on the road north" becomes **"one of them on the road north"**.

**Add these.** All are measured after snapping. The route is the polyline hut, haven, crook, nest A, WayLamp. "On route" means within that foe's wake radius of the route.
1. **The first route to the find:** hut to crook crosses **at most 2 packs, 4 foes in all, 0 Spitwicks, 0 elites and 0 nests**.
2. **The route after the find:** crook to WayLamp crosses **at most 1 pack and exactly 1 nest**.
3. **The whole first route** crosses **at most 3 of the 24 packs and 1 of the 12 nests**. The counts stay 24 and 12.
4. **A safe start:** nothing hostile within 16 tiles (existing). **No nest within 30 tiles. No Spitwick or elite within 25.**
5. **Clear fight spots:** no pack or nest other than the warm-up packs within its wake radius of the crook. Nothing within wake radius of nest A. Nest A is at least `kl_nest_wake_radius + 1 tile` from the crook.
6. **The haven:** it exists, starts cold, is 10-14 tiles from the hut and within `kl_clinker_leash` of the crook.
7. **You can afford the key:** reachable scrap within 3 tiles of the crook is at least `post_lamp_cost_scrap`.
8. **Level 2 at the find:** the wick from the route packs plus `kl_clinker_wick` is at least `kl_wick_first_level`.
9. **Goal order:** `GOALS[0..6]` are `gather_fuel, relight_first, read_ledger, relight_waypost, build_post, burn_nest, kindle_hollow`, and every pointer target resolves to a node.
10. **The Clinker balance** (§7.4): a headless fight with a scripted beam reports the time and the faints. As a test it checks only that the time is under 90 s; the target goes in DESIGN §9.

Run `tools/run_tests.sh`, `python3 tools/check_docs.py` and a capture frame of the view from the haven, to show the red pulse is on screen.

**The approval boundary:** this plan approves nothing. The builder needs your markup before changing the repo.

---

## 8. OWNER questions

**Owner answers (2026-11-27):**
1. **Option B:** a small guard on the Post Lamp; the Clinker moves to be a mid-boss near the WayLamp.
2. **Allow the lone Wickling closer**, so the Post Lamp sits at about 18 tiles.
3. **A second cold lantern on the way north:** try it; cut it if it feels cheesy.
4. **One nest on the main route:** decide after playing.
5. **The 6-scrap cache at the Post Lamp:** yes.
6. **The §6 texts:** approved.
7. **The south of the Hollow:** keep it as optional content, possibly a side quest from an NPC there.


1. **Option A** (crook and Clinker at about 22 tiles, with a haven at 12)? Or B (a small guard on the crook, with the Clinker as a WayLamp mid-boss)?
2. **The calm rule:** keep 16 tiles, which puts the crook at about 22? Or allow the lone Wickling at about 12 tiles, which pulls the crook in to about 18?
3. **The haven:** a second cold old lantern on the north path, as a second relight and win? Or none, so the Clinker fight is harder?
4. **Only one nest on the route.** The original plan had three on the road north. Is one lock enough for the Hollow, or should a second sit about 5 tiles off the route?
5. **The 6-scrap cache at the crook:** OK, or should the player gather scrap by the hut first (a new goal)?
6. Text: the new ledger line, the five new tips, the goal lines, and the optional Clinker banner and journal line in §6. Keep, change or cut?
7. **The south:** today 44 tiles of the Hollow lie south of the hut. Keep it as optional content (the lamp glass and quiet packs), or shrink it in a later map pass?

## 9. Still open

- **Straight-line routes:** the counts above use straight lines. Rock may push the real path sideways. The test should use the snapped positions, and a walkable path if one is cheap.
- **Telling lures apart:** sleeping packs (pale blue pulses) and nests (cold blue glows) look alike above the fog. A shape or colour split may be needed. The art is yours.
- **The Ashbrood** hasn't been rechecked for a keeper who arrives at about level 2 or 3 with one built lamp. That is for the balance pass after the map change.
- **Timings** are estimates from walk speed and kill times, not a playtest. The gate is a first-time tester who isn't the owner, playing to minute 10 without help.
- **Leads** (PLAN §6.3) are still cut, so the single goal line carries the route. If they return, only the route stays as Oswin's lead.
