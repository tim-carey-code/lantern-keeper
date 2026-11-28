extends Node
## Autoload "Tuning": live placeholder numbers from DESIGN §3.
## The debug panel (F1 / gamepad Select) edits many of these while the game runs.

# Post Lamp. M1b (no more tending): lamps never burn, dim or need fuel; they shine at full radius while lit.
var lantern_max_radius := 224.0         # px
var post_lamp_cost_scrap := 5
var pickup_refund := 1.0                # share of build cost returned on pick-up (M1c: full, PLAN_LANTERNS §5)
var kl_snuff_sec := 8.0                 # s a lamp stays snuffed after the Ashbrood's dive; then it relights itself

# Hooded Lamp (unlocked at the glazier's workshop): a smaller light (its gust-proof job comes in M6)
var hooded_cost_scrap := 7              # was 5 scrap + 2 glass (M1b: glass is cut; GAME_PLAN §6)
var hooded_radius := 180.0

# Mirror Post (unlocked at the signal station): throws a beam when lit by another light
var mirror_cost_scrap := 8              # was 4 scrap + 3 glass (M1b: glass is cut; GAME_PLAN §6)
var mirror_beam_length := 352.0         # px (11 tiles)
var mirror_beam_width := 48.0           # px
var mirror_catch := 0.9                 # must stand within this share of a lantern's light radius
var mirror_glow_radius := 40.0

# The Windward Ridge's gusts (inert from M1b until M6: kl_wind_enabled)
var ridge_calm_min := 12.0              # gusts come much more often on the Ridge
var ridge_calm_max := 22.0

# Reservoir Lamp (unlocked at the pumphouse): a wide dim light (feeding other lamps is cut, M1b)
var reservoir_cost_scrap := 8
var reservoir_radius := 200.0

# Fog
var fog_creep_per_sec := 0.05           # how fast unlit tiles fog back in
var fog_clear_per_sec := 0.8            # how fast light pushes fog out
var fog_slow_min := 0.6                 # walk speed multiplier in full fog
var marsh_creep_mult := 1.8             # the Reedmarsh fogs back faster

# Wind gusts. M1b: inert until M6, when gusts come back on the Ridge only (GAME_PLAN §6). Off, no gust ever starts.
var kl_wind_enabled := false
var wind_calm_min := 30.0
var wind_calm_max := 55.0
var wind_warning_sec := 5.0
var wind_gust_sec := 10.0
var wind_creep_mult := 1.5

# Hand lamp (never goes out; its light follows its charge)
# Upgrades found in the valley: a keeper's satchel and a lamp glass in each region (placeholders)
var carry_base := 30                       # scrap carried before any satchel (satchels become bag slots in M3)
var carry_upgrade_step := 10               # each satchel: carry this many more
var lamp_upgrade_radius := 12.0            # each lamp glass: hand lamp light reaches this much further (px)
var lamp_upgrade_charge := 0.1             # ...and holds this much more charge (M1b, GAME_PLAN §5: max 1.0 + 0.1 a glass)
var hand_lamp_max_radius := 104.0
var hand_lamp_ember_radius := 44.0
var hand_lamp_recharge_per_sec := 0.5       # charge/s in lantern light out of a fight

# PROTOTYPE: Wicklings, the flare and warmth (branch proto/wicklings)
var wick_enabled := true
var wick_first_delay := 25.0        # grace period at the start (s): time to relight the first lantern (owner: 25 s)
var wick_spawn_sec := 12.0
var wick_max := 7
var wick_hp := 3.0
var wick_speed := 65.0              # keeper walks at 160
var wick_sense := 380.0             # px: how far they notice lanterns / the keeper
var wick_core := 0.55               # light level that burns them
var wick_light_burn := 2.0          # hp/s while in a lantern's bright core
var wick_beam_burn := 3.5           # hp/s inside a Mirror Post beam (3 hp -> under a second)
var ember_life := 30.0              # seconds before a scrap drop fades
var wick_scrap_chance := 0.35       # chance a burned Wickling also drops 1 scrap
var warmth_max := 100.0
var kl_warmth_regen := 20.0         # in lantern light when nothing hunts (GAME_PLAN §5)
# The faint rule (M1b, GAME_PLAN §12): nothing carried is lost; wick waits where you fell.
var kl_faint_warmth := 0.6          # share of max warmth you wake with
var kl_faint_skip_radius := 320.0   # px: a light this close to an unbeaten fight is skipped as a place to wake
var kl_lamp_low_charge := 0.05      # the hand lamp counts as "an ember" at or below this charge (HUD chip, tip)

