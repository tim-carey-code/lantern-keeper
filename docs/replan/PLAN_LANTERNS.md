# Lantern Keeper: lanterns at the centre, and target lock (plan addendum)

**APPROVED by the owner, 2026-11-27** ("1-6 yes to all": every §9 question answered as recommended, including the supersede list in §7). Numbers are starting values for tuning; in-game texts stay DRAFT until shown to the owner.

**Inputs.** `docs/replan/GAME_PLAN.md` v2 (the plan of record; "plan §n"), `docs/DESIGN.md` (what is built; "DESIGN §n"), `docs/ART_DIRECTION.md` ("art §n"), `docs/research/ARPG_REFERENCES.md` ("brief §n"), and the code on this branch: `scripts/player/combat.gd`, `scripts/player/skills/*.gd`, `scripts/enemies/foe.gd`, `scripts/lanterns/lantern.gd`, `systems/light/light_sense.gd`, `tools/setup_input.gd`.

**How to read it.** Same rules as the plan. Numbers are starting values for tuning. Names in `code font` are `systems/tuning.gd` entries; "(new)" marks one that doesn't exist yet. All in-game text is DRAFT. The keeper is "they". Original design only: other games are references for mechanics, never for names, art or levels.

**Words used here.** *Dark*: outside every light. *Dim*: inside only the keeper's hand-lamp light. *Lit*: inside a lamp's light (the list is in §2.1). *Exposed*: a foe that is lit. *Flame*: the lamp head on a planted lamp (`Lantern.LAMP_Y`, `CROOK_LAMP`), where combos trigger. *Lock*: the target lock in §6. *Slot*: a lamp slot (§5), not a bar slot.

---

## 0. In short

1. Light sets the rules of a fight. In the dark, foes take 30% less and their shells can't break. In lamp light they take 30% more and their shells break faster. The hand lamp makes a middle state, "dim", so you can always close in.
2. The Ashbrood can only be hurt in lamp light. A fixed old lamp on the bowl's rim and the ember in the bowl mean you can never be stuck.
3. Your fire combos with lamps: Lampfire **catches** and splits at a flame, Fireglobe **flares** a lamp into a big burst, Lance **chains** between two lamps.
4. Lamp types become build pieces (turret, well, ward, bouncer), upgraded by loot lines on the four slots. You plant more lamps as you level: 2 at the start, 5 at level 12, up to 6 with gear.
5. Lamps on old posts **claim** ground for good: the fog stays back and secrets show. At the Lakeshore, the dark comes for your lamps.
6. **Target lock:** R3 locks the best foe near your aim; a flick switches; holding the stick steers freely without dropping the lock. With a lock, Y may hold aimed skills.
7. **Build order:** a new **M1c** after M1b (light states, combos, the Ashbrood, lamp slots and the lock, all in the Hollow). Lamp types and loot lines go in M3 and the region milestones; claiming goes in M3; the dark fighting back in M7-M8.

---

## 1. The problem

The owner, after M1b removed tending: "with this new system i feel like the lanterns are useless and therefore making the game useless lol".

Why it happened. Tending was the lamps' job. With no fuel, a planted lamp is a heal spot between fights (plan §5: charge only 0.1/s while hunted, no warmth) and a nest-burner. In a fight it does almost nothing. Elites, the Clinker and the Ashbrood ignore light (built, `foe.gd` `tick_foe()`). The fire kit is fun (DECISIONS, M1a playtest), but it never asks where your lamps are.

The fix the owner approved ("yes that direction feels right"): make light the rule of every fight, make lamps part of your attacks, make lamp types a build, and make lit lamps change the map. This addendum gives each a rule, numbers and a look.

---

## 2. The four parts

### 2.1 Part 1: light against dark

**The three states.** Each foe works out its state once a frame (from `LightSense`, plus the keeper's hand lamp).

| State | Where | Damage taken | Shells | How it reads |
|---|---|---|---|---|
| **Dark** | outside every light | x0.7 (`kl_dark_dmg_mult`, new) | wear, but **can't break**: they stop at `kl_dark_shell_floor` 1.0 (new) | Eyes and rim only (art §1.5): body `#0b0e1a`, eyes `#a3bcd4`, rim `#36507a`. Its bar is dimmed. A shell bar shows a dark notch at the floor. Hits on a held shell clink (built `_clink`) |
| **Dim** | inside the keeper's hand-lamp light only: 44-104 px, set by lamp charge (`hand_lamp_*`) | x1.0 | wear and break as today (DESIGN §4.5) | Full colours, as today |
| **Lit** (exposed) | inside a lamp's light (below) | x1.3 (`kl_lit_dmg_mult`, new) | wear x1.5 (`kl_lit_shell_mult`, new), and break | Full colours, a 1 px warm rim-light on the side facing the lamp, and pale crack lines on shell plates. The first time a foe steps in, a soft sound slot `exposed` (owner's job; a Kenney stand-in) |

**What counts as lit.** A planted lamp; a lit old lamp (the hut, the north path); a lit WayLamp; a mirror beam; a claimed post's stub light (§2.4); a lamp's flare (§3); later, Fireglobe's *Beacon* and the dash's *Ember rest* (M2). **Not lit:** the Lampfire light pop, bolt lights and burning ground. They clear fog only. If your own fire exposed its own target, the rule would vanish.

