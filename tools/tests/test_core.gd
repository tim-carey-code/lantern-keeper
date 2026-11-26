extends Node
## Headless checks for the core loop (M1 + M2). Run:
##   godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_core.tscn
## Exit code 0 = all passed. Runs as a scene so the autoloads are available.

var main: Node
var frame := 0
var fails := 0
var fog: FogGrid
var player: Node
var lamp: PostLamp
var woodpile: ResourceNode
var scrap_pile: ResourceNode
var built: PostLamp
var start := Vector2.ZERO
var lamp_density_cold := 0.0

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
			fog = main.fog
			player = main.player
			start = main.start
			lamp = main.get_node("Lanterns").get_child(0)
			for r in get_tree().get_nodes_in_group("resource"):
				if r.always_regrow:
					woodpile = r
				elif r.kind == "scrap" and r.global_position.distance_to(start) < 100.0:
					scrap_pile = r
			check(lamp != null and lamp.is_lit(), "starting lantern exists and is lit")
			check(woodpile != null and scrap_pile != null, "hut woodpile and starter scrap exist")
			var res := get_tree().get_nodes_in_group("resource")
			check(res.size() >= 40, "resources scattered in the Hollow (%d)" % res.size())
			check(res.all(func(r): return not r.is_revealed()), "all resources start hidden in fog")
			check(Inventory.get_count("fuel") == 0 and Inventory.get_count("scrap") == 0, "keeper starts with nothing")
			check(fog.is_solid_at(Vector2(8, 8)) and not fog.is_solid_at(start), "rock rings the Hollow, start is open")
			check(player.place_block_reason(Vector2(16, 16)) == "rock", "cannot build on rock")
		120:
			check(fog.density_at(lamp.global_position) < 0.1, "light clears fog at the lantern")
			check(fog.density_at(lamp.global_position + Vector2(400, 0)) > 0.9, "fog stays outside the radius")
			check(woodpile.is_revealed() and scrap_pile.is_revealed(), "light reveals nearby resources")
			check(lamp.fuel < Tuning.lantern_max_fuel, "lantern burns fuel")
			check(player.place_block_reason(start + Vector2(0, 96)).begins_with("needs"), "cannot build without scrap")
			player.position = scrap_pile.global_position + Vector2(12, 0)
			Input.action_press("interact")
		240:
			Input.action_release("interact")
			check(Inventory.get_count("scrap") == 6 and scrap_pile.amount == 0, "holding interact gathers scrap (%d)" % Inventory.get_count("scrap"))
			player.position = start + Vector2(0, 96)
		242:
			built = player.try_place()
			check(built != null, "can build a Post Lamp on lit ground")
			check(Inventory.get_count("scrap") == 1, "building costs %d scrap" % Tuning.post_lamp_cost_scrap)
			check(player.place_block_reason(player.place_pos()) != "", "cannot build twice in one spot")
			player.position = built.global_position
		244:
			player.pick_up_nearest()
		248:
			check(get_tree().get_nodes_in_group("lantern").size() == 1, "pick up removes the lantern")
			check(Inventory.get_count("scrap") == 3, "pick up refunds half the scrap")
			check(Inventory.get_count("fuel") >= 9, "pick up returns the tank's fuel (%d)" % Inventory.get_count("fuel"))
			# Hand lamp: walk deep into the dark with no fuel.
			Inventory.counts["fuel"] = 0
			Tuning.hand_lamp_drain_per_sec = 1.0
			player.position = start + Vector2(-420, 0)
		320:
			check(player.lamp_charge == 0.0, "hand lamp dims in the dark")
			check(is_equal_approx(player.get_light_radius(), Tuning.hand_lamp_ember_radius) and player.get_light_radius() > 0.0, "hand lamp never goes out (ember)")
			Inventory.add("fuel", 5)
		330:
			check(Inventory.get_count("fuel") < 5 and player.lamp_charge > 0.0, "hand lamp burns carried fuel when low")
			Tuning.hand_lamp_drain_per_sec = 1.0 / 45.0
			# Soft-lock scenario: every lantern cold, nothing carried, woodpile empty.
			lamp.fuel = 0.0
			Inventory.counts["fuel"] = 0
			woodpile.amount = 0
			woodpile.regrow_sec = 0.5
			Tuning.fog_creep_per_sec = 0.5
			player.position = woodpile.global_position + Vector2(12, 0)
		400:
			check(not lamp.is_lit(), "unfuelled lantern goes cold")
			check(woodpile.amount >= 1, "hut woodpile regrows: no soft-lock")
			Input.action_press("interact")
		460:
			Input.action_release("interact")
			check(Inventory.get_count("fuel") >= 1, "gathered fuel from the woodpile")
			lamp_density_cold = fog.density_at(lamp.global_position)
			check(lamp_density_cold > 0.15, "fog creeps back over a cold lantern (%.2f)" % lamp_density_cold)
			var t := fog.tile_of(lamp.global_position)
			check(fog.remembered[t.y * fog.cols + t.x] == 1, "faded tile stays remembered")
			Tuning.fog_creep_per_sec = 0.05
			player.position = lamp.global_position + Vector2(12, 0)
			Input.action_press("interact")
		462:
			Input.action_release("interact")
		465:
			check(lamp.is_lit(), "carried fuel relights a cold lantern")
			Inventory.counts["fuel"] = 0
			check(Inventory.add("fuel", 100) == Inventory.carry_limit, "carry limit caps gathering")
			print("RESULT fails=%d" % fails)
			get_tree().quit(1 if fails else 0)