# WayLamps: lit by touch (M1b); the Hollow's wakes the Ashbrood, the others are hold fights until M5-M6
var waylamp_kindle_sec := 15.0           # how long it must be kept clear of the dark
var waylamp_radius := 420.0
var waylamp_swarm := 4                   # bold Wicklings drawn to a kindling WayLamp
var waylamp_clear_radius := 160.0        # px: no building this close, so no lantern's bright core covers it
var waylamp_sap_per_wick := 1.5          # seconds of kindling undone per second, per Wickling on it
var travel_hunt_radius := 384.0          # px (12 tiles): a foe hunting the keeper this close blocks WayLamp fast travel

# Light repels Wicklings (M1b: nothing is drained)
var wick_repel_speed := 160.0            # px/s a Wickling is pushed out of healthy light

# Keeper's Light (PROTOTYPE): the keeper's light as a weapon. Lamp charge is the stamina.
var kl_min_charge := 0.05
var kl_beam_len := 240.0                 # px
var kl_beam_half_width := 12.0           # px
var kl_beam_dps := 7.5                   # was 6 (GAME_PLAN §4.1: 25 damage per charge, the same as Lance)
var kl_beam_cost := 0.3                  # lamp charge per second (a full lamp: about 3 s of beam)
var kl_beam_walk := 0.7                  # walk speed while beaming
# Hearth ring (M1a): the old burst, reworked. A ring of flame that sets foes alight, with a small push.
var kl_burst_radius := 120.0
var kl_burst_dmg := 2.0
var kl_burst_burn_dps := 1.0             # it sets what it hits alight (new)
var kl_burst_burn_time := 2.0            # s (new)
var kl_burst_knock := 60.0               # px thrown back (was 140)
var kl_burst_cd := 4.0                   # s (was 3)
var kl_burst_cost := 0.2
var kl_dash_dist := 110.0                # px
var kl_dash_time := 0.16                 # s
var kl_dash_cd := 0.9                    # s
var kl_dash_cost := 0.08
# Shelled elites: only a beam (yours or a mirror's) wears the shell down
var kl_elite_hp := 9.0
var kl_elite_shell := 4.0
var kl_elite_speed := 48.0
var kl_elite_chill_mult := 1.6           # its touch chills this much harder
var kl_elite_every := 4                  # every Nth Wickling that comes out of the fog is an elite
var kl_shell_regrow_wait := 3.0
var kl_shell_regrow_per_sec := 1.0
# Hollow enemies (prototype placeholders).
var kl_spitwick_hp := 4.0
var kl_spitwick_wick := 2              # wick: 4 hp and ranged (balance pass 2026-11-27: kept)
var kl_spit_keep_min := 190.0
var kl_spit_keep_max := 250.0
var kl_spit_keep_speed := 55.0
var kl_spit_retreat_speed := 70.0
var kl_spit_max_range := 500.0
var kl_spit_period := 2.5
var kl_spit_tell := 0.7                 # was 0.6 (readability: ART_DIRECTION §4.3 row 4)
var kl_spit_speed := 150.0
var kl_spit_warmth := 12.0
var kl_spit_charge := 0.1
var kl_spit_life := 3.5
var kl_spit_hit_radius := 12.0
var kl_clinker_hp := 48.0               # was 24: about 30 s against the M1a kit (GAME_PLAN §4.6; test_skills does the sums)
var kl_clinker_shell := 12.0
var kl_clinker_speed := 40.0
var kl_clinker_roll_speed := 280.0
var kl_clinker_roll_dist := 260.0
var kl_clinker_roll_tell := 0.9         # was 0.8 (readability: §4.3 row 8)
var kl_clinker_hit_warmth := 30.0      # was 25 (M1c damage fix): Lv 4 x1.24 = 37, the Hollow's hardest single hit
var kl_clinker_hit_range := 22.0
var kl_clinker_target_range := 330.0
var kl_clinker_wake_radius := 224.0     # px from its post: it sleeps until you come this close
var kl_clinker_leash := 480.0           # px from its post: past this it goes home
var kl_clinker_stop_range := 65.0
var kl_clinker_roll_cooldown := 3.5
var kl_clinker_wick := 28               # was 20 (M1b): Lv 4 x1.75 = 49, so a pure beeline goes into the Ashbrood at L4 (test_leveling)
var kl_nest_hp := 12.0
var kl_nest_core_dps := 2.0
var kl_nest_wick := 5                   # was 8: 12 nests made a third of the Hollow's wick (balance pass)
var kl_nest_wake_radius := 320.0
var kl_nest_hatch_count := 3
var kl_nest_hatch_sec := 10.0
var kl_nest_core_radius := 16.0
var kl_ashbrood_hp := 300.0             # phase 1 (M2: 3 phases; was 340 a phase for 2, M1c). Times in test_ashbrood_kill
var kl_ashbrood_hp2 := 300.0            # phase 2 (M2)
var kl_ashbrood_hp3 := 220.0            # phase 3, "last of the brood" (M2)
var kl_ashbrood_shell := 12.0
var kl_ashbrood_puff_period := 7.0
var kl_ashbrood_puff_tell := 1.0        # was 0.8 (readability: §4.3 row 9)
var kl_ashbrood_puff_radius := 140.0
var kl_ashbrood_puff_warmth := 15.0
var kl_ashbrood_wave_period := 8.0
var kl_ashbrood_dive_period := 1.5        # was 6 (M1c: "it just sits there"): s after a sit before the next dive
var kl_ashbrood_dive_tell := 1.0        # was 0.7 (readability: §4.3 row 11)
var kl_ashbrood_dive_warmth := 25.0
var kl_ashbrood_sit_sec := 4.0
var kl_ashbrood_wick := 32              # base (M1b: Lv 5, x2 = 64); was 50 flat, 40 before the balance pass. Its kill is the Hollow's last level
var kl_ashbrood_puff_charge := 0.1
var kl_ashbrood_wave_count := 3
var kl_ashbrood_dive_dist := 200.0
var kl_ashbrood_hit_radius := 48.0       # the dive's landing circle, lamp or no lamp (was 36 at a lamp: one value per hit, §4.4 rule 3)
var kl_focus_shell_mult := 1.3
var kl_long_throw_len := 310.0          # "Long throw": beam length (was hard-coded)
var kl_deep_tank_mult := 0.8            # "Deep tank": beam cost x (was hard-coded)
var kl_heavy_flare_knock_mult := 1.5    # "Heavy flare": burst throws this much farther (was hard-coded)
var kl_heavy_flare_stun := 0.6          # ...and stuns this long (s) (was hard-coded)
# Four more upgrades from PLAN §5.2 (balance pass: 12 in all, so every Hollow offer has three cards)
var kl_steady_hand_walk := 0.9          # "Steady hand": walk speed while beaming
var kl_lee_mult := 0.75                 # "Lee": a Wickling's touch chills this much
var kl_hot_core_mult := 2.0             # "Hot core": your lanterns' cores burn this much harder
var kl_spill_cd := 2.2                  # "Spill": burst cooldown (s)
var kl_spill_charge := 0.03             # ...and each thing the burst hits gives back this much charge
var kl_linger_duration := 2.0
var kl_linger_dps := 2.0
var kl_catch_damage := 2.0
# Wick and levels (DESIGN §9). Wick to go from level L to L+1 is round(kl_wick_base * L ^ kl_wick_exp).
# Level-gap pass (owner, 2026-11-27): every foe has a level, and its wick scales with it (DESIGN §9).
# M1b (GAME_PLAN §9): level 2 at the crook; the Hollow's last level on the Ashbrood kill: L5 on a beeline,
# L6 for an explorer (test_leveling).
# Foe scaling (M1b, GAME_PLAN §4.6): foes +12% health and shell a level over 1; the keeper +10% damage a level over 1.
var kl_foe_hp_per_level := 0.12
var kl_dmg_per_level := 0.1
var kl_wick_base := 7.0                 # was 6 (M1b, GAME_PLAN §9)
var kl_wick_exp := 1.65                 # was 1.25: 7, 22, 43, 69, 100, 135, 174, 216, 263, 313, 366
var kl_level_cap := 12                  # v1 cap (PLAN §5.1): never more level-ups than upgrades to pick
var kl_wick_kindle := 10                # kindling a WayLamp (was 30: the Hollow's last level now comes on the Ashbrood kill)
var kl_wickling_wick := 1               # 3 hp, half a second of beam
var kl_elite_wick := 3                  # was 1 (unset): 9 hp behind a 4-point shell, about 2 s of beam (PLAN §5.1 says 3)
# Wick by level gap (Diablo/PoE style; replaces the old "hatchlings pay 0, a pack member pays once" rules).
# A kill pays base wick * (1 + kl_xp_level_growth * (foe level - 1)) * the gap factor, gap = keeper level - foe level:
# gap <= band: full; above it x kl_xp_falloff per level; nothing at kl_xp_zero_gap or more. Foes above the keeper
# pay kl_xp_bonus more per level, up to kl_xp_bonus_max. Farming Lv 1 foes stalls at level 4 (test_leveling).
var kl_xp_band := 1                     # full wick up to this many levels above the foe
var kl_xp_falloff := 0.25               # each level past the band: x0.25 (gap 2: 1/4, gap 3: 1/16, gap 4: 1/64)
var kl_xp_zero_gap := 5                 # this many levels above the foe (or more): no wick
var kl_xp_bonus := 0.1                  # per level the foe is above the keeper
var kl_xp_bonus_max := 0.3
var kl_xp_level_growth := 0.25          # higher-level foes are worth more: +25% base wick per level over 1
var kl_clinker_level := 4
var kl_ashbrood_level := 5              # was 7 (M1b, GAME_PLAN §8.2: Hollow foes 1-4, the Ashbrood 5)
var kl_ashbrood_add_level := 4          # was 5: its phase-1 Wicklings, one below it (GAME_PLAN §16)
var kl_waylamp_swarm_level := 6         # Wicklings drawn to a kindling WayLamp (no guardian)
# Foe levels for packs and nests are in the HOLLOW_PACKS / HOLLOW_NESTS tables in scripts/main/main.gd.
var kl_wick_drop_radius := 28.0
var kl_pack_wake_radius := 320.0
# The first 10 minutes (onboarding, owner 2026-11-27, Option B): a small guard on the Post Lamp find.
# The route's first packs wake closer (the 6th column of HOLLOW_PACKS, in tiles), so nothing wakes at the hut.
var kl_post_guard_wake_radius := 128.0  # px (4 tiles): the shelled Wickling on Oswin's crook sleeps until you come this close
var kl_post_guard_level := 2            # its foe level: the first elite, one above the route's Wicklings

