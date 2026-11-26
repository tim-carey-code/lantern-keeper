extends Node
## Headless M1 checks. Run:
##   godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_m1.tscn
## (Runs as a scene so the Tuning autoload is available.)
## Exit code 0 = all passed.

var main: Node
var frame := 0
var fails := 0
var lamp: PostLamp
var fog: FogGrid
var player: Node
var lamp_tile_density_lit := 0.0

func check(ok: bool, what: String) -> void:
	print(("PASS " if ok else "FAIL ") + what)
	if not ok:
		fails += 1

func _ready() -> void:
	main = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)

func _process(_delta: float) -> void:
	frame += 1
	match frame:
		2:
			fog = main.get_node("FogGrid")
			player = main.get_node("Player")
			lamp = main.get_node("Lanterns").get_child(0)
			check(lamp != null and lamp.is_lit(), "starting lantern exists and is lit")
			# Walk the keeper far away so only the lantern lights its tiles.
			player.position = Vector2(200, 200)
			var lt := Tuning.lantern_max_radius
			check(absf(lamp.get_light_radius() - lt) < 1.0, "full tank = full radius")
		120:
			lamp_tile_density_lit = fog.density_at(lamp.global_position)
			check(lamp_tile_density_lit < 0.1, "light clears fog at the lantern (%.2f)" % lamp_tile_density_lit)
			check(fog.density_at(lamp.global_position + Vector2(400, 0)) > 0.9, "fog stays outside the radius")
			check(fog.revealed_fraction() > 0.0, "lit tiles are remembered")
			check(lamp.fuel < Tuning.lantern_max_fuel, "lantern burns fuel")
			lamp.fuel = Tuning.lantern_max_fuel * 0.01
			var r := lamp.get_light_radius()
			check(r < Tuning.lantern_max_radius * 0.45 and r > 0.0, "near-empty radius shrinks to ~40%% (%.0f px)" % r)
			Tuning.lantern_burn_per_sec = 50.0
			Tuning.fog_creep_per_sec = 0.5
		180:
			check(not lamp.is_lit() and lamp.get_light_radius() == 0.0, "empty lantern goes cold")
			check(is_instance_valid(lamp), "cold lantern keeps its frame")
		600:
			var d := fog.density_at(lamp.global_position)
			check(d > lamp_tile_density_lit + 0.3, "fog creeps back after the light fades (%.2f)" % d)
			var t := fog.tile_of(lamp.global_position)
			check(fog.remembered[t.y * fog.cols + t.x] == 1, "faded tile is still remembered")
			# Relight costs only fuel.
			Tuning.lantern_burn_per_sec = 1.0 / 3.0
			var added: float = lamp.refuel(Tuning.refuel_amount)
			check(lamp.is_lit() and added > 0.0, "refuel relights a cold lantern")
			# Placement rules: not in deep fog, not on top of another lantern.
			player.position = Vector2(1900, 1400)
			check(not player.can_place(player.place_pos()), "cannot place in deep fog")
			player.position = lamp.global_position
			check(not player.can_place(player.place_pos()), "cannot place on an existing lantern")
			player.position = lamp.global_position + Vector2(96, 0)
		700:
			var placed = player.try_place()
			check(placed != null, "can place next to lit ground")
			check(get_tree().get_nodes_in_group("lantern").size() == 2, "two lanterns in the world")
		702:
			player.pick_up_nearest()
		705:
			check(get_tree().get_nodes_in_group("lantern").size() == 1, "pick up removes a lantern")
			print("RESULT fails=%d" % fails)
			get_tree().quit(1 if fails else 0)
