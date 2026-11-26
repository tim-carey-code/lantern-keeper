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
var hand_lamp_max_radius := 104.0
var hand_lamp_ember_radius := 44.0
var hand_lamp_drain_per_sec := 1.0 / 45.0   # full -> ember in 45 s of darkness
var hand_lamp_recharge_per_sec := 0.5       # free top-up while in lantern light
var hand_lamp_charge_per_fuel := 0.5        # auto-burns 1 carried fuel when low

# PROTOTYPE: Wicklings, the flare and warmth (branch proto/wicklings)
var wick_enabled := true
var wick_first_delay := 25.0        # grace period at the start (s)
var wick_spawn_sec := 12.0
var wick_max := 7
var wick_hp := 3.0
var wick_speed := 65.0              # keeper walks at 160
var wick_sense := 380.0             # px: how far they notice lanterns / the keeper
var wick_rim := 0.12                # light level where they stop and drain (rim of the light)
var wick_core := 0.55               # light level that burns them
var wick_light_burn := 2.0          # hp/s while in a lantern's bright core
var wick_drain_per_sec := 5.0       # lantern fuel/s drained (100-fuel tank: ~20 s)
# Lamp beam (hold F / RB / RT): a cone of light from the hand lamp that wears Wicklings down.
var beam_length := 230.0            # px
var beam_half_angle := 0.32         # radians (~18 degrees each side)
var beam_dps := 1.5                 # Wickling hp per second (3 hp -> 2 s)
var beam_sec_per_fuel := 1.5        # one carried fuel keeps the beam on this long
var beam_walk_mult := 0.5           # you move slower while beaming
var warmth_max := 100.0
var warmth_drain_per_sec := 30.0    # while a Wickling touches the keeper
var warmth_regen_per_sec := 20.0    # in lantern light
var faint_drop := 0.5               # share of carried resources dropped on fainting

var ui_open := false                    # true while a menu has focus (player stops)