# M1a: fire in the Hollow (GAME_PLAN §4.1, §5, §15; owner-approved starting values).
# Lampfire, the basic attack (slot 1, held): a fireball of light that bursts on impact.
var kl_lampfire_dmg := 2.0               # on the foe it hits (half of it wears a shell)
var kl_lampfire_splash_dmg := 1.0        # to everything else within the splash (never a shell)
var kl_lampfire_splash := 40.0           # px
var kl_lampfire_period := 0.35           # s between bolts while held (5.7 dps)
var kl_lampfire_speed := 480.0           # px/s
var kl_lampfire_range := 320.0           # px
var kl_lampfire_charge := 0.03           # lamp charge back per hit
var kl_lampfire_hit_radius := 6.0        # px: the bolt's own size for hits
var kl_lampfire_pop := 72.0              # px: the light pop on impact, which clears fog
var kl_lampfire_pop_clear := 0.45        # fog density the pop clears at its centre
# Fireglobe (slot 2): the big lobbed fireball. Leaves burning ground.
var kl_fireglobe_dmg := 8.0
var kl_fireglobe_radius := 90.0
var kl_fireglobe_burn_dps := 2.0         # burning ground
var kl_fireglobe_burn_time := 3.0        # s
var kl_fireglobe_min := 120.0            # px: it lands this far out at least...
var kl_fireglobe_max := 280.0            # ...and at most (stick tilt or the cursor)
var kl_fireglobe_flight := 0.6           # s in the air, with a marker where it lands
var kl_fireglobe_arc := 46.0             # px at the top of the lob
var kl_fireglobe_cost := 0.3
var kl_fireglobe_cd := 5.0
var kl_fireglobe_pop_clear := 0.7        # fog density its burst clears
# Lance (slot 3 from level 2): a fast piercing bolt, the shell-breaker.
var kl_lance_dmg := 5.0
var kl_lance_pierce := 3                 # foes it hits on its way through
var kl_lance_speed := 700.0
var kl_lance_range := 360.0
var kl_lance_cost := 0.2
var kl_lance_cd := 0.5
var kl_lance_hit_radius := 5.0
var kl_lance_level := 2                  # the level that brings it (it takes LB, with a toast)
var kl_bolt_light := 40.0                # px: your fire lights the fog around it while it flies
# Aim (pad): a gentle pull toward a foe for Lampfire and Lance, and the aim hold.
var kl_aim_assist_deg := 12.0
var kl_aim_hold := true                  # while slot 1, 2 or 3 is held, a released right stick keeps its last aim
var kl_autofire_stick := 0.8             # the auto-fire option: Lampfire fires while the right stick is past this
# Light and regen (GAME_PLAN §5): out of a fight light refills fast; while hunted only slowly.
var kl_charge_regen := 0.06              # lamp charge/s anywhere (the Beam doesn't stop it)
var kl_light_charge_hunted := 0.1        # lamp charge/s in light while hunted (out of a fight: hand_lamp_recharge_per_sec)
# Lamp-oil flasks (B / R).
var kl_flask_max := 3
var kl_flask_heal := 0.4                 # share of max warmth
var kl_flask_charge := 0.4
var kl_flask_lockout := 1.0              # s before you can drink again
var kl_elite_oil_chance := 0.3           # an elite drops oil this often; a cleared pack's last foe always drops 1
var kl_boss_oil_step := 0.5              # mid-boss and guardian: 1 oil when health falls past this share (each phase)
# Juice (GAME_PLAN §15, brief §4).
var kl_hitstop := 0.06                   # s: a big hit freezes the keeper and its target only (40-80 ms)
var kl_hitstop_big := 5.0                # damage that counts as a big hit (Lance, Fireglobe); kills always do
var kl_trauma_decay := 1.8               # screen-shake trauma lost per second
var kl_shake_lance_hit := 0.2            # screen-shake trauma (0..1) when a Lance hits
var kl_shake_lance_cast := 0.12          # ... throwing a Lance (a little recoil)
var kl_shake_globe := 0.55               # ... a Fireglobe landing
var kl_shake_ring := 0.4                 # ... Hearth ring
var kl_shake_kill := 0.15                # ... a kill
var kl_shake_kill_big := 0.35            # ... killing an elite, a shelled foe or a boss
var kl_oil_pull := 220.0                 # px/s: a lamp-oil drop slides to the keeper inside its pull radius
var kl_pickup_hold := 0.8                # s: hold interact (A / E) by a lantern this long to pick it up
var kl_stick_aim_min := 0.3              # pad: the right stick aims once pushed past this
var kl_stick_tilt_full := 0.9            # pad: pushed this far counts as full tilt (the Fireglobe's farthest landing)