**Small rules.**
- A foe stays exposed for `kl_exposed_linger` 0.5 s (new) after it leaves light, so the edge doesn't flicker.
- The multiplier applies last, once, after every add-on (plan §10: numbers add, never multiply). Steady lamp damage (`"core"`, `"light"`, mirror `"beam"`) skips it, so core burns stay at 2 hp/s. Nests skip the whole rule; only cores hurt them (built).
- "Elites, mid-bosses and guardians ignore light" (built) stays true for **movement**: they don't flee and cores don't burn them. They can still be exposed.
- The hand lamp's dim radius shrinks as you spend charge (`get_light_radius()` in `player.gd`). Spending charge shrinks your close-in reach.
- A first-time tip (DRAFT, STORY): "In the dark they shrug off your fire. Bring light to them."

**Why three states, not two.** Before the crook, the keeper has no lamp to plant. The crook's guard is shelled (Lv 2). With only dark and lit, it could not be killed at all. Dim makes it a choice: fight from range in the dark and wear the shell to a sliver, or step in close and break it.

**Time to kill, re-checked** (plan §4.6 arithmetic, L1 Lampfire 2 a hit, 0.35 s a bolt):

| Fight | Dark | Dim | Lit |
|---|---|---|---|
| Wickling Lv 1 (3 hp) | 1.4 a hit: 3 hits, 0.7 s | 2 hits | 2 hits |
| The crook's guard (10.1 hp, 4.5 shell) | can't be killed: the shell holds at 1 | 11 hits, about 3.5 s (as the plan) | shell 3 hits, then 4 hits: about 2.4 s |
| Spitwick Lv 1 (4 hp), Lance 5 | 3.5: not one shot | one shot | one shot |

So the plan's targets become the **dim and lit** targets, and the dark is about 1.5x slower. *Uncertain:* Spitwicks keep 190-250 px off, so they are mostly in the dark. If that feels like a chore, lower `kl_dark_dmg_mult` for small foes only, or let a Spitwick's throat glow count as dim.

**The Ashbrood (DECISIONS "the Ashbrood's ember").** It can be hurt **only when lit**. Dim counts as dark for it (`kl_ashbrood_needs_light` true, new). In the dark every hit glances off with the built clink, and the boss bar hint says "It shrugs off fire in the dark. Bring a lamp." (DRAFT).
- **Phase 1, in the bowl.** It covers the ember with its wings. Two ways to expose it:
  - Plant a Post Lamp whose light reaches the bowl (224 px). Its ash puff (140 px, built) now also snuffs lamps inside the circle for 4 s (`kl_ashbrood_puff_snuff`, new). So the best spot is 150-220 px out: inside the light, outside the puff.
  - Throw a Fireglobe into the bowl. That stirs the ember: a 120 px flare (`kl_ember_flare_radius`, new) exposes it for 4 s (`kl_ember_flare_time`), at most once per 8 s (`kl_ember_flare_cd`). This works with no scrap at all.
