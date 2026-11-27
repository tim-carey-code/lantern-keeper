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
var ward_drain_per_sec := 0.25      # lamp charge per second (full lamp -> 4 s of ward)
var ward_walk_mult := 0.6           # you move slower while warding
var ward_min_charge := 0.05         # below this the lamp is too dim to ward
var ember_fuel := 1                 # a burned Wickling leaves an ember worth this much fuel
var ember_life := 30.0              # seconds before an ember fades
var wick_scrap_chance := 0.35       # chance a burned Wickling also drops 1 scrap
var warmth_max := 100.0
var warmth_drain_per_sec := 30.0    # while a Wickling touches the keeper
var warmth_regen_per_sec := 20.0    # in lantern light
var faint_drop := 0.5               # share of carried resources dropped on fainting

var ui_open := false                    # true while a menu has focus (player stops)