# Feedback (PROTOTYPE)
var kl_shake_px := 16.0                  # px of shake at full trauma (offset = this x trauma squared; was 6 x linear)
var kl_kindled_kill_charge := 0.1        # "Kindled kills": lamp charge back per kill

# Lanterns and the dark (PROTOTYPE, owner 2026-11-27)
var kl_timid_share := 0.5                # share of Wicklings that won't enter healthy light
var kl_light_tolerance := 2.5            # s a brave Wickling can stand in light before it burns
var kl_light_burn_dps := 1.5             # hp/s it then takes (and it runs)

# Readability step (ART_DIRECTION §4, DRAFT): the shared telegraph system (systems/telegraph/telegraph.gd).
# Every foe attack goes notice -> wind-up -> commit -> strike -> recover. Markers are cold (#a3bcd4), above the fog.
var kl_tell_min := 0.5                   # s: the shortest warning any discrete hit gets (fairness rule 1)
var kl_tell_commit := 0.15               # s: the last part of a wind-up flashes (solid with "reduce flashes"); aim is locked
var kl_tell_commit_boss := 0.2           # s: the same for the Clinker and the Ashbrood
var kl_notice_time := 0.3                # s: eyes flare when a foe starts hunting you
var kl_tell_gap := 0.3                   # s: two warnings near the keeper never land closer together than this (rule 9)
var kl_tell_budget_radius := 240.0       # px: "near the keeper" for that rule
var kl_tell_arrow_range := 900.0         # px: an off-screen wind-up this close to the keeper gets an edge arrow
var kl_wick_latch_tell := 0.25           # s: a Wickling reaches for you before its touch starts to drain
var kl_elite_latch_tell := 0.35          # s: the same for a Shelled Wickling
var kl_spit_aim_lock := 0.2              # s: the Spitwick's aim locks for the end of its wind-up
var kl_spit_onscreen_margin := 16.0      # px: a Spitwick starts a wind-up only this far inside the screen
var kl_nest_hatch_tell := 1.0            # s: a nest's ring fills, and glows show where the hatchlings come (was a code constant)
var kl_hatch_fade := 0.3                 # s: hatched and called Wicklings fade in, harmless, for this long
var kl_clinker_wake_time := 0.6          # s: the Clinker uncurls when it wakes, and can't roll until it is done
var kl_clinker_recover := 0.6            # s: dizzy after a roll (it can't move or roll: hit it now)
var kl_ashbrood_add_tell := 0.8          # s: cold glows where its adds will rise, before they come
var kl_ashbrood_dive_travel := 0.3       # s: its dive is a visible flight, not a jump
var kl_ashbrood_phase_pause := 1.5       # s: it rises out of the bowl; it can't attack or be hurt meanwhile
# The keeper's own feedback (code-drawn until the owner draws poses).
var kl_fx_dash_ghosts := 3               # afterimages a dash leaves
var kl_fx_ghost_life := 0.22             # s: how long an afterimage lasts
var kl_fx_cast_time := 0.14              # s: the lamp-thrust cue on a cast (Lampfire, Fireglobe, Lance)
var kl_fx_drink_time := 0.6              # s: the warm glow rising up the keeper after a flask
var kl_fx_hurt_time := 0.25              # s: the cold flash when something chills the keeper

