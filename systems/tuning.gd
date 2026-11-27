extends Node
## Autoload "Tuning": live placeholder numbers from DESIGN §3.
## The debug panel (F1 / gamepad Select) edits many of these while the game runs.

# Post Lamp
var lantern_max_fuel := 100.0
var lantern_burn_per_sec := 0.5         # 100 fuel lasts ~3.3 minutes (was 5; owner: "a little too slow")
var lantern_max_radius := 224.0         # px at full tank
var lantern_min_radius_frac := 0.4      # radius just before it goes cold
var post_lamp_cost_scrap := 5
var pickup_refund := 0.5                # share of build cost returned on pick-up

# Hooded Lamp (unlocked at the glazier's workshop): wind-proof, smaller light
var hooded_cost_scrap := 5
var hooded_cost_glass := 2
var hooded_radius := 180.0

# Mirror Post (unlocked at the signal station): no fuel, throws a beam when lit by another light
var mirror_cost_scrap := 4
var mirror_cost_glass := 3
var mirror_beam_length := 352.0         # px (11 tiles)
var mirror_beam_width := 48.0           # px
var mirror_catch := 0.9                 # must stand within this share of a lantern's light radius
var mirror_glow_radius := 40.0

# The Windward Ridge: constant west wind on top of the gusts
var ridge_burn_mult := 1.6              # exposed lanterns on the Ridge
var ridge_radius_mult := 0.85
var ridge_calm_min := 12.0              # gusts come much more often on the Ridge
var ridge_calm_max := 22.0

# Reservoir Lamp (unlocked at the pumphouse)
var reservoir_cost_scrap := 8
var reservoir_max_fuel := 200.0
var reservoir_burn_per_sec := 0.3
var reservoir_radius := 200.0
var reservoir_min_radius_frac := 0.6
var reservoir_feed_per_sec := 0.75      # fuel/s to each other lantern in its light; must beat the Post Lamp burn (0.5)

# Resources
var fuel_per_unit := 10.0               # lantern fuel per carried fuel unit
var gather_interval := 0.25             # s of holding per unit gathered

# Fog
var fog_creep_per_sec := 0.05           # how fast unlit tiles fog back in
var fog_clear_per_sec := 0.8            # how fast light pushes fog out
var fog_slow_min := 0.6                 # walk speed multiplier in full fog
var marsh_creep_mult := 1.8             # the Reedmarsh fogs back faster

# Wind gusts (the only weather in v1)
var wind_calm_min := 30.0
var wind_calm_max := 55.0
var wind_warning_sec := 5.0
var wind_gust_sec := 10.0
var wind_burn_mult := 3.0               # exposed lanterns during a gust (was 2; owner: gusts too weak)
var wind_radius_mult := 0.7
var wind_creep_mult := 1.5

# Hand lamp (dims in the dark, never goes out)
# Upgrades found in the valley: a keeper's satchel and a lamp glass in each region (placeholders)
var carry_base := 30                       # carried of each resource before any satchel
var carry_upgrade_step := 10               # each satchel: carry this many more of everything
var lamp_upgrade_radius := 12.0            # each lamp glass: hand lamp light reaches this much further (px)
var lamp_upgrade_dim_mult := 0.75          # ...and dims this much slower in the dark (x per glass)
var lamp_upgrade_ward_mult := 0.85         # ...and the ward costs this much charge (x per glass)
var hand_lamp_max_radius := 104.0
var hand_lamp_ember_radius := 44.0
var hand_lamp_drain_per_sec := 1.0 / 45.0   # full -> ember in 45 s of darkness
var hand_lamp_recharge_per_sec := 0.5       # free top-up while in lantern light
var hand_lamp_charge_per_fuel := 0.5        # auto-burns 1 carried fuel when low

