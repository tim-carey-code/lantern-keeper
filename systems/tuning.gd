extends Node
## Autoload "Tuning": live placeholder numbers from DESIGN §3.
## The debug panel (F1 / gamepad Select) edits many of these while the game runs.

# Post Lamp. M1b (no more tending): lamps never burn, dim or need fuel; they shine at full radius while lit.
var lantern_max_radius := 224.0         # px
var post_lamp_cost_scrap := 5
var pickup_refund := 0.5                # share of build cost returned on pick-up (as built; owner redesigning lanterns)
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
var warmth_drain_per_sec := 30.0    # while a Wickling touches the keeper
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
var kl_clinker_hit_warmth := 25.0
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
var kl_ashbrood_hp := 220.0             # per phase; 2 phases in M1a, hand-set to the 2-minute target (GAME_PLAN §4.6)
var kl_ashbrood_shell := 12.0
var kl_ashbrood_puff_period := 7.0
var kl_ashbrood_puff_tell := 1.0        # was 0.8 (readability: §4.3 row 9)
var kl_ashbrood_puff_radius := 140.0
var kl_ashbrood_puff_warmth := 15.0
var kl_ashbrood_wave_period := 8.0
var kl_ashbrood_dive_period := 6.0
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

var ui_open := false                    # true while a menu has focus (player stops)