var kl_ambient_spawns := false           # the old endless trickle of Wicklings out of the fog (off: ARPG packs instead)

# --- M1c: lamps in the fight (docs/replan/PLAN_LANTERNS.md; owner-approved 2026-11-27, starting values) ---
# The damage fix (owner, M1b playtest: "the Wicklings fried me", "I was tanking hit after hit from the Clinker").
# A touching Wickling chills in ticks, and all Wicklings together take at most kl_swarm_chill_cap a second:
# 3 Wicklings and no dodging take a full keeper down in about 3.6 s (was 1.1 s at 30/s each, stacking).
var kl_wick_chill_hit := 5.0             # warmth per touch tick (an elite: x kl_elite_chill_mult)
var kl_wick_chill_tick := 0.5            # s between one Wickling's ticks
var kl_swarm_chill_cap := 28.0           # warmth/s: the most every touching Wickling together can take
var kl_swarm_chill_burst := 0.5          # s of the cap that can land at once (the swarm's budget refills at the cap)
var kl_foe_dmg_per_level := 0.08         # foe damage +8% a level over 1 (hits, spit, touch, the guardians)
var kl_clinker_knock := 120.0            # px the Clinker's roll throws the keeper, out of its lane
var kl_hurt_shake_min := 10.0            # a chill this big or more is a hit: shake and the cold flash
# Light states (§2.1): dark (outside every light), dim (only the hand lamp), lit (a lamp's light).
var kl_dark_dmg_mult := 0.7              # damage a foe in the dark takes
var kl_lit_dmg_mult := 1.3               # ...and a lit (exposed) one
var kl_lit_shell_mult := 1.5             # a lit foe's shell wears this much faster
var kl_dark_shell_floor := 1.0           # in the dark a shell wears down to this and no further (it can't break)
var kl_exposed_linger := 0.5             # s a foe stays exposed after it leaves light
var kl_ashbrood_needs_light := true      # the Ashbrood is hurt only when lit (dim counts as dark for it)
# Combos (§3): at a lamp's flame (a planted lamp or a lit old lamp; WayLamps don't).
var kl_catch_reach := 28.0               # px: a Lampfire bolt this close to a flame catches
var kl_catch_dmg_add := 1.0              # ...and hits this much harder
var kl_catch_split := 2                  # side bolts it throws
var kl_catch_spread_deg := 18.0
var kl_catch_split_dmg := 2.0
var kl_catch_split_range := 240.0
var kl_flare_reach := 40.0               # px: a Fireglobe landing this close to a flame snaps onto it and flares it
var kl_flare_dmg := 16.0
var kl_flare_radius := 160.0
var kl_flare_ground_radius := 140.0
var kl_flare_light_mult := 1.5           # the lamp's light while it flares
var kl_flare_time := 3.0
var kl_flare_lamp_cd := 6.0              # s before a lamp can flare again
var kl_shake_flare := 0.6
var kl_chain_reach := 28.0               # px: a Lance this close to two flames chains them
var kl_chain_max_gap := 420.0
var kl_chain_dmg := 6.0
var kl_chain_width := 20.0
var kl_chain_burn_dps := 2.0
var kl_chain_burn_time := 2.0
var kl_shake_chain := 0.3
var kl_feed_light_mult := 1.3            # the Beam touching a flame (the Beam is still an optional skill)
var kl_feed_core_mult := 2.0
# Lamp slots by level (§5; owner 2026-11-28: build them now). 2 at the start, +1 at each level below, up to 5.
var kl_lamp_slots_base := 2
var kl_lamp_slot_level_a := 4            # the 3rd slot
var kl_lamp_slot_level_b := 8            # the 4th
var kl_lamp_slot_level_c := 12           # the 5th
var kl_lamp_slots_max := 6               # with gear (M3); no gear adds slots yet
var kl_lamp_replant_cd := 8.0            # s after picking a lamp up before you can plant again
# The Ashbrood (§2.1, §8 item 3; owner playtest: "it just sits there").
var kl_ashbrood_puff_snuff := 4.0        # s its ash puff snuffs every planted lamp inside the circle
var kl_ember_flare_radius := 120.0       # a Fireglobe in the bowl stirs the ember: it lights this far
var kl_ember_flare_time := 4.0
var kl_ember_flare_cd := 8.0
var kl_rim_lamp_dist := 180.0            # px from the WayLamp: the old lamp on the bowl's rim
var kl_ashbrood_bolt_period := 2.2       # s between its ash bolts in the bowl (phase 1)
var kl_ashbrood_bolt_tell := 0.7
var kl_ashbrood_bolt_count := 3          # bolts in a fan
var kl_ashbrood_bolt_spread_deg := 16.0
var kl_ashbrood_bolt_speed := 230.0
var kl_ashbrood_bolt_warmth := 10.0
var kl_ashbrood_bolt_range := 420.0
var kl_ashbrood_sweep_tell := 0.8        # its wing sweep (phase 1) when you stand close
var kl_ashbrood_sweep_radius := 96.0
var kl_ashbrood_sweep_warmth := 16.0
var kl_ashbrood_sweep_knock := 90.0
var kl_ashbrood_sweep_cd := 4.0
var kl_ashbrood_dark_sit := 1.0          # s it sits after a dive that found no lit lamp (then ash bolts)
var kl_ashbrood_idle_max := 2.0          # s: it never waits longer than this between attacks
var kl_ashbrood_trail_period := 1.0      # phase 2: ash it drops along a dive's flight lingers as small puffs
# M2 (owner M1c playtest: "phase 2 is still a bit boring and there definitely needs to be more moves"): phase 2's new
# moves and phase 3, "last of the brood". Every number DRAFT, in the tuning panel.
var kl_ashbrood_wave_tell := 1.1         # the ash wave: a lane from it through you...
var kl_ashbrood_ash_wave_len := 460.0
var kl_ashbrood_ash_wave_half := 30.0    # ...60 px wide (fairness: lanes no wider than 64)
var kl_ashbrood_ash_wave_warmth := 14.0
var kl_ashbrood_ash_wave_knock := 70.0
var kl_ashbrood_ash_wave_travel := 0.35  # s the wave front takes to run the lane (the look; the hit is the lane)
var kl_ashbrood_strafe_tell := 1.0       # the low pass: a lane past you...
var kl_ashbrood_strafe_len := 380.0
var kl_ashbrood_strafe_half := 28.0
var kl_ashbrood_strafe_warmth := 16.0
var kl_ashbrood_strafe_travel := 0.45    # ...flown in this long...
var kl_ashbrood_strafe_embers := 4       # ...leaving this many cold embers on its path
var kl_cold_ember_radius := 26.0
var kl_cold_ember_life := 4.0
var kl_cold_ember_warm := 0.5            # s a cold ember glows before it chills (it can't hurt you yet)
var kl_cold_ember_chill := 4.0           # warmth every kl_wick_chill_tick while you stand in one
var kl_ashbrood_recover := 0.6           # s it hangs after a wave or a pass (the window, if it is lit)
var kl_ashbrood_call_period := 16.0      # phase 2: it calls Wicklings from the dark this often...
var kl_ashbrood_call_count := 2
var kl_ashbrood_call_dist := 300.0       # ...this far from the bowl, between you and the dark
var kl_ashbrood_p3_mult := 0.8           # phase 3: wind-ups and waits x this (never under kl_tell_min)
var kl_ashbrood_brood_sit := 2.5         # phase 3: it settles over the last ember this long (the ember lights it)
var kl_ashbrood_p3_sit := 2.4            # phase 3: a sit on a lamp is shorter, and a wave follows it
var kl_ashbrood_combo_gap := 0.35        # phase 3: s between the parts of a combo
# Target lock (§6).
var kl_lock_range := 400.0
var kl_lock_cone_deg := 60.0
var kl_lock_flick := 0.8
var kl_lock_flick_time := 0.25
var kl_lock_steer_time := 0.25
var kl_lock_chain_radius := 160.0
var kl_lock_break_range := 480.0
var kl_lock_break_time := 0.5
var kl_lock_los_grace := 0.75
var kl_lock_fog_max := 0.8
var kl_lock_fog_grace := 1.5
var kl_lock_lead_max := 48.0
var kl_lock_globe_min := 60.0
var kl_lock_beam_turn := 180.0           # degrees a second
var kl_y_autotarget_deg := 30.0
var kl_sticky_click_radius := 24.0
# M2 "Builds" (GAME_PLAN §4.2, §9): skill points, tiers, respec. Pick numbers (DRAFT, the owner tunes them here).
var kl_points_per_level := 1             # skill points a level-up gives
var kl_tier2_level := 4                  # tier 2 opens at this level (tier 1 with the skill; tier 3 on the Ashbrood kill)
var kl_respec_radius := 220.0            # px: after resting at a lit WayLamp, picks change freely this close to it
var kl_catch_min_travel := 72.0          # px a Lampfire bolt must fly before it can catch (owner M1c: standing at your own lamp was too strong)
# Lampfire picks.
var kl_pick_burn_dps := 2.0              # Lingering burn: hit foes burn this much a second...
var kl_pick_burn_time := 2.0             # ...for this long (and Catching's kill sets the next one alight the same)
var kl_scatter_count := 3                # Scatter: sparks a burst throws
var kl_scatter_dmg := 1.0
var kl_scatter_range := 110.0             # (was 70, backward; M2 review: the sparks fly on through the pack)
var kl_scatter_spread_deg := 40.0        # ...in a fan this wide each side of the bolt's way
var kl_twin_spread_deg := 8.0            # Twin: each bolt this far off the aim
var kl_twin_mult := 0.65                 # ...at this much of a bolt's damage
var kl_skip_range := 140.0               # Skip: it jumps to a foe this close
var kl_skip_mult := 0.75
var kl_catching_radius := 60.0
var kl_comet_every := 4                  # Comet: every Nth bolt is big
var kl_comet_mult := 2.0                 # ...this much damage and splash
# Fireglobe picks.
var kl_skip_globe_dist := 100.0          # Skipping globe: it hops on this far
var kl_skip_globe_mult := 0.7            # ...and bursts again at this much
var kl_skip_globe_flight := 0.35
var kl_slick_slow := 0.4                 # Slick: foes in its burning ground move this much slower (not bosses)
var kl_second_globe_delay := 0.3         # Second globe: a smaller one this long after
var kl_second_globe_mult := 0.6          # ...damage and radius x
var kl_fire_line_count := 3              # Fire line: bursts across the aim
var kl_fire_line_gap := 64.0
var kl_fire_line_mult := 0.6
var kl_fire_line_radius := 55.0
var kl_cluster_count := 4                # Cluster: small globes it bursts into
var kl_cluster_dist := 70.0
var kl_cluster_dmg := 3.0
var kl_cluster_radius := 45.0
var kl_beacon_time := 6.0                # Beacon: it stays lit this long (counts as lit)
var kl_beacon_radius := 110.0
var kl_undertow_reach := 1.7             # Undertow: pulls foes within this x its radius...
var kl_undertow_pull := 50.0             # ...this far in
# Lance picks.
var kl_burning_line_time := 2.0          # Burning line: fire along its path
var kl_burning_line_dps := 2.0
var kl_brand_mult := 1.5                 # Brand: the next hit on the branded foe
var kl_fork_spread_deg := 25.0           # Forked: two lances this far off at the first hit
var kl_fork_mult := 0.6
var kl_fork_range := 200.0
var kl_breaking_count := 3               # Breaking: Lampfire bolts at its end
var kl_breaking_spread_deg := 20.0
var kl_held_lance_time := 0.6            # Held lance: hold this long...
var kl_held_lance_mult := 2.0            # ...for this much damage, through everything
var kl_shatter_dmg := 4.0                # Shatter: a shell it breaks bursts for this...
var kl_shatter_radius := 60.0            # ...this far around
# Dash picks.
var kl_cinder_dps := 2.0                 # Cinder trail: burning ground along the dash
var kl_cinder_time := 2.0
var kl_cinder_radius := 26.0
var kl_phase_stun := 0.4                 # Phase: foes you dash through
var kl_phase_width := 22.0
var kl_flame_step_dmg := 2.0             # Flame step: a fire ring where the dash ends
var kl_flame_step_radius := 70.0
var kl_ember_rest_time := 3.0            # Ember rest: an ember that counts as lit
var kl_ember_rest_radius := 90.0
var kl_blink_dist := 150.0               # Blink: an instant step this far
var kl_recoil_count := 3                 # Recoil: bolts a backward dash throws forward
var kl_recoil_spread_deg := 12.0
var kl_recoil_dot := -0.3                # a dash counts as backward when it points this far against the aim
# Beam picks.
var kl_prism_spread_deg := 12.0          # Prism: two more beams this far off
var kl_prism_mult := 0.5                 # ...each beam at this much
var kl_searing_max := 0.5                # Searing: up to +50%...
var kl_searing_ramp := 1.5               # ...over this long on one foe
var kl_stoking_cut := 1.0                # Stoking: s off Fireglobe's cooldown per s on a foe
# Hearth ring picks.
var kl_heavy_ring_push := 140.0          # Heavy ring: push (was 60) and kl_heavy_flare_stun
var kl_lasting_ring_time := 3.0          # Lasting ring: its ground burns this long
var kl_lasting_ring_dps := 1.5
var kl_warm_ring_warmth := 2.0           # Warm ring: warmth back per foe hit
var kl_sunburst_count := 8               # Sunburst: Lampfire bolts all around
var kl_crackle_shell := 2.0              # Crackle: shell stripped from every foe hit
var kl_rising_ring_radius := 220.0       # Rising ring: a second ring rolls out this far...
var kl_rising_ring_time := 1.0           # ...over this long
var kl_rising_ring_dmg := 2.0
# Elite affixes (GAME_PLAN §8.1; M2): one on an elite from a level-4 pack in the Hollow (2 from the marsh on).
var kl_affix_min_level := 4
var kl_affix_swift := 1.3                # Swift: speed x
var kl_affix_biting := 1.5               # Biting cold: chill x
var kl_affix_bursting := 2               # Bursting: Wicklings when it dies...
var kl_affix_burst_tell := 0.6           # ...after a spawn glow this long
var kl_affix_thick := 2.0                # Thick shell: shell x
var kl_lightless_snuff := 4.0            # Lightless: lamps it passes are snuffed this long...
var kl_lightless_reach := 40.0           # ...when it comes this close
var kl_lightless_tell := 0.5             # ...after flickering cold this long

var ui_open := false                    # true while a menu has focus (player stops)