# PROTOTYPE: Wicklings, the flare and warmth (branch proto/wicklings)
var wick_enabled := true
var wick_first_delay := 25.0        # grace period at the start (s): time to relight the first lantern (owner: 25 s)
var wick_spawn_sec := 12.0
var wick_max := 7
var wick_hp := 3.0
var wick_speed := 65.0              # keeper walks at 160
var wick_sense := 380.0             # px: how far they notice lanterns / the keeper
var wick_rim := 0.12                # light level where they stop and drain (rim of the light)
var wick_core := 0.55               # light level that burns them
var wick_light_burn := 2.0          # hp/s while in a lantern's bright core
var wick_beam_burn := 3.5           # hp/s inside a Mirror Post beam (3 hp -> under a second)
var wick_drain_per_sec := 5.0       # lantern fuel/s drained (100-fuel tank: ~20 s)
# Warding glow (hold F / RB / RT): the hand lamp swells into a bright circle that burns
# and pushes back Wicklings. Powered by the hand lamp's charge, never by carried fuel.
var ward_radius := 110.0            # px
var ward_dps := 4.5                 # Wickling hp per second (3 hp -> about 0.7 s)
var ward_push := 140.0              # px/s pushed outward
var ward_drain_per_sec := 0.45      # lamp charge per second: a full lamp gives about 2 s of ward (was 0.25; owner: combat too easy)
var ward_walk_mult := 0.6           # you move slower while warding
var ward_min_charge := 0.05         # below this the lamp is too dim to ward
var ember_fuel := 1                 # a burned Wickling leaves an ember worth this much fuel
var ember_life := 30.0              # seconds before an ember fades
var wick_scrap_chance := 0.35       # chance a burned Wickling also drops 1 scrap
var warmth_max := 100.0
var warmth_drain_per_sec := 30.0    # while a Wickling touches the keeper
var warmth_regen_per_sec := 20.0    # in lantern light
var faint_drop := 0.5               # share of carried resources dropped on fainting

# WayLamps (PROTOTYPE): kindle one and its whole region is held
var waylamp_fuel_need := 15              # carried fuel to feed it
var waylamp_kindle_sec := 15.0           # how long it must be kept clear of the dark
var waylamp_radius := 420.0
var waylamp_swarm := 4                   # bold Wicklings drawn to a kindling WayLamp
var waylamp_clear_radius := 160.0        # px: no building this close, so no lantern's bright core covers it
var waylamp_sap_per_wick := 1.5          # seconds of kindling undone per second, per Wickling on it

# Light repels Wicklings; only a dying lantern can be drained (PROTOTYPE)
var dying_frac := 0.25                   # under this share of its tank a lantern is "dying"
var wick_repel_speed := 160.0            # px/s a Wickling is pushed out of healthy light

