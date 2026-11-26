extends Node
## Autoload "Tuning": live placeholder numbers from DESIGN §3.
## The debug panel (F1 / gamepad Select) edits many of these while the game runs.

# Post Lamp
var lantern_max_fuel := 100.0
var lantern_burn_per_sec := 1.0 / 3.0   # 100 fuel lasts ~5 minutes
var lantern_max_radius := 224.0         # px at full tank
var lantern_min_radius_frac := 0.4      # radius just before it goes cold
var post_lamp_cost_scrap := 5
var pickup_refund := 0.5                # share of build cost returned on pick-up

# Reservoir Lamp (unlocked at the pumphouse)
var reservoir_cost_scrap := 8
var reservoir_max_fuel := 200.0
var reservoir_burn_per_sec := 0.2
var reservoir_radius := 200.0
var reservoir_min_radius_frac := 0.6
var reservoir_feed_per_sec := 0.5       # fuel/s given to each other lantern in its light

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
var wind_gust_sec := 8.0
var wind_burn_mult := 2.0               # exposed lanterns during a gust
var wind_radius_mult := 0.85
var wind_creep_mult := 1.5

# Hand lamp (dims in the dark, never goes out)
var hand_lamp_max_radius := 104.0
var hand_lamp_ember_radius := 44.0
var hand_lamp_drain_per_sec := 1.0 / 45.0   # full -> ember in 45 s of darkness
var hand_lamp_recharge_per_sec := 0.5       # free top-up while in lantern light
var hand_lamp_charge_per_fuel := 0.5        # auto-burns 1 carried fuel when low

var ui_open := false                    # true while a menu has focus (player stops)
