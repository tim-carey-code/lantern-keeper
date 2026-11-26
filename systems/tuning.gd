extends Node
## Autoload "Tuning": live placeholder numbers from DESIGN §3.
## The debug panel (F1 / gamepad Select) edits these while the game runs.

var lantern_max_fuel := 100.0
var lantern_burn_per_sec := 1.0 / 3.0   # 100 fuel lasts ~5 minutes
var lantern_max_radius := 224.0         # px at full tank
var lantern_min_radius_frac := 0.4      # radius just before it goes cold
var refuel_amount := 100.0              # M1: infinite test pool, fills the tank

var fog_creep_per_sec := 0.05           # how fast unlit tiles fog back in
var fog_clear_per_sec := 0.8            # how fast light pushes fog out

var hand_lamp_radius := 72.0            # M1: fixed ember radius

var ui_open := false                    # true while a menu has focus (player stops)