# Keeper's Light (PROTOTYPE): the keeper's light as a weapon. Lamp charge is the stamina.
var kl_min_charge := 0.05
var kl_beam_len := 240.0                 # px
var kl_beam_half_width := 12.0           # px
var kl_beam_dps := 6.0                   # a Wickling (3 hp) in half a second
var kl_beam_cost := 0.3                  # lamp charge per second (a full lamp: about 3 s of beam)
var kl_beam_walk := 0.7                  # walk speed while beaming
var kl_burst_radius := 120.0
var kl_burst_dmg := 2.0
var kl_burst_knock := 140.0              # px thrown back
var kl_burst_cd := 3.0                   # s
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
var kl_spit_tell := 0.6
var kl_spit_speed := 150.0
var kl_spit_warmth := 12.0
var kl_spit_charge := 0.1
var kl_spit_life := 3.5
var kl_spit_hit_radius := 12.0
var kl_clinker_hp := 24.0
var kl_clinker_shell := 12.0
var kl_clinker_speed := 40.0
var kl_clinker_roll_speed := 280.0
var kl_clinker_roll_dist := 260.0
var kl_clinker_roll_tell := 0.8
var kl_clinker_hit_warmth := 25.0
var kl_clinker_hit_range := 22.0
var kl_clinker_target_range := 330.0
var kl_clinker_wake_radius := 224.0     # px from its post: it sleeps until you come this close
var kl_clinker_leash := 480.0           # px from its post: past this it goes home
var kl_clinker_stop_range := 65.0
var kl_clinker_roll_cooldown := 3.5
var kl_clinker_wick := 20               # was 15: 36 hp of shell and body, a roll; about 6 s of beam (balance pass)
var kl_nest_hp := 12.0
var kl_nest_core_dps := 2.0
var kl_nest_wick := 5                   # was 8: 12 nests made a third of the Hollow's wick (balance pass)
var kl_nest_wake_radius := 320.0
var kl_nest_hatch_count := 3
var kl_nest_hatch_sec := 10.0
var kl_nest_core_radius := 16.0
var kl_ashbrood_hp := 40.0
var kl_ashbrood_shell := 12.0
var kl_ashbrood_puff_period := 7.0
var kl_ashbrood_puff_tell := 0.8
var kl_ashbrood_puff_radius := 140.0
var kl_ashbrood_puff_warmth := 15.0
var kl_ashbrood_wave_period := 8.0
var kl_ashbrood_dive_period := 6.0
var kl_ashbrood_dive_tell := 0.7
var kl_ashbrood_dive_warmth := 25.0
var kl_ashbrood_sit_sec := 4.0
var kl_ashbrood_wick := 32              # base (Lv 7: x2.5 = 80); was 50 flat, 40 before the balance pass. Its kill is the Hollow's last level
var kl_ashbrood_puff_charge := 0.1
var kl_ashbrood_wave_count := 3
var kl_ashbrood_dive_dist := 200.0
var kl_ashbrood_roll_radius := 36.0
var kl_ashbrood_hit_radius := 48.0
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
# Wick and levels (balance pass 2026-11-27, DESIGN §9). Wick to go from level L to L+1 is
# round(kl_wick_base * L ^ kl_wick_exp): 6, 14, 24, 34, 45, 56, 68, 81, 93... (was flat: 15, then +10 a level).
# Level-gap pass (owner, 2026-11-27): every foe has a level, and its wick scales with it (DESIGN §9).
# Level 2 after the first pack or two, level 3 before the Clinker, level 7 into the Ashbrood, level 8 on its kill.
var kl_wick_base := 6.0
var kl_wick_exp := 1.25
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
var kl_ashbrood_level := 7
var kl_ashbrood_add_level := 5          # its phase-1 Wicklings: two below it, so standing in phase 1 is no farm
var kl_waylamp_swarm_level := 6         # Wicklings drawn to a kindling WayLamp (no guardian)
# Foe levels for packs and nests are in the HOLLOW_PACKS / HOLLOW_NESTS tables in scripts/main/main.gd.
var kl_wick_drop_radius := 28.0
var kl_pack_wake_radius := 320.0
# The first 10 minutes (onboarding, owner 2026-11-27, Option B): a small guard on the Post Lamp find.
# The route's first packs wake closer (the 6th column of HOLLOW_PACKS, in tiles), so nothing wakes at the hut.
var kl_post_guard_wake_radius := 128.0  # px (4 tiles): the shelled Wickling on Oswin's crook sleeps until you come this close
var kl_post_guard_level := 2            # its foe level: the first elite, one above the route's Wicklings

# Feedback (PROTOTYPE)
var kl_shake_px := 6.0                   # screen shake at full strength
var kl_kindled_kill_charge := 0.1        # "Kindled kills": lamp charge back per kill

# Lanterns and the dark (PROTOTYPE, owner 2026-11-27)
var kl_timid_share := 0.5                # share of Wicklings that won't enter healthy light
var kl_light_tolerance := 2.5            # s a brave Wickling can stand in light before it burns
var kl_light_burn_dps := 1.5             # hp/s it then takes (and it runs)

var kl_ambient_spawns := false           # the old endless trickle of Wicklings out of the fog (off: ARPG packs instead)

var ui_open := false                    # true while a menu has focus (player stops)