- **Phase 2, the dives.** It dives at the nearest lit lamp (built). During its 4 s sit it **smothers** that lamp. The lamp stays lit while it sits, so the sit is the punish window. Then the lamp is out for 8 s (plan §6's snuff, moved to after the sit).
- **The rim lamp (new world object).** One old lamp stands on the bowl's rim, about 180 px out, and is relit by touch like the hut lamp. The Ashbrood can smother it, but it never needs scrap. This is the no-soft-lock guarantee.
- **Health.** Keep 220 per phase (built) and re-measure. The x1.3 raises damage, and having to be lit lowers uptime. *Uncertain* which wins; `test_skills` re-runs the 2-3 minute target.

### 2.2 Part 2: the keeper's fire combos with lamps

Details and numbers are in §3. The rules:
- A combo triggers at a lamp's **flame**: a planted lamp or a lit old lamp. WayLamps don't combo; they are in held ground.
- Each combo reads in warm colours only (art §1.4 rule 1). Shake and hit-stop use the built trauma system.
- **Fireglobe snaps.** A landing within `kl_flare_reach` 40 px of a flame moves onto it, so a flare is easy on a pad.
- The Beam's combo (Feed) exists only if the owner keeps the Beam. Keep-or-cut is still open.

### 2.3 Part 3: lantern types are build pieces

Each type has a job in a fight, a cost in scrap, and loot lines that change it (table in §4). The four item slots (lens, burner, coat, wick) are named for lamp parts. Each now also shapes one lamp job, following the plan §10 slot rule:
- **lens** shapes direct shots (the Post Lamp's turret, the Mirror Post's bounce);
- **burner** shapes burns and blasts (flares, the Reservoir's burn);
- **coat** shapes protection (the Hooded Lamp's ward);
- **wick** shapes lamp count and light (slots, radius).

**How many you can plant** grows with level and gear, like summon slots (§5).

### 2.4 Part 4: lit lamps claim the valley

**Old posts.** Each region has fixed **old posts**: stone footings with an iron hook, shown as a small red-amber pulse once seen. The Hollow gets 8 (a proposal; the places aren't chosen yet). Plant a lamp on a post. When it has stood for `kl_claim_time` 10 s (new) with nothing hunting you within its light, the post is **claimed**:
- A stub light of 64 px (`kl_claim_stub_radius`, new) burns there for good, even if you pick the lamp up. It counts as lit (part 1).
- Fog never comes back within 192 px (`kl_claim_clear_radius`, new). Today unlit tiles fog back in (DESIGN §7.1).
- Hidden things within 256 px show (`kl_claim_reveal_radius`, new): side caches, a secret path, a loot glint (plan §7's lure).
- A lamp standing on a claimed post uses no lamp slot.
- The map shows "Posts 3/8" for the region.

**Counting toward holding.** Recommended: claiming is a reward, not a gate. At 4 of 8 posts, a hidden cache shows on the map. At 8 of 8, the region's post cache opens (one Bright-or-better item) and every secret shows on the map. A region is still **held** by its guardian kill (plan §8.2). *Alternative (not recommended):* the guardian wakes only at 4 posts. That forces a play style and risks a soft lock.

**The dark fights back (the Lakeshore, M7; the Still Lake, M8).** This is the old "tides" idea (DECISIONS "new direction and font": kept for later).
- Every 90-120 s (`kl_tide_period_min`, `kl_tide_period_max`, new), a tide rises. A cold edge arrow and the sound slot `tide_windup` warn 3 s ahead (art §4.4 rule 5).
- Wicklings come out of the shallows and go for your **lamps**, not you. A Wickling on a lamp smothers it over 3 s (`kl_tide_smother_time`). The lamp then stays out until you touch it.
- A claimed post whose lamp is out for 20 s loses its claim (`kl_tide_unclaim_time`). Its stub light stays, so you can retake it.
- You defend with kills, the Hooded Lamp's ward and mirror beams (which burn Wicklings, built). Tides stop when the region is held.
- *Uncertain:* the pacing needs a playtest. The Soul's phase 3 snuff (plan §8.3) is the finale's version.

---

## 3. The combo list

Lit damage (x1.3) applies on top when the foe is exposed. It usually is, because combos happen at lamps.

| Combo | Trigger | Effect | Numbers (all new) | Look |
|---|---|---|---|---|
| **Catch** (Lampfire) | A bolt passes within 28 px of a flame | The bolt catches: +1 damage (2 → 3). It throws 2 side bolts at ±18°, each 2 damage and a fresh 240 px. Side bolts can't catch again. Once per bolt | `kl_catch_reach` 28, `kl_catch_dmg_add` 1, `kl_catch_split` 2, `kl_catch_spread_deg` 18, `kl_catch_split_dmg` 2, `kl_catch_split_range` 240 | The bolt swells and brightens; the flame gulps; two thin warm trails fan out |
| **Flare** (Fireglobe) | A globe lands within 40 px of a flame (it snaps on) | The lamp flares: 16 in 160 px (instead of 8 in 90), burning ground in 140 px for 3 s, and the lamp's light x1.5 for 3 s, so more foes are exposed. No shell wear (plan §4.5 unchanged). A lamp flares once per 6 s; on cooldown, the globe bursts as normal | `kl_flare_reach` 40, `kl_flare_dmg` 16, `kl_flare_radius` 160, `kl_flare_ground_radius` 140, `kl_flare_light_mult` 1.5, `kl_flare_time` 3, `kl_flare_lamp_cd` 6, `kl_shake_flare` 0.6 | The flame leaps; a wide warm ring; the light pulses out and settles back over 3 s; a small ember on the post shows the cooldown |
| **Chain** (Lance) | A Lance passes within 28 px of two flames up to 420 px apart, with no rock between | Fire arcs between the two lamps: 6 to every foe within 20 px of the line, with **full** shell wear, then the line burns 2 s at 2 dps. A third lamp in line chains on. The Lance flies on as normal | `kl_chain_reach` 28, `kl_chain_max_gap` 420, `kl_chain_dmg` 6, `kl_chain_width` 20, `kl_chain_burn_dps` 2, `kl_chain_burn_time` 2, `kl_shake_chain` 0.3 | A jagged warm arc from flame to flame; both flames flare; a burning seam on the ground |
| **Feed** (the Beam, only if kept) | The Beam touches a flame | While it touches: the lamp's light x1.3 and its core burns x2. The Beam goes on past the lamp | `kl_feed_light_mult` 1.3, `kl_feed_core_mult` 2 | The flame stretches toward you |
| **Ember** (the Ashbrood, phase 1) | A globe lands in the WayLamp's bowl | The ember flares: the Ashbrood is exposed for 4 s | `kl_ember_flare_radius` 120, `kl_ember_flare_time` 4, `kl_ember_flare_cd` 8 | Amber light spills out from under its wings |

**Arithmetic** (L1, before lit x1.3):
- **Lance down a two-lamp line:** 5 + 6 = 11 on one foe for 0.2 charge, or 55 per charge against the plan's 25 (plan §4.1). That is strong, but you have to set it up.
- **Flare:** 16 in 160 px for 0.3 charge, against 8 in 90.
- **Catch:** a single target takes 3 instead of 2. A pack can take 7 a bolt.
- *Uncertain:* combos may make packs trivial. The first knobs are `kl_flare_lamp_cd` and `kl_chain_dmg`. `test_combos` checks the sums.

**Not combos.** Hearth ring and Moth-lights don't combo in M1c. A tier-3 pick might add one in M2, for example Moth-lights' *Lamp-keepers* (plan §4.2).

---

## 4. Lantern types

| Type | Region find | Cost | Role | Effect in a fight | Loot lines (Bright and up; which slot) |
|---|---|---|---|---|---|
| **Post Lamp** | the Hollow (built) | 5 scrap | **Turret** | Light 224 px; its core burns small foes and nests (built). New: every 1.5 s it throws a small bolt at the nearest exposed foe in its light, 1.5 damage, half shell wear (`kl_post_shot_period`, `kl_post_shot_dmg`, new) | lens: "Your Post Lamps fire twice" (2 bolts a shot); lens: "Post Lamp bolts pierce 1"; burner: "Post Lamp bolts burst (30 px)" |
| **Reservoir Lamp** | the Reedmarsh (M5) | 8 scrap | **Well** | Wide dim light, 200 px, no core; brings water foes up (plan §6). New: in its light you refill charge at 0.25/s even while hunted (0.1 elsewhere; `kl_well_charge_hunted`, new) | burner: "Reservoirs also burn foes" (1 dps to foes in its light); wick: "Reservoirs refill a flask charge every 45 s you stand in them"; wick: "+25% Reservoir light" |
| **Hooded Lamp** | the Ridge (M6) | 7 scrap | **Ward** | Gusts can't snuff it; Gutterkites snag on it (plan §6). New: small foes can't enter its 120 px inner ring; elites slow to 60% inside it (`kl_ward_radius`, `kl_ward_slow`, new). Guardians ignore it | coat: "Your Hooded Lamps push foes back on entry (60 px)"; coat: "While in a Hooded Lamp's ward, you chill 30% less"; burner: "The ward ring burns 2 dps" |
| **Mirror Post** | the Lakeshore (M7) | 8 scrap | **Bouncer** | Its beam cuts fog, wears shells and exposes (built). New: your Lampfire and Lance that hit the mirror bounce along its beam with +50% range (`kl_bounce_range_mult`, new). Fire crossing a beam bursts at double radius (plan §4.4) | lens: "Bounced fire pierces 1 more"; lens: "Mirror beams are 50% longer"; wick: "A mirror catches light from 25% farther" |

**General lamp lines** (wick, any lamp): "+1 lamp slot" (Rare only, `kl_slot_line`); "+15% lamp light"; "Lamps flare again 2 s sooner" (`kl_flare_lamp_cd`). That makes **12 type lines and 3 general lines**, all new. They join the plan's 20 affixes (plan §10), and the same stacking rule holds: numbers add, never multiply, and no line repeats a branch pick.

*Uncertain:* 15 new lines is a lot of tuning (brief §6.2). The cut line is the second line of each type.

**Each type's base job is the region find** (plan §6, "the find is the key"). The turret is the Post Lamp's new job, and it lands in M3 (§8) so M1c stays small.

---

## 5. Lamp slots by level

This replaces the plan's flat "at most 3 lamps outside held ground" (`kl_lamp_limit`, never built; M1b left it out).

| Keeper level | 1-3 | 4-7 | 8-11 | 12 |
|---|---|---|---|---|
| Lamp slots (`kl_lamp_slots`, new: one value per level) | 2 | 3 | 4 | 5 |

- You can't plant at all until the crook's find (built). Level 2 comes at the crook.
- **Gear:** +1 from the Rare wick line, +1 from one relic (to be chosen in M3). At most 6 (`kl_lamp_slots_max`, new).
- **Free:** lamps in held regions (plan §6, kept) and lamps on claimed posts (§2.4).
- **Pick up and replant:** full refund (plan §6, kept). The replant delay drops from 15 s to **8 s** (`kl_lamp_replant_cd`), because lamps now matter mid-fight. *Uncertain:* 8 s may still be too long; the M1c playtest decides.
- **The HUD** shows slots as small lamp pips next to the lamp kind (like the flask pips). A refused plant says why: "All your lamps are lit." (DRAFT).
- Scrap still pays for each lamp. With M1b's one-off piles, scrap is finite in a region. *Uncertain:* whether 5 scrap a lamp is still right once lamps are weapons. Check it in `test_leveling`'s full-clear run.

---

## 6. Target lock

### 6.1 The recommendation

**R3 toggles a lock. A flick of the right stick switches targets. Holding the stick steers freely while the lock waits. The lock jumps to the next foe nearby when its target dies. Free aim stays the default.** On keyboard and mouse, holding a fire button with the cursor on a foe keeps firing at it ("sticky click").

**Why this one:**
- It keeps what already works. Free aim, the 12° assist and the aim hold are built and the owner likes the fire (DECISIONS, M1a playtest). A lock you choose adds to them. It doesn't replace them.
- It frees the right thumb (§6.6). That is the real gain for the §3 map. Diablo IV can put skills on Y and the face buttons because it targets for you (brief §1). Our twin-stick map couldn't, until now.
- Twin-stick aim is precise but tiring in long boss fights. A lock helps most there: the Clinker's rolls, the Ashbrood's dives.
- "Hold to steer" keeps combos possible while locked. To catch, flare or chain you aim at a lamp, not a foe.

**Rejected options:**
- **Always-on soft lock** (the game picks for you): it fights the combos, which need aiming past foes. It is kept as an option (§6.7).
- **A stronger aim assist only:** it doesn't free the thumb, so Y stays self-cast.
- **Lock on LT, held:** LT is the dash (approved).

### 6.2 Starting, switching and steering

| Action | Pad | What happens |
|---|---|---|
| **Lock** | R3 (`lock_on`, new; `JOY_BUTTON_RIGHT_STICK` is free today) | It picks the best foe within `kl_lock_range` 400 px in a 60° cone (`kl_lock_cone_deg`) around your aim: the stick if pushed, else your facing. The best is the smallest angle plus distance/400, and foes hunting you come first. If the cone is empty, it takes the nearest foe in range. If none, a soft "no target" tick |
| **Switch** | flick the right stick | A flick goes from below 0.3 to past 0.8 (`kl_lock_flick`) and back within 0.25 s (`kl_lock_flick_time`). The lock moves to the nearest foe within 60° of the flick's direction, measured from the current target. None there: the lock stays |
| **Steer** | hold the right stick for more than 0.25 s | You aim freely, with the built assist. The lock stays, drawn at half strength. Let go and the aim returns to the lock |
| **Unlock** | R3 again | It ends at once |

- **Nests aren't lockable.** Only cores hurt them, and `assisted()` already skips them.
- **Guardians are lockable.** The Soul's eyes become lock points in M8.
- **You can't lock a lamp.** The flare snap (40 px) does that job without a second kind of target.

### 6.3 The lock marker

**Drawn like a telegraph, coloured like the keeper's fire.** The brief asked for the cold telegraph style. This draft keeps the telegraph *drawing rules* and uses the keeper's warm colour. Here is why. Art §1.4 rule 1 says a keeper mark never glows blue. Art §4.2 says "a cold ring means get out and a warm ring means your fire lands here". A cold marker on your own target would read as a foe tell. This is owner question 4.

- **Shape:** four corner brackets around the foe's body (`body_radius()` + 6 px), 2 px, in `#ffd27a`. Each bracket arm is 6 px. Bracket shapes are used by no foe tell (art §4.2 uses lines, lanes, circles and glows), so the shape alone tells them apart.
- **Like a telegraph** (art §4.4 rules 2 and 6): the marker is drawn by the shared node on the fog layer (z 13), above fog and foes. It shows at full size from the first frame. It **never flashes**, so "reduce flashes" changes nothing.
- **Start:** the brackets snap in from +8 px over 0.1 s, with a soft tick (sound slot `lock_on`; the owner's job).
- **Its light state** (part 1): a short warm bar under the brackets while the target is lit, none while it is dark. You can see at a glance whether your shots are at full strength.
- **Steering:** half opacity. **About to break** (a grace timer running): the brackets open by 2 px. **Break:** they open and fade over 0.2 s.
- **Bars:** the locked foe's name bar always shows (built for hurt foes), with warm corner ticks. Locking the Ashbrood puts a small warm bracket on the boss bar.

### 6.4 When a lock breaks

| Cause | Rule (new values) |
|---|---|
| **Death** | The lock moves to the nearest foe within 160 px of the dead one (`kl_lock_chain_radius`), hunting foes first. None: it breaks. An option turns this off (§6.7) |
| **Range** | More than 480 px away (`kl_lock_break_range`) for 0.5 s, or off screen by more than 32 px |
| **Line of sight** | Rock (`FogGrid.is_solid_at`, sampled every 16 px, ten times a second) blocks the line for 0.75 s (`kl_lock_los_grace`) |
| **Fog** | You can't **start** a lock on a foe in fog above 0.8 (`kl_lock_fog_max`). A lock **holds** for 1.5 s (`kl_lock_fog_grace`) once its target's fog passes 0.8, then breaks. Your bolts light fog as they fly (built), so streaming at it usually keeps it seen |
| **Other** | R3; a menu opening; a faint; fast travel; the target fading in held ground (`fade_if_held()`) |

Being in the **dark** never breaks a lock. Foes in the dark still show their eyes (art §1.5), and fighting them in the dark is a real choice.

### 6.5 How each skill uses the lock

| Skill | With a lock (unlocked: as built) |
|---|---|
| **Lampfire** | Streams at the target, leading it by its speed x flight time, capped at 48 px (`kl_lock_lead_max`). The aim assist is off: the lock replaces it |
| **Fireglobe** | Lands on the target, leading it by half its 0.6 s flight. Clamped to 280 px (`kl_fireglobe_max`). The near limit drops from 120 to 60 px (`kl_lock_globe_min`). Stick tilt is ignored. If the landing is within 40 px of a flame, it snaps to the flame and flares |
| **Lance** | Fires at the target with the same lead, and pierces on through. A lamp on the line chains as normal |
| **The Beam** (if kept) | Turns toward the target at up to 180° a second (`kl_lock_beam_turn`), so it sweeps instead of snapping |
| **Hearth ring** | Self-cast; no change |
| **Moth-lights** (M5) | The motes seek the locked foe first |
| **Dash** | Still along your movement. The lock holds through it, so you can dash past a foe and keep firing at it |
| **Planting a lamp** | **No change:** X plants on your tile. Where you stand to fight is the choice. A lamp thrown toward the lock could be a relic or a branch pick later ("Crook's reach: plant up to 96 px toward your lock"); not planned |

### 6.6 What the free thumb changes: the §3 map

With a lock, the right thumb doesn't have to aim, so Y and B no longer cost you your aim. **Recommendation: Y may hold aimed skills.**

| Slot | Pad | Was (plan §3) | Proposed |
|---|---|---|---|
| 1 | RT | Lampfire, always | same |
| 2 | RB | aimed | same |
| 3 | LB | aimed | same |
| 4 | **Y** | **self-cast only** | **any skill.** An aimed skill on Y fires at the lock. With no lock, it fires at the best foe within 30° of your aim or facing (`kl_y_autotarget_deg`, new). With none there, it fires straight along the aim |
| Dash | LT | dash | same |
| Flask | B | flask, after the menu guard | same (and now safe mid-fight while locked) |
| **Lock** | **R3** | — (unbound) | **lock / unlock** (new) |

- **This is not the latch the plan rejected** (plan §3, "Y and aim"). A latch fires along a direction up to half a second old. Y here fires at a foe the game has picked and shows, so a miss can't feel like the game's fault.
- **Keyboard and mouse don't change.** The mouse aims all the time, so F and Q were never a problem.
- **The bar stays at four skills.** That keeps the small-bar choice (brief §1: Last Epoch caps you at five on purpose).
- **Lance on Y** (or Fireglobe) becomes a real option once Wheeling flame arrives at level 9 (plan §4.1). M1c lets you bind either one to Y so the owner can test it.

### 6.7 Keyboard and mouse

- **Sticky click (on by default).** Press left or right mouse with the cursor within 24 px of a foe's body. While the button is held, the fire follows that foe even if the cursor drifts. Release ends it. The marker shows while it lasts.
- **Full lock:** middle mouse (`lock_on`) toggles a lock as on the pad. With it on, the cursor steers, as "hold to steer" does on the pad.
- **Switch:** the mouse wheel moves to the next foe clockwise or anticlockwise around you.
- No change to F, Q or E.

### 6.8 Accessibility options (pause menu, saved in `user://settings.cfg`)

| Option | Values (default first) | Why |
|---|---|---|
| **Target lock** | Toggle (R3) · Auto · Off | *Auto:* the lock picks the nearest hunting foe whenever you have none, and a flick switches. This is for players who can't hold twin-stick aim for long |
| **Move to the next foe on a kill** | On · Off | Some players want each new target to be their own choice |
| **Lock button** | R3 · Y · L3 (dev builds use L3 for F1) · a back button | Clicking a stick is hard for some hands, and it is easy to do by accident while aiming hard |
| **Lock marker** | Normal · Large (brackets x1.5, 3 px) | Low vision |
| **Aim assist** | 12° · 20° · Off (`kl_aim_assist_deg`) | Already a tuning value; this shows it to players |
| **Auto-fire** (built) | Off · On | With a lock and auto-fire on, Lampfire streams at the lock while any skill button or the stick is down |

Every lock cue uses two of shape, colour and sound (art §1.6 rule 6): brackets, warm, and a tick.

### 6.9 With the built aim assist and aim hold (`combat.gd`)

- `update_aim()` gets one new branch after `aim_override`. With a lock and no steering, `aim` is the direction to the target's led position, and `_stick_aim` stays false.
- `assisted()` returns `dir` unchanged while locked (the lock is already exact). While steering, the 12° assist works as built.
- **The aim hold** (`kl_aim_hold`) does nothing while locked, because the lock already holds the aim. While steering, it works as built.
- `globe_target()` uses the led target position while locked, clamped as in §6.5, then pulls back off rock (built).
- **Auto-fire** (`kl_autofire_stick`) also fires at a lock when the option is on (§6.8).
- **Code shape** (a proposal): `systems/combat/lock_on.gd` (new) holds the target, the pick, the flick and the break timers. Combat asks it for an aim. The marker draws in the telegraph node's pass. `lock_on` is read after the menu guard, like every combat input (DESIGN §3.1).

---

## 7. What this would supersede

None of it is settled until the owner approves (question 6 covers parts 3 and 4).

| # | Now | Proposed | Here |
|---|---|---|---|
| 1 | Plan §6 and DECISIONS "the game plan approved" Q4: at most 3 lamps outside held ground (`kl_lamp_limit`), 15 s replant delay. M1b did not build the limit (DECISIONS, newest) | Lamp slots by level, 2 → 5, up to 6 with gear; free on claimed posts; replant 8 s | §5 |
| 2 | Plan §4.5 and DESIGN §4.5, the shell rule: wear by source only | Same sources, plus light: in the dark a shell stops at 1 and can't break; when lit it wears x1.5. Chain (Lance combo) wears in full | §2.1, §3 |
| 3 | Plan §3 and DESIGN §3.1 map: Y self-cast only; R3 unbound | Y takes any skill (fires at the lock, else auto-targets within 30°); R3 locks | §6.6 |
| 4 | Plan §3 "Y and aim" rejects a latch (review M4) | Still no latch. The lock is a shown target, not a remembered direction | §6.6 |
| 5 | Plan §4.6 time-to-kill targets, light-blind | They become the dim and lit targets; the dark is about 1.5x slower | §2.1 |
| 6 | Plan §8.4, DESIGN §8.1-8.2, DECISIONS "Hollow prototype playtest": elites, mid-bosses and guardians ignore light | They still ignore it for movement and cores, but light exposes them | §2.1 |
| 7 | Plan §6: the Ashbrood's dive snuffs a lamp for 8 s | It smothers the lamp during its 4 s sit (still lit, so you can punish it), then 8 s out. Its puff snuffs lamps in its circle for 4 s. It is hurt only when lit. A rim lamp and the ember flare are added | §2.1 |
| 8 | Plan §6 lamp jobs: haven and nest-burner (Post), water (Reservoir), gust-proof (Hooded), beam (Mirror) | Each keeps its job and adds turret, well, ward or bouncer | §4 |
| 9 | Plan §10: 16 general affixes and 4 skill changes | Plus 12 lamp-type lines and 3 general lamp lines; the slot rule also covers lamp jobs | §2.3, §4 |
| 10 | Plan §5: "light" for regen means any lamp or WayLamp light | Unchanged, plus claimed stubs and the Reservoir well (0.25/s while hunted). Dim is not light for regen | §2.1, §4 |
| 11 | Plan §1 pillar 2 and DESIGN §1: "Light is your shelter"; the plan removed "light is safety" | Light is your shelter **and your edge in a fight**. Light still isn't safety (foes still hurt you in it) | §1 |
| 12 | DECISIONS "new direction and font": tides kept for later | The tides become the Lakeshore and Still Lake's "the dark fights back" | §2.4 |
| 13 | DESIGN §7.1: unlit tiles fog back in | Except within 192 px of a claimed post | §2.4 |
| 14 | DECISIONS "M1a playtest; art; order of work": readability, then M1b, then M2 | Readability, M1b, **M1c**, then M2 | §8 |
| 15 | Art §1.5: "in fog you see only eyes and rim; in light, full colours" | The same look, now tied to the dark/dim/lit states (dark, not fog). One added cue: a warm rim-light on exposed foes | §2.1 |

---

## 8. Build plan

### M1c: Lamps in the fight (right after M1b; the Hollow only)

- **Scope:**
  1. **Light states** in `foe.gd` (dark, dim, lit; the linger), using `LightSense` and the hand lamp's radius. The damage multipliers, the dark shell floor and lit shell wear. The looks in §2.1 (silhouette, dimmed bar, floor notch, warm rim-light, cracks). The first-time tip. Nests are exempt.
  2. **Combos:** catch, flare (with the snap) and chain in `fire_bolts.gd`, checked against flames. Feed only if the Beam is kept by then.
  3. **The Ashbrood:** hurt only when lit; the rim lamp; the ember flare; smothering during the sit; the puff snuffing lamps. The boss bar hint.
  4. **Lamp slots** by level (no gear yet), the HUD pips and the refusal reason; replant 8 s.
  5. **Target lock** on pad and keyboard/mouse; the marker; the breaks; per-skill use; Y takes any skill; the §6.8 options.
  6. DRAFT texts in STORY (tip, hint, refusal, option names). No save change expected (*uncertain*: the rim lamp's lit state may need saving like the old lamps).
- **Not in M1c:** lamp types' new jobs (turret and the rest), loot lines, claim posts and tides.
- **Owner checks (pad only, one WayLamp lit, plus a save from before the Ashbrood):**
  1. In the dark, a shelled foe's shell stops at a sliver and you can see it. Step close (dim) or plant a lamp (lit), and it breaks.
  2. You can tell a dark foe from a lit one at a glance, without reading numbers.
  3. Lampfire through a lamp's flame splits; a Fireglobe near a lamp snaps on and flares; a Lance down two lamps chains.
  4. **Do the lamps feel useful now?** The owner marks each combo keep, rework or cut in PLAYTEST.md.
  5. The crook's guard can be beaten with no lamp (close in).
  6. The Ashbrood glances in the dark. It can be beaten with the rim lamp alone, and with a Fireglobe in the bowl. Hitting it while it smothers a lamp feels like the right window.
  7. A 3rd lamp at level 3 is refused with the reason; at level 4 it plants.
  8. R3 locks the foe you meant. A flick switches. Holding the stick steers and letting go returns to the lock. The lock moves on after a kill.
  9. With a lock: Lance on Y hits; B drinks without losing the target; Fireglobe lands on the target.
  10. The lock breaks behind rock, far away and in deep fog, and never leaks out of a menu.
  11. **Lock or free aim, which do you use?** Record it, plus the marker colour verdict.
- **Tests:**
  - `test_light_states` (new): the three states and their numbers; the linger; dim follows charge; nests and core burns exempt; the Ashbrood needs light.
  - `test_combos` (new): each trigger and its numbers; once per bolt; flare cooldown; chain gap and rock; the snap; the §3 sums.
  - `test_lock` (new): the cone pick; hunting first; flick and steer timing; each break; move on after a kill; lead; Fireglobe clamps; assist off while locked; sticky click; Auto mode.
  - Updated: `test_skills` (shell rule with light; time-to-kill sums), `test_waylamps` (the Ashbrood, the rim lamp, the ember), `test_input` (R3 and middle mouse after the menu guard; Y with an aimed skill), `test_telegraphs` (the lock marker above fog, never in a foe colour).
  - The bench: 40 projectiles and 6 lamps under the 4 ms budget.
- **Risks:**
  - **The dark feels like a chore** (Spitwicks, early packs). Knobs: `kl_dark_dmg_mult`, or small foes exempt.
  - **Combos trivialise packs.** Knobs: the flare cooldown and the chain damage.
  - **Lamp-dragging.** If 8 s replant lets players carry a lamp through every fight, go back toward 15 s.
  - **R3 clicks by accident** under heavy aiming. Fallback: the button option, or a 0.15 s hold.
  - **A lot in one milestone.** Cut order if it runs long: Feed, then Auto mode, then the puff snuff. The lock and part 1 never get cut.
  - **Look.** *Uncertain* whether foes on the fog layer can be drawn as silhouettes outside light without a shader. Check a capture first.

### Where parts 3 and 4 slot in

| Milestone | Adds |
|---|---|
| **M2** (builds) | Branch picks that touch lamps: Fireglobe *Beacon* counts as lit; dash *Ember rest* counts as lit. The elite affix *Lightless* can't be exposed by lamps, only by dim. No new lamp rules |
| **M3** (loot) | The Post Lamp turret. The 3 Post Lamp lines and the 3 general lamp lines, including "+1 lamp slot" and one slot relic. **Claim posts in the Hollow** (8), their reveals, and the post cache at 8/8 (it needs loot to exist). `test_loot` covers the lamp lines; a new `test_claims` |
| **M5** (the Reedmarsh) | The Reservoir well and its 3 lines; marsh posts; the Sump surfaces in Reservoir light (plan, kept), now also exposed |
| **M6** (the Ridge) | The Hooded Lamp ward and its 3 lines; Ridge posts; gusts snuff exposed lamps (plan, kept), which also turns their light off for part 1 |
| **M7** (the Lakeshore) | The Mirror Post bouncer and its 3 lines; shore posts; **the tides begin** |
| **M8** (the Still Lake) | Tides in the run-up to the finale; the Soul's eyes as lock points; its phase 3 snuff is the last "dark fights back" |

---

## 9. Owner questions

Each one says which milestone needs the answer. I recommend yes to each.

1. **[before M1c] Three light states?** Dark (x0.7, shells can't break), dim (the hand lamp, x1.0), lit (lamp light, x1.3, shells wear x1.5). Recommended because dim stops the crook's guard and early packs from being unkillable before you have a lamp, while lamps still clearly win.
2. **[before M1c] The Ashbrood only hurt in lamp light,** with the rim lamp, the ember flare (Fireglobe in the bowl), smothering during the sit, and the puff snuffing lamps? Recommended because it makes the guardian fight about where your light is, and the rim lamp means it can never soft-lock.
3. **[before M1c] Target lock as in §6:** R3 toggles, a flick switches, holding the stick steers, it moves on after a kill; sticky click and middle mouse on keyboard/mouse; free aim stays the default. Recommended because it adds to the aim you already enjoy, keeps combos aimable, and frees the right thumb.
4. **[before M1c] A warm lock marker, not cold?** The brief asked for the cold telegraph style. I recommend the telegraph's drawing rules in the keeper's amber, because art §1.4 and §4.2 make cold mean "a foe's attack". Corner brackets are a shape no tell uses either.
5. **[before M1c] Y may take aimed skills?** It fires at the lock, else at the best foe within 30° of your aim, else straight. Recommended because the lock removes the plan's reason for keeping Y self-cast (a remembered, stale aim), and it gives four aimed slots without a bigger bar.
6. **[before M3] Parts 3 and 4 as placed?** That covers: lamp slots by level (2 → 5, up to 6 with gear) replacing the 3-lamp limit, with an 8 s replant; the turret, well, ward and bouncer jobs and their 15 loot lines; claim posts as a reward rather than a gate; and tides from the Lakeshore on. Recommended because each region's lamp then changes how you fight, not only where you rest. Strike any part you don't want.

---

## Uncertainties

1. Every number is a starting value, and the time-to-kill sums are arithmetic, not measured. Combos and the lit multiplier could push guardians below 2 minutes; the dark could push packs over 12 s.
2. Whether foes can be drawn as silhouettes outside light cheaply (§8, M1c risks).
3. The Hollow's 8 old posts, the rim lamp's place and the post cache are not laid out or walked.
4. The flick timing (0.25 s) and the 0.8 threshold come from no measurement. They need the owner's pad.
5. Tides: the pacing is a guess.
6. This draft departs from the brief in one place: the marker colour (question 4).
